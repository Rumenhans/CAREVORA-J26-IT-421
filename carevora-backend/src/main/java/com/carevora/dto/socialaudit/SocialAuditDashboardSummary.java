package com.carevora.dto.socialaudit;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SocialAuditDashboardSummary {
    private int totalResidents;
    private int residentsWithCompletedAudit;
    private int residentsAwaitingAudit;
    private int auditsCompletedToday;
    private List<SocialAuditResponse> recentAudits;
}
