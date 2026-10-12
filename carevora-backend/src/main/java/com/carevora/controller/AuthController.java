package com.carevora.controller;

import com.carevora.dto.ApiResponse;
import com.carevora.dto.auth.FacilityAccessRequest;
import com.carevora.dto.auth.LoginRequest;
import com.carevora.dto.auth.LoginResponse;
import com.carevora.dto.auth.RegisterRequest;
import com.carevora.dto.elderhome.ElderHomeResponse;
import com.carevora.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@Tag(name = "Authentication & Onboarding", description = "Endpoints for Elder, Caregiver, Doctor auth and elder home onboarding")
public class AuthController {

    private final AuthService authService;

    @PostMapping("/login")
    @Operation(summary = "Login with email and password")
    public ResponseEntity<ApiResponse<LoginResponse>> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    @PostMapping("/register")
    @Operation(summary = "Register a new user (Caregiver, Elder, Doctor) with elder home selection")
    public ResponseEntity<ApiResponse<LoginResponse>> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.ok(authService.register(request));
    }

    @PostMapping("/facility-request")
    @Operation(summary = "Onboard and register an elder care facility community (Request Facility Access modal)")
    public ResponseEntity<ApiResponse<ElderHomeResponse>> requestFacilityAccess(@Valid @RequestBody FacilityAccessRequest request) {
        return ResponseEntity.ok(authService.requestFacilityAccess(request));
    }

    @GetMapping("/me")
    @Operation(summary = "Get current authenticated user's profile and assigned elder home")
    public ResponseEntity<ApiResponse<LoginResponse>> getCurrentUser() {
        return ResponseEntity.ok(authService.getCurrentUserProfile());
    }
}
