import 'package:flutter_test/flutter_test.dart';
import 'package:carevora/features/doctor/domain/models.dart';
import 'package:carevora/features/medicine/application/dose_schedule_service.dart';

void main() {
  group('DoseScheduleService Tests', () {
    test('generateEventsForPrescription creates correct number of events for pattern 1-0-2-1 over 7 days', () {
      final startDate = DateTime(2026, 10, 10);
      final prescription = Prescription(
        id: 'RX-TEST-101',
        residentId: 'R-105',
        doctorId: 'DOC-1',
        medicineName: 'Metformin',
        strength: '500mg',
        form: PrescriptionForm.tablet,
        doseAmount: '1 tablet',
        pattern: const DosePattern(morning: 1, afternoon: 0, evening: 2, night: 1),
        mealTiming: MealTiming.afterMeal,
        startDate: startDate,
        durationDays: 7,
        endDate: DoseScheduleService.computeEndDate(startDate, 7),
        instructions: 'Take after meals',
        type: PrescriptionType.regular,
        status: PrescriptionStatus.active,
        createdAt: DateTime.now(),
      );

      final events = DoseScheduleService.generateEventsForPrescription(prescription);

      // 1 morning + 2 evening (counted as slot event) + 1 night = 3 slots per day * 7 days = 21 events
      expect(events.length, equals(21));
      
      final morningEvents = events.where((e) => e.slot == DoseSlot.morning).toList();
      final eveningEvents = events.where((e) => e.slot == DoseSlot.evening).toList();
      final nightEvents = events.where((e) => e.slot == DoseSlot.night).toList();
      final afternoonEvents = events.where((e) => e.slot == DoseSlot.afternoon).toList();

      expect(morningEvents.length, equals(7));
      expect(eveningEvents.length, equals(7));
      expect(nightEvents.length, equals(7));
      expect(afternoonEvents.length, equals(0));
    });

    test('computeEndDate computes correct inclusive end date', () {
      final startDate = DateTime(2026, 10, 10);
      final endDate = DoseScheduleService.computeEndDate(startDate, 7);
      expect(endDate, equals(DateTime(2026, 10, 16)));
    });

    test('calculateRealtimeSlotStatus evaluates upcoming, pending, overdue, and given status correctly', () {
      final now = DateTime(2026, 10, 10, 10, 45); // 10:45 AM
      final morningWindow = const SlotWindow(
        slot: DoseSlot.morning,
        startHour: 6,
        startMinute: 0,
        endHour: 10,
        endMinute: 0,
      );

      final pendingEvent = DoseEvent(
        id: 'DE-1',
        prescriptionId: 'RX-1',
        residentId: 'R-105',
        date: DateTime(2026, 10, 10),
        slot: DoseSlot.morning,
        status: DoseStatus.pending,
      );

      // Overdue because 10:45 is > 06:00 + 30 mins grace
      final statusOverdue = DoseScheduleService.calculateRealtimeSlotStatus(
        event: pendingEvent,
        window: morningWindow,
        now: now,
        graceMinutes: 30,
      );
      expect(statusOverdue, equals('overdue'));

      // Given status returns given regardless of window
      final givenEvent = pendingEvent.copyWith(status: DoseStatus.given);
      final statusGiven = DoseScheduleService.calculateRealtimeSlotStatus(
        event: givenEvent,
        window: morningWindow,
        now: now,
      );
      expect(statusGiven, equals('given'));
    });
  });
}
