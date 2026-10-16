package com.carevora.dto.cognitive;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SaveCognitiveResponsesRequest {

    private Map<Integer, String> responses;
    private Map<Integer, Double> questionTimes;
    private String status;
    private Boolean autoFinalize;
}
