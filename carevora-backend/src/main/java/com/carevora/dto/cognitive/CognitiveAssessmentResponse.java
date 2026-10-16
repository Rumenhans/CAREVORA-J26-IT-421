package com.carevora.dto.cognitive;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CognitiveAssessmentResponse {
    private Long id;
    private Long residentId;
    private String residentName;
    private Double memory;
    private Double attention;
    private Double orientation;
    private Double recall;
    private Double reasoning;
    private Double acrfScore;
    private String mlPrediction;
    private String riskLevel;
    private Boolean alertTriggered;
    private List<CategoryContributionDto> categoryContributions;
    private Map<String, Double> weightsApplied;
    private MlModelStatusDto mlModelEvaluation;
    private String methodology;
    private String clinicalDisclaimer;
    private String assessedBy;
    private LocalDateTime createdAt;
    private String sessionId;
    private String status;
    private Map<Integer, String> responses;
    private Map<Integer, Double> grades;
    private Map<String, Double> accuracies;
    private Map<String, Double> responseTimes;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CategoryContributionDto {
        private String category;
        private Double score;
        private Double weight;
        private Double contribution;
        private String weightPercentage;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class MlModelStatusDto {
        private boolean available;
        private String modelType;
        private String statusMessage;
        private Object prediction;
        private Map<String, Double> probabilities;
        private Boolean alertTriggered;
        private Double alertThreshold;
        private String experimentalLabel;
        private List<String> missingFeatures;
    }
}
