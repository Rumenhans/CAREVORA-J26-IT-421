package com.carevora.repository;

import com.carevora.entity.Alert;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AlertRepository extends JpaRepository<Alert, Long> {
    List<Alert> findByResidentIdOrderByCreatedAtDesc(Long residentId);
    List<Alert> findAllByOrderByCreatedAtDesc();
    List<Alert> findByIsReadFalseOrderByCreatedAtDesc();
    long countByIsReadFalse();
}
