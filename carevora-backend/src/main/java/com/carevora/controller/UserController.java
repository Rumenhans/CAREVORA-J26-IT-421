package com.carevora.controller;

import com.carevora.dto.ApiResponse;
import com.carevora.dto.user.UserSummaryResponse;
import com.carevora.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@Tag(name = "Doctor & User Management", description = "Clinical Doctor directory view of all users across facilities")
public class UserController {

    private final UserService userService;

    @GetMapping("/users")
    @Operation(summary = "Get all system users across facilities (Doctor & Admin only)")
    public ResponseEntity<ApiResponse<List<UserSummaryResponse>>> getAllUsers(
            @RequestParam(required = false) String search
    ) {
        return ResponseEntity.ok(userService.getAllUsersForDoctor(search));
    }

    @GetMapping("/doctor/all-users")
    @Operation(summary = "Doctor portal view of all users, caregivers and elders")
    public ResponseEntity<ApiResponse<List<UserSummaryResponse>>> getDoctorUsersView(
            @RequestParam(required = false) String search
    ) {
        return ResponseEntity.ok(userService.getAllUsersForDoctor(search));
    }
}
