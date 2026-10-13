package com.carevora.controller;

import com.carevora.dto.cognitive.CognitiveAiResult;
import com.carevora.dto.cognitive.CognitiveAssessmentResponse;
import com.carevora.dto.cognitive.CognitiveAssessmentSubmissionRequest;
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

import java.util.List;
import java.util.Map;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class CognitiveAssessmentSecurityIntegrationTest {

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

    private String caregiverToken;
    private String caregiverOtherHomeToken;
    private String elderToken;

    @BeforeEach
    void setUp() {
        UserDetails caregiverDetails = userDetailsService.loadUserByUsername("eleanor.vance@carevora.com");
        caregiverToken = jwtService.generateToken(caregiverDetails);

        UserDetails caregiverOtherHomeDetails = userDetailsService.loadUserByUsername("david.silva@carevora.com");
        caregiverOtherHomeToken = jwtService.generateToken(caregiverOtherHomeDetails);

        UserDetails elderDetails = userDetailsService.loadUserByUsername("sarah.jenkins@carevora.com");
        elderToken = jwtService.generateToken(elderDetails);

        CognitiveAiResult mockAi = CognitiveAiResult.builder()
                .acrfScore(82.0)
                .rawWeightedScore(82.0)
                .scale("0-100")
                .scoringDirection("Higher is better")
                .weightsApplied(Map.of("memory", 0.25, "attention", 0.20, "orientation", 0.20, "recall", 0.20, "reasoning", 0.15))
                .categoryScores(Map.of("memory", 80.0, "attention", 85.0, "orientation", 90.0, "recall", 75.0, "reasoning", 80.0))
                .categoryContributions(List.of(
                        CognitiveAssessmentResponse.CategoryContributionDto.builder().category("memory").score(80.0).weight(0.25).contribution(20.0).weightPercentage("25%").build()
                ))
                .mlModelEvaluation(CognitiveAssessmentResponse.MlModelStatusDto.builder().available(false).modelType("RandomForestClassifier").build())
                .methodology("ACRF Fixed Base Weights")
                .clinicalDisclaimer("Non-diagnostic wellness metric")
                .build();
        when(aiMlService.predictCognitive(any(), any(), any(), any(), any(), any())).thenReturn(mockAi);
        when(aiMlService.predictCognitive(any(), any(), any(), any(), any(), any(), any(), any(), any(), any())).thenReturn(mockAi);
    }

    private CognitiveAssessmentSubmissionRequest validRequest(Long residentId) {
        return CognitiveAssessmentSubmissionRequest.builder()
                .residentId(residentId)
                .memory(80.0)
                .attention(85.0)
                .orientation(90.0)
                .recall(75.0)
                .reasoning(80.0)
                .build();
    }

    @Test
    void testUnauthenticated_GetHistory_Returns401Unauthorized() throws Exception {
        mockMvc.perform(get("/api/cognitive/assessments/resident/1"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("UNAUTHORIZED"));
    }

    @Test
    void testUnauthenticated_Submit_Returns401Unauthorized() throws Exception {
        mockMvc.perform(post("/api/cognitive/assessments/submit")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validRequest(1L))))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("UNAUTHORIZED"));
    }

    @Test
    void testAuthorized_CaregiverSameHome_GetHistory_Returns200() throws Exception {
        mockMvc.perform(get("/api/cognitive/assessments/resident/1")
                        .header("Authorization", "Bearer " + caregiverToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void testAuthorized_CaregiverSameHome_Submit_Returns200() throws Exception {
        mockMvc.perform(post("/api/cognitive/assessments/submit")
                        .header("Authorization", "Bearer " + caregiverToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validRequest(1L))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.residentId").value(1))
                .andExpect(jsonPath("$.data.acrfScore").value(82.0));
    }

    @Test
    void testUnauthorized_CaregiverDifferentHome_GetHistory_Returns403() throws Exception {
        // David Silva (Home 2) trying to access Sarah Jenkins (Home 1)
        mockMvc.perform(get("/api/cognitive/assessments/resident/1")
                        .header("Authorization", "Bearer " + caregiverOtherHomeToken))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("ACCESS_DENIED"));
    }

    @Test
    void testUnauthorized_ElderAccessingOtherElder_Returns403() throws Exception {
        // Sarah Jenkins (Resident 1) trying to access Arthur Pendelton (Resident 2)
        mockMvc.perform(get("/api/cognitive/assessments/resident/2")
                        .header("Authorization", "Bearer " + elderToken))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("ACCESS_DENIED"));
    }

    @Test
    void testAuthorized_ElderAccessingOwnRecord_Returns200() throws Exception {
        mockMvc.perform(get("/api/cognitive/assessments/resident/1")
                        .header("Authorization", "Bearer " + elderToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }
}
