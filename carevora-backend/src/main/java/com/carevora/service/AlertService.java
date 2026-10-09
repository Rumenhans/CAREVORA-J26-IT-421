package com.carevora.service;

import com.carevora.dto.ApiResponse;
import com.carevora.entity.Alert;
import com.carevora.exception.ResourceNotFoundException;
import com.carevora.repository.AlertRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class AlertService {

    private final AlertRepository alertRepository;

    public ApiResponse<List<Alert>> getAllAlerts() {
        return ApiResponse.ok(alertRepository.findAllByOrderByCreatedAtDesc());
    }

    public ApiResponse<Alert> markAsRead(Long alertId) {
        Alert alert = alertRepository.findById(alertId)
                .orElseThrow(() -> new ResourceNotFoundException("Alert not found with id: " + alertId));
        alert.setIsRead(true);
        return ApiResponse.ok(alertRepository.save(alert), "Alert marked as read");
    }
}
