package com.carevora.controller;

import com.carevora.dto.ApiResponse;
import com.carevora.dto.dashboard.DashboardSummaryResponse;
import com.carevora.service.DashboardService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
@Tag(name = "Dashboard", description = "Aggregated clinical metrics for Caregiver Web Dashboard")
public class DashboardController {

    private final DashboardService dashboardService;

    @GetMapping("/summary")
    @Operation(summary = "Get aggregated summary of facility residents, risk distribution, and urgent alerts")
    public ResponseEntity<ApiResponse<DashboardSummaryResponse>> getDashboardSummary() {
        return ResponseEntity.ok(dashboardService.getSummary());
    }
}
