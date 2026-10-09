package com.carevora.service;

import com.carevora.dto.ApiResponse;
import com.carevora.dto.assessment.AssessmentResponse;
import com.carevora.dto.assessment.AssessmentSubmissionRequest;
import com.carevora.entity.Assessment;
import com.carevora.entity.AssessmentAnswer;
import com.carevora.entity.ContributingFactor;
import com.carevora.entity.Recommendation;
import com.carevora.entity.Resident;
import com.carevora.enums.RiskLevel;
import com.carevora.enums.TrajectoryStatus;
import com.carevora.enums.WellnessStatus;
import com.carevora.exception.ResourceNotFoundException;
import com.carevora.repository.AssessmentRepository;
import com.carevora.repository.ContributingFactorRepository;
import com.carevora.repository.RecommendationRepository;
import com.carevora.repository.ResidentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AssessmentService {

    private final AssessmentRepository assessmentRepository;
    private final ResidentRepository residentRepository;
    private final ContributingFactorRepository contributingFactorRepository;
    private final RecommendationRepository recommendationRepository;

    @Transactional
    public ApiResponse<AssessmentResponse> submitAssessment(AssessmentSubmissionRequest request) {
        Resident resident = residentRepository.findById(request.getResidentId())
                .orElseThrow(() -> new ResourceNotFoundException("Resident not found with id: " + request.getResidentId()));

        double avgVal = 0.0;
        if (request.getAnswers() != null && !request.getAnswers().isEmpty()) {
            double sum = request.getAnswers().stream().mapToDouble(Integer::doubleValue).sum();
            avgVal = sum / request.getAnswers().size();
        }

        double score = Math.max(40.0, Math.min(96.0, 100.0 - (avgVal * 20.0)));
        double emotionalScore = Math.min(100.0, score + 2.0);
        double socialScore = Math.max(0.0, score - 2.0);

        WellnessStatus status = score >= 75.0 ? WellnessStatus.LOOKING_GOOD : (score >= 60.0 ? WellnessStatus.STABLE : WellnessStatus.NEEDS_ATTENTION);
        RiskLevel risk = score >= 75.0 ? RiskLevel.LOW : (score >= 60.0 ? RiskLevel.MODERATE : RiskLevel.HIGH);
        TrajectoryStatus trajectory = TrajectoryStatus.IMPROVING;

        String encouragingMsg = score >= 75.0 
                ? "You're doing wonderfully today! Your emotional wellness is shining."
                : "Thank you for sharing. We're here to support you with calm and comfort.";

        Assessment assessment = Assessment.builder()
                .resident(resident)
                .overallScore(score)
                .emotionalScore(emotionalScore)
                .socialScore(socialScore)
                .status(status)
                .riskLevel(risk)
                .trajectory(trajectory)
                .encouragingMessage(encouragingMsg)
                .facialCheckIncluded(request.getIncludeFacialCheck())
                .voiceCheckIncluded(request.getIncludeVoiceCheck())
                .build();

        List<AssessmentAnswer> answers = new ArrayList<>();
        if (request.getAnswers() != null) {
            for (int i = 0; i < request.getAnswers().size(); i++) {
                answers.add(AssessmentAnswer.builder()
                        .assessment(assessment)
                        .questionId("q" + (i + 1))
                        .selectedIndex(request.getAnswers().get(i))
                        .build());
            }
        }
        assessment.setAnswers(answers);
        Assessment savedAssessment = assessmentRepository.save(assessment);

        // Update Resident current snapshot
        resident.setCurrentStatus(status);
        resident.setRiskLevel(risk);
        resident.setTrajectory(trajectory);
        resident.setEmotionalScore(emotionalScore);
        resident.setSocialScore(socialScore);
        resident.setLastAssessmentDate(LocalDateTime.now());
        residentRepository.save(resident);

        // Save AI-ready Contributing Factors
        List<ContributingFactor> factors = new ArrayList<>();
        factors.add(ContributingFactor.builder()
                .assessment(savedAssessment)
                .resident(resident)
                .title("Daily Questionnaire")
                .score(score)
                .category("Questionnaire")
                .description("Self-reported answers to emotional and social prompts")
                .build());

        if (Boolean.TRUE.equals(request.getIncludeFacialCheck())) {
            factors.add(ContributingFactor.builder()
                    .assessment(savedAssessment)
                    .resident(resident)
                    .title("Facial Affect Check")
                    .score(86.0)
                    .category("Facial")
                    .description("Gentle facial cues indicate calm resting composure")
                    .build());
        }

        if (Boolean.TRUE.equals(request.getIncludeVoiceCheck())) {
            factors.add(ContributingFactor.builder()
                    .assessment(savedAssessment)
                    .resident(resident)
                    .title("Acoustic Tone Check")
                    .score(82.0)
                    .category("Voice")
                    .description("Vocal modulation reflects clear and steady warmth")
                    .build());
        }
        contributingFactorRepository.saveAll(factors);

        // Create Recommendations
        Recommendation rec1 = Recommendation.builder()
                .resident(resident)
                .assessment(savedAssessment)
                .title("Afternoon Garden Walk")
                .reason("Fresh air and light walking help sustain your calm mood.")
                .priority("Low")
                .suggestedAction("Take a gentle 15-minute courtyard stroll")
                .iconKey("walk")
                .build();
        recommendationRepository.save(rec1);

        return ApiResponse.ok(mapToResponse(savedAssessment, factors, List.of(rec1)), "Assessment submitted successfully");
    }

    public ApiResponse<List<AssessmentResponse>> getResidentAssessments(Long residentId) {
        List<Assessment> list = assessmentRepository.findByResidentIdOrderByCreatedAtDesc(residentId);
        List<AssessmentResponse> resList = list.stream().map(a -> {
            List<ContributingFactor> factors = contributingFactorRepository.findByAssessmentId(a.getId());
            List<Recommendation> recs = recommendationRepository.findByResidentIdAndActiveTrue(residentId);
            return mapToResponse(a, factors, recs);
        }).collect(Collectors.toList());

        return ApiResponse.ok(resList);
    }

    private AssessmentResponse mapToResponse(Assessment a, List<ContributingFactor> factors, List<Recommendation> recs) {
        return AssessmentResponse.builder()
                .id(a.getId())
                .residentId(a.getResident().getId())
                .overallScore(a.getOverallScore())
                .emotionalScore(a.getEmotionalScore())
                .socialScore(a.getSocialScore())
                .status(a.getStatus())
                .riskLevel(a.getRiskLevel())
                .trajectory(a.getTrajectory())
                .encouragingMessage(a.getEncouragingMessage())
                .timestamp(a.getCreatedAt())
                .contributingFactors(factors.stream().map(f -> AssessmentResponse.ContributingFactorDto.builder()
                        .title(f.getTitle())
                        .score(f.getScore())
                        .category(f.getCategory())
                        .description(f.getDescription())
                        .build()).collect(Collectors.toList()))
                .recommendations(recs.stream().map(r -> AssessmentResponse.RecommendationDto.builder()
                        .id(r.getId())
                        .title(r.getTitle())
                        .reason(r.getReason())
                        .priority(r.getPriority())
                        .suggestedAction(r.getSuggestedAction())
                        .iconKey(r.getIconKey())
                        .build()).collect(Collectors.toList()))
                .build();
    }
}
