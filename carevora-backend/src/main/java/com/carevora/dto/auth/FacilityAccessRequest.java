package com.carevora.dto.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FacilityAccessRequest {

    @NotBlank(message = "Full name is required")
    private String fullName;

    @NotBlank(message = "Work email address is required")
    @Email(message = "Please provide a valid work email address")
    private String workEmail;

    @NotBlank(message = "Care Home / Facility Name is required")
    private String facilityName;

    private String address;
    private String phone;
}
