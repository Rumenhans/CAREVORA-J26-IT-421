package com.carevora.service;

import com.carevora.dto.ApiResponse;
import com.carevora.dto.memorygame.MemoryGameProgressSummaryResponse;
import com.carevora.dto.memorygame.MemoryGameSessionRequest;
import com.carevora.dto.memorygame.MemoryGameSessionResponse;
import com.carevora.entity.Caregiver;
import com.carevora.entity.MemoryGameSession;
import com.carevora.entity.Resident;
import com.carevora.entity.User;
import com.carevora.enums.UserRole;
import com.carevora.exception.BadRequestException;
import com.carevora.exception.ResourceNotFoundException;
import com.carevora.repository.CaregiverRepository;
import com.carevora.repository.MemoryGameSessionRepository;
import com.carevora.repository.ResidentRepository;
import com.carevora.repository.UserRepository;
import com.carevora.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MemoryGameService {

    private final MemoryGameSessionRepository memoryGameSessionRepository;
    private final ResidentRepository residentRepository;
    private final UserRepository userRepository;
    private final CaregiverRepository caregiverRepository;

    @Transactional
    public ApiResponse<MemoryGameSessionResponse> saveGameSession(MemoryGameSessionRequest request) {
        if (request == null || request.getResidentId() == null) {
            throw new BadRequestException("Resident ID is required to save a game session");
        }

        // Must be a completed session - do not save incomplete or abandoned games
        if (request.getStatus() == null || !"COMPLETED".equalsIgnoreCase(request.getStatus().trim())) {
            throw new BadRequestException("Incomplete or abandoned game sessions cannot be saved as completed.");
        }

        if (request.getScorePercentage() == null || request.getScorePercentage() < 0.0 || request.getScorePercentage() > 100.0) {
            throw new BadRequestException("Score percentage must be within range [0.0, 100.0]");
        }

        Resident resident;
        Optional<User> currentUserOpt = SecurityUtils.getCurrentUser(userRepository);
        if (currentUserOpt.isPresent() && (currentUserOpt.get().getRole() == UserRole.ELDER || currentUserOpt.get().getRole() == UserRole.RESIDENT)) {
            resident = residentRepository.findByUserId(currentUserOpt.get().getId())
                    .orElseGet(() -> residentRepository.findById(request.getResidentId())
                            .orElseThrow(() -> new ResourceNotFoundException("Resident not found with id: " + request.getResidentId())));
        } else {
            resident = residentRepository.findById(request.getResidentId())
                    .orElseThrow(() -> new ResourceNotFoundException("Resident not found with id: " + request.getResidentId()));
        }

        enforceResidentAccess(resident);

        String currentUserName = currentUserOpt
                .map(User::getFullName)
                .orElse(resident.getUser() != null ? resident.getUser().getFullName() : "Resident #" + resident.getId());

        String sessionId = request.getSessionId();
        if (sessionId == null || sessionId.isBlank()) {
            sessionId = "mg-sess-" + UUID.randomUUID().toString();
        }

        MemoryGameSession session = MemoryGameSession.builder()
                .sessionId(sessionId)
                .resident(resident)
                .gameType(request.getGameType().toUpperCase().trim())
                .scorePercentage(Math.round(request.getScorePercentage() * 10.0) / 10.0)
                .attempts(request.getAttempts())
                .correctAnswers(request.getCorrectAnswers())
                .totalItems(request.getTotalItems())
                .status("COMPLETED")
                .completionDetailsJson(request.getCompletionDetailsJson())
                .playedBy(currentUserName)
                .build();

        session = memoryGameSessionRepository.save(session);

        return ApiResponse.ok(mapToResponse(session), "Memory game session recorded successfully");
    }

    @Transactional(readOnly = true)
    public ApiResponse<List<MemoryGameSessionResponse>> getResidentGameSessions(Long residentId) {
        Resident resident;
        Optional<User> currentUserOpt = SecurityUtils.getCurrentUser(userRepository);
        if (currentUserOpt.isPresent() && (currentUserOpt.get().getRole() == UserRole.ELDER || currentUserOpt.get().getRole() == UserRole.RESIDENT)) {
            resident = residentRepository.findByUserId(currentUserOpt.get().getId())
                    .orElseGet(() -> residentRepository.findById(residentId)
                            .orElseThrow(() -> new ResourceNotFoundException("Resident not found with id: " + residentId)));
        } else {
            resident = residentRepository.findById(residentId)
                    .orElseThrow(() -> new ResourceNotFoundException("Resident not found with id: " + residentId));
        }

        enforceResidentAccess(resident);

        List<MemoryGameSession> sessions = memoryGameSessionRepository.findByResidentIdOrderByCompletedAtDesc(resident.getId());
        List<MemoryGameSessionResponse> responses = sessions.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());

        return ApiResponse.ok(responses, "Memory game sessions retrieved successfully");
    }

    @Transactional(readOnly = true)
    public ApiResponse<MemoryGameProgressSummaryResponse> getResidentGameProgress(Long residentId) {
        Resident resident;
        Optional<User> currentUserOpt = SecurityUtils.getCurrentUser(userRepository);
        if (currentUserOpt.isPresent() && (currentUserOpt.get().getRole() == UserRole.ELDER || currentUserOpt.get().getRole() == UserRole.RESIDENT)) {
            resident = residentRepository.findByUserId(currentUserOpt.get().getId())
                    .orElseGet(() -> residentRepository.findById(residentId)
                            .orElseThrow(() -> new ResourceNotFoundException("Resident not found with id: " + residentId)));
        } else {
            resident = residentRepository.findById(residentId)
                    .orElseThrow(() -> new ResourceNotFoundException("Resident not found with id: " + residentId));
        }

        enforceResidentAccess(resident);

        List<MemoryGameSession> sessions = memoryGameSessionRepository.findByResidentIdOrderByCompletedAtDesc(resident.getId());
        List<MemoryGameSessionResponse> sessionResponses = sessions.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());

        Double latestSequenceScore = null;
        Double latestPairsScore = null;
        Double latestItemsScore = null;

        List<Double> sequenceScores = new ArrayList<>();
        List<Double> pairsScores = new ArrayList<>();
        List<Double> itemsScores = new ArrayList<>();

        for (MemoryGameSession s : sessions) {
            String type = s.getGameType().toUpperCase();
            if (type.contains("SEQUENCE")) {
                if (latestSequenceScore == null) latestSequenceScore = s.getScorePercentage();
                sequenceScores.add(s.getScorePercentage());
            } else if (type.contains("PAIR")) {
                if (latestPairsScore == null) latestPairsScore = s.getScorePercentage();
                pairsScores.add(s.getScorePercentage());
            } else if (type.contains("ITEM")) {
                if (latestItemsScore == null) latestItemsScore = s.getScorePercentage();
                itemsScores.add(s.getScorePercentage());
            }
        }

        Double averageScore = sessions.isEmpty()
                ? null
                : Math.round((sessions.stream().mapToDouble(MemoryGameSession::getScorePercentage).average().orElse(0.0)) * 10.0) / 10.0;

        String sequenceProgress = determineTrend(sequenceScores);
        String pairsProgress = determineTrend(pairsScores);
        String itemsProgress = determineTrend(itemsScores);
        String overallProgress = determineOverallTrend(sessions);

        boolean hasRepeatedDecline = detectRepeatedDecline(sessions);
        String caregiverNotice = null;
        if (hasRepeatedDecline) {
            caregiverNotice = "Caregiver Notice: Memory game accuracy has shown a downward trend across recent sessions. Consider scheduling a relaxed, supportive cognitive review.";
        }

        MemoryGameProgressSummaryResponse summary = MemoryGameProgressSummaryResponse.builder()
                .residentId(resident.getId())
                .residentName(resident.getUser() != null ? resident.getUser().getFullName() : "Resident #" + resident.getId())
                .totalCompletedSessions(sessions.size())
                .latestActivityDate(sessions.isEmpty() ? null : sessions.get(0).getCompletedAt())
                .latestSequenceScore(latestSequenceScore)
                .latestPairsScore(latestPairsScore)
                .latestItemsScore(latestItemsScore)
                .averageScore(averageScore)
                .sequenceProgress(sequenceProgress)
                .pairsProgress(pairsProgress)
                .itemsProgress(itemsProgress)
                .overallProgress(overallProgress)
                .hasRepeatedDecline(hasRepeatedDecline)
                .caregiverNotice(caregiverNotice)
                .sessions(sessionResponses)
                .build();

        return ApiResponse.ok(summary, "Memory game progress summary retrieved successfully");
    }

    private String determineTrend(List<Double> scoresDescending) {
        if (scoresDescending == null || scoresDescending.isEmpty()) {
            return "NO_DATA";
        }
        if (scoresDescending.size() == 1) {
            return "STEADY";
        }

        double latest = scoresDescending.get(0);
        double previous = scoresDescending.get(1);

        if (latest >= previous + 5.0) {
            return "IMPROVING";
        } else if (latest <= previous - 15.0) {
            return "NEEDS_PRACTICE";
        } else {
            return "STEADY";
        }
    }

    private String determineOverallTrend(List<MemoryGameSession> sessionsDescending) {
        if (sessionsDescending.isEmpty()) return "NO_DATA";
        if (sessionsDescending.size() < 2) return "STEADY";

        double latest = sessionsDescending.get(0).getScorePercentage();
        double previous = sessionsDescending.get(1).getScorePercentage();

        if (latest >= previous + 5.0) {
            return "IMPROVING";
        } else if (latest <= previous - 15.0) {
            return "NEEDS_PRACTICE";
        } else {
            return "STEADY";
        }
    }

    private boolean detectRepeatedDecline(List<MemoryGameSession> sessionsDescending) {
        if (sessionsDescending == null || sessionsDescending.size() < 3) {
            return false;
        }

        // Check if last 3 consecutive sessions had decreasing scores
        double s0 = sessionsDescending.get(0).getScorePercentage();
        double s1 = sessionsDescending.get(1).getScorePercentage();
        double s2 = sessionsDescending.get(2).getScorePercentage();

        return (s0 < s1 && s1 < s2 && (s2 - s0) >= 15.0);
    }

    private void enforceResidentAccess(Resident resident) {
        Optional<User> currentUserOpt = SecurityUtils.getCurrentUser(userRepository);
        if (currentUserOpt.isEmpty()) {
            return; // Internal / system or test context without security context
        }

        User currentUser = currentUserOpt.get();
        UserRole role = currentUser.getRole();

        // 1. Caregiver can only access residents in their assigned Elder Home
        if (role == UserRole.CAREGIVER) {
            Optional<Caregiver> caregiverOpt = caregiverRepository.findByUserId(currentUser.getId());
            if (caregiverOpt.isEmpty() || caregiverOpt.get().getElderHome() == null ||
                    resident.getElderHome() == null ||
                    !resident.getElderHome().getId().equals(caregiverOpt.get().getElderHome().getId())) {
                throw new AccessDeniedException("Access denied: You can only view game records for residents belonging to your assigned Elder Home.");
            }
        }
        // 2. Elder can only access their own game records
        else if (role == UserRole.ELDER || role == UserRole.RESIDENT) {
            if (resident.getUser() == null || !resident.getUser().getId().equals(currentUser.getId())) {
                throw new AccessDeniedException("Access denied: Elders are not authorized to view other elders' game records.");
            }
        }
        // 3. DOCTOR and ADMIN have facility-wide access
    }

    private MemoryGameSessionResponse mapToResponse(MemoryGameSession session) {
        String resName = "Resident #" + session.getResident().getId();
        if (session.getResident().getUser() != null && session.getResident().getUser().getFullName() != null) {
            resName = session.getResident().getUser().getFullName();
        }
        return MemoryGameSessionResponse.builder()
                .id(session.getId())
                .sessionId(session.getSessionId())
                .residentId(session.getResident().getId())
                .residentName(resName)
                .gameType(session.getGameType())
                .scorePercentage(session.getScorePercentage())
                .attempts(session.getAttempts())
                .correctAnswers(session.getCorrectAnswers())
                .totalItems(session.getTotalItems())
                .status(session.getStatus())
                .completionDetailsJson(session.getCompletionDetailsJson())
                .playedBy(session.getPlayedBy())
                .completedAt(session.getCompletedAt())
                .build();
    }
}
