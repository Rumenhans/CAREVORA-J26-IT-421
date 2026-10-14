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

    public CognitiveAiResult(
            Double acrfScore,
            Double rawWeightedScore,
            String scale,
            String scoringDirection,
            Map<String, Double> weightsApplied,
            Map<String, Double> categoryScores,
            List<CognitiveAssessmentResponse.CategoryContributionDto> categoryContributions,
            CognitiveAssessmentResponse.MlModelStatusDto mlModelEvaluation,
            String methodology,
            String clinicalDisclaimer) {
        this.acrfScore = acrfScore;
        this.rawWeightedScore = rawWeightedScore;
        this.scale = scale;
        this.scoringDirection = scoringDirection;
        this.weightsApplied = weightsApplied;
        this.categoryScores = categoryScores;
        this.categoryContributions = categoryContributions;
        this.mlModelEvaluation = mlModelEvaluation;
        this.methodology = methodology;
        this.clinicalDisclaimer = clinicalDisclaimer;
    }
}
