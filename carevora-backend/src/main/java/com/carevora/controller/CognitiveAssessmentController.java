package com.carevora.controller;

import com.carevora.dto.ApiResponse;
import com.carevora.dto.cognitive.CognitiveAssessmentResponse;
import com.carevora.dto.cognitive.CognitiveAssessmentSubmissionRequest;
import com.carevora.service.CognitiveAssessmentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/cognitive/assessments")
@Tag(name = "Cognitive Assessments", description = "Endpoints for ACRF cognitive wellness scoring, submission, and history")
public class CognitiveAssessmentController {

    private final CognitiveAssessmentService cognitiveAssessmentService;

    public CognitiveAssessmentController(CognitiveAssessmentService cognitiveAssessmentService) {
        this.cognitiveAssessmentService = cognitiveAssessmentService;
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
