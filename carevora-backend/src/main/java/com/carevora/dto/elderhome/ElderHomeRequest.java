package com.carevora.dto.elderhome;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ElderHomeRequest {

    @NotBlank(message = "Elder home / facility name is required")
    private String name;

    private String facilityCode;
    private String address;
    private String contactEmail;
    private String contactPhone;
}
