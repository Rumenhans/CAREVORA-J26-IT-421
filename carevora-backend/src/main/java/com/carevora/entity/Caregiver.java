package com.carevora.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "caregivers")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Caregiver {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(name = "staff_code", length = 50)
    private String staffCode;

    @Column(length = 100)
    private String title; // e.g. Lead Care Coordinator

    @Column(length = 100)
    private String department;

    @ManyToMany
    @JoinTable(
        name = "caregiver_resident_assignment",
        joinColumns = @JoinColumn(name = "caregiver_id"),
        inverseJoinColumns = @JoinColumn(name = "resident_id")
    )
    @Builder.Default
    private Set<Resident> assignedResidents = new HashSet<>();

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
