package com.carevora.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "cognitive_assessments")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CognitiveAssessment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "resident_id", nullable = false)
    private Resident resident;

    @Column(name = "memory_score", nullable = false)
    private Double memoryScore;

    @Column(name = "attention_score", nullable = false)
    private Double attentionScore;

    @Column(name = "orientation_score", nullable = false)
    private Double orientationScore;

    @Column(name = "recall_score", nullable = false)
    private Double recallScore;

    @Column(name = "reasoning_score", nullable = false)
    private Double reasoningScore;

    @Column(name = "acrf_score", nullable = false)
    private Double acrfScore;

    @Column(name = "assessed_by", length = 100)
    private String assessedBy;

    @Column(name = "ml_available")
    @Builder.Default
    private Boolean mlAvailable = false;

    @Column(name = "ml_prediction", length = 50)
    private String mlPrediction;

    @Column(name = "alert_triggered")
    @Builder.Default
    private Boolean alertTriggered = false;

    @Column(name = "high_risk_probability")
    private Double highRiskProbability;

    @Column(name = "class_probabilities", length = 255)
    private String classProbabilities;

    @Column(name = "session_id", length = 100)
    private String sessionId;

    @Column(name = "status", length = 50)
    @Builder.Default
    private String status = "COMPLETED";

    @Column(name = "responses_json", length = 4000)
    private String responsesJson;

    @Column(name = "grades_json", length = 1000)
    private String gradesJson;

    @Column(name = "accuracies_json", length = 1000)
    private String accuraciesJson;

    @Column(name = "response_times_json", length = 1000)
    private String responseTimesJson;

    public boolean isMlPredictionAvailable() {
        return Boolean.TRUE.equals(this.mlAvailable);
    }

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
