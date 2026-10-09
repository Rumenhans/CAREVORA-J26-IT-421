import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../components/buttons/carevora_button.dart';
import '../resident/resident_main_view.dart';

class ResidentLoginView extends StatefulWidget {
  const ResidentLoginView({super.key});

  @override
  State<ResidentLoginView> createState() => _ResidentLoginViewState();
}

class _ResidentLoginViewState extends State<ResidentLoginView> {
  final _emailController = TextEditingController(text: 'sarah.jenkins@carevora.com');
  final _passwordController = TextEditingController(text: 'carevora123');
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ResidentMainView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 36),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome to CAREVORA',
                    textAlign: TextAlign.center,
                    style: AppTypography.h1.copyWith(fontSize: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your daily companion for peace, connection, and wellbeing.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 36),

                  // Email
                  Text('Email or Resident ID', style: AppTypography.label.copyWith(fontSize: 15)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    style: AppTypography.bodyLarge,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary),
                      hintText: 'Enter your email address',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password
                  Text('Password', style: AppTypography.label.copyWith(fontSize: 15)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: AppTypography.bodyLarge,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      hintText: 'Enter your password',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Remember Me & Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (v) => setState(() => _rememberMe = v ?? true),
                          ),
                          Text('Remember me', style: AppTypography.body),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Need Help?',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Login Button (Large for elderly accessibility)
                  CarevoraButton(
                    text: 'Sign In to Wellness',
                    height: 56,
                    isLoading: _isLoading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 24),

                  // Help Note
                  Center(
                    child: Text(
                      'If you need assistance signing in, please tap the call button in your room or speak with your care coordinator.',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
