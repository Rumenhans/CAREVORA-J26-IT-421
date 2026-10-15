package com.carevora.repository;

import com.carevora.entity.CognitiveAssessmentSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CognitiveAssessmentSessionRepository extends JpaRepository<CognitiveAssessmentSession, Long> {

    Optional<CognitiveAssessmentSession> findBySessionId(String sessionId);

    List<CognitiveAssessmentSession> findByResidentIdOrderByCreatedAtDesc(Long residentId);

    Optional<CognitiveAssessmentSession> findFirstByResidentIdAndStatusOrderByCreatedAtDesc(Long residentId, String status);

    boolean existsBySessionId(String sessionId);
}
