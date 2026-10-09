package com.carevora.repository;

import com.carevora.entity.Recommendation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RecommendationRepository extends JpaRepository<Recommendation, Long> {
    List<Recommendation> findByResidentIdAndActiveTrue(Long residentId);
    List<Recommendation> findByResidentIdOrderByCreatedAtDesc(Long residentId);
}
