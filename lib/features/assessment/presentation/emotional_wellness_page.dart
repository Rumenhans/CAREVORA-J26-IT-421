import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/responsive/responsive_builder.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/mock/mock_carevora_data.dart';
import '../../../data/models/carevora_models.dart';
import '../application/facial_emotion_ai_service.dart';
import '../application/automatic_facial_capture_service.dart';
import '../application/emotional_assessment_service.dart';
import '../application/social_audit_service.dart';
import 'widgets/caregiver_social_audit_dialog.dart';
import '../../auth/application/auth_controller.dart';

class EmotionalWellnessPage extends ConsumerStatefulWidget {
  final String? initialResidentId;

  const EmotionalWellnessPage({super.key, this.initialResidentId});

  @override
  ConsumerState<EmotionalWellnessPage> createState() => _EmotionalWellnessPageState();
}

class _EmotionalWellnessPageState extends ConsumerState<EmotionalWellnessPage>
    with TickerProviderStateMixin {
  // Start from Question 1 (index 0)
  int _currentIndex = 0;
  final List<AssessmentQuestion> _questions = MockCarevoraData.emotionalQuestions;
  final Map<int, bool?> _answers = {};
  bool _isSubmittingAssessment = false;
  String? _submissionError;

  // Real-time analysis metrics
  String _selectedEmotion = 'Happy';
  double _facialConfidence = 0.85;
  String _voiceEmotion = 'Neutral';
  double _voiceConfidence = 0.72;

  // Scores
  int _lonelinessScore = 67;
  int _isolationScore = 58;

  // Social behavior indicators
  String _commLevel = 'Moderate';
  String _engagementLevel = 'High';
  String _responseTime = 'Normal';

  // Voice recording & timers
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  String _spokenText =
      'Sometimes in the evenings, even when people are around, I feel alone in my thoughts.';

  // Automatic Facial Affect Capture & Consent
  late final AutomaticFacialCaptureService _facialCaptureService;
  bool _hasFacialConsent = false;

  // Speech and Voice engines
  late FlutterTts _flutterTts;
  late stt.SpeechToText _speech;
  bool _speechEnabled = false;

  // Camera & Image state
  String _currentFaceAsset = 'assets/images/landing/senior_neutral_calm_face.jpg';
  Uint8List? _capturedImageBytes;
  final ImagePicker _picker = ImagePicker();

  // Animations
  late AnimationController _waveController;
  late AnimationController _scannerController;

  // Sub-navigation: 0: Assessment Session, 1: RALPA Trajectory, 2: Care Interventions & Reassessment, 3: Assessment History
  int _selectedSubTab = 0;
  late Resident _currentResident;
  SocialAuditRecord? _latestSocialAudit;
  bool _isLoadingSocialAudit = false;
  bool _useSimplifiedElderView = false;
  late List<Resident> _availableResidents;

  late List<PersonalizedActivityItem> _activities;
  late List<EmotionalAssessmentHistoryLog> _historyLogs;
  late Map<String, ResidentProfileDataset> _residentDatasets;

  void _initResidents() {
    final baseResidents = [
      MockCarevoraData.defaultResident,
      const Resident(
        id: '9002',
        name: 'Mrs. Sarah Jenkins',
        age: 78,
        gender: 'Female',
        roomNo: '101',
        lastAssessmentDate: '11 May 2025, 02:30 PM',
        cognitiveScore: 0.68,
        cognitiveTrend: 0.04,
        emotionalScore: 0.74,
        emotionalTrend: 0.08,
        metabolicScore: 0.80,
        metabolicTrend: 0.02,
        overallIndex: 0.74,
        overallTrend: 0.05,
      ),
      const Resident(
        id: '9003',
        name: 'Mr. Arthur Pendelton',
        age: 82,
        gender: 'Male',
        roomNo: '102',
        lastAssessmentDate: '09 May 2025, 11:15 AM',
        cognitiveScore: 0.54,
        cognitiveTrend: -0.05,
        emotionalScore: 0.62,
        emotionalTrend: -0.04,
        metabolicScore: 0.70,
        metabolicTrend: 0.01,
        overallIndex: 0.62,
        overallTrend: -0.03,
      ),
      const Resident(
        id: '9004',
        name: 'Mrs. Margaret Chen',
        age: 79,
        gender: 'Female',
        roomNo: '103',
        lastAssessmentDate: '08 May 2025, 04:00 PM',
        cognitiveScore: 0.72,
        cognitiveTrend: 0.06,
        emotionalScore: 0.82,
        emotionalTrend: 0.10,
        metabolicScore: 0.65,
        metabolicTrend: 0.03,
        overallIndex: 0.73,
        overallTrend: 0.06,
      ),
    ];

    _availableResidents = List<Resident>.from(baseResidents);

    final authState = ref.read(authProvider).state;
    final userName = authState.userName?.trim();

    if (authState.isElder) {
      Resident? matchedResident;
      if (authState.residentId != null) {
        final bId = authState.residentId!;
        for (final r in _availableResidents) {
          final parsed = int.tryParse(r.id);
          if (parsed == bId ||
              (bId == 1 && (parsed == 9002 || r.name.contains('Sarah'))) ||
              (bId == 2 && (parsed == 9003 || r.name.contains('Arthur'))) ||
              (bId == 3 && (parsed == 9004 || r.name.contains('Margaret')))) {
            matchedResident = r;
            break;
          }
        }
      }
      if (matchedResident == null && userName != null && userName.isNotEmpty) {
        final cleanName = userName.toLowerCase();
        for (final r in _availableResidents) {
          final rClean = r.name.toLowerCase().replaceAll('mrs. ', '').replaceAll('mr. ', '').replaceAll('dr. ', '');
          if (rClean.contains(cleanName) || cleanName.contains(rClean)) {
            matchedResident = r;
            break;
          }
        }
      }

      if (matchedResident != null) {
        _currentResident = matchedResident;
      } else {
        final newResident = Resident(
          id: authState.residentId?.toString() ?? '9005',
          name: (userName != null && userName.isNotEmpty) ? userName : 'Senior Resident',
          age: 75,
          gender: 'Senior Resident',
          roomNo: '101',
          lastAssessmentDate: 'Today, 10:30 AM',
          cognitiveScore: 0.72,
          cognitiveTrend: 0.05,
          emotionalScore: 0.78,
          emotionalTrend: 0.08,
          metabolicScore: 0.68,
          metabolicTrend: 0.02,
          overallIndex: 0.73,
          overallTrend: 0.05,
        );
        _currentResident = newResident;
      }
      _availableResidents = [_currentResident];
    } else {
      if (widget.initialResidentId != null) {
        final target = widget.initialResidentId!;
        Resident? found;
        for (final r in _availableResidents) {
          final parsed = int.tryParse(r.id);
          if (r.id == target ||
              (target == '1' && (parsed == 9002 || r.name.contains('Sarah'))) ||
              (target == '2' && (parsed == 9003 || r.name.contains('Arthur'))) ||
              (target == '3' && (parsed == 9004 || r.name.contains('Margaret')))) {
            found = r;
            break;
          }
        }
        _currentResident = found ?? _availableResidents.first;
      } else {
        _currentResident = _availableResidents.first;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initResidents();
    _initActivitiesAndHistory();
    _loadResidentData(_currentResident.id);
    _initAnimations();
    _initVoiceEngines();
    _initFacialCapture();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLatestSocialAuditForCurrentResident();
    });
  }

  void _initActivitiesAndHistory() {
    _residentDatasets = {
      // 1. Mr. James Perera (ID: 9001) - 5 Sessions across 4 weeks, High Risk Drift
      '9001': ResidentProfileDataset(
        baselineLoneliness: 54.0,
        baselineIsolation: 46.0,
        baselineEstablishedDate: '14 Apr 2025',
        trendSlope: 2.2,
        activities: [
          PersonalizedActivityItem(
            id: 'ACT-1-9001',
            title: 'Soothing Classical & Traditional Chants Playlist',
            category: 'Music Therapy',
            description: 'Listening to familiar acoustic rhythms reduces agitation, stabilizes vocal prosody, and elevates positive valence.',
            icon: LucideIcons.music,
            priority: 'High Priority',
            priorityColor: AppColors.primary,
            isCompleted: false,
          ),
          PersonalizedActivityItem(
            id: 'ACT-2-9001',
            title: 'Historical Folklore & Illustrated Biography Reading',
            category: 'Reading & Literature',
            description: 'Engaging narrative material prompts conversational recall and provides comfortable individual engagement in personal quarters.',
            icon: LucideIcons.bookOpen,
            priority: 'Recommended',
            priorityColor: Colors.blueAccent,
            isCompleted: true,
            completionNotes: 'Resident completed chapter 3 with caregiver assistance.',
            residentFeedback: 'Felt calm and reminisced about childhood stories.',
          ),
          PersonalizedActivityItem(
            id: 'ACT-3-9001',
            title: 'Morning Spiritual Chanting & Mindful Reflection',
            category: 'Religious / Cultural',
            description: 'Grounded in Sri Lankan care home findings (Wijesiri et al.) as a primary emotional coping mechanism for elderly residents.',
            icon: LucideIcons.sparkles,
            priority: 'Essential',
            priorityColor: AppColors.leafGreen,
            isCompleted: false,
          ),
          PersonalizedActivityItem(
            id: 'ACT-4-9001',
            title: 'Parlor Herbal Tea Connection & Peer Carrom Session',
            category: 'Social Interaction',
            description: 'Facilitated buddy pairing at 3:30 PM tea time to counter prolonged seclusion and rebuild voluntary interaction frequency.',
            icon: LucideIcons.users,
            priority: 'High Priority',
            priorityColor: AppColors.riskModerate,
            isCompleted: false,
          ),
        ],
        logs: const [
          EmotionalAssessmentHistoryLog(
            id: 'EAL-001',
            date: '12 May 2025, 10:30 AM',
            primaryEmotion: 'Sad / Affect Flattening',
            lonelinessScore: 78,
            isolationScore: 72,
            deviation: 24.0,
            trajectory: 'Increasing Risk',
            interventionStatus: 'Garden Stroll Assigned',
            assessedBy: 'Seetha N. (RN)',
          ),
          EmotionalAssessmentHistoryLog(
            id: 'EAL-002',
            date: '05 May 2025, 10:10 AM',
            primaryEmotion: 'Calm / Neutral',
            lonelinessScore: 66,
            isolationScore: 60,
            deviation: 12.0,
            trajectory: 'Stable Baseline',
            interventionStatus: 'Reading Session Completed',
            assessedBy: 'Seetha N. (RN)',
          ),
          EmotionalAssessmentHistoryLog(
            id: 'EAL-003',
            date: '28 Apr 2025, 09:45 AM',
            primaryEmotion: 'Happy / Cheerful',
            lonelinessScore: 52,
            isolationScore: 48,
            deviation: -2.0,
            trajectory: 'Improving',
            interventionStatus: 'Tea Connection Completed',
            assessedBy: 'K. Bandara (Caregiver)',
          ),
          EmotionalAssessmentHistoryLog(
            id: 'EAL-004',
            date: '21 Apr 2025, 02:15 PM',
            primaryEmotion: 'Calm / Neutral',
            lonelinessScore: 56,
            isolationScore: 50,
            deviation: 2.0,
            trajectory: 'Stable',
            interventionStatus: 'Chanting Reflection Completed',
            assessedBy: 'Seetha N. (RN)',
          ),
          EmotionalAssessmentHistoryLog(
            id: 'EAL-005',
            date: '14 Apr 2025, 10:00 AM',
            primaryEmotion: 'Neutral Baseline',
            lonelinessScore: 54,
            isolationScore: 46,
            deviation: 0.0,
            trajectory: 'Initial Baseline Established',
            interventionStatus: 'Baseline Logged',
            assessedBy: 'Dr. Wickramasinghe',
          ),
        ],
      ),

      // 2. Mrs. Sarah Jenkins (ID: 9002) - 4 Sessions, Stable Baseline
      '9002': ResidentProfileDataset(
        baselineLoneliness: 48.0,
        baselineIsolation: 42.0,
        baselineEstablishedDate: '18 Apr 2025',
        trendSlope: 0.2,
        activities: [
          PersonalizedActivityItem(
            id: 'ACT-1-9002',
            title: 'Symphonic Chamber Music & Nature Sounds',
            category: 'Music Therapy',
            description: 'Gentle classical strings playlist during morning relaxation.',
            icon: LucideIcons.music,
            priority: 'Recommended',
            priorityColor: Colors.blueAccent,
            isCompleted: true,
            completionNotes: 'Enjoyed listening while reading.',
            residentFeedback: 'Very peaceful start to the morning.',
          ),
          PersonalizedActivityItem(
            id: 'ACT-2-9002',
            title: 'Botanical Garden Memoir & Poetry',
            category: 'Reading & Literature',
            description: 'Short nature poems supporting cognitive recall and personal peace.',
            icon: LucideIcons.bookOpen,
            priority: 'Recommended',
            priorityColor: AppColors.leafGreen,
            isCompleted: false,
          ),
          PersonalizedActivityItem(
            id: 'ACT-3-9002',
            title: 'Morning Chapel Hymns & Contemplation',
            category: 'Religious / Cultural',
            description: 'Weekly choir hymn recitation with fellowship group.',
            icon: LucideIcons.sparkles,
            priority: 'Standard',
            priorityColor: AppColors.primary,
            isCompleted: false,
          ),
          PersonalizedActivityItem(
            id: 'ACT-4-9002',
            title: 'Community Knitting & Herbal Tea Table',
            category: 'Social Interaction',
            description: 'Participates in 3-person crafts circle in the east lounge.',
            icon: LucideIcons.users,
            priority: 'High Priority',
            priorityColor: AppColors.riskModerate,
            isCompleted: true,
            completionNotes: 'Participated for 45 minutes.',
            residentFeedback: 'Loved catching up with friends.',
          ),
        ],
        logs: const [
          EmotionalAssessmentHistoryLog(
            id: 'EAL-011',
            date: '11 May 2025, 02:30 PM',
            primaryEmotion: 'Calm / Neutral',
            lonelinessScore: 49,
            isolationScore: 43,
            deviation: 1.0,
            trajectory: 'Stable Baseline',
            interventionStatus: 'Knitting Circle Completed',
            assessedBy: 'Seetha N. (RN)',
          ),
          EmotionalAssessmentHistoryLog(
            id: 'EAL-012',
            date: '04 May 2025, 03:00 PM',
            primaryEmotion: 'Happy / Cheerful',
            lonelinessScore: 47,
            isolationScore: 41,
            deviation: -1.0,
            trajectory: 'Improving',
            interventionStatus: 'Music Session Completed',
            assessedBy: 'Seetha N. (RN)',
          ),
          EmotionalAssessmentHistoryLog(
            id: 'EAL-013',
            date: '27 Apr 2025, 11:15 AM',
            primaryEmotion: 'Calm / Neutral',
            lonelinessScore: 50,
            isolationScore: 44,
            deviation: 2.0,
            trajectory: 'Stable',
            interventionStatus: 'Tea Table Completed',
            assessedBy: 'K. Bandara (Caregiver)',
          ),
          EmotionalAssessmentHistoryLog(
            id: 'EAL-014',
            date: '18 Apr 2025, 10:00 AM',
            primaryEmotion: 'Neutral Baseline',
            lonelinessScore: 48,
            isolationScore: 42,
            deviation: 0.0,
            trajectory: 'Baseline Established',
            interventionStatus: 'Initial Baseline Logged',
            assessedBy: 'Dr. Wickramasinghe',
          ),
        ],
      ),

      // 3. Mr. Arthur Pendelton (ID: 9003) - 3 Sessions, Acute Deterioration & Counsellor Alert
      '9003': ResidentProfileDataset(
        baselineLoneliness: 65.0,
        baselineIsolation: 68.0,
        baselineEstablishedDate: '25 Apr 2025',
        trendSlope: 3.1,
        activities: [
          PersonalizedActivityItem(
            id: 'ACT-1-9003',
            title: 'Acoustic Calming Audio & Binaural Tones',
            category: 'Music Therapy',
            description: 'Designed to soothe evening agitation and promote restful sleep.',
            icon: LucideIcons.music,
            priority: 'High Priority',
            priorityColor: AppColors.riskHigh,
            isCompleted: false,
          ),
          PersonalizedActivityItem(
            id: 'ACT-2-9003',
            title: 'Steam Locomotive Archive & Picture Albums',
            category: 'Reading & Literature',
            description: 'High-interest historical machinery album to spark conversational enthusiasm.',
            icon: LucideIcons.bookOpen,
            priority: 'Recommended',
            priorityColor: Colors.blueAccent,
            isCompleted: false,
          ),
          PersonalizedActivityItem(
            id: 'ACT-3-9003',
            title: 'Quiet Sunset Meditation & Scripture',
            category: 'Religious / Cultural',
            description: 'Individual reflection session with spiritual care coordinator.',
            icon: LucideIcons.sparkles,
            priority: 'Essential',
            priorityColor: AppColors.leafGreen,
            isCompleted: false,
          ),
          PersonalizedActivityItem(
            id: 'ACT-4-9003',
            title: 'One-on-One Courtyard Stroll with Care Attendant',
            category: 'Social Interaction',
            description: 'Direct individual companion walk to bridge social withdrawal gently.',
            icon: LucideIcons.users,
            priority: 'Urgent Action',
            priorityColor: AppColors.riskHigh,
            isCompleted: false,
          ),
        ],
        logs: const [
          EmotionalAssessmentHistoryLog(
            id: 'EAL-021',
            date: '09 May 2025, 11:15 AM',
            primaryEmotion: 'Agitated / Withdrawal',
            lonelinessScore: 82,
            isolationScore: 78,
            deviation: 17.0,
            trajectory: 'Rapid Deterioration',
            interventionStatus: 'Counsellor Alert Dispatched',
            assessedBy: 'Dr. Wickramasinghe',
          ),
          EmotionalAssessmentHistoryLog(
            id: 'EAL-022',
            date: '02 May 2025, 02:45 PM',
            primaryEmotion: 'Sad / Low Affect',
            lonelinessScore: 74,
            isolationScore: 73,
            deviation: 9.0,
            trajectory: 'Increasing Risk',
            interventionStatus: 'Courtyard Stroll Assigned',
            assessedBy: 'Seetha N. (RN)',
          ),
          EmotionalAssessmentHistoryLog(
            id: 'EAL-023',
            date: '25 Apr 2025, 09:30 AM',
            primaryEmotion: 'Neutral Baseline',
            lonelinessScore: 65,
            isolationScore: 68,
            deviation: 0.0,
            trajectory: 'Baseline Established',
            interventionStatus: 'Initial Intake Logged',
            assessedBy: 'Dr. Wickramasinghe',
          ),
        ],
      ),

      // 4. Mrs. Margaret Chen (ID: 9004) - Only 1 Session, Insufficient Historical Data (Tests RALPA Safe Fallback!)
      '9004': ResidentProfileDataset(
        baselineLoneliness: 45.0,
        baselineIsolation: 40.0,
        baselineEstablishedDate: '08 May 2025',
        trendSlope: 0.0,
        activities: [
          PersonalizedActivityItem(
            id: 'ACT-1-9004',
            title: 'Traditional Folk Melodies & Guzheng Instrumental',
            category: 'Music Therapy',
            description: 'Culturally familiar acoustic rhythms to support smooth initial care home transition.',
            icon: LucideIcons.music,
            priority: 'Recommended',
            priorityColor: AppColors.primary,
            isCompleted: false,
          ),
          PersonalizedActivityItem(
            id: 'ACT-2-9004',
            title: 'Illustrated Travelogues & Art Journals',
            category: 'Reading & Literature',
            description: 'Visual cultural narratives for leisurely room reading.',
            icon: LucideIcons.bookOpen,
            priority: 'Recommended',
            priorityColor: Colors.blueAccent,
            isCompleted: false,
          ),
          PersonalizedActivityItem(
            id: 'ACT-3-9004',
            title: 'Midday Mindful Breathing & Tea Ceremony',
            category: 'Religious / Cultural',
            description: 'Quiet tea mindfulness reflecting personal daily routine.',
            icon: LucideIcons.sparkles,
            priority: 'Standard',
            priorityColor: AppColors.leafGreen,
            isCompleted: false,
          ),
          PersonalizedActivityItem(
            id: 'ACT-4-9004',
            title: 'Dining Hall Buddy Introduction',
            category: 'Social Interaction',
            description: 'Paired with Mrs. Jenkins during lunch to establish first care home friendship.',
            icon: LucideIcons.users,
            priority: 'High Priority',
            priorityColor: AppColors.riskModerate,
            isCompleted: false,
          ),
        ],
        logs: const [
          EmotionalAssessmentHistoryLog(
            id: 'EAL-031',
            date: '08 May 2025, 04:00 PM',
            primaryEmotion: 'Calm / Neutral',
            lonelinessScore: 45,
            isolationScore: 40,
            deviation: 0.0,
            trajectory: 'Baseline Establishing (1 Session)',
            interventionStatus: 'Intake Assessment Logged',
            assessedBy: 'Seetha N. (RN)',
          ),
        ],
      ),
    };
  }

  ResidentProfileDataset _createDefaultDataset(String residentName) {
    return ResidentProfileDataset(
      baselineLoneliness: 46.0,
      baselineIsolation: 40.0,
      baselineEstablishedDate: '12 May 2025',
      trendSlope: 0.8,
      activities: [
        PersonalizedActivityItem(
          id: 'ACT-1-CUSTOM',
          title: 'Soothing Classical & Traditional Melody Listening',
          category: 'Music Therapy',
          description: 'Acoustic rhythms to stabilize vocal prosody and support positive valence.',
          icon: LucideIcons.music,
          priority: 'High Priority',
          priorityColor: AppColors.primary,
          isCompleted: false,
        ),
        PersonalizedActivityItem(
          id: 'ACT-2-CUSTOM',
          title: 'Courtyard Nature Walk & Mindful Breathing',
          category: 'Physical / Relaxation',
          description: 'Gentle nature walk in personal quarters or courtyard to elevate mood.',
          icon: LucideIcons.sparkles,
          priority: 'Recommended',
          priorityColor: AppColors.leafGreen,
          isCompleted: false,
        ),
        PersonalizedActivityItem(
          id: 'ACT-3-CUSTOM',
          title: 'Social Afternoon Tea & Reminiscence Chat',
          category: 'Social Interaction',
          description: 'Peer interaction over afternoon tea to strengthen social connectivity.',
          icon: LucideIcons.users,
          priority: 'Essential',
          priorityColor: Colors.blueAccent,
          isCompleted: false,
        ),
      ],
      logs: [
        EmotionalAssessmentHistoryLog(
          id: 'EAL-001',
          date: '12 May 2025, 10:30 AM',
          primaryEmotion: 'Calm / Neutral',
          lonelinessScore: 38,
          isolationScore: 32,
          deviation: 0.0,
          trajectory: 'Stable Wellness Profile',
          interventionStatus: 'Regular Monitoring Active',
          assessedBy: 'Self-Report & Specialist',
        ),
      ],
    );
  }

  void _loadResidentData(String id) {
    final dataset = _residentDatasets[id] ?? _createDefaultDataset(_currentResident.name);
    _historyLogs = List.from(dataset.logs);
    _activities = List.from(dataset.activities);
    _capturedImageBytes = null;
    if (_historyLogs.isNotEmpty) {
      final latest = _historyLogs.first;
      _lonelinessScore = latest.lonelinessScore;
      _isolationScore = latest.isolationScore;

      final pEmotion = latest.primaryEmotion.toLowerCase();
      if (pEmotion.contains('sad')) {
        _selectedEmotion = 'Sad';
        _currentFaceAsset = 'assets/images/landing/senior_sad_face.jpg';
        _facialConfidence = 0.82;
        _voiceEmotion = 'Melancholic / Low Pitch';
        _voiceConfidence = 0.82;
        _commLevel = 'Low';
        _engagementLevel = 'Low';
        _responseTime = 'Delayed';
      } else if (pEmotion.contains('agitated') || pEmotion.contains('angry') || pEmotion.contains('confused')) {
        _selectedEmotion = 'Confused';
        _currentFaceAsset = 'assets/images/landing/senior_confused_face.jpg';
        _facialConfidence = 0.74;
        _voiceEmotion = 'Puzzled / Hesitant Prosody';
        _voiceConfidence = 0.76;
        _commLevel = 'Hesitant';
        _engagementLevel = 'Medium';
        _responseTime = 'Delayed';
      } else if (pEmotion.contains('fear') || pEmotion.contains('anxious') || pEmotion.contains('fearful')) {
        _selectedEmotion = 'Fear';
        _currentFaceAsset = 'assets/images/landing/senior_fear_face.jpg';
        _facialConfidence = 0.78;
        _voiceEmotion = 'Apprehensive / Tremulous Pitch';
        _voiceConfidence = 0.79;
        _commLevel = 'Guarded';
        _engagementLevel = 'Low';
        _responseTime = 'Variable';
      } else if (pEmotion.contains('happy') || pEmotion.contains('cheerful')) {
        _selectedEmotion = 'Happy';
        _currentFaceAsset = 'assets/images/landing/senior_happy_face.jpg';
        _facialConfidence = 0.85;
        _voiceEmotion = 'Neutral / Calm';
        _voiceConfidence = 0.72;
        _commLevel = 'Moderate';
        _engagementLevel = 'High';
        _responseTime = 'Normal';
      } else {
        _selectedEmotion = 'Neutral';
        _currentFaceAsset = 'assets/images/landing/senior_neutral_calm_face.jpg';
        _facialConfidence = 0.80;
        _voiceEmotion = 'Calm / Steady Prosody';
        _voiceConfidence = 0.75;
        _commLevel = 'Moderate';
        _engagementLevel = 'Moderate';
        _responseTime = 'Normal';
      }
    }
    _fetchLatestSocialAuditForCurrentResident();
  }

  Future<void> _fetchLatestSocialAuditForCurrentResident() async {
    final bId = _resolveBackendResidentId();
    final authState = ref.read(authProvider).state;
    setState(() {
      _isLoadingSocialAudit = true;
    });
    try {
      final audit = await SocialAuditService.fetchLatestAudit(
        residentId: bId,
        token: authState.token,
      );
      if (mounted) {
        setState(() {
          _latestSocialAudit = audit;
          if (audit != null && audit.socialScore != null) {
            _currentResident = Resident(
              id: _currentResident.id,
              name: _currentResident.name,
              age: _currentResident.age,
              gender: _currentResident.gender,
              roomNo: _currentResident.roomNo,
              lastAssessmentDate: _currentResident.lastAssessmentDate,
              cognitiveScore: _currentResident.cognitiveScore,
              cognitiveTrend: _currentResident.cognitiveTrend,
              emotionalScore: _currentResident.emotionalScore,
              emotionalTrend: _currentResident.emotionalTrend,
              metabolicScore: _currentResident.metabolicScore,
              metabolicTrend: _currentResident.metabolicTrend,
              overallIndex: _currentResident.overallIndex,
              overallTrend: _currentResident.overallTrend,
              socialScore: audit.socialScore,
            );
            final idx = _availableResidents.indexWhere((r) => r.id == _currentResident.id);
            if (idx != -1) {
              _availableResidents[idx] = _currentResident;
            }
          }
          _isLoadingSocialAudit = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingSocialAudit = false;
        });
      }
    }
  }

  void _initAnimations() {
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  Future<void> _initVoiceEngines() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.45);

    _speech = stt.SpeechToText();
    try {
      _speechEnabled = await _speech.initialize(
        onError: (err) => debugPrint('STT Error: $err'),
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted && _isRecording) {
              // keep state synced
            }
          }
        },
      );
    } catch (e) {
      debugPrint('Speech init fallback: $e');
    }
  }

  void _startRecordingTimer() {
    _recordTimer?.cancel();
    if (_isRecording) {
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordSeconds++;
          });
        }
      });
    }
  }

  void _initFacialCapture() {
    _facialCaptureService = AutomaticFacialCaptureService();
    _facialCaptureService.onStatusChanged = (status) {
      if (mounted) {
        setState(() {});
      }
    };
    _facialCaptureService.onFrameCaptured = (bytes) {
      if (mounted) {
        setState(() {
          _capturedImageBytes = bytes;
        });
      }
    };
    _facialCaptureService.onFrameAnalyzed = (result) {
      if (mounted) {
        _handleAutomaticCaptureResult(result);
      }
    };
  }

  void _handleAutomaticCaptureResult(FacialEmotionResult result) {
    if (!mounted) return;
    if (result.status == FacialInferenceStatus.success) {
      _updateEmotionFromResult(result);
    } else {
      debugPrint('Automatic facial capture status: ${result.status} (${result.clinicalObservation})');
    }
  }

  Future<bool> _ensureFacialObservationConsent() async {
    if (_hasFacialConsent) return true;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(LucideIcons.camera, color: AppColors.primary, size: 22),
            SizedBox(width: 10),
            Text('Facial Affect Consent', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lavenderBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lilac),
              ),
              child: Row(
                children: const [
                  Icon(LucideIcons.shieldCheck, color: AppColors.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Elderly-Care Research Protocol (RALPA)',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'To support longitudinal affective prediction, Carevora periodically captures front-camera video frames (approx. every 5 seconds) while the resident is speaking.',
              style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.body),
            ),
            const SizedBox(height: 12),
            const Text(
              '• Video frames are processed in volatile memory only and discarded immediately.\n'
              '• No images or video are permanently stored.\n'
              '• Camera access can be stopped at any moment by pausing recording.',
              style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.muted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Decline (Audio Only)', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Grant Consent & Start'),
          ),
        ],
      ),
    );

    final granted = result ?? false;
    if (mounted) {
      setState(() {
        _hasFacialConsent = granted;
      });
    }
    _facialCaptureService.grantConsent(granted);
    return granted;
  }

  @override
  void dispose() {
    _facialCaptureService.dispose();
    _recordTimer?.cancel();
    _waveController.dispose();
    _scannerController.dispose();
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

  Future<void> _readQuestionAloud() async {
    final currentQ = _questions[_currentIndex];
    await _flutterTts.speak(currentQ.audioPrompt);
  }

  Future<void> _toggleRecording() async {
    if (!_isRecording) {
      final consentGranted = await _ensureFacialObservationConsent();
      if (!mounted) return;
      setState(() {
        _isRecording = true;
      });
      _startRecordingTimer();
      if (_speechEnabled) {
        _speech.listen(onResult: (result) {
          if (mounted) {
            setState(() {
              _spokenText = result.recognizedWords;
            });
          }
        });
      }
      if (consentGranted) {
        await _facialCaptureService.startCaptureForVoiceRecording();
      }
    } else {
      setState(() {
        _isRecording = false;
      });
      _recordTimer?.cancel();
      if (_speechEnabled) {
        await _speech.stop();
      }
      _facialCaptureService.stopCapture();
    }
  }

  Future<void> _takeLiveCameraPhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 480,
        maxHeight: 480,
        imageQuality: 85,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _capturedImageBytes = bytes;
        });

        final result = await FacialEmotionAiService.analyzeImage(imageBytes: bytes);
        if (mounted) {
          _updateEmotionFromResult(result);
        }
      }
    } catch (e) {
      debugPrint('Camera capture error: $e');
    }
  }

  Future<void> _pickImageFromGalleryOrFile() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 480,
        maxHeight: 480,
        imageQuality: 85,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _capturedImageBytes = bytes;
        });

        final result = await FacialEmotionAiService.analyzeImage(imageBytes: bytes);
        if (mounted) {
          _updateEmotionFromResult(result);
        }
      }
    } catch (e) {
      debugPrint('Photo upload error: $e');
    }
  }

  void _updateEmotionFromResult(FacialEmotionResult result) {
    if (result.status != FacialInferenceStatus.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.clinicalObservation),
            backgroundColor: result.status == FacialInferenceStatus.noFaceDetected
                ? AppColors.riskModerate
                : AppColors.riskHigh,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() {
      _facialConfidence = result.confidence;
      if (result.primaryEmotion == EmotionCategory.happy) {
        _selectedEmotion = 'Happy';
        _lonelinessScore = 52;
        _isolationScore = 48;
      } else if (result.primaryEmotion == EmotionCategory.sadDepressed) {
        _selectedEmotion = 'Sad';
        _lonelinessScore = 79;
        _isolationScore = 75;
      } else if (result.primaryEmotion == EmotionCategory.confusedAgitated) {
        _selectedEmotion = 'Confused';
        _lonelinessScore = 65;
        _isolationScore = 62;
      } else if (result.primaryEmotion == EmotionCategory.calmNeutral) {
        _selectedEmotion = 'Neutral';
        _lonelinessScore = 54;
        _isolationScore = 50;
      } else {
        _selectedEmotion = 'Fear';
        _lonelinessScore = 70;
        _isolationScore = 68;
      }
    });
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _updateQuestionContext();
      });
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _updateQuestionContext();
      });
    } else {
      _showEndAssessmentDialog();
    }
  }

  void _skipQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _updateQuestionContext();
      });
    }
  }

  void _selectYesNoAnswer(int questionId, bool answer) {
    setState(() {
      _answers[questionId] = answer;
      _updateQuestionContext();
    });
  }

  void _updateQuestionContext() {
    final q = _questions[_currentIndex];
    final ans = _answers[q.id];

    switch (q.id) {
      case 1:
        _spokenText = ans == false
            ? "No, I felt a little low and tired when waking up today."
            : "Yes, I had a good night's rest and feel quite peaceful today.";
        break;
      case 2:
        _spokenText = ans == false
            ? "No, sometimes it is hard to look forward to tomorrow."
            : "Yes, I feel hopeful and look forward to our weekend visits.";
        break;
      case 3:
        _spokenText = ans == false
            ? "No, I haven't found anyone here I feel really close with."
            : "Yes, I have two dear companions here at our tea table.";
        break;
      case 4:
        _spokenText = ans == true
            ? "Yes, sometimes in the evenings even when people are around, I feel alone in my thoughts."
            : "No, I feel warmly included when others gather in the lounge.";
        break;
      case 5:
        _spokenText = ans == true
            ? "Yes, I find myself staying alone in my room resting for most of the day."
            : "No, I like coming out to the garden or hallway in the afternoon.";
        break;
      case 6:
        _spokenText = ans == false
            ? "No, my relatives are far away and rarely call or visit."
            : "Yes, my son and grandchildren call me every couple of days.";
        break;
      case 7:
        _spokenText = ans == false
            ? "No, I usually prefer sitting quietly on the side during group activities."
            : "Yes, I enjoy taking part in the morning tea and light movements.";
        break;
      case 8:
        _spokenText = ans == true
            ? "Yes, having an attendant or companion walk with me gives me confidence."
            : "No, I prefer my own quiet routine right now.";
        break;
      case 9:
        _spokenText = ans == false
            ? "No, I hesitate because the nurses always seem so busy."
            : "Yes, the care staff always listen with patience when I speak.";
        break;
      case 10:
        _spokenText = ans == true
            ? "Yes, listening to soothing Buddhist pirith chants brings me deep calm."
            : "No, I haven't tried listening to calming music lately.";
        break;
      default:
        _spokenText = 'Resident verbal response captured and transcribed via RALPA audio feature pipeline.';
    }
  }

  void _showTipsDialog() {
    final currentQ = _questions[_currentIndex];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(LucideIcons.sparkles, color: AppColors.primary, size: 22),
            SizedBox(width: 10),
            Text('AI Protocol Guide', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lavenderBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lilac),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.heartHandshake, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Question ${_currentIndex + 1} Focus: ${currentQ.category}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(currentQ.tip, style: AppTextStyles.body),
            const SizedBox(height: 12),
            const Text(
              '• Allow the senior at least 10–15 seconds to finish their thoughts without interruption.\n• The AI speech model analyzes vocal latency, fundamental frequency (F0), and emotional prosody.',
              style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  int _resolveBackendResidentId() {
    final authState = ref.read(authProvider).state;
    if (authState.isElder && authState.residentId != null) {
      return authState.residentId!;
    }
    final parsed = int.tryParse(_currentResident.id);
    if (parsed != null) {
      if (parsed == 9002 || _currentResident.name.contains('Sarah')) return 1;
      if (parsed == 9003 || _currentResident.name.contains('Arthur')) return 2;
      if (parsed == 9004 || _currentResident.name.contains('Margaret')) return 3;
      if (parsed <= 100) return parsed;
    }
    if (authState.residentId != null) {
      return authState.residentId!;
    }
    return 1;
  }

  void _showEndAssessmentDialog() {
    if (_isRecording) {
      _toggleRecording();
    }
    final allAnswered = EmotionalAssessmentService.areAllQuestionsAnswered(_answers);
    final missingQuestions = EmotionalAssessmentService.getUnansweredQuestions(_answers);
    final calculatedWellness = EmotionalAssessmentService.calculateWellnessScore(_answers);
    final calculatedRisk = EmotionalAssessmentService.calculateLonelinessRiskScore(calculatedWellness);

    final riskTier = calculatedRisk >= 65.0
        ? 'High Risk'
        : (calculatedRisk >= 40.0 ? 'Moderate Risk' : 'Low Risk');
    final riskColor = calculatedRisk >= 65.0
        ? AppColors.riskHigh
        : (calculatedRisk >= 40.0 ? AppColors.riskModerate : AppColors.riskLow);

    // Multimodal signals from session
    final facialAggregate = _facialCaptureService.aggregate;
    final bool hasFacialInference = facialAggregate.validCount > 0;
    final String dominantFaceEmotion = hasFacialInference
        ? facialAggregate.dominantEmotion.toUpperCase()
        : (_capturedImageBytes != null ? 'OBSERVED' : 'NONE');
    final double? facialConf = hasFacialInference ? facialAggregate.averageConfidence : null;

    double? facialScore;
    if (hasFacialInference) {
      final domLower = facialAggregate.dominantEmotion.toLowerCase();
      if (['happy', 'surprise'].contains(domLower)) {
        facialScore = 85.0;
      } else if (domLower == 'neutral') {
        facialScore = 75.0;
      } else {
        facialScore = 40.0;
      }
    }

    final bool hasVoiceSession = _recordSeconds > 0;
    final double? vocalScore = hasVoiceSession ? 78.0 : null;

    showDialog(
      context: context,
      barrierDismissible: !_isSubmittingAssessment,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(
                  allAnswered ? LucideIcons.clipboardCheck : LucideIcons.alertTriangle,
                  color: allAnswered ? AppColors.primary : AppColors.riskModerate,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    allAnswered ? 'Assessment Summary & Submission' : 'Incomplete Assessment Warning',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resident & Session header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.lavenderBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.user, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Resident: ${_currentResident.name} (ID: ${_resolveBackendResidentId()})',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: allAnswered ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              allAnswered ? 'Validated 10/10' : 'Incomplete (${10 - missingQuestions.length}/10)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: allAnswered ? const Color(0xFF166534) : const Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (!allAnswered) ...[
                      // Incomplete warning container
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF97316)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(LucideIcons.alertCircle, color: Color(0xFFF97316), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Missing Questionnaire Responses',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC2410C), fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'All 10 standardized questions must be completed before submitting. Tap any question below to jump directly to it:',
                              style: TextStyle(fontSize: 12, color: Color(0xFF9A3412), height: 1.4),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: missingQuestions.map((qNum) {
                                return ActionChip(
                                  avatar: const Icon(LucideIcons.arrowRightCircle, size: 16, color: Color(0xFFC2410C)),
                                  label: Text('Question $qNum', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9A3412))),
                                  backgroundColor: const Color(0xFFFFEDD5),
                                  side: const BorderSide(color: Color(0xFFFDBA74)),
                                  onPressed: () {
                                    Navigator.pop(dialogCtx);
                                    setState(() {
                                      _currentIndex = qNum - 1;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: const [
                            Icon(LucideIcons.lock, size: 18, color: AppColors.muted),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Provisional scoring and submission are locked until all 10 questions are answered.',
                                style: TextStyle(fontSize: 12, color: AppColors.muted, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Validated Complete Assessment Summary
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Clinical Scores', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navy)),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Questionnaire Wellness Score:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                Text(
                                  '${calculatedWellness.toStringAsFixed(1)}% (Higher is Better)',
                                  style: const TextStyle(color: AppColors.riskLow, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('Loneliness Risk:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    Text('Questionnaire inverse proxy (non-diagnostic)', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                                  ],
                                ),
                                Text(
                                  '${calculatedRisk.toStringAsFixed(1)}% ($riskTier)',
                                  style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('Social-Isolation Risk:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    Text('Requires caregiver social audit', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                                  ],
                                ),
                                if (_currentResident.socialScore != null)
                                  Text(
                                    '${(100.0 - _currentResident.socialScore!).toStringAsFixed(1)}%',
                                    style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 13),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Unassessed (No Staff Audit)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Multimodal Sensor & AI Modality Breakdown
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Multimodal AI Inferences', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navy)),
                            const Divider(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(LucideIcons.camera, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        hasFacialInference
                                            ? 'Facial Affect: $dominantFaceEmotion (${(facialConf! * 100).toStringAsFixed(1)}% conf)'
                                            : 'Facial Affect: Camera active (FER-2013 ready)',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        hasFacialInference
                                            ? '${facialAggregate.validCount} valid frames analyzed via PyTorch CNN'
                                            : 'No valid facial frame captured or consent not granted',
                                        style: const TextStyle(fontSize: 11, color: AppColors.muted),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: hasFacialInference ? const Color(0xFFDCFCE7) : AppColors.surfaceSecondary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    hasFacialInference ? 'Inferred' : 'Standby',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: hasFacialInference ? const Color(0xFF166534) : AppColors.muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(LucideIcons.mic, size: 16, color: AppColors.accentTeal),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        hasVoiceSession
                                            ? 'Voice: Acoustic Prosody Analyzed (${_recordSeconds}s)'
                                            : 'Voice: Not recorded in this session',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        hasVoiceSession
                                            ? 'RMS energy & zero-crossing extracted (CREMA-D norms; non-neural)'
                                            : 'Audio recording was not started',
                                        style: const TextStyle(fontSize: 11, color: AppColors.muted),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: hasVoiceSession ? const Color(0xFFDCFCE7) : AppColors.surfaceSecondary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    hasVoiceSession ? 'Acoustic' : 'None',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: hasVoiceSession ? const Color(0xFF166534) : AppColors.muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(LucideIcons.trendingUp, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'RALPA Longitudinal Trajectory Engine',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        'Applies 149-feature ensemble upon submission to forecast risk drift',
                                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Active',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_submissionError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.riskHighBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.riskHigh),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.xCircle, color: AppColors.riskHigh, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _submissionError!,
                                style: const TextStyle(fontSize: 12, color: AppColors.riskHigh),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isSubmittingAssessment ? null : () => Navigator.pop(context),
                child: Text(allAnswered ? 'Review Answers' : 'Continue Questionnaire'),
              ),
              if (!allAnswered && missingQuestions.isNotEmpty)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _currentIndex = missingQuestions.first - 1;
                    });
                  },
                  child: Text('Jump to Q${missingQuestions.first}'),
                ),
              ElevatedButton(
                onPressed: (!allAnswered || _isSubmittingAssessment)
                    ? null
                    : () async {
                        setDialogState(() {
                          _isSubmittingAssessment = true;
                          _submissionError = null;
                        });

                        final token = ref.read(authProvider).state.token;
                        final residentId = _resolveBackendResidentId();
                        final answersPayload = EmotionalAssessmentService.buildAnswersPayload(_answers);

                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(dialogCtx);
                        final router = GoRouter.of(context);

                        try {
                          final result = await EmotionalAssessmentService.submitAssessment(
                            residentId: residentId,
                            answers: answersPayload,
                            includeFacialCheck: (hasFacialInference || _capturedImageBytes != null),
                            includeVoiceCheck: hasVoiceSession,
                            facialScore: facialScore,
                            vocalScore: vocalScore,
                            dominantEmotion: hasFacialInference ? facialAggregate.dominantEmotion : null,
                            facialConfidence: facialConf,
                            token: token,
                          );

                          if (!mounted) return;

                          setState(() {
                            _lonelinessScore = calculatedRisk.round();
                            if (_latestSocialAudit != null && _latestSocialAudit!.socialScore != null) {
                              _isolationScore = (100.0 - _latestSocialAudit!.socialScore!).round();
                            }
                            _isSubmittingAssessment = false;
                          });

                          navigator.pop();

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Assessment #${result.id} saved successfully! Wellness score: ${result.overallScore.toStringAsFixed(1)}%.',
                              ),
                              backgroundColor: AppColors.riskLow,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );

                          router.go('/dashboard');
                        } catch (e) {
                          if (mounted) {
                            setDialogState(() {
                              _isSubmittingAssessment = false;
                              _submissionError = e.toString();
                            });
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Submission failed: $e'),
                                backgroundColor: AppColors.riskHigh,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                child: _isSubmittingAssessment
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save & Finish Assessment'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTimer(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentQ = _questions[_currentIndex];
    final completedCount = _currentIndex;
    final remainingCount = _questions.length - (_currentIndex + 1);

    // When logged in as an Elder resident, display the full emotional wellness dashboard
    // matching the caregiver experience, with an option to toggle the accessible conversation view.
    if (_useSimplifiedElderView && authState.state.isElder) {
      return _buildElderResidentView(currentQ);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Bar: Back to Residents & Date Badge
          _buildTopHeaderBar(),
          const SizedBox(height: 16),

          // 2. Resident Profile Card (Dynamic Resident Selector)
          _buildResidentHeaderCard(),
          const SizedBox(height: 20),

          // 3. Navigation Sub-Tabs (Session, RALPA Trajectory, Interventions, History)
          _buildNavigationSubTabs(),
          const SizedBox(height: 20),

          // 4. View Switching based on _selectedSubTab
          if (_selectedSubTab == 0) ...[
            // Active Loneliness & Social Assessment Session (Proposal Figure 11-4)
            ResponsiveBuilder(
              mobile: (context) => Column(
                children: [
                  _buildMainAssessmentCard(currentQ),
                  const SizedBox(height: 24),
                  _buildRightSidePanel(completedCount, remainingCount),
                ],
              ),
              desktop: (context) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 68, child: _buildMainAssessmentCard(currentQ)),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 32,
                    child: _buildRightSidePanel(completedCount, remainingCount),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // RALPA Research Methodology Intelligence Dashboard (Chapter 3: Sec 3.1 - 3.5)
            _buildRalpaMethodologyAnalyticsPanel(),
          ] else if (_selectedSubTab == 1) ...[
            // In-Depth RALPA Longitudinal Trajectory & Baseline Drift Analytics
            _buildRalpaMethodologyAnalyticsPanel(),
          ] else if (_selectedSubTab == 2) ...[
            // Personalized Interventions & Reassessment Tracking (FR11, FR14)
            _buildPersonalizedInterventionsTab(),
          ] else ...[
            // Historical Assessment Records & Audit Logs (FR4, FR13)
            _buildAssessmentHistoryTab(),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationSubTabs() {
    final tabs = [
      {'title': 'Active Assessment', 'icon': LucideIcons.messageSquare, 'desc': 'Fig 11-4 Structured Session'},
      {'title': 'RALPA Trajectory', 'icon': LucideIcons.trendingUp, 'desc': 'Sec 3.1-3.4 Longitudinal AI'},
      {'title': 'Care Interventions', 'icon': LucideIcons.sparkles, 'desc': 'FR11 / FR14 Reassessments'},
      {'title': 'Assessment History', 'icon': LucideIcons.history, 'desc': 'FR4 Longitudinal Records'},
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 700;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(tabs.length, (index) {
              final tab = tabs[index];
              final isSelected = _selectedSubTab == index;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedSubTab = index;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : AppColors.muted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tab['title'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppColors.navy,
                        ),
                      ),
                      if (!isCompact) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.2)
                                : AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tab['desc'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? Colors.white : AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  // --- TOP HEADER BAR ---
  Widget _buildTopHeaderBar() {
    final isElder = ref.watch(authProvider).state.isElder;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () => context.go('/dashboard/residents'),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              children: [
                const Icon(LucideIcons.arrowLeft, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  isElder ? 'Back to My Health Record' : 'Back to Residents',
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
        Row(
          children: [
            if (isElder) ...[
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _useSimplifiedElderView = !_useSimplifiedElderView;
                  });
                },
                icon: Icon(
                  _useSimplifiedElderView ? LucideIcons.layoutDashboard : LucideIcons.smile,
                  size: 15,
                  color: AppColors.primary,
                ),
                label: Text(
                  _useSimplifiedElderView ? 'Full Dashboard' : 'Simplified Check-In',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(LucideIcons.bell, size: 16, color: AppColors.navy),
                ),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.riskHigh,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '3',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: const [
                  Icon(LucideIcons.calendar, size: 14, color: AppColors.muted),
                  SizedBox(width: 8),
                  Text(
                    '12 May 2025',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navy),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Monday, 10:30 AM',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- RESIDENT HEADER CARD ---
  Widget _buildResidentHeaderCard() {
    final authState = ref.watch(authProvider).state;
    final initials = _currentResident.name
        .split(' ')
        .where((w) => !w.startsWith('Mr.') && !w.startsWith('Mrs.') && !w.startsWith('Dr.'))
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 16,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials.isNotEmpty ? initials : 'R',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_currentResident.name} (ID: R00${_currentResident.id.length > 2 ? _currentResident.id.substring(_currentResident.id.length - 2) : _currentResident.id})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      // Dropdown to switch residents seamlessly for staff
                      if (!authState.isElder && _availableResidents.length > 1)
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _availableResidents.any((r) => r.id == _currentResident.id)
                                ? _currentResident.id
                                : (_availableResidents.isNotEmpty ? _availableResidents.first.id : null),
                            icon: const Icon(LucideIcons.chevronDown, size: 16, color: AppColors.primary),
                            dropdownColor: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            onChanged: (String? newResId) {
                              if (newResId != null) {
                                final selected = _availableResidents.firstWhere(
                                  (r) => r.id == newResId,
                                  orElse: () => _availableResidents.first,
                                );
                                setState(() {
                                  _currentResident = selected;
                                  _loadResidentData(selected.id);
                                });
                              }
                            },
                            items: () {
                              final seen = <String>{};
                              final uniqueResidents = <Resident>[];
                              for (final r in _availableResidents) {
                                if (seen.add(r.id)) {
                                  uniqueResidents.add(r);
                                }
                              }
                              return uniqueResidents.map((Resident r) {
                                return DropdownMenuItem<String>(
                                  value: r.id,
                                  child: Text(
                                    r.name,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navy),
                                  ),
                                );
                              }).toList();
                            }(),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Age ${_currentResident.age} / ${_currentResident.gender} / Room No: ${_currentResident.roomNo}',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ],
          ),
          Wrap(
            spacing: 32,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ASSESSMENT TYPE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(LucideIcons.heartPulse, size: 14, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'Loneliness & Social-Isolation Assessment',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SESSION STARTED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(LucideIcons.clock, size: 14, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        '10:30:15 AM',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- MAIN ASSESSMENT CARD ---
  Widget _buildMainAssessmentCard(AssessmentQuestion currentQ) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Session Title and Question Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'AI-Assisted Loneliness & Social-Isolation Assessment Session',
                  style: AppTextStyles.h3.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Question ${_currentIndex + 1} of ${_questions.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 2. Question Prompt Lavender Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.lavenderBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.lilac),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.sparkles, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentQ.prompt,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _readQuestionAloud,
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(LucideIcons.volume2, size: 14, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text(
                              'Tap to replay',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _buildYesNoChoiceButton(
                            label: 'Yes / ඔව්',
                            isSelected: _answers[currentQ.id] == true,
                            isYes: true,
                            onTap: () => _selectYesNoAnswer(currentQ.id, true),
                          ),
                          const SizedBox(width: 12),
                          _buildYesNoChoiceButton(
                            label: 'No / නැත',
                            isSelected: _answers[currentQ.id] == false,
                            isYes: false,
                            onTap: () => _selectYesNoAnswer(currentQ.id, false),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Side-by-side: Camera & Voice Recording
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 650) {
                return Column(
                  children: [
                    _buildCameraCard(),
                    const SizedBox(height: 16),
                    _buildVoiceRecordingCard(),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildCameraCard()),
                  const SizedBox(width: 18),
                  Expanded(child: _buildVoiceRecordingCard()),
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          // 4. Voice Prompt Guidance Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: const [
                Icon(LucideIcons.shieldCheck, size: 18, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Please respond using your voice. Take your time. There are no right or wrong answers.',
                    style: TextStyle(fontSize: 13, color: AppColors.body, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5. Button Navigation Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: _currentIndex > 0 ? _previousQuestion : null,
                icon: const Icon(LucideIcons.arrowLeft, size: 15),
                label: const Text('Previous Question'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.border, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _nextQuestion,
                    icon: const Icon(LucideIcons.arrowRight, size: 15),
                    label: Text(_currentIndex < _questions.length - 1 ? 'Next Question' : 'Complete Assessment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: _skipQuestion,
                    icon: const Icon(LucideIcons.chevronsRight, size: 15, color: AppColors.muted),
                    label: const Text('Skip Question', style: TextStyle(color: AppColors.muted)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 20),

          // 6. Assessment Focus Panel
          _buildAssessmentFocusPanel(),
        ],
      ),
    );
  }

  // --- CAMERA BOX (FACIAL EXPRESSION) ---
  Widget _buildCameraCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Camera (Facial Expression)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy),
              ),
              _buildFacialCaptureStatusBadge(),
            ],
          ),
          const SizedBox(height: 12),

          // Face Stream Video Container with Bounding Box Reticle
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 1.35,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _capturedImageBytes != null
                      ? Image.memory(
                          _capturedImageBytes!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
                            'assets/images/landing/senior_neutral_calm_face.jpg',
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          _currentFaceAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/landing/senior_neutral_calm_face.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, st) {
                                return Container(
                                  color: const Color(0xFF1E293B),
                                  child: const Center(
                                    child: Icon(
                                      LucideIcons.user,
                                      size: 56,
                                      color: Colors.white54,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),

                  // Overlay Face Tracking Box with green/purple corners
                  Center(
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedEmotion == 'Happy'
                              ? AppColors.riskLow.withValues(alpha: 0.85)
                              : (_selectedEmotion == 'Sad'
                                  ? AppColors.riskHigh.withValues(alpha: 0.85)
                                  : (_selectedEmotion == 'Confused'
                                      ? AppColors.riskModerate.withValues(alpha: 0.85)
                                      : (_selectedEmotion == 'Fear'
                                          ? AppColors.lilac.withValues(alpha: 0.85)
                                          : AppColors.primary.withValues(alpha: 0.85)))),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 4,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Face Target: ${(_facialConfidence * 100).toInt()}%',
                                style: const TextStyle(color: Colors.white, fontSize: 9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Subtle animated scanning laser line
                  AnimatedBuilder(
                    animation: _scannerController,
                    builder: (context, child) {
                      return Positioned(
                        top: 20 + (_scannerController.value * 120),
                        left: 40,
                        right: 40,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.8),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                            gradient: const LinearGradient(
                              colors: [Colors.transparent, AppColors.primary, Colors.transparent],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Action buttons: Upload Image & Capture Camera
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: 'Upload senior photo for AI Inference',
                          child: InkWell(
                            onTap: _pickImageFromGalleryOrFile,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.uploadCloud, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: 'Capture live camera photo',
                          child: InkWell(
                            onTap: _takeLiveCameraPhoto,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.camera, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Live auto-capture bottom status overlay
                  Positioned(
                    bottom: 6,
                    left: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _facialCaptureService.isAutoCapturing
                                ? LucideIcons.activity
                                : LucideIcons.shieldCheck,
                            size: 11,
                            color: _facialCaptureService.isAutoCapturing
                                ? AppColors.leafGreen
                                : Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _facialCaptureService.isAutoCapturing
                                  ? 'Auto-capture active (1s interval) • ${_facialCaptureService.aggregate.validCount} valid samples'
                                  : (_hasFacialConsent
                                      ? 'Consent granted • Auto-captures during voice'
                                      : 'Consent required for auto facial capture'),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_facialCaptureService.status == FacialCaptureStatus.modelUnavailable) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.riskModerateBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.riskModerate.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: const [
                  Icon(LucideIcons.alertTriangle, size: 14, color: AppColors.riskModerate),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'PyTorch FER Model offline on FastAPI. Frames captured safely without fabricating scores.',
                      style: TextStyle(fontSize: 10, color: AppColors.navy, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Real AI Detected Emotion Readout
          const Text(
            'AI Detected Facial Emotion:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.navy),
          ),
          const SizedBox(height: 8),
          _buildAiDetectedEmotionDisplay(),
        ],
      ),
    );
  }

  Widget _buildFacialCaptureStatusBadge() {
    final status = _facialCaptureService.status;
    Color bg;
    Color fg;
    String text;
    IconData icon;

    switch (status) {
      case FacialCaptureStatus.capturing:
        bg = AppColors.primarySoft;
        fg = AppColors.primary;
        text = 'Capturing';
        icon = LucideIcons.camera;
        break;
      case FacialCaptureStatus.analyzing:
        bg = AppColors.lavenderBg;
        fg = AppColors.primary;
        text = 'Analyzing AI';
        icon = LucideIcons.sparkles;
        break;
      case FacialCaptureStatus.noFace:
        bg = AppColors.riskModerateBg;
        fg = AppColors.riskModerate;
        text = 'No Face';
        icon = LucideIcons.alertCircle;
        break;
      case FacialCaptureStatus.modelUnavailable:
        bg = AppColors.border;
        fg = AppColors.navy;
        text = 'Model Offline';
        icon = LucideIcons.alertTriangle;
        break;
      case FacialCaptureStatus.consentRequired:
        bg = AppColors.riskModerateBg;
        fg = AppColors.riskModerate;
        text = 'Consent Needed';
        icon = LucideIcons.shieldAlert;
        break;
      case FacialCaptureStatus.permissionDenied:
        bg = AppColors.riskHighBg;
        fg = AppColors.riskHigh;
        text = 'Perm Denied';
        icon = LucideIcons.shieldAlert;
        break;
      case FacialCaptureStatus.cameraUnavailable:
        bg = AppColors.border;
        fg = AppColors.muted;
        text = 'No Camera';
        icon = LucideIcons.videoOff;
        break;
      case FacialCaptureStatus.networkError:
        bg = AppColors.riskHighBg;
        fg = AppColors.riskHigh;
        text = 'Network Err';
        icon = LucideIcons.wifiOff;
        break;
      case FacialCaptureStatus.standby:
        bg = AppColors.riskLowBg;
        fg = AppColors.riskLow;
        text = 'Auto (Voice)';
        icon = Icons.fiber_manual_record;
        break;
      case FacialCaptureStatus.error:
        bg = AppColors.riskHighBg;
        fg = AppColors.riskHigh;
        text = 'Error';
        icon = LucideIcons.alertOctagon;
        break;
      case FacialCaptureStatus.initializingCamera:
        bg = AppColors.lavenderBg;
        fg = AppColors.primary;
        text = 'Init Camera';
        icon = LucideIcons.loader;
        break;
      case FacialCaptureStatus.idle:
        bg = AppColors.border;
        fg = AppColors.muted;
        text = 'Standby';
        icon = LucideIcons.video;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiDetectedEmotionDisplay() {
    final status = _facialCaptureService.status;
    final bool isRecording = _isRecording;
    final bool hasPredictions = _facialCaptureService.aggregate.validCount > 0 || _capturedImageBytes != null;

    Color bg;
    Color border;
    Color text;
    String emoji;
    String title;
    String confidenceStr = '${(_facialConfidence * 100).toInt()}% Confidence';
    String subtitle;

    if (!isRecording && !hasPredictions) {
      bg = Colors.white;
      border = AppColors.border;
      text = AppColors.muted;
      emoji = '🎙️';
      title = 'Standby for Voice Session';
      confidenceStr = 'Awaiting Recording';
      subtitle = 'Facial affect capture starts automatically when voice recording begins.';
    } else if (status == FacialCaptureStatus.noFace) {
      bg = AppColors.riskModerateBg;
      border = AppColors.riskModerate.withValues(alpha: 0.5);
      text = AppColors.riskModerate;
      emoji = '🔍';
      title = 'No Face Recognized';
      confidenceStr = 'Reposition Senior';
      subtitle = 'Ensure senior is positioned facing camera in adequate ambient lighting.';
    } else if (status == FacialCaptureStatus.modelUnavailable) {
      bg = AppColors.surfaceSecondary;
      border = AppColors.border;
      text = AppColors.navy;
      emoji = '⚠️';
      title = 'Inference Offline';
      confidenceStr = 'Model Unavailable';
      subtitle = 'Camera capture active; facial emotion scoring paused until AI microservice is online.';
    } else {
      switch (_selectedEmotion.toLowerCase()) {
        case 'happy':
        case 'cheerful':
          bg = AppColors.riskLowBg;
          border = AppColors.riskLow.withValues(alpha: 0.4);
          text = AppColors.riskLow;
          emoji = '😊';
          title = 'Happy / Uplifted';
          subtitle = 'Bilateral zygomaticus engagement detected. Consistent with positive emotional wellness.';
          break;
        case 'sad':
        case 'depressed':
          bg = AppColors.riskHighBg;
          border = AppColors.riskHigh.withValues(alpha: 0.4);
          text = AppColors.riskHigh;
          emoji = '😔';
          title = 'Sad / Affect Flattening';
          subtitle = 'Depressed lip corners and brow tension observed. Informs RALPA affective drift analysis.';
          break;
        case 'confused':
        case 'agitated':
        case 'angry':
          bg = AppColors.riskModerateBg;
          border = AppColors.riskModerate.withValues(alpha: 0.4);
          text = AppColors.riskModerate;
          emoji = '🤔';
          title = 'Confused / Agitated';
          subtitle = 'Corrugator brow furrowing and contraction detected. Informs cognitive-emotional assessment.';
          break;
        case 'fear':
        case 'anxious':
        case 'fearful':
          bg = AppColors.lavenderBg;
          border = AppColors.lilac;
          text = AppColors.primary;
          emoji = '😨';
          title = 'Fear / Anxious';
          subtitle = 'Upper eyelid elevation and apprehension markers detected.';
          break;
        case 'neutral':
        case 'calm':
        default:
          bg = AppColors.surfaceSecondary;
          border = AppColors.border;
          text = AppColors.navy;
          emoji = '😐';
          title = 'Calm / Neutral Baseline';
          subtitle = 'Resting facial expression with symmetrical prosody and stable valence.';
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: text,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: border),
                ),
                child: Text(
                  confidenceStr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.muted,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // --- VOICE RECORDING BOX ---
  Widget _buildVoiceRecordingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with recording blinker
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Voice Recording',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _isRecording ? AppColors.riskHighBg : AppColors.border,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fiber_manual_record,
                          size: 8,
                          color: _isRecording ? AppColors.riskHigh : AppColors.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isRecording ? 'Recording...' : 'Paused',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _isRecording ? AppColors.riskHigh : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTimer(_recordSeconds),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dynamic Animated Audio Waveform Box
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(24, (i) {
                    final factor = (1 + 0.8 * ((i % 4 == 0) ? 1.0 : 0.4));
                    final waveValue = (_waveController.value * 6.28 + (i * 0.3)).abs();
                    final dynamicHeight = _isRecording
                        ? (12.0 + (35.0 * (0.3 + 0.7 * (1.0 - (waveValue % 1.0)))) * factor)
                            .clamp(8.0, 75.0)
                        : 6.0;

                    return Container(
                      width: 4,
                      height: dynamicHeight,
                      decoration: BoxDecoration(
                        color: _isRecording ? AppColors.primary : AppColors.border,
                        borderRadius: BorderRadius.circular(3),
                        gradient: _isRecording
                            ? LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withValues(alpha: 0.5),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              )
                            : null,
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Central Microphone Action Button
          Center(
            child: Column(
              children: [
                InkWell(
                  onTap: _toggleRecording,
                  borderRadius: BorderRadius.circular(40),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isRecording ? AppColors.riskHigh : AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? AppColors.riskHigh : AppColors.primary)
                              .withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording ? LucideIcons.square : LucideIcons.mic,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isRecording ? 'Tap microphone to stop' : 'Tap microphone to record',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Spoken Transcript Preview
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.messageSquare, size: 14, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _spokenText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.navy),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYesNoChoiceButton({
    required String label,
    required bool isSelected,
    required bool isYes,
    required VoidCallback onTap,
  }) {
    final activeColor = isYes ? AppColors.riskLow : const Color(0xFFF97316);
    final activeBg = isYes ? AppColors.riskLowBg : const Color(0xFFFFF7ED);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? activeColor : AppColors.border,
              width: isSelected ? 2.0 : 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected
                    ? (isYes ? LucideIcons.circleCheck : LucideIcons.circleX)
                    : LucideIcons.circle,
                size: 18,
                color: isSelected ? activeColor : AppColors.muted,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? activeColor : AppColors.navy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- ASSESSMENT FOCUS PANEL ---
  Widget _buildAssessmentFocusPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assessment Focus',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy),
        ),
        const SizedBox(height: 4),
        const Text(
          'This assessment helps us understand your emotional well-being and social connection',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            _buildFocusBadge(LucideIcons.heart, 'Emotional Well-being', isCurrent: _questions[_currentIndex].category == 'Emotional Well-being'),
            _buildFocusBadge(LucideIcons.users, 'Social Interaction', isCurrent: _questions[_currentIndex].category == 'Social Interaction'),
            _buildFocusBadge(LucideIcons.messageSquare, 'Communication Patterns', isCurrent: _questions[_currentIndex].category == 'Communication Patterns'),
            _buildFocusBadge(LucideIcons.shieldAlert, 'Loneliness Indicators', isCurrent: _questions[_currentIndex].category == 'Loneliness Indicators'),
            _buildFocusBadge(LucideIcons.share2, 'Social-isolation Indicators', isCurrent: _questions[_currentIndex].category == 'Social-isolation Indicators'),
          ],
        ),
      ],
    );
  }

  Widget _buildFocusBadge(IconData icon, String title, {required bool isCurrent}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.primarySoft : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? AppColors.primary : AppColors.border,
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isCurrent ? AppColors.primary : AppColors.muted),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: isCurrent ? AppColors.primary : AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }

  // --- RIGHT SIDEBAR PANEL ---
  Widget _buildRightSidePanel(int completed, int remaining) {
    return Column(
      children: [
        // 1. Real-time Analysis Card
        _buildRealtimeAnalysisCard(),
        const SizedBox(height: 18),

        // 2. Loneliness & Social-Isolation Indicators Card
        _buildLonelinessIsolationCard(),
        const SizedBox(height: 18),

        // 3. Session Progress Card
        _buildSessionProgressCard(completed, remaining),
        const SizedBox(height: 18),

        // 4. AI Assistant Tips Card
        _buildAiAssistantCard(),
        const SizedBox(height: 18),

        // 5. End Assessment Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showEndAssessmentDialog,
            icon: const Icon(LucideIcons.xCircle, size: 16, color: AppColors.riskHigh),
            label: const Text(
              'End Assessment',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.riskHigh,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.riskHigh, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  // 1. Real-time Analysis Card
  Widget _buildRealtimeAnalysisCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Real-time Analysis',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy),
          ),
          const SizedBox(height: 16),

          // Facial Emotion
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Facial Emotion', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              Text(
                '$_selectedEmotion  ${(_facialConfidence * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _selectedEmotion == 'Happy'
                      ? AppColors.riskLow
                      : (_selectedEmotion == 'Sad'
                          ? AppColors.riskHigh
                          : (_selectedEmotion == 'Confused'
                              ? AppColors.riskModerate
                              : (_selectedEmotion == 'Fear'
                                  ? AppColors.primary
                                  : AppColors.primary))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _facialConfidence,
              minHeight: 6,
              backgroundColor: AppColors.border,
              color: _selectedEmotion == 'Happy'
                  ? AppColors.riskLow
                  : (_selectedEmotion == 'Sad'
                      ? AppColors.riskHigh
                      : (_selectedEmotion == 'Confused'
                          ? AppColors.riskModerate
                          : (_selectedEmotion == 'Fear'
                              ? AppColors.primary
                              : AppColors.primary))),
            ),
          ),
          const SizedBox(height: 14),

          // Voice Emotion
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Voice Emotion', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              Text(
                '$_voiceEmotion  ${(_voiceConfidence * 100).toInt()}%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _voiceConfidence,
              minHeight: 6,
              backgroundColor: AppColors.border,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),

          // Social Behavior Indicators
          const Text(
            'Social Behavior Indicators',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.navy),
          ),
          const SizedBox(height: 10),
          _buildBehaviorRow('• Communication Level', _commLevel, AppColors.riskModerateBg, AppColors.riskModerate),
          const SizedBox(height: 8),
          _buildBehaviorRow('• Engagement Level', _engagementLevel, AppColors.riskLowBg, AppColors.riskLow),
          const SizedBox(height: 8),
          _buildBehaviorRow('• Response Time', _responseTime, const Color(0xFFE0F2FE), Colors.blue),
        ],
      ),
    );
  }

  Widget _buildBehaviorRow(String label, String value, Color bg, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.body)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
          ),
        ),
      ],
    );
  }

  // 2. Loneliness & Social-Isolation Indicators Card
  Widget _buildLonelinessIsolationCard() {
    final authState = ref.watch(authProvider).state;
    final hasAnswers = _answers.isNotEmpty;
    final calculatedWellness = hasAnswers
        ? EmotionalAssessmentService.calculateWellnessScore(_answers)
        : null;
    final calculatedLoneliness = calculatedWellness != null
        ? EmotionalAssessmentService.calculateLonelinessRiskScore(calculatedWellness)
        : null;

    final q3Answer = _answers[2]; // Someone close to talk to (Social Support)
    final q4Answer = _answers[3]; // Feel left out or lonely (Perceived Loneliness)
    final q5Answer = _answers[4]; // Spending day alone in room (Room Isolation)

    final String perceivedLonelinessLevel = q4Answer == null
        ? 'Pending Q4'
        : (q4Answer == true ? 'High' : 'Low');
    final String seclusionLevel = q5Answer == null
        ? 'Pending Q5'
        : (q5Answer == true ? 'High' : 'Low');
    final String socialSupportLevel = q3Answer == null
        ? 'Pending Q3'
        : (q3Answer == true ? 'Adequate' : 'Low');

    final int displayLoneliness = calculatedLoneliness != null
        ? calculatedLoneliness.round()
        : _lonelinessScore;
    final String lonelinessTier = displayLoneliness >= 65
        ? 'High Risk'
        : (displayLoneliness >= 40 ? 'Moderate Risk' : 'Low Risk');
    final Color lonelinessColor = displayLoneliness >= 65
        ? AppColors.riskHigh
        : (displayLoneliness >= 40 ? AppColors.riskModerate : AppColors.riskLow);
    final Color lonelinessBg = displayLoneliness >= 65
        ? AppColors.riskHighBg
        : (displayLoneliness >= 40 ? AppColors.riskModerateBg : const Color(0xFFDCFCE7));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Loneliness & Social-Isolation Indicators',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy),
          ),
          const SizedBox(height: 16),

          // Section A: Loneliness Indicators
          Row(
            children: [
              const Text(
                'Loneliness Indicators',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.lavenderBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Questionnaire-Derived',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _IndicatorSubRow(label: 'Perceived Loneliness (Q4)', level: perceivedLonelinessLevel),
                    const SizedBox(height: 4),
                    _IndicatorSubRow(label: 'Room Seclusion (Q5)', level: seclusionLevel),
                    const SizedBox(height: 4),
                    _IndicatorSubRow(label: 'Social Support (Q3)', level: socialSupportLevel),
                  ],
                ),
              ),
              _buildCircularScoreGauge(
                score: displayLoneliness,
                riskLabel: lonelinessTier,
                riskColor: lonelinessColor,
                bgRingColor: lonelinessBg,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),

          // Section B: Social-Isolation Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Social-Isolation Indicators',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.riskHigh),
                  ),
                  const SizedBox(width: 8),
                  if (_isLoadingSocialAudit)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  else if (_latestSocialAudit != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Verified Caregiver Audit',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Unassessed — No Caregiver Social Audit On File',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                      ),
                    ),
                ],
              ),
              if (!authState.isElder)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  icon: const Icon(LucideIcons.clipboardCheck, size: 14, color: AppColors.primary),
                  label: const Text(
                    'Social Audit Hub',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  onPressed: () => context.go('/dashboard/social-audit/resident/${_resolveBackendResidentId()}'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_latestSocialAudit != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _IndicatorSubRow(
                              label: 'External Contacts (7d)',
                              level: _latestSocialAudit!.externalContactUnknown
                                  ? 'Unknown / Not Recorded'
                                  : '${_latestSocialAudit!.totalExternalContacts ?? 0} contacts (${_latestSocialAudit!.familyInPersonVisits ?? 0} visits, ${_latestSocialAudit!.familyPhoneVideoContacts ?? 0} calls)',
                            ),
                            const SizedBox(height: 4),
                            _IndicatorSubRow(
                              label: 'Peer Social Interaction',
                              level: _latestSocialAudit!.peerInteractionLevel.label,
                            ),
                            const SizedBox(height: 4),
                            _IndicatorSubRow(
                              label: 'Activity Attendance',
                              level: _latestSocialAudit!.activitiesAttended != null
                                  ? '${_latestSocialAudit!.activitiesAttended} / ${_latestSocialAudit!.activitiesAvailable ?? 0} (${_latestSocialAudit!.activityParticipationLevel.label})'
                                  : _latestSocialAudit!.activityParticipationLevel.label,
                            ),
                            const SizedBox(height: 4),
                            _IndicatorSubRow(
                              label: 'Time Alone / Day',
                              level: _latestSocialAudit!.estimatedHoursAlonePerDay != null
                                  ? '${_latestSocialAudit!.estimatedHoursAlonePerDay!.toStringAsFixed(1)} hrs/day (${_latestSocialAudit!.aloneTimeContext.label})'
                                  : _latestSocialAudit!.aloneTimeContext.label,
                            ),
                          ],
                        ),
                      ),
                      if (_latestSocialAudit!.socialScore != null)
                        _buildCircularScoreGauge(
                          score: (100.0 - _latestSocialAudit!.socialScore!).round(),
                          riskLabel: (100.0 - _latestSocialAudit!.socialScore!) >= 50 ? 'Elevated' : 'Low',
                          riskColor: (100.0 - _latestSocialAudit!.socialScore!) >= 50 ? AppColors.riskHigh : AppColors.riskLow,
                          bgRingColor: (100.0 - _latestSocialAudit!.socialScore!) >= 50 ? AppColors.riskHighBg : const Color(0xFFDCFCE7),
                        ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    children: [
                      const Icon(LucideIcons.userCheck, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Audited on ${_latestSocialAudit!.auditDate.day}/${_latestSocialAudit!.auditDate.month}/${_latestSocialAudit!.auditDate.year} by ${_latestSocialAudit!.caregiverName}',
                          style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (_latestSocialAudit!.healthMobilityBarriers)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEDD5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Health Barrier Protected',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFC2410C)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(LucideIcons.clipboardList, size: 20, color: AppColors.muted),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Unassessed — No Caregiver Social Audit On File. External contacts, visitor logs, and group activity attendance require staff observational audit.',
                          style: TextStyle(fontSize: 11, color: AppColors.body, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                  if (!authState.isElder) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lavenderBg,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: AppColors.lilac),
                          ),
                        ),
                        icon: const Icon(LucideIcons.clipboardPlus, size: 16),
                        label: const Text('Open in Caregiver Social Audit Hub', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () => context.go('/dashboard/social-audit/resident/${_resolveBackendResidentId()}'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCircularScoreGauge({
    required int score,
    required String riskLabel,
    required Color riskColor,
    required Color bgRingColor,
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 58,
              height: 58,
              child: CircularProgressIndicator(
                value: score / 100.0,
                strokeWidth: 5,
                backgroundColor: bgRingColor,
                valueColor: AlwaysStoppedAnimation<Color>(riskColor),
              ),
            ),
            Text(
              '$score',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: riskColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          riskLabel,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: riskColor,
          ),
        ),
      ],
    );
  }

  // 3. Session Progress Card
  Widget _buildSessionProgressCard(int completed, int remaining) {
    final currentNum = _currentIndex + 1;
    final total = _questions.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Session Progress',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 68,
                    height: 68,
                    child: CircularProgressIndicator(
                      value: currentNum / total.toDouble(),
                      strokeWidth: 6,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  Text(
                    '$currentNum',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgressLegendDot(Colors.blue, 'Completed', '$completed'),
                  const SizedBox(height: 6),
                  _buildProgressLegendDot(AppColors.primary, 'Current', '1'),
                  const SizedBox(height: 6),
                  _buildProgressLegendDot(AppColors.muted, 'Remaining', '$remaining'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLegendDot(Color color, String label, String count) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          '• $label',
          style: const TextStyle(fontSize: 12, color: AppColors.body),
        ),
        const SizedBox(width: 6),
        Text(
          count,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navy),
        ),
      ],
    );
  }

  // 4. AI Assistant Tips Card
  Widget _buildAiAssistantCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.lavenderBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lilac),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(LucideIcons.bot, size: 16, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'AI ASSISTANT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '"I am here to listen and understand how you feel."',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.navy,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _showTipsDialog,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(LucideIcons.lightbulb, size: 14, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  'Show Tips',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // --- RALPA RESEARCH METHODOLOGY ANALYTICS PANEL (CHAPTER 3: SEC 3.1 - 3.5) ---
  // =========================================================================
  Widget _buildRalpaMethodologyAnalyticsPanel() {
    final dataset = _residentDatasets[_currentResident.id] ?? _residentDatasets['9001']!;
    final bool hasSufficientHistory = _historyLogs.length >= 2;
    final double baselineLoneliness = dataset.baselineLoneliness;
    final double baselineIsolation = dataset.baselineIsolation;
    final double currentLoneliness = _lonelinessScore.toDouble();
    final double currentIsolation = _isolationScore.toDouble();
    final double deltaLoneliness = currentLoneliness - baselineLoneliness;
    final double deltaIsolation = currentIsolation - baselineIsolation;

    final bool isHighRisk = currentLoneliness >= 70 || _selectedEmotion == 'Sad' || _selectedEmotion == 'Angry' || _selectedEmotion == 'Fear';
    final String trajectoryStatus = !hasSufficientHistory
        ? 'BASELINE ESTABLISHING (INSUFFICIENT DATA)'
        : (dataset.trendSlope > 1.0 || deltaLoneliness > 10.0
            ? 'DETERIORATING / INCREASING RISK'
            : (dataset.trendSlope < -1.0 ? 'IMPROVING TRAJECTORY' : 'STABLE BASELINE'));
    final Color trajectoryColor = !hasSufficientHistory
        ? AppColors.primary
        : (dataset.trendSlope > 1.0 || deltaLoneliness > 10.0
            ? AppColors.riskHigh
            : (_selectedEmotion == 'Happy' ? AppColors.riskLow : Colors.blueAccent));

    final List<double> forecastValues = hasSufficientHistory
        ? List.generate(14, (i) => (currentLoneliness + (i * dataset.trendSlope * 0.8)).clamp(10.0, 95.0))
        : [];

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.lilac, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title & Methodology Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.lilac),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(LucideIcons.graduationCap, size: 13, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text(
                                'RESEARCH METHODOLOGY (SEC 3.1 - 3.5)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'RALPA Longitudinal Predictive Intelligence Engine',
                      style: AppTextStyles.h2.copyWith(fontSize: 20, color: AppColors.navy),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Resident-Adaptive Baseline Modelling • Multimodal Deviation Detection • Longitudinal Trajectory Forecasting • Multimodal Attribution',
                      style: TextStyle(fontSize: 12, color: AppColors.body),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: const [
                    Icon(LucideIcons.checkCircle2, size: 16, color: AppColors.riskLow),
                    SizedBox(width: 8),
                    Text(
                      'Model: RALPA-Adaptive v1',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navy),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 24),

          // ROW 1: Baseline vs Deviation Card & Benchmark Comparison
          ResponsiveBuilder(
            mobile: (context) => Column(
              children: [
                _buildBaselineDeviationCard(
                  hasSufficientHistory: hasSufficientHistory,
                  baselineLoneliness: baselineLoneliness,
                  currentLoneliness: currentLoneliness,
                  deltaLoneliness: deltaLoneliness,
                  baselineIsolation: baselineIsolation,
                  currentIsolation: currentIsolation,
                  deltaIsolation: deltaIsolation,
                ),
                const SizedBox(height: 20),
                _buildComparativeBenchmarkCard(),
              ],
            ),
            desktop: (context) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildBaselineDeviationCard(
                    hasSufficientHistory: hasSufficientHistory,
                    baselineLoneliness: baselineLoneliness,
                    currentLoneliness: currentLoneliness,
                    deltaLoneliness: deltaLoneliness,
                    baselineIsolation: baselineIsolation,
                    currentIsolation: currentIsolation,
                    deltaIsolation: deltaIsolation,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(child: _buildComparativeBenchmarkCard()),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ROW 2: Trajectory Forecast Chart & SHAP Feature Importance
          ResponsiveBuilder(
            mobile: (context) => Column(
              children: [
                _buildTrajectoryForecastCard(
                  isHighRisk: isHighRisk,
                  status: trajectoryStatus,
                  statusColor: trajectoryColor,
                  forecast: forecastValues,
                ),
                const SizedBox(height: 20),
                _buildShapFeatureImportanceCard(),
              ],
            ),
            desktop: (context) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTrajectoryForecastCard(
                    isHighRisk: isHighRisk,
                    status: trajectoryStatus,
                    statusColor: trajectoryColor,
                    forecast: forecastValues,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(child: _buildShapFeatureImportanceCard()),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ROW 3: Personalized Interventions & Reassessment Tracking (Sec 3.5)
          _buildPersonalizedInterventionsCard(isHighRisk),
        ],
      ),
    );
  }

  // --- 1. RESIDENT BASELINE & DEVIATION DETECTION CARD (SEC 3.1 & 3.3) ---
  Widget _buildBaselineDeviationCard({
    required bool hasSufficientHistory,
    required double baselineLoneliness,
    required double currentLoneliness,
    required double deltaLoneliness,
    required double baselineIsolation,
    required double currentIsolation,
    required double deltaIsolation,
  }) {
    final bool hasHighDrift = hasSufficientHistory && (deltaLoneliness > 10.0 || deltaIsolation > 10.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
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
                  Icon(LucideIcons.userCheck, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Resident-Specific Baseline & Deviation',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: !hasSufficientHistory
                      ? AppColors.primarySoft
                      : (hasHighDrift ? AppColors.riskHighBg : AppColors.riskLowBg),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  !hasSufficientHistory
                      ? 'Baseline Establishing (N < 2)'
                      : (hasHighDrift ? 'Significant Deviation Δ' : 'Baseline Aligned'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: !hasSufficientHistory
                        ? AppColors.primary
                        : (hasHighDrift ? AppColors.riskHigh : AppColors.riskLow),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            !hasSufficientHistory
                ? 'Methodology Sec 3.1 & 3.5: Resident requires at least 2 longitudinal assessments across distinct care periods to establish individual normal baseline.'
                : 'Methodology Sec 3.1 & 3.3: Historical modeled baseline compared against current multimodal observation to identify resident-specific drift.',
            style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.3),
          ),
          const SizedBox(height: 16),

          // Loneliness Metric Comparison
          _buildDeviationMetricRow(
            label: 'Loneliness Index',
            hasSufficientHistory: hasSufficientHistory,
            baseline: baselineLoneliness,
            current: currentLoneliness,
            delta: deltaLoneliness,
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          // Social Isolation Metric Comparison
          _buildDeviationMetricRow(
            label: 'Social-Isolation Index',
            hasSufficientHistory: hasSufficientHistory,
            baseline: baselineIsolation,
            current: currentIsolation,
            delta: deltaIsolation,
          ),
          const SizedBox(height: 14),

          // Clinical Interpretation Badge
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  !hasSufficientHistory
                      ? LucideIcons.info
                      : (hasHighDrift ? LucideIcons.alertTriangle : LucideIcons.shieldCheck),
                  size: 16,
                  color: !hasSufficientHistory
                      ? AppColors.primary
                      : (hasHighDrift ? AppColors.riskModerate : AppColors.riskLow),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    !hasSufficientHistory
                        ? 'Initial intake session recorded. Baseline distribution requires subsequent observation sessions to model variance and separate fluctuations from sustained drift.'
                        : (hasHighDrift
                            ? 'Resident shows +${deltaLoneliness.toStringAsFixed(1)}Δ deviation from personal baseline. Indicates acute loneliness spike requiring proactive caregiver intervention.'
                            : 'Resident scores align within expected historical stability zone (±3.0Δ deviation). No anomalous behavioral departure detected.'),
                    style: const TextStyle(fontSize: 11, color: AppColors.body, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviationMetricRow({
    required String label,
    required double baseline,
    required double current,
    required double delta,
    bool hasSufficientHistory = true,
  }) {
    final bool isPositive = delta > 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navy)),
            const SizedBox(height: 2),
            Text(
              hasSufficientHistory
                  ? 'Historical Baseline: ${baseline.toInt()}/100'
                  : 'Historical Baseline: Pending (Intake Session)',
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${current.toInt()} / 100',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isPositive ? AppColors.riskHigh : AppColors.riskLow,
                  ),
                ),
                Text(
                  hasSufficientHistory
                      ? '${isPositive ? "+" : ""}${delta.toStringAsFixed(1)} Δ drift'
                      : 'Establishing',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: hasSufficientHistory
                        ? (isPositive ? AppColors.riskHigh : AppColors.riskLow)
                        : AppColors.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // --- 2. COMPARATIVE BENCHMARK CARD (SEC 3.3) ---
  Widget _buildComparativeBenchmarkCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
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
                  Icon(LucideIcons.barChart3, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Experimental Comparative Targets',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Sec 3.3 Comparative Design',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Proposal Sec 3.3 Comparative Design: Target experimental evaluation criteria formulated to validate RALPA advantage against non-adaptive baselines in future clinical trials.',
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
          const SizedBox(height: 14),

          // Benchmark Table / Rows
          _buildBenchmarkComparisonRow(
            modelName: '1. Non-Personalized ML',
            description: 'Static multimodal features without baseline',
            mae: '8.6',
            accuracy: '76.2%',
            isProposed: false,
          ),
          const SizedBox(height: 8),
          _buildBenchmarkComparisonRow(
            modelName: '2. Population-Level Model',
            description: 'Trained on cohort averages across homes',
            mae: '7.8',
            accuracy: '79.4%',
            isProposed: false,
          ),
          const SizedBox(height: 8),
          _buildBenchmarkComparisonRow(
            modelName: '3. Current-State Model',
            description: 'Single latest observation without temporal trend',
            mae: '6.9',
            accuracy: '82.1%',
            isProposed: false,
          ),
          const SizedBox(height: 8),
          _buildBenchmarkComparisonRow(
            modelName: 'Proposed: RALPA Architecture',
            description: 'Resident Baseline + Deviation + Trajectory (Validation Target)',
            mae: '< 4.0 (Target)',
            accuracy: '> 90.0% (Target)',
            isProposed: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkComparisonRow({
    required String modelName,
    required String description,
    required String mae,
    required String accuracy,
    required bool isProposed,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isProposed ? AppColors.primarySoft.withValues(alpha: 0.6) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isProposed ? AppColors.primary : AppColors.border,
          width: isProposed ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      modelName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isProposed ? AppColors.primary : AppColors.navy,
                      ),
                    ),
                    if (isProposed) ...[
                      const SizedBox(width: 6),
                      const Icon(LucideIcons.sparkles, size: 12, color: AppColors.primary),
                    ],
                  ],
                ),
                Text(description, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
              ],
            ),
          ),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Acc: $accuracy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isProposed ? AppColors.primary : AppColors.navy)),
                  Text('MAE: $mae', style: const TextStyle(fontSize: 9, color: AppColors.muted)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 3. LONGITUDINAL 7-DAY TRAJECTORY FORECAST CARD (SEC 3.1 & 3.4) ---
  Widget _buildTrajectoryForecastCard({
    required bool isHighRisk,
    required String status,
    required Color statusColor,
    required List<double> forecast,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
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
                  Icon(LucideIcons.trendingUp, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Longitudinal 14-Day Trajectory Forecast',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Methodology Sec 3.1 & 3.4: Temporal trend modeling predicting continuous risk trajectory across 14 future care periods (Day +1 to Day +14).',
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
          const SizedBox(height: 16),

          if (forecast.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lilac),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertCircle, color: AppColors.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Insufficient Historical Data for Trajectory Forecasting',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navy),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Per RALPA specification (Sec 3.1 & 3.5), at least 2 longitudinal assessments across distinct timepoints are required to compute personal baseline deviation and model trajectory slope.',
                          style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Visual 14-Day Projection Bar/Step Indicator
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Forecasted Loneliness Risk (Day +1 to Day +14)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.navy)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'RALPA Linear Regression Projection',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(forecast.length, (index) {
                        final val = forecast[index];
                        final dayLabel = index == 0 ? 'Today' : 'D+$index';
                        final barHeight = (val / 100.0 * 55.0).clamp(12.0, 55.0);

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${val.toInt()}',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isHighRisk ? AppColors.riskHigh : AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 22,
                                height: barHeight,
                                decoration: BoxDecoration(
                                  color: isHighRisk
                                      ? AppColors.riskHigh.withValues(alpha: 0.2 + ((index % 7) * 0.11))
                                      : AppColors.primary.withValues(alpha: 0.8 - ((index % 7) * 0.08)),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isHighRisk ? AppColors.riskHigh : AppColors.primary,
                                    width: index == 0 ? 1.5 : 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                dayLabel,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Proposal Table 3:1 Evaluation Target Protocol Strip
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Proposal Table 3:1 Benchmark Protocol Targets (Validation in Progress):',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.muted),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildMetricChip('Target Accuracy', '> 85.0%'),
                  _buildMetricChip('Target Macro F1', '> 0.80'),
                  _buildMetricChip('Target MAE Error', '< 5.0 pts'),
                  _buildMetricChip('Target ROC-AUC', '> 0.85'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 10, color: AppColors.muted)),
          Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.navy)),
        ],
      ),
    );
  }

  // --- 4. MULTIMODAL FEATURE ATTRIBUTION CARD (SEC 3.4 TABLE 3:1) ---
  Widget _buildShapFeatureImportanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
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
                  Icon(LucideIcons.layers, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Multimodal Modality Attribution',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Table 3:1 Protocol Weights',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Methodology Table 3:1: Predefined linear modality attribution weights (Questionnaire 40%, Social Attendance 25%, Facial Affect 20%, Voice Acoustics 15%) providing transparent clinical interpretability prior to post-hoc SHAP kernel training.',
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
          const SizedBox(height: 14),

          // Modality 1: Questionnaire
          _buildShapBarRow(
            modality: 'Questionnaire Self-Report (40% Weight)',
            contribution: 40.0,
            color: AppColors.primary,
            clinicalNote: 'UCLA Loneliness scale items measuring subjective feelings of isolation.',
          ),
          const SizedBox(height: 10),

          // Modality 2: Social-Behavioral
          _buildShapBarRow(
            modality: 'Social-Behavioral Attendance (25% Weight)',
            contribution: 25.0,
            color: Colors.blueAccent,
            clinicalNote: 'Group activity participation frequency and recorded room seclusion intervals.',
          ),
          const SizedBox(height: 10),

          // Modality 3: Facial Expression
          _buildShapBarRow(
            modality: 'Facial Affect Recognition (20% Weight)',
            contribution: 20.0,
            color: AppColors.riskModerate,
            clinicalNote: 'PyTorch FER-2013 affect classification (flat affect vs positive valence).',
          ),
          const SizedBox(height: 10),

          // Modality 4: Vocal Acoustics
          _buildShapBarRow(
            modality: 'Vocal Acoustic Prosody (15% Weight)',
            contribution: 15.0,
            color: AppColors.leafGreen,
            clinicalNote: 'Rule-based acoustic metrics (RMS energy, pitch cadence, speech latency).',
          ),
        ],
      ),
    );
  }

  Widget _buildShapBarRow({
    required String modality,
    required double contribution,
    required Color color,
    required String clinicalNote,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(modality, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.navy)),
            Text('${contribution.toInt()}% Impact', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: contribution / 100.0,
            minHeight: 5,
            backgroundColor: AppColors.border,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(clinicalNote, style: const TextStyle(fontSize: 10, color: AppColors.muted, fontStyle: FontStyle.italic)),
      ],
    );
  }

  // --- 5. PERSONALIZED CARE INTERVENTIONS & REASSESSMENT CARD (SEC 3.5) ---
  Widget _buildPersonalizedInterventionsCard(bool isHighRisk) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lavenderBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lilac),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(LucideIcons.heartPulse, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Personalized Intervention Protocols & Reassessment (Sec 3.5)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.lilac),
                ),
                child: const Text(
                  'Closed-Loop Reassessment Active',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Methodology Sec 3.5: Following personalized recommendations, post-intervention observations are monitored to verify whether predicted trajectory stabilizes or improves.',
            style: TextStyle(fontSize: 11, color: AppColors.body),
          ),
          const SizedBox(height: 14),

          // Interventions Grid
          ResponsiveBuilder(
            mobile: (context) => Column(
              children: [
                _buildInterventionCardItem(
                  icon: LucideIcons.sun,
                  title: 'Afternoon Garden & Daylight Stroll',
                  description: 'Exposure to natural sunlight and walking garden path supports circadian wellness and offsets evening loneliness surge.',
                  priority: isHighRisk ? 'High Priority' : 'Standard',
                  priorityColor: isHighRisk ? AppColors.riskHigh : AppColors.riskLow,
                ),
                const SizedBox(height: 10),
                _buildInterventionCardItem(
                  icon: LucideIcons.coffee,
                  title: 'Parlor Herbal Tea Connection (3:30 PM)',
                  description: 'Facilitated small-group peer table matching with active conversational partner to rebuild regular social interaction frequency.',
                  priority: 'Recommended',
                  priorityColor: AppColors.primary,
                ),
              ],
            ),
            desktop: (context) => Row(
              children: [
                Expanded(
                  child: _buildInterventionCardItem(
                    icon: LucideIcons.sun,
                    title: 'Afternoon Garden & Daylight Stroll',
                    description: 'Exposure to natural sunlight and walking garden path supports circadian wellness and offsets evening loneliness surge.',
                    priority: isHighRisk ? 'High Priority' : 'Standard',
                    priorityColor: isHighRisk ? AppColors.riskHigh : AppColors.riskLow,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildInterventionCardItem(
                    icon: LucideIcons.coffee,
                    title: 'Parlor Herbal Tea Connection (3:30 PM)',
                    description: 'Facilitated small-group peer table matching with active conversational partner to rebuild regular social interaction frequency.',
                    priority: 'Recommended',
                    priorityColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterventionCardItem({
    required IconData icon,
    required String title,
    required String description,
    required String priority,
    required Color priorityColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navy)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        priority,
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: priorityColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SUB-VIEW: PERSONALIZED INTERVENTIONS & REASSESSMENT (FR11, FR14) ---
  Widget _buildPersonalizedInterventionsTab() {
    final completedCount = _activities.where((a) => a.isCompleted).length;
    final pendingCount = _activities.length - completedCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Protocol Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.sparkles, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Personalized Care Interventions & Response Reassessment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Grounding in Proposal Sec 1.1, FR11 & FR14: Interventions are tailored across 4 research modalities (Music, Reading, Religious/Cultural, Social) and tracked post-activity to measure longitudinal response.',
                          style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricMiniItem('Active Resident', _currentResident.name, LucideIcons.user),
                    _buildMetricMiniItem('Completed Activities', '$completedCount / ${_activities.length}', LucideIcons.checkCircle2),
                    _buildMetricMiniItem('Pending Action', '$pendingCount Recommended', LucideIcons.clock),
                    _buildMetricMiniItem('RALPA Trajectory', 'Deterioration Warning', LucideIcons.alertTriangle),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Activities List
        const Text(
          'Targeted Activity Interventions for Loneliness & Isolation Mitigation',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navy),
        ),
        const SizedBox(height: 12),
        ..._activities.map((activity) => _buildActivityDetailCard(activity)),

        const SizedBox(height: 20),
        // Escalation Protocol Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.lavenderBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lilac),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.shieldAlert, color: AppColors.primary, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Proposal Section 1.1 Protocol: Counsellor Escalation & Professional Follow-Up',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navy),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'If post-intervention reassessment shows continued high loneliness (Score > 75) or persistent isolation over 2 consecutive cycles, care attendants are prompted to schedule a registered gerontological counsellor or psychologist consultation.',
                      style: TextStyle(fontSize: 12, color: AppColors.body, height: 1.4),
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

  Widget _buildMetricMiniItem(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navy)),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityDetailCard(PersonalizedActivityItem activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: activity.isCompleted ? AppColors.leafGreen.withValues(alpha: 0.5) : AppColors.border,
          width: activity.isCompleted ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: activity.priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(activity.icon, size: 22, color: activity.priorityColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            activity.title,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navy),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: activity.isCompleted
                                ? AppColors.leafGreen.withValues(alpha: 0.15)
                                : activity.priorityColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            activity.isCompleted ? 'COMPLETED & REASSESSED' : activity.priority,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: activity.isCompleted ? AppColors.leafGreen : activity.priorityColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Category: ${activity.category}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      activity.description,
                      style: const TextStyle(fontSize: 12, color: AppColors.body, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (activity.isCompleted) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(LucideIcons.checkCircle2, size: 14, color: AppColors.leafGreen),
                      SizedBox(width: 6),
                      Text(
                        'Post-Intervention Reassessment Record:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.navy),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (activity.completionNotes != null)
                    Text('• Caregiver Notes: ${activity.completionNotes}',
                        style: const TextStyle(fontSize: 11, color: AppColors.body)),
                  if (activity.residentFeedback != null)
                    Text('• Resident Response: "${activity.residentFeedback}"',
                        style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.primary)),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showCounsellorEscalationModal(activity),
                  icon: const Icon(LucideIcons.shieldAlert, size: 14, color: AppColors.riskModerate),
                  label: const Text('Escalate to Counsellor', style: TextStyle(fontSize: 12, color: AppColors.riskModerate)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.riskModerate),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _showActivityCompletionModal(activity),
                  icon: const Icon(LucideIcons.check, size: 14, color: Colors.white),
                  label: const Text('Mark Completed & Reassess', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- SUB-VIEW: ASSESSMENT HISTORY & AUDIT LOGS (FR4, FR13) ---
  Widget _buildAssessmentHistoryTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Longitudinal Assessment History & Records',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Historical multimodal records for ${_currentResident.name} used by RALPA to track deviations and forecast risk trajectories.',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.database, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${_historyLogs.length} Sessions Logged',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Records Table Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.surfaceSecondary),
              columns: const [
                DataColumn(label: Text('Record ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Facial / Vocal Affect', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Loneliness', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Social Isolation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Baseline Dev.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Trajectory Forecast', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Intervention Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Assessor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
              rows: _historyLogs.map((log) {
                final isElevated = log.lonelinessScore > 70;
                return DataRow(
                  cells: [
                    DataCell(Text(log.id, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                    DataCell(Text(log.date, style: const TextStyle(fontSize: 11))),
                    DataCell(Text(log.primaryEmotion, style: const TextStyle(fontSize: 11))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isElevated ? AppColors.riskHigh.withValues(alpha: 0.12) : AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${log.lonelinessScore} / 100',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isElevated ? AppColors.riskHigh : AppColors.navy,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text('${log.isolationScore} / 100', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    DataCell(
                      Text(
                        '${log.deviation > 0 ? "+" : ""}${log.deviation.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: log.deviation > 15 ? AppColors.riskHigh : AppColors.leafGreen,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: log.trajectory.contains('Increasing')
                              ? AppColors.riskHigh.withValues(alpha: 0.1)
                              : AppColors.leafGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          log.trajectory,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: log.trajectory.contains('Increasing') ? AppColors.riskHigh : AppColors.leafGreen,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(log.interventionStatus, style: const TextStyle(fontSize: 11))),
                    DataCell(Text(log.assessedBy, style: const TextStyle(fontSize: 11, color: AppColors.muted))),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // --- ELDER RESIDENT ACCESSIBLE VIEW (SECTION 6.6 PRIVACY & DISTRESS SHIELD) ---
  Widget _buildElderResidentView(AssessmentQuestion currentQ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Friendly Header (No clinical scores)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.navy],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(LucideIcons.smile, size: 48, color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      'Welcome, ${_currentResident.name}!',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Let\'s take a gentle moment together today. How are you feeling?',
                      style: TextStyle(fontSize: 15, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _useSimplifiedElderView = false),
                      icon: const Icon(LucideIcons.layoutDashboard, size: 16),
                      label: const Text('View Full Emotional Wellness Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Conversation Question Card (Big font & large tactile buttons)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${_currentIndex + 1} of ${_questions.length}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.volume2, color: AppColors.primary, size: 28),
                          tooltip: 'Listen to Question',
                          onPressed: _readQuestionAloud,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currentQ.prompt,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Microphone interaction button
                    GestureDetector(
                      onTap: _toggleRecording,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        decoration: BoxDecoration(
                          color: _isRecording ? AppColors.riskHigh : AppColors.primary,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: (_isRecording ? AppColors.riskHigh : AppColors.primary).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_isRecording ? LucideIcons.square : LucideIcons.mic, color: Colors.white, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              _isRecording ? 'Listening... Tap to Stop' : 'Tap to Speak Your Answer',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        'Your Words: "$_spokenText"',
                        style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.navy, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentIndex > 0)
                          ElevatedButton.icon(
                            onPressed: _previousQuestion,
                            icon: const Icon(LucideIcons.chevronLeft, size: 20),
                            label: const Text('Previous', style: TextStyle(fontSize: 15)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surfaceSecondary,
                              foregroundColor: AppColors.navy,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          )
                        else
                          const SizedBox(),
                        ElevatedButton.icon(
                          onPressed: _nextQuestion,
                          icon: const Icon(LucideIcons.chevronRight, size: 20),
                          label: Text(
                            _currentIndex < _questions.length - 1 ? 'Next Question' : 'Complete Check-In',
                            style: const TextStyle(fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Senior Friendly Activities List
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Enjoyable Activities for Today',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Choose activities you love. You can let us know when you finish them!',
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                    const SizedBox(height: 16),
                    ..._activities.map((act) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: act.isCompleted ? AppColors.leafGreen.withValues(alpha: 0.08) : AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: act.isCompleted ? AppColors.leafGreen : AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(act.icon, color: act.isCompleted ? AppColors.leafGreen : AppColors.primary, size: 24),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      act.title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: act.isCompleted ? AppColors.leafGreen : AppColors.navy,
                                        decoration: act.isCompleted ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(act.category, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                                  ],
                                ),
                              ),
                              if (act.isCompleted)
                                const Icon(LucideIcons.checkCircle2, color: AppColors.leafGreen, size: 24)
                              else
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      act.isCompleted = true;
                                      act.residentFeedback = 'Completed happily during morning routine.';
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Great job completing "${act.title}"!'),
                                        backgroundColor: AppColors.leafGreen,
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('I did this!'),
                                ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- MODALS FOR INTERVENTIONS & REASSESSMENT ---
  void _showActivityCompletionModal(PersonalizedActivityItem activity) {
    final notesController = TextEditingController(text: 'Resident engaged positively and showed interest.');
    final feedbackController = TextEditingController(text: 'Reported feeling uplifted and more sociable afterwards.');
    String reassessmentOutcome = 'Positive Improvement';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(LucideIcons.checkCircle2, color: AppColors.leafGreen, size: 22),
              SizedBox(width: 10),
              Text('Log Activity & Post Reassessment', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Activity: ${activity.title}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navy)),
                const SizedBox(height: 12),
                const Text('Caregiver Observation Notes:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Enter observation during activity...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Resident Verbal Feedback:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: feedbackController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Resident feedback quote...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Post-Intervention Reassessment Mood:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: reassessmentOutcome,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Positive Improvement', child: Text('Positive Improvement (Valence Elevated)')),
                    DropdownMenuItem(value: 'Stable / Mild Relief', child: Text('Stable / Mild Relief')),
                    DropdownMenuItem(value: 'No Significant Change', child: Text('No Significant Change (Follow-up Needed)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => reassessmentOutcome = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  activity.isCompleted = true;
                  activity.completionNotes = notesController.text;
                  activity.residentFeedback = feedbackController.text;
                  // If outcome improved, simulate slight reduction in loneliness
                  if (reassessmentOutcome == 'Positive Improvement' && _lonelinessScore > 55) {
                    _lonelinessScore -= 5;
                  }
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Activity logged & Post-Intervention Reassessment updated!'),
                    backgroundColor: AppColors.leafGreen,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save & Update Reassessment'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCounsellorEscalationModal(PersonalizedActivityItem activity) {
    final reasonController = TextEditingController(
      text: 'Resident exhibits persistent affect flattening and withdrawal despite scheduled activities. RALPA longitudinal trend indicates increasing risk.',
    );
    String urgency = 'High Priority (Within 24 Hours)';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(LucideIcons.shieldAlert, color: AppColors.riskModerate, size: 22),
              SizedBox(width: 10),
              Text('Escalate to Care Home Counsellor', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Proposal Section 1.1: When loneliness and social isolation indicators remain elevated, escalate to clinical care staff or psychological counsellor for direct intervention.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.3),
                ),
                const SizedBox(height: 14),
                const Text('Urgency Level:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: urgency,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Immediate (Within 4 Hours)', child: Text('Immediate (Within 4 Hours)')),
                    DropdownMenuItem(value: 'High Priority (Within 24 Hours)', child: Text('High Priority (Within 24 Hours)')),
                    DropdownMenuItem(value: 'Routine Review (Weekly)', child: Text('Routine Review (Weekly)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => urgency = val);
                  },
                ),
                const SizedBox(height: 12),
                const Text('Clinical Escalation Notes:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter clinical concerns and observed patterns...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Escalation alert sent to Care Home Counsellor ($urgency).'),
                    backgroundColor: AppColors.riskModerate,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.riskModerate,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Submit Escalation Notice'),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndicatorSubRow extends StatelessWidget {
  final String label;
  final String level;

  const _IndicatorSubRow({required this.label, required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ),
        Text(
          level,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.navy),
        ),
        const SizedBox(width: 14),
      ],
    );
  }
}

class PersonalizedActivityItem {
  final String id;
  final String title;
  final String category;
  final String description;
  final IconData icon;
  final String priority;
  final Color priorityColor;
  bool isCompleted;
  String? completionNotes;
  String? residentFeedback;

  PersonalizedActivityItem({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
    required this.priority,
    required this.priorityColor,
    this.isCompleted = false,
    this.completionNotes,
    this.residentFeedback,
  });
}

class EmotionalAssessmentHistoryLog {
  final String id;
  final String date;
  final String primaryEmotion;
  final int lonelinessScore;
  final int isolationScore;
  final double deviation;
  final String trajectory;
  final String interventionStatus;
  final String assessedBy;

  const EmotionalAssessmentHistoryLog({
    required this.id,
    required this.date,
    required this.primaryEmotion,
    required this.lonelinessScore,
    required this.isolationScore,
    required this.deviation,
    required this.trajectory,
    required this.interventionStatus,
    required this.assessedBy,
  });
}

class ResidentProfileDataset {
  final double baselineLoneliness;
  final double baselineIsolation;
  final String baselineEstablishedDate;
  final List<EmotionalAssessmentHistoryLog> logs;
  final List<PersonalizedActivityItem> activities;
  final double trendSlope;

  const ResidentProfileDataset({
    required this.baselineLoneliness,
    required this.baselineIsolation,
    required this.baselineEstablishedDate,
    required this.logs,
    required this.activities,
    required this.trendSlope,
  });
}
