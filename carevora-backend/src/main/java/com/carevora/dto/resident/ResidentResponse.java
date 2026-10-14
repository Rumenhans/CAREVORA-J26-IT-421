package com.carevora.dto.resident;

import com.carevora.enums.RiskLevel;
import com.carevora.enums.TrajectoryStatus;
import com.carevora.enums.WellnessStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
public class ResidentResponse {
    private Long id;
    private Long userId;
    private String name;
    private Integer age;
    private Integer educationYears;
    private String roomNumber;
    private String avatarUrl;
    private WellnessStatus currentStatus;
    private RiskLevel riskLevel;
    private TrajectoryStatus trajectory;
    private Double emotionalScore;
    private Double socialScore;
    private Double cognitiveScore;
    private LocalDateTime lastAssessmentDate;
    private int unreadAlertsCount;
    private Long elderHomeId;
    private String elderHomeName;

    public ResidentResponse(
            Long id,
            Long userId,
            String name,
            Integer age,
            Integer educationYears,
            String roomNumber,
            String avatarUrl,
            WellnessStatus currentStatus,
            RiskLevel riskLevel,
            TrajectoryStatus trajectory,
            Double emotionalScore,
            Double socialScore,
            Double cognitiveScore,
            LocalDateTime lastAssessmentDate,
            int unreadAlertsCount,
            Long elderHomeId,
            String elderHomeName) {
        this.id = id;
        this.userId = userId;
        this.name = name;
        this.age = age;
        this.educationYears = educationYears;
        this.roomNumber = roomNumber;
        this.avatarUrl = avatarUrl;
        this.currentStatus = currentStatus;
        this.riskLevel = riskLevel;
        this.trajectory = trajectory;
        this.emotionalScore = emotionalScore;
        this.socialScore = socialScore;
        this.cognitiveScore = cognitiveScore;
        this.lastAssessmentDate = lastAssessmentDate;
        this.unreadAlertsCount = unreadAlertsCount;
        this.elderHomeId = elderHomeId;
        this.elderHomeName = elderHomeName;
    }
}
