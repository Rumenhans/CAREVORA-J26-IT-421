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
@AllArgsConstructor
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
}
