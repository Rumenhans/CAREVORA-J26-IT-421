import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/landing/presentation/pages/landing_page.dart';
import '../../features/dashboard/presentation/dashboard_shell.dart';
import '../../features/dashboard/presentation/overview_page.dart';
import '../../features/dashboard/presentation/generic_placeholder_tab.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/doctor/presentation/pages/doctor_dashboard_page.dart';
import '../../features/medicine/presentation/pages/live_medicine_board_page.dart';
import '../../features/medicine/presentation/pages/medicine_history_page.dart';
import '../../features/assessment/presentation/assessment_session_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/landing',
        builder: (context, state) => const LandingPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final reason = state.uri.queryParameters['reason'];
          return LoginPage(timeoutReason: reason);
        },
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardPage(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => DashboardShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const OverviewPage(),
          ),
          GoRoute(
            path: '/dashboard/residents',
            builder: (context, state) => const GenericPlaceholderTab(
              title: 'Resident Directory',
              description: 'Continuous emotional and social wellness tracking',
              icon: LucideIcons.users,
            ),
          ),
          GoRoute(
            path: '/dashboard/cognitive/session',
            builder: (context, state) => const AssessmentSessionPage(),
          ),
          GoRoute(
            path: '/dashboard/emotional',
            builder: (context, state) => const GenericPlaceholderTab(
              title: 'Emotional Wellness',
              description: 'Affect scoring, sentiment trajectory, and withdrawal indicators',
              icon: LucideIcons.heartPulse,
            ),
          ),
          GoRoute(
            path: '/dashboard/metabolic',
            builder: (context, state) => const GenericPlaceholderTab(
              title: 'Metabolic Health',
              description: 'Vitals tracking, glucose regularity, and sleep rhythm',
              icon: LucideIcons.activity,
            ),
          ),
          GoRoute(
            path: '/dashboard/alerts',
            builder: (context, state) => const GenericPlaceholderTab(
              title: 'Alerts & Clinical Notifications',
              description: 'Automated AI multimodal risk detections and care reminders',
              icon: LucideIcons.bell,
            ),
          ),
          GoRoute(
            path: '/dashboard/reports',
            builder: (context, state) => const GenericPlaceholderTab(
              title: 'Reports & Clinical Analytics',
              description: 'Comprehensive longitudinal healthcare reports',
              icon: LucideIcons.barChart3,
            ),
          ),
          GoRoute(
            path: '/dashboard/care-plans',
            builder: (context, state) => const GenericPlaceholderTab(
              title: 'Care Plans Management',
              description: 'Personalized care recommendations and intervention protocols',
              icon: LucideIcons.clipboardList,
            ),
          ),
          GoRoute(
            path: '/dashboard/doctor',
            builder: (context, state) => const DoctorDashboardPage(),
          ),
          GoRoute(
            path: '/dashboard/medicine',
            builder: (context, state) => const LiveMedicineBoardPage(),
          ),
          GoRoute(
            path: '/dashboard/medicine/history',
            builder: (context, state) => const MedicineHistoryPage(),
          ),
          GoRoute(
            path: '/dashboard/settings',
            builder: (context, state) => const GenericPlaceholderTab(
              title: 'Facility Settings',
              description: 'Accessibility, text sizing, and clinical telemetry configurations',
              icon: LucideIcons.settings,
            ),
          ),
        ],
      ),
    ],
  );
}
