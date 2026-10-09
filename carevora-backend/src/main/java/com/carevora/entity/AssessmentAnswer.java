package com.carevora.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "assessment_answers")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AssessmentAnswer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assessment_id", nullable = false)
    private Assessment assessment;

    @Column(name = "question_id", nullable = false, length = 50)
    private String questionId;

    @Column(name = "selected_index", nullable = false)
    private Integer selectedIndex;

    @Column(name = "answer_text", length = 255)
    private String answerText;
}
