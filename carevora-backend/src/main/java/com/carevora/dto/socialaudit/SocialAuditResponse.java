package com.carevora.dto.socialaudit;

import com.carevora.enums.ActivityParticipationLevel;
import com.carevora.enums.AloneTimeContext;
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
public class SocialAuditResponse {

    private Long id;
    private Long residentId;
    private String residentName;
    private Long caregiverUserId;
    private String caregiverName;
    private String caregiverStaffCode;
    private LocalDateTime auditDate;
    private Integer reportingPeriodDays;

    // Family and external contacts
    private Integer familyInPersonVisits;
    private Integer familyPhoneVideoContacts;
    private Integer totalExternalContacts;
    private Boolean externalContactUnknown;

    // Peer interaction
    private PeerInteractionLevel peerInteractionLevel;

    // Activity participation
    private Integer activitiesAvailable;
    private Integer activitiesAttended;
    private Double activityParticipationRate;
    private ActivityParticipationLevel activityParticipationLevel;
    private Boolean healthMobilityBarriers;

    // Time spent alone
    private Double estimatedHoursAlonePerDay;
    private AloneTimeContext aloneTimeContext;

    // Caregiver notes & metadata
    private String caregiverNotes;
    private Double socialScore;
    private String scoreProvenance;
    private LocalDateTime createdAt;
}
