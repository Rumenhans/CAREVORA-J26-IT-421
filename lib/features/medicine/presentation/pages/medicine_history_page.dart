import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../doctor/application/doctor_providers.dart';
import '../../../doctor/domain/models.dart';

class MedicineHistoryPage extends ConsumerStatefulWidget {
  const MedicineHistoryPage({super.key});

  @override
  ConsumerState<MedicineHistoryPage> createState() => _MedicineHistoryPageState();
}

class _MedicineHistoryPageState extends ConsumerState<MedicineHistoryPage> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final doseEvents = ref.watch(doseEventsProvider);
    final residents = ref.watch(residentsProvider);

    final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    final dayEvents = doseEvents.where((e) {
      final ed = DateTime(e.date.year, e.date.month, e.date.day);
      return ed.isAtSameMomentAs(selectedDay);
    }).toList();

    final totalCount = dayEvents.length;
    final givenCount = dayEvents.where((e) => e.status == DoseStatus.given).length;
    final missedCount = dayEvents.where((e) => e.status == DoseStatus.missed || e.status == DoseStatus.refused).length;
    final adherencePct = totalCount > 0 ? ((givenCount / totalCount) * 100).toStringAsFixed(1) : '100.0';

    return Scaffold(
      backgroundColor: AppColors.dashboardBg,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        title: const Text('MEDICATION ADHERENCE HISTORY', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Picker Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2026, 1, 1),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 14, color: Colors.white),
                  label: const Text('Select Date', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Metrics Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Adherence Rate', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                        const SizedBox(height: 4),
                        Text('$adherencePct%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Given Doses', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                        const SizedBox(height: 4),
                        Text('$givenCount / $totalCount', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.riskLow)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Missed / Refused', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                        const SizedBox(height: 4),
                        Text('$missedCount', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.riskHigh)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // History Log Table
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dose Execution Audit Trail', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
                    const SizedBox(height: 16),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dayEvents.length,
                      separatorBuilder: (ctx, i) => const Divider(),
                      itemBuilder: (ctx, i) {
                        final event = dayEvents[i];
                        final res = residents.firstWhere((r) => r.id == event.residentId, orElse: () => const Resident(id: '', name: 'Unknown', roomNo: '', age: 0, gender: '', allergies: []));
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: event.status == DoseStatus.given ? AppColors.riskLowBg : AppColors.riskHighBg,
                            child: Icon(event.status == DoseStatus.given ? Icons.check : Icons.close, color: event.status == DoseStatus.given ? AppColors.riskLow : AppColors.riskHigh, size: 16),
                          ),
                          title: Text('${res.name} (Room ${res.roomNo}) - ${event.slot.name.toUpperCase()}'),
                          subtitle: Text('Status: ${event.status.name.toUpperCase()} • Executed by: ${event.givenBy ?? "System"}'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
