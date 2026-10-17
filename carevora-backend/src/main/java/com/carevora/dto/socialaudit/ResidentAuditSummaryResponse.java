package com.carevora.dto.socialaudit;

import com.carevora.enums.PeerInteractionLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ResidentAuditSummaryResponse {
    private Long residentId;
    private String name;
    private String roomNumber;
    private Integer age;
    private String avatarUrl;
    private Long elderHomeId;
    private String elderHomeName;
    private boolean hasCompletedAudit;
    private Double latestSocialScore;
    private LocalDateTime latestAuditDate;
    private PeerInteractionLevel latestPeerInteractionLevel;
    private long auditCount;
}
