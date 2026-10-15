package com.carevora.controller;

import com.carevora.dto.ApiResponse;
import com.carevora.dto.auth.LoginRequest;
import com.carevora.dto.auth.LoginResponse;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class EmotionalWellnessIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    private String obtainToken(String email, String password) throws Exception {
        LoginRequest req = new LoginRequest();
        req.setEmail(email);
        req.setPassword(password);

        MvcResult result = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andReturn();

        String json = result.getResponse().getContentAsString();
        ApiResponse<?> apiResponse = objectMapper.readValue(json, ApiResponse.class);
        LoginResponse loginResp = objectMapper.convertValue(apiResponse.getData(), LoginResponse.class);
        return loginResp.getToken();
    }

    @Test
    @DisplayName("Doctor can view all residents across all elder homes")
    void doctorCanViewAllResidents() throws Exception {
        String token = obtainToken("dr.reed@carevora.com", "doctor123");

        mockMvc.perform(get("/api/residents")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(greaterThanOrEqualTo(4))));
    }

    @Test
    @DisplayName("Caregiver 1 is restricted to Home 1 (Serene Valley) residents")
    void caregiverRestrictedToAssignedHome() throws Exception {
        String token = obtainToken("eleanor.vance@carevora.com", "carevora_admin");

        mockMvc.perform(get("/api/residents")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(2)))
                .andExpect(jsonPath("$.data[0].elderHomeName", is("Serene Valley Senior Living")))
                .andExpect(jsonPath("$.data[1].elderHomeName", is("Serene Valley Senior Living")));
    }

    @Test
    @DisplayName("Caregiver is forbidden (403) from accessing resident belonging to another home")
    void caregiverDeniedAccessToOtherHomeResident() throws Exception {
        String token = obtainToken("eleanor.vance@carevora.com", "carevora_admin");

        // Resident 3 belongs to Golden Sunset (Home 2)
        mockMvc.perform(get("/api/residents/3")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Elder is restricted to self-profile and forbidden from viewing other elders")
    void elderAccessIsolation() throws Exception {
        String token = obtainToken("sarah.jenkins@carevora.com", "carevora123");

        // Elder can access self (resident ID 1)
        mockMvc.perform(get("/api/residents/1")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name", is("Sarah Jenkins")));

        // Elder is blocked from accessing another resident (ID 2)
        mockMvc.perform(get("/api/residents/2")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Submit assessment and verify persistence in database with valid 10-item answers")
    void submitAssessmentAndVerifyPersistence() throws Exception {
        String token = obtainToken("dr.reed@carevora.com", "doctor123");

        String payload = """
                {
                    "residentId": 1,
                    "answers": [0, 1, 0, 0, 1, 0, 0, 1, 0, 0],
                    "includeFacialCheck": true,
                    "includeVoiceCheck": true
                }
                """;

        mockMvc.perform(post("/api/assessments/submit")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.residentId", is(1)))
                .andExpect(jsonPath("$.data.overallScore", is(70.0)))
                .andExpect(jsonPath("$.data.emotionalScore", is(70.0)))
                .andExpect(jsonPath("$.data.contributingFactors", hasSize(3)))
                .andExpect(jsonPath("$.data.recommendations", hasSize(greaterThanOrEqualTo(1))));

        // Retrieve historical assessments for resident 1
        mockMvc.perform(get("/api/assessments/resident/1")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(greaterThanOrEqualTo(2))));
    }

    @Test
    @DisplayName("Submit assessment with all favorable answers (all 0s) yields 100.0 wellness")
    void submitAssessmentAllFavorableYields100() throws Exception {
        String token = obtainToken("dr.reed@carevora.com", "doctor123");

        String payload = """
                {
                    "residentId": 1,
                    "answers": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                    "includeFacialCheck": false,
                    "includeVoiceCheck": false
                }
                """;

        mockMvc.perform(post("/api/assessments/submit")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.overallScore", is(100.0)))
                .andExpect(jsonPath("$.data.emotionalScore", is(100.0)))
                .andExpect(jsonPath("$.data.riskLevel", is("LOW")))
                .andExpect(jsonPath("$.data.status", is("LOOKING_GOOD")));
    }

    @Test
    @DisplayName("Submit assessment with all adverse answers (all 1s) yields 0.0 wellness")
    void submitAssessmentAllAdverseYields0() throws Exception {
        String token = obtainToken("dr.reed@carevora.com", "doctor123");

        String payload = """
                {
                    "residentId": 1,
                    "answers": [1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
                    "includeFacialCheck": false,
                    "includeVoiceCheck": false
                }
                """;

        mockMvc.perform(post("/api/assessments/submit")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.overallScore", is(0.0)))
                .andExpect(jsonPath("$.data.emotionalScore", is(0.0)))
                .andExpect(jsonPath("$.data.riskLevel", is("HIGH")))
                .andExpect(jsonPath("$.data.status", is("NEEDS_ATTENTION")));
    }

    @Test
    @DisplayName("Submit assessment with fewer than 10 answers rejected with 400 Bad Request")
    void submitAssessmentFewerAnswersRejected() throws Exception {
        String token = obtainToken("dr.reed@carevora.com", "doctor123");

        String payload = """
                {
                    "residentId": 1,
                    "answers": [0, 1, 0, 1]
                }
                """;

        mockMvc.perform(post("/api/assessments/submit")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("Submit assessment with invalid non-binary answers rejected with 400 Bad Request")
    void submitAssessmentNonBinaryAnswersRejected() throws Exception {
        String token = obtainToken("dr.reed@carevora.com", "doctor123");

        String payload = """
                {
                    "residentId": 1,
                    "answers": [0, 2, 0, 1, 0, 0, 1, 0, 0, 0]
                }
                """;

        mockMvc.perform(post("/api/assessments/submit")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isBadRequest());
    }
}
