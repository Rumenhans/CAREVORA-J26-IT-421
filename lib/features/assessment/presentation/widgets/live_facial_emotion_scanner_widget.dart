import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../application/facial_emotion_ai_service.dart';

class LiveFacialEmotionScannerWidget extends StatefulWidget {
  final ValueChanged<FacialEmotionResult>? onAnalysisComplete;

  const LiveFacialEmotionScannerWidget({
    super.key,
    this.onAnalysisComplete,
  });

  @override
  State<LiveFacialEmotionScannerWidget> createState() =>
      _LiveFacialEmotionScannerWidgetState();
}

class _LiveFacialEmotionScannerWidgetState
    extends State<LiveFacialEmotionScannerWidget>
    with SingleTickerProviderStateMixin {
  String _selectedSampleAsset = 'assets/images/landing/senior_happy_face.jpg';
  bool _isAnalyzing = false;
  FacialEmotionResult? _analysisResult;
  late AnimationController _scannerLineController;

  final ImagePicker _picker = ImagePicker();
  Uint8List? _capturedBytes;

  @override
  void initState() {
    super.initState();
    _scannerLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Initial analysis on load
    _runAiInference(_selectedSampleAsset);
  }

  @override
  void dispose() {
    _scannerLineController.dispose();
    super.dispose();
  }

  Future<void> _captureLiveCameraPhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 480,
        maxHeight: 480,
        imageQuality: 85,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _isAnalyzing = true;
          _capturedBytes = bytes;
        });

        final result = await FacialEmotionAiService.analyzeImage(imageBytes: bytes);

        if (mounted) {
          setState(() {
            _isAnalyzing = false;
            _analysisResult = result;
          });
          if (widget.onAnalysisComplete != null) {
            widget.onAnalysisComplete!(result);
          }
        }
      }
    } catch (e) {
      debugPrint('Camera capture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera capture error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _runAiInference(String assetPath) async {
    setState(() {
      _isAnalyzing = true;
      _selectedSampleAsset = assetPath;
      _capturedBytes = null;
    });

    final result = await FacialEmotionAiService.analyzeImage(assetPath: assetPath);

    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _analysisResult = result;
      });
      if (widget.onAnalysisComplete != null) {
        widget.onAnalysisComplete!(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.camera,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Facial Affect & Emotion AI',
                        style: AppTextStyles.h4.copyWith(fontSize: 15),
                      ),
                      const Text(
                        'Real-time Vision ML Model • Senior Affect Analysis',
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.riskLowBg,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: AppColors.riskLow.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.fiber_manual_record, size: 8, color: AppColors.riskLow),
                    SizedBox(width: 6),
                    Text(
                      'AI Vision Active',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.riskLow,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Viewport (Video Stream / Photo Scan Box)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Frame with Scanning Reticle
              Expanded(
                flex: 5,
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.lilac, width: 2),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Image (Camera Bytes or Asset Sample)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _capturedBytes != null
                              ? Image.memory(
                                  _capturedBytes!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                )
                              : Image.asset(
                                  _selectedSampleAsset,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                        ),

                        // Face Landmark Target Bounding Box
                        Container(
                          margin: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: (_analysisResult?.primaryEmotion ==
                                      EmotionCategory.happy)
                                  ? AppColors.riskLow
                                  : (_analysisResult?.primaryEmotion ==
                                          EmotionCategory.sadDepressed)
                                      ? AppColors.riskHigh
                                      : (_analysisResult?.primaryEmotion ==
                                              EmotionCategory.confusedAgitated)
                                          ? AppColors.riskModerate
                                          : (_analysisResult?.primaryEmotion ==
                                                  EmotionCategory.anxious)
                                              ? AppColors.lilac
                                              : AppColors.primary,
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),

                        // Animated Laser Scanning Line
                        AnimatedBuilder(
                          animation: _scannerLineController,
                          builder: (context, _) {
                            return Align(
                              alignment: Alignment(
                                0.0,
                                -0.8 + (_scannerLineController.value * 1.6),
                              ),
                              child: Container(
                                height: 2,
                                margin: const EdgeInsets.symmetric(horizontal: 24),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      AppColors.accentPink,
                                      AppColors.primary,
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.8),
                                      blurRadius: 8,
                                      offset: const Offset(0, 0),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // Emotion Live Tag on Viewport
                        if (_analysisResult != null && !_isAnalyzing)
                          Positioned(
                            bottom: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _analysisResult!.emoji,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _analysisResult!.emotionLabel,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '(${( _analysisResult!.confidence * 100).toInt()}%)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.lilac,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        if (_isAnalyzing)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Analysis Metrics Breakdown (Happy / Sad / Neutral Meters)
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Predicted Emotion Distribution',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (_analysisResult != null) ...[
                      _buildProbabilityBar(
                        'Happy / Cheerful',
                        '😊',
                        _analysisResult!.emotionProbabilities[
                                EmotionCategory.happy] ??
                            0.0,
                        AppColors.riskLow,
                      ),
                      const SizedBox(height: 8),
                      _buildProbabilityBar(
                        'Calm / Neutral',
                        '😌',
                        _analysisResult!.emotionProbabilities[
                                EmotionCategory.calmNeutral] ??
                            0.0,
                        AppColors.primary,
                      ),
                      const SizedBox(height: 8),
                      _buildProbabilityBar(
                        'Confused / Agitated',
                        '🤔',
                        _analysisResult!.emotionProbabilities[
                                EmotionCategory.confusedAgitated] ??
                            0.0,
                        AppColors.riskModerate,
                      ),
                      const SizedBox(height: 8),
                      _buildProbabilityBar(
                        'Fear / Anxious',
                        '😨',
                        _analysisResult!.emotionProbabilities[
                                EmotionCategory.anxious] ??
                            0.0,
                        AppColors.lilac,
                      ),
                      const SizedBox(height: 8),
                      _buildProbabilityBar(
                        'Sad / Depressed',
                        '😔',
                        _analysisResult!.emotionProbabilities[
                                EmotionCategory.sadDepressed] ??
                            0.0,
                        AppColors.riskHigh,
                      ),
                      const SizedBox(height: 12),

                      // Clinical Inference Insight
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          _analysisResult!.clinicalObservation,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.body,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Resident Face Selection & Live Camera Capture Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Live Face Capture & Test Input:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.muted,
                ),
              ),
              _buildSwitchChip(
                label: '😊 Happy Resident',
                asset: 'assets/images/landing/senior_happy_face.jpg',
              ),
              _buildSwitchChip(
                label: '😌 Calm Neutral',
                asset: 'assets/images/landing/senior_neutral_calm_face.jpg',
              ),
              _buildSwitchChip(
                label: '🤔 Confused Face',
                asset: 'assets/images/landing/senior_confused_face.jpg',
              ),
              _buildSwitchChip(
                label: '😨 Fear Face',
                asset: 'assets/images/landing/senior_fear_face.jpg',
              ),
              _buildSwitchChip(
                label: '😔 Sad / Depressed',
                asset: 'assets/images/landing/senior_sad_face.jpg',
              ),
              ElevatedButton.icon(
                onPressed: _captureLiveCameraPhoto,
                icon: const Icon(LucideIcons.camera, size: 14, color: Colors.white),
                label: const Text(
                  'Capture Live Photo',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProbabilityBar(
    String label,
    String emoji,
    double probability,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$emoji $label',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            Text(
              '${(probability * 100).toInt()}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: probability,
            minHeight: 6,
            backgroundColor: AppColors.surfaceSecondary,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchChip({required String label, required String asset}) {
    final isSelected = _selectedSampleAsset == asset;

    return InkWell(
      onTap: () => _runAiInference(asset),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.body,
          ),
        ),
      ),
    );
  }
}
