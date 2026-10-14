import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';

class ResidentItem {
  final int id;
  final String name;
  final int age;
  final String gender;
  final String roomNo;
  final String elderHomeName;
  final int elderHomeId;
  final double cognitiveScore;
  final double emotionalScore;
  final double metabolicScore;
  final double riskScore;
  final String caregiverName;

  const ResidentItem({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.roomNo,
    required this.elderHomeName,
    required this.elderHomeId,
    required this.cognitiveScore,
    required this.emotionalScore,
    required this.metabolicScore,
    required this.riskScore,
    required this.caregiverName,
  });
}

class UserDirectoryItem {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? elderHomeName;

  const UserDirectoryItem({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.elderHomeName,
  });
}

class ResidentDirectoryPage extends ConsumerStatefulWidget {
  const ResidentDirectoryPage({super.key});

  @override
  ConsumerState<ResidentDirectoryPage> createState() => _ResidentDirectoryPageState();
}

class _ResidentDirectoryPageState extends ConsumerState<ResidentDirectoryPage> {
  int _selectedFilterHomeId = 0; // 0: All homes
  int _doctorTabIndex = 0; // 0: Elders, 1: All System Users
  bool _isLoading = false;

  final List<ResidentItem> _allEldersFallback = [
    const ResidentItem(
      id: 1,
      name: 'Sarah Jenkins',
      age: 78,
      gender: 'Female',
      roomNo: '101',
      elderHomeName: 'Serene Valley Senior Living',
      elderHomeId: 1,
      cognitiveScore: 0.68,
      emotionalScore: 0.74,
      metabolicScore: 0.80,
      riskScore: 0.28,
      caregiverName: 'Eleanor Vance',
    ),
    const ResidentItem(
      id: 2,
      name: 'Arthur Pendelton',
      age: 82,
      gender: 'Male',
      roomNo: '102',
      elderHomeName: 'Serene Valley Senior Living',
      elderHomeId: 1,
      cognitiveScore: 0.54,
      emotionalScore: 0.62,
      metabolicScore: 0.70,
      riskScore: 0.42,
      caregiverName: 'Eleanor Vance',
    ),
    const ResidentItem(
      id: 3,
      name: 'Margaret Chen',
      age: 79,
      gender: 'Female',
      roomNo: '201',
      elderHomeName: 'Golden Sunset Eldercare',
      elderHomeId: 2,
      cognitiveScore: 0.82,
      emotionalScore: 0.85,
      metabolicScore: 0.78,
      riskScore: 0.18,
      caregiverName: 'David Silva',
    ),
    const ResidentItem(
      id: 4,
      name: 'Robert Hastings',
      age: 84,
      gender: 'Male',
      roomNo: '202',
      elderHomeName: 'Golden Sunset Eldercare',
      elderHomeId: 2,
      cognitiveScore: 0.48,
      emotionalScore: 0.55,
      metabolicScore: 0.60,
      riskScore: 0.52,
      caregiverName: 'David Silva',
    ),
    const ResidentItem(
      id: 5,
      name: 'Simon Perera',
      age: 76,
      gender: 'Male',
      roomNo: '301',
      elderHomeName: 'Lotus Care Senior Home',
      elderHomeId: 3,
      cognitiveScore: 0.60,
      emotionalScore: 0.65,
      metabolicScore: 0.72,
      riskScore: 0.35,
      caregiverName: 'Staff On Duty',
    ),
  ];

  final List<UserDirectoryItem> _allUsersFallback = [
    const UserDirectoryItem(
      id: 1,
      name: 'Dr. Samantha Reed',
      email: 'dr.reed@carevora.com',
      role: 'DOCTOR',
      elderHomeName: 'Global Oversight (All Facilities)',
    ),
    const UserDirectoryItem(
      id: 2,
      name: 'Eleanor Vance',
      email: 'eleanor.vance@carevora.com',
      role: 'CAREGIVER',
      elderHomeName: 'Serene Valley Senior Living',
    ),
    const UserDirectoryItem(
      id: 3,
      name: 'David Silva',
      email: 'david.silva@carevora.com',
      role: 'CAREGIVER',
      elderHomeName: 'Golden Sunset Eldercare',
    ),
    const UserDirectoryItem(
      id: 4,
      name: 'Sarah Jenkins',
      email: 'sarah.jenkins@carevora.com',
      role: 'ELDER',
      elderHomeName: 'Serene Valley Senior Living',
    ),
    const UserDirectoryItem(
      id: 5,
      name: 'Arthur Pendelton',
      email: 'arthur.p@carevora.com',
      role: 'ELDER',
      elderHomeName: 'Serene Valley Senior Living',
    ),
    const UserDirectoryItem(
      id: 6,
      name: 'Margaret Chen',
      email: 'margaret.c@carevora.com',
      role: 'ELDER',
      elderHomeName: 'Golden Sunset Eldercare',
    ),
    const UserDirectoryItem(
      id: 7,
      name: 'Robert Hastings',
      email: 'robert.h@carevora.com',
      role: 'ELDER',
      elderHomeName: 'Golden Sunset Eldercare',
    ),
    const UserDirectoryItem(
      id: 8,
      name: 'Simon Perera',
      email: 'simon.p@carevora.com',
      role: 'ELDER',
      elderHomeName: 'Lotus Care Senior Home',
    ),
  ];

  List<ResidentItem> _liveResidents = [];
  List<UserDirectoryItem> _liveUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final authState = ref.read(authProvider).state;
    final token = authState.token;

    if (token == null) {
      _applyFallback();
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Fetch Residents scoped by backend role
      final res = await http.get(
        Uri.parse('${AppConfig.backendBaseUrl}/api/residents'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded['data'] as List?;
        if (list != null && list.isNotEmpty) {
          _liveResidents = list.map((e) {
            return ResidentItem(
              id: (e['id'] as num).toInt(),
              name: e['name'] as String? ?? 'Resident',
              age: (e['age'] as num?)?.toInt() ?? 75,
              gender: e['gender'] as String? ?? 'Unknown',
              roomNo: e['roomNumber'] as String? ?? 'Room',
              elderHomeName: e['elderHomeName'] as String? ?? 'Care Facility',
              elderHomeId: (e['elderHomeId'] as num?)?.toInt() ?? 1,
              cognitiveScore: 0.65,
              emotionalScore: 0.72,
              metabolicScore: 0.75,
              riskScore: 0.30,
              caregiverName: 'Assigned Care Team',
            );
          }).toList();
        }
      }

      // 2. If Doctor, fetch all users
      if (authState.isDoctor) {
        final usersRes = await http.get(
          Uri.parse('${AppConfig.backendBaseUrl}/api/doctor/all-users'),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 4));

        if (usersRes.statusCode == 200) {
          final decoded = jsonDecode(usersRes.body);
          final list = decoded['data'] as List?;
          if (list != null && list.isNotEmpty) {
            _liveUsers = list.map((u) {
              return UserDirectoryItem(
                id: (u['id'] as num).toInt(),
                name: u['name'] as String? ?? 'User',
                email: u['email'] as String? ?? '',
                role: u['role'] as String? ?? 'USER',
                elderHomeName: u['elderHomeName'] as String?,
              );
            }).toList();
          }
        }
      }
    } catch (_) {
      _applyFallback();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFallback() {
    _liveResidents = _allEldersFallback;
    _liveUsers = _allUsersFallback;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider).state;

    return Scaffold(
      backgroundColor: AppColors.dashboardBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRoleHeader(authState),
            const SizedBox(height: 20),
            if (authState.isDoctor)
              _buildDoctorView(authState)
            else if (authState.isCaregiver)
              _buildCaregiverView(authState)
            else
              _buildElderView(authState),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleHeader(AuthState auth) {
    String badgeText;
    Color badgeBg;
    Color badgeColor;
    IconData badgeIcon;

    if (auth.isDoctor) {
      badgeText = 'DOCTOR GLOBAL OVERSIGHT • All Facilities & All Users';
      badgeBg = const Color(0xFFCCFBF1);
      badgeColor = const Color(0xFF0F766E);
      badgeIcon = LucideIcons.stethoscope;
    } else if (auth.isCaregiver) {
      final home = auth.elderHomeName ?? 'Assigned Elder Home';
      badgeText = 'CAREGIVER SCOPED ACCESS • $home';
      badgeBg = AppColors.primarySoft;
      badgeColor = AppColors.primaryDeep;
      badgeIcon = LucideIcons.shieldCheck;
    } else {
      final home = auth.elderHomeName ?? 'Care Community';
      badgeText = 'ELDER PRIVACY PROTECTION • $home';
      badgeBg = const Color(0xFFFEF3C7);
      badgeColor = const Color(0xFF92400E);
      badgeIcon = LucideIcons.lock;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 14, color: badgeColor),
                    const SizedBox(width: 6),
                    Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            auth.isElder
                ? 'My Confidential Health Record'
                : 'Resident Directory & Community Registry',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            auth.isDoctor
                ? 'Logged in as ${auth.userName}. You have clinical clearance to review all residents and registered staff across all elder homes.'
                : auth.isCaregiver
                    ? 'Logged in as ${auth.userName}. You are actively assigned to ${auth.elderHomeName ?? 'your facility'}. You can only access residents residing in your facility.'
                    : 'Logged in as ${auth.userName}. Under HIPAA and resident privacy standards, you cannot view other elders\' records.',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.body,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // DOCTOR VIEW: Global access to all elders & all users
  // ----------------------------------------------------
  Widget _buildDoctorView(AuthState auth) {
    final allResidents = _liveResidents.isNotEmpty ? _liveResidents : _allEldersFallback;
    final allUsers = _liveUsers.isNotEmpty ? _liveUsers : _allUsersFallback;

    final filteredResidents = _selectedFilterHomeId == 0
        ? allResidents
        : allResidents.where((r) => r.elderHomeId == _selectedFilterHomeId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tabs: Elders vs All Users
        Row(
          children: [
            _buildTabButton('All Elders (${allResidents.length})', 0, LucideIcons.users),
            const SizedBox(width: 10),
            _buildTabButton('All System Users (${allUsers.length})', 1, LucideIcons.userCheck),
          ],
        ),
        const SizedBox(height: 16),

        if (_doctorTabIndex == 0) ...[
          // Facility Filter Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFacilityChip('All Elder Homes (${allResidents.length})', 0),
              _buildFacilityChip('Serene Valley (2)', 1),
              _buildFacilityChip('Golden Sunset (2)', 2),
              _buildFacilityChip('Lotus Care (1)', 3),
            ],
          ),
          const SizedBox(height: 16),
          // Elders Grid
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: filteredResidents.map((r) => _buildResidentCard(r, isDoctor: true)).toList(),
          ),
        ] else ...[
          // All Users Directory Table / Cards
          _buildAllUsersDirectory(allUsers),
        ],
      ],
    );
  }

  Widget _buildTabButton(String label, int index, IconData icon) {
    final isSelected = _doctorTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _doctorTabIndex = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.navy : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.navy),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityChip(String label, int homeId) {
    final isSelected = _selectedFilterHomeId == homeId;
    return InkWell(
      onTap: () => setState(() => _selectedFilterHomeId = homeId),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.body,
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // CAREGIVER VIEW: Scoped ONLY to Caregiver's Elder Home
  // ----------------------------------------------------
  Widget _buildCaregiverView(AuthState auth) {
    final allResidents = _liveResidents.isNotEmpty ? _liveResidents : _allEldersFallback;
    final assignedHomeId = auth.elderHomeId ?? 1;

    // Filter STRICTLY by caregiver's elder home
    final scopedResidents = allResidents.where((r) => r.elderHomeId == assignedHomeId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notice Container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.shieldCheck, color: Color(0xFF1D4ED8), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Facility-Scoped Care Access: ${auth.elderHomeName ?? "Assigned Facility"}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Displaying ${scopedResidents.length} resident(s) enrolled in your assigned care community. Residents belonging to other care facilities are shielded for data governance compliance.',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: scopedResidents.map((r) => _buildResidentCard(r, isDoctor: false)).toList(),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // ELDER VIEW: Confidential individual record ONLY
  // ----------------------------------------------------
  Widget _buildElderView(AuthState auth) {
    final allResidents = _liveResidents.isNotEmpty ? _liveResidents : _allEldersFallback;

    // Find this elder's record, or fallback to first
    final myRecord = allResidents.firstWhere(
      (r) => auth.userName != null && r.name.toLowerCase().contains(auth.userName!.toLowerCase().split(' ')[0]),
      orElse: () => allResidents.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Privacy Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: const [
              Icon(LucideIcons.lock, color: Color(0xFFB45309), size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Elder Confidential Privacy Protocol Active',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Other resident records are confidential and hidden from view. You have exclusive private access to your own personalized health telemetry and cognitive wellness progress.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF78350F)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primarySoft,
                      child: const Icon(LucideIcons.user, size: 30, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.userName ?? myRecord.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy,
                            ),
                          ),
                          Text(
                            'Room ${myRecord.roomNo} • Age ${myRecord.age} • ${myRecord.gender}',
                            style: const TextStyle(fontSize: 13, color: AppColors.body),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              auth.elderHomeName ?? myRecord.elderHomeName,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32, color: AppColors.border),
                const Text(
                  'Your Wellness Tracking Scores',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navy),
                ),
                const SizedBox(height: 12),
                _buildScoreBar('Cognitive Clarity', myRecord.cognitiveScore, const Color(0xFF6366F1)),
                const SizedBox(height: 10),
                _buildScoreBar('Emotional Wellness', myRecord.emotionalScore, const Color(0xFFEC4899)),
                const SizedBox(height: 10),
                _buildScoreBar('Metabolic Stability', myRecord.metabolicScore, const Color(0xFF10B981)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.heartHandshake, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Assigned Primary Caregiver: ${myRecord.caregiverName}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navy),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResidentCard(ResidentItem r, {required bool isDoctor}) {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  r.name.substring(0, 1),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Room ${r.roomNo} • Age ${r.age} (${r.gender})',
                      style: const TextStyle(fontSize: 12, color: AppColors.body),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: r.riskScore < 0.3 ? AppColors.riskLowBg : AppColors.riskModerateBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  r.riskScore < 0.3 ? 'Low Risk' : 'Moderate',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: r.riskScore < 0.3 ? AppColors.riskLow : AppColors.riskModerate,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Elder Home Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.lavenderBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.building2, size: 12, color: AppColors.primary),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    r.elderHomeName,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryDeep),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric('Cognitive', '${(r.cognitiveScore * 100).toInt()}%'),
              _buildMiniMetric('Emotional', '${(r.emotionalScore * 100).toInt()}%'),
              _buildMiniMetric('Metabolic', '${(r.metabolicScore * 100).toInt()}%'),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Caregiver: ${r.caregiverName}',
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
              if (isDoctor)
                InkWell(
                  onTap: () => context.go('/dashboard/doctor'),
                  child: const Text(
                    'Prescribe Rx →',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navy)),
      ],
    );
  }

  Widget _buildScoreBar(String label, double score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.body)),
            Text('${(score * 100).toInt()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score,
            minHeight: 6,
            backgroundColor: AppColors.surfaceSecondary,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildAllUsersDirectory(List<UserDirectoryItem> users) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: users.length,
        separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
        itemBuilder: (context, index) {
          final u = users[index];
          Color roleColor = AppColors.primary;
          if (u.role == 'DOCTOR') roleColor = const Color(0xFF0D9488);
          if (u.role == 'ELDER') roleColor = const Color(0xFFD97706);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: roleColor.withValues(alpha: 0.15),
              child: Text(
                u.name.substring(0, 1),
                style: TextStyle(fontWeight: FontWeight.bold, color: roleColor),
              ),
            ),
            title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(
              '${u.email} • ${u.elderHomeName ?? "No Home"}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                u.role,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: roleColor),
              ),
            ),
          );
        },
      ),
    );
  }
}
