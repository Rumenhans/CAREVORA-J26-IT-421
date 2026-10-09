package com.carevora.config;

import com.carevora.entity.*;
import com.carevora.enums.*;
import com.carevora.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;

@Component
@RequiredArgsConstructor
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final ResidentRepository residentRepository;
    private final CaregiverRepository caregiverRepository;
    private final AssessmentRepository assessmentRepository;
    private final ContributingFactorRepository contributingFactorRepository;
    private final RecommendationRepository recommendationRepository;
    private final AlertRepository alertRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        if (userRepository.count() > 0) {
            return;
        }

        // Seed Caregiver
        User caregiverUser = User.builder()
                .email("eleanor.vance@carevora.com")
                .passwordHash(passwordEncoder.encode("carevora_admin"))
                .firstName("Eleanor")
                .lastName("Vance")
                .role(UserRole.CAREGIVER)
                .build();
        userRepository.save(caregiverUser);

        Caregiver caregiver = Caregiver.builder()
                .user(caregiverUser)
                .staffCode("CG-101")
                .title("Lead Care Coordinator")
                .department("Senior Behavioral Health")
                .build();
        caregiverRepository.save(caregiver);

        // Seed Resident 1: Sarah Jenkins
        User sarahUser = User.builder()
                .email("sarah.jenkins@carevora.com")
                .passwordHash(passwordEncoder.encode("carevora123"))
                .firstName("Sarah")
                .lastName("Jenkins")
                .role(UserRole.RESIDENT)
                .build();
        userRepository.save(sarahUser);

        Resident sarah = Resident.builder()
                .user(sarahUser)
                .roomNumber("Suite 204")
                .age(78)
                .emergencyContact("+1 (555) 019-2834")
                .currentStatus(WellnessStatus.LOOKING_GOOD)
                .riskLevel(RiskLevel.LOW)
                .trajectory(TrajectoryStatus.IMPROVING)
                .emotionalScore(88.0)
                .socialScore(82.0)
                .lastAssessmentDate(LocalDateTime.now().minusHours(2))
                .build();
        residentRepository.save(sarah);

        // Seed Resident 2: Arthur Pendelton
        User arthurUser = User.builder()
                .email("arthur.p@carevora.com")
                .passwordHash(passwordEncoder.encode("carevora123"))
                .firstName("Arthur")
                .lastName("Pendelton")
                .role(UserRole.RESIDENT)
                .build();
        userRepository.save(arthurUser);

        Resident arthur = Resident.builder()
                .user(arthurUser)
                .roomNumber("Suite 112")
                .age(82)
                .emergencyContact("+1 (555) 018-9921")
                .currentStatus(WellnessStatus.NEEDS_ATTENTION)
                .riskLevel(RiskLevel.MODERATE)
                .trajectory(TrajectoryStatus.INCREASING_RISK)
                .emotionalScore(54.0)
                .socialScore(48.0)
                .lastAssessmentDate(LocalDateTime.now().minusHours(5))
                .build();
        residentRepository.save(arthur);

        // Seed Resident 3: Margaret Chen
        User margaretUser = User.builder()
                .email("margaret.c@carevora.com")
                .passwordHash(passwordEncoder.encode("carevora123"))
                .firstName("Margaret")
                .lastName("Chen")
                .role(UserRole.RESIDENT)
                .build();
        userRepository.save(margaretUser);

        Resident margaret = Resident.builder()
                .user(margaretUser)
                .roomNumber("Suite 305")
                .age(75)
                .currentStatus(WellnessStatus.STABLE)
                .riskLevel(RiskLevel.LOW)
                .trajectory(TrajectoryStatus.STABLE)
                .emotionalScore(76.0)
                .socialScore(78.0)
                .lastAssessmentDate(LocalDateTime.now().minusHours(8))
                .build();
        residentRepository.save(margaret);

        // Seed Resident 4: Robert Hastings
        User robertUser = User.builder()
                .email("robert.h@carevora.com")
                .passwordHash(passwordEncoder.encode("carevora123"))
                .firstName("Robert")
                .lastName("Hastings")
                .role(UserRole.RESIDENT)
                .build();
        userRepository.save(robertUser);

        Resident robert = Resident.builder()
                .user(robertUser)
                .roomNumber("Suite 108")
                .age(84)
                .currentStatus(WellnessStatus.CHECK_IN_NEEDED)
                .riskLevel(RiskLevel.HIGH)
                .trajectory(TrajectoryStatus.INCREASING_RISK)
                .emotionalScore(38.0)
                .socialScore(35.0)
                .lastAssessmentDate(LocalDateTime.now().minusHours(1))
                .build();
        residentRepository.save(robert);

        // Seed Sarah's Assessment
        Assessment sarahAssessment = Assessment.builder()
                .resident(sarah)
                .overallScore(86.0)
                .emotionalScore(88.0)
                .socialScore(84.0)
                .status(WellnessStatus.LOOKING_GOOD)
                .riskLevel(RiskLevel.LOW)
                .trajectory(TrajectoryStatus.IMPROVING)
                .encouragingMessage("You're feeling uplifted and well connected today!")
                .facialCheckIncluded(true)
                .voiceCheckIncluded(true)
                .build();
        assessmentRepository.save(sarahAssessment);

        contributingFactorRepository.saveAll(List.of(
                ContributingFactor.builder().assessment(sarahAssessment).resident(sarah).title("Morning Garden Walk").score(92.0).category("Social").description("Active outdoor engagement noted early morning").build(),
                ContributingFactor.builder().assessment(sarahAssessment).resident(sarah).title("Calm Vocal Tone").score(85.0).category("Voice").description("Speech rhythm exhibited relaxed cadence").build(),
                ContributingFactor.builder().assessment(sarahAssessment).resident(sarah).title("Positive Expression").score(88.0).category("Facial").description("Frequent smiles during community greeting").build()
        ));

        recommendationRepository.save(Recommendation.builder()
                .resident(sarah)
                .assessment(sarahAssessment)
                .title("Afternoon Tea Social")
                .reason("Keep up the warm social connection with fellow residents.")
                .priority("Low")
                .suggestedAction("Join community lounge at 3:30 PM")
                .iconKey("social")
                .build());

        // Seed Alerts
        alertRepository.saveAll(List.of(
                Alert.builder().resident(robert).title("Sudden Dip in Social Wellness").message("Robert has missed group activities for 2 consecutive days.").type(AlertType.WELLNESS_ALERT).priority(AlertPriority.HIGH).isRead(false).build(),
                Alert.builder().resident(arthur).title("Risk Trajectory Shift").message("RALPA trajectory shifted from Stable towards Increasing Risk.").type(AlertType.RISK_ALERT).priority(AlertPriority.MEDIUM).isRead(false).build(),
                Alert.builder().resident(sarah).title("Daily Assessment Completed").message("Sarah completed her morning emotional wellness check-in.").type(AlertType.ASSESSMENT_ALERT).priority(AlertPriority.LOW).isRead(true).build()
        ));
    }
}
