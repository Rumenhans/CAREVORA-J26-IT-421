package com.carevora.controller;

import com.carevora.dto.ApiResponse;
import com.carevora.dto.memorygame.MemoryGameProgressSummaryResponse;
import com.carevora.dto.memorygame.MemoryGameSessionRequest;
import com.carevora.dto.memorygame.MemoryGameSessionResponse;
import com.carevora.service.MemoryGameService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/memory-games")
@RequiredArgsConstructor
@Tag(name = "Memory Games", description = "Endpoints for memory game session persistence and progress monitoring")
public class MemoryGameController {

    private final MemoryGameService memoryGameService;

    @PostMapping("/sessions")
    @Operation(summary = "Persist a completed memory game session")
    public ResponseEntity<ApiResponse<MemoryGameSessionResponse>> saveGameSession(
            @Valid @RequestBody MemoryGameSessionRequest request
    ) {
        return ResponseEntity.ok(memoryGameService.saveGameSession(request));
    }

    @GetMapping("/resident/{residentId}")
    @Operation(summary = "Get historical completed memory game sessions for a resident")
    public ResponseEntity<ApiResponse<List<MemoryGameSessionResponse>>> getResidentGameSessions(
            @PathVariable Long residentId
    ) {
        return ResponseEntity.ok(memoryGameService.getResidentGameSessions(residentId));
    }

    @GetMapping("/resident/{residentId}/progress")
    @Operation(summary = "Get memory game progress summary and trends for a resident")
    public ResponseEntity<ApiResponse<MemoryGameProgressSummaryResponse>> getResidentGameProgress(
            @PathVariable Long residentId
    ) {
        return ResponseEntity.ok(memoryGameService.getResidentGameProgress(residentId));
    }
}
