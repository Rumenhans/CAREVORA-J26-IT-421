package com.carevora.controller;

import com.carevora.dto.ApiResponse;
import com.carevora.service.AiMlService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/ai")
@RequiredArgsConstructor
@Tag(name = "AI/ML Integration", description = "Endpoints connecting future ML models and RALPA algorithms")
public class AiMlController {

    private final AiMlService aiMlService;

    @GetMapping("/trajectory/{residentId}")
    @Operation(summary = "Get RALPA predicted trajectory for resident")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getTrajectory(@PathVariable Long residentId) {
        return ResponseEntity.ok(aiMlService.predictTrajectory(residentId));
    }
}
