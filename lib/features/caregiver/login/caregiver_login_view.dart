import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../components/brand/carevora_logo.dart';
import '../../../components/brand/caregiver_hands_illustration.dart';
import '../dashboard/caregiver_shell_view.dart';

/// 4K Desktop Web UI & Responsive Login Page for Carevora
/// "Compassionate Care, Smarter Tomorrow"
/// AI-powered wellness monitoring and early risk detection system for elderly care homes.
class CaregiverLoginView extends StatefulWidget {
  const CaregiverLoginView({super.key});

  @override
  State<CaregiverLoginView> createState() => _CaregiverLoginViewState();
}

class _CaregiverLoginViewState extends State<CaregiverLoginView> {
  final _emailController = TextEditingController(text: 'eleanor.vance@carevora.com');
  final _passwordController = TextEditingController(text: 'carevora_admin');
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CaregiverShellView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 960;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background: Full-screen soft lavender-to-pink watercolor gradient with subtle organic ambient shapes
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFF4F0FF), // Lavender Background #F4F0FF
                    Color(0xFFFFFFFF), // Crisp clean center
                    Color(0xFFFDF2F8), // Faint pink blush
                  ],
                  stops: [0.0, 0.5, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Organic curved ambient glow shapes & soft sparkles
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 520,
              height: 520,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE9E1FF).withValues(alpha: 0.45),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -80,
            child: Container(
              width: 560,
              height: 560,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE88BC4).withValues(alpha: 0.14),
              ),
            ),
          ),

          // Subtle Sparkles & ambient stars
          Positioned(
            top: 100,
            left: 220,
            child: Icon(Icons.auto_awesome, color: const Color(0xFF6C3FC5).withValues(alpha: 0.22), size: 22),
          ),
          Positioned(
            bottom: 220,
            left: 140,
            child: Icon(Icons.auto_awesome, color: const Color(0xFFE88BC4).withValues(alpha: 0.25), size: 18),
          ),
          Positioned(
            top: 160,
            right: 280,
            child: Icon(Icons.auto_awesome, color: const Color(0xFF6C3FC5).withValues(alpha: 0.18), size: 20),
          ),

          // Botanical leaf silhouettes at bottom-left and bottom-right
          Positioned(
            bottom: 12,
            left: 16,
            child: Opacity(
              opacity: 0.16,
              child: Icon(
                Icons.spa_rounded,
                size: 110,
                color: const Color(0xFF6CC24A),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 16,
            child: Opacity(
              opacity: 0.14,
              child: Transform.flip(
                flipX: true,
                child: Icon(
                  Icons.eco_rounded,
                  size: 110,
                  color: const Color(0xFF6CC24A),
                ),
              ),
            ),
          ),

          // Main 50/50 Desktop Layout or Centered Stack for smaller screens
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1680),
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // LEFT SIDE (50%): Carevora Brand showcase
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
                              child: _buildLeftHeroContent(),
                            ),
                          ),

                          // RIGHT SIDE (50%): Tall white rounded card (radius 36px)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 32),
                              child: Center(
                                child: _buildRightLoginCard(),
                              ),
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        child: Column(
                          children: [
                            const CarevoraLogo(size: 90, showWordmark: false),
                            const SizedBox(height: 12),
                            Text(
                              'CAREVORA',
                              style: AppTypography.brandWordmark.copyWith(
                                fontSize: 26,
                                color: const Color(0xFF5B2FB0),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Compassionate Care, Smarter Tomorrow',
                              style: AppTypography.bodySmall.copyWith(
                                color: const Color(0xFF6C3FC5),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 28),
                            _buildRightLoginCard(),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// LEFT SIDE: Large centered Carevora logo, serif wordmark, divider with pink heart, tagline, 3-line description, and caregiver hands silhouette
  Widget _buildLeftHeroContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(),

        // Large centered Carevora logo (heart-hand icon with purple adult + pink child, green leaves)
        const CarevoraLogo(size: 140, showWordmark: false),

        const SizedBox(height: 20),

        // CAREVORA in elegant serif small caps, deep purple
        Text(
          'CAREVORA',
          textAlign: TextAlign.center,
          style: AppTypography.brandWordmark.copyWith(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: 5.5,
          ),
        ),

        const SizedBox(height: 16),

        // Thin divider with small pink heart in the middle
        SizedBox(
          width: 260,
          child: Row(
            children: [
              Expanded(
                child: Divider(
                  color: AppColors.softLilac,
                  thickness: 1.5,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  Icons.favorite_rounded,
                  color: AppColors.accentPink,
                  size: 16,
                ),
              ),
              Expanded(
                child: Divider(
                  color: AppColors.softLilac,
                  thickness: 1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Tagline: "Compassionate Care, Smarter Tomorrow"
        Text(
          'Compassionate Care, Smarter Tomorrow',
          textAlign: TextAlign.center,
          style: AppTypography.h3.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),

        const SizedBox(height: 12),

        // AI-Powered Wellness Monitoring and Early Risk Detection System for Elderly Care Homes in 3 centered lines, gray
        SizedBox(
          width: 440,
          child: Text(
            'AI-Powered Wellness Monitoring\nand Early Risk Detection System\nfor Elderly Care Homes',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
              fontSize: 15,
            ),
          ),
        ),

        const Spacer(),

        // Translucent purple-tinted illustration silhouette of a caregiver gently holding an elderly person's hands
        const CaregiverHandsIllustration(width: 340, height: 130),

        const SizedBox(height: 16),
      ],
    );
  }

  /// RIGHT SIDE: A tall white rounded card (radius 36px) with a 2px lavender-purple border and soft glow shadow
  Widget _buildRightLoginCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 520),
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 46),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: AppColors.borderCard,
          width: 2.0,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // "Welcome Back!" bold navy
          Text(
            'Welcome Back!',
            style: AppTypography.h1.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 30,
            ),
          ),

          const SizedBox(height: 8),

          // "Sign in to continue to Carevora" (Carevora in purple bold)
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
              children: [
                const TextSpan(text: 'Sign in to continue to '),
                TextSpan(
                  text: 'Carevora',
                  style: AppTypography.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // Label "Email Address" + input with mail icon
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Email Address',
              style: AppTypography.label.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildInputField(
            controller: _emailController,
            prefixIcon: Icons.mail_outline_rounded,
            hintText: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 20),

          // Label "Password" + input with lock icon, eye toggle icon
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Password',
              style: AppTypography.label.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildInputField(
            controller: _passwordController,
            prefixIcon: Icons.lock_outline_rounded,
            hintText: 'Enter your password',
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.textTertiary,
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),

          const SizedBox(height: 16),

          // Row: checkbox "Remember me" (left), "Forgot password?" purple link (right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: _rememberMe,
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      side: const BorderSide(color: AppColors.borderInput, width: 1.5),
                      onChanged: (val) => setState(() => _rememberMe = val ?? true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Remember me',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset link sent to your registered email.')),
                  );
                },
                child: Text(
                  'Forgot password?',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Full-width primary purple button with login icon "LOGIN"
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                shadowColor: AppColors.primary.withValues(alpha: 0.3),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.login_rounded, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'LOGIN',
                          style: AppTypography.button.copyWith(
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 22),

          // Divider with "or"
          Row(
            children: [
              Expanded(
                child: Divider(color: AppColors.border, thickness: 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'or',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Divider(color: AppColors.border, thickness: 1),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Outlined button with shield icon "Sign in with SSO"
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Redirecting to Enterprise Health SSO portal...')),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.borderInput, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.transparent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Sign in with SSO',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Bottom: "Don't have an account? Register here" (link purple bold)
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              children: [
                const TextSpan(text: "Don't have an account? "),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Registration portal: please contact your institution administrator.')),
                      );
                    },
                    child: Text(
                      'Register here',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
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

  /// Inputs: 48px height, radius 12px, border #E4DEF5, light lavender fill #FAF8FF
  Widget _buildInputField({
    required TextEditingController controller,
    required IconData prefixIcon,
    required String hintText,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return SizedBox(
      height: 48,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.surfaceSecondary,
          prefixIcon: Icon(prefixIcon, color: AppColors.textTertiary, size: 20),
          suffixIcon: suffixIcon,
          hintText: hintText,
          hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderInput, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderInput, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
          ),
        ),
      ),
    );
  }
}
