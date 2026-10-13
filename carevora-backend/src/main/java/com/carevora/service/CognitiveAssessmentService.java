package com.carevora.service;

import com.carevora.dto.ApiResponse;
import com.carevora.dto.cognitive.CognitiveAiResult;
import com.carevora.dto.cognitive.CognitiveAssessmentResponse;
import com.carevora.dto.cognitive.CognitiveAssessmentSubmissionRequest;
import com.carevora.entity.Caregiver;
import com.carevora.entity.CognitiveAssessment;
import com.carevora.entity.Resident;
import com.carevora.entity.User;
import com.carevora.enums.UserRole;
import com.carevora.exception.BadRequestException;
import com.carevora.exception.ResourceNotFoundException;
import com.carevora.repository.CaregiverRepository;
import com.carevora.repository.CognitiveAssessmentRepository;
import com.carevora.repository.ResidentRepository;
import com.carevora.repository.UserRepository;
import com.carevora.security.SecurityUtils;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CognitiveAssessmentService {

    private final CognitiveAssessmentRepository cognitiveAssessmentRepository;
    private final ResidentRepository residentRepository;
    private final UserRepository userRepository;
    private final CaregiverRepository caregiverRepository;
    private final AiMlService aiMlService;
    private final ObjectMapper objectMapper;

    // Fixed ACRF Base Weights established in system specifications
    private static final Map<String, Double> ACRF_WEIGHTS = Map.of(
            "memory", 0.25,
            "attention", 0.20,
            "orientation", 0.20,
            "recall", 0.20,
            "reasoning", 0.15
    );

    @Transactional
    public ApiResponse<CognitiveAssessmentResponse> submitAssessment(CognitiveAssessmentSubmissionRequest request) {
        validateCategoryScores(request);
        validateOptionalMlFeatures(request);

        Resident resident = residentRepository.findById(request.getResidentId())
                .orElseThrow(() -> new ResourceNotFoundException("Resident not found with id: " + request.getResidentId()));

        enforceResidentAccess(resident);

        // Determine effective demographics without inventing or synthesizing missing values
        Integer effectiveAge = request.getAge() != null ? request.getAge() : resident.getAge();
        Integer effectiveEducationYears = request.getEducationYears() != null ? request.getEducationYears() : resident.getEducationYears();

        if (request.getEducationYears() != null && resident.getEducationYears() == null) {
            resident.setEducationYears(request.getEducationYears());
        }

        // Call FastAPI AI Microservice for ACRF scoring and ML model inference
        CognitiveAiResult aiResult = aiMlService.predictCognitive(
                resident.getId(),
                request.getMemory(),
                request.getAttention(),
                request.getOrientation(),
                request.getRecall(),
                request.getReasoning(),
                effectiveAge,
                effectiveEducationYears,
                request.getAccuracies(),
                request.getResponseTimes()
        );

        String currentUserName = SecurityUtils.getCurrentUser(userRepository)
                .map(User::getFullName)
                .orElse("Care Specialist");

        CognitiveAssessmentResponse.MlModelStatusDto mlEval = aiResult.getMlModelEvaluation();
        boolean mlAvailable = mlEval != null && mlEval.isAvailable();
        String mlPrediction = mlAvailable && mlEval.getPrediction() != null
                ? String.valueOf(mlEval.getPrediction())
                : null;
        Boolean alertTriggered = mlAvailable && Boolean.TRUE.equals(mlEval.getAlertTriggered());

        Double highRiskProb = null;
        String classProbsJson = null;
        if (mlAvailable && mlEval.getProbabilities() != null) {
            highRiskProb = mlEval.getProbabilities().get("High");
            try {
                classProbsJson = objectMapper.writeValueAsString(mlEval.getProbabilities());
            } catch (Exception ignored) {}
        }

        CognitiveAssessment entity = CognitiveAssessment.builder()
                .resident(resident)
                .memoryScore(request.getMemory())
                .attentionScore(request.getAttention())
                .orientationScore(request.getOrientation())
                .recallScore(request.getRecall())
                .reasoningScore(request.getReasoning())
                .acrfScore(aiResult.getAcrfScore())
                .assessedBy(currentUserName)
                .mlAvailable(mlAvailable)
                .mlPrediction(mlPrediction)
                .alertTriggered(alertTriggered)
                .highRiskProbability(highRiskProb)
                .classProbabilities(classProbsJson)
                .build();

        CognitiveAssessment saved = cognitiveAssessmentRepository.save(entity);

        // Update Resident current cognitive snapshot (without modifying emotional or social scores)
        resident.setCognitiveScore(aiResult.getAcrfScore());
        resident.setLastAssessmentDate(LocalDateTime.now());
        residentRepository.save(resident);

        CognitiveAssessmentResponse response = mapToResponse(saved, aiResult);
        return ApiResponse.ok(response, "Cognitive assessment evaluated and saved successfully");
    }

    @Transactional(readOnly = true)
    public ApiResponse<List<CognitiveAssessmentResponse>> getResidentCognitiveAssessments(Long residentId) {
        Resident resident = residentRepository.findById(residentId)
                .orElseThrow(() -> new ResourceNotFoundException("Resident not found with id: " + residentId));

        enforceResidentAccess(resident);

        List<CognitiveAssessment> history = cognitiveAssessmentRepository.findByResidentIdOrderByCreatedAtDesc(residentId);
        List<CognitiveAssessmentResponse> responses = history.stream()
                .map(this::mapHistoryToResponse)
                .collect(Collectors.toList());

        return ApiResponse.ok(responses, "Resident cognitive assessment history retrieved successfully");
    }

    private void validateCategoryScores(CognitiveAssessmentSubmissionRequest req) {
        validateFiniteNumber(req.getMemory(), "Memory");
        validateFiniteNumber(req.getAttention(), "Attention");
        validateFiniteNumber(req.getOrientation(), "Orientation");
        validateFiniteNumber(req.getRecall(), "Recall");
        validateFiniteNumber(req.getReasoning(), "Reasoning");
    }

    private void validateOptionalMlFeatures(CognitiveAssessmentSubmissionRequest req) {
        if (req.getEducationYears() != null) {
            if (req.getEducationYears() < 0 || req.getEducationYears() > 40) {
                throw new BadRequestException("Education years must be between 0 and 40");
            }
        }
        if (req.getAge() != null) {
            if (req.getAge() <= 0 || req.getAge() > 130) {
                throw new BadRequestException("Age must be between 1 and 130");
            }
        }
        if (req.getAccuracies() != null) {
            for (Map.Entry<String, Double> entry : req.getAccuracies().entrySet()) {
                Double acc = entry.getValue();
                if (acc != null) {
                    if (Double.isNaN(acc) || Double.isInfinite(acc) || acc < 0.0 || acc > 100.0) {
                        throw new BadRequestException("Accuracy for '" + entry.getKey() + "' must be a finite number in range [0.0, 100.0]");
                    }
                }
            }
        }
        if (req.getResponseTimes() != null) {
            for (Map.Entry<String, Double> entry : req.getResponseTimes().entrySet()) {
                Double rt = entry.getValue();
                if (rt != null) {
                    if (Double.isNaN(rt) || Double.isInfinite(rt) || rt <= 0.0) {
                        throw new BadRequestException("Response time for '" + entry.getKey() + "' must be a finite number > 0.0 seconds");
                    }
                }
            }
        }
    }

    private void validateFiniteNumber(Double val, String fieldName) {
        if (val == null) {
            throw new BadRequestException(fieldName + " score is required");
        }
        if (Double.isNaN(val) || Double.isInfinite(val)) {
            throw new BadRequestException(fieldName + " score cannot be NaN or infinite");
        }
        if (val < 0.0 || val > 100.0) {
            throw new BadRequestException(fieldName + " score must be within range [0.0, 100.0]");
        }
    }

    private void enforceResidentAccess(Resident resident) {
        Optional<User> currentUserOpt = SecurityUtils.getCurrentUser(userRepository);
        if (currentUserOpt.isEmpty()) {
            return; // Internal / system execution or test context without security context
        }

        User currentUser = currentUserOpt.get();
        UserRole role = currentUser.getRole();

        // 1. Caregiver can only access residents in their assigned Elder Home
        if (role == UserRole.CAREGIVER) {
            Optional<Caregiver> caregiverOpt = caregiverRepository.findByUserId(currentUser.getId());
            if (caregiverOpt.isEmpty() || caregiverOpt.get().getElderHome() == null ||
                    resident.getElderHome() == null ||
                    !resident.getElderHome().getId().equals(caregiverOpt.get().getElderHome().getId())) {
                throw new AccessDeniedException("Access denied: You can only view/assess residents belonging to your assigned Elder Home.");
            }
        }
        // 2. Elder can only access their own assessments
        else if (role == UserRole.ELDER || role == UserRole.RESIDENT) {
            if (!resident.getUser().getId().equals(currentUser.getId())) {
                throw new AccessDeniedException("Access denied: Elders are not authorized to view other elders' records.");
            }
        }
        // 3. DOCTOR and ADMIN have full cross-facility authorization
    }

    private CognitiveAssessmentResponse mapToResponse(CognitiveAssessment saved, CognitiveAiResult aiResult) {
        return CognitiveAssessmentResponse.builder()
                .id(saved.getId())
                .residentId(saved.getResident().getId())
                .residentName(saved.getResident().getUser().getFullName())
                .memory(saved.getMemoryScore())
                .attention(saved.getAttentionScore())
                .orientation(saved.getOrientationScore())
                .recall(saved.getRecallScore())
                .reasoning(saved.getReasoningScore())
                .acrfScore(aiResult.getAcrfScore())
                .mlPrediction(saved.getMlPrediction())
                .alertTriggered(saved.getAlertTriggered())
                .categoryContributions(aiResult.getCategoryContributions())
                .weightsApplied(aiResult.getWeightsApplied())
                .mlModelEvaluation(aiResult.getMlModelEvaluation())
                .methodology(aiResult.getMethodology())
                .clinicalDisclaimer(aiResult.getClinicalDisclaimer())
                .assessedBy(saved.getAssessedBy())
                .createdAt(saved.getCreatedAt())
                .build();
    }

    private CognitiveAssessmentResponse mapHistoryToResponse(CognitiveAssessment c) {
        List<CognitiveAssessmentResponse.CategoryContributionDto> contributions = new ArrayList<>();
        contributions.add(createContrib("memory", c.getMemoryScore(), 0.25));
        contributions.add(createContrib("attention", c.getAttentionScore(), 0.20));
        contributions.add(createContrib("orientation", c.getOrientationScore(), 0.20));
        contributions.add(createContrib("recall", c.getRecallScore(), 0.20));
        contributions.add(createContrib("reasoning", c.getReasoningScore(), 0.15));

        Map<String, Double> parsedProbs = null;
        if (c.getClassProbabilities() != null && !c.getClassProbabilities().isBlank()) {
            try {
                parsedProbs = objectMapper.readValue(
                        c.getClassProbabilities(),
                        new TypeReference<Map<String, Double>>() {}
                );
            } catch (Exception ignored) {}
        }

        boolean mlAvailable = Boolean.TRUE.equals(c.getMlAvailable());
        CognitiveAssessmentResponse.MlModelStatusDto mlStatus;
        if (mlAvailable) {
            mlStatus = CognitiveAssessmentResponse.MlModelStatusDto.builder()
                    .available(true)
                    .modelType("RandomForestClassifier")
                    .statusMessage("Experimental prediction generated using artifact trained on synthetic data. Non-clinical demonstration metric.")
                    .prediction(c.getMlPrediction())
                    .probabilities(parsedProbs)
                    .alertTriggered(c.getAlertTriggered())
                    .alertThreshold(0.48)
                    .experimentalLabel("Synthetic Data Experiment (Non-Clinical)")
                    .build();
        } else {
            mlStatus = CognitiveAssessmentResponse.MlModelStatusDto.builder()
                    .available(false)
                    .modelType("RandomForestClassifier")
                    .statusMessage("Random Forest model inference was unavailable (missing required task metrics at assessment time)")
                    .prediction(null)
                    .probabilities(null)
                    .alertTriggered(false)
                    .alertThreshold(0.48)
                    .experimentalLabel("Synthetic Data Experiment (Non-Clinical)")
                    .build();
        }

        return CognitiveAssessmentResponse.builder()
                .id(c.getId())
                .residentId(c.getResident().getId())
                .residentName(c.getResident().getUser().getFullName())
                .memory(c.getMemoryScore())
                .attention(c.getAttentionScore())
                .orientation(c.getOrientationScore())
                .recall(c.getRecallScore())
                .reasoning(c.getReasoningScore())
                .acrfScore(c.getAcrfScore())
                .mlPrediction(c.getMlPrediction())
                .alertTriggered(c.getAlertTriggered())
                .categoryContributions(contributions)
                .weightsApplied(ACRF_WEIGHTS)
                .mlModelEvaluation(mlStatus)
                .methodology("ACRF Fixed Base Weights")
                .clinicalDisclaimer("The ACRF score is an arithmetic weighted wellness metric. Non-diagnostic.")
                .assessedBy(c.getAssessedBy())
                .createdAt(c.getCreatedAt())
                .build();
    }

    private CognitiveAssessmentResponse.CategoryContributionDto createContrib(String category, Double score, Double weight) {
        double contribution = Math.round(score * weight * 10000.0) / 10000.0;
        return CognitiveAssessmentResponse.CategoryContributionDto.builder()
                .category(category)
                .score(score)
                .weight(weight)
                .contribution(contribution)
                .weightPercentage((int) (weight * 100) + "%")
                .build();
    }
}
