package com.carevora.service;

import com.carevora.dto.ApiResponse;
import com.carevora.dto.auth.LoginRequest;
import com.carevora.dto.auth.LoginResponse;
import com.carevora.entity.Caregiver;
import com.carevora.entity.Resident;
import com.carevora.entity.User;
import com.carevora.repository.CaregiverRepository;
import com.carevora.repository.ResidentRepository;
import com.carevora.repository.UserRepository;
import com.carevora.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final ResidentRepository residentRepository;
    private final CaregiverRepository caregiverRepository;
    private final AuthenticationManager authenticationManager;
    private final UserDetailsService userDetailsService;
    private final JwtService jwtService;

    public ApiResponse<LoginResponse> login(LoginRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword())
        );

        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("User not found"));

        UserDetails userDetails = userDetailsService.loadUserByUsername(user.getEmail());
        String token = jwtService.generateToken(userDetails);

        Long residentId = residentRepository.findByUserId(user.getId()).map(Resident::getId).orElse(null);
        Long caregiverId = caregiverRepository.findByUserId(user.getId()).map(Caregiver::getId).orElse(null);

        LoginResponse response = LoginResponse.builder()
                .token(token)
                .id(user.getId())
                .email(user.getEmail())
                .name(user.getFullName())
                .role(user.getRole())
                .avatarUrl(user.getAvatarUrl())
                .residentId(residentId)
                .caregiverId(caregiverId)
                .build();

        return ApiResponse.ok(response, "Login successful");
    }
}
