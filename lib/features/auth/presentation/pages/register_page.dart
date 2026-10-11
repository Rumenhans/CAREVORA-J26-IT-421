import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/responsive/responsive_builder.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/common/app_text_field.dart';
import '../widgets/common/glass_container.dart';
import '../widgets/common/gradient_button.dart';
import '../widgets/login_background.dart';
import '../widgets/login_desktop_hero.dart';
import '../widgets/login_header.dart';
import '../widgets/protected_signin_strip.dart';
import '../widgets/secure_footer.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _facilityController = TextEditingController();

  bool _isLoading = false;
  bool _isSuccess = false;
  bool _hasSubmittedOnce = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _facilityController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() => _hasSubmittedOnce = true);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 900));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoginBackground(
        child: SafeArea(
          child: ResponsiveBuilder(
            mobile: (context) => _buildMobileLayout(),
            tablet: (context) => _buildTabletLayout(),
            desktop: (context) => _buildDesktopLayout(),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 36),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Hero Story Block
              const Expanded(
                flex: 6,
                child: Padding(
                  padding: EdgeInsets.only(right: 60),
                  child: LoginDesktopHero(),
                ),
              ),

              // Right Frosted-Glass Card
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _buildGlassCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LoginHeader(),
              const SizedBox(height: 24),
              _buildGlassCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LoginHeader(),
              const SizedBox(height: 20),
              _buildGlassCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard() {
    return GlassContainer(
      borderRadius: 32,
      blur: 20,
      color: AppColors.glassWhite,
      borderColor: AppColors.glassBorder,
      borderWidth: 1.5,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      child: _isSuccess ? _buildSuccessView() : _buildFormView(),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      autovalidateMode: _hasSubmittedOnce
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Gradient Accent Line
          Center(
            child: Container(
              height: 3.5,
              width: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accentPink],
                ),
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header Row with Back Button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.lilac.withValues(alpha: 0.8),
                  ),
                ),
                child: const Icon(
                  LucideIcons.building2,
                  size: 22,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Request Facility Access',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Care community onboarding',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.body,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  LucideIcons.arrowLeft,
                  color: AppColors.navy,
                  size: 20,
                ),
                tooltip: 'Back to Login',
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Subtitle info
          const Text(
            'Register your eldercare facility to deploy AI-driven resident safety & risk alerts.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.body,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Full Name Input
          AppTextField(
            controller: _nameController,
            label: 'Full Name',
            hintText: 'Sarah Jenkins',
            leadingIcon: LucideIcons.user,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Please enter your name.' : null,
          ),
          const SizedBox(height: 14),

          // Work Email Input
          AppTextField(
            controller: _emailController,
            label: 'Work Email Address',
            hintText: 'sarah@meadowcare.org',
            leadingIcon: LucideIcons.mail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter your work email.';
              }
              final regex = RegExp(
                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
              );
              if (!regex.hasMatch(v.trim())) {
                return 'Enter a valid work email.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Facility Name Input
          AppTextField(
            controller: _facilityController,
            label: 'Care Home / Facility Name',
            hintText: 'Meadowview Senior Living',
            leadingIcon: LucideIcons.building,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleRegister(),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please enter facility name.'
                : null,
          ),
          const SizedBox(height: 22),

          // Submit Button
          GradientButton(
            isLoading: _isLoading,
            loadingLabel: 'Submitting Request...',
            onPressed: _handleRegister,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  LucideIcons.send,
                  size: 16,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Text(
                  'Submit Access Request',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Protected Sign-in Strip
          const ProtectedSignInStrip(),
          const SizedBox(height: 18),

          // Back to Login Link
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              children: [
                const Text(
                  'Already registered? ',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.body,
                  ),
                ),
                InkWell(
                  onTap: () => context.go('/login'),
                  child: const Text(
                    'Return to Login',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Secure Footer
          const SecureFooter(),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Gradient Accent Line
        Center(
          child: Container(
            height: 3.5,
            width: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accentPink],
              ),
              borderRadius: BorderRadius.circular(9999),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Success Icon Circle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.riskLowBg,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.riskLow.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: const Icon(
            LucideIcons.checkCircle2,
            size: 38,
            color: AppColors.riskLow,
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'Request Submitted!',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),

        Text(
          'Thank you, ${_nameController.text.trim()}.\nOur clinical deployment team will verify ${_facilityController.text.trim()} and dispatch your onboarding security keys.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.body,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 26),

        GradientButton(
          onPressed: () => context.go('/login'),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                LucideIcons.logIn,
                size: 16,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Text(
                'Back to Sign In',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        const SecureFooter(),
      ],
    );
  }
}
