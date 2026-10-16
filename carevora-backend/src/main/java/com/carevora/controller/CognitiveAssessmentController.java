package com.carevora.controller;

import com.carevora.dto.ApiResponse;
import com.carevora.dto.cognitive.CognitiveAssessmentResponse;
import com.carevora.dto.cognitive.CognitiveAssessmentSubmissionRequest;
import com.carevora.dto.cognitive.CognitiveSessionResponse;
import com.carevora.dto.cognitive.SaveCognitiveResponsesRequest;
import com.carevora.dto.cognitive.StartCognitiveSessionRequest;
import com.carevora.service.CognitiveAssessmentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/cognitive/assessments")
@Tag(name = "Cognitive Assessments", description = "Endpoints for ACRF cognitive wellness scoring, submission, sessions, and history")
public class CognitiveAssessmentController {

    private final CognitiveAssessmentService cognitiveAssessmentService;

    public CognitiveAssessmentController(CognitiveAssessmentService cognitiveAssessmentService) {
        this.cognitiveAssessmentService = cognitiveAssessmentService;
    }

    @PostMapping("/sessions/start")
    @Operation(summary = "Initiate a new repeatable cognitive assessment session for a resident")
    public ResponseEntity<ApiResponse<CognitiveSessionResponse>> startSession(
            @Valid @RequestBody StartCognitiveSessionRequest request
    ) {
        return ResponseEntity.ok(cognitiveAssessmentService.startSession(request));
    }

    @PostMapping("/sessions/{sessionId}/responses")
    @Operation(summary = "Save resident responses for a session and transition to Pending Caregiver Review")
    public ResponseEntity<ApiResponse<CognitiveSessionResponse>> saveResponses(
            @PathVariable String sessionId,
            @Valid @RequestBody SaveCognitiveResponsesRequest request
    ) {
        return ResponseEntity.ok(cognitiveAssessmentService.saveResponses(sessionId, request));
    }

    @GetMapping("/sessions/pending/resident/{residentId}")
    @Operation(summary = "Get current pending session and answers for caregiver review")
    public ResponseEntity<ApiResponse<CognitiveSessionResponse>> getPendingSession(
            @PathVariable Long residentId
    ) {
        return ResponseEntity.ok(cognitiveAssessmentService.getPendingSession(residentId));
    }

    @PostMapping("/submit")
    @Operation(summary = "Submit category scores for ACRF cognitive wellness evaluation and persistence")
    public ResponseEntity<ApiResponse<CognitiveAssessmentResponse>> submitAssessment(
            @Valid @RequestBody CognitiveAssessmentSubmissionRequest request
    ) {
        return ResponseEntity.ok(cognitiveAssessmentService.submitAssessment(request));
    }

    @GetMapping("/resident/{residentId}")
    @Operation(summary = "Get historical cognitive assessments for a specific resident")
    public ResponseEntity<ApiResponse<List<CognitiveAssessmentResponse>>> getResidentCognitiveAssessments(
            @PathVariable Long residentId
    ) {
        return ResponseEntity.ok(cognitiveAssessmentService.getResidentCognitiveAssessments(residentId));
    }
}
