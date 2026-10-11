import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class FeatureItemData {
  final IconData icon;
  final String title;
  final String description;

  const FeatureItemData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class TrustMetricData {
  final String title;
  final String subtext;
  final IconData icon;

  const TrustMetricData({
    required this.title,
    required this.subtext,
    required this.icon,
  });
}

class SolutionCardData {
  final IconData icon;
  final String title;
  final String description;
  final String domainTag;

  const SolutionCardData({
    required this.icon,
    required this.title,
    required this.description,
    required this.domainTag,
  });
}

class HowItWorksStepData {
  final int stepNumber;
  final String title;
  final String description;
  final IconData icon;

  const HowItWorksStepData({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class CaregiverBenefitData {
  final IconData icon;
  final String title;
  final String description;

  const CaregiverBenefitData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class TestimonialItemData {
  final String quote;
  final String name;
  final String role;
  final String facility;
  final String avatarAsset;

  const TestimonialItemData({
    required this.quote,
    required this.name,
    required this.role,
    required this.facility,
    required this.avatarAsset,
  });
}

class FaqItemData {
  final String question;
  final String answer;

  const FaqItemData({
    required this.question,
    required this.answer,
  });
}

class LandingContent {
  LandingContent._();

  // Hero Texts
  static const String heroPill = 'AI-Powered Wellness Monitoring';
  static const String heroTitleNavy = 'Caring Today,\n';
  static const String heroTitlePurple = 'Protecting Tomorrow';
  static const String heroParagraph =
      'Carevora helps caregivers in elderly care homes monitor emotional wellness, cognitive wellness, metabolic wellness and detect early signs of decline using AI-assisted assessments and intelligent insights.';

  // Feature Strip (Exact copy preserved from screenshot)
  static const List<FeatureItemData> features = [
    FeatureItemData(
      icon: LucideIcons.bot,
      title: 'AI Assistant',
      description: 'Interactive assessments through natural conversation.',
    ),
    FeatureItemData(
      icon: LucideIcons.activity,
      title: 'Smart Analysis',
      description: 'Advanced AI models analyze responses and speech patterns.',
    ),
    FeatureItemData(
      icon: LucideIcons.trendingUp,
      title: 'Risk Insights',
      description: 'Get clear risk levels with explainable factors and recommendations.',
    ),
    FeatureItemData(
      icon: LucideIcons.heartHandshake,
      title: 'Caregiver Support',
      description: 'Empowering caregivers with actionable insights for better care decisions.',
    ),
  ];

  // Purple Trust Band & Metrics (Product facts only)
  static const List<TrustMetricData> trustMetrics = [
    TrustMetricData(
      title: 'Privacy. Security. Compassion.',
      subtext: 'Highest healthcare data safeguards',
      icon: LucideIcons.shieldCheck,
    ),
    TrustMetricData(
      title: 'Trusted by Care Homes',
      subtext: 'Tailored for senior living staff',
      icon: LucideIcons.building2,
    ),
    TrustMetricData(
      title: 'AI-Powered Assessments',
      subtext: '20-item multimodal conversational session',
      icon: LucideIcons.sparkles,
    ),
    TrustMetricData(
      title: 'Better Care, Better Lives',
      subtext: 'Longitudinal risk trajectory tracking',
      icon: LucideIcons.heartPulse,
    ),
  ];

  static const List<Map<String, String>> statsCountUp = [
    {'value': '3', 'label': 'Clinical Wellness Domains', 'suffix': ''},
    {'value': '20', 'label': 'Item Standard Assessment', 'suffix': ' Qs'},
    {'value': '100', 'label': 'Explainable Risk Factors', 'suffix': '%'},
    {'value': '24', 'label': 'Continuous Caregiver Support', 'suffix': '/7'},
  ];

  // About Section
  static const String aboutHeading = 'Designed for Care Homes';
  static const String aboutParagraph =
      'Carevora bridges clinical rigor with caregiver warmth, giving staff instant actionable risk indicators.';
  static const List<String> aboutMissionBullets = [
    'Early detection before overt clinical decline occurs',
    'Transparent, explainable AI scoring without black-box metrics',
    'Caregiver-first design tailored for daily assistive routines',
  ];

  // Solutions (4 cards)
  static const List<SolutionCardData> solutions = [
    SolutionCardData(
      icon: LucideIcons.brain,
      domainTag: 'Cognitive',
      title: 'Cognitive Monitoring',
      description:
          'Standardized 20-item conversational assessment evaluating temporal orientation, working memory, and language.',
    ),
    SolutionCardData(
      icon: LucideIcons.smile,
      domainTag: 'Emotional',
      title: 'Emotional Wellness',
      description:
          'Facial affect analysis and vocal tone sentiment to identify acute withdrawal and depressive onset early.',
    ),
    SolutionCardData(
      icon: LucideIcons.activity,
      domainTag: 'Metabolic',
      title: 'Metabolic & Vitals',
      description:
          'Blood pressure, glucose trends, and circadian sleep regularity synthesized into holistic wellness index.',
    ),
    SolutionCardData(
      icon: LucideIcons.bot,
      domainTag: 'Assistant',
      title: 'AI Protocol Assistant',
      description:
          'Interactive conversational guidance helping caregivers administer structured speech evaluation with ease.',
    ),
  ];

  // How It Works (4 steps)
  static const List<HowItWorksStepData> steps = [
    HowItWorksStepData(
      stepNumber: 1,
      title: 'Register Resident Profile',
      description:
          'Enter baseline demographic information, room location, and existing care history into Carevora.',
      icon: LucideIcons.userPlus,
    ),
    HowItWorksStepData(
      stepNumber: 2,
      title: 'Voice-Guided AI Assessment',
      description:
          'Administer a calm, 20-question conversational session with automated speech-to-text and reading assistance.',
      icon: LucideIcons.mic,
    ),
    HowItWorksStepData(
      stepNumber: 3,
      title: 'Multimodal AI Analysis',
      description:
          'Natural language processing and sentiment models compute domain scores across cognitive, emotional, and metabolic metrics.',
      icon: LucideIcons.cpu,
    ),
    HowItWorksStepData(
      stepNumber: 4,
      title: 'Actionable Care Insights',
      description:
          'Caregivers review instant risk indicators, trend lines, and clear clinical recommendations for care planning.',
      icon: LucideIcons.clipboardCheck,
    ),
  ];

  // For Caregivers Benefits
  static const List<CaregiverBenefitData> caregiverBenefits = [
    CaregiverBenefitData(
      icon: LucideIcons.clock,
      title: 'Save Time on Assessments',
      description:
          'Conversational guidance and automatic scoring cut evaluation documentation time significantly.',
    ),
    CaregiverBenefitData(
      icon: LucideIcons.checkCircle2,
      title: 'Clear, Explainable Risk Levels',
      description:
          'Color-coded risk tiers (<0.40 Low, 0.40–0.69 Moderate, ≥0.70 High) make priorities crystal clear.',
    ),
    CaregiverBenefitData(
      icon: LucideIcons.bellRing,
      title: 'Alerts That Truly Matter',
      description:
          'Longitudinal risk trajectory highlights subtle behavioral withdrawal before standard clinical symptoms.',
    ),
    CaregiverBenefitData(
      icon: LucideIcons.accessibility,
      title: 'Simple, Senior-Friendly Interface',
      description:
          'High-contrast typography, large touch targets, and natural voice interaction keep residents comfortable.',
    ),
  ];

  // Why Carevora & Security
  static const List<Map<String, dynamic>> whyCarevora = [
    {
      'title': 'Strict Privacy & Data Safeguards',
      'desc':
          'Resident data is protected with enterprise encryption, strict role-based access, and local healthcare privacy compliance.',
      'icon': LucideIcons.lock,
    },
    {
      'title': 'Clinically Explainable AI',
      'desc':
          'Every score provides exact contributing factors and linguistic markers—no opaque black-box recommendations.',
      'icon': LucideIcons.binary,
    },
    {
      'title': 'Designed for Elderly Comfort',
      'desc':
          'Conversational pacing, clear typography, and gentle speech synthesis prevent anxiety during evaluation.',
      'icon': LucideIcons.heartHandshake,
    },
  ];

  // Testimonials (Sample placeholders clearly marked)
  static const List<TestimonialItemData> testimonials = [
    TestimonialItemData(
      quote:
          'Carevora gives our nursing staff immediate clarity on emotional shifts that are usually difficult to quantify during brief rounds.',
      name: 'Sister Nilmini K.',
      role: 'Head Nurse & Care Manager',
      facility: 'Colombo Eldercare Haven',
      avatarAsset: 'assets/images/landing/testimonial_1.jpg',
    ),
    TestimonialItemData(
      quote:
          'The 20-question voice session feels like an engaging conversation to our residents rather than a clinical test. It is compassionate and effective.',
      name: 'Dr. Aruna Perera',
      role: 'Geriatric Wellness Consultant',
      facility: 'Sunset Valley Senior Living',
      avatarAsset: 'assets/images/landing/testimonial_2.jpg',
    ),
    TestimonialItemData(
      quote:
          'Spotting emotional withdrawal 10 days before standard clinical symptoms allowed us to adjust care plans proactively with families.',
      name: 'K. Bandara',
      role: 'Senior Care Specialist',
      facility: 'Greenwood Care Community',
      avatarAsset: 'assets/images/landing/testimonial_3.jpg',
    ),
  ];

  // FAQ
  static const List<FaqItemData> faqs = [
    FaqItemData(
      question: 'What is Carevora?',
      answer:
          'Carevora is an AI-powered wellness monitoring and early risk detection platform built specifically for elderly care homes. It assesses cognitive, emotional, and metabolic wellness through conversational interactions.',
    ),
    FaqItemData(
      question: 'How does the AI assessment work?',
      answer:
          'Caregivers guide residents through a structured 20-item conversational assessment. AI algorithms analyze verbal responses, speech fluency, and sentiment markers to compute longitudinal risk scores.',
    ),
    FaqItemData(
      question: 'Is resident data secure and private?',
      answer:
          'Yes. All patient records and assessment telemetry are encrypted in transit and at rest. Strict role-based authentication ensures only verified care home personnel have access.',
    ),
    FaqItemData(
      question: 'Does Carevora replace doctors or clinicians?',
      answer:
          'No. Carevora is an assistive risk detection tool designed to support care home staff and caregivers. It does not provide medical diagnoses or replace licensed physicians.',
    ),
    FaqItemData(
      question: 'Does Carevora work on mobile phones and tablets?',
      answer:
          'Yes. Carevora is fully responsive on desktop web, tablets, and mobile smartphones, including installable PWA support with voice-enabled touch interfaces.',
    ),
  ];

  // Clinical Disclaimer
  static const String clinicalDisclaimer =
      'Important Notice: Carevora is a clinical decision-support and wellness monitoring tool for caregivers. It provides early risk insights and does not provide formal medical diagnoses or replace medical professionals.';
}
