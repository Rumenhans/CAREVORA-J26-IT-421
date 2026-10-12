package com.carevora.service;

import com.carevora.dto.ApiResponse;
import com.carevora.dto.dashboard.DashboardSummaryResponse;
import com.carevora.dto.assessment.AssessmentResponse;
import com.carevora.entity.Alert;
import com.carevora.entity.Assessment;
import com.carevora.entity.Caregiver;
import com.carevora.entity.User;
import com.carevora.enums.RiskLevel;
import com.carevora.enums.UserRole;
import com.carevora.enums.WellnessStatus;
import com.carevora.repository.AlertRepository;
import com.carevora.repository.AssessmentRepository;
import com.carevora.repository.CaregiverRepository;
import com.carevora.repository.ResidentRepository;
import com.carevora.repository.UserRepository;
import com.carevora.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DashboardService {

    private final ResidentRepository residentRepository;
    private final AlertRepository alertRepository;
    private final AssessmentRepository assessmentRepository;
    private final UserRepository userRepository;
    private final CaregiverRepository caregiverRepository;

    @Transactional(readOnly = true)
    public ApiResponse<DashboardSummaryResponse> getSummary() {
        Optional<User> currentUserOpt = SecurityUtils.getCurrentUser(userRepository);
        Long scopedElderHomeId = null;

        if (currentUserOpt.isPresent()) {
            User currentUser = currentUserOpt.get();
            if (currentUser.getRole() == UserRole.CAREGIVER) {
                Optional<Caregiver> cgOpt = caregiverRepository.findByUserId(currentUser.getId());
                if (cgOpt.isPresent() && cgOpt.get().getElderHome() != null) {
                    scopedElderHomeId = cgOpt.get().getElderHome().getId();
                }
            }
        }

        long total;
        long needsAttention;
        long stable;
        long improving;
        Map<String, Long> riskMap = new HashMap<>();

        if (scopedElderHomeId != null) {
            // Scoped to Caregiver's Elder Home
            total = residentRepository.countByElderHomeId(scopedElderHomeId);
            needsAttention = residentRepository.countByElderHomeIdAndCurrentStatus(scopedElderHomeId, WellnessStatus.NEEDS_ATTENTION) +
                    residentRepository.countByElderHomeIdAndCurrentStatus(scopedElderHomeId, WellnessStatus.CHECK_IN_NEEDED);
            stable = residentRepository.countByElderHomeIdAndCurrentStatus(scopedElderHomeId, WellnessStatus.STABLE);
            improving = residentRepository.countByElderHomeIdAndCurrentStatus(scopedElderHomeId, WellnessStatus.LOOKING_GOOD);

            riskMap.put("low", residentRepository.countByElderHomeIdAndRiskLevel(scopedElderHomeId, RiskLevel.LOW));
            riskMap.put("moderate", residentRepository.countByElderHomeIdAndRiskLevel(scopedElderHomeId, RiskLevel.MODERATE));
            riskMap.put("high", residentRepository.countByElderHomeIdAndRiskLevel(scopedElderHomeId, RiskLevel.HIGH));
        } else {
            // Doctor / Admin global view across all Elder Homes
            total = residentRepository.count();
            needsAttention = residentRepository.countByCurrentStatus(WellnessStatus.NEEDS_ATTENTION) +
                    residentRepository.countByCurrentStatus(WellnessStatus.CHECK_IN_NEEDED);
            stable = residentRepository.countByCurrentStatus(WellnessStatus.STABLE);
            improving = residentRepository.countByCurrentStatus(WellnessStatus.LOOKING_GOOD);

            riskMap.put("low", residentRepository.countByRiskLevel(RiskLevel.LOW));
            riskMap.put("moderate", residentRepository.countByRiskLevel(RiskLevel.MODERATE));
            riskMap.put("high", residentRepository.countByRiskLevel(RiskLevel.HIGH));
        }

        final Long finalHomeId = scopedElderHomeId;
        List<Alert> recentAlerts = alertRepository.findAllByOrderByCreatedAtDesc().stream()
                .filter(a -> finalHomeId == null || (a.getResident() != null && a.getResident().getElderHome() != null && a.getResident().getElderHome().getId().equals(finalHomeId)))
                .limit(5)
                .collect(Collectors.toList());

        List<Assessment> assessments = assessmentRepository.findTop10ByOrderByCreatedAtDesc().stream()
                .filter(a -> finalHomeId == null || (a.getResident() != null && a.getResident().getElderHome() != null && a.getResident().getElderHome().getId().equals(finalHomeId)))
                .collect(Collectors.toList());

        List<AssessmentResponse> recentAssessments = assessments.stream().map(a -> AssessmentResponse.builder()
                .id(a.getId())
                .residentId(a.getResident().getId())
                .overallScore(a.getOverallScore())
                .emotionalScore(a.getEmotionalScore())
                .socialScore(a.getSocialScore())
                .status(a.getStatus())
                .riskLevel(a.getRiskLevel())
                .trajectory(a.getTrajectory())
                .encouragingMessage(a.getEncouragingMessage())
                .timestamp(a.getCreatedAt())
                .build()).collect(Collectors.toList());

        DashboardSummaryResponse summary = DashboardSummaryResponse.builder()
                .totalResidents(total)
                .needsAttention(needsAttention)
                .stable(stable)
                .improving(improving)
                .riskDistribution(riskMap)
                .recentAlerts(recentAlerts)
                .recentAssessments(recentAssessments)
                .build();

        return ApiResponse.ok(summary);
    }
}
