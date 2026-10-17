package com.carevora.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "memory_game_sessions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class MemoryGameSession {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "session_id", length = 100, nullable = false, unique = true)
    private String sessionId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "resident_id", nullable = false)
    @JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
    private Resident resident;

    @Column(name = "game_type", length = 30, nullable = false)
    private String gameType; // SEQUENCE, PAIRS, ITEMS

    @Column(name = "score_percentage", nullable = false)
    private Double scorePercentage;

    @Column(name = "attempts", nullable = false)
    private Integer attempts;

    @Column(name = "correct_answers", nullable = false)
    private Integer correctAnswers;

    @Column(name = "total_items", nullable = false)
    private Integer totalItems;

    @Column(name = "status", length = 30, nullable = false)
    @Builder.Default
    private String status = "COMPLETED";

    @Column(name = "completion_details_json", length = 2000)
    private String completionDetailsJson;

    @Column(name = "played_by", length = 100)
    private String playedBy;

    @CreationTimestamp
    @Column(name = "completed_at", nullable = false, updatable = false)
    private LocalDateTime completedAt;
}
