package com.carevora.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "recommendations")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Recommendation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "resident_id", nullable = false)
    private Resident resident;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assessment_id")
    private Assessment assessment;

    @Column(nullable = false, length = 150)
    private String title;

    @Column(length = 500)
    private String reason;

    @Column(nullable = false, length = 20)
    @Builder.Default
    private String priority = "Low"; // Low, Medium, High

    @Column(name = "suggested_action", length = 500)
    private String suggestedAction;

    @Column(name = "icon_key", length = 50)
    @Builder.Default
    private String iconKey = "walk";

    @Column(nullable = false)
    @Builder.Default
    private Boolean active = true;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
