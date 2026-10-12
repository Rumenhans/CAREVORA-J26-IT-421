package com.carevora.repository;

import com.carevora.entity.ElderHome;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ElderHomeRepository extends JpaRepository<ElderHome, Long> {
    Optional<ElderHome> findByFacilityCode(String facilityCode);
    Optional<ElderHome> findByName(String name);
    List<ElderHome> findByActiveTrue();
    boolean existsByFacilityCode(String facilityCode);
    boolean existsByNameIgnoreCase(String name);
}
