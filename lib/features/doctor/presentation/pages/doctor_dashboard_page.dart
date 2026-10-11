import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/responsive/responsive_builder.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/carevora_logo.dart';
import '../../../auth/application/auth_controller.dart';
import '../../application/doctor_providers.dart';
import '../../domain/models.dart';
import '../widgets/allergy_warning_dialog.dart';
import '../widgets/doctor_components.dart';

class DoctorDashboardPage extends ConsumerStatefulWidget {
  const DoctorDashboardPage({super.key});

  @override
  ConsumerState<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends ConsumerState<DoctorDashboardPage> {
  int _selectedTabIndex = 0; // 0: Prescribe, 1: Prescriptions, 2: Doctors

  // Prescribe Form state
  Resident? _selectedResident;
  String _residentSearchQuery = '';
  final _medNameController = TextEditingController();
  final _strengthController = TextEditingController();
  final _doseAmountController = TextEditingController();
  final _durationDaysController = TextEditingController(text: '7');
  final _instructionsController = TextEditingController();

  PrescriptionForm _selectedForm = PrescriptionForm.tablet;
  DosePattern _pattern = const DosePattern(morning: 1, afternoon: 0, evening: 1, night: 0);
  MealTiming _mealTiming = MealTiming.afterMeal;
  PrescriptionType _rxType = PrescriptionType.regular;
  DateTime _startDate = DateTime.now();

  // Prescriptions Tab Search & Filter
  String _rxSearchQuery = '';
  PrescriptionStatus? _statusFilter;

  @override
  void dispose() {
    _medNameController.dispose();
    _strengthController.dispose();
    _doseAmountController.dispose();
    _durationDaysController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _handlePrescribeSubmit() async {
    if (_selectedResident == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a resident first.')),
      );
      return;
    }
    if (_medNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicine name is required.')),
      );
      return;
    }
    if (!_pattern.hasAnyDose) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set at least one dose in the pattern stepper.')),
      );
      return;
    }

    final medName = _medNameController.text.trim();
    final resident = _selectedResident!;

    // Check Allergy Match
    final matchingAllergy = resident.allergies.firstWhere(
      (a) => medName.toLowerCase().contains(a.toLowerCase()) || a.toLowerCase().contains(medName.toLowerCase()),
      orElse: () => '',
    );

    if (matchingAllergy.isNotEmpty) {
      final approved = await showDialog<bool>(
        context: context,
        builder: (ctx) => AllergyWarningDialog(
          residentName: resident.name,
          medicineName: medName,
          allergyMatched: matchingAllergy,
          onOverrideApproved: (reason) {
            // Handled
          },
        ),
      );
      if (approved != true) return;
    }

    // Check Duplicate Active Prescription
    final existingRx = ref.read(prescriptionsProvider).where((rx) =>
        rx.residentId == resident.id &&
        rx.status == PrescriptionStatus.active &&
        rx.medicineName.toLowerCase() == medName.toLowerCase()).toList();

    if (existingRx.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('DUPLICATE PRESCRIPTION WARNING', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.riskModerate)),
          content: Text('${resident.name} already has an active prescription for $medName (${existingRx.first.strength}). Are you sure you want to add another?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Prescribe Anyway', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    final duration = int.tryParse(_durationDaysController.text.trim()) ?? 7;
    final authState = ref.read(authProvider).state;

    final newRx = Prescription(
      id: 'RX-${DateTime.now().millisecondsSinceEpoch}',
      residentId: resident.id,
      doctorId: authState.userName ?? 'Dr. Nimal Fernando',
      medicineName: medName,
      strength: _strengthController.text.trim().isEmpty ? '500mg' : _strengthController.text.trim(),
      form: _selectedForm,
      doseAmount: _doseAmountController.text.trim().isEmpty ? '1 tablet' : _doseAmountController.text.trim(),
      pattern: _pattern,
      mealTiming: _mealTiming,
      startDate: _startDate,
      durationDays: duration,
      endDate: DateTime(_startDate.year, _startDate.month, _startDate.day).add(Duration(days: duration - 1)),
      instructions: _instructionsController.text.trim(),
      type: _rxType,
      status: PrescriptionStatus.active,
      createdAt: DateTime.now(),
    );

    ref.read(mockDataRepositoryProvider).addPrescription(newRx, authState.userName ?? 'Dr. Nimal Fernando');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prescription for $medName successfully created and scheduled!')),
      );
      // Reset form
      setState(() {
        _medNameController.clear();
        _strengthController.clear();
        _doseAmountController.clear();
        _instructionsController.clear();
        _selectedTabIndex = 1; // Switch to Prescriptions tab
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider).state;
    final isDoctor = authState.isDoctor;
    final isAdmin = authState.isAdmin;

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
                color: AppColors.primarySoft.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.lilac, width: 1),
              ),
              child: const Text(
                'CLINICAL DOCTOR MODULE',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tabs Bar
            Row(
              children: [
                _buildTabChip(0, 'Prescribe Medicine', LucideIcons.filePlus, enabled: isDoctor || isAdmin),
                const SizedBox(width: 8),
                _buildTabChip(1, 'Active Prescriptions', LucideIcons.pill, enabled: true),
                const SizedBox(width: 8),
                if (isAdmin) _buildTabChip(2, 'Doctors Directory', LucideIcons.userCheck, enabled: true),
              ],
            ),
            const SizedBox(height: 20),

            if (_selectedTabIndex == 0) _buildPrescribeTab(isDoctor: isDoctor),
            if (_selectedTabIndex == 1) _buildPrescriptionsListTab(),
            if (_selectedTabIndex == 2 && isAdmin) _buildDoctorsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip(int index, String label, IconData icon, {required bool enabled}) {
    final isSelected = _selectedTabIndex == index;
    return ChoiceChip(
      showCheckmark: false,
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.navy),
      label: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.navy)),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      onSelected: enabled ? (_) => setState(() => _selectedTabIndex = index) : null,
    );
  }

  Widget _buildPrescribeTab({required bool isDoctor}) {
    final residents = ref.watch(residentsProvider);
    final filteredResidents = residents.where((r) =>
        r.name.toLowerCase().contains(_residentSearchQuery.toLowerCase()) ||
        r.roomNo.contains(_residentSearchQuery)).toList();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Prescribe New Medication', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
                    Text('Select resident & configure clinical dose schedule', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(8)),
                  child: const Text('Pattern: Morning-Afternoon-Evening-Night', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Resident Search, Dropdown & Picker
            const Text('1. Select Resident:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
            const SizedBox(height: 8),
            ResponsiveBuilder(
              mobile: (ctx) => Column(
                children: [
                  DropdownButtonFormField<Resident>(
                    initialValue: _selectedResident,
                    decoration: const InputDecoration(
                      labelText: 'Select Resident (Dropdown)',
                      prefixIcon: Icon(LucideIcons.userCheck, size: 18),
                      border: OutlineInputBorder(),
                    ),
                    items: residents
                        .map((r) => DropdownMenuItem<Resident>(
                              value: r,
                              child: Text('${r.name} (Room ${r.roomNo})'),
                            ))
                        .toList(),
                    onChanged: (r) => setState(() => _selectedResident = r),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    onChanged: (val) => setState(() => _residentSearchQuery = val),
                    decoration: const InputDecoration(
                      hintText: 'Type initials / name / room to filter below...',
                      prefixIcon: Icon(LucideIcons.search, size: 18),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              desktop: (ctx) => Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<Resident>(
                      initialValue: _selectedResident,
                      decoration: const InputDecoration(
                        labelText: 'Select Resident (Dropdown)',
                        prefixIcon: Icon(LucideIcons.userCheck, size: 18),
                        border: OutlineInputBorder(),
                      ),
                      items: residents
                          .map((r) => DropdownMenuItem<Resident>(
                                value: r,
                                child: Text('${r.name} (Room ${r.roomNo})'),
                              ))
                          .toList(),
                      onChanged: (r) => setState(() => _selectedResident = r),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      onChanged: (val) => setState(() => _residentSearchQuery = val),
                      decoration: const InputDecoration(
                        hintText: 'Type initials / name / room to filter below...',
                        prefixIcon: Icon(LucideIcons.search, size: 18),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filteredResidents.length,
                itemBuilder: (ctx, i) {
                  final r = filteredResidents[i];
                  final isSel = _selectedResident?.id == r.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedResident = r),
                    child: Container(
                      width: 170,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.primarySoft : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSel ? AppColors.primary : AppColors.border, width: isSel ? 2 : 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSel ? AppColors.primary : AppColors.navy), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('Room ${r.roomNo} • ${r.age} yrs', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                          const SizedBox(height: 4),
                          if (r.allergies.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.riskHighBg, borderRadius: BorderRadius.circular(4)),
                              child: Text('Allergy: ${r.allergies.join(", ")}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.riskHigh), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
            const Text('2. Medication Details:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
            const SizedBox(height: 12),

            ResponsiveBuilder(
              mobile: (ctx) => Column(
                children: [
                  RawAutocomplete<String>(
                    textEditingController: _medNameController,
                    focusNode: FocusNode(),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      const commonMeds = [
                        'Metformin',
                        'Donepezil',
                        'Lisinopril',
                        'Amlodipine',
                        'Atorvastatin',
                        'Memantine',
                        'Levothyroxine',
                        'Omeprazole',
                        'Paracetamol',
                        'Amoxicillin'
                      ];
                      return commonMeds.where((String option) {
                        return option.toLowerCase().startsWith(textEditingValue.text.toLowerCase());
                      });
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 260,
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final option = options.elementAt(index);
                                return ListTile(
                                  title: Text(option, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onEditingComplete: onEditingComplete,
                        decoration: const InputDecoration(
                          labelText: 'Medicine Name (Type initials to auto-suggest)',
                          hintText: 'e.g. Met, Don, Lis...',
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _strengthController,
                          decoration: const InputDecoration(labelText: 'Strength (e.g. 500mg)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<PrescriptionForm>(
                          initialValue: _selectedForm,
                          decoration: const InputDecoration(labelText: 'Form', border: OutlineInputBorder()),
                          items: PrescriptionForm.values.map((f) => DropdownMenuItem(value: f, child: Text(f.name.toUpperCase()))).toList(),
                          onChanged: (v) => setState(() => _selectedForm = v ?? _selectedForm),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              desktop: (ctx) => Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: RawAutocomplete<String>(
                      textEditingController: _medNameController,
                      focusNode: FocusNode(),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        const commonMeds = [
                          'Metformin',
                          'Donepezil',
                          'Lisinopril',
                          'Amlodipine',
                          'Atorvastatin',
                          'Memantine',
                          'Levothyroxine',
                          'Omeprazole',
                          'Paracetamol',
                          'Amoxicillin'
                        ];
                        return commonMeds.where((String option) {
                          return option.toLowerCase().startsWith(textEditingValue.text.toLowerCase());
                        });
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 300,
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    title: Text(option, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onEditingComplete: onEditingComplete,
                          decoration: const InputDecoration(
                            labelText: 'Medicine Name (Type initials to auto-suggest)',
                            hintText: 'e.g. Met, Don, Lis...',
                            border: OutlineInputBorder(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _strengthController,
                      decoration: const InputDecoration(labelText: 'Strength (e.g. 500mg)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<PrescriptionForm>(
                      initialValue: _selectedForm,
                      decoration: const InputDecoration(labelText: 'Form', border: OutlineInputBorder()),
                      items: PrescriptionForm.values.map((f) => DropdownMenuItem(value: f, child: Text(f.name.toUpperCase()))).toList(),
                      onChanged: (v) => setState(() => _selectedForm = v ?? _selectedForm),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Dose Pattern Stepper
            Row(
              children: [
                const Text('Dose Pattern Stepper: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                  child: Text('Summary: ${_pattern.summary}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DosePatternStepper(
              value: _pattern,
              onChanged: (p) => setState(() => _pattern = p),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<MealTiming>(
                    initialValue: _mealTiming,
                    decoration: const InputDecoration(labelText: 'Meal Timing', border: OutlineInputBorder()),
                    items: MealTiming.values.map((m) => DropdownMenuItem(value: m, child: Text(m.name.toUpperCase()))).toList(),
                    onChanged: (v) => setState(() => _mealTiming = v ?? _mealTiming),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _durationDaysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Duration (Days)', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _instructionsController,
              decoration: const InputDecoration(labelText: 'Special Clinical Instructions', border: OutlineInputBorder()),
            ),

            const SizedBox(height: 20),
            // Disclaimer
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.dashboardBg, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: const [
                  Icon(LucideIcons.info, size: 16, color: AppColors.muted),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Disclaimer: Prescribing decisions are the doctor\'s responsibility. Carevora does not provide diagnoses.',
                      style: TextStyle(fontSize: 11, color: AppColors.muted, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: _handlePrescribeSubmit,
                icon: const Icon(LucideIcons.checkCircle2, color: Colors.white),
                label: const Text('Issue Prescription & Generate Schedule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionsListTab() {
    final prescriptions = ref.watch(prescriptionsProvider);
    final residents = ref.watch(residentsProvider);

    final filtered = prescriptions.where((rx) {
      final res = residents.firstWhere((r) => r.id == rx.residentId, orElse: () => Resident(id: '', name: 'Unknown', roomNo: '', age: 0, gender: '', allergies: []));
      final matchesQuery = rx.medicineName.toLowerCase().contains(_rxSearchQuery.toLowerCase()) ||
          res.name.toLowerCase().contains(_rxSearchQuery.toLowerCase()) ||
          res.roomNo.contains(_rxSearchQuery);
      final matchesStatus = _statusFilter == null || rx.status == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _rxSearchQuery = val),
                    decoration: const InputDecoration(hintText: 'Search prescriptions by medicine or resident...', prefixIcon: Icon(LucideIcons.search, size: 18), border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<PrescriptionStatus?>(
                  value: _statusFilter,
                  hint: const Text('All Statuses'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Statuses')),
                    ...PrescriptionStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()))),
                  ],
                  onChanged: (val) => setState(() => _statusFilter = val),
                ),
              ],
            ),
            const SizedBox(height: 20),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (ctx, i) => const Divider(),
              itemBuilder: (ctx, i) {
                final rx = filtered[i];
                final res = residents.firstWhere((r) => r.id == rx.residentId, orElse: () => Resident(id: '', name: 'Unknown', roomNo: '', age: 0, gender: '', allergies: []));
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primarySoft,
                    child: Text(res.roomNo, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12)),
                  ),
                  title: Text('${rx.medicineName} ${rx.strength} (${rx.pattern.summary})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('Resident: ${res.name} (Room ${res.roomNo}) • Prescribed by ${rx.doctorId}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MealTimingBadge(mealTiming: rx.mealTiming),
                      const SizedBox(width: 10),
                      if (rx.status == PrescriptionStatus.active)
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.riskHigh, side: const BorderSide(color: AppColors.riskHigh)),
                          onPressed: () {
                            ref.read(mockDataRepositoryProvider).stopPrescription(rx.id, 'Stopped by doctor on review', rx.doctorId);
                          },
                          child: const Text('STOP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        )
                      else
                        Text(rx.status.name.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.muted)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorsTab() {
    final doctors = ref.watch(doctorsProvider);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Registered Clinical Doctors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: doctors.length,
              separatorBuilder: (ctx, i) => const Divider(),
              itemBuilder: (ctx, i) {
                final doc = doctors[i];
                return ListTile(
                  leading: const CircleAvatar(backgroundColor: AppColors.primarySoft, child: Icon(LucideIcons.userCheck, color: AppColors.primary)),
                  title: Text(doc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${doc.specialty} • ${doc.phone}'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
