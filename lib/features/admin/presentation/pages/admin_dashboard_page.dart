import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/responsive/responsive_builder.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/carevora_logo.dart';
import '../../../auth/application/auth_controller.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  // Simulated System Settings & Control Toggles
  bool _aiInferenceActive = true;
  bool _alertNotificationsActive = true;
  bool _autoBackupEnabled = true;
  double _aiSensitivityThreshold = 0.75;

  // Active Sub-Tab: 0: Overview, 1: Mood Analytics, 2: SOS Emergency Queue, 3: Shift Tracker, 4: Medication Schedule, 5: AI Fine-tuning
  int _selectedTab = 0;

  final List<Map<String, dynamic>> _sosAlerts = [
    {
      'id': 'SOS-991',
      'patient': 'Florence Nightingale',
      'trigger': 'High Distress Affect (Sadness 94%)',
      'time': '10 Oct, 08:05 AM',
      'status': 'Unresolved',
      'severity': 'Critical'
    },
    {
      'id': 'SOS-988',
      'patient': 'Eleanor Vance',
      'trigger': 'Fall Risk Gesture Detected',
      'time': '10 Oct, 06:20 AM',
      'status': 'In Progress',
      'severity': 'High'
    },
  ];

  final List<Map<String, dynamic>> _shiftLogs = [
    {
      'caregiver': 'Seetha N.',
      'shift': 'Morning (07:00 AM - 03:00 PM)',
      'status': 'Clocked In (06:55 AM)',
      'assignedCount': 2
    },
    {
      'caregiver': 'Sarah Jenkins',
      'shift': 'Evening (03:00 PM - 11:00 PM)',
      'status': 'Scheduled',
      'assignedCount': 1
    },
    {
      'caregiver': 'Dr. Aris Thorne',
      'shift': 'On-Call Medical Lead',
      'status': 'Active On-Call',
      'assignedCount': 3
    },
  ];

  final List<Map<String, dynamic>> _medications = [
    {
      'patient': 'Florence Nightingale',
      'medicine': 'Donepezil 10mg',
      'time': '09:00 AM',
      'status': 'Administered by Seetha N.',
      'given': true
    },
    {
      'patient': 'Arthur Pendelton',
      'medicine': 'Memantine 5mg',
      'time': '01:00 PM',
      'status': 'Pending Caregiver Check',
      'given': false
    },
    {
      'patient': 'Eleanor Vance',
      'medicine': 'Multivitamin & Physio',
      'time': '04:00 PM',
      'status': 'Scheduled Evening',
      'given': false
    },
  ];

  final List<Map<String, dynamic>> _registeredUsers = [
    {
      'name': 'Seetha N.',
      'email': 'seetha@carevora.com',
      'role': 'Senior Caregiver',
      'status': 'Active',
      'lastLogin': 'Today, 08:14 AM'
    },
    {
      'name': 'Sarah Jenkins',
      'email': 'sarah@meadowcare.org',
      'role': 'Care Director',
      'status': 'Active',
      'lastLogin': 'Yesterday, 04:30 PM'
    },
    {
      'name': 'Dr. Aris Thorne',
      'email': 'aris@carevora.com',
      'role': 'Clinical Lead Specialist',
      'status': 'Active',
      'lastLogin': '10 Oct, 01:15 AM'
    },
  ];

  final List<Map<String, dynamic>> _patients = [
    {
      'id': 'P-101',
      'name': 'Florence Nightingale',
      'age': 84,
      'condition': 'Mild Cognitive Impairment',
      'caregiver': 'Seetha N.',
      'status': 'Stable'
    },
    {
      'id': 'P-102',
      'name': 'Arthur Pendelton',
      'age': 79,
      'condition': 'Early Alzheimer\'s',
      'caregiver': 'Sarah Jenkins',
      'status': 'Monitoring'
    },
    {
      'id': 'P-103',
      'name': 'Eleanor Vance',
      'age': 88,
      'condition': 'Post-stroke Rehab',
      'caregiver': 'Seetha N.',
      'status': 'Critical Track'
    },
  ];

  final List<Map<String, dynamic>> _auditLogs = [
    {
      'event': 'AI Vision Model Re-trained',
      'user': 'Admin System',
      'time': '10 Oct, 07:38 AM',
      'severity': 'Low'
    },
    {
      'event': 'Caregiver Login Successful',
      'user': 'seetha@carevora.com',
      'time': '10 Oct, 08:14 AM',
      'severity': 'Info'
    },
    {
      'event': 'High Risk Affect Alert Triggered',
      'user': 'AI Sensor Engine',
      'time': '10 Oct, 02:15 AM',
      'severity': 'Warning'
    },
  ];

  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String role = 'Caregiver';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Staff Member', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: ['Senior Caregiver', 'Caregiver', 'Nurse Specialist', 'Care Director']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => role = v ?? role,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && emailCtrl.text.isNotEmpty) {
                setState(() {
                  _registeredUsers.add({
                    'name': nameCtrl.text,
                    'email': emailCtrl.text,
                    'role': role,
                    'status': 'Active',
                    'lastLogin': 'Just now'
                  });
                  _auditLogs.insert(0, {
                    'event': 'New User Added (${nameCtrl.text})',
                    'user': 'Admin',
                    'time': 'Just now',
                    'severity': 'Info'
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Staff member ${nameCtrl.text} registered successfully!')),
                );
              }
            },
            child: const Text('Save User', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddPatientDialog() {
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final condCtrl = TextEditingController();
    String caregiver = _registeredUsers.first['name']!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Elder / Patient Profile', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Patient Full Name')),
            TextField(controller: ageCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Age')),
            TextField(controller: condCtrl, decoration: const InputDecoration(labelText: 'Primary Condition (e.g. Memory Loss)')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: caregiver,
              decoration: const InputDecoration(labelText: 'Assigned Caregiver'),
              items: _registeredUsers
                  .map((u) => DropdownMenuItem<String>(value: u['name'] as String, child: Text(u['name'] as String)))
                  .toList(),
              onChanged: (v) => caregiver = v ?? caregiver,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                setState(() {
                  _patients.add({
                    'id': 'P-${100 + _patients.length + 1}',
                    'name': nameCtrl.text,
                    'age': int.tryParse(ageCtrl.text) ?? 80,
                    'condition': condCtrl.text.isEmpty ? 'General Care' : condCtrl.text,
                    'caregiver': caregiver,
                    'status': 'Stable'
                  });
                  _auditLogs.insert(0, {
                    'event': 'New Patient Profile Created (${nameCtrl.text})',
                    'user': 'Admin',
                    'time': 'Just now',
                    'severity': 'Info'
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Patient ${nameCtrl.text} added & assigned to $caregiver!')),
                );
              }
            },
            child: const Text('Save Profile', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleLogout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      {'label': 'Overview Dashboard', 'icon': LucideIcons.layoutDashboard},
      {'label': 'Mood Trends & Analytics', 'icon': LucideIcons.barChart3},
      {'label': 'Emergency SOS Queue', 'icon': LucideIcons.bellRing},
      {'label': 'Shift & Attendance Tracker', 'icon': LucideIcons.clock},
      {'label': 'Medication & Care Schedule', 'icon': LucideIcons.pill},
      {'label': 'Live Medicine Board (System)', 'icon': LucideIcons.activity},
      {'label': 'PyTorch AI Fine-Tuning', 'icon': LucideIcons.brainCircuit},
    ];

    return Scaffold(
      backgroundColor: AppColors.dashboardBg,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(LucideIcons.menu, color: Colors.white, size: 22),
            tooltip: 'Open Admin Navigation Menu',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            const CarevoraLogo(
              variant: LogoVariant.full,
              size: 26,
              isDark: true,
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accentPink.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.accentPink, width: 1),
              ),
              child: const Text(
                'ADMIN PANEL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: Colors.white, size: 20),
            tooltip: 'Sign Out Admin',
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.navy,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CarevoraLogo(
                      variant: LogoVariant.full,
                      size: 32,
                      isDark: true,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Admin Control Center',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'admin@carevora.com',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: tabs.length,
                  itemBuilder: (ctx, i) {
                    final isSelected = _selectedTab == i;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Material(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          leading: Icon(
                            tabs[i]['icon'] as IconData,
                            color: isSelected ? Colors.white : Colors.white70,
                            size: 20,
                          ),
                          title: Text(
                            tabs[i]['label'] as String,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          onTap: () {
                            setState(() => _selectedTab = i);
                            Navigator.pop(ctx); // Close drawer
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                    foregroundColor: Colors.redAccent,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _handleLogout,
                  icon: const Icon(LucideIcons.logOut, size: 18),
                  label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ResponsiveBuilder(
        mobile: (context) => _buildBody(isMobile: true),
        tablet: (context) => _buildBody(isMobile: false),
        desktop: (context) => _buildBody(isMobile: false),
      ),
    );
  }

  Widget _buildBody({required bool isMobile}) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Banner
          _buildAdminHeaderCard(),
          const SizedBox(height: 24),

          // Quick System Status Cards Grid
          _buildMetricsGrid(isMobile: isMobile),
          const SizedBox(height: 24),

          // Admin Feature Navigation Tabs
          _buildAdminTabBar(isMobile: isMobile),
          const SizedBox(height: 24),

          // Render Selected Admin Feature Tab
          if (_selectedTab == 0) ...[
            if (isMobile) ...[
              _buildPatientManagementSection(),
              const SizedBox(height: 24),
              _buildSystemControlSection(),
              const SizedBox(height: 24),
              _buildUserManagementSection(),
              const SizedBox(height: 24),
              _buildAuditLogsSection(),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _buildPatientManagementSection(),
                        const SizedBox(height: 24),
                        _buildSystemControlSection(),
                        const SizedBox(height: 24),
                        _buildAuditLogsSection(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 6,
                    child: _buildUserManagementSection(),
                  ),
                ],
              ),
          ] else if (_selectedTab == 1)
            _buildMoodAnalyticsSection()
          else if (_selectedTab == 2)
            _buildSosEmergencySection()
          else if (_selectedTab == 3)
            _buildShiftTrackerSection()
          else if (_selectedTab == 4)
            _buildMedicationScheduleSection()
          else if (_selectedTab == 5) ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
              onPressed: () => context.go('/dashboard/medicine'),
              icon: const Icon(LucideIcons.externalLink, color: Colors.white, size: 16),
              label: const Text('Open Full Interactive Live Medicine Board', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            _buildMedicationScheduleSection(),
          ] else if (_selectedTab == 6)
            _buildAiFineTuningSection(),
        ],
      ),
    );
  }

  Widget _buildAdminHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.primaryDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDeep.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.shieldAlert,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'System Administrator Control Center',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage facility access, AI vision model parameters, user roles, and security compliance logs.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid({required bool isMobile}) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildStatCard('Active Caregivers', '14 Staff', LucideIcons.users, AppColors.primary),
        _buildStatCard('Connected Facilities', '3 Locations', LucideIcons.building2, AppColors.leafGreen),
        _buildStatCard('AI Model Status', 'PyTorch CNN Online', LucideIcons.cpu, AppColors.accentPink),
        _buildStatCard('Security Audits', '100% Compliant', LucideIcons.shieldCheck, AppColors.riskLow),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color accentColor) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
              Icon(icon, size: 18, color: accentColor),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemControlSection() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(LucideIcons.sliders, size: 20, color: AppColors.primary),
                SizedBox(width: 10),
                Text(
                  'AI & System Control Toggles',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SwitchListTile(
              value: _aiInferenceActive,
              activeThumbColor: AppColors.primary,
              title: const Text('Real-time PyTorch AI Model Inference', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('Enable camera affect recognition microservice', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              onChanged: (val) => setState(() => _aiInferenceActive = val),
            ),
            const Divider(),
            SwitchListTile(
              value: _alertNotificationsActive,
              activeThumbColor: AppColors.primary,
              title: const Text('Automated High-Risk Clinical Alerts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('Send SMS and push alerts to head nurses', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              onChanged: (val) => setState(() => _alertNotificationsActive = val),
            ),
            const Divider(),
            SwitchListTile(
              value: _autoBackupEnabled,
              activeThumbColor: AppColors.primary,
              title: const Text('Encrypted Database Auto-Backup', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('Daily backup to cloud healthcare storage', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              onChanged: (val) => setState(() => _autoBackupEnabled = val),
            ),
            const SizedBox(height: 14),
            const Text('AI Sensitivity Threshold:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Slider(
              value: _aiSensitivityThreshold,
              activeColor: AppColors.primary,
              min: 0.5,
              max: 0.95,
              divisions: 9,
              label: '${(_aiSensitivityThreshold * 100).toInt()}% Confidence',
              onChanged: (val) => setState(() => _aiSensitivityThreshold = val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserManagementSection() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(LucideIcons.userCheck, size: 20, color: AppColors.primary),
                    SizedBox(width: 10),
                    Text(
                      'Registered Staff & Roles',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddUserDialog,
                  icon: const Icon(LucideIcons.userPlus, size: 14, color: Colors.white),
                  label: const Text('Add User', style: TextStyle(fontSize: 12, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _registeredUsers.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final u = _registeredUsers[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primarySoft,
                    child: Text(
                      u['name']![0],
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  title: Text(u['name']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: Text('${u['email']} • ${u['role']}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.riskLowBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      u['status']!,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.riskLow),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientManagementSection() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.heartPulse, size: 20, color: AppColors.primary),
                  const SizedBox(width: 10),
                  const Text(
                    'Elders & Patients Managed',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAddPatientDialog,
                icon: const Icon(LucideIcons.plus, size: 14, color: Colors.white),
                label: const Text('Add Patient', style: TextStyle(fontSize: 12, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _patients.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final p = _patients[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.user, color: AppColors.primary, size: 18),
                ),
                title: Text('${p['name']} (${p['age']} yrs)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: Text('${p['condition']} • Caregiver: ${p['caregiver']}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p['status']!,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.redAccent),
                      onPressed: () {
                        setState(() {
                          final removed = _patients.removeAt(index);
                          _auditLogs.insert(0, {
                            'event': 'Patient Profile Removed (${removed['name']})',
                            'user': 'Admin',
                            'time': 'Just now',
                            'severity': 'Warning'
                          });
                        });
                      },
                    )
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

  Widget _buildAuditLogsSection() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(LucideIcons.fileText, size: 20, color: AppColors.primary),
                SizedBox(width: 10),
                Text(
                  'Security & Audit Logs',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _auditLogs.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final log = _auditLogs[index];
                return Row(
                  children: [
                    const Icon(LucideIcons.shieldCheck, size: 16, color: AppColors.muted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(log['event']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navy)),
                          Text('${log['user']} • ${log['time']}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminTabBar({required bool isMobile}) {
    final tabs = [
      {'label': 'Overview', 'icon': LucideIcons.layoutDashboard},
      {'label': 'Mood Analytics', 'icon': LucideIcons.barChart3},
      {'label': 'SOS Emergency Queue', 'icon': LucideIcons.bellRing},
      {'label': 'Shift Tracker', 'icon': LucideIcons.clock},
      {'label': 'Medication Schedule', 'icon': LucideIcons.pill},
      {'label': 'AI Fine-Tuning', 'icon': LucideIcons.brainCircuit},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSelected = _selectedTab == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              showCheckmark: false,
              avatar: Icon(
                tabs[i]['icon'] as IconData,
                size: 16,
                color: isSelected ? Colors.white : AppColors.navy,
              ),
              label: Text(
                tabs[i]['label'] as String,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.navy,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              onSelected: (_) => setState(() => _selectedTab = i),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMoodAnalyticsSection() {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(LucideIcons.barChart3, size: 22, color: AppColors.primary),
                    SizedBox(width: 10),
                    Text(
                      'Patient Mood Trends & Report Exporter',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Generating PDF Clinical Wellbeing Report... Exported to Downloads!')),
                    );
                  },
                  icon: const Icon(LucideIcons.fileSpreadsheet, size: 14, color: Colors.white),
                  label: const Text('Export PDF / CSV', style: TextStyle(fontSize: 12, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.lavenderBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Weekly Affect Overview', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
                      Text('Oct 04 - Oct 10, 2026', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBar('Mon', 0.8, AppColors.riskLow),
                      _buildBar('Tue', 0.85, AppColors.riskLow),
                      _buildBar('Wed', 0.65, AppColors.riskModerate),
                      _buildBar('Thu', 0.9, AppColors.riskLow),
                      _buildBar('Fri', 0.45, AppColors.riskHigh),
                      _buildBar('Sat', 0.78, AppColors.riskLow),
                      _buildBar('Sun', 0.92, AppColors.riskLow),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String day, double val, Color color) {
    return Column(
      children: [
        Text('${(val * 100).toInt()}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 6),
        Container(
          height: 90 * val,
          width: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(day, style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildSosEmergencySection() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.riskHigh.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(LucideIcons.bellRing, size: 22, color: AppColors.riskHigh),
                SizedBox(width: 10),
                Text(
                  'Emergency SOS & Triggered Alerts Queue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _sosAlerts.length,
              separatorBuilder: (ctx, i) => const Divider(),
              itemBuilder: (ctx, i) {
                final sos = _sosAlerts[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.riskHighBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.triangleAlert, color: AppColors.riskHigh, size: 20),
                  ),
                  title: Text('${sos['id']} • ${sos['patient']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('${sos['trigger']} (${sos['time']})', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sos['status'] == 'Unresolved' ? AppColors.riskHigh : AppColors.riskModerate,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      setState(() {
                        sos['status'] = 'Resolved by Admin';
                        _auditLogs.insert(0, {
                          'event': 'SOS Alert ${sos['id']} Marked Resolved',
                          'user': 'Admin',
                          'time': 'Just now',
                          'severity': 'Info'
                        });
                      });
                    },
                    child: Text(sos['status']!, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftTrackerSection() {
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
            Row(
              children: const [
                Icon(LucideIcons.clock, size: 22, color: AppColors.primary),
                SizedBox(width: 10),
                Text(
                  'Caregiver Work Shift & Attendance Tracker',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _shiftLogs.length,
              separatorBuilder: (ctx, i) => const Divider(),
              itemBuilder: (ctx, i) {
                final shift = _shiftLogs[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primarySoft,
                    child: Icon(LucideIcons.userCheck, color: AppColors.primary, size: 18),
                  ),
                  title: Text(shift['caregiver']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('${shift['shift']} • Patients Assigned: ${shift['assignedCount']}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.riskLowBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(shift['status']!, style: const TextStyle(color: AppColors.riskLow, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationScheduleSection() {
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
            Row(
              children: const [
                Icon(LucideIcons.pill, size: 22, color: AppColors.primary),
                SizedBox(width: 10),
                Text(
                  'Medication & Care Schedule Monitor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _medications.length,
              separatorBuilder: (ctx, i) => const Divider(),
              itemBuilder: (ctx, i) {
                final med = _medications[i];
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: med['given'] as bool,
                  title: Text('${med['medicine']} - ${med['patient']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('Scheduled: ${med['time']} • Status: ${med['status']}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  onChanged: (val) {
                    setState(() {
                      med['given'] = val ?? false;
                      med['status'] = (val ?? false) ? 'Administered by Admin' : 'Pending Caregiver Check';
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiFineTuningSection() {
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
            Row(
              children: const [
                Icon(LucideIcons.brainCircuit, size: 22, color: AppColors.primary),
                SizedBox(width: 10),
                Text(
                  'PyTorch AI Model Fine-tuning & Data Annotation Panel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Re-train PyTorch CNN model weights (emotion_model.pth) with custom caregiver photos or adjust emotion classifications in real-time.',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PyTorch PyTorch re-training job dispatched! Check terminal task output.')),
                    );
                  },
                  icon: const Icon(LucideIcons.refreshCw, size: 14, color: Colors.white),
                  label: const Text('Re-Train PyTorch Model Now', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dataset Annotation Tool opened.')),
                    );
                  },
                  icon: const Icon(LucideIcons.image, size: 14, color: AppColors.primary),
                  label: const Text('Annotate Training Photos', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
