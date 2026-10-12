package com.carevora.dto.auth;

import com.carevora.enums.UserRole;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LoginResponse {
    private String token;
    @Builder.Default
    private String type = "Bearer";
    private Long id;
    private String email;
    private String name;
    private UserRole role;
    private String avatarUrl;
    private Long residentId;
    private Long caregiverId;
    private Long elderHomeId;
    private String elderHomeName;
}
