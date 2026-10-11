import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/responsive/responsive_builder.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/carevora_logo.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../doctor/application/doctor_providers.dart';
import '../../../doctor/domain/models.dart';
import '../../application/dose_schedule_service.dart';
import '../widgets/dose_detail_sheet.dart';
import '../widgets/resident_dose_card.dart';

class LiveMedicineBoardPage extends ConsumerStatefulWidget {
  const LiveMedicineBoardPage({super.key});

  @override
  ConsumerState<LiveMedicineBoardPage> createState() => _LiveMedicineBoardPageState();
}

class _LiveMedicineBoardPageState extends ConsumerState<LiveMedicineBoardPage> {
  Timer? _refreshTimer;
  DateTime _now = DateTime.now();
  String _searchQuery = '';
  bool _pendingOnly = false;
  DoseSlot _selectedMobileSlot = DoseSlot.morning;

  @override
  void initState() {
    super.initState();
    // Auto refresh status every 30s
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });

    // Auto set default active slot based on current hour
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) {
      _selectedMobileSlot = DoseSlot.morning;
    } else if (hour >= 12 && hour < 17) {
      _selectedMobileSlot = DoseSlot.afternoon;
    } else if (hour >= 17 && hour < 20) {
      _selectedMobileSlot = DoseSlot.evening;
    } else {
      _selectedMobileSlot = DoseSlot.night;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _openDoseDetailSheet(Resident resident, DoseSlot slot, List<DoseEvent> events) {
    final prescriptions = ref.read(prescriptionsProvider);
    final slotWindows = ref.read(slotWindowsProvider);
    final window = slotWindows.firstWhere((w) => w.slot == slot);
    final authState = ref.read(authProvider);
    final isReadOnly = authState.state.isDoctor; // Doctor is view-only

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DoseDetailSheet(
        resident: resident,
        slot: slot,
        window: window,
        events: events,
        prescriptions: prescriptions,
        currentUser: authState.state.userName ?? 'Caregiver',
        isReadOnly: isReadOnly,
        onMarkStatus: (event, newStatus, note) {
          ref.read(mockDataRepositoryProvider).markDoseStatus(
            doseEventId: event.id,
            status: newStatus,
            givenBy: authState.state.userName ?? 'Caregiver',
            note: note,
          );
          setState(() {});
        },
        onMarkAllGiven: () {
          ref.read(mockDataRepositoryProvider).markAllResidentDosesForSlot(
            residentId: resident.id,
            slot: slot,
            date: DateTime.now(),
            givenBy: authState.state.userName ?? 'Caregiver',
          );
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final residents = ref.watch(residentsProvider);
    final doseEvents = ref.watch(doseEventsProvider);
    final prescriptions = ref.watch(prescriptionsProvider);
    final slotWindows = ref.watch(slotWindowsProvider);
    final repo = ref.watch(mockDataRepositoryProvider);

    final today = DateTime(_now.year, _now.month, _now.day);

    // Today's events
    final todayEvents = doseEvents.where((e) {
      final ed = DateTime(e.date.year, e.date.month, e.date.day);
      return ed.isAtSameMomentAs(today);
    }).toList();

    final totalGivenCount = todayEvents.where((e) => e.status == DoseStatus.given).length;
    final totalEventsCount = todayEvents.length;

    int overdueCount = 0;
    for (final e in todayEvents) {
      final window = slotWindows.firstWhere((w) => w.slot == e.slot);
      final st = DoseScheduleService.calculateRealtimeSlotStatus(
        event: e,
        window: window,
        now: _now,
        graceMinutes: repo.overdueGraceMinutes,
      );
      if (st == 'overdue') overdueCount++;
    }

    return Scaffold(
      backgroundColor: AppColors.dashboardBg,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        title: Row(
          children: [
            const CarevoraLogo(variant: LogoVariant.full, size: 26, isDark: true),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.riskLowBg.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.riskLow, width: 1),
              ),
              child: const Text(
                'LIVE MEDICINE BOARD',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.history, color: Colors.white, size: 20),
            tooltip: 'Medication History',
            onPressed: () => context.go('/dashboard/medicine/history'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar & Summary Chips
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Today: ${_now.day}/${_now.month}/${_now.year}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
                    Text('Live Clock: ${_now.hour.toString().padLeft(2, "0")}:${_now.minute.toString().padLeft(2, "0")}:${_now.second.toString().padLeft(2, "0")}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      backgroundColor: AppColors.riskLowBg,
                      avatar: const Icon(Icons.check_circle, size: 16, color: AppColors.riskLow),
                      label: Text('Today: $totalGivenCount/$totalEventsCount given', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.riskLow)),
                    ),
                    Chip(
                      backgroundColor: overdueCount > 0 ? AppColors.riskHighBg : AppColors.dashboardBg,
                      avatar: Icon(Icons.warning, size: 16, color: overdueCount > 0 ? AppColors.riskHigh : AppColors.muted),
                      label: Text('Overdue: $overdueCount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: overdueCount > 0 ? AppColors.riskHigh : AppColors.muted)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search & Pending Only Filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: const InputDecoration(
                      hintText: 'Search by resident name or room number...',
                      prefixIcon: Icon(LucideIcons.search, size: 18),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text('Pending Only'),
                  selected: _pendingOnly,
                  onSelected: (val) => setState(() => _pendingOnly = val),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 4 Column Board Grid Layout
            ResponsiveBuilder(
              mobile: (ctx) => _buildMobileSlotBoard(residents, todayEvents, prescriptions, slotWindows, repo.overdueGraceMinutes),
              tablet: (ctx) => _buildTabletBoard(residents, todayEvents, prescriptions, slotWindows, repo.overdueGraceMinutes),
              desktop: (ctx) => _buildDesktopBoard(residents, todayEvents, prescriptions, slotWindows, repo.overdueGraceMinutes),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopBoard(List<Resident> residents, List<DoseEvent> todayEvents, List<Prescription> prescriptions, List<SlotWindow> windows, int grace) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: DoseSlot.values.map((slot) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildSlotColumn(slot, residents, todayEvents, prescriptions, windows.firstWhere((w) => w.slot == slot), grace),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTabletBoard(List<Resident> residents, List<DoseEvent> todayEvents, List<Prescription> prescriptions, List<SlotWindow> windows, int grace) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildSlotColumn(DoseSlot.morning, residents, todayEvents, prescriptions, windows.firstWhere((w) => w.slot == DoseSlot.morning), grace)),
            const SizedBox(width: 12),
            Expanded(child: _buildSlotColumn(DoseSlot.afternoon, residents, todayEvents, prescriptions, windows.firstWhere((w) => w.slot == DoseSlot.afternoon), grace)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildSlotColumn(DoseSlot.evening, residents, todayEvents, prescriptions, windows.firstWhere((w) => w.slot == DoseSlot.evening), grace)),
            const SizedBox(width: 12),
            Expanded(child: _buildSlotColumn(DoseSlot.night, residents, todayEvents, prescriptions, windows.firstWhere((w) => w.slot == DoseSlot.night), grace)),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileSlotBoard(List<Resident> residents, List<DoseEvent> todayEvents, List<Prescription> prescriptions, List<SlotWindow> windows, int grace) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: DoseSlot.values.map((slot) {
              final isSel = _selectedMobileSlot == slot;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(slot.name.toUpperCase()),
                  selected: isSel,
                  onSelected: (_) => setState(() => _selectedMobileSlot = slot),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        _buildSlotColumn(_selectedMobileSlot, residents, todayEvents, prescriptions, windows.firstWhere((w) => w.slot == _selectedMobileSlot), grace),
      ],
    );
  }

  Widget _buildSlotColumn(DoseSlot slot, List<Resident> residents, List<DoseEvent> todayEvents, List<Prescription> prescriptions, SlotWindow window, int grace) {
    final slotEvents = todayEvents.where((e) => e.slot == slot).toList();
    final residentIds = slotEvents.map((e) => e.residentId).toSet();

    final slotResidents = residents.where((r) {
      final matchesSlot = residentIds.contains(r.id);
      final matchesQuery = r.name.toLowerCase().contains(_searchQuery.toLowerCase()) || r.roomNo.contains(_searchQuery);
      return matchesSlot && matchesQuery;
    }).toList();

    final givenSlotCount = slotEvents.where((e) => e.status == DoseStatus.given).length;
    final totalSlotCount = slotEvents.length;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Column Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  slot.name.toUpperCase(),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navy),
                ),
                Text(
                  '${window.startHour.toString().padLeft(2, "0")}:00 - ${window.endHour.toString().padLeft(2, "0")}:00',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('$givenSlotCount/$totalSlotCount given', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: totalSlotCount > 0 ? givenSlotCount / totalSlotCount : 0,
              backgroundColor: AppColors.primarySoft,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),

            // Resident Cards
            if (slotResidents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No doses scheduled', style: TextStyle(fontSize: 12, color: AppColors.muted))),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: slotResidents.length,
                itemBuilder: (ctx, i) {
                  final res = slotResidents[i];
                  final resEvents = slotEvents.where((e) => e.residentId == res.id).toList();

                  // Compute resident status for slot
                  String resStatus = 'upcoming';
                  final allGiven = resEvents.every((e) => e.status == DoseStatus.given);
                  if (allGiven) {
                    resStatus = 'given';
                  } else {
                    for (final e in resEvents) {
                      final st = DoseScheduleService.calculateRealtimeSlotStatus(
                        event: e,
                        window: window,
                        now: _now,
                        graceMinutes: grace,
                      );
                      if (st == 'overdue') {
                        resStatus = 'overdue';
                        break;
                      } else if (st == 'pending') {
                        resStatus = 'pending';
                      }
                    }
                  }

                  if (_pendingOnly && resStatus == 'given') return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ResidentDoseCard(
                      resident: res,
                      slotEvents: resEvents,
                      prescriptions: prescriptions,
                      status: resStatus,
                      onTap: () => _openDoseDetailSheet(res, slot, resEvents),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
