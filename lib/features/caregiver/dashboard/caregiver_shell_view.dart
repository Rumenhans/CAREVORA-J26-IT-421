import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';
import '../../../components/brand/carevora_logo.dart';
import '../login/caregiver_login_view.dart';

/// Full Carevora Portal Shell with interactive tabs matching localhost:3000
/// (Overview, Residents, Cognitive Assessment, Emotional, Metabolic, Alerts, Reports, Care Plans, Settings)
class CaregiverShellView extends StatefulWidget {
  const CaregiverShellView({super.key});

  @override
  State<CaregiverShellView> createState() => _CaregiverShellViewState();
}

class _CaregiverShellViewState extends State<CaregiverShellView> {
  int _activeNavIndex = 0;

  // Question state for Cognitive Session tab
  int _currentQuestionIdx = 0;
  final Set<int> _completedQuestionIds = {1};
  bool _isListening = false;
  String _voiceTranscript = '';

  final List<String> _questions = const [
    "What is today's date, including the day of the week, month, and year?",
    "Can you tell me where we are right now, including the building and the city?",
    "I am going to name three objects: Apple, Table, and Penny. Please repeat them back to me.",
    "Could you spell the word 'WORLD' backwards for me?",
    "What were the three objects I asked you to remember a few moments ago?",
    "What do you call this object: a wristwatch? And what is this: a pencil?",
  ];

  final List<_NavItem> _navItems = const [
    _NavItem('Overview', Icons.dashboard_rounded, null),
    _NavItem('Residents', Icons.people_alt_rounded, null),
    _NavItem('Cognitive Assessment', Icons.psychology_rounded, null),
    _NavItem('Emotional Wellness', Icons.favorite_rounded, null),
    _NavItem('Metabolic Health', Icons.monitor_heart_rounded, null),
    _NavItem('Alerts & Notifications', Icons.notifications_rounded, '3'),
    _NavItem('Reports & Analytics', Icons.bar_chart_rounded, null),
    _NavItem('Care Plans', Icons.assignment_rounded, '3'),
    _NavItem('Settings', Icons.settings_rounded, null),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FB),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Exact 260px Fixed Desktop Sidebar
          if (isDesktop) _buildSidebar(),

          // 2. Main Tab View Content Area
          Expanded(
            child: Column(
              children: [
                _buildTopNavbar(isDesktop),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1540),
                        child: _buildCurrentTabContent(isDesktop),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop ? null : _buildMobileBottomBar(),
    );
  }

  Widget _buildCurrentTabContent(bool isDesktop) {
    switch (_activeNavIndex) {
      case 0:
        return _buildOverviewTab(isDesktop);
      case 1:
        return _buildResidentsTab(isDesktop);
      case 2:
        return _buildCognitiveSessionTab(isDesktop);
      case 3:
        return _buildEmotionalWellnessTab();
      case 4:
        return _buildMetabolicHealthTab(isDesktop);
      case 5:
        return _buildAlertsTab();
      case 6:
        return _buildReportsTab(isDesktop);
      case 7:
        return _buildCarePlansTab(isDesktop);
      case 8:
        return _buildSettingsTab();
      default:
        return _buildOverviewTab(isDesktop);
    }
  }

  // ================= 1. SIDEBAR (260px) =================
  Widget _buildSidebar() {
    return Container(
      width: 260,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFECE8F7), width: 1)),
      ),
      child: Column(
        children: [
          // Brand Logo Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Row(
              children: [
                const CarevoraLogo(size: 38, showWordmark: false),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CAREVORA',
                      style: AppTypography.brandWordmark.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.2,
                        color: const Color(0xFF1A1445),
                      ),
                    ),
                    const Text(
                      'Compassionate Care, Smarter Tomorrow',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6C3FC5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFECE8F7)),

          // Navigation Links
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isActive = index == _activeNavIndex;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: InkWell(
                    onTap: () => setState(() => _activeNavIndex = index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFFEDE9FE) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 18,
                            color: isActive ? const Color(0xFF6C3FC5) : const Color(0xFF8E8CA3),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                color: isActive ? const Color(0xFF6C3FC5) : const Color(0xFF5B5A6E),
                              ),
                            ),
                          ),
                          if (item.badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isActive ? const Color(0xFF6C3FC5) : const Color(0xFFFDE8E8),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                item.badge!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isActive ? Colors.white : const Color(0xFFEF4444),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Caregiver Profile & Logout
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFECE8F7))),
              color: Color(0xFFFAF8FF),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFECE8F7)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF6C3FC5), Color(0xFFE88BC4)],
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'SN',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CAREGIVER',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF8E8CA3),
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Seetha N.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1445),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF8E8CA3)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const CaregiverLoginView()),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, size: 15, color: Color(0xFFEF4444)),
                        SizedBox(width: 6),
                        Text(
                          'Log Out',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= 2. TOP NAVBAR =================
  Widget _buildTopNavbar(bool isDesktop) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFECE8F7))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome back, Seetha! 👋',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1445),
                ),
              ),
              SizedBox(height: 2),
              Text(
                "Here's the overall wellness overview of your residents.",
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF5B5A6E),
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Live Date Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF8FF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE9E1FF)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF6C3FC5)),
                    SizedBox(width: 7),
                    Text(
                      '12 May 2025, 10:45 AM',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5B2FB0),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Notification Bell
              InkWell(
                onTap: () => setState(() => _activeNavIndex = 5),
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFECE8F7)),
                      ),
                      child: const Icon(Icons.notifications_none_rounded, size: 20, color: Color(0xFF5B5A6E)),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '3',
                          style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= TAB 0: OVERVIEW =================
  Widget _buildOverviewTab(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResidentHeaderCard(),
        const SizedBox(height: 20),
        _buildScoreCardsGrid(isDesktop),
        const SizedBox(height: 24),
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: _buildRiskTrendChartCard()),
              const SizedBox(width: 20),
              Expanded(flex: 3, child: _buildComponentDonutCard()),
              const SizedBox(width: 20),
              Expanded(flex: 3, child: _buildAlertsCard()),
            ],
          )
        else ...[
          _buildRiskTrendChartCard(),
          const SizedBox(height: 20),
          _buildComponentDonutCard(),
          const SizedBox(height: 20),
          _buildAlertsCard(),
        ],
        const SizedBox(height: 24),
        _buildRecentAssessmentsCard(),
      ],
    );
  }

  // ================= TAB 1: RESIDENTS =================
  Widget _buildResidentsTab(bool isDesktop) {
    final List<Map<String, dynamic>> residents = [
      {'name': 'Mr. James Perera', 'id': '9001', 'room': '105', 'age': '78', 'risk': 'Moderate', 'color': const Color(0xFFF59E0B)},
      {'name': 'Mrs. Margaret Silva', 'id': '9002', 'room': '108', 'age': '82', 'risk': 'High', 'color': const Color(0xFFEF4444)},
      {'name': 'Mr. Arthur Fernando', 'id': '9003', 'room': '204', 'age': '75', 'risk': 'Low', 'color': const Color(0xFF22C55E)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Residents Directory', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1445))),
        const SizedBox(height: 4),
        const Text('Active resident profiles and multimodal wellness monitoring', style: TextStyle(fontSize: 13, color: Color(0xFF5B5A6E))),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: residents.map((r) {
            final name = r['name'] as String;
            final id = r['id'] as String;
            final room = r['room'] as String;
            final risk = r['risk'] as String;
            final color = r['color'] as Color;

            return Container(
              width: isDesktop ? 360 : double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFECE8F7)),
                boxShadow: const [BoxShadow(color: Color.fromRGBO(108, 63, 197, 0.05), blurRadius: 18)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(colors: [Color(0xFF6C3FC5), Color(0xFF5B2FB0)]),
                            ),
                            child: Center(
                              child: Text(
                                name.split(' ').map((n) => n[0]).take(2).join(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1445))),
                              Text('ID: $id • Room $room', style: const TextStyle(fontSize: 11, color: Color(0xFF8E8CA3))),
                            ],
                          ),
                        ],
                      ),
                      _buildRiskBadge(risk, color),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() => _activeNavIndex = 2),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C3FC5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(double.infinity, 38),
                    ),
                    child: const Text('Start Cognitive Assessment →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ================= TAB 2: COGNITIVE LIVE SESSION =================
  Widget _buildCognitiveSessionTab(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () => setState(() => _activeNavIndex = 0),
              child: const Row(
                children: [
                  Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF6C3FC5)),
                  SizedBox(width: 6),
                  Text('Back to overview', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6C3FC5))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0xFFECE8F7))),
              child: const Text('Session Started: 2m 45s', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1445))),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Live Question Box
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFECE8F7)),
            boxShadow: const [BoxShadow(color: Color.fromRGBO(108, 63, 197, 0.08), blurRadius: 24)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cognitive Assessment in Progress', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1445))),
                  Text('Question ${_currentQuestionIdx + 1} of 20 (15%)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF6C3FC5))),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (_currentQuestionIdx + 1) / 20,
                backgroundColor: const Color(0xFFFAF8FF),
                color: const Color(0xFF6C3FC5),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 24),

              // Large Lavender Question Panel
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF8FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE9E1FF), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE4DEF5))),
                          child: const Text('Orientation', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6C3FC5))),
                        ),
                        IconButton(
                          icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF6C3FC5)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Reading question aloud via Web Speech synthesis...')),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _questions[_currentQuestionIdx % _questions.length],
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1445), height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFECE8F7))),
                      child: const Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFF6C3FC5)),
                          SizedBox(width: 8),
                          Text('AI Guidance: "Please take your time and answer clearly."', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF5B5A6E))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Response Panel with Voice Waveform
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFECE8F7)),
                ),
                child: Column(
                  children: [
                    Text(_isListening ? 'Listening to response...' : 'Tap mic to record response', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1445))),
                    const SizedBox(height: 12),
                    // Waveform simulation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        14,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 4,
                          height: _isListening ? 10 + (index % 5) * 6 : 8,
                          decoration: BoxDecoration(
                            color: _isListening ? const Color(0xFF22C55E) : const Color(0xFF8E8CA3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _voiceTranscript.isEmpty ? '“Patient: Today is Monday, October 9th...”' : _voiceTranscript,
                      style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Color(0xFF5B5A6E)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isListening = !_isListening;
                              if (_isListening) {
                                _voiceTranscript = '“October 9th, 2026. Care home room 105.”';
                              }
                            });
                          },
                          icon: Icon(_isListening ? Icons.mic_off_rounded : Icons.mic_rounded),
                          label: Text(_isListening ? 'Stop Mic' : 'Start Mic'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isListening ? const Color(0xFFEF4444) : const Color(0xFF6C3FC5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                        const SizedBox(width: 14),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _completedQuestionIds.add(_currentQuestionIdx + 1);
                              _currentQuestionIdx = (_currentQuestionIdx + 1) % _questions.length;
                              _isListening = false;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: const Text('Next Question →', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF6C3FC5))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= TAB 3: EMOTIONAL WELLNESS =================
  Widget _buildEmotionalWellnessTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Emotional Wellness & Affect Analysis', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1445))),
        const SizedBox(height: 4),
        const Text('AI facial affect recognition & vocal acoustic valence tracking', style: TextStyle(fontSize: 13, color: Color(0xFF5B5A6E))),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFECE8F7))),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Emotional Index: 0.78 (Serene)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1445))),
                  _buildRiskBadge('High Attention', const Color(0xFFEF4444)),
                ],
              ),
              const SizedBox(height: 16),
              const Text('FER-2013 Affect Analysis highlights calm facial composure with positive social responsiveness during speech assessment.', style: TextStyle(fontSize: 13, color: Color(0xFF5B5A6E))),
            ],
          ),
        ),
      ],
    );
  }

  // ================= TAB 4: METABOLIC HEALTH =================
  Widget _buildMetabolicHealthTab(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Metabolic Health & Vitals', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1445))),
        const SizedBox(height: 4),
        const Text('Physiological telemetry and cardiovascular vital records', style: TextStyle(fontSize: 13, color: Color(0xFF5B5A6E))),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildVitalCard('Blood Pressure', '128/82 mmHg', 'Normal', const Color(0xFF22C55E)),
            _buildVitalCard('Fasting Glucose', '108 mg/dL', 'Optimal', const Color(0xFF22C55E)),
            _buildVitalCard('Resting Heart Rate', '72 bpm', 'Steady', const Color(0xFF6C3FC5)),
            _buildVitalCard('Body Temperature', '98.4 °F', 'Normal', const Color(0xFF22C55E)),
          ],
        ),
      ],
    );
  }

  Widget _buildVitalCard(String label, String value, String status, Color color) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFECE8F7))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF8E8CA3))),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1445))),
          const SizedBox(height: 4),
          Text('● $status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  // ================= TAB 5: ALERTS =================
  Widget _buildAlertsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Alerts & Clinical Notifications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1445))),
        const SizedBox(height: 4),
        const Text('Real-time AI notifications and flagged observations', style: TextStyle(fontSize: 13, color: Color(0xFF5B5A6E))),
        const SizedBox(height: 24),
        _buildAlertsCard(),
      ],
    );
  }

  // ================= TAB 6: REPORTS =================
  Widget _buildReportsTab(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reports & Analytics', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1445))),
        const SizedBox(height: 4),
        const Text('Longitudinal clinical charts and printable records', style: TextStyle(fontSize: 13, color: Color(0xFF5B5A6E))),
        const SizedBox(height: 24),
        _buildRiskTrendChartCard(),
        const SizedBox(height: 20),
        _buildComponentDonutCard(),
      ],
    );
  }

  // ================= TAB 7: CARE PLANS =================
  Widget _buildCarePlansTab(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Individualized Care Plans', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1445))),
        const SizedBox(height: 4),
        const Text('Tailored clinical routines and caregiver schedules', style: TextStyle(fontSize: 13, color: Color(0xFF5B5A6E))),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFECE8F7))),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Daily Cognitive Stimulation & Reminiscence Therapy', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1445))),
              SizedBox(height: 4),
              Text('Assigned Caregiver: Seetha N. • Schedule: Twice Daily', style: TextStyle(fontSize: 12, color: Color(0xFF6C3FC5))),
              SizedBox(height: 12),
              Text('• 15-minute photo album orientation\n• Category animal naming fluency drill\n• Guided memory recall journal check', style: TextStyle(fontSize: 13, color: Color(0xFF5B5A6E), height: 1.6)),
            ],
          ),
        ),
      ],
    );
  }

  // ================= TAB 8: SETTINGS =================
  Widget _buildSettingsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Caregiver Settings & Preferences', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1445))),
        const SizedBox(height: 4),
        const Text('Accessibility parameters and clinical telemetry preferences', style: TextStyle(fontSize: 13, color: Color(0xFF5B5A6E))),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFECE8F7))),
          child: Column(
            children: [
              SwitchListTile(
                value: true,
                onChanged: (val) {},
                title: const Text('Enhanced Font Scaling (Elderly Comfort)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1445))),
                subtitle: const Text('Optimizes touch targets and contrast for care homes', style: TextStyle(fontSize: 12, color: Color(0xFF5B5A6E))),
                activeColor: const Color(0xFF6C3FC5),
              ),
              const Divider(color: Color(0xFFECE8F7)),
              SwitchListTile(
                value: true,
                onChanged: (val) {},
                title: const Text('Automatic Question Read-Aloud (TTS)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1445))),
                subtitle: const Text('Reads assessment queries aloud using speech synthesis', style: TextStyle(fontSize: 12, color: Color(0xFF5B5A6E))),
                activeColor: const Color(0xFF6C3FC5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= REUSABLE OVERVIEW WIDGETS =================
  Widget _buildResidentHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECE8F7)),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(108, 63, 197, 0.06), blurRadius: 20, offset: Offset(0, 6))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(colors: [Color(0xFF6C3FC5), Color(0xFF5B2FB0)]),
                ),
                child: const Center(
                  child: Text('JP', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Mr. James Perera', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF1A1445))),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFFAF8FF), borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0xFFE9E1FF))),
                        child: const Text('ID: 9001', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6C3FC5))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Age: 78 • Male • Room No: 105', style: TextStyle(fontSize: 12.5, color: Color(0xFF5B5A6E), fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => setState(() => _activeNavIndex = 1),
                    child: const Text('View Profile →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6C3FC5))),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('LAST ASSESSMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF8E8CA3), letterSpacing: 0.5)),
              const SizedBox(height: 2),
              const Text('12 May 2025, 10:30 AM', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1A1445))),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => setState(() => _activeNavIndex = 2),
                icon: const Icon(Icons.description_outlined, size: 16),
                label: const Text('View Detailed Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFAF8FF),
                  foregroundColor: const Color(0xFF6C3FC5),
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFFE4DEF5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCardsGrid(bool isDesktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = isDesktop ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStandardScoreCard('Cognitive Health', 0.64, 0.08, 'Moderate', const Color(0xFFF59E0B), cardWidth, 2),
            _buildStandardScoreCard('Emotional Wellness', 0.78, 0.12, 'High', const Color(0xFFEF4444), cardWidth, 3),
            _buildStandardScoreCard('Metabolic Health', 0.56, 0.04, 'Moderate', const Color(0xFFF59E0B), cardWidth, 4),
            _buildGaugeScoreCard('Overall Wellness Index', 0.62, 0.06, cardWidth),
          ],
        );
      },
    );
  }

  Widget _buildStandardScoreCard(String title, double score, double delta, String riskLabel, Color riskColor, double width, int targetNav) {
    return InkWell(
      onTap: () => setState(() => _activeNavIndex = targetNav),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFECE8F7)),
          boxShadow: const [BoxShadow(color: Color.fromRGBO(108, 63, 197, 0.05), blurRadius: 18, offset: Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF5B5A6E))),
                _buildRiskBadge(riskLabel, riskColor),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(score.toStringAsFixed(2), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFF1A1445))),
                const SizedBox(width: 4),
                const Text('/ 1.00', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8E8CA3))),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF4F0FF)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('vs. last month', style: TextStyle(fontSize: 11, color: Color(0xFF8E8CA3))),
                Row(
                  children: [
                    const Icon(Icons.arrow_upward_rounded, size: 14, color: Color(0xFFEF4444)),
                    Text(delta.toStringAsFixed(2), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFEF4444))),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGaugeScoreCard(String title, double score, double delta, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECE8F7)),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(108, 63, 197, 0.05), blurRadius: 18, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF5B5A6E))),
              _buildRiskBadge('Moderate', const Color(0xFFF59E0B)),
            ],
          ),
          const SizedBox(height: 6),
          Center(
            child: CustomPaint(
              size: const Size(120, 68),
              painter: _SemicircleGaugePainter(score),
              child: SizedBox(
                width: 120,
                height: 68,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    score.toStringAsFixed(2),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A1445)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF4F0FF)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Out of 1.00', style: TextStyle(fontSize: 11, color: Color(0xFF8E8CA3))),
              Row(
                children: [
                  const Icon(Icons.arrow_upward_rounded, size: 14, color: Color(0xFF22C55E)),
                  Text(delta.toStringAsFixed(2), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF22C55E))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _buildRiskTrendChartCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECE8F7)),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(108, 63, 197, 0.05), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Overall Risk Trend', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1445))),
                  SizedBox(height: 2),
                  Text('Temporal fluctuation across clinical assessments', style: TextStyle(fontSize: 11, color: Color(0xFF8E8CA3))),
                ],
              ),
              InkWell(
                onTap: () => setState(() => _activeNavIndex = 6),
                child: const Text('View Full Trend →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6C3FC5))),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(height: 180, width: double.infinity, child: CustomPaint(painter: _RiskTrendPainter())),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF4F0FF)),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(Color(0xFF22C55E), 'Low (< 0.40)'),
              SizedBox(width: 18),
              _LegendDot(Color(0xFFF59E0B), 'Moderate (0.40 - 0.69)'),
              SizedBox(width: 18),
              _LegendDot(Color(0xFFEF4444), 'High (≥ 0.70)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComponentDonutCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECE8F7)),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(108, 63, 197, 0.05), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Component Contribution to Overall Risk', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1445))),
          const SizedBox(height: 2),
          const Text('Proportional weight breakdown', style: TextStyle(fontSize: 11, color: Color(0xFF8E8CA3))),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(size: const Size(150, 150), painter: _DonutChartPainter()),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: const Color(0xFFFAF8FF), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE9E1FF))),
                    child: const Icon(Icons.psychology_rounded, size: 24, color: Color(0xFF6C3FC5)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF4F0FF)),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ComponentRatio('Cognitive', '40%', Color(0xFF6C3FC5)),
              _ComponentRatio('Emotional', '35%', Color(0xFFEF4444)),
              _ComponentRatio('Metabolic', '25%', Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECE8F7)),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(108, 63, 197, 0.05), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Alerts & Notifications', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1445))),
              InkWell(
                onTap: () => setState(() => _activeNavIndex = 5),
                child: const Text('View All →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6C3FC5))),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text('Automated AI risk detections', style: TextStyle(fontSize: 11, color: Color(0xFF8E8CA3))),
          const SizedBox(height: 18),
          _buildAlertItem('Elevated Emotional Distress Detected', 'Affect scoring indicates acute withdrawal during morning session.', '10 mins ago', const Color(0xFFFDE8E8), const Color(0xFFEF4444), Icons.error_outline_rounded),
          const SizedBox(height: 10),
          _buildAlertItem('Cognitive Memory Recall Inconsistency', 'Delayed verbal recall for 3-item delayed retrieval task.', '2 hours ago', const Color(0xFFFEF3DC), const Color(0xFFF59E0B), Icons.warning_amber_rounded),
          const SizedBox(height: 10),
          _buildAlertItem('Metabolic Vitals Due for Entry', 'Evening BP and blood glucose logging requested.', 'Yesterday', const Color(0xFFFAF8FF), const Color(0xFF6C3FC5), Icons.schedule_rounded),
        ],
      ),
    );
  }

  Widget _buildAlertItem(String title, String desc, String time, Color bg, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg.withOpacity(0.4), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1445)), overflow: TextOverflow.ellipsis)),
                    Text(time, style: const TextStyle(fontSize: 10, color: Color(0xFF8E8CA3))),
                  ],
                ),
                const SizedBox(height: 3),
                Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF5B5A6E)), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAssessmentsCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECE8F7)),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(108, 63, 197, 0.05), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recent Assessments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1445))),
                  SizedBox(height: 2),
                  Text('Historical multimodal risk scores for Mr. James Perera', style: TextStyle(fontSize: 12, color: Color(0xFF8E8CA3))),
                ],
              ),
              InkWell(
                onTap: () => setState(() => _activeNavIndex = 2),
                child: const Text('View All Assessments →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6C3FC5))),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFECE8F7)))),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Date & Time', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF8E8CA3)))),
                Expanded(flex: 2, child: Text('Cognitive', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF8E8CA3)))),
                Expanded(flex: 2, child: Text('Emotional', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF8E8CA3)))),
                Expanded(flex: 2, child: Text('Metabolic', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF8E8CA3)))),
                Expanded(flex: 2, child: Text('Overall Risk', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF8E8CA3)))),
                Expanded(flex: 2, child: Text('Assessed By', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF8E8CA3)))),
                Expanded(flex: 1, child: Text('Action', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF8E8CA3)))),
              ],
            ),
          ),
          _buildAssessmentRow('12 May 2025, 10:30 AM', 0.64, 0.78, 0.56, 0.66, 'Seetha N.'),
          _buildAssessmentRow('02 May 2025, 02:15 PM', 0.52, 0.61, 0.53, 0.55, 'Seetha N.'),
          _buildAssessmentRow('26 Apr 2025, 09:45 AM', 0.45, 0.50, 0.46, 0.47, 'Kamal P.'),
        ],
      ),
    );
  }

  Widget _buildAssessmentRow(String date, double cog, double emo, double met, double risk, String assessor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF4F0FF)))),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(date, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF1A1445)))),
          Expanded(flex: 2, child: Text(cog.toStringAsFixed(2), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1A1445)))),
          Expanded(flex: 2, child: Text(emo.toStringAsFixed(2), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1A1445)))),
          Expanded(flex: 2, child: Text(met.toStringAsFixed(2), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1A1445)))),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(risk.toStringAsFixed(2), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF1A1445))),
                const SizedBox(width: 6),
                _buildRiskBadge('Moderate', const Color(0xFFF59E0B)),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(assessor, style: const TextStyle(fontSize: 12, color: Color(0xFF5B5A6E), fontWeight: FontWeight.w500))),
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: () => setState(() => _activeNavIndex = 2),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE4DEF5)),
                backgroundColor: const Color(0xFFFAF8FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              child: const Text('Details', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6C3FC5))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBottomBar() {
    return BottomNavigationBar(
      currentIndex: _activeNavIndex.clamp(0, 4),
      onTap: (index) => setState(() => _activeNavIndex = index),
      selectedItemColor: const Color(0xFF6C3FC5),
      unselectedItemColor: const Color(0xFF8E8CA3),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Overview'),
        BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Residents'),
        BottomNavigationBarItem(icon: Icon(Icons.psychology_rounded), label: 'Assess'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications_rounded), label: 'Alerts'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
      ],
    );
  }
}

// Data Helper Classes & Painters
class _NavItem {
  final String title;
  final IconData icon;
  final String? badge;
  const _NavItem(this.title, this.icon, this.badge);
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF5B5A6E), fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _ComponentRatio extends StatelessWidget {
  final String label;
  final String percentage;
  final Color color;
  const _ComponentRatio(this.label, this.percentage, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF5B5A6E))),
          ],
        ),
        const SizedBox(height: 2),
        Text(percentage, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1A1445))),
      ],
    );
  }
}

class _SemicircleGaugePainter extends CustomPainter {
  final double score;
  _SemicircleGaugePainter(this.score);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    const radius = 50.0;
    const strokeWidth = 10.0;

    final bgPaint = Paint()
      ..color = const Color(0xFFF4F0FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi, math.pi, false, bgPaint);

    final valuePaint = Paint()
      ..color = const Color(0xFF6C3FC5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweep = math.pi * score.clamp(0.0, 1.0);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi, sweep, false, valuePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _RiskTrendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final gridPaint = Paint()..color = const Color(0xFFF4F0FF)..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = h * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    double getY(double val) => h - ((val - 0.3) / 0.4) * h;

    final points = [
      Offset(w * 0.1, getY(0.45)),
      Offset(w * 0.38, getY(0.50)),
      Offset(w * 0.65, getY(0.47)),
      Offset(w * 0.92, getY(0.55)),
    ];

    final linePaint = Paint()
      ..color = const Color(0xFF6C3FC5)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final cx = (p0.dx + p1.dx) / 2;
      path.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = const Color(0xFF6C3FC5);
    final dotBorder = Paint()..color = Colors.white..strokeWidth = 2.5..style = PaintingStyle.stroke;

    for (final pt in points) {
      canvas.drawCircle(pt, 5, dotPaint);
      canvas.drawCircle(pt, 5, dotBorder);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 22.0;

    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = strokeWidth;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    paint.color = const Color(0xFF6C3FC5);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * 0.40 - 0.04, false, paint);

    paint.color = const Color(0xFFEF4444);
    canvas.drawArc(rect, -math.pi / 2 + 2 * math.pi * 0.40, 2 * math.pi * 0.35 - 0.04, false, paint);

    paint.color = const Color(0xFFF59E0B);
    canvas.drawArc(rect, -math.pi / 2 + 2 * math.pi * 0.75, 2 * math.pi * 0.25 - 0.04, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
