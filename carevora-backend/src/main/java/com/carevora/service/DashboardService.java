package com.carevora.service;

import com.carevora.dto.ApiResponse;
import com.carevora.dto.dashboard.DashboardSummaryResponse;
import com.carevora.dto.assessment.AssessmentResponse;
import com.carevora.entity.Alert;
import com.carevora.entity.Assessment;
import com.carevora.enums.RiskLevel;
import com.carevora.enums.TrajectoryStatus;
import com.carevora.enums.WellnessStatus;
import com.carevora.repository.AlertRepository;
import com.carevora.repository.AssessmentRepository;
import com.carevora.repository.ResidentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DashboardService {

    private final ResidentRepository residentRepository;
    private final AlertRepository alertRepository;
    private final AssessmentRepository assessmentRepository;

    public ApiResponse<DashboardSummaryResponse> getSummary() {
        long total = residentRepository.count();
        long needsAttention = residentRepository.countByCurrentStatus(WellnessStatus.NEEDS_ATTENTION) +
                residentRepository.countByCurrentStatus(WellnessStatus.CHECK_IN_NEEDED);
        long stable = residentRepository.countByCurrentStatus(WellnessStatus.STABLE);
        long improving = residentRepository.countByCurrentStatus(WellnessStatus.LOOKING_GOOD);

        Map<String, Long> riskMap = new HashMap<>();
        riskMap.put("low", residentRepository.countByRiskLevel(RiskLevel.LOW));
        riskMap.put("moderate", residentRepository.countByRiskLevel(RiskLevel.MODERATE));
        riskMap.put("high", residentRepository.countByRiskLevel(RiskLevel.HIGH));

        List<Alert> recentAlerts = alertRepository.findAllByOrderByCreatedAtDesc().stream().limit(5).collect(Collectors.toList());
        List<Assessment> assessments = assessmentRepository.findTop10ByOrderByCreatedAtDesc();

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
