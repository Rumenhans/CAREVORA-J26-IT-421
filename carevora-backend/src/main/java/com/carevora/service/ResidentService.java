package com.carevora.service;

import com.carevora.dto.ApiResponse;
import com.carevora.dto.resident.ResidentResponse;
import com.carevora.entity.Caregiver;
import com.carevora.entity.Resident;
import com.carevora.entity.User;
import com.carevora.enums.UserRole;
import com.carevora.exception.ResourceNotFoundException;
import com.carevora.repository.AlertRepository;
import com.carevora.repository.CaregiverRepository;
import com.carevora.repository.ResidentRepository;
import com.carevora.repository.UserRepository;
import com.carevora.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ResidentService {

    private final ResidentRepository residentRepository;
    private final AlertRepository alertRepository;
    private final UserRepository userRepository;
    private final CaregiverRepository caregiverRepository;

    @Transactional(readOnly = true)
    public ApiResponse<List<ResidentResponse>> getAllResidents(String search) {
        Optional<User> currentUserOpt = SecurityUtils.getCurrentUser(userRepository);
        List<Resident> list;

        if (currentUserOpt.isEmpty()) {
            // Fallback for unauthenticated/system calls
            list = (search != null && !search.trim().isEmpty())
                    ? residentRepository.searchResidents(search.trim())
                    : residentRepository.findAll();
            return ApiResponse.ok(list.stream().map(this::mapToResponse).collect(Collectors.toList()));
        }

        User currentUser = currentUserOpt.get();
        UserRole role = currentUser.getRole();

        // 1. DOCTOR & ADMIN: Can see ALL elders across all elder homes
        if (role == UserRole.DOCTOR || role == UserRole.ADMIN) {
            if (search != null && !search.trim().isEmpty()) {
                list = residentRepository.searchResidents(search.trim());
            } else {
                list = residentRepository.findAll();
            }
        }
        // 2. CAREGIVER: Can ONLY see elders who belong to their assigned Elder Home
        else if (role == UserRole.CAREGIVER) {
            Optional<Caregiver> caregiverOpt = caregiverRepository.findByUserId(currentUser.getId());
            if (caregiverOpt.isPresent() && caregiverOpt.get().getElderHome() != null) {
                Long homeId = caregiverOpt.get().getElderHome().getId();
                if (search != null && !search.trim().isEmpty()) {
                    list = residentRepository.searchResidentsByElderHomeId(search.trim(), homeId);
                } else {
                    list = residentRepository.findByElderHomeId(homeId);
                }
            } else {
                list = Collections.emptyList();
            }
        }
        // 3. ELDER: Cannot see other elders! Can only see themselves
        else if (role == UserRole.ELDER || role == UserRole.RESIDENT) {
            Optional<Resident> residentOpt = residentRepository.findByUserId(currentUser.getId());
            list = residentOpt.map(Collections::singletonList).orElseGet(Collections::emptyList);
        } else {
            list = Collections.emptyList();
        }

        List<ResidentResponse> responses = list.stream().map(this::mapToResponse).collect(Collectors.toList());
        return ApiResponse.ok(responses);
    }

    @Transactional(readOnly = true)
    public ApiResponse<ResidentResponse> getResidentById(Long id) {
        Resident resident = residentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Resident not found with id: " + id));

        Optional<User> currentUserOpt = SecurityUtils.getCurrentUser(userRepository);
        if (currentUserOpt.isPresent()) {
            User currentUser = currentUserOpt.get();
            UserRole role = currentUser.getRole();

            // Caregiver can only inspect elders in their elder home
            if (role == UserRole.CAREGIVER) {
                Optional<Caregiver> caregiverOpt = caregiverRepository.findByUserId(currentUser.getId());
                if (caregiverOpt.isEmpty() || caregiverOpt.get().getElderHome() == null ||
                        resident.getElderHome() == null ||
                        !resident.getElderHome().getId().equals(caregiverOpt.get().getElderHome().getId())) {
                    throw new AccessDeniedException("Access denied: You can only view residents belonging to your assigned Elder Home.");
                }
            }
            // Elder cannot inspect other elders' profiles
            else if (role == UserRole.ELDER || role == UserRole.RESIDENT) {
                if (!resident.getUser().getId().equals(currentUser.getId())) {
                    throw new AccessDeniedException("Access denied: Elders are not authorized to view other elders' confidential records.");
                }
            }
            // Doctor and Admin have full access across all facilities
        }

        return ApiResponse.ok(mapToResponse(resident));
    }

    public ResidentResponse mapToResponse(Resident r) {
        int unreadAlerts = (int) alertRepository.findByResidentIdOrderByCreatedAtDesc(r.getId())
                .stream().filter(a -> !a.getIsRead()).count();

        Long homeId = r.getElderHome() != null ? r.getElderHome().getId() : null;
        String homeName = r.getElderHome() != null ? r.getElderHome().getName() : null;

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
                .elderHomeId(homeId)
                .elderHomeName(homeName)
                .build();
    }
}
