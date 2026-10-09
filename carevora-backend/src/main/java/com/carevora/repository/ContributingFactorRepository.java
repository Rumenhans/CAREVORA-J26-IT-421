package com.carevora.repository;

import com.carevora.entity.ContributingFactor;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ContributingFactorRepository extends JpaRepository<ContributingFactor, Long> {
    List<ContributingFactor> findByAssessmentId(Long assessmentId);
    List<ContributingFactor> findByResidentId(Long residentId);
}
