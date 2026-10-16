package com.carevora.entity;

import com.carevora.enums.RiskLevel;
import com.carevora.enums.TrajectoryStatus;
import com.carevora.enums.WellnessStatus;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "assessments")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Assessment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "resident_id", nullable = false)
    private Resident resident;

    @Column(name = "overall_score", nullable = false)
    private Double overallScore;

    @Column(name = "emotional_score", nullable = false)
    private Double emotionalScore;

    @Column(name = "social_score")
    private Double socialScore;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 30)
    private WellnessStatus status;

    @Enumerated(EnumType.STRING)
    @Column(name = "risk_level", nullable = false, length = 30)
    private RiskLevel riskLevel;

    @Enumerated(EnumType.STRING)
    @Column(name = "trajectory", nullable = false, length = 30)
    private TrajectoryStatus trajectory;

    @Column(name = "encouraging_message", length = 500)
    private String encouragingMessage;

    @Column(name = "facial_check_included")
    @Builder.Default
    private Boolean facialCheckIncluded = false;

    @Column(name = "voice_check_included")
    @Builder.Default
    private Boolean voiceCheckIncluded = false;

    @OneToMany(mappedBy = "assessment", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<AssessmentAnswer> answers = new ArrayList<>();

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
