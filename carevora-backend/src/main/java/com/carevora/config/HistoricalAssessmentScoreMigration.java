package com.carevora.config;

import com.carevora.entity.Assessment;
import com.carevora.entity.AssessmentAnswer;
import com.carevora.entity.ContributingFactor;
import com.carevora.enums.RiskLevel;
import com.carevora.enums.WellnessStatus;
import com.carevora.repository.AssessmentRepository;
import com.carevora.repository.ContributingFactorRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Normalization component for historical questionnaire assessments.
 *
 * Requirements:
 * - Preserve database compatibility: does not alter schema or drop columns.
 * - Only assessments with verified ground-truth 10-answer items in assessment_answers
 *   are recalculated using clamp(100 - avgVal * 100, 0, 100).
 * - Legacy records WITHOUT raw answers (e.g. manually seeded mock assessments) are
 *   NOT silently reinterpreted or guessed; their existing scores are preserved as-is.
 */
@Component
@Order(100)
@RequiredArgsConstructor
@Slf4j
public class HistoricalAssessmentScoreMigration implements CommandLineRunner {

    private final AssessmentRepository assessmentRepository;
    private final ContributingFactorRepository contributingFactorRepository;

    @Override
    @Transactional
    public void run(String... args) {
        List<Assessment> assessments = assessmentRepository.findAll();
        for (Assessment assessment : assessments) {
            List<AssessmentAnswer> answers = assessment.getAnswers();
            // Ground truth exists only when answers were persisted (exactly 10 binary answers)
            if (answers != null && answers.size() == 10
                    && answers.stream().allMatch(a -> a.getSelectedIndex() != null && (a.getSelectedIndex() == 0 || a.getSelectedIndex() == 1))) {
                double avgVal = answers.stream().mapToDouble(AssessmentAnswer::getSelectedIndex).sum() / 10.0;
                double correctScore = Math.max(0.0, Math.min(100.0, 100.0 - (avgVal * 100.0)));
                correctScore = Math.round(correctScore * 10.0) / 10.0;

                Double currentOverall = assessment.getOverallScore();
                if (currentOverall == null || Math.abs(currentOverall - correctScore) > 0.001) {
                    log.info("Normalizing historical assessment id={}: overallScore {} -> {}, emotionalScore {} -> {}",
                            assessment.getId(), currentOverall, correctScore, assessment.getEmotionalScore(), correctScore);
                    assessment.setOverallScore(correctScore);
                    assessment.setEmotionalScore(correctScore);

                    WellnessStatus status = correctScore >= 75.0 ? WellnessStatus.LOOKING_GOOD : (correctScore >= 60.0 ? WellnessStatus.STABLE : WellnessStatus.NEEDS_ATTENTION);
                    RiskLevel risk = correctScore >= 75.0 ? RiskLevel.LOW : (correctScore >= 60.0 ? RiskLevel.MODERATE : RiskLevel.HIGH);
                    assessment.setStatus(status);
                    assessment.setRiskLevel(risk);

                    assessmentRepository.save(assessment);

                    List<ContributingFactor> factors = contributingFactorRepository.findByAssessmentId(assessment.getId());
                    for (ContributingFactor factor : factors) {
                        if ("Questionnaire".equalsIgnoreCase(factor.getCategory())) {
                            factor.setScore(correctScore);
                            contributingFactorRepository.save(factor);
                        }
                    }
                }
            } else {
                log.debug("Assessment id={} has {} answer rows; preserving legacy record as-is without reinterpretation.",
                        assessment.getId(), answers != null ? answers.size() : 0);
            }
        }
    }
}
