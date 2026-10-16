package com.carevora.repository;

import com.carevora.entity.CognitiveAssessment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CognitiveAssessmentRepository extends JpaRepository<CognitiveAssessment, Long> {
    List<CognitiveAssessment> findByResidentIdOrderByCreatedAtDesc(Long residentId);
    boolean existsBySessionId(String sessionId);
}

