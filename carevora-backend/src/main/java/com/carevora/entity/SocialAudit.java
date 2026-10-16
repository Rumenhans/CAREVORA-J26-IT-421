package com.carevora.entity;

import com.carevora.enums.ActivityParticipationLevel;
import com.carevora.enums.AloneTimeContext;
import com.carevora.enums.PeerInteractionLevel;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "social_audits")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@com.fasterxml.jackson.annotation.JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class SocialAudit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "resident_id", nullable = false)
    @com.fasterxml.jackson.annotation.JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
    private Resident resident;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "caregiver_user_id", nullable = false)
    @com.fasterxml.jackson.annotation.JsonIgnoreProperties({"hibernateLazyInitializer", "handler", "passwordHash"})
    private User caregiverUser;

    @Column(name = "audit_date", nullable = false)
    @Builder.Default
    private LocalDateTime auditDate = LocalDateTime.now();

    @Column(name = "reporting_period_days", nullable = false)
    @Builder.Default
    private Integer reportingPeriodDays = 7;

    @Column(name = "family_in_person_visits")
    private Integer familyInPersonVisits;

    @Column(name = "family_phone_video_contacts")
    private Integer familyPhoneVideoContacts;

    @Column(name = "external_contact_unknown", nullable = false)
    @Builder.Default
    private Boolean externalContactUnknown = false;

    @Enumerated(EnumType.STRING)
    @Column(name = "peer_interaction_level", length = 30)
    private PeerInteractionLevel peerInteractionLevel;

    @Column(name = "activities_available")
    private Integer activitiesAvailable;

    @Column(name = "activities_attended")
    private Integer activitiesAttended;

    @Enumerated(EnumType.STRING)
    @Column(name = "activity_participation_level", length = 35)
    private ActivityParticipationLevel activityParticipationLevel;

    @Column(name = "health_mobility_barriers", nullable = false)
    @Builder.Default
    private Boolean healthMobilityBarriers = false;

    @Column(name = "estimated_hours_alone_per_day")
    private Double estimatedHoursAlonePerDay;

    @Enumerated(EnumType.STRING)
    @Column(name = "alone_time_context", length = 30)
    private AloneTimeContext aloneTimeContext;

    @Column(name = "caregiver_notes", length = 1000)
    private String caregiverNotes;

    @Column(name = "social_score")
    private Double socialScore;

    @Column(name = "score_provenance", length = 200)
    private String scoreProvenance;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
