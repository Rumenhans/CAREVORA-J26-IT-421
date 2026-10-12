package com.carevora.dto.elderhome;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ElderHomeResponse {
    private Long id;
    private String name;
    private String facilityCode;
    private String address;
    private String contactEmail;
    private String contactPhone;
    private Boolean active;
    private long elderCount;
    private long caregiverCount;
    private LocalDateTime createdAt;
}
