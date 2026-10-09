package com.carevora.controller;

import com.carevora.dto.ApiResponse;
import com.carevora.dto.assessment.AssessmentResponse;
import com.carevora.dto.assessment.AssessmentSubmissionRequest;
import com.carevora.service.AssessmentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/assessments")
@RequiredArgsConstructor
@Tag(name = "Assessments", description = "Endpoints for multimodal daily wellness assessments")
public class AssessmentController {

    private final AssessmentService assessmentService;

    @PostMapping("/submit")
    @Operation(summary = "Submit a daily multimodal assessment")
    public ResponseEntity<ApiResponse<AssessmentResponse>> submitAssessment(
            @Valid @RequestBody AssessmentSubmissionRequest request
    ) {
        return ResponseEntity.ok(assessmentService.submitAssessment(request));
    }

    @GetMapping("/resident/{residentId}")
    @Operation(summary = "Get historical assessments for a resident")
    public ResponseEntity<ApiResponse<List<AssessmentResponse>>> getResidentAssessments(
            @PathVariable Long residentId
    ) {
        return ResponseEntity.ok(assessmentService.getResidentAssessments(residentId));
    }
}
