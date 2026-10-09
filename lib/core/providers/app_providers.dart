import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import '../../models/carevora_models.dart';
import '../../models/enums.dart';

// Live REST API Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Current User State
final currentUserProvider = NotifierProvider<CurrentUserNotifier, UserModel?>(CurrentUserNotifier.new);

class CurrentUserNotifier extends Notifier<UserModel?> {
  @override
  UserModel? build() {
    return ref.watch(apiServiceProvider).currentUser;
  }

  void setUser(UserModel? user) => state = user;
}

// Current active role
final activeRoleProvider = NotifierProvider<ActiveRoleNotifier, UserRole>(ActiveRoleNotifier.new);

class ActiveRoleNotifier extends Notifier<UserRole> {
  @override
  UserRole build() => UserRole.resident;

  void setRole(UserRole role) => state = role;
}

// Residents list provider
final residentsProvider = FutureProvider<List<ResidentModel>>((ref) async {
  final service = ref.watch(apiServiceProvider);
  return service.getResidents();
});

// Selected resident ID for caregiver view
final selectedResidentIdProvider = NotifierProvider<SelectedResidentIdNotifier, String>(SelectedResidentIdNotifier.new);

class SelectedResidentIdNotifier extends Notifier<String> {
  @override
  String build() => '1';

  void select(String id) => state = id;
}

// Selected resident detail provider
final selectedResidentProvider = FutureProvider<ResidentModel?>((ref) async {
  final service = ref.watch(apiServiceProvider);
  final residentId = ref.watch(selectedResidentIdProvider);
  return service.getResidentById(residentId);
});

// Alerts provider
final alertsListProvider = FutureProvider<List<AlertModel>>((ref) async {
  final service = ref.watch(apiServiceProvider);
  return service.getAlerts();
});

// Assessment questions provider
final assessmentQuestionsProvider = FutureProvider<List<AssessmentQuestion>>((ref) async {
  final service = ref.watch(apiServiceProvider);
  return service.getQuestions();
});

// Latest assessment result provider
final latestWellnessResultProvider = NotifierProvider<LatestResultNotifier, WellnessResultModel?>(LatestResultNotifier.new);

class LatestResultNotifier extends Notifier<WellnessResultModel?> {
  @override
  WellnessResultModel? build() => null;

  void setResult(WellnessResultModel? res) => state = res;
}
