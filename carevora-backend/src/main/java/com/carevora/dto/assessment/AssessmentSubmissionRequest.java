package com.carevora.dto.assessment;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AssessmentSubmissionRequest {
    @NotNull(message = "Resident ID is required")
    private Long residentId;

    @NotNull(message = "Answers cannot be empty")
    @Size(min = 10, max = 10, message = "Exactly 10 questionnaire answers are required")
    private List<Integer> answers;

    @Builder.Default
    private Boolean includeFacialCheck = false;

    @Builder.Default
    private Boolean includeVoiceCheck = false;
}
