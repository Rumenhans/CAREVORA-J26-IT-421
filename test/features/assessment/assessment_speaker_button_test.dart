// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text_platform_interface/speech_to_text_platform_interface.dart';
import 'package:carevora/features/auth/application/auth_controller.dart';
import 'package:carevora/features/assessment/presentation/assessment_session_page.dart';

class MockElderAuthNotifier extends AuthNotifier {
  @override
  AuthState get state => const AuthState(
        isAuthenticated: true,
        userName: 'Sarah Jenkins',
        role: UserRole.elder,
        residentId: 1,
        elderHomeId: 1,
        elderHomeName: 'Serene Valley Senior Living',
        token: 'test-jwt-token',
      );
}

class MockSpeechToTextPlatform extends SpeechToTextPlatform {
  bool initResult = true;
  bool listenResult = true;
  bool listenInvoked = false;
  bool stopInvoked = false;
  bool cancelInvoked = false;

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> initialize({debugLogging = false, List<SpeechConfigOption>? options}) async {
    return initResult;
  }

  @override
  Future<bool> listen({
    String? localeId,
    partialResults = true,
    onDevice = false,
    int listenMode = 0,
    sampleRate = 0,
    SpeechListenOptions? options,
  }) async {
    listenInvoked = true;
    onStatus?.call('listening');
    return listenResult;
  }

  @override
  Future<void> stop() async {
    stopInvoked = true;
  }

  @override
  Future<void> cancel() async {
    cancelInvoked = true;
  }

  @override
  Future<List<dynamic>> locales() async => ['en_US:English US'];

  void reset() {
    listenInvoked = false;
    stopInvoked = false;
    cancelInvoked = false;
    initResult = true;
    listenResult = true;
  }

  void emitWords(String words, {bool isFinal = false}) {
    final typeVal = isFinal ? 2 : 0;
    onTextRecognition?.call(
      '{"alternates":[{"recognizedWords":"$words","confidence":0.9}],"resultType":$typeVal}',
    );
  }

  void emitStatus(String status) {
    onStatus?.call(status);
  }

  void emitError(String errorMsg, {bool permanent = true}) {
    onError?.call('{"errorMsg":"$errorMsg","permanent":$permanent}');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> ttsCalls = [];
  final mockSttPlatform = MockSpeechToTextPlatform();
  SpeechToTextPlatform.instance = mockSttPlatform;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ttsCalls.clear();
    mockSttPlatform.reset();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (call) async {
      ttsCalls.add(call);
      switch (call.method) {
        case 'setLanguage':
        case 'setSpeechRate':
        case 'setVolume':
        case 'setPitch':
        case 'stop':
        case 'speak':
          return 1;
        default:
          return 1;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => MockElderAuthNotifier()),
      ],
      child: const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(1440, 1600)),
          child: Scaffold(
            body: AssessmentSessionPage(),
          ),
        ),
      ),
    );
  }

  group('Cognitive Assessment Speaker Button & Microphone Integration Tests', () {
    testWidgets('1. Displays speaker-off (volumeX) icon before playback starts', (tester) async {
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        oldOnError?.call(details);
      };

      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      tester.takeException();

      // Find the speaker icon button by tooltip
      final speakerBtn = find.byTooltip('Read question aloud');
      expect(speakerBtn, findsOneWidget);

      // Verify that volumeX (speaker-off) is displayed and volume2 is NOT
      final iconFinder = find.descendant(of: speakerBtn, matching: find.byType(Icon));
      expect(iconFinder, findsOneWidget);
      final iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.icon, equals(LucideIcons.volumeX));

      FlutterError.onError = oldOnError;
    });

    testWidgets('2. Clicking speaker button changes icon to speaker-on (volume2) and starts audio', (tester) async {
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        oldOnError?.call(details);
      };

      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      tester.takeException();

      final speakerBtn = find.byTooltip('Read question aloud');
      expect(speakerBtn, findsOneWidget);

      // Click to start audio
      await tester.tap(speakerBtn);
      await tester.pump(); // Immediate rebuild with _isSpeaking = true

      // Verify speaker-on icon is now displayed
      final activeBtn = find.byTooltip('Stop audio');
      expect(activeBtn, findsOneWidget);
      final iconFinder = find.descendant(of: activeBtn, matching: find.byType(Icon));
      final iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.icon, equals(LucideIcons.volume2));

      // Verify speak was called on TTS engine
      expect(ttsCalls.any((c) => c.method == 'speak'), isTrue);

      FlutterError.onError = oldOnError;
    });

    testWidgets('3. Clicking speaker button during playback stops audio and returns icon to speaker-off', (tester) async {
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        oldOnError?.call(details);
      };

      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      tester.takeException();

      // Start audio
      await tester.tap(find.byTooltip('Read question aloud'));
      await tester.pump();

      // Confirm playing state
      expect(find.byTooltip('Stop audio'), findsOneWidget);

      // Click again while playing
      await tester.tap(find.byTooltip('Stop audio'));
      await tester.pump();

      // Verify returned to speaker-off (volumeX)
      final speakerBtn = find.byTooltip('Read question aloud');
      expect(speakerBtn, findsOneWidget);
      final iconFinder = find.descendant(of: speakerBtn, matching: find.byType(Icon));
      final iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.icon, equals(LucideIcons.volumeX));

      // Verify stop was called on TTS engine
      expect(ttsCalls.any((c) => c.method == 'stop'), isTrue);

      FlutterError.onError = oldOnError;
    });

    testWidgets('4. Natural audio completion returns icon to speaker-off', (tester) async {
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        oldOnError?.call(details);
      };

      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      tester.takeException();

      // Start audio
      await tester.tap(find.byTooltip('Read question aloud'));
      await tester.pump();

      // Verify playing state
      expect(find.byTooltip('Stop audio'), findsOneWidget);

      // Simulate completion event from platform
      final ByteData message = const StandardMethodCodec().encodeMethodCall(
        const MethodCall('speak.onComplete'),
      );
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage('flutter_tts', message, (ByteData? reply) {});
      await tester.pump();

      // Verify returned to speaker-off
      final speakerBtn = find.byTooltip('Read question aloud');
      expect(speakerBtn, findsOneWidget);
      final iconFinder = find.descendant(of: speakerBtn, matching: find.byType(Icon));
      final iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.icon, equals(LucideIcons.volumeX));

      FlutterError.onError = oldOnError;
    });

    testWidgets('5. Question navigation stops audio and resets icon to speaker-off', (tester) async {
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        oldOnError?.call(details);
      };

      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      tester.takeException();

      // Start audio
      await tester.tap(find.byTooltip('Read question aloud'));
      await tester.pump();
      expect(find.byTooltip('Stop audio'), findsOneWidget);

      // Navigate to next question
      final nextBtn = find.text('Next Question →');
      await tester.ensureVisible(nextBtn);
      await tester.tap(nextBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify audio stopped and new question shows speaker-off
      final speakerBtn = find.byTooltip('Read question aloud');
      expect(speakerBtn, findsOneWidget);
      final iconFinder = find.descendant(of: speakerBtn, matching: find.byType(Icon));
      final iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.icon, equals(LucideIcons.volumeX));

      FlutterError.onError = oldOnError;
    });

    testWidgets('6. Microphone button tap stops active TTS immediately, resetting speaker icon', (tester) async {
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        oldOnError?.call(details);
      };

      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      tester.takeException();

      // 1. Start audio
      await tester.tap(find.byTooltip('Read question aloud'));
      await tester.pump();
      expect(find.byTooltip('Stop audio'), findsOneWidget);

      // 2. Tap microphone button while audio is playing
      final micBtn = find.byIcon(LucideIcons.mic);
      expect(micBtn, findsOneWidget);
      await tester.ensureVisible(micBtn);
      await tester.tap(micBtn);
      await tester.pump();

      // 3. TTS is stopped immediately and speaker icon returns to speaker-off
      expect(ttsCalls.any((c) => c.method == 'stop'), isTrue);
      expect(find.byTooltip('Read question aloud'), findsOneWidget);
      expect(find.byTooltip('Stop audio'), findsNothing);

      // 4. Speech recognition listen was initiated
      expect(mockSttPlatform.listenInvoked, isTrue);

      FlutterError.onError = oldOnError;
    });

    testWidgets('7. Speaker button tap stops active microphone listening before playing audio', (tester) async {
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        oldOnError?.call(details);
      };

      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      tester.takeException();

      // 1. Start listening
      final micBtn = find.byIcon(LucideIcons.mic);
      await tester.ensureVisible(micBtn);
      await tester.tap(micBtn);
      await tester.pump();

      // Confirm listening is active
      expect(find.byIcon(LucideIcons.micOff), findsOneWidget);

      // 2. Tap speaker button to play question
      final speakerBtn = find.byTooltip('Read question aloud');
      await tester.tap(speakerBtn);
      await tester.pump();

      // 3. STT stop was called, micOff reverts to mic, and TTS starts with speaker-on
      expect(mockSttPlatform.stopInvoked, isTrue);
      expect(find.byIcon(LucideIcons.mic), findsOneWidget);
      expect(find.byTooltip('Stop audio'), findsOneWidget);

      FlutterError.onError = oldOnError;
    });

    testWidgets('8. Manual keyboard typing works and preserves answer', (tester) async {
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        oldOnError?.call(details);
      };

      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      tester.takeException();

      // Enter manual text
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, 'Friday');
      await tester.pump();

      expect(find.text('Friday'), findsOneWidget);
      expect(find.text('Answer Saved'), findsAtLeastNWidgets(1));

      FlutterError.onError = oldOnError;
    });

    testWidgets('9. Spoken answer is recognized, displayed, and preserved across question navigation', (tester) async {
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        oldOnError?.call(details);
      };

      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      tester.takeException();

      // Start listening
      final micBtn = find.byIcon(LucideIcons.mic);
      await tester.ensureVisible(micBtn);
      await tester.tap(micBtn);
      await tester.pump();

      // Emit recognized words
      mockSttPlatform.emitWords('Friday', isFinal: true);
      await tester.pump();

      // Verify text field updated with recognized speech
      expect(find.text('Friday'), findsOneWidget);

      // Navigate to Next Question
      final nextBtn = find.text('Next Question →');
      await tester.ensureVisible(nextBtn);
      await tester.tap(nextBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Navigate back to Previous Question
      final prevBtn = find.text('← Prev');
      await tester.ensureVisible(prevBtn);
      await tester.tap(prevBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Verify speech answer is still preserved
      expect(find.text('Friday'), findsOneWidget);

      FlutterError.onError = oldOnError;
    });

    testWidgets('10. Multi-word spoken answer with pauses displays full recognized phrase', (tester) async {
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        oldOnError?.call(details);
      };

      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      tester.takeException();

      // Tap microphone
      final micBtn = find.byIcon(LucideIcons.mic);
      await tester.ensureVisible(micBtn);
      await tester.tap(micBtn);
      await tester.pump();

      // First partial recognition
      mockSttPlatform.emitWords('Sun Book', isFinal: false);
      await tester.pump();
      expect(find.text('Sun Book'), findsOneWidget);

      // Final complete phrase recognition
      mockSttPlatform.emitWords('Sun, Book, Tree', isFinal: true);
      await tester.pump();
      expect(find.text('Sun, Book, Tree'), findsOneWidget);

      FlutterError.onError = oldOnError;
    });

    testWidgets('11. Recognition error handles gracefully and displays status message without crashing', (tester) async {
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        oldOnError?.call(details);
      };

      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      tester.takeException();

      // Tap microphone
      final micBtn = find.byIcon(LucideIcons.mic);
      await tester.ensureVisible(micBtn);
      await tester.tap(micBtn);
      await tester.pump();

      // Emit error
      mockSttPlatform.emitError('Microphone permission denied', permanent: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify status note displayed and session remains stable
      expect(find.byType(AssessmentSessionPage), findsOneWidget);
      expect(find.textContaining('Microphone permission denied', skipOffstage: false), findsOneWidget);

      FlutterError.onError = oldOnError;
    });

    testWidgets('12. Partial transcript followed by an empty callback does not erase recognized text', (tester) async {
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        oldOnError?.call(details);
      };

      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      tester.takeException();

      // Tap microphone
      final micBtn = find.byIcon(LucideIcons.mic);
      await tester.ensureVisible(micBtn);
      await tester.tap(micBtn);
      await tester.pump();

      // 1. Partial transcript arrives
      mockSttPlatform.emitWords('clock', isFinal: false);
      await tester.pump();
      expect(find.text('clock'), findsOneWidget);

      // 2. Empty callback arrives
      mockSttPlatform.emitWords('', isFinal: false);
      await tester.pump();

      // 3. Verify text was NOT wiped by the empty callback
      expect(find.text('clock'), findsOneWidget);

      FlutterError.onError = oldOnError;
    });

    testWidgets('13. Partial transcript followed by session completion without a final result saves and scores answer', (tester) async {
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        oldOnError?.call(details);
      };

      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      tester.takeException();

      // Tap microphone
      final micBtn = find.byIcon(LucideIcons.mic);
      await tester.ensureVisible(micBtn);
      await tester.tap(micBtn);
      await tester.pump();

      // Chrome Web Speech API reality: emits partial results with isFinal: false, never true
      mockSttPlatform.emitWords('Friday', isFinal: false);
      await tester.pump();
      expect(find.text('Friday'), findsOneWidget);

      // Session ends naturally (status: notListening) without ever emitting finalResult: true
      mockSttPlatform.emitStatus('notListening');
      await tester.pump();

      // Verify listening state stopped, transcript preserved, and voice response confirmed captured
      expect(find.byIcon(LucideIcons.mic), findsOneWidget);
      expect(find.text('Friday'), findsOneWidget);
      expect(find.text('Voice response captured.'), findsOneWidget);

      FlutterError.onError = oldOnError;
    });

    testWidgets('14. Manual stop preserves the latest valid transcript and scores answer', (tester) async {
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        oldOnError?.call(details);
      };

      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      tester.takeException();

      // Start listening
      final micBtn = find.byIcon(LucideIcons.mic);
      await tester.ensureVisible(micBtn);
      await tester.tap(micBtn);
      await tester.pump();
      expect(find.byIcon(LucideIcons.micOff), findsOneWidget);

      // Partial words recognized
      mockSttPlatform.emitWords('wrist watch', isFinal: false);
      await tester.pump();
      expect(find.text('wrist watch'), findsOneWidget);

      // User manually taps mic to stop
      final stopMicBtn = find.byIcon(LucideIcons.micOff);
      await tester.tap(stopMicBtn);
      await tester.pump();

      // Verify microphone stop called, transcript preserved, and captured status displayed
      expect(mockSttPlatform.stopInvoked, isTrue);
      expect(find.byIcon(LucideIcons.mic), findsOneWidget);
      expect(find.text('wrist watch'), findsOneWidget);
      expect(find.text('Voice response captured.'), findsOneWidget);

      FlutterError.onError = oldOnError;
    });

    testWidgets('15. Recognition error does not erase previously recognized text', (tester) async {
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        oldOnError?.call(details);
      };

      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      tester.takeException();

      // Start listening
      final micBtn = find.byIcon(LucideIcons.mic);
      await tester.ensureVisible(micBtn);
      await tester.tap(micBtn);
      await tester.pump();

      // User spoke partial answer
      mockSttPlatform.emitWords('hospital and school', isFinal: false);
      await tester.pump();
      expect(find.text('hospital and school'), findsOneWidget);

      // Error event fires (e.g. timeout / no-speech)
      mockSttPlatform.emitError('no-speech', permanent: false);
      await tester.pump();

      // Verify recognized words are NOT wiped on error
      expect(find.text('hospital and school'), findsOneWidget);
      expect(find.text('Voice response captured.'), findsOneWidget);

      FlutterError.onError = oldOnError;
    });

    testWidgets('16. Empty results show a retry message instead of treating it as captured', (tester) async {
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        oldOnError?.call(details);
      };

      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      tester.takeException();

      // Start listening without uttering any speech
      final micBtn = find.byIcon(LucideIcons.mic);
      await tester.ensureVisible(micBtn);
      await tester.tap(micBtn);
      await tester.pump();

      // Recognition ends with empty buffer
      mockSttPlatform.emitStatus('notListening');
      await tester.pump();

      // Verify clear retry prompt is shown and no false "captured" note is displayed
      expect(find.text('Voice response captured.'), findsNothing);
      expect(
        find.textContaining('Speech not recognized. Please tap the microphone to retry or type your answer.'),
        findsOneWidget,
      );

      FlutterError.onError = oldOnError;
    });

    testWidgets('17. A late callback from a previous session does not overwrite a newer session answer', (tester) async {
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        oldOnError?.call(details);
      };

      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      tester.takeException();

      // 1. Start listening on Question 1 (Day of week)
      final micBtn = find.byIcon(LucideIcons.mic);
      await tester.ensureVisible(micBtn);
      await tester.tap(micBtn);
      await tester.pump();

      // 2. Navigate to Question 2 before recognition returns
      final nextBtn = find.text('Next Question →');
      await tester.ensureVisible(nextBtn);
      await tester.tap(nextBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 3. Question 2 has empty input
      expect(find.text('Friday'), findsNothing);

      // 4. A delayed/stale callback from Question 1's speech session arrives now
      mockSttPlatform.emitWords('Friday', isFinal: false);
      await tester.pump();

      // 5. Verify Question 2 was NOT overwritten with Friday!
      expect(find.text('Friday'), findsNothing);

      FlutterError.onError = oldOnError;
    });
  });
}
