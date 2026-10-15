package com.carevora.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "cognitive_assessment_sessions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CognitiveAssessmentSession {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "session_id", nullable = false, unique = true, length = 100)
    private String sessionId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "resident_id", nullable = false)
    private Resident resident;

    @Column(name = "status", nullable = false, length = 50)
    @Builder.Default
    private String status = "IN_PROGRESS"; // IN_PROGRESS, PENDING_CAREGIVER_REVIEW, COMPLETED

    @Column(name = "responses_json", length = 4000)
    private String responsesJson;

    @Column(name = "grades_json", length = 1000)
    private String gradesJson;

    @Column(name = "question_times_json", length = 1000)
    private String questionTimesJson;

    @Column(name = "initiated_by", length = 100)
    private String initiatedBy;

    @Column(name = "reviewed_by", length = 100)
    private String reviewedBy;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
