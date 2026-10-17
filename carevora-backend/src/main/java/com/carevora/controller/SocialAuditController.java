package com.carevora.controller;

import com.carevora.dto.ApiResponse;
import com.carevora.dto.socialaudit.SocialAuditRequest;
import com.carevora.dto.socialaudit.SocialAuditResponse;
import com.carevora.service.SocialAuditService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/residents/{residentId}/social-audits")
@RequiredArgsConstructor
@Tag(name = "Social Audits", description = "Endpoints for observational caregiver social audits and social-isolation assessments")
public class SocialAuditController {

    private final SocialAuditService socialAuditService;

    @PostMapping
    @PreAuthorize("hasAnyRole('CAREGIVER', 'DOCTOR', 'ADMIN')")
    @Operation(summary = "Submit an observational caregiver social audit for a resident")
    public ResponseEntity<ApiResponse<SocialAuditResponse>> createSocialAudit(
            @PathVariable Long residentId,
            @Valid @RequestBody SocialAuditRequest request,
            Authentication authentication
    ) {
        String authenticatedEmail = authentication != null ? authentication.getName() : null;
        return ResponseEntity.ok(socialAuditService.createSocialAudit(residentId, request, authenticatedEmail));
    }

    @GetMapping
    @Operation(summary = "Retrieve chronological caregiver social audit history for a resident")
    public ResponseEntity<ApiResponse<List<SocialAuditResponse>>> getAuditsByResident(
            @PathVariable Long residentId,
            Authentication authentication
    ) {
        String email = authentication != null ? authentication.getName() : null;
        return ResponseEntity.ok(socialAuditService.getAuditsByResident(residentId, email));
    }

    @GetMapping("/latest")
    @Operation(summary = "Retrieve the latest caregiver social audit record for a resident")
    public ResponseEntity<ApiResponse<SocialAuditResponse>> getLatestAudit(
            @PathVariable Long residentId,
            Authentication authentication
    ) {
        String email = authentication != null ? authentication.getName() : null;
        return ResponseEntity.ok(socialAuditService.getLatestAudit(residentId, email));
    }

    @GetMapping("/{auditId}")
    @Operation(summary = "Retrieve an individual caregiver social audit record by ID")
    public ResponseEntity<ApiResponse<SocialAuditResponse>> getAuditById(
            @PathVariable Long residentId,
            @PathVariable Long auditId
    ) {
        return ResponseEntity.ok(socialAuditService.getAuditById(residentId, auditId));
    }
}
