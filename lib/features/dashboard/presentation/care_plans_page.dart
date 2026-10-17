import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../assessment/application/care_plans_service.dart';
import '../../assessment/application/cognitive_assessment_service.dart';
import '../../auth/application/auth_controller.dart';

class CarePlansPage extends ConsumerStatefulWidget {
  final int? initialResidentId;

  const CarePlansPage({super.key, this.initialResidentId});

  @override
  ConsumerState<CarePlansPage> createState() => _CarePlansPageState();
}

class _CarePlansPageState extends ConsumerState<CarePlansPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<CarePlanResident> _allResidents = [];
  bool _isLoadingResidents = false;
  String? _residentLoadError;

  CarePlanResident? _selectedResident;

  // Wellness Data State
  CarePlanCognitiveData? _cognitiveData;
  CarePlanEmotionalData? _emotionalData;
  CarePlanMetabolicData? _metabolicData;
  bool _isLoadingWellness = false;
  String? _wellnessError;

  // Cognitive history view state
  bool _showCognitiveHistory = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final auth = ref.read(authProvider).state;

    // 1. If Elder role: directly load own profile
    if (auth.isElder) {
      final elderId = auth.residentId ?? 1;
      final elderResident = CarePlanResident(
        id: elderId,
        name: auth.userName ?? 'Sarah Jenkins',
        roomNumber: 'Room 204',
        elderHomeName: auth.elderHomeName ?? 'Serene Valley Senior Living',
        elderHomeId: auth.elderHomeId ?? 1,
      );
      setState(() {
        _selectedResident = elderResident;
      });
      await _loadResidentWellness(elderResident);
      return;
    }

    // 2. Caregiver / Doctor: fetch residents list
    setState(() {
      _isLoadingResidents = true;
      _residentLoadError = null;
    });

    try {
      final token = auth.token;
      final facilityId = auth.isCaregiver ? auth.elderHomeId : null;
      final residents = await CarePlansService.fetchResidents(
        token: token,
        facilityId: facilityId,
      );

      if (mounted) {
        setState(() {
          _allResidents = residents;
          _isLoadingResidents = false;
        });

        // Check if an initial residentId was provided
        if (widget.initialResidentId != null) {
          final target = residents.firstWhere(
            (r) => r.id == widget.initialResidentId,
            orElse: () => CarePlanResident(
              id: widget.initialResidentId!,
              name: 'Resident #${widget.initialResidentId}',
              roomNumber: 'Room',
              elderHomeName: auth.elderHomeName ?? 'Assigned Facility',
              elderHomeId: auth.elderHomeId ?? 1,
            ),
          );
          await _selectResident(target);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingResidents = false;
          _residentLoadError = 'Failed to load residents. Please check connection.';
        });
      }
    }
  }

  Future<void> _selectResident(CarePlanResident resident) async {
    setState(() {
      _selectedResident = resident;
      _showCognitiveHistory = false;
    });
    await _loadResidentWellness(resident);
  }

  Future<void> _loadResidentWellness(CarePlanResident resident) async {
    setState(() {
      _isLoadingWellness = true;
      _wellnessError = null;
    });

    final token = ref.read(authProvider).state.token;

    try {
      final cognitiveFuture = CarePlansService.loadCognitiveData(resident.id, token: token);
      final emotionalFuture = CarePlansService.loadEmotionalData(
        resident.id,
        residentName: resident.name,
        token: token,
      );
      final metabolicFuture = CarePlansService.loadMetabolicData(resident.id, token: token);

      final results = await Future.wait([cognitiveFuture, emotionalFuture, metabolicFuture]);

      if (mounted && _selectedResident?.id == resident.id) {
        setState(() {
          _cognitiveData = results[0] as CarePlanCognitiveData;
          _emotionalData = results[1] as CarePlanEmotionalData;
          _metabolicData = results[2] as CarePlanMetabolicData;
          _isLoadingWellness = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWellness = false;
          _wellnessError = 'Failed to load resident care plan records: $e';
        });
      }
    }
  }

  void _clearSelectedResident() {
    setState(() {
      _selectedResident = null;
      _cognitiveData = null;
      _emotionalData = null;
      _metabolicData = null;
      _showCognitiveHistory = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider).state;

    return Scaffold(
      backgroundColor: AppColors.dashboardBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(auth),
            const SizedBox(height: 20),

            // If not an Elder, render the Search UI
            if (!auth.isElder) ...[
              _buildSearchBar(),
              const SizedBox(height: 20),
            ],

            // Content body: either Search Results, Empty State, or Selected Resident Care Plan
            if (_selectedResident != null) ...[
              _buildSelectedResidentPlan(),
            ] else if (_isLoadingResidents) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ] else if (_residentLoadError != null) ...[
              _buildErrorBanner(_residentLoadError!, () => _loadInitialData()),
            ] else if (_searchQuery.trim().isEmpty) ...[
              _buildEmptySearchPrompt(auth),
            ] else ...[
              _buildSearchResultsList(),
            ],
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // HEADER
  // ----------------------------------------------------
  Widget _buildHeader(AuthState auth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(LucideIcons.clipboardList, size: 28, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Care Plans Management',
                      style: AppTextStyles.h2.copyWith(fontSize: 22, color: AppColors.navy),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.lavenderBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: const Text(
                        'Multimodal Clinical Guidance',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  auth.isElder
                      ? 'Your personalized holistic wellness plan and daily care recommendations.'
                      : 'Search any resident by name or resident ID to view structured, risk-based care plans across Cognitive, Emotional, and Metabolic wellness domains.',
                  style: const TextStyle(fontSize: 13, color: AppColors.body, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // SEARCH BAR (Consistent with Resident Directory UI)
  // ----------------------------------------------------
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.search, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 14, color: AppColors.navy),
              decoration: const InputDecoration(
                hintText: 'Search residents by name or resident ID...',
                hintStyle: TextStyle(fontSize: 14, color: AppColors.muted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.x, size: 18, color: AppColors.muted),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              tooltip: 'Clear search',
            ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // EMPTY SEARCH PROMPT
  // ----------------------------------------------------
  Widget _buildEmptySearchPrompt(AuthState auth) {
    final facilityName = auth.elderHomeName ?? 'Your Facility';
    final count = _allResidents.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.search, size: 28, color: AppColors.primary),
          ),
          const SizedBox(height: 18),
          const Text(
            'Search to Select a Resident',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(
              'Type a resident name or resident ID above to review their latest assessment results and personalized Care Plans.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.body, height: 1.4),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.lavenderBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.building2, size: 14, color: AppColors.primaryDeep),
                const SizedBox(width: 6),
                Text(
                  '$facilityName ($count residents available)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDeep,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // SEARCH RESULTS LIST
  // ----------------------------------------------------
  Widget _buildSearchResultsList() {
    final q = _searchQuery.trim().toLowerCase();
    final matches = _allResidents.where((r) {
      final nameMatch = r.name.toLowerCase().contains(q);
      final idMatch = r.id.toString() == q;
      final roomMatch = r.roomNumber.toLowerCase().contains(q);
      return nameMatch || idMatch || roomMatch;
    }).toList();

    if (matches.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(LucideIcons.userX, size: 36, color: AppColors.muted),
            const SizedBox(height: 14),
            const Text(
              'No residents found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy),
            ),
            const SizedBox(height: 6),
            Text(
              'No resident matches "$_searchQuery". Please check the spelling or resident ID.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              'Matching Residents (${matches.length})',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.muted),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: matches.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
            itemBuilder: (context, index) {
              final r = matches[index];
              return InkWell(
                onTap: () => _selectResident(r),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primarySoft,
                        child: Text(
                          r.name.isNotEmpty ? r.name.substring(0, 1).toUpperCase() : 'R',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  r.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navy,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.lavenderBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'ID: #${r.id}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${r.roomNumber} • ${r.elderHomeName}${r.age != null ? ' • Age ${r.age}' : ''}',
                              style: const TextStyle(fontSize: 12, color: AppColors.body),
                            ),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.muted),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // SELECTED RESIDENT CARE PLAN VIEW
  // ----------------------------------------------------
  Widget _buildSelectedResidentPlan() {
    final resident = _selectedResident!;
    final auth = ref.watch(authProvider).state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resident Profile Header Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  resident.name.isNotEmpty ? resident.name.substring(0, 1).toUpperCase() : 'R',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          resident.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.lavenderBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ID: #${resident.id}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${resident.roomNumber} • ${resident.elderHomeName}${resident.age != null ? ' • Age ${resident.age}' : ''}${resident.gender != null ? ' • ${resident.gender}' : ''}',
                      style: const TextStyle(fontSize: 13, color: AppColors.body),
                    ),
                  ],
                ),
              ),
              if (!auth.isElder)
                OutlinedButton.icon(
                  onPressed: _clearSelectedResident,
                  icon: const Icon(LucideIcons.userCheck, size: 16),
                  label: const Text('Change Resident'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primarySoft, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Clinical Support Guidance Notice
        _buildClinicalNoticeBanner(),
        const SizedBox(height: 20),

        if (_isLoadingWellness) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
        ] else if (_wellnessError != null) ...[
          _buildErrorBanner(_wellnessError!, () => _loadResidentWellness(resident)),
        ] else ...[
          // THREE SEPARATE RECOMMENDATION CARDS
          // 1. Cognitive Wellness
          _buildCognitiveWellnessCard(),
          const SizedBox(height: 20),

          // 2. Emotional Wellness
          _buildEmotionalWellnessCard(),
          const SizedBox(height: 20),

          // 3. Metabolic Wellness
          _buildMetabolicWellnessCard(),
        ],
      ],
    );
  }

  // ----------------------------------------------------
  // CLINICAL NOTICE BANNER
  // ----------------------------------------------------
  Widget _buildClinicalNoticeBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(LucideIcons.info, size: 18, color: Color(0xFF2563EB)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Caregiver Guidance Notice: Care plan recommendations provided below are supportive wellness suggestions and non-pharmacological interventions. They are not diagnoses or medical prescriptions. Consult the attending physician or clinical lead before modifying clinical protocols.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF1E40AF),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // 1. COGNITIVE WELLNESS CARD
  // ----------------------------------------------------
  Widget _buildCognitiveWellnessCard() {
    final cog = _cognitiveData;
    if (cog == null || !cog.hasAssessment) {
      return _buildEmptyCognitiveCard();
    }

    final latest = cog.latestAssessment!;
    final rec = cog.recommendation;
    final accuracyStr = CarePlansService.formatTaskAccuracyScore(cog.taskAccuracyScore);
    final dateStr = _formatDate(cog.assessmentDate);
    final priorRecords = _getPriorRecords(cog);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.brain, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cognitive Wellness',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Latest Assessment: $dateStr',
                        style: const TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                // Risk Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: rec.badgeBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: rec.badgeColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(rec.icon, size: 14, color: rec.badgeColor),
                      const SizedBox(width: 6),
                      Text(
                        rec.categoryLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: rec.badgeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Key Metrics Row: Task Accuracy Score vs AI Risk Level
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Task Accuracy Score Tile
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(LucideIcons.target, size: 14, color: AppColors.muted),
                                SizedBox(width: 6),
                                Text(
                                  'Task Accuracy Score',
                                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              accuracyStr,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navy,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cog.taskAccuracyScore != null &&
                                      ((cog.taskAccuracyScore! <= 1.0 && cog.taskAccuracyScore! > 0.0)
                                          ? cog.taskAccuracyScore! * 100.0 >= 80.0
                                          : cog.taskAccuracyScore! >= 80.0)
                                  ? 'High task execution accuracy'
                                  : 'Moderate or partial task execution',
                              style: const TextStyle(fontSize: 11, color: AppColors.body),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // AI-Predicted Risk Level Tile
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: rec.badgeBg.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: rec.badgeColor.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(LucideIcons.sparkles, size: 14, color: rec.badgeColor),
                                const SizedBox(width: 6),
                                const Text(
                                  'Actual AI-Predicted Risk',
                                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              rec.categoryLabel,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: rec.badgeColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cog.mlAvailable
                                  ? '31-feature ML model prediction'
                                  : (cog.actualRiskLevel != null
                                      ? 'Score-based clinical risk tier'
                                      : 'Model prediction unavailable'),
                              style: const TextStyle(fontSize: 11, color: AppColors.body),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Sub-Domain Accuracy Bar
                _buildDomainScoresRow(latest),
                const SizedBox(height: 20),

                // Risk-Based Recommendations Block
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: rec.badgeBg.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: rec.badgeColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(rec.icon, color: rec.badgeColor, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            rec.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: rec.badgeColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rec.summary,
                        style: const TextStyle(fontSize: 13, color: AppColors.body, height: 1.4),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Caregiver Action Protocol:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...rec.actionItems.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: rec.badgeColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.navy,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Previous Assessment History Toggle
                if (priorRecords.isNotEmpty) ...[
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showCognitiveHistory = !_showCognitiveHistory;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            _showCognitiveHistory ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Previous Assessment History (${priorRecords.length} prior records)',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showCognitiveHistory) ...[
                    const SizedBox(height: 10),
                    _buildCognitiveHistoryList(priorRecords),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCognitiveCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.brain, size: 40, color: AppColors.muted),
          const SizedBox(height: 12),
          const Text(
            'No Cognitive Assessment Recorded',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy),
          ),
          const SizedBox(height: 6),
          const Text(
            'This resident has not completed a cognitive evaluation yet. Start an assessment to generate risk-based care plans.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.push('/dashboard/assessment'),
            icon: const Icon(LucideIcons.play, size: 16),
            label: const Text('Start Cognitive Assessment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDomainScoresRow(CognitiveSubmissionResult result) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cognitive Domain Scores',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildDomainScoreItem('Orientation', result.orientation)),
              Expanded(child: _buildDomainScoreItem('Memory', result.memory)),
              Expanded(child: _buildDomainScoreItem('Attention', result.attention)),
              Expanded(child: _buildDomainScoreItem('Recall', result.recall)),
              Expanded(child: _buildDomainScoreItem('Reasoning', result.reasoning)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDomainScoreItem(String label, double? score) {
    final pct = CarePlansService.formatDomainScore(score);
    return Column(
      children: [
        Text(
          pct,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }

  List<CognitiveSubmissionResult> _getPriorRecords(CarePlanCognitiveData cog) {
    final latest = cog.latestAssessment;
    if (latest == null) return cog.history;
    return cog.history.where((item) {
      if (identical(item, latest)) return false;
      if (latest.id > 0 && item.id > 0 && item.id == latest.id) return false;
      if (latest.sessionId != null &&
          latest.sessionId!.isNotEmpty &&
          item.sessionId != null &&
          item.sessionId!.isNotEmpty &&
          item.sessionId == latest.sessionId) {
        return false;
      }
      return true;
    }).toList();
  }

  Widget _buildCognitiveHistoryList(List<CognitiveSubmissionResult> priorRecords) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: priorRecords.length,
        separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
        itemBuilder: (context, index) {
          final item = priorRecords[index];
          final date = _formatDate(item.createdAt);
          final accuracy = CarePlansService.formatTaskAccuracyScore(item.acrfScore);
          String risk = item.riskLevel ?? item.mlPrediction ?? '';
          if (risk.isEmpty ||
              risk == 'UNKNOWN' ||
              risk == 'Not Available' ||
              risk == 'Risk Level Not Available' ||
              risk == 'Prediction Unavailable') {
            if (item.acrfScore != null) {
              final s = (item.acrfScore! <= 1.0 && item.acrfScore! > 0.0)
                  ? item.acrfScore! * 100.0
                  : item.acrfScore!;
              if (s >= 70.0) {
                risk = 'LOW';
              } else if (s >= 50.0) {
                risk = 'MODERATE';
              } else {
                risk = 'HIGH';
              }
            } else {
              risk = 'UNKNOWN';
            }
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(LucideIcons.calendar, size: 16, color: AppColors.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        date,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Assessed by ${item.assessedBy}',
                        style: const TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Accuracy: $accuracy',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.body),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getRiskBadgeColor(risk).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    risk,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getRiskBadgeColor(risk),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ----------------------------------------------------
  // 2. EMOTIONAL WELLNESS CARD
  // ----------------------------------------------------
  Widget _buildEmotionalWellnessCard() {
    final emo = _emotionalData;
    final hasData = emo != null && emo.hasData;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE7F3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.heartHandshake, color: Color(0xFFDB2777), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Emotional Wellness',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasData
                            ? 'Social connectedness and affect stability • Status: ${emo.status ?? 'STABLE'}'
                            : 'Personalized activities, literature, music & social engagement',
                        style: const TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                if (hasData && emo.riskLevel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getRiskBadgeColor(emo.riskLevel!).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${emo.riskLevel} RISK',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getRiskBadgeColor(emo.riskLevel!),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasData && emo.overallScore != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Emotional Wellness Score', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                              const SizedBox(height: 6),
                              Text(
                                '${emo.overallScore!.toStringAsFixed(0)}%',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Social Connection Trend', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                              const SizedBox(height: 6),
                              Text(
                                emo.trajectory ?? 'Stable Trajectory',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Personalized Activities, Games, Books, Songs, Social Engagement
                if (hasData && emo.recommendations.isNotEmpty) ...[
                  const Text(
                    'Personalized Therapeutic Activities & Recommendations',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navy),
                  ),
                  const SizedBox(height: 10),
                  ...emo.recommendations.map((item) => _buildEmotionalRecommendationTile(item)),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: const [
                        Icon(LucideIcons.heart, size: 28, color: AppColors.muted),
                        SizedBox(height: 8),
                        Text(
                          'No Emotional Assessment Available',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Conduct an emotional wellness questionnaire to generate personalized music, literature, and social engagement recommendations for this resident.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionalRecommendationTile(EmotionalRecommendationItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(item.icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.lavenderBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.category,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(fontSize: 12, color: AppColors.body, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // 3. METABOLIC WELLNESS CARD (Strictly Honest Pending Status)
  // ----------------------------------------------------
  Widget _buildMetabolicWellnessCard() {
    final meta = _metabolicData ?? const CarePlanMetabolicData();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.activity, color: Color(0xFFD97706), size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Metabolic Wellness',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Vitals tracking, glucose regularity, and sleep rhythm',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                // Pending Integration Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.clock, size: 12, color: Color(0xFFD97706)),
                      const SizedBox(width: 4),
                      Text(
                        meta.statusMessage,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Content Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(LucideIcons.layers, size: 16, color: AppColors.muted),
                      SizedBox(width: 8),
                      Text(
                        'No Metabolic Assessment Available',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navy),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    meta.integrationNote,
                    style: const TextStyle(fontSize: 13, color: AppColors.body, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• Hardware sensors for continuous vital signs and glucose monitoring are pending facility hardware validation.\n• No simulated or fabricated measurements are shown to maintain clinical record integrity.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // ERROR BANNER
  // ----------------------------------------------------
  Widget _buildErrorBanner(String message, VoidCallback onRetry) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.riskHighBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.riskHigh.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertTriangle, color: AppColors.riskHigh, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppColors.navy),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry', style: TextStyle(color: AppColors.riskHigh, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // HELPERS
  // ----------------------------------------------------
  Color _getRiskBadgeColor(String risk) {
    final norm = risk.toUpperCase();
    if (norm.contains('LOW')) return AppColors.riskLow;
    if (norm.contains('MODERATE')) return AppColors.riskModerate;
    if (norm.contains('HIGH')) return AppColors.riskHigh;
    return AppColors.muted;
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return 'Recent';
    try {
      final parsed = DateTime.parse(raw).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final m = months[parsed.month - 1];
      final day = parsed.day.toString().padLeft(2, '0');
      final year = parsed.year;
      final hour12 = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
      final min = parsed.minute.toString().padLeft(2, '0');
      final amPm = parsed.hour >= 12 ? 'PM' : 'AM';
      return '$day $m $year, $hour12:$min $amPm';
    } catch (_) {
      return raw;
    }
  }
}
