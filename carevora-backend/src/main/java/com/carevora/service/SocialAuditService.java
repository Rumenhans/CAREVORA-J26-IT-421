package com.carevora.service;

import com.carevora.dto.ApiResponse;
import com.carevora.dto.socialaudit.SocialAuditRequest;
import com.carevora.dto.socialaudit.SocialAuditResponse;
import com.carevora.entity.Caregiver;
import com.carevora.entity.Resident;
import com.carevora.entity.SocialAudit;
import com.carevora.entity.User;
import com.carevora.enums.ActivityParticipationLevel;
import com.carevora.enums.AloneTimeContext;
import com.carevora.enums.PeerInteractionLevel;
import com.carevora.enums.UserRole;
import com.carevora.exception.BadRequestException;
import com.carevora.exception.ResourceNotFoundException;
import com.carevora.repository.CaregiverRepository;
import com.carevora.repository.ResidentRepository;
import com.carevora.repository.SocialAuditRepository;
import com.carevora.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class SocialAuditService {

    private final SocialAuditRepository socialAuditRepository;
    private final ResidentRepository residentRepository;
    private final UserRepository userRepository;
    private final CaregiverRepository caregiverRepository;

    @Transactional
    public ApiResponse<SocialAuditResponse> createSocialAudit(
            Long residentId,
            SocialAuditRequest request,
            String authenticatedEmail
    ) {
        Resident resident = residentRepository.findById(residentId)
                .orElseThrow(() -> new ResourceNotFoundException("Resident not found with id: " + residentId));

        User caregiverUser = userRepository.findByEmail(authenticatedEmail)
                .orElseThrow(() -> new ResourceNotFoundException("Authenticated user not found with email: " + authenticatedEmail));

        // Enforce authorization: only CAREGIVER, DOCTOR, or ADMIN can conduct staff social audits
        if (caregiverUser.getRole() != UserRole.CAREGIVER &&
            caregiverUser.getRole() != UserRole.DOCTOR &&
            caregiverUser.getRole() != UserRole.ADMIN) {
            throw new AccessDeniedException("User role " + caregiverUser.getRole() + " is not authorized to submit caregiver social audits");
        }

        // If caregiver, verify elder home scope when both have an assigned elder home
        if (caregiverUser.getRole() == UserRole.CAREGIVER) {
            Optional<Caregiver> cgOpt = caregiverRepository.findByUserId(caregiverUser.getId());
            if (cgOpt.isPresent() && cgOpt.get().getElderHome() != null && resident.getElderHome() != null) {
                Long cgHomeId = cgOpt.get().getElderHome().getId();
                Long resHomeId = resident.getElderHome().getId();
                if (!cgHomeId.equals(resHomeId)) {
                    throw new AccessDeniedException("Caregiver is not authorized to audit residents of a different elder home");
                }
            }
        }

        // Validate activity participation consistency
        if (request.getActivitiesAvailable() != null &&
            request.getActivitiesAttended() != null &&
            request.getActivitiesAttended() > request.getActivitiesAvailable()) {
            throw new BadRequestException("Activities attended (" + request.getActivitiesAttended() +
                    ") cannot exceed activities available (" + request.getActivitiesAvailable() + ")");
        }

        // Compute observational social score with transparent provenance
        ObservationalScoreResult scoreResult = computeObservationalScore(request);

        SocialAudit audit = SocialAudit.builder()
                .resident(resident)
                .caregiverUser(caregiverUser)
                .auditDate(LocalDateTime.now())
                .reportingPeriodDays(request.getReportingPeriodDays() != null ? request.getReportingPeriodDays() : 7)
                .familyInPersonVisits(Boolean.TRUE.equals(request.getExternalContactUnknown()) ? null : request.getFamilyInPersonVisits())
                .familyPhoneVideoContacts(Boolean.TRUE.equals(request.getExternalContactUnknown()) ? null : request.getFamilyPhoneVideoContacts())
                .externalContactUnknown(Boolean.TRUE.equals(request.getExternalContactUnknown()))
                .peerInteractionLevel(request.getPeerInteractionLevel())
                .activitiesAvailable(request.getActivitiesAvailable())
                .activitiesAttended(request.getActivitiesAttended())
                .activityParticipationLevel(request.getActivityParticipationLevel())
                .healthMobilityBarriers(Boolean.TRUE.equals(request.getHealthMobilityBarriers()))
                .estimatedHoursAlonePerDay(request.getEstimatedHoursAlonePerDay())
                .aloneTimeContext(request.getAloneTimeContext())
                .caregiverNotes(request.getCaregiverNotes())
                .socialScore(scoreResult.score)
                .scoreProvenance(scoreResult.provenance)
                .build();

        SocialAudit savedAudit = socialAuditRepository.save(audit);

        // Update Resident's current verified social score snapshot
        if (scoreResult.score != null) {
            resident.setSocialScore(scoreResult.score);
            residentRepository.save(resident);
        }

        log.info("Successfully recorded caregiver social audit #{} for resident #{} by user #{} (score: {})",
                savedAudit.getId(), residentId, caregiverUser.getId(), scoreResult.score);

        return ApiResponse.ok(mapToResponse(savedAudit), "Caregiver social audit recorded successfully");
    }

    @Transactional(readOnly = true)
    public ApiResponse<List<SocialAuditResponse>> getAuditsByResident(Long residentId) {
        if (!residentRepository.existsById(residentId)) {
            throw new ResourceNotFoundException("Resident not found with id: " + residentId);
        }
        List<SocialAudit> audits = socialAuditRepository.findByResidentIdOrderByAuditDateDesc(residentId);
        List<SocialAuditResponse> responses = audits.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
        return ApiResponse.ok(responses, "Retrieved " + responses.size() + " social audit records");
    }

    @Transactional(readOnly = true)
    public ApiResponse<SocialAuditResponse> getLatestAudit(Long residentId) {
        if (!residentRepository.existsById(residentId)) {
            throw new ResourceNotFoundException("Resident not found with id: " + residentId);
        }
        SocialAudit latest = socialAuditRepository.findFirstByResidentIdOrderByAuditDateDesc(residentId)
                .orElse(null);

        if (latest == null) {
            return ApiResponse.ok(null, "No caregiver social audit recorded for this resident");
        }
        return ApiResponse.ok(mapToResponse(latest), "Latest caregiver social audit retrieved");
    }

    @Transactional(readOnly = true)
    public ApiResponse<SocialAuditResponse> getAuditById(Long residentId, Long auditId) {
        SocialAudit audit = socialAuditRepository.findByIdAndResidentId(auditId, residentId)
                .orElseThrow(() -> new ResourceNotFoundException("Social audit #" + auditId + " not found for resident #" + residentId));
        return ApiResponse.ok(mapToResponse(audit), "Social audit retrieved successfully");
    }

    // ------------------------------------------------------------------------
    // Observational 4-Domain Standardized Scoring Algorithm
    // ------------------------------------------------------------------------
    private ObservationalScoreResult computeObservationalScore(SocialAuditRequest req) {
        double weightedSum = 0.0;
        double totalWeight = 0.0;
        List<String> activeDomains = new ArrayList<>();

        // Domain 1: Family & External Contact (Weight: 0.30)
        if (!Boolean.TRUE.equals(req.getExternalContactUnknown()) &&
            (req.getFamilyInPersonVisits() != null || req.getFamilyPhoneVideoContacts() != null)) {
            int visits = req.getFamilyInPersonVisits() != null ? req.getFamilyInPersonVisits() : 0;
            int calls = req.getFamilyPhoneVideoContacts() != null ? req.getFamilyPhoneVideoContacts() : 0;
            int totalContacts = visits + calls;

            // 0 contacts = 25.0, 1 = 50.0, 2 = 70.0, 3 = 85.0, 4+ = 100.0
            double contactScore = Math.min(100.0, 25.0 + (totalContacts * 18.75));
            weightedSum += contactScore * 0.30;
            totalWeight += 0.30;
            activeDomains.add("ExternalContact(" + totalContacts + ")");
        }

        // Domain 2: Peer Interaction Frequency (Weight: 0.30)
        if (req.getPeerInteractionLevel() != null && req.getPeerInteractionLevel() != PeerInteractionLevel.UNKNOWN) {
            double peerScore;
            switch (req.getPeerInteractionLevel()) {
                case VERY_OFTEN:
                    peerScore = 100.0;
                    break;
                case OFTEN:
                    peerScore = 80.0;
                    break;
                case SOMETIMES:
                    peerScore = 55.0;
                    break;
                case RARELY:
                default:
                    peerScore = 20.0;
                    break;
            }
            weightedSum += peerScore * 0.30;
            totalWeight += 0.30;
            activeDomains.add("PeerInteraction(" + req.getPeerInteractionLevel().name() + ")");
        }

        // Domain 3: Group Activity Participation (Weight: 0.25)
        if (req.getActivityParticipationLevel() != null && req.getActivityParticipationLevel() != ActivityParticipationLevel.UNKNOWN) {
            double actScore;
            if (Boolean.TRUE.equals(req.getHealthMobilityBarriers())) {
                // Resident has physical/mobility/illness barriers: do not penalize inability to attend
                actScore = 75.0; // Neutral/exempt baseline
            } else if (req.getActivitiesAvailable() != null && req.getActivitiesAvailable() > 0 && req.getActivitiesAttended() != null) {
                actScore = Math.min(100.0, ((double) req.getActivitiesAttended() / req.getActivitiesAvailable()) * 100.0);
            } else {
                switch (req.getActivityParticipationLevel()) {
                    case ACTIVE_ENGAGEMENT:
                        actScore = 100.0;
                        break;
                    case PASSIVE_OBSERVER:
                        actScore = 70.0;
                        break;
                    case UNABLE_HEALTH_MOBILITY:
                        actScore = 75.0;
                        break;
                    case DECLINED_PREFERS_ALONE:
                    default:
                        actScore = 35.0;
                        break;
                }
            }
            weightedSum += actScore * 0.25;
            totalWeight += 0.25;
            activeDomains.add("Activities(" + req.getActivityParticipationLevel().name() + ")");
        }

        // Domain 4: Solitude Context (Weight: 0.15)
        if (req.getAloneTimeContext() != null && req.getAloneTimeContext() != AloneTimeContext.UNKNOWN) {
            double aloneScore;
            switch (req.getAloneTimeContext()) {
                case CHOSEN_SOLITUDE:
                    aloneScore = 85.0; // Healthy, voluntary autonomous quiet time
                    break;
                case MIXED:
                    aloneScore = 55.0;
                    break;
                case INVOLUNTARY_ISOLATION:
                default:
                    aloneScore = 20.0; // Distressing, unwanted isolation
                    break;
            }
            weightedSum += aloneScore * 0.15;
            totalWeight += 0.15;
            activeDomains.add("SolitudeContext(" + req.getAloneTimeContext().name() + ")");
        }

        if (totalWeight <= 0.0) {
            return new ObservationalScoreResult(null, "UNASSESSED: No observable metrics recorded");
        }

        double normalizedScore = Math.round((weightedSum / totalWeight) * 10.0) / 10.0;
        String provenance = "CAREVORA-OBS-SOC-V1: Domains[" + String.join(", ", activeDomains) + "] (w=" +
                Math.round(totalWeight * 100.0) + "%)";

        return new ObservationalScoreResult(normalizedScore, provenance);
    }

    private SocialAuditResponse mapToResponse(SocialAudit audit) {
        Integer visits = audit.getFamilyInPersonVisits();
        Integer calls = audit.getFamilyPhoneVideoContacts();
        Integer totalContacts = (visits != null || calls != null)
                ? (visits != null ? visits : 0) + (calls != null ? calls : 0)
                : null;

        Double participationRate = null;
        if (audit.getActivitiesAvailable() != null && audit.getActivitiesAvailable() > 0 && audit.getActivitiesAttended() != null) {
            participationRate = Math.round(((double) audit.getActivitiesAttended() / audit.getActivitiesAvailable()) * 1000.0) / 10.0;
        }

        String staffCode = null;
        if (audit.getCaregiverUser() != null) {
            Optional<Caregiver> cg = caregiverRepository.findByUserId(audit.getCaregiverUser().getId());
            if (cg.isPresent()) {
                staffCode = cg.get().getStaffCode();
            }
        }

        return SocialAuditResponse.builder()
                .id(audit.getId())
                .residentId(audit.getResident() != null ? audit.getResident().getId() : null)
                .residentName(audit.getResident() != null && audit.getResident().getUser() != null ? audit.getResident().getUser().getFullName() : "Unknown Resident")
                .caregiverUserId(audit.getCaregiverUser() != null ? audit.getCaregiverUser().getId() : null)
                .caregiverName(audit.getCaregiverUser() != null ? audit.getCaregiverUser().getFullName() : "Caregiver Staff")
                .caregiverStaffCode(staffCode)
                .auditDate(audit.getAuditDate())
                .reportingPeriodDays(audit.getReportingPeriodDays())
                .familyInPersonVisits(audit.getFamilyInPersonVisits())
                .familyPhoneVideoContacts(audit.getFamilyPhoneVideoContacts())
                .totalExternalContacts(totalContacts)
                .externalContactUnknown(audit.getExternalContactUnknown())
                .peerInteractionLevel(audit.getPeerInteractionLevel())
                .activitiesAvailable(audit.getActivitiesAvailable())
                .activitiesAttended(audit.getActivitiesAttended())
                .activityParticipationRate(participationRate)
                .activityParticipationLevel(audit.getActivityParticipationLevel())
                .healthMobilityBarriers(audit.getHealthMobilityBarriers())
                .estimatedHoursAlonePerDay(audit.getEstimatedHoursAlonePerDay())
                .aloneTimeContext(audit.getAloneTimeContext())
                .caregiverNotes(audit.getCaregiverNotes())
                .socialScore(audit.getSocialScore())
                .scoreProvenance(audit.getScoreProvenance())
                .createdAt(audit.getCreatedAt())
                .build();
    }

    private static class ObservationalScoreResult {
        final Double score;
        final String provenance;

        ObservationalScoreResult(Double score, String provenance) {
            this.score = score;
            this.provenance = provenance;
        }
    }
}
