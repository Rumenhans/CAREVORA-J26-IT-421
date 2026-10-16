package com.carevora.service;

import com.carevora.dto.ApiResponse;
import com.carevora.dto.cognitive.CognitiveAiResult;
import com.carevora.dto.cognitive.CognitiveAssessmentResponse;
import com.carevora.dto.cognitive.CognitiveAssessmentSubmissionRequest;
import com.carevora.entity.*;
import com.carevora.enums.UserRole;
import com.carevora.exception.AiServiceException;
import com.carevora.exception.BadRequestException;
import com.carevora.exception.ResourceNotFoundException;
import com.carevora.repository.*;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.time.LocalDateTime;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CognitiveAssessmentServiceTest {

    @Mock
    private CognitiveAssessmentRepository cognitiveAssessmentRepository;

    @Mock
    private ResidentRepository residentRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private CaregiverRepository caregiverRepository;

    @Mock
    private AiMlService aiMlService;

    @org.mockito.Spy
    private com.fasterxml.jackson.databind.ObjectMapper objectMapper = new com.fasterxml.jackson.databind.ObjectMapper();

    @InjectMocks
    private CognitiveAssessmentService cognitiveAssessmentService;

    private ElderHome home1;
    private ElderHome home2;
    private Resident resident;
    private User residentUser;
    private User doctorUser;
    private User caregiver1User;
    private Caregiver caregiver1;

    @BeforeEach
    void setUp() {
        home1 = ElderHome.builder().id(1L).name("Serene Valley").build();
        home2 = ElderHome.builder().id(2L).name("Golden Sunset").build();

        residentUser = User.builder().id(10L).email("resident@carevora.com").role(UserRole.ELDER).firstName("James").lastName("Perera").build();
        resident = Resident.builder().id(100L).user(residentUser).elderHome(home1).roomNumber("105").cognitiveScore(70.0).build();

        doctorUser = User.builder().id(20L).email("doctor@carevora.com").role(UserRole.DOCTOR).firstName("Dr. Samantha").lastName("Reed").build();

        caregiver1User = User.builder().id(30L).email("caregiver1@carevora.com").role(UserRole.CAREGIVER).firstName("Eleanor").lastName("Vance").build();
        caregiver1 = Caregiver.builder().id(1L).user(caregiver1User).elderHome(home1).build();
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    private void authenticateUser(String email) {
        UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken(email, null, Collections.emptyList());
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    private CognitiveAssessmentSubmissionRequest createValidRequest() {
        return CognitiveAssessmentSubmissionRequest.builder()
                .residentId(100L)
                .memory(80.0)
                .attention(85.0)
                .orientation(90.0)
                .recall(75.0)
                .reasoning(80.0)
                .build();
    }

    private CognitiveAiResult createMockAiResult() {
        List<CognitiveAssessmentResponse.CategoryContributionDto> contribs = List.of(
                CognitiveAssessmentResponse.CategoryContributionDto.builder().category("memory").score(80.0).weight(0.25).contribution(20.0).weightPercentage("25%").build(),
                CognitiveAssessmentResponse.CategoryContributionDto.builder().category("attention").score(85.0).weight(0.20).contribution(17.0).weightPercentage("20%").build(),
                CognitiveAssessmentResponse.CategoryContributionDto.builder().category("orientation").score(90.0).weight(0.20).contribution(18.0).weightPercentage("20%").build(),
                CognitiveAssessmentResponse.CategoryContributionDto.builder().category("recall").score(75.0).weight(0.20).contribution(15.0).weightPercentage("20%").build(),
                CognitiveAssessmentResponse.CategoryContributionDto.builder().category("reasoning").score(80.0).weight(0.15).contribution(12.0).weightPercentage("15%").build()
        );

        CognitiveAssessmentResponse.MlModelStatusDto mlStatus = CognitiveAssessmentResponse.MlModelStatusDto.builder()
                .available(false)
                .modelType("RandomForestClassifier")
                .statusMessage("Model artifact pending")
                .prediction(null)
                .build();

        return CognitiveAiResult.builder()
                .acrfScore(82.0)
                .rawWeightedScore(82.0)
                .scale("0-100")
                .scoringDirection("Higher is better")
                .weightsApplied(Map.of("memory", 0.25, "attention", 0.20, "orientation", 0.20, "recall", 0.20, "reasoning", 0.15))
                .categoryScores(Map.of("memory", 80.0, "attention", 85.0, "orientation", 90.0, "recall", 75.0, "reasoning", 80.0))
                .categoryContributions(contribs)
                .mlModelEvaluation(mlStatus)
                .methodology("ACRF Fixed Base Weights")
                .clinicalDisclaimer("Non-diagnostic wellness metric")
                .build();
    }

    @Test
    void testSubmitAssessment_Success() {
        authenticateUser("caregiver1@carevora.com");
        when(userRepository.findByEmail("caregiver1@carevora.com")).thenReturn(Optional.of(caregiver1User));
        when(caregiverRepository.findByUserId(30L)).thenReturn(Optional.of(caregiver1));
        when(residentRepository.findById(100L)).thenReturn(Optional.of(resident));
        when(aiMlService.predictCognitive(any(), any(), any(), any(), any(), any(), any(), any(), any(), any()))
                .thenReturn(createMockAiResult());

        CognitiveAssessment savedEntity = CognitiveAssessment.builder()
                .id(1L)
                .resident(resident)
                .memoryScore(80.0)
                .attentionScore(85.0)
                .orientationScore(90.0)
                .recallScore(75.0)
                .reasoningScore(80.0)
                .acrfScore(82.0)
                .assessedBy("Eleanor Vance")
                .createdAt(LocalDateTime.now())
                .build();
        when(cognitiveAssessmentRepository.save(any(CognitiveAssessment.class))).thenReturn(savedEntity);

        ApiResponse<CognitiveAssessmentResponse> response = cognitiveAssessmentService.submitAssessment(createValidRequest());

        assertNotNull(response);
        assertTrue(response.isSuccess());
        assertEquals(82.0, response.getData().getAcrfScore());
        assertEquals("James Perera", response.getData().getResidentName());
        assertEquals(100L, response.getData().getResidentId());
        assertFalse(response.getData().getMlModelEvaluation().isAvailable());
        assertEquals(5, response.getData().getCategoryContributions().size());

        // Verify resident score snapshot updated
        verify(residentRepository).save(argThat(r -> r.getCognitiveScore().equals(82.0)));
        verify(cognitiveAssessmentRepository).save(any(CognitiveAssessment.class));
    }

    @Test
    void testSubmitAssessment_ResidentNotFound_ThrowsException() {
        CognitiveAssessmentSubmissionRequest req = createValidRequest();
        when(residentRepository.findById(100L)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> cognitiveAssessmentService.submitAssessment(req));
        verify(aiMlService, never()).predictCognitive(any(), any(), any(), any(), any(), any(), any(), any(), any(), any());
    }

    @Test
    void testSubmitAssessment_AiServiceFailure_SavesWithPredictionUnavailable() {
        authenticateUser("doctor@carevora.com");
        when(userRepository.findByEmail("doctor@carevora.com")).thenReturn(Optional.of(doctorUser));
        when(residentRepository.findById(100L)).thenReturn(Optional.of(resident));
        when(aiMlService.predictCognitive(any(), any(), any(), any(), any(), any(), any(), any(), any(), any()))
                .thenThrow(new AiServiceException("AI microservice down"));

        CognitiveAssessment saved = CognitiveAssessment.builder()
                .id(1L)
                .resident(resident)
                .memoryScore(80.0)
                .attentionScore(85.0)
                .orientationScore(90.0)
                .recallScore(75.0)
                .reasoningScore(80.0)
                .acrfScore(82.0)
                .status("COMPLETED_PREDICTION_UNAVAILABLE")
                .assessedBy("Dr. Samantha Reed")
                .createdAt(LocalDateTime.now())
                .build();
        when(cognitiveAssessmentRepository.save(any(CognitiveAssessment.class))).thenReturn(saved);

        ApiResponse<CognitiveAssessmentResponse> response = cognitiveAssessmentService.submitAssessment(createValidRequest());

        assertNotNull(response);
        assertTrue(response.isSuccess());
        assertEquals(82.0, response.getData().getAcrfScore());
        assertEquals("COMPLETED_PREDICTION_UNAVAILABLE", response.getData().getStatus());
        assertFalse(response.getData().getMlModelEvaluation().isAvailable());
        verify(cognitiveAssessmentRepository).save(any(CognitiveAssessment.class));
        verify(residentRepository).save(any(Resident.class));
    }

    @Test
    void testSubmitAssessment_InvalidScores_NaN_ThrowsBadRequest() {
        CognitiveAssessmentSubmissionRequest req = createValidRequest();
        req.setMemory(Double.NaN);

        assertThrows(BadRequestException.class, () -> cognitiveAssessmentService.submitAssessment(req));
    }

    @Test
    void testSubmitAssessment_InvalidScores_Negative_ThrowsBadRequest() {
        CognitiveAssessmentSubmissionRequest req = createValidRequest();
        req.setAttention(-5.0);

        assertThrows(BadRequestException.class, () -> cognitiveAssessmentService.submitAssessment(req));
    }

    @Test
    void testSubmitAssessment_InvalidScores_Above100_ThrowsBadRequest() {
        CognitiveAssessmentSubmissionRequest req = createValidRequest();
        req.setReasoning(105.0);

        assertThrows(BadRequestException.class, () -> cognitiveAssessmentService.submitAssessment(req));
    }

    @Test
    void testAuthorization_CaregiverDifferentHome_ThrowsAccessDenied() {
        authenticateUser("caregiver2@carevora.com");
        User caregiver2User = User.builder().id(40L).email("caregiver2@carevora.com").role(UserRole.CAREGIVER).build();
        Caregiver caregiver2 = Caregiver.builder().id(2L).user(caregiver2User).elderHome(home2).build();

        when(residentRepository.findById(100L)).thenReturn(Optional.of(resident)); // resident is in home1
        when(userRepository.findByEmail("caregiver2@carevora.com")).thenReturn(Optional.of(caregiver2User));
        when(caregiverRepository.findByUserId(40L)).thenReturn(Optional.of(caregiver2));

        assertThrows(AccessDeniedException.class, () -> cognitiveAssessmentService.submitAssessment(createValidRequest()));
        verify(aiMlService, never()).predictCognitive(any(), any(), any(), any(), any(), any());
    }

    @Test
    void testAuthorization_ElderAccessingOtherElder_ThrowsAccessDenied() {
        authenticateUser("other.elder@carevora.com");
        User otherElder = User.builder().id(999L).email("other.elder@carevora.com").role(UserRole.ELDER).build();

        when(residentRepository.findById(100L)).thenReturn(Optional.of(resident)); // resident has user ID 10L
        when(userRepository.findByEmail("other.elder@carevora.com")).thenReturn(Optional.of(otherElder));

        assertThrows(AccessDeniedException.class, () -> cognitiveAssessmentService.submitAssessment(createValidRequest()));
    }

    @Test
    void testAuthorization_Doctor_HasFullAccess() {
        authenticateUser("doctor@carevora.com");
        when(residentRepository.findById(100L)).thenReturn(Optional.of(resident));
        when(userRepository.findByEmail("doctor@carevora.com")).thenReturn(Optional.of(doctorUser));
        when(aiMlService.predictCognitive(any(), any(), any(), any(), any(), any(), any(), any(), any(), any())).thenReturn(createMockAiResult());

        CognitiveAssessment saved = CognitiveAssessment.builder()
                .id(1L).resident(resident).memoryScore(80.0).attentionScore(85.0).orientationScore(90.0)
                .recallScore(75.0).reasoningScore(80.0).acrfScore(82.0).assessedBy("Dr. Samantha Reed")
                .createdAt(LocalDateTime.now()).build();
        when(cognitiveAssessmentRepository.save(any())).thenReturn(saved);

        ApiResponse<CognitiveAssessmentResponse> res = cognitiveAssessmentService.submitAssessment(createValidRequest());
        assertTrue(res.isSuccess());
    }

    @Test
    void testGetResidentCognitiveAssessments_Success() {
        authenticateUser("doctor@carevora.com");
        when(residentRepository.findById(100L)).thenReturn(Optional.of(resident));
        when(userRepository.findByEmail("doctor@carevora.com")).thenReturn(Optional.of(doctorUser));

        CognitiveAssessment asm1 = CognitiveAssessment.builder()
                .id(1L).resident(resident).memoryScore(80.0).attentionScore(80.0).orientationScore(80.0)
                .recallScore(80.0).reasoningScore(80.0).acrfScore(80.0).assessedBy("Nurse")
                .createdAt(LocalDateTime.now()).build();
        when(cognitiveAssessmentRepository.findByResidentIdOrderByCreatedAtDesc(100L))
                .thenReturn(List.of(asm1));

        ApiResponse<List<CognitiveAssessmentResponse>> res = cognitiveAssessmentService.getResidentCognitiveAssessments(100L);
        assertTrue(res.isSuccess());
        assertEquals(1, res.getData().size());
        assertEquals(80.0, res.getData().get(0).getAcrfScore());
        assertEquals(5, res.getData().get(0).getCategoryContributions().size());
    }

    @Test
    void testGetResidentCognitiveAssessments_NotFound() {
        when(residentRepository.findById(999L)).thenReturn(Optional.empty());
        assertThrows(ResourceNotFoundException.class, () -> cognitiveAssessmentService.getResidentCognitiveAssessments(999L));
    }

    @Test
    void testSubmitAssessment_WithFullMlFeatures_PersistsMlAvailableTrue_PredictionAndProbabilities() {
        authenticateUser("caregiver1@carevora.com");
        when(userRepository.findByEmail("caregiver1@carevora.com")).thenReturn(Optional.of(caregiver1User));
        when(caregiverRepository.findByUserId(30L)).thenReturn(Optional.of(caregiver1));
        when(residentRepository.findById(100L)).thenReturn(Optional.of(resident));

        CognitiveAssessmentSubmissionRequest req = createValidRequest();
        req.setAge(79);
        req.setEducationYears(16);
        req.setAccuracies(Map.of("memory", 0.90, "attention", 0.85, "orientation", 0.95, "recall", 0.80, "reasoning", 0.85));
        req.setResponseTimes(Map.of("memory", 4.5, "attention", 3.2, "orientation", 2.8, "recall", 5.1, "reasoning", 6.0));

        Map<String, Double> probs = Map.of("Low", 0.05, "Moderate", 0.25, "High", 0.70);
        CognitiveAssessmentResponse.MlModelStatusDto mlAvailableStatus = CognitiveAssessmentResponse.MlModelStatusDto.builder()
                .available(true)
                .modelType("RandomForestClassifier")
                .statusMessage("Experimental prediction generated using artifact trained on synthetic data.")
                .prediction("High")
                .probabilities(probs)
                .alertTriggered(true)
                .alertThreshold(0.48)
                .experimentalLabel("Synthetic Data Experiment (Non-Clinical)")
                .build();

        CognitiveAiResult mockAiResult = CognitiveAiResult.builder()
                .acrfScore(82.0)
                .rawWeightedScore(82.0)
                .scale("0-100")
                .scoringDirection("Higher is better")
                .weightsApplied(Map.of("memory", 0.25, "attention", 0.20, "orientation", 0.20, "recall", 0.20, "reasoning", 0.15))
                .categoryScores(Map.of("memory", 80.0, "attention", 85.0, "orientation", 90.0, "recall", 75.0, "reasoning", 80.0))
                .categoryContributions(List.of())
                .mlModelEvaluation(mlAvailableStatus)
                .methodology("ACRF Fixed Base Weights")
                .clinicalDisclaimer("Non-diagnostic")
                .build();

        when(aiMlService.predictCognitive(eq(100L), eq(80.0), eq(85.0), eq(90.0), eq(75.0), eq(80.0), eq(79), eq(16), eq(req.getAccuracies()), eq(req.getResponseTimes())))
                .thenReturn(mockAiResult);

        CognitiveAssessment savedEntity = CognitiveAssessment.builder()
                .id(1L)
                .resident(resident)
                .memoryScore(80.0)
                .attentionScore(85.0)
                .orientationScore(90.0)
                .recallScore(75.0)
                .reasoningScore(80.0)
                .acrfScore(82.0)
                .assessedBy("Eleanor Vance")
                .mlAvailable(true)
                .mlPrediction("High")
                .alertTriggered(true)
                .highRiskProbability(0.70)
                .classProbabilities("{\"Low\":0.05,\"Moderate\":0.25,\"High\":0.70}")
                .createdAt(LocalDateTime.now())
                .build();
        when(cognitiveAssessmentRepository.save(any(CognitiveAssessment.class))).thenReturn(savedEntity);

        ApiResponse<CognitiveAssessmentResponse> response = cognitiveAssessmentService.submitAssessment(req);

        assertNotNull(response);
        assertTrue(response.isSuccess());
        assertEquals("High", response.getData().getMlPrediction());
        assertTrue(response.getData().getAlertTriggered());
        assertTrue(response.getData().getMlModelEvaluation().isAvailable());
        assertEquals("High", response.getData().getMlModelEvaluation().getPrediction());
        assertEquals(0.70, response.getData().getMlModelEvaluation().getProbabilities().get("High"));

        verify(cognitiveAssessmentRepository).save(argThat(entity ->
                Boolean.TRUE.equals(entity.getMlAvailable()) &&
                "High".equals(entity.getMlPrediction()) &&
                Boolean.TRUE.equals(entity.getAlertTriggered()) &&
                Double.valueOf(0.70).equals(entity.getHighRiskProbability())
        ));
    }

    @Test
    void testSubmitAssessment_WithMissingMlFeatures_PersistsMlAvailableFalse() {
        authenticateUser("caregiver1@carevora.com");
        when(userRepository.findByEmail("caregiver1@carevora.com")).thenReturn(Optional.of(caregiver1User));
        when(caregiverRepository.findByUserId(30L)).thenReturn(Optional.of(caregiver1));
        when(residentRepository.findById(100L)).thenReturn(Optional.of(resident));

        CognitiveAssessmentSubmissionRequest req = createValidRequest();

        CognitiveAiResult mockAiResult = createMockAiResult();
        when(aiMlService.predictCognitive(any(), any(), any(), any(), any(), any(), any(), any(), any(), any()))
                .thenReturn(mockAiResult);

        CognitiveAssessment savedEntity = CognitiveAssessment.builder()
                .id(2L)
                .resident(resident)
                .memoryScore(80.0)
                .attentionScore(85.0)
                .orientationScore(90.0)
                .recallScore(75.0)
                .reasoningScore(80.0)
                .acrfScore(82.0)
                .assessedBy("Eleanor Vance")
                .mlAvailable(false)
                .mlPrediction(null)
                .alertTriggered(false)
                .createdAt(LocalDateTime.now())
                .build();
        when(cognitiveAssessmentRepository.save(any(CognitiveAssessment.class))).thenReturn(savedEntity);

        ApiResponse<CognitiveAssessmentResponse> response = cognitiveAssessmentService.submitAssessment(req);

        assertNotNull(response);
        assertTrue(response.isSuccess());
        assertNull(response.getData().getMlPrediction());
        assertFalse(response.getData().getAlertTriggered());
        assertFalse(response.getData().getMlModelEvaluation().isAvailable());

        verify(cognitiveAssessmentRepository).save(argThat(entity ->
                Boolean.FALSE.equals(entity.getMlAvailable()) &&
                entity.getMlPrediction() == null &&
                Boolean.FALSE.equals(entity.getAlertTriggered())
        ));
    }

    @Test
    void testSubmitAssessment_InvalidEducationYears_ThrowsBadRequest() {
        CognitiveAssessmentSubmissionRequest req1 = createValidRequest();
        req1.setEducationYears(45);
        assertThrows(BadRequestException.class, () -> cognitiveAssessmentService.submitAssessment(req1));

        CognitiveAssessmentSubmissionRequest req2 = createValidRequest();
        req2.setEducationYears(-1);
        assertThrows(BadRequestException.class, () -> cognitiveAssessmentService.submitAssessment(req2));
    }

    @Test
    void testSubmitAssessment_InvalidAge_ThrowsBadRequest() {
        CognitiveAssessmentSubmissionRequest req1 = createValidRequest();
        req1.setAge(0);
        assertThrows(BadRequestException.class, () -> cognitiveAssessmentService.submitAssessment(req1));

        CognitiveAssessmentSubmissionRequest req2 = createValidRequest();
        req2.setAge(140);
        assertThrows(BadRequestException.class, () -> cognitiveAssessmentService.submitAssessment(req2));
    }

    @Test
    void testSubmitAssessment_InvalidAccuracy_ThrowsBadRequest() {
        CognitiveAssessmentSubmissionRequest req1 = createValidRequest();
        req1.setAccuracies(Map.of("memory", -1.0));
        assertThrows(BadRequestException.class, () -> cognitiveAssessmentService.submitAssessment(req1));

        CognitiveAssessmentSubmissionRequest req2 = createValidRequest();
        req2.setAccuracies(Map.of("memory", 105.0));
        assertThrows(BadRequestException.class, () -> cognitiveAssessmentService.submitAssessment(req2));

        CognitiveAssessmentSubmissionRequest req3 = createValidRequest();
        req3.setAccuracies(Map.of("memory", Double.NaN));
        assertThrows(BadRequestException.class, () -> cognitiveAssessmentService.submitAssessment(req3));
    }

    @Test
    void testSubmitAssessment_InvalidResponseTime_ThrowsBadRequest() {
        CognitiveAssessmentSubmissionRequest req1 = createValidRequest();
        req1.setResponseTimes(Map.of("memory", 0.0));
        assertThrows(BadRequestException.class, () -> cognitiveAssessmentService.submitAssessment(req1));

        CognitiveAssessmentSubmissionRequest req2 = createValidRequest();
        req2.setResponseTimes(Map.of("memory", -3.5));
        assertThrows(BadRequestException.class, () -> cognitiveAssessmentService.submitAssessment(req2));

        CognitiveAssessmentSubmissionRequest req3 = createValidRequest();
        req3.setResponseTimes(Map.of("memory", Double.POSITIVE_INFINITY));
        assertThrows(BadRequestException.class, () -> cognitiveAssessmentService.submitAssessment(req3));
    }

    @Test
    void testSubmitAssessment_UpdatesResidentEducationYears_WhenPreviouslyNull() {
        authenticateUser("caregiver1@carevora.com");
        when(userRepository.findByEmail("caregiver1@carevora.com")).thenReturn(Optional.of(caregiver1User));
        when(caregiverRepository.findByUserId(30L)).thenReturn(Optional.of(caregiver1));
        when(residentRepository.findById(100L)).thenReturn(Optional.of(resident));
        resident.setEducationYears(null);

        CognitiveAssessmentSubmissionRequest req = createValidRequest();
        req.setEducationYears(12);

        when(aiMlService.predictCognitive(any(), any(), any(), any(), any(), any(), any(), any(), any(), any()))
                .thenReturn(createMockAiResult());
        when(cognitiveAssessmentRepository.save(any())).thenReturn(CognitiveAssessment.builder().id(1L).resident(resident).memoryScore(80.0).attentionScore(80.0).orientationScore(80.0).recallScore(80.0).reasoningScore(80.0).acrfScore(80.0).build());

        cognitiveAssessmentService.submitAssessment(req);

        assertEquals(12, resident.getEducationYears());
        verify(residentRepository).save(argThat(r -> Integer.valueOf(12).equals(r.getEducationYears())));
    }

    @Test
    void testGetResidentCognitiveAssessments_WithMlAvailableAndUnavailableInHistory() {
        authenticateUser("doctor@carevora.com");
        when(residentRepository.findById(100L)).thenReturn(Optional.of(resident));
        when(userRepository.findByEmail("doctor@carevora.com")).thenReturn(Optional.of(doctorUser));

        CognitiveAssessment asm1 = CognitiveAssessment.builder()
                .id(1L).resident(resident).memoryScore(80.0).attentionScore(80.0).orientationScore(80.0)
                .recallScore(80.0).reasoningScore(80.0).acrfScore(80.0).assessedBy("Nurse")
                .mlAvailable(true)
                .mlPrediction("Moderate")
                .alertTriggered(false)
                .highRiskProbability(0.20)
                .classProbabilities("{\"Low\":0.3,\"Moderate\":0.5,\"High\":0.2}")
                .createdAt(LocalDateTime.now()).build();

        CognitiveAssessment asm2 = CognitiveAssessment.builder()
                .id(2L).resident(resident).memoryScore(70.0).attentionScore(70.0).orientationScore(70.0)
                .recallScore(70.0).reasoningScore(70.0).acrfScore(70.0).assessedBy("Nurse")
                .mlAvailable(false)
                .mlPrediction(null)
                .alertTriggered(false)
                .createdAt(LocalDateTime.now().minusDays(1)).build();

        when(cognitiveAssessmentRepository.findByResidentIdOrderByCreatedAtDesc(100L))
                .thenReturn(List.of(asm1, asm2));

        ApiResponse<List<CognitiveAssessmentResponse>> res = cognitiveAssessmentService.getResidentCognitiveAssessments(100L);
        assertTrue(res.isSuccess());
        assertEquals(2, res.getData().size());

        // Item 1: ML available
        CognitiveAssessmentResponse resp1 = res.getData().get(0);
        assertTrue(resp1.getMlModelEvaluation().isAvailable());
        assertEquals("Moderate", resp1.getMlPrediction());
        assertEquals("Moderate", resp1.getMlModelEvaluation().getPrediction());
        assertNotNull(resp1.getMlModelEvaluation().getProbabilities());
        assertEquals(0.5, resp1.getMlModelEvaluation().getProbabilities().get("Moderate"));

        // Item 2: ML unavailable
        CognitiveAssessmentResponse resp2 = res.getData().get(1);
        assertFalse(resp2.getMlModelEvaluation().isAvailable());
        assertNull(resp2.getMlPrediction());
        assertNull(resp2.getMlModelEvaluation().getPrediction());
    }
}
