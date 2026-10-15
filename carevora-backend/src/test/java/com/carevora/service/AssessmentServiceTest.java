package com.carevora.service;

import com.carevora.dto.ApiResponse;
import com.carevora.dto.assessment.AssessmentResponse;
import com.carevora.dto.assessment.AssessmentSubmissionRequest;
import com.carevora.entity.Assessment;
import com.carevora.entity.ContributingFactor;
import com.carevora.entity.Recommendation;
import com.carevora.entity.Resident;
import com.carevora.enums.RiskLevel;
import com.carevora.enums.TrajectoryStatus;
import com.carevora.enums.WellnessStatus;
import com.carevora.exception.BadRequestException;
import com.carevora.exception.ResourceNotFoundException;
import com.carevora.repository.AssessmentRepository;
import com.carevora.repository.ContributingFactorRepository;
import com.carevora.repository.RecommendationRepository;
import com.carevora.repository.ResidentRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AssessmentServiceTest {

    @Mock
    private AssessmentRepository assessmentRepository;

    @Mock
    private ResidentRepository residentRepository;

    @Mock
    private ContributingFactorRepository contributingFactorRepository;

    @Mock
    private RecommendationRepository recommendationRepository;

    @InjectMocks
    private AssessmentService assessmentService;

    private Resident sampleResident;

    @BeforeEach
    void setUp() {
        sampleResident = Resident.builder()
                .id(1L)
                .emotionalScore(70.0)
                .socialScore(82.0)
                .currentStatus(WellnessStatus.STABLE)
                .riskLevel(RiskLevel.LOW)
                .trajectory(TrajectoryStatus.STABLE)
                .build();
    }

    private void mockSaveAssessment() {
        when(assessmentRepository.save(any(Assessment.class))).thenAnswer(invocation -> {
            Assessment a = invocation.getArgument(0);
            a.setId(100L);
            return a;
        });
        when(residentRepository.save(any(Resident.class))).thenAnswer(invocation -> invocation.getArgument(0));
    }

    @Test
    @DisplayName("All favorable answers (all 0s) calculates exact 100.0 wellness score without compression")
    void submitAssessment_allFavorableAnswers_returns100WellnessScore() {
        when(residentRepository.findById(1L)).thenReturn(Optional.of(sampleResident));
        mockSaveAssessment();

        AssessmentSubmissionRequest request = AssessmentSubmissionRequest.builder()
                .residentId(1L)
                .answers(List.of(0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
                .build();

        ApiResponse<AssessmentResponse> response = assessmentService.submitAssessment(request);

        assertNotNull(response);
        assertTrue(response.isSuccess());
        AssessmentResponse data = response.getData();
        assertEquals(100.0, data.getOverallScore(), 0.001);
        assertEquals(100.0, data.getEmotionalScore(), 0.001);
        assertEquals(WellnessStatus.LOOKING_GOOD, data.getStatus());
        assertEquals(RiskLevel.LOW, data.getRiskLevel());

        // Verify Resident snapshot was updated with wellness score
        ArgumentCaptor<Resident> residentCaptor = ArgumentCaptor.forClass(Resident.class);
        verify(residentRepository).save(residentCaptor.capture());
        assertEquals(100.0, residentCaptor.getValue().getEmotionalScore(), 0.001);

        // Verify Assessment entity saved with 100.0 overallScore
        ArgumentCaptor<Assessment> assessmentCaptor = ArgumentCaptor.forClass(Assessment.class);
        verify(assessmentRepository).save(assessmentCaptor.capture());
        assertEquals(100.0, assessmentCaptor.getValue().getOverallScore(), 0.001);
        assertEquals(100.0, assessmentCaptor.getValue().getEmotionalScore(), 0.001);
    }

    @Test
    @DisplayName("All adverse answers (all 1s) calculates exact 0.0 wellness score without 40.0 floor compression")
    void submitAssessment_allAdverseAnswers_returns0WellnessScore() {
        when(residentRepository.findById(1L)).thenReturn(Optional.of(sampleResident));
        mockSaveAssessment();

        AssessmentSubmissionRequest request = AssessmentSubmissionRequest.builder()
                .residentId(1L)
                .answers(List.of(1, 1, 1, 1, 1, 1, 1, 1, 1, 1))
                .build();

        ApiResponse<AssessmentResponse> response = assessmentService.submitAssessment(request);

        assertNotNull(response);
        assertTrue(response.isSuccess());
        AssessmentResponse data = response.getData();
        assertEquals(0.0, data.getOverallScore(), 0.001);
        assertEquals(0.0, data.getEmotionalScore(), 0.001);
        assertEquals(WellnessStatus.NEEDS_ATTENTION, data.getStatus());
        assertEquals(RiskLevel.HIGH, data.getRiskLevel());

        // Verify Resident snapshot was updated with 0.0 emotionalScore
        ArgumentCaptor<Resident> residentCaptor = ArgumentCaptor.forClass(Resident.class);
        verify(residentRepository).save(residentCaptor.capture());
        assertEquals(0.0, residentCaptor.getValue().getEmotionalScore(), 0.001);
    }

    @Test
    @DisplayName("Mixed answers (8 favorable, 2 adverse) calculates exact 80.0 wellness score")
    void submitAssessment_mixedAnswers8Favorable2Adverse_returns80WellnessScore() {
        when(residentRepository.findById(1L)).thenReturn(Optional.of(sampleResident));
        mockSaveAssessment();

        // 8 zeros, 2 ones -> avgVal = 0.2 -> score = 100 - 20 = 80.0
        AssessmentSubmissionRequest request = AssessmentSubmissionRequest.builder()
                .residentId(1L)
                .answers(List.of(0, 0, 0, 1, 1, 0, 0, 0, 0, 0))
                .build();

        ApiResponse<AssessmentResponse> response = assessmentService.submitAssessment(request);

        assertNotNull(response);
        AssessmentResponse data = response.getData();
        assertEquals(80.0, data.getOverallScore(), 0.001);
        assertEquals(80.0, data.getEmotionalScore(), 0.001);
        assertEquals(WellnessStatus.LOOKING_GOOD, data.getStatus());
        assertEquals(RiskLevel.LOW, data.getRiskLevel());
    }

    @Test
    @DisplayName("Mixed answers (5 favorable, 5 adverse) calculates exact 50.0 wellness score")
    void submitAssessment_mixedAnswers5Favorable5Adverse_returns50WellnessScore() {
        when(residentRepository.findById(1L)).thenReturn(Optional.of(sampleResident));
        mockSaveAssessment();

        // 5 zeros, 5 ones -> avgVal = 0.5 -> score = 100 - 50 = 50.0
        AssessmentSubmissionRequest request = AssessmentSubmissionRequest.builder()
                .residentId(1L)
                .answers(List.of(0, 1, 0, 1, 0, 1, 0, 1, 0, 1))
                .build();

        ApiResponse<AssessmentResponse> response = assessmentService.submitAssessment(request);

        assertNotNull(response);
        AssessmentResponse data = response.getData();
        assertEquals(50.0, data.getOverallScore(), 0.001);
        assertEquals(50.0, data.getEmotionalScore(), 0.001);
        assertEquals(WellnessStatus.NEEDS_ATTENTION, data.getStatus());
        assertEquals(RiskLevel.HIGH, data.getRiskLevel());
    }

    @Test
    @DisplayName("Preserves independent socialScore without fabricating measurements or overwriting resident social score")
    void submitAssessment_preservesIndependentSocialScore() {
        sampleResident.setSocialScore(82.0);
        sampleResident.setEmotionalScore(80.0);
        when(residentRepository.findById(1L)).thenReturn(Optional.of(sampleResident));
        mockSaveAssessment();

        // Submitting assessment with score 100.0 (all favorable)
        AssessmentSubmissionRequest request = AssessmentSubmissionRequest.builder()
                .residentId(1L)
                .answers(List.of(0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
                .build();

        ApiResponse<AssessmentResponse> response = assessmentService.submitAssessment(request);

        // Assessment response socialScore reflects resident's actual socialScore (82.0), not fabricated 98.0
        assertEquals(82.0, response.getData().getSocialScore(), 0.001);

        // Resident socialScore was not mutated/overwritten
        ArgumentCaptor<Resident> residentCaptor = ArgumentCaptor.forClass(Resident.class);
        verify(residentRepository).save(residentCaptor.capture());
        assertEquals(82.0, residentCaptor.getValue().getSocialScore(), 0.001);
    }

    @Test
    @DisplayName("Rejects request with null answers list with BadRequestException")
    void submitAssessment_nullAnswers_throwsBadRequestException() {
        AssessmentSubmissionRequest request = AssessmentSubmissionRequest.builder()
                .residentId(1L)
                .answers(null)
                .build();

        assertThrows(BadRequestException.class, () -> assessmentService.submitAssessment(request));
        verifyNoInteractions(residentRepository);
    }

    @Test
    @DisplayName("Rejects request with fewer than 10 answers with BadRequestException")
    void submitAssessment_fewerThan10Answers_throwsBadRequestException() {
        AssessmentSubmissionRequest request = AssessmentSubmissionRequest.builder()
                .residentId(1L)
                .answers(List.of(0, 1, 0, 1))
                .build();

        assertThrows(BadRequestException.class, () -> assessmentService.submitAssessment(request));
        verifyNoInteractions(residentRepository);
    }

    @Test
    @DisplayName("Rejects request with more than 10 answers with BadRequestException")
    void submitAssessment_moreThan10Answers_throwsBadRequestException() {
        AssessmentSubmissionRequest request = AssessmentSubmissionRequest.builder()
                .residentId(1L)
                .answers(List.of(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
                .build();

        assertThrows(BadRequestException.class, () -> assessmentService.submitAssessment(request));
        verifyNoInteractions(residentRepository);
    }

    @Test
    @DisplayName("Rejects request with non-binary values (e.g. 2, -1) with BadRequestException")
    void submitAssessment_nonBinaryAnswers_throwsBadRequestException() {
        AssessmentSubmissionRequest request = AssessmentSubmissionRequest.builder()
                .residentId(1L)
                .answers(List.of(0, 1, 2, 0, 0, 0, 0, 0, 0, 0))
                .build();

        assertThrows(BadRequestException.class, () -> assessmentService.submitAssessment(request));
        verifyNoInteractions(residentRepository);
    }

    @Test
    @DisplayName("Rejects request with null element inside answers with BadRequestException")
    void submitAssessment_nullAnswerElement_throwsBadRequestException() {
        AssessmentSubmissionRequest request = AssessmentSubmissionRequest.builder()
                .residentId(1L)
                .answers(Arrays.asList(0, 1, null, 0, 0, 0, 0, 0, 0, 0))
                .build();

        assertThrows(BadRequestException.class, () -> assessmentService.submitAssessment(request));
        verifyNoInteractions(residentRepository);
    }

    @Test
    @DisplayName("Rejects request with null residentId with BadRequestException")
    void submitAssessment_nullResidentId_throwsBadRequestException() {
        AssessmentSubmissionRequest request = AssessmentSubmissionRequest.builder()
                .residentId(null)
                .answers(List.of(0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
                .build();

        assertThrows(BadRequestException.class, () -> assessmentService.submitAssessment(request));
    }

    @Test
    @DisplayName("Throws ResourceNotFoundException when resident does not exist")
    void submitAssessment_residentNotFound_throwsResourceNotFoundException() {
        when(residentRepository.findById(999L)).thenReturn(Optional.empty());

        AssessmentSubmissionRequest request = AssessmentSubmissionRequest.builder()
                .residentId(999L)
                .answers(List.of(0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
                .build();

        assertThrows(ResourceNotFoundException.class, () -> assessmentService.submitAssessment(request));
    }

    @Test
    @DisplayName("Trajectory shifts to IMPROVING when score increases compared to resident snapshot")
    void submitAssessment_trajectoryImprovingWhenScoreIncreases() {
        sampleResident.setEmotionalScore(60.0);
        when(residentRepository.findById(1L)).thenReturn(Optional.of(sampleResident));
        mockSaveAssessment();

        // 80.0 score > 60.0 + 2.0 -> IMPROVING
        AssessmentSubmissionRequest request = AssessmentSubmissionRequest.builder()
                .residentId(1L)
                .answers(List.of(0, 0, 0, 1, 1, 0, 0, 0, 0, 0))
                .build();

        ApiResponse<AssessmentResponse> response = assessmentService.submitAssessment(request);
        assertEquals(TrajectoryStatus.IMPROVING, response.getData().getTrajectory());
    }

    @Test
    @DisplayName("Trajectory shifts to INCREASING_RISK when score drops significantly")
    void submitAssessment_trajectoryIncreasingRiskWhenScoreDecreases() {
        sampleResident.setEmotionalScore(85.0);
        when(residentRepository.findById(1L)).thenReturn(Optional.of(sampleResident));
        mockSaveAssessment();

        // 50.0 score < 85.0 - 2.0 -> INCREASING_RISK
        AssessmentSubmissionRequest request = AssessmentSubmissionRequest.builder()
                .residentId(1L)
                .answers(List.of(0, 1, 0, 1, 0, 1, 0, 1, 0, 1))
                .build();

        ApiResponse<AssessmentResponse> response = assessmentService.submitAssessment(request);
        assertEquals(TrajectoryStatus.INCREASING_RISK, response.getData().getTrajectory());
    }
}
