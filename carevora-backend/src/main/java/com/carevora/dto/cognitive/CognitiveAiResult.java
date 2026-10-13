package com.carevora.dto.cognitive;

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
public class CognitiveAiResult {
    private Double acrfScore;
    private Double rawWeightedScore;
    private String scale;
    private String scoringDirection;
    private Map<String, Double> weightsApplied;
    private Map<String, Double> categoryScores;
    private List<CognitiveAssessmentResponse.CategoryContributionDto> categoryContributions;
    private CognitiveAssessmentResponse.MlModelStatusDto mlModelEvaluation;
    private String methodology;
    private String clinicalDisclaimer;
}
