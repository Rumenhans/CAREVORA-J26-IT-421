package com.carevora.dto.assessment;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.List;

@Data
public class AssessmentSubmissionRequest {
    @NotNull(message = "Resident ID is required")
    private Long residentId;

    @NotEmpty(message = "Answers cannot be empty")
    private List<Integer> answers;

    private Boolean includeFacialCheck = false;
    private Boolean includeVoiceCheck = false;
}
