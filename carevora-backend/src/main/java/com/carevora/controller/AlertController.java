package com.carevora.controller;

import com.carevora.dto.ApiResponse;
import com.carevora.entity.Alert;
import com.carevora.service.AlertService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/alerts")
@RequiredArgsConstructor
@Tag(name = "Alerts", description = "Caregiver alerts & preventative action tracking")
public class AlertController {

    private final AlertService alertService;

    @GetMapping
    @Operation(summary = "Get all alerts sorted by timestamp descending")
    public ResponseEntity<ApiResponse<List<Alert>>> getAllAlerts() {
        return ResponseEntity.ok(alertService.getAllAlerts());
    }

    @PutMapping("/{id}/read")
    @Operation(summary = "Mark an alert as read")
    public ResponseEntity<ApiResponse<Alert>> markAsRead(@PathVariable Long id) {
        return ResponseEntity.ok(alertService.markAsRead(id));
    }
}
