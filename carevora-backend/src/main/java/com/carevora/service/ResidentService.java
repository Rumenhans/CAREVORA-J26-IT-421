package com.carevora.service;

import com.carevora.dto.ApiResponse;
import com.carevora.dto.resident.ResidentResponse;
import com.carevora.entity.Resident;
import com.carevora.exception.ResourceNotFoundException;
import com.carevora.repository.AlertRepository;
import com.carevora.repository.ResidentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ResidentService {

    private final ResidentRepository residentRepository;
    private final AlertRepository alertRepository;

    public ApiResponse<List<ResidentResponse>> getAllResidents(String search) {
        List<Resident> list;
        if (search != null && !search.trim().isEmpty()) {
            list = residentRepository.searchResidents(search.trim());
        } else {
            list = residentRepository.findAll();
        }

        List<ResidentResponse> responses = list.stream().map(this::mapToResponse).collect(Collectors.toList());
        return ApiResponse.ok(responses);
    }

    public ApiResponse<ResidentResponse> getResidentById(Long id) {
        Resident resident = residentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Resident not found with id: " + id));
        return ApiResponse.ok(mapToResponse(resident));
    }

    private ResidentResponse mapToResponse(Resident r) {
        int unreadAlerts = (int) alertRepository.findByResidentIdOrderByCreatedAtDesc(r.getId())
                .stream().filter(a -> !a.getIsRead()).count();

        return ResidentResponse.builder()
                .id(r.getId())
                .userId(r.getUser().getId())
                .name(r.getUser().getFullName())
                .age(r.getAge())
                .roomNumber(r.getRoomNumber())
                .avatarUrl(r.getUser().getAvatarUrl())
                .currentStatus(r.getCurrentStatus())
                .riskLevel(r.getRiskLevel())
                .trajectory(r.getTrajectory())
                .emotionalScore(r.getEmotionalScore())
                .socialScore(r.getSocialScore())
                .lastAssessmentDate(r.getLastAssessmentDate())
                .unreadAlertsCount(unreadAlerts)
                .build();
    }
}
