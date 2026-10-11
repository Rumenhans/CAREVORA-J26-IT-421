import '../../doctor/domain/models.dart';

class DoseScheduleService {
  /// Generates DoseEvent objects for a prescription spanning N days starting from startDate.
  static List<DoseEvent> generateEventsForPrescription(Prescription prescription) {
    final List<DoseEvent> events = [];
    final startDate = DateTime(prescription.startDate.year, prescription.startDate.month, prescription.startDate.day);

    for (int day = 0; day < prescription.durationDays; day++) {
      final currentDate = startDate.add(Duration(days: day));

      // Morning
      if (prescription.pattern.morning > 0) {
        events.add(DoseEvent(
          id: 'DE-${prescription.id}-M-$day',
          prescriptionId: prescription.id,
          residentId: prescription.residentId,
          date: currentDate,
          slot: DoseSlot.morning,
          status: DoseStatus.pending,
        ));
      }

      // Afternoon
      if (prescription.pattern.afternoon > 0) {
        events.add(DoseEvent(
          id: 'DE-${prescription.id}-A-$day',
          prescriptionId: prescription.id,
          residentId: prescription.residentId,
          date: currentDate,
          slot: DoseSlot.afternoon,
          status: DoseStatus.pending,
        ));
      }

      // Evening
      if (prescription.pattern.evening > 0) {
        events.add(DoseEvent(
          id: 'DE-${prescription.id}-E-$day',
          prescriptionId: prescription.id,
          residentId: prescription.residentId,
          date: currentDate,
          slot: DoseSlot.evening,
          status: DoseStatus.pending,
        ));
      }

      // Night
      if (prescription.pattern.night > 0) {
        events.add(DoseEvent(
          id: 'DE-${prescription.id}-N-$day',
          prescriptionId: prescription.id,
          residentId: prescription.residentId,
          date: currentDate,
          slot: DoseSlot.night,
          status: DoseStatus.pending,
        ));
      }
    }
    return events;
  }

  /// Calculates real-time status of a dose event relative to current time and slot window.
  static String calculateRealtimeSlotStatus({
    required DoseEvent event,
    required SlotWindow window,
    required DateTime now,
    int graceMinutes = 30,
  }) {
    if (event.status == DoseStatus.given) {
      return 'given';
    }
    if (event.status == DoseStatus.refused) {
      return 'refused';
    }
    if (event.status == DoseStatus.held) {
      return 'held';
    }
    if (event.status == DoseStatus.missed) {
      return 'missed';
    }

    // Pending event evaluation against time windows
    final eventDay = DateTime(event.date.year, event.date.month, event.date.day);
    final today = DateTime(now.year, now.month, now.day);

    if (eventDay.isBefore(today)) {
      return 'missed';
    } else if (eventDay.isAfter(today)) {
      return 'upcoming';
    }

    // Today's event
    final windowStart = DateTime(now.year, now.month, now.day, window.startHour, window.startMinute);
    final overdueThreshold = windowStart.add(Duration(minutes: graceMinutes));

    if (now.isBefore(windowStart)) {
      return 'upcoming';
    } else if (now.isAfter(overdueThreshold)) {
      return 'overdue';
    } else {
      return 'pending';
    }
  }

  /// Computes end date for a prescription given start date and duration days.
  static DateTime computeEndDate(DateTime startDate, int durationDays) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    return start.add(Duration(days: durationDays > 0 ? durationDays - 1 : 0));
  }
}
