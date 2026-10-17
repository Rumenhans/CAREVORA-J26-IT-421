package com.carevora.controller;

import com.carevora.dto.memorygame.MemoryGameSessionRequest;
import com.carevora.security.CustomUserDetailsService;
import com.carevora.security.JwtService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class MemoryGameIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JwtService jwtService;

    @Autowired
    private CustomUserDetailsService userDetailsService;

    @Autowired
    private ObjectMapper objectMapper;

    private String caregiverHome1Token;
    private String caregiverHome2Token;
    private String elderSarahToken;

    @BeforeEach
    void setUp() {
        UserDetails caregiverDetails = userDetailsService.loadUserByUsername("eleanor.vance@carevora.com");
        caregiverHome1Token = jwtService.generateToken(caregiverDetails);

        UserDetails caregiverOtherHomeDetails = userDetailsService.loadUserByUsername("david.silva@carevora.com");
        caregiverHome2Token = jwtService.generateToken(caregiverOtherHomeDetails);

        UserDetails elderDetails = userDetailsService.loadUserByUsername("sarah.jenkins@carevora.com");
        elderSarahToken = jwtService.generateToken(elderDetails);
    }

    @Test
    void testElderCanSaveTheirOwnCompletedGameSession() throws Exception {
        MemoryGameSessionRequest request = MemoryGameSessionRequest.builder()
                .residentId(1L) // Sarah Jenkins
                .gameType("SEQUENCE")
                .scorePercentage(100.0)
                .attempts(1)
                .correctAnswers(3)
                .totalItems(3)
                .status("COMPLETED")
                .completionDetailsJson("{\"level\": 1}")
                .build();

        mockMvc.perform(post("/api/memory-games/sessions")
                .header("Authorization", "Bearer " + elderSarahToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.gameType", is("SEQUENCE")))
                .andExpect(jsonPath("$.data.scorePercentage", is(100.0)))
                .andExpect(jsonPath("$.data.attempts", is(1)))
                .andExpect(jsonPath("$.data.correctAnswers", is(3)));
    }

    @Test
    void testIncompleteOrAbandonedSessionIsRejected() throws Exception {
        MemoryGameSessionRequest request = MemoryGameSessionRequest.builder()
                .residentId(1L)
                .gameType("PAIRS")
                .scorePercentage(50.0)
                .attempts(3)
                .correctAnswers(2)
                .totalItems(6)
                .status("ABANDONED") // Incomplete / abandoned
                .build();

        mockMvc.perform(post("/api/memory-games/sessions")
                .header("Authorization", "Bearer " + elderSarahToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.message", containsString("cannot be saved as completed")));
    }

    @Test
    void testCaregiverFromSameHomeCanAccessResidentProgress() throws Exception {
        mockMvc.perform(get("/api/memory-games/resident/1/progress")
                .header("Authorization", "Bearer " + caregiverHome1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.residentId", is(1)))
                .andExpect(jsonPath("$.data.residentName", is("Sarah Jenkins")));
    }

    @Test
    void testCaregiverFromDifferentHomeIsDeniedAccess() throws Exception {
        // David Silva from Home 2 trying to access Sarah Jenkins (Home 1)
        mockMvc.perform(get("/api/memory-games/resident/1/progress")
                .header("Authorization", "Bearer " + caregiverHome2Token))
                .andExpect(status().isForbidden());
    }

    @Test
    void testCaregiverFromSameHomeCanViewResidentSessions() throws Exception {
        mockMvc.perform(get("/api/memory-games/resident/1")
                .header("Authorization", "Bearer " + caregiverHome1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data", is(instanceOf(java.util.List.class))));
    }
}
