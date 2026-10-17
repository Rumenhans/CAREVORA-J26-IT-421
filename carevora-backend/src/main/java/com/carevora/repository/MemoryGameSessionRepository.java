package com.carevora.repository;

import com.carevora.entity.MemoryGameSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MemoryGameSessionRepository extends JpaRepository<MemoryGameSession, Long> {
    Optional<MemoryGameSession> findBySessionId(String sessionId);
    List<MemoryGameSession> findByResidentIdOrderByCompletedAtDesc(Long residentId);
    List<MemoryGameSession> findByResidentIdAndGameTypeOrderByCompletedAtDesc(Long residentId, String gameType);
}
