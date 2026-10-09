package com.carevora.dto.dashboard;

import com.carevora.dto.assessment.AssessmentResponse;
import com.carevora.entity.Alert;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DashboardSummaryResponse {
    private long totalResidents;
    private long needsAttention;
    private long stable;
    private long improving;
    private Map<String, Long> riskDistribution;
    private List<AssessmentResponse> recentAssessments;
    private List<Alert> recentAlerts;
}
