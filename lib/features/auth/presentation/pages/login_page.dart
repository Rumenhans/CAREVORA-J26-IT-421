import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/responsive/responsive_builder.dart';
import '../../application/auth_controller.dart';
import '../widgets/glass_login_card.dart';
import '../widgets/login_background.dart';
import '../widgets/login_desktop_hero.dart';
import '../widgets/login_header.dart';

class LoginPage extends ConsumerStatefulWidget {
  final String? timeoutReason;

  const LoginPage({
    super.key,
    this.timeoutReason,
  });

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.timeoutReason == 'timeout') {
        ref.read(authProvider).setInfoMessage(
              'You were signed out due to inactivity for your security.',
            );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache background photography for smooth presentation
    precacheImage(
      const AssetImage('assets/images/auth/login_bg_desktop.jpg'),
      context,
    );
    precacheImage(
      const AssetImage('assets/images/auth/login_bg_mobile.jpg'),
      context,
    );
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
              // Left Hero Information Block
              const Expanded(
                flex: 6,
                child: Padding(
                  padding: EdgeInsets.only(right: 60),
                  child: LoginDesktopHero(),
                ),
              ),

              // Right Frosted-Glass Login Card
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: const GlassLoginCard(),
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
            children: const [
              LoginHeader(),
              SizedBox(height: 24),
              GlassLoginCard(),
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
            children: const [
              LoginHeader(),
              SizedBox(height: 20),
              GlassLoginCard(),
            ],
          ),
        ),
      ),
    );
  }
}
