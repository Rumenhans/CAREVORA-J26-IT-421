import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> ttsCalls = [];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ttsCalls.clear();

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

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugin_speech_to_text'), (call) async {
      switch (call.method) {
        case 'initialize':
          return true;
        case 'stop':
        case 'cancel':
          return true;
        default:
          return true;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugin_speech_to_text'), null);
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => MockElderAuthNotifier()),
      ],
      child: const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(1800, 1200)),
          child: Scaffold(
            body: AssessmentSessionPage(),
          ),
        ),
      ),
    );
  }

  group('Cognitive Assessment Speaker Button Icon & State Tests', () {
    testWidgets('1. Displays speaker-off (volumeX) icon before playback starts', (tester) async {
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        oldOnError?.call(details);
      };

      await tester.binding.setSurfaceSize(const Size(1800, 1200));
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      tester.takeException(); // Clear any pre-existing layout warnings

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

      await tester.binding.setSurfaceSize(const Size(1800, 1200));
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

      await tester.binding.setSurfaceSize(const Size(1800, 1200));
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

      await tester.binding.setSurfaceSize(const Size(1800, 1200));
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

      await tester.binding.setSurfaceSize(const Size(1800, 1200));
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
  });
}
