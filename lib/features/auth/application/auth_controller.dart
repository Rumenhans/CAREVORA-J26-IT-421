import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRole {
  admin,
  doctor,
  caregiver,
}

class AuthState {
  final bool isAuthenticated;
  final String? email;
  final String? userName;
  final UserRole role;
  final bool isLoading;
  final String? errorMessage;
  final int failedAttempts;
  final int lockoutSecondsRemaining;
  final String? infoMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.email,
    this.userName,
    this.role = UserRole.caregiver,
    this.isLoading = false,
    this.errorMessage,
    this.failedAttempts = 0,
    this.lockoutSecondsRemaining = 0,
    this.infoMessage,
  });

  bool get isLockedOut => lockoutSecondsRemaining > 0;
  bool get isAdmin => role == UserRole.admin;
  bool get isDoctor => role == UserRole.doctor;
  bool get isCaregiver => role == UserRole.caregiver;

  AuthState copyWith({
    bool? isAuthenticated,
    String? email,
    String? userName,
    UserRole? role,
    bool? isLoading,
    String? errorMessage,
    int? failedAttempts,
    int? lockoutSecondsRemaining,
    String? infoMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      email: email ?? this.email,
      userName: userName ?? this.userName,
      role: role ?? this.role,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockoutSecondsRemaining:
          lockoutSecondsRemaining ?? this.lockoutSecondsRemaining,
      infoMessage: infoMessage,
    );
  }
}

class AuthNotifier extends ChangeNotifier {
  AuthState _state = const AuthState();
  AuthState get state => _state;
  Timer? _lockoutTimer;

  AuthNotifier() {
    _init();
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final isAuth = prefs.getBool('carevora_auth') ?? true;
    final email = prefs.getString('carevora_email') ?? 'seetha@carevora.com';
    final roleStr = prefs.getString('carevora_role') ?? 'caregiver';
    UserRole role = UserRole.caregiver;
    if (roleStr == 'admin') {
      role = UserRole.admin;
    } else if (roleStr == 'doctor') {
      role = UserRole.doctor;
    }

    String userName = 'Seetha N.';
    if (role == UserRole.admin) {
      userName = 'System Admin';
    } else if (role == UserRole.doctor) {
      userName = 'Dr. Nimal Fernando';
    }

    _state = AuthState(
      isAuthenticated: isAuth,
      email: email,
      userName: userName,
      role: role,
    );
    notifyListeners();
  }

  void setInfoMessage(String? message) {
    _state = _state.copyWith(infoMessage: message);
    notifyListeners();
  }

  void clearErrorMessage() {
    if (_state.errorMessage != null) {
      _state = _state.copyWith(errorMessage: null);
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password, bool rememberMe) async {
    if (_state.isLockedOut) return false;

    _state = _state.copyWith(
      isLoading: true,
      errorMessage: null,
      infoMessage: null,
    );
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    final normalizedEmail = email.trim().toLowerCase();

    // Admin Credentials: admin@carevora.com / admin123
    final isAdminValid = (normalizedEmail == 'admin@carevora.com' || normalizedEmail == 'admin') &&
        password == 'admin123';

    // Doctor Credentials: doctor@carevora.com / doctor123 or nimal@carevora.com / doctor123
    final isDoctorValid = (normalizedEmail == 'doctor@carevora.com' || normalizedEmail == 'nimal@carevora.com' || normalizedEmail == 'doctor') &&
        (password == 'doctor123' || password == 'demo1234');

    // Caregiver Demo Credentials: seetha@carevora.com / demo1234
    final isDemoValid = normalizedEmail == 'seetha@carevora.com' &&
        password == 'demo1234';

    if (isAdminValid) {
      final prefs = await SharedPreferences.getInstance();
      if (rememberMe) {
        await prefs.setBool('carevora_auth', true);
        await prefs.setString('carevora_email', normalizedEmail);
        await prefs.setString('carevora_role', 'admin');
      }
      _state = _state.copyWith(
        isAuthenticated: true,
        email: normalizedEmail,
        userName: 'System Admin',
        role: UserRole.admin,
        isLoading: false,
        failedAttempts: 0,
      );
      notifyListeners();
      return true;
    } else if (isDoctorValid) {
      final prefs = await SharedPreferences.getInstance();
      if (rememberMe) {
        await prefs.setBool('carevora_auth', true);
        await prefs.setString('carevora_email', normalizedEmail);
        await prefs.setString('carevora_role', 'doctor');
      }
      _state = _state.copyWith(
        isAuthenticated: true,
        email: normalizedEmail,
        userName: 'Dr. Nimal Fernando',
        role: UserRole.doctor,
        isLoading: false,
        failedAttempts: 0,
      );
      notifyListeners();
      return true;
    } else if (isDemoValid) {
      final prefs = await SharedPreferences.getInstance();
      if (rememberMe) {
        await prefs.setBool('carevora_auth', true);
        await prefs.setString('carevora_email', normalizedEmail);
        await prefs.setString('carevora_role', 'caregiver');
      }
      _state = _state.copyWith(
        isAuthenticated: true,
        email: normalizedEmail,
        userName: 'Seetha N.',
        role: UserRole.caregiver,
        isLoading: false,
        failedAttempts: 0,
      );
      notifyListeners();
      return true;
    } else {
      final newFailedAttempts = _state.failedAttempts + 1;
      int lockoutTime = 0;

      if (newFailedAttempts >= 5) {
        lockoutTime = 30;
        _startLockoutCountdown(30);
      }

      _state = _state.copyWith(
        isLoading: false,
        failedAttempts: newFailedAttempts,
        lockoutSecondsRemaining: lockoutTime,
        errorMessage: newFailedAttempts >= 5
            ? 'Account temporarily locked due to multiple failed attempts.'
            : 'Invalid credentials. Please verify your email and password.',
      );
      notifyListeners();
      return false;
    }
  }

  void _startLockoutCountdown(int seconds) {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = _state.lockoutSecondsRemaining - 1;
      if (remaining <= 0) {
        timer.cancel();
        _state = _state.copyWith(
          lockoutSecondsRemaining: 0,
          failedAttempts: 0,
          errorMessage: null,
        );
      } else {
        _state = _state.copyWith(lockoutSecondsRemaining: remaining);
      }
      notifyListeners();
    });
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('carevora_auth');
    await prefs.remove('carevora_role');
    _state = const AuthState(isAuthenticated: false);
    notifyListeners();
  }
}

final authProvider = ChangeNotifierProvider<AuthNotifier>((ref) {
  return AuthNotifier();
});
