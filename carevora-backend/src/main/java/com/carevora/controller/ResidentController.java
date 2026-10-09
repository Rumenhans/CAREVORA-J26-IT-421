package com.carevora.controller;

import com.carevora.dto.ApiResponse;
import com.carevora.dto.resident.ResidentResponse;
import com.carevora.service.ResidentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/residents")
@RequiredArgsConstructor
@Tag(name = "Residents", description = "Resident management & profile endpoints")
public class ResidentController {

    private final ResidentService residentService;

    @GetMapping
    @Operation(summary = "Get list of all residents with optional search query")
    public ResponseEntity<ApiResponse<List<ResidentResponse>>> getResidents(
            @RequestParam(required = false) String search
    ) {
        return ResponseEntity.ok(residentService.getAllResidents(search));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get resident detailed wellness profile by ID")
    public ResponseEntity<ApiResponse<ResidentResponse>> getResidentById(@PathVariable Long id) {
        return ResponseEntity.ok(residentService.getResidentById(id));
    }
}
