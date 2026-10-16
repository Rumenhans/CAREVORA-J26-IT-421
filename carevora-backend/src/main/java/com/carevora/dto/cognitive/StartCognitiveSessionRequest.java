package com.carevora.dto.cognitive;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StartCognitiveSessionRequest {

    @NotNull(message = "Resident ID is required")
    private Long residentId;
}
