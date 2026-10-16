package com.carevora.dto.socialaudit;

import com.carevora.enums.ActivityParticipationLevel;
import com.carevora.enums.AloneTimeContext;
import com.carevora.enums.PeerInteractionLevel;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SocialAuditRequest {

    @Builder.Default
    @Min(value = 1, message = "Reporting period must be at least 1 day")
    @Max(value = 30, message = "Reporting period cannot exceed 30 days")
    private Integer reportingPeriodDays = 7;

    @Min(value = 0, message = "In-person visits cannot be negative")
    @Max(value = 100, message = "In-person visits cannot exceed 100 per reporting period")
    private Integer familyInPersonVisits;

    @Min(value = 0, message = "Phone/video contacts cannot be negative")
    @Max(value = 100, message = "Phone/video contacts cannot exceed 100 per reporting period")
    private Integer familyPhoneVideoContacts;

    @Builder.Default
    private Boolean externalContactUnknown = false;

    private PeerInteractionLevel peerInteractionLevel;

    @Min(value = 0, message = "Activities available cannot be negative")
    @Max(value = 100, message = "Activities available cannot exceed 100 per reporting period")
    private Integer activitiesAvailable;

    @Min(value = 0, message = "Activities attended cannot be negative")
    @Max(value = 100, message = "Activities attended cannot exceed 100 per reporting period")
    private Integer activitiesAttended;

    private ActivityParticipationLevel activityParticipationLevel;

    @Builder.Default
    private Boolean healthMobilityBarriers = false;

    @DecimalMin(value = "0.0", message = "Estimated hours alone cannot be negative")
    @DecimalMax(value = "24.0", message = "Estimated hours alone cannot exceed 24.0 hours per day")
    private Double estimatedHoursAlonePerDay;

    private AloneTimeContext aloneTimeContext;

    @Size(max = 1000, message = "Caregiver notes cannot exceed 1000 characters")
    private String caregiverNotes;
}
