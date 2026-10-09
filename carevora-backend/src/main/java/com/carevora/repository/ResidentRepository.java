package com.carevora.repository;

import com.carevora.entity.Resident;
import com.carevora.enums.RiskLevel;
import com.carevora.enums.WellnessStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ResidentRepository extends JpaRepository<Resident, Long> {
    Optional<Resident> findByUserId(Long userId);
    List<Resident> findByCurrentStatus(WellnessStatus status);
    List<Resident> findByRiskLevel(RiskLevel riskLevel);

    @Query("SELECT r FROM Resident r JOIN r.user u WHERE " +
           "LOWER(u.firstName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "LOWER(u.lastName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "LOWER(r.roomNumber) LIKE LOWER(CONCAT('%', :query, '%'))")
    List<Resident> searchResidents(@Param("query") String query);

    long countByRiskLevel(RiskLevel riskLevel);
    long countByCurrentStatus(WellnessStatus status);
}
