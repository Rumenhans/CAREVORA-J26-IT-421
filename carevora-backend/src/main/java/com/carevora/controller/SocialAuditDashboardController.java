package com.carevora.controller;

import com.carevora.dto.ApiResponse;
import com.carevora.dto.socialaudit.ResidentAuditSummaryResponse;
import com.carevora.dto.socialaudit.SocialAuditDashboardSummary;
import com.carevora.service.SocialAuditService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/social-audits")
@RequiredArgsConstructor
@Tag(name = "Caregiver Social Audit Dashboard", description = "Endpoints for caregiver social audit dashboard, metrics, and resident directory search")
public class SocialAuditDashboardController {

    private final SocialAuditService socialAuditService;

    @GetMapping("/dashboard-summary")
    @PreAuthorize("hasAnyRole('CAREGIVER', 'DOCTOR', 'ADMIN')")
    @Operation(summary = "Get aggregated real metrics for caregiver social audit dashboard")
    public ResponseEntity<ApiResponse<SocialAuditDashboardSummary>> getDashboardSummary(
            Authentication authentication
    ) {
        String email = authentication != null ? authentication.getName() : null;
        return ResponseEntity.ok(socialAuditService.getDashboardSummary(email));
    }

    @GetMapping("/residents")
    @PreAuthorize("hasAnyRole('CAREGIVER', 'DOCTOR', 'ADMIN')")
    @Operation(summary = "Search residents with real-time caregiver social audit status")
    public ResponseEntity<ApiResponse<List<ResidentAuditSummaryResponse>>> getResidentsAuditSummary(
            @RequestParam(required = false) String search,
            Authentication authentication
    ) {
        String email = authentication != null ? authentication.getName() : null;
        return ResponseEntity.ok(socialAuditService.getResidentsAuditSummary(search, email));
    }
}
