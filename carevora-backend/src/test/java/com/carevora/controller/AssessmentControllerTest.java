package com.carevora.controller;

import com.carevora.dto.ApiResponse;
import com.carevora.dto.assessment.AssessmentResponse;
import com.carevora.dto.assessment.AssessmentSubmissionRequest;
import com.carevora.enums.RiskLevel;
import com.carevora.enums.TrajectoryStatus;
import com.carevora.enums.WellnessStatus;
import com.carevora.exception.BadRequestException;
import com.carevora.exception.GlobalExceptionHandler;
import com.carevora.service.AssessmentService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ExtendWith(MockitoExtension.class)
class AssessmentControllerTest {

    private MockMvc mockMvc;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Mock
    private AssessmentService assessmentService;

    @InjectMocks
    private AssessmentController assessmentController;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(assessmentController)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    private AssessmentSubmissionRequest validRequest() {
        return AssessmentSubmissionRequest.builder()
                .residentId(1L)
                .answers(List.of(0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
                .includeFacialCheck(true)
                .includeVoiceCheck(true)
                .facialScore(85.0)
                .vocalScore(78.0)
                .dominantEmotion("HAPPY")
                .facialConfidence(0.92)
                .build();
    }

    @Test
    @DisplayName("POST /api/assessments/submit with valid 10 answers returns 200 OK")
    void submitAssessment_validRequest_returns200() throws Exception {
        AssessmentResponse responseDto = AssessmentResponse.builder()
                .id(1L)
                .residentId(1L)
                .overallScore(100.0)
                .emotionalScore(100.0)
                .socialScore(80.0)
                .status(WellnessStatus.LOOKING_GOOD)
                .riskLevel(RiskLevel.LOW)
                .trajectory(TrajectoryStatus.STABLE)
                .encouragingMessage("You are doing wonderfully!")
                .timestamp(LocalDateTime.now())
                .contributingFactors(Collections.emptyList())
                .recommendations(Collections.emptyList())
                .build();

        when(assessmentService.submitAssessment(any(AssessmentSubmissionRequest.class)))
                .thenReturn(ApiResponse.ok(responseDto, "Assessment submitted successfully"));

        mockMvc.perform(post("/api/assessments/submit")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validRequest())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.overallScore").value(100.0))
                .andExpect(jsonPath("$.data.emotionalScore").value(100.0))
                .andExpect(jsonPath("$.data.residentId").value(1L));
    }

    @Test
    @DisplayName("POST /api/assessments/submit with fewer than 10 answers (e.g. 6) returns 400 Bad Request")
    void submitAssessment_incompleteAnswers_returns400() throws Exception {
        AssessmentSubmissionRequest incomplete = AssessmentSubmissionRequest.builder()
                .residentId(1L)
                .answers(List.of(0, 1, 0, 0, 1, 0)) // Only 6 answers
                .build();

        mockMvc.perform(post("/api/assessments/submit")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(incomplete)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("POST /api/assessments/submit with null answers returns 400 Bad Request")
    void submitAssessment_nullAnswers_returns400() throws Exception {
        AssessmentSubmissionRequest incomplete = AssessmentSubmissionRequest.builder()
                .residentId(1L)
                .answers(null)
                .build();

        mockMvc.perform(post("/api/assessments/submit")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(incomplete)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("POST /api/assessments/submit with null residentId returns 400 Bad Request")
    void submitAssessment_nullResidentId_returns400() throws Exception {
        AssessmentSubmissionRequest noResident = AssessmentSubmissionRequest.builder()
                .residentId(null)
                .answers(List.of(0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
                .build();

        mockMvc.perform(post("/api/assessments/submit")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(noResident)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("GET /api/assessments/resident/{residentId} returns 200 OK")
    void getResidentAssessments_returns200() throws Exception {
        when(assessmentService.getResidentAssessments(1L))
                .thenReturn(ApiResponse.ok(Collections.emptyList()));

        mockMvc.perform(get("/api/assessments/resident/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }
}
