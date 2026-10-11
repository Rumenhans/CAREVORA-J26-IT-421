import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../application/doctor_medicine_repository.dart';
import '../domain/models.dart';

final mockDataRepositoryProvider = ChangeNotifierProvider<MockDataRepository>((ref) {
  return MockDataRepository();
});

final residentsProvider = Provider<List<Resident>>((ref) {
  return ref.watch(mockDataRepositoryProvider).residents;
});

final doctorsProvider = Provider<List<DoctorModel>>((ref) {
  return ref.watch(mockDataRepositoryProvider).doctors;
});

final prescriptionsProvider = Provider<List<Prescription>>((ref) {
  return ref.watch(mockDataRepositoryProvider).prescriptions;
});

final doseEventsProvider = Provider<List<DoseEvent>>((ref) {
  return ref.watch(mockDataRepositoryProvider).doseEvents;
});

final auditLogsProvider = Provider<List<AuditLog>>((ref) {
  return ref.watch(mockDataRepositoryProvider).auditLogs;
});

final slotWindowsProvider = Provider<List<SlotWindow>>((ref) {
  return ref.watch(mockDataRepositoryProvider).slotWindows;
});
