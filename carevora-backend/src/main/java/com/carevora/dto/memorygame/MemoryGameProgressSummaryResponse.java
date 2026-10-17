package com.carevora.dto.memorygame;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MemoryGameProgressSummaryResponse {
    private Long residentId;
    private String residentName;
    private int totalCompletedSessions;
    private LocalDateTime latestActivityDate;
    private Double latestSequenceScore;
    private Double latestPairsScore;
    private Double latestItemsScore;
    private Double averageScore;
    private String sequenceProgress; // IMPROVING, STEADY, NEEDS_PRACTICE, NO_DATA
    private String pairsProgress;
    private String itemsProgress;
    private String overallProgress;
    private boolean hasRepeatedDecline;
    private String caregiverNotice;
    private List<MemoryGameSessionResponse> sessions;
}
