package com.carevora.dto.cognitive;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@Builder
@NoArgsConstructor
public class CognitiveAssessmentSubmissionRequest {

    @NotNull(message = "Resident ID is required")
    private Long residentId;

    @NotNull(message = "Memory score is required")
    @DecimalMin(value = "0.0", message = "Memory score must be >= 0.0")
    @DecimalMax(value = "100.0", message = "Memory score must be <= 100.0")
    private Double memory;

    @NotNull(message = "Attention score is required")
    @DecimalMin(value = "0.0", message = "Attention score must be >= 0.0")
    @DecimalMax(value = "100.0", message = "Attention score must be <= 100.0")
    private Double attention;

    @NotNull(message = "Orientation score is required")
    @DecimalMin(value = "0.0", message = "Orientation score must be >= 0.0")
    @DecimalMax(value = "100.0", message = "Orientation score must be <= 100.0")
    private Double orientation;

    @NotNull(message = "Recall score is required")
    @DecimalMin(value = "0.0", message = "Recall score must be >= 0.0")
    @DecimalMax(value = "100.0", message = "Recall score must be <= 100.0")
    private Double recall;

    @NotNull(message = "Reasoning score is required")
    @DecimalMin(value = "0.0", message = "Reasoning score must be >= 0.0")
    @DecimalMax(value = "100.0", message = "Reasoning score must be <= 100.0")
    private Double reasoning;

    // Optional task & demographic features for Random Forest ML model inference (synthetic training experiment)
    @Min(value = 1, message = "Age must be >= 1")
    @Max(value = 130, message = "Age must be <= 130")
    private Integer age;

    @Min(value = 0, message = "Education years must be >= 0")
    @Max(value = 40, message = "Education years must be <= 40")
    private Integer educationYears;

    private Map<String, Double> accuracies;

    private Map<String, Double> responseTimes;

    private String sessionId;

    private Map<Integer, String> responses;

    private Map<Integer, Double> grades;

    public CognitiveAssessmentSubmissionRequest(
            Long residentId,
            Double memory,
            Double attention,
            Double orientation,
            Double recall,
            Double reasoning,
            Integer age,
            Integer educationYears,
            Map<String, Double> accuracies,
            Map<String, Double> responseTimes) {
        this.residentId = residentId;
        this.memory = memory;
        this.attention = attention;
        this.orientation = orientation;
        this.recall = recall;
        this.reasoning = reasoning;
        this.age = age;
        this.educationYears = educationYears;
        this.accuracies = accuracies;
        this.responseTimes = responseTimes;
    }

    public CognitiveAssessmentSubmissionRequest(
            Long residentId,
            Double memory,
            Double attention,
            Double orientation,
            Double recall,
            Double reasoning,
            Integer age,
            Integer educationYears,
            Map<String, Double> accuracies,
            Map<String, Double> responseTimes,
            String sessionId,
            Map<Integer, String> responses,
            Map<Integer, Double> grades) {
        this(residentId, memory, attention, orientation, recall, reasoning, age, educationYears, accuracies, responseTimes);
        this.sessionId = sessionId;
        this.responses = responses;
        this.grades = grades;
    }
}
