import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/caregiver/login/caregiver_login_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: CarevoraApp(),
    ),
  );
}

class CarevoraApp extends StatelessWidget {
  const CarevoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CAREVORA • Compassionate Care, Smarter Tomorrow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const CaregiverLoginView(),
    );
  }
}
