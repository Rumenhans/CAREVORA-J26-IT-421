package com.carevora.controller;

import com.carevora.dto.ApiResponse;
import com.carevora.dto.socialaudit.SocialAuditRequest;
import com.carevora.dto.socialaudit.SocialAuditResponse;
import com.carevora.enums.ActivityParticipationLevel;
import com.carevora.enums.AloneTimeContext;
import com.carevora.enums.PeerInteractionLevel;
import com.carevora.exception.GlobalExceptionHandler;
import com.carevora.service.SocialAuditService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ExtendWith(MockitoExtension.class)
class SocialAuditControllerTest {

    private MockMvc mockMvc;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Mock
    private SocialAuditService socialAuditService;

    @InjectMocks
    private SocialAuditController socialAuditController;

    private Authentication mockAuth;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(socialAuditController)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();

        mockAuth = new UsernamePasswordAuthenticationToken(
                "caregiver@carevora.com",
                "password",
                Collections.emptyList()
        );
    }

    private SocialAuditRequest validRequest() {
        return SocialAuditRequest.builder()
                .reportingPeriodDays(7)
                .familyInPersonVisits(2)
                .familyPhoneVideoContacts(3)
                .externalContactUnknown(false)
                .peerInteractionLevel(PeerInteractionLevel.OFTEN)
                .activitiesAvailable(4)
                .activitiesAttended(3)
                .activityParticipationLevel(ActivityParticipationLevel.ACTIVE_ENGAGEMENT)
                .healthMobilityBarriers(false)
                .estimatedHoursAlonePerDay(5.0)
                .aloneTimeContext(AloneTimeContext.CHOSEN_SOLITUDE)
                .caregiverNotes("Comfortable and sociable.")
                .build();
    }

    private SocialAuditResponse sampleResponse() {
        return SocialAuditResponse.builder()
                .id(1L)
                .residentId(1L)
                .residentName("James Perera")
                .caregiverUserId(20L)
                .caregiverName("David Silva")
                .caregiverStaffCode("CG-9021")
                .auditDate(LocalDateTime.now())
                .reportingPeriodDays(7)
                .familyInPersonVisits(2)
                .familyPhoneVideoContacts(3)
                .totalExternalContacts(5)
                .peerInteractionLevel(PeerInteractionLevel.OFTEN)
                .activitiesAvailable(4)
                .activitiesAttended(3)
                .activityParticipationRate(75.0)
                .activityParticipationLevel(ActivityParticipationLevel.ACTIVE_ENGAGEMENT)
                .healthMobilityBarriers(false)
                .estimatedHoursAlonePerDay(5.0)
                .aloneTimeContext(AloneTimeContext.CHOSEN_SOLITUDE)
                .caregiverNotes("Comfortable and sociable.")
                .socialScore(82.5)
                .scoreProvenance("CAREVORA-OBS-SOC-V1: Domains[ExternalContact(5), PeerInteraction(OFTEN)]")
                .build();
    }

    @Test
    @DisplayName("POST /api/residents/{residentId}/social-audits succeeds with HTTP 200 and audit response")
    void createSocialAudit_returnsOk() throws Exception {
        when(socialAuditService.createSocialAudit(eq(1L), any(SocialAuditRequest.class), any()))
                .thenReturn(ApiResponse.ok(sampleResponse(), "Caregiver social audit recorded successfully"));

        mockMvc.perform(post("/api/residents/1/social-audits")
                        .principal(mockAuth)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validRequest())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(1))
                .andExpect(jsonPath("$.data.socialScore").value(82.5))
                .andExpect(jsonPath("$.data.residentName").value("James Perera"));
    }

    @Test
    @DisplayName("POST /api/residents/{residentId}/social-audits rejects invalid negative counts with 400")
    void createSocialAudit_rejectsNegativeValues() throws Exception {
        SocialAuditRequest invalidReq = validRequest();
        invalidReq.setFamilyInPersonVisits(-3); // Negative visits not allowed

        mockMvc.perform(post("/api/residents/1/social-audits")
                        .principal(mockAuth)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalidReq)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    @DisplayName("GET /api/residents/{residentId}/social-audits returns list of audits")
    void getAuditsByResident_returnsList() throws Exception {
        when(socialAuditService.getAuditsByResident(1L))
                .thenReturn(ApiResponse.ok(List.of(sampleResponse()), "Retrieved 1 social audit records"));

        mockMvc.perform(get("/api/residents/1/social-audits"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data").isArray())
                .andExpect(jsonPath("$.data[0].id").value(1));
    }

    @Test
    @DisplayName("GET /api/residents/{residentId}/social-audits/latest returns latest audit")
    void getLatestAudit_returnsLatest() throws Exception {
        when(socialAuditService.getLatestAudit(1L))
                .thenReturn(ApiResponse.ok(sampleResponse(), "Latest caregiver social audit retrieved"));

        mockMvc.perform(get("/api/residents/1/social-audits/latest"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.socialScore").value(82.5));
    }

    @Test
    @DisplayName("GET /api/residents/{residentId}/social-audits/{auditId} returns individual audit")
    void getAuditById_returnsAudit() throws Exception {
        when(socialAuditService.getAuditById(1L, 1L))
                .thenReturn(ApiResponse.ok(sampleResponse(), "Social audit retrieved successfully"));

        mockMvc.perform(get("/api/residents/1/social-audits/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(1));
    }
}
