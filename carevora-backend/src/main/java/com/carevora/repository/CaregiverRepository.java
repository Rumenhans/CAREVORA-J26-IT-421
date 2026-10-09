package com.carevora.repository;

import com.carevora.entity.Caregiver;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CaregiverRepository extends JpaRepository<Caregiver, Long> {
    Optional<Caregiver> findByUserId(Long userId);
    Optional<Caregiver> findByStaffCode(String staffCode);
}
