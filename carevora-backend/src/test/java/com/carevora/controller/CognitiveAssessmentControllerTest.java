package com.carevora.controller;

import com.carevora.dto.ApiResponse;
import com.carevora.dto.cognitive.CognitiveAssessmentResponse;
import com.carevora.dto.cognitive.CognitiveAssessmentSubmissionRequest;
import com.carevora.exception.AiServiceException;
import com.carevora.exception.GlobalExceptionHandler;
import com.carevora.exception.ResourceNotFoundException;
import com.carevora.service.CognitiveAssessmentService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.time.LocalDateTime;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ExtendWith(MockitoExtension.class)
class CognitiveAssessmentControllerTest {

    private MockMvc mockMvc;

    private ObjectMapper objectMapper = new ObjectMapper();

    @Mock
    private CognitiveAssessmentService cognitiveAssessmentService;

    @InjectMocks
    private CognitiveAssessmentController cognitiveAssessmentController;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(cognitiveAssessmentController)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    private CognitiveAssessmentSubmissionRequest validRequest() {
        return CognitiveAssessmentSubmissionRequest.builder()
                .residentId(1L)
                .memory(85.0)
                .attention(80.0)
                .orientation(90.0)
                .recall(75.0)
                .reasoning(80.0)
                .build();
    }

    private CognitiveAssessmentResponse validResponse() {
        return CognitiveAssessmentResponse.builder()
                .id(10L)
                .residentId(1L)
                .residentName("Sarah Jenkins")
                .acrfScore(82.5)
                .memory(85.0)
                .attention(80.0)
                .orientation(90.0)
                .recall(75.0)
                .reasoning(80.0)
                .assessedBy("Dr. John")
                .createdAt(LocalDateTime.now())
                .mlModelEvaluation(CognitiveAssessmentResponse.MlModelStatusDto.builder()
                        .available(false)
                        .modelType("RandomForestClassifier")
                        .statusMessage("Pending clinical dataset training")
                        .build())
                .build();
    }

    @Test
    void testSubmitAssessment_Success() throws Exception {
        when(cognitiveAssessmentService.submitAssessment(any(CognitiveAssessmentSubmissionRequest.class)))
                .thenReturn(ApiResponse.ok(validResponse(), "Cognitive assessment recorded successfully"));

        mockMvc.perform(post("/api/cognitive/assessments/submit")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validRequest())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(10))
                .andExpect(jsonPath("$.data.acrfScore").value(82.5))
                .andExpect(jsonPath("$.data.mlModelEvaluation.available").value(false));
    }

    @Test
    void testSubmitAssessment_ValidationError_NullResidentId() throws Exception {
        CognitiveAssessmentSubmissionRequest req = validRequest();
        req.setResidentId(null);

        mockMvc.perform(post("/api/cognitive/assessments/submit")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("VALIDATION_ERROR"))
                .andExpect(jsonPath("$.data.residentId").exists());
    }

    @Test
    void testSubmitAssessment_ValidationError_ScoreOutOfRange() throws Exception {
        CognitiveAssessmentSubmissionRequest req = validRequest();
        req.setMemory(105.0); // exceeds 100.0

        mockMvc.perform(post("/api/cognitive/assessments/submit")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("VALIDATION_ERROR"))
                .andExpect(jsonPath("$.data.memory").exists());
    }

    @Test
    void testSubmitAssessment_AiServiceUnavailable_Returns503() throws Exception {
        when(cognitiveAssessmentService.submitAssessment(any(CognitiveAssessmentSubmissionRequest.class)))
                .thenThrow(new AiServiceException("AI microservice unreachable"));

        mockMvc.perform(post("/api/cognitive/assessments/submit")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validRequest())))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("AI_SERVICE_UNAVAILABLE"));
    }

    @Test
    void testSubmitAssessment_AccessDenied_Returns403() throws Exception {
        when(cognitiveAssessmentService.submitAssessment(any(CognitiveAssessmentSubmissionRequest.class)))
                .thenThrow(new AccessDeniedException("Access denied"));

        mockMvc.perform(post("/api/cognitive/assessments/submit")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validRequest())))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("ACCESS_DENIED"));
    }

    @Test
    void testGetResidentAssessments_Success() throws Exception {
        when(cognitiveAssessmentService.getResidentCognitiveAssessments(1L))
                .thenReturn(ApiResponse.ok(List.of(validResponse())));

        mockMvc.perform(get("/api/cognitive/assessments/resident/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].id").value(10))
                .andExpect(jsonPath("$.data[0].residentId").value(1));
    }

    @Test
    void testGetResidentAssessments_NotFound_Returns404() throws Exception {
        when(cognitiveAssessmentService.getResidentCognitiveAssessments(999L))
                .thenThrow(new ResourceNotFoundException("Resident not found with id: 999"));

        mockMvc.perform(get("/api/cognitive/assessments/resident/999"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("RESOURCE_NOT_FOUND"));
    }

    @Test
    void testSubmitAssessment_WithOptionalMlFeatures_Success() throws Exception {
        CognitiveAssessmentSubmissionRequest req = validRequest();
        req.setAge(78);
        req.setEducationYears(14);
        req.setAccuracies(java.util.Map.of("memory", 0.9, "attention", 0.85, "orientation", 0.95, "recall", 0.8, "reasoning", 0.85));
        req.setResponseTimes(java.util.Map.of("memory", 4.2, "attention", 3.5, "orientation", 2.9, "recall", 5.0, "reasoning", 6.1));

        CognitiveAssessmentResponse resp = validResponse();
        resp.setMlPrediction("Moderate");
        resp.setAlertTriggered(false);

        when(cognitiveAssessmentService.submitAssessment(any(CognitiveAssessmentSubmissionRequest.class)))
                .thenReturn(ApiResponse.ok(resp, "Assessment submitted"));

        mockMvc.perform(post("/api/cognitive/assessments/submit")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.mlPrediction").value("Moderate"));
    }

    @Test
    void testSubmitAssessment_ValidationError_EducationYearsExceedsMax() throws Exception {
        CognitiveAssessmentSubmissionRequest req = validRequest();
        req.setEducationYears(45); // Max is 40

        mockMvc.perform(post("/api/cognitive/assessments/submit")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("VALIDATION_ERROR"))
                .andExpect(jsonPath("$.data.educationYears").exists());
    }

    @Test
    void testSubmitAssessment_ValidationError_AgeExceedsMax() throws Exception {
        CognitiveAssessmentSubmissionRequest req = validRequest();
        req.setAge(140); // Max is 130

        mockMvc.perform(post("/api/cognitive/assessments/submit")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("VALIDATION_ERROR"))
                .andExpect(jsonPath("$.data.age").exists());
    }
}
