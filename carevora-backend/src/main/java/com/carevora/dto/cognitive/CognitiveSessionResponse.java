package com.carevora.dto.cognitive;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CognitiveSessionResponse {

    private String sessionId;
    private Long residentId;
    private String residentName;
    private String status;
    private Map<Integer, String> responses;
    private Map<Integer, Double> grades;
    private Map<Integer, Double> questionTimes;
    private String initiatedBy;
    private String reviewedBy;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
