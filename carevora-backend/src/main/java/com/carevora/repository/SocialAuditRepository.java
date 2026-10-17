package com.carevora.repository;

import com.carevora.entity.SocialAudit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SocialAuditRepository extends JpaRepository<SocialAudit, Long> {
    List<SocialAudit> findByResidentIdOrderByAuditDateDesc(Long residentId);
    Optional<SocialAudit> findFirstByResidentIdOrderByAuditDateDesc(Long residentId);
    Optional<SocialAudit> findByIdAndResidentId(Long id, Long residentId);
    long countByResidentId(Long residentId);
    List<SocialAudit> findTop10ByOrderByAuditDateDesc();
    List<SocialAudit> findTop10ByResidentElderHomeIdOrderByAuditDateDesc(Long elderHomeId);
    long countByAuditDateAfter(java.time.LocalDateTime date);
    long countByResidentElderHomeIdAndAuditDateAfter(Long elderHomeId, java.time.LocalDateTime date);
}
