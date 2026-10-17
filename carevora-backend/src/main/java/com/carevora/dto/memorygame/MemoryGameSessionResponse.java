package com.carevora.dto.memorygame;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MemoryGameSessionResponse {
    private Long id;
    private String sessionId;
    private Long residentId;
    private String residentName;
    private String gameType;
    private Double scorePercentage;
    private Integer attempts;
    private Integer correctAnswers;
    private Integer totalItems;
    private String status;
    private String completionDetailsJson;
    private String playedBy;
    private LocalDateTime completedAt;
}
