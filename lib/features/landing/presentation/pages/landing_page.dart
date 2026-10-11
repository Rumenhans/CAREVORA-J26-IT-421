import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/about_section.dart';
import '../widgets/contact_section.dart';
import '../widgets/faq_section.dart';
import '../widgets/feature_strip.dart';
import '../widgets/final_cta_banner.dart';
import '../widgets/for_caregivers_section.dart';
import '../widgets/hero_section.dart';
import '../widgets/how_it_works_section.dart';
import '../widgets/landing_drawer.dart';
import '../widgets/landing_footer.dart';
import '../widgets/landing_navbar.dart';
import '../widgets/product_preview_section.dart';
import '../widgets/solution_section.dart';
import '../widgets/stats_band.dart';
import '../widgets/testimonials_section.dart';
import '../widgets/why_carevora_section.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollController = ScrollController();

  final _homeKey = GlobalKey();
  final _aboutKey = GlobalKey();
  final _solutionKey = GlobalKey();
  final _howKey = GlobalKey();
  final _caregiversKey = GlobalKey();
  final _contactKey = GlobalKey();

  String _activeSection = 'home';
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    if (offset > 600 && !_showBackToTop) {
      setState(() => _showBackToTop = true);
    } else if (offset <= 600 && _showBackToTop) {
      setState(() => _showBackToTop = false);
    }
  }

  void _scrollTo(GlobalKey key, String sectionName) {
    setState(() => _activeSection = sectionName);
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.page,
      drawer: LandingDrawer(
        activeSection: _activeSection,
        onScrollHome: () {
          Navigator.pop(context);
          _scrollTo(_homeKey, 'home');
        },
        onScrollAbout: () {
          Navigator.pop(context);
          _scrollTo(_aboutKey, 'about');
        },
        onScrollSolution: () {
          Navigator.pop(context);
          _scrollTo(_solutionKey, 'solution');
        },
        onScrollHow: () {
          Navigator.pop(context);
          _scrollTo(_howKey, 'how');
        },
        onScrollCaregivers: () {
          Navigator.pop(context);
          _scrollTo(_caregiversKey, 'caregivers');
        },
        onScrollContact: () {
          Navigator.pop(context);
          _scrollTo(_contactKey, 'contact');
        },
      ),
      floatingActionButton: _showBackToTop
          ? FloatingActionButton(
              mini: true,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: _scrollToTop,
              tooltip: 'Back to top',
              child: const Icon(Icons.keyboard_arrow_up_rounded),
            )
          : null,
      body: Column(
        children: [
          // 1. Sticky Navbar
          LandingNavbar(
            scaffoldKey: _scaffoldKey,
            activeSection: _activeSection,
            onScrollHome: () => _scrollTo(_homeKey, 'home'),
            onScrollAbout: () => _scrollTo(_aboutKey, 'about'),
            onScrollSolution: () => _scrollTo(_solutionKey, 'solution'),
            onScrollHow: () => _scrollTo(_howKey, 'how'),
            onScrollCaregivers: () => _scrollTo(_caregiversKey, 'caregivers'),
            onScrollContact: () => _scrollTo(_contactKey, 'contact'),
          ),
          // Scrollable Landing Page Content
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  // 2. Hero Section
                  HeroSection(
                    heroKey: _homeKey,
                    onLearnMore: () => _scrollTo(_solutionKey, 'solution'),
                  ),
                  // 3. Feature Strip (Overlapping Hero bottom)
                  const FeatureStrip(),
                  // 4. Stats / Trust Band
                  const StatsBand(),
                  // 5. About Section
                  AboutSection(aboutKey: _aboutKey),
                  // 6. Our Solution Section
                  SolutionSection(solutionKey: _solutionKey),
                  // 7. Product Preview Mockup
                  const ProductPreviewSection(),
                  // 8. How It Works Section
                  HowItWorksSection(howKey: _howKey),
                  // 9. For Caregivers Section
                  ForCaregiversSection(caregiversKey: _caregiversKey),
                  // 10. Why Carevora / Privacy Section
                  const WhyCarevoraSection(),
                  // 11. Testimonials Section (Sample)
                  const TestimonialsSection(),
                  // 12. FAQ Section
                  const FaqSection(),
                  // 13. Contact Section
                  ContactSection(contactKey: _contactKey),
                  // 14. Final CTA Banner
                  const FinalCtaBanner(),
                  // 15. Footer
                  LandingFooter(
                    onScrollHome: () => _scrollTo(_homeKey, 'home'),
                    onScrollAbout: () => _scrollTo(_aboutKey, 'about'),
                    onScrollSolution: () => _scrollTo(_solutionKey, 'solution'),
                    onScrollHow: () => _scrollTo(_howKey, 'how'),
                    onScrollCaregivers: () => _scrollTo(_caregiversKey, 'caregivers'),
                    onScrollContact: () => _scrollTo(_contactKey, 'contact'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
