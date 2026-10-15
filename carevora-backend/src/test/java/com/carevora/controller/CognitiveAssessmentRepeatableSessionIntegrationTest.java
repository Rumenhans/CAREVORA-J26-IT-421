package com.carevora.controller;

import com.carevora.dto.cognitive.*;
import com.carevora.security.CustomUserDetailsService;
import com.carevora.security.JwtService;
import com.carevora.service.AiMlService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.test.web.servlet.MockMvc;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.hamcrest.Matchers.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class CognitiveAssessmentRepeatableSessionIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JwtService jwtService;

    @Autowired
    private CustomUserDetailsService userDetailsService;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private AiMlService aiMlService;

    private String caregiverHome1Token;
    private String caregiverHome2Token;

    @BeforeEach
    void setUp() {
        UserDetails caregiverDetails = userDetailsService.loadUserByUsername("eleanor.vance@carevora.com");
        caregiverHome1Token = jwtService.generateToken(caregiverDetails);

        UserDetails caregiverOtherHomeDetails = userDetailsService.loadUserByUsername("david.silva@carevora.com");
        caregiverHome2Token = jwtService.generateToken(caregiverOtherHomeDetails);

        CognitiveAiResult mockAiResult = CognitiveAiResult.builder()
                .acrfScore(85.5)
                .rawWeightedScore(85.5)
                .categoryContributions(List.of())
                .weightsApplied(Map.of("memory", 0.25, "attention", 0.20, "orientation", 0.20, "recall", 0.20, "reasoning", 0.15))
                .mlModelEvaluation(CognitiveAssessmentResponse.MlModelStatusDto.builder()
                        .available(true)
                        .modelType("RandomForestClassifier")
                        .prediction("Low Risk")
                        .statusMessage("Prediction available")
                        .alertTriggered(false)
                        .build())
                .methodology("ACRF Fixed Base Weights")
                .clinicalDisclaimer("The ACRF score is an arithmetic weighted wellness metric. Non-diagnostic.")
                .build();

        when(aiMlService.predictCognitive(any(), any(), any(), any(), any(), any(), any(), any(), any(), any()))
                .thenReturn(mockAiResult);
    }

    @Test
    void testFullRepeatableAssessmentLifecycle() throws Exception {
        // Sarah Jenkins is Resident ID 1 in Serene Valley (Home 1)
        Long residentId = 1L;

        // 1. Caregiver initiates a new assessment session
        StartCognitiveSessionRequest startReq = StartCognitiveSessionRequest.builder()
                .residentId(residentId)
                .build();

        String startResponse = mockMvc.perform(post("/api/cognitive/assessments/sessions/start")
                        .header("Authorization", "Bearer " + caregiverHome1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(startReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.sessionId").isNotEmpty())
                .andExpect(jsonPath("$.data.status").value("IN_PROGRESS"))
                .andExpect(jsonPath("$.data.residentId").value(residentId.intValue()))
                .andReturn().getResponse().getContentAsString();

        String sessionId1 = objectMapper.readTree(startResponse).path("data").path("sessionId").asText();

        // 2. Resident completes 10 questions and saves responses
        Map<Integer, String> answers1 = new HashMap<>();
        answers1.put(1, "Monday");
        answers1.put(2, "2026");
        answers1.put(3, "Sun, Book, Tree");
        answers1.put(4, "Sun, Book, Tree");
        answers1.put(5, "5");
        answers1.put(6, "8");
        answers1.put(7, "Sun, Book, Tree");
        answers1.put(8, "Yes");
        answers1.put(9, "Pen");
        answers1.put(10, "Yes, both are fruits");

        Map<Integer, Double> durations1 = new HashMap<>();
        for (int i = 1; i <= 10; i++) durations1.put(i, 3.5);

        SaveCognitiveResponsesRequest saveReq1 = SaveCognitiveResponsesRequest.builder()
                .responses(answers1)
                .questionTimes(durations1)
                .build();

        mockMvc.perform(post("/api/cognitive/assessments/sessions/" + sessionId1 + "/responses")
                        .header("Authorization", "Bearer " + caregiverHome1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(saveReq1)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.sessionId").value(sessionId1))
                .andExpect(jsonPath("$.data.status").value("PENDING_CAREGIVER_REVIEW"))
                .andExpect(jsonPath("$.data.responses.1").value("Monday"))
                .andExpect(jsonPath("$.data.responses.10").value("Yes, both are fruits"));

        // 3. Caregiver retrieves pending session from backend (survives refresh)
        mockMvc.perform(get("/api/cognitive/assessments/sessions/pending/resident/" + residentId)
                        .header("Authorization", "Bearer " + caregiverHome1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.sessionId").value(sessionId1))
                .andExpect(jsonPath("$.data.status").value("PENDING_CAREGIVER_REVIEW"))
                .andExpect(jsonPath("$.data.responses.1").value("Monday"));

        // 4. Caregiver grades the responses (including a legitimate 0.0 grade) and submits
        Map<Integer, Double> grades1 = new HashMap<>();
        for (int i = 1; i <= 9; i++) grades1.put(i, 1.0);
        grades1.put(10, 0.0); // Legitimate incorrect grade

        CognitiveAssessmentSubmissionRequest submitReq1 = CognitiveAssessmentSubmissionRequest.builder()
                .residentId(residentId)
                .sessionId(sessionId1)
                .memory(90.0)
                .attention(85.0)
                .orientation(100.0)
                .recall(80.0)
                .reasoning(50.0)
                .responses(answers1)
                .grades(grades1)
                .accuracies(Map.of("memory", 0.9, "attention", 0.85, "orientation", 1.0, "recall", 0.8, "reasoning", 0.5))
                .responseTimes(Map.of("memory", 3.5, "attention", 3.5, "orientation", 3.5, "recall", 3.5, "reasoning", 3.5))
                .build();

        mockMvc.perform(post("/api/cognitive/assessments/submit")
                        .header("Authorization", "Bearer " + caregiverHome1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(submitReq1)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.sessionId").value(sessionId1))
                .andExpect(jsonPath("$.data.status").value("COMPLETED"))
                .andExpect(jsonPath("$.data.grades.10").value(0.0))
                .andExpect(jsonPath("$.data.acrfScore").value(85.5));

        // 5. Duplicate submission for the same session is prevented
        mockMvc.perform(post("/api/cognitive/assessments/submit")
                        .header("Authorization", "Bearer " + caregiverHome1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(submitReq1)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value(containsString("Duplicate submission detected")));

        // 6. Caregiver initiates a SECOND genuinely new assessment session for the same resident
        StartCognitiveSessionRequest startReq2 = StartCognitiveSessionRequest.builder()
                .residentId(residentId)
                .build();

        String startResponse2 = mockMvc.perform(post("/api/cognitive/assessments/sessions/start")
                        .header("Authorization", "Bearer " + caregiverHome1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(startReq2)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.sessionId").isNotEmpty())
                .andReturn().getResponse().getContentAsString();

        String sessionId2 = objectMapper.readTree(startResponse2).path("data").path("sessionId").asText();
        org.junit.jupiter.api.Assertions.assertNotEquals(sessionId1, sessionId2);

        // 7. Complete and submit second assessment with distinct scores
        CognitiveAssessmentSubmissionRequest submitReq2 = CognitiveAssessmentSubmissionRequest.builder()
                .residentId(residentId)
                .sessionId(sessionId2)
                .memory(95.0)
                .attention(90.0)
                .orientation(100.0)
                .recall(90.0)
                .reasoning(80.0)
                .build();

        mockMvc.perform(post("/api/cognitive/assessments/submit")
                        .header("Authorization", "Bearer " + caregiverHome1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(submitReq2)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.sessionId").value(sessionId2));

        // 8. History retrieval: Returns multiple assessments, newest first
        mockMvc.perform(get("/api/cognitive/assessments/resident/" + residentId)
                        .header("Authorization", "Bearer " + caregiverHome1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data", hasSize(greaterThanOrEqualTo(2))))
                .andExpect(jsonPath("$.data[0].sessionId").value(sessionId2))
                .andExpect(jsonPath("$.data[1].sessionId").value(sessionId1));

        // 9. Records from different residents are isolated
        // Arthur Pendelton is Resident ID 2
        mockMvc.perform(get("/api/cognitive/assessments/resident/2")
                        .header("Authorization", "Bearer " + caregiverHome1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.sessionId == '" + sessionId1 + "')]").doesNotExist())
                .andExpect(jsonPath("$.data[?(@.sessionId == '" + sessionId2 + "')]").doesNotExist());

        // 10. Facility scoping: Caregiver from Home 2 cannot access Home 1 resident
        mockMvc.perform(get("/api/cognitive/assessments/resident/" + residentId)
                        .header("Authorization", "Bearer " + caregiverHome2Token))
                .andExpect(status().isForbidden());
    }
}
