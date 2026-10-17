package com.carevora.dto.memorygame;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MemoryGameSessionRequest {

    @NotNull(message = "Resident ID is required")
    private Long residentId;

    @NotBlank(message = "Game type is required (e.g. SEQUENCE, PAIRS, ITEMS)")
    private String gameType;

    @NotNull(message = "Score percentage is required")
    @Min(value = 0, message = "Score percentage cannot be negative")
    @Max(value = 100, message = "Score percentage cannot exceed 100.0")
    private Double scorePercentage;

    @NotNull(message = "Attempts count is required")
    @Min(value = 0, message = "Attempts cannot be negative")
    private Integer attempts;

    @NotNull(message = "Correct answers count is required")
    @Min(value = 0, message = "Correct answers cannot be negative")
    private Integer correctAnswers;

    @NotNull(message = "Total items count is required")
    @Min(value = 1, message = "Total items must be at least 1")
    private Integer totalItems;

    private String sessionId;

    @Builder.Default
    private String status = "COMPLETED";

    private String completionDetailsJson;
}
