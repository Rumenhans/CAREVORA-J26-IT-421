import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carevora/core/utils/risk_utils.dart';
import 'package:carevora/features/auth/application/auth_controller.dart';
import 'package:carevora/features/auth/presentation/widgets/glass_login_card.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Clinical bounds & utils', () {
    test('RiskUtils tier calculation conforms to Carevora clinical bounds', () {
      expect(RiskUtils.getTier(0.35), RiskTier.low);
      expect(RiskUtils.getTier(0.39), RiskTier.low);
      expect(RiskUtils.getTier(0.40), RiskTier.moderate);
      expect(RiskUtils.getTier(0.64), RiskTier.moderate);
      expect(RiskUtils.getTier(0.69), RiskTier.moderate);
      expect(RiskUtils.getTier(0.70), RiskTier.high);
      expect(RiskUtils.getTier(0.85), RiskTier.high);
    });
  });

  group('Auth Unit & State Tests', () {
    test('AuthNotifier lockout triggers after 5 failed attempts', () async {
      final notifier = AuthNotifier();

      // 4 invalid attempts
      for (int i = 0; i < 4; i++) {
        final res = await notifier.login('bad@carevora.com', 'wrong', false);
        expect(res, false);
        expect(notifier.state.isLockedOut, false);
        expect(notifier.state.failedAttempts, i + 1);
      }

      // 5th invalid attempt
      final res5 = await notifier.login('bad@carevora.com', 'wrong', false);
      expect(res5, false);
      expect(notifier.state.isLockedOut, true);
      expect(notifier.state.lockoutSecondsRemaining, 30);
      expect(notifier.state.failedAttempts, 5);

      notifier.dispose();
    });

    test('AuthNotifier succeeds on demo credentials', () async {
      final notifier = AuthNotifier();
      final res = await notifier.login('seetha@carevora.com', 'demo1234', true);
      expect(res, true);
      expect(notifier.state.isAuthenticated, true);
      expect(notifier.state.email, 'seetha@carevora.com');
      notifier.dispose();
    });
  });

  group('Glass Login Card Widget Tests', () {
    testWidgets('Renders Glass Login Card with all core UI elements and security cues',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: GlassLoginCard(),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.text('Care Home Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Remember me'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('LOGIN'), findsOneWidget);
      expect(find.text('Sign in with SSO'), findsOneWidget);
      expect(find.text('Register here'), findsOneWidget);
      expect(find.text('Encrypted\nconnection'), findsOneWidget);
      expect(find.text('Data stays\nconfidential'), findsOneWidget);
      expect(find.text('Auto sign-out\nwhen idle'), findsOneWidget);
    });

    testWidgets('Validates email and password on submission',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: GlassLoginCard(),
              ),
            ),
          ),
        ),
      );

      // Press LOGIN button with empty fields
      await tester.tap(find.text('LOGIN'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email.'), findsOneWidget);
      expect(find.text('Please enter your password.'), findsOneWidget);
    });
  });
}
