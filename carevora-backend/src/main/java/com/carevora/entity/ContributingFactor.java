package com.carevora.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "contributing_factors")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ContributingFactor {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assessment_id")
    private Assessment assessment;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "resident_id")
    private Resident resident;

    @Column(nullable = false, length = 100)
    private String title;

    @Column(nullable = false)
    private Double score; // 0.0 - 100.0

    @Column(length = 500)
    private String description;

    @Column(nullable = false, length = 50)
    private String category; // Facial, Voice, Social, Questionnaire
}
