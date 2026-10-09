package com.carevora.dto.assessment;

import com.carevora.enums.RiskLevel;
import com.carevora.enums.TrajectoryStatus;
import com.carevora.enums.WellnessStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AssessmentResponse {
    private Long id;
    private Long residentId;
    private Double overallScore;
    private Double emotionalScore;
    private Double socialScore;
    private WellnessStatus status;
    private RiskLevel riskLevel;
    private TrajectoryStatus trajectory;
    private String encouragingMessage;
    private LocalDateTime timestamp;
    private List<ContributingFactorDto> contributingFactors;
    private List<RecommendationDto> recommendations;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ContributingFactorDto {
        private String title;
        private Double score;
        private String description;
        private String category;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RecommendationDto {
        private Long id;
        private String title;
        private String reason;
        private String priority;
        private String suggestedAction;
        private String iconKey;
    }
}
