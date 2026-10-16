package com.carevora.service;

import com.carevora.dto.ApiResponse;
import com.carevora.dto.socialaudit.SocialAuditRequest;
import com.carevora.dto.socialaudit.SocialAuditResponse;
import com.carevora.entity.*;
import com.carevora.enums.*;
import com.carevora.exception.BadRequestException;
import com.carevora.exception.ResourceNotFoundException;
import com.carevora.repository.CaregiverRepository;
import com.carevora.repository.ResidentRepository;
import com.carevora.repository.SocialAuditRepository;
import com.carevora.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.access.AccessDeniedException;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SocialAuditServiceTest {

    @Mock
    private SocialAuditRepository socialAuditRepository;

    @Mock
    private ResidentRepository residentRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private CaregiverRepository caregiverRepository;

    @InjectMocks
    private SocialAuditService socialAuditService;

    private Resident sampleResident;
    private User caregiverUser;
    private Caregiver caregiverEntity;
    private ElderHome elderHome;

    @BeforeEach
    void setUp() {
        elderHome = ElderHome.builder().id(1L).name("Golden Sunset Eldercare").build();

        User residentUser = User.builder()
                .id(10L)
                .firstName("James")
                .lastName("Perera")
                .role(UserRole.RESIDENT)
                .build();

        sampleResident = Resident.builder()
                .id(1L)
                .user(residentUser)
                .elderHome(elderHome)
                .roomNumber("101")
                .socialScore(null)
                .build();

        caregiverUser = User.builder()
                .id(20L)
                .firstName("David")
                .lastName("Silva")
                .email("david.silva@carevora.com")
                .role(UserRole.CAREGIVER)
                .build();

        caregiverEntity = Caregiver.builder()
                .id(5L)
                .user(caregiverUser)
                .elderHome(elderHome)
                .staffCode("CG-9021")
                .build();
    }

    @Test
    @DisplayName("Successfully creates social audit and updates resident socialScore with documented provenance")
    void createSocialAudit_successWithFullObservations() {
        SocialAuditRequest req = SocialAuditRequest.builder()
                .reportingPeriodDays(7)
                .familyInPersonVisits(2)
                .familyPhoneVideoContacts(3)
                .externalContactUnknown(false)
                .peerInteractionLevel(PeerInteractionLevel.OFTEN)
                .activitiesAvailable(4)
                .activitiesAttended(3)
                .activityParticipationLevel(ActivityParticipationLevel.ACTIVE_ENGAGEMENT)
                .healthMobilityBarriers(false)
                .estimatedHoursAlonePerDay(4.5)
                .aloneTimeContext(AloneTimeContext.CHOSEN_SOLITUDE)
                .caregiverNotes("Resident engaged warmly during tea and card games.")
                .build();

        when(residentRepository.findById(1L)).thenReturn(Optional.of(sampleResident));
        when(userRepository.findByEmail("david.silva@carevora.com")).thenReturn(Optional.of(caregiverUser));
        when(caregiverRepository.findByUserId(20L)).thenReturn(Optional.of(caregiverEntity));

        when(socialAuditRepository.save(any(SocialAudit.class))).thenAnswer(invocation -> {
            SocialAudit a = invocation.getArgument(0);
            a.setId(101L);
            return a;
        });

        ApiResponse<SocialAuditResponse> res = socialAuditService.createSocialAudit(1L, req, "david.silva@carevora.com");

        assertTrue(res.isSuccess());
        assertNotNull(res.getData());
        assertEquals(101L, res.getData().getId());
        assertEquals("James Perera", res.getData().getResidentName());
        assertEquals("David Silva", res.getData().getCaregiverName());
        assertEquals("CG-9021", res.getData().getCaregiverStaffCode());
        assertEquals(5, res.getData().getTotalExternalContacts());
        assertNotNull(res.getData().getSocialScore());
        assertTrue(res.getData().getSocialScore() > 70.0);
        assertTrue(res.getData().getScoreProvenance().contains("CAREVORA-OBS-SOC-V1"));

        // Verify resident socialScore was updated
        ArgumentCaptor<Resident> residentCaptor = ArgumentCaptor.forClass(Resident.class);
        verify(residentRepository).save(residentCaptor.capture());
        assertEquals(res.getData().getSocialScore(), residentCaptor.getValue().getSocialScore(), 0.001);
    }

    @Test
    @DisplayName("Handles unknown observations gracefully without fabricating zero contacts or fake default 80.0")
    void createSocialAudit_handlesUnknownObservationsWithoutFabrication() {
        SocialAuditRequest req = SocialAuditRequest.builder()
                .reportingPeriodDays(7)
                .externalContactUnknown(true) // Family contact unrecorded
                .peerInteractionLevel(PeerInteractionLevel.SOMETIMES)
                .activitiesAvailable(null)
                .activitiesAttended(null)
                .activityParticipationLevel(ActivityParticipationLevel.UNKNOWN)
                .healthMobilityBarriers(false)
                .estimatedHoursAlonePerDay(null)
                .aloneTimeContext(AloneTimeContext.UNKNOWN)
                .caregiverNotes("New resident admission; family contact history pending.")
                .build();

        when(residentRepository.findById(1L)).thenReturn(Optional.of(sampleResident));
        when(userRepository.findByEmail("david.silva@carevora.com")).thenReturn(Optional.of(caregiverUser));
        when(caregiverRepository.findByUserId(20L)).thenReturn(Optional.of(caregiverEntity));

        when(socialAuditRepository.save(any(SocialAudit.class))).thenAnswer(invocation -> {
            SocialAudit a = invocation.getArgument(0);
            a.setId(102L);
            return a;
        });

        ApiResponse<SocialAuditResponse> res = socialAuditService.createSocialAudit(1L, req, "david.silva@carevora.com");

        assertTrue(res.isSuccess());
        SocialAuditResponse data = res.getData();
        assertNull(data.getFamilyInPersonVisits());
        assertNull(data.getFamilyPhoneVideoContacts());
        assertTrue(data.getExternalContactUnknown());
        assertEquals(PeerInteractionLevel.SOMETIMES, data.getPeerInteractionLevel());
        // Score is calculated strictly from peer interaction (55.0) without injecting fake 80.0
        assertEquals(55.0, data.getSocialScore(), 0.1);
    }

    @Test
    @DisplayName("Health and mobility barriers do not penalize group activity score as proof of social withdrawal")
    void createSocialAudit_healthMobilityBarriersDoNotPenalizeResident() {
        SocialAuditRequest req = SocialAuditRequest.builder()
                .reportingPeriodDays(7)
                .familyInPersonVisits(1)
                .peerInteractionLevel(PeerInteractionLevel.OFTEN)
                .activitiesAvailable(5)
                .activitiesAttended(0) // 0 attended due to severe arthritis
                .activityParticipationLevel(ActivityParticipationLevel.UNABLE_HEALTH_MOBILITY)
                .healthMobilityBarriers(true) // Explicit barrier flag
                .aloneTimeContext(AloneTimeContext.CHOSEN_SOLITUDE)
                .build();

        when(residentRepository.findById(1L)).thenReturn(Optional.of(sampleResident));
        when(userRepository.findByEmail("david.silva@carevora.com")).thenReturn(Optional.of(caregiverUser));
        when(caregiverRepository.findByUserId(20L)).thenReturn(Optional.of(caregiverEntity));
        when(socialAuditRepository.save(any(SocialAudit.class))).thenAnswer(i -> i.getArgument(0));

        ApiResponse<SocialAuditResponse> res = socialAuditService.createSocialAudit(1L, req, "david.silva@carevora.com");

        assertTrue(res.isSuccess());
        // Resident is not crushed by zero attendance because health mobility barriers flag protected them
        assertTrue(res.getData().getSocialScore() >= 65.0);
    }

    @Test
    @DisplayName("Rejects submission when activities attended exceeds activities available")
    void createSocialAudit_rejectsAttendedExceedingAvailable() {
        SocialAuditRequest req = SocialAuditRequest.builder()
                .activitiesAvailable(2)
                .activitiesAttended(5)
                .build();

        when(residentRepository.findById(1L)).thenReturn(Optional.of(sampleResident));
        when(userRepository.findByEmail("david.silva@carevora.com")).thenReturn(Optional.of(caregiverUser));

        assertThrows(BadRequestException.class, () ->
                socialAuditService.createSocialAudit(1L, req, "david.silva@carevora.com"));
    }

    @Test
    @DisplayName("Rejects audit submission when user does not have caregiver, doctor, or admin role")
    void createSocialAudit_rejectsUnauthorizedRole() {
        User residentRoleUser = User.builder()
                .id(99L)
                .email("elderly@carevora.com")
                .role(UserRole.RESIDENT)
                .build();

        when(residentRepository.findById(1L)).thenReturn(Optional.of(sampleResident));
        when(userRepository.findByEmail("elderly@carevora.com")).thenReturn(Optional.of(residentRoleUser));

        SocialAuditRequest req = SocialAuditRequest.builder().build();
        assertThrows(AccessDeniedException.class, () ->
                socialAuditService.createSocialAudit(1L, req, "elderly@carevora.com"));
    }

    @Test
    @DisplayName("Preserves chronological audit history across multiple sessions without overwriting")
    void getAuditsByResident_returnsChronologicalAuditHistory() {
        SocialAudit audit1 = SocialAudit.builder()
                .id(201L)
                .resident(sampleResident)
                .caregiverUser(caregiverUser)
                .auditDate(LocalDateTime.now().minusDays(7))
                .socialScore(68.0)
                .build();

        SocialAudit audit2 = SocialAudit.builder()
                .id(202L)
                .resident(sampleResident)
                .caregiverUser(caregiverUser)
                .auditDate(LocalDateTime.now())
                .socialScore(74.0)
                .build();

        when(residentRepository.existsById(1L)).thenReturn(true);
        when(socialAuditRepository.findByResidentIdOrderByAuditDateDesc(1L)).thenReturn(List.of(audit2, audit1));

        ApiResponse<List<SocialAuditResponse>> res = socialAuditService.getAuditsByResident(1L);

        assertTrue(res.isSuccess());
        assertEquals(2, res.getData().size());
        assertEquals(202L, res.getData().get(0).getId());
        assertEquals(201L, res.getData().get(1).getId());
    }

    @Test
    @DisplayName("Returns latest audit record for a resident, or null when unassessed")
    void getLatestAudit_returnsLatestOrNull() {
        when(residentRepository.existsById(1L)).thenReturn(true);
        when(socialAuditRepository.findFirstByResidentIdOrderByAuditDateDesc(1L)).thenReturn(Optional.empty());

        ApiResponse<SocialAuditResponse> res = socialAuditService.getLatestAudit(1L);
        assertTrue(res.isSuccess());
        assertNull(res.getData());
        assertTrue(res.getMessage().contains("No caregiver social audit"));
    }
}
