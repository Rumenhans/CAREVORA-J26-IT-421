import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Available games in the Memory Games suite.
enum MemoryGameType {
  none,
  sequence,
  pairs,
  items,
}

class MemoryGamesPage extends StatefulWidget {
  final MemoryGameType initialGame;
  final List<int>? initialSequence;

  const MemoryGamesPage({
    super.key,
    this.initialGame = MemoryGameType.none,
    this.initialSequence,
  });

  @override
  State<MemoryGamesPage> createState() => _MemoryGamesPageState();
}

class _MemoryGamesPageState extends State<MemoryGamesPage> {
  late MemoryGameType _activeGame;

  @override
  void initState() {
    super.initState();
    _activeGame = widget.initialGame;
  }

  void _selectGame(MemoryGameType game) {
    setState(() {
      _activeGame = game;
    });
  }

  void _backToHub() {
    setState(() {
      _activeGame = MemoryGameType.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildCurrentView(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_activeGame) {
      case MemoryGameType.sequence:
        return _SequenceGameView(
          key: const ValueKey('sequence_game'),
          onBack: _backToHub,
          initialSequence: widget.initialSequence,
        );
      case MemoryGameType.pairs:
        return _PairsGameView(
          key: const ValueKey('pairs_game'),
          onBack: _backToHub,
        );
      case MemoryGameType.items:
        return _ItemsGameView(
          key: const ValueKey('items_game'),
          onBack: _backToHub,
        );
      case MemoryGameType.none:
        return _buildHubView();
    }
  }

  Widget _buildHubView() {
    return Column(
      key: const ValueKey('hub_view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome & Cognitive Wellness Header Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      LucideIcons.gamepad2,
                      color: AppColors.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            Text(
                              'Memory Games',
                              style: AppTextStyles.h1.copyWith(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.lavenderBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.sparkles,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Gentle Brain Practice',
                                    style: AppTextStyles.caption.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Relax, have fun, and exercise your memory at your own comfortable pace. There are no timers, no scores recorded, and no penalties.',
                          style: AppTextStyles.body.copyWith(
                            fontSize: 15,
                            color: AppColors.body,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.lavenderBg.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.heart,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Friendly Note: These optional games are purely for fun and daily wellness. They are never graded or sent to clinical records.',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 13,
                          color: AppColors.navy,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        Text(
          'Choose a Game to Play',
          style: AppTextStyles.h2.copyWith(
            fontSize: 22,
            color: AppColors.navy,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Select any activity below. You can return here at any time.',
          style: AppTextStyles.body.copyWith(
            fontSize: 14,
            color: AppColors.muted,
          ),
        ),

        const SizedBox(height: 20),

        // Three Game Cards Layout
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildGameCard(
                      title: 'Remember the Sequence',
                      badge: 'Pattern Recall',
                      description:
                          'A sequence of colorful numbered tiles will appear. Memorize the order and tap them back in the exact same pattern.',
                      icon: LucideIcons.sparkles,
                      accentColor: AppColors.primary,
                      features: const [
                        'Starts with 3 easy tiles',
                        'Expands as you succeed',
                        'Replay the pattern anytime',
                      ],
                      buttonText: 'Play Sequence',
                      onPlay: () => _selectGame(MemoryGameType.sequence),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildGameCard(
                      title: 'Find the Matching Pairs',
                      badge: 'Card Matching',
                      description:
                          'Turn over large, cheerful cards two at a time to discover matching pairs of familiar pictures.',
                      icon: LucideIcons.puzzle,
                      accentColor: const Color(0xFF0D9488),
                      features: const [
                        'Familiar friendly pictures',
                        'Large, easy-to-tap cards',
                        'Play at your leisure',
                      ],
                      buttonText: 'Play Matching Pairs',
                      onPlay: () => _selectGame(MemoryGameType.pairs),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildGameCard(
                      title: 'Remember the Items',
                      badge: 'Object Recall',
                      description:
                          'Take a gentle look at a few familiar objects, then test your memory by picking them out from a larger group.',
                      icon: LucideIcons.bookOpen,
                      accentColor: const Color(0xFFE88BC4),
                      features: const [
                        'Simple everyday objects',
                        'Take all the time you need',
                        'Warm, encouraging feedback',
                      ],
                      buttonText: 'Play Remember Items',
                      onPlay: () => _selectGame(MemoryGameType.items),
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildGameCard(
                    title: 'Remember the Sequence',
                    badge: 'Pattern Recall',
                    description:
                        'A sequence of colorful numbered tiles will appear. Memorize the order and tap them back in the exact same pattern.',
                    icon: LucideIcons.sparkles,
                    accentColor: AppColors.primary,
                    features: const [
                      'Starts with 3 easy tiles',
                      'Expands as you succeed',
                      'Replay the pattern anytime',
                    ],
                    buttonText: 'Play Sequence',
                    onPlay: () => _selectGame(MemoryGameType.sequence),
                  ),
                  const SizedBox(height: 18),
                  _buildGameCard(
                    title: 'Find the Matching Pairs',
                    badge: 'Card Matching',
                    description:
                        'Turn over large, cheerful cards two at a time to discover matching pairs of familiar pictures.',
                    icon: LucideIcons.puzzle,
                    accentColor: const Color(0xFF0D9488),
                    features: const [
                      'Familiar friendly pictures',
                      'Large, easy-to-tap cards',
                      'Play at your leisure',
                    ],
                    buttonText: 'Play Matching Pairs',
                    onPlay: () => _selectGame(MemoryGameType.pairs),
                  ),
                  const SizedBox(height: 18),
                  _buildGameCard(
                    title: 'Remember the Items',
                    badge: 'Object Recall',
                    description:
                        'Take a gentle look at a few familiar objects, then test your memory by picking them out from a larger group.',
                    icon: LucideIcons.bookOpen,
                    accentColor: const Color(0xFFE88BC4),
                    features: const [
                      'Simple everyday objects',
                      'Take all the time you need',
                      'Warm, encouraging feedback',
                    ],
                    buttonText: 'Play Remember Items',
                    onPlay: () => _selectGame(MemoryGameType.items),
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildGameCard({
    required String title,
    required String badge,
    required String description,
    required IconData icon,
    required Color accentColor,
    required List<String> features,
    required String buttonText,
    required VoidCallback onPlay,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor, size: 26),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  badge,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                    color: AppColors.body,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: AppTextStyles.h3.copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: AppTextStyles.body.copyWith(
              fontSize: 14,
              color: AppColors.body,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: features.map((feature) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.check,
                      size: 16,
                      color: AppColors.riskLow,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 13,
                          color: AppColors.body,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onPlay,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.gamepad2, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      buttonText,
                      style: AppTextStyles.button.copyWith(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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

// ==============================================================================
// GAME 1: REMEMBER THE SEQUENCE
// ==============================================================================

class _SequenceGameView extends StatefulWidget {
  final VoidCallback onBack;
  final List<int>? initialSequence;

  const _SequenceGameView({
    super.key,
    required this.onBack,
    this.initialSequence,
  });

  @override
  State<_SequenceGameView> createState() => _SequenceGameViewState();
}

enum _SeqPhase {
  showing,
  input,
  success,
  retry,
}

class _SequenceTileData {
  final int id;
  final String label;
  final Color color;
  final IconData icon;

  const _SequenceTileData({
    required this.id,
    required this.label,
    required this.color,
    required this.icon,
  });
}

class _SequenceGameViewState extends State<_SequenceGameView> {
  static const List<_SequenceTileData> _tiles = [
    _SequenceTileData(
      id: 0,
      label: 'Violet 1',
      color: Color(0xFF7C3AED),
      icon: Icons.looks_one_rounded,
    ),
    _SequenceTileData(
      id: 1,
      label: 'Blue 2',
      color: Color(0xFF2563EB),
      icon: Icons.looks_two_rounded,
    ),
    _SequenceTileData(
      id: 2,
      label: 'Green 3',
      color: Color(0xFF16A34A),
      icon: Icons.looks_3_rounded,
    ),
    _SequenceTileData(
      id: 3,
      label: 'Orange 4',
      color: Color(0xFFEA580C),
      icon: Icons.looks_4_rounded,
    ),
  ];

  int _currentLevel = 1;
  int _sequenceLength = 3;
  List<int> _targetSequence = [];
  List<int> _userTaps = [];
  _SeqPhase _phase = _SeqPhase.showing;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    if (widget.initialSequence != null && widget.initialSequence!.isNotEmpty) {
      _sequenceLength = widget.initialSequence!.length;
      _targetSequence = List<int>.from(widget.initialSequence!);
      _userTaps = [];
      _phase = _SeqPhase.showing;
    } else {
      _startNewRound();
    }
  }

  void _startNewRound() {
    final List<int> seq = [];
    for (int i = 0; i < _sequenceLength; i++) {
      seq.add(_random.nextInt(_tiles.length));
    }
    setState(() {
      _targetSequence = seq;
      _userTaps = [];
      _phase = _SeqPhase.showing;
    });
  }

  void _startInputPhase() {
    setState(() {
      _userTaps = [];
      _phase = _SeqPhase.input;
    });
  }

  void _replaySequence() {
    setState(() {
      _userTaps = [];
      _phase = _SeqPhase.showing;
    });
  }

  void _resetToBeginning() {
    setState(() {
      _currentLevel = 1;
      _sequenceLength = 3;
    });
    _startNewRound();
  }

  void _onTileTap(int tileId) {
    if (_phase != _SeqPhase.input) return;

    final nextIndex = _userTaps.length;
    if (nextIndex >= _targetSequence.length) return;

    final expected = _targetSequence[nextIndex];
    final updatedTaps = List<int>.from(_userTaps)..add(tileId);

    if (tileId != expected) {
      setState(() {
        _userTaps = updatedTaps;
        _phase = _SeqPhase.retry;
      });
      return;
    }

    if (updatedTaps.length == _targetSequence.length) {
      setState(() {
        _userTaps = updatedTaps;
        _phase = _SeqPhase.success;
      });
    } else {
      setState(() {
        _userTaps = updatedTaps;
      });
    }
  }

  void _advanceToNextLevel() {
    setState(() {
      _currentLevel++;
      _sequenceLength++;
    });
    _startNewRound();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGameNavBar(
          gameTitle: 'Remember the Sequence',
          onBack: widget.onBack,
          onReset: _resetToBeginning,
          statusBadge: 'Level $_currentLevel ($_sequenceLength Tiles)',
        ),
        const SizedBox(height: 20),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildInstructionBanner(),
              const SizedBox(height: 28),

              if (_phase == _SeqPhase.showing) ...[
                _buildSequencePreview(),
                const SizedBox(height: 28),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    key: const ValueKey('start_sequence_input_button'),
                    onPressed: _startInputPhase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'I Remember! Hide & Start My Turn',
                      style: AppTextStyles.button.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ] else if (_phase == _SeqPhase.input) ...[
                _buildProgressSlots(),
                const SizedBox(height: 32),
                _buildInteractiveTilesGrid(),
                const SizedBox(height: 28),
                OutlinedButton.icon(
                  key: const ValueKey('replay_sequence_button'),
                  onPressed: _replaySequence,
                  icon: const Icon(LucideIcons.rotateCcw, size: 18),
                  label: const Text(
                    'Replay Sequence to Watch Again',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ] else if (_phase == _SeqPhase.success) ...[
                _buildSuccessView(),
              ] else if (_phase == _SeqPhase.retry) ...[
                _buildRetryView(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionBanner() {
    String title = '';
    String subtitle = '';
    Color bannerBg = AppColors.lavenderBg;
    Color iconColor = AppColors.primary;
    IconData icon = LucideIcons.sparkles;

    switch (_phase) {
      case _SeqPhase.showing:
        title = 'Watch & Remember the Sequence';
        subtitle =
            'Take your time to memorize the colors and numbers shown below. When ready, tap the button to begin.';
        break;
      case _SeqPhase.input:
        title = 'Your Turn: Tap the Tiles in Order';
        subtitle =
            'Tap the colored circles below in the same sequence you just saw.';
        break;
      case _SeqPhase.success:
        title = 'Well done! Perfect Memory!';
        subtitle =
            'You correctly recalled all $_sequenceLength tiles in the sequence. Would you like to advance to the next level?';
        bannerBg = AppColors.riskLowBg;
        iconColor = AppColors.riskLow;
        icon = LucideIcons.check;
        break;
      case _SeqPhase.retry:
        title = 'Good try!';
        subtitle =
            'Memory practice takes patience. You can replay the sequence to take another look and try again!';
        bannerBg = const Color(0xFFFEF3DC);
        iconColor = AppColors.riskModerate;
        icon = LucideIcons.rotateCcw;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.15),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.h3.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    color: AppColors.body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSequencePreview() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: List.generate(_targetSequence.length, (index) {
        final tile = _tiles[_targetSequence[index]];
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Step ${index + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: tile.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: tile.color.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(tile.icon, size: 44, color: Colors.white),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tile.label,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
                fontSize: 13,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildProgressSlots() {
    return Column(
      children: [
        Text(
          'Progress: ${_userTaps.length} of ${_targetSequence.length} tiles tapped',
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.muted,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 14,
          children: List.generate(_targetSequence.length, (index) {
            final isFilled = index < _userTaps.length;
            if (isFilled) {
              final tile = _tiles[_userTaps[index]];
              return Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: tile.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: tile.color.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(tile.icon, size: 30, color: Colors.white),
                ),
              );
            } else {
              return Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              );
            }
          }),
        ),
      ],
    );
  }

  Widget _buildInteractiveTilesGrid() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 20,
      runSpacing: 20,
      children: _tiles.map((tile) {
        return InkWell(
          key: ValueKey('sequence_tile_${tile.id}'),
          onTap: () => _onTileTap(tile.id),
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: tile.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: tile.color.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(tile.icon, size: 42, color: Colors.white),
                const SizedBox(height: 2),
                Text(
                  tile.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        const Icon(
          LucideIcons.sparkles,
          size: 54,
          color: AppColors.riskLow,
        ),
        const SizedBox(height: 14),
        Text(
          'Well done!',
          style: AppTextStyles.h2.copyWith(
            color: AppColors.riskLow,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'You remembered the entire sequence of $_sequenceLength tiles accurately!',
          style: AppTextStyles.body.copyWith(
            fontSize: 16,
            color: AppColors.body,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              key: const ValueKey('next_level_button'),
              onPressed: _advanceToNextLevel,
              icon: const Icon(LucideIcons.sparkles, size: 18),
              label: Text(
                'Next Round (${_sequenceLength + 1} Tiles)',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              key: const ValueKey('replay_same_level_button'),
              onPressed: _startNewRound,
              icon: const Icon(LucideIcons.rotateCcw, size: 18),
              label: const Text(
                'Replay Current Level',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRetryView() {
    return Column(
      children: [
        const Icon(
          LucideIcons.rotateCcw,
          size: 50,
          color: AppColors.riskModerate,
        ),
        const SizedBox(height: 14),
        Text(
          'Good try!',
          style: AppTextStyles.h2.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Don\'t worry at all! Memory takes practice. Would you like to play again?',
          style: AppTextStyles.body.copyWith(
            fontSize: 16,
            color: AppColors.body,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              key: const ValueKey('try_again_button'),
              onPressed: _replaySequence,
              icon: const Icon(LucideIcons.rotateCcw, size: 18),
              label: const Text(
                'Watch & Try Again',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              key: const ValueKey('reset_level_1_button'),
              onPressed: _resetToBeginning,
              icon: const Icon(LucideIcons.rotateCcw, size: 18),
              label: const Text(
                'Restart from Level 1',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ==============================================================================
// GAME 2: FIND THE MATCHING PAIRS
// ==============================================================================

class _PairsGameView extends StatefulWidget {
  final VoidCallback onBack;

  const _PairsGameView({super.key, required this.onBack});

  @override
  State<_PairsGameView> createState() => _PairsGameViewState();
}

class _CardSymbol {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const _CardSymbol({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _CardModel {
  final int id;
  final _CardSymbol symbol;
  bool isMatched = false;

  _CardModel({
    required this.id,
    required this.symbol,
  });
}

class _PairsGameViewState extends State<_PairsGameView> {
  static const List<_CardSymbol> _symbols = [
    _CardSymbol(
      key: 'apple',
      label: 'Apple',
      icon: Icons.apple_rounded,
      color: Color(0xFFDC2626),
    ),
    _CardSymbol(
      key: 'sun',
      label: 'Sunshine',
      icon: LucideIcons.sun,
      color: Color(0xFFD97706),
    ),
    _CardSymbol(
      key: 'flower',
      label: 'Flower',
      icon: LucideIcons.flower,
      color: Color(0xFFDB2777),
    ),
    _CardSymbol(
      key: 'cup',
      label: 'Tea Cup',
      icon: LucideIcons.coffee,
      color: Color(0xFF854D0E),
    ),
    _CardSymbol(
      key: 'home',
      label: 'Cozy Home',
      icon: Icons.home_rounded,
      color: Color(0xFF0D9488),
    ),
    _CardSymbol(
      key: 'star',
      label: 'Golden Star',
      icon: Icons.star_rounded,
      color: Color(0xFFCA8A04),
    ),
  ];

  late List<_CardModel> _cards;
  final List<int> _flippedIndices = [];
  int _pairsFound = 0;
  bool _isProcessing = false;
  Timer? _flipBackTimer;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  @override
  void dispose() {
    _flipBackTimer?.cancel();
    super.dispose();
  }

  void _startNewGame() {
    _flipBackTimer?.cancel();
    final List<_CardModel> list = [];
    int idCounter = 0;
    for (final sym in _symbols) {
      list.add(_CardModel(id: idCounter++, symbol: sym));
      list.add(_CardModel(id: idCounter++, symbol: sym));
    }
    list.shuffle(Random());

    setState(() {
      _cards = list;
      _flippedIndices.clear();
      _pairsFound = 0;
      _isProcessing = false;
    });
  }

  void _onCardTap(int index) {
    if (_isProcessing) return;
    if (_cards[index].isMatched) return;
    if (_flippedIndices.contains(index)) return;

    if (_flippedIndices.isEmpty) {
      setState(() {
        _flippedIndices.add(index);
      });
    } else if (_flippedIndices.length == 1) {
      final firstIndex = _flippedIndices[0];
      final firstCard = _cards[firstIndex];
      final secondCard = _cards[index];

      setState(() {
        _flippedIndices.add(index);
      });

      if (firstCard.symbol.key == secondCard.symbol.key) {
        // MATCH!
        setState(() {
          firstCard.isMatched = true;
          secondCard.isMatched = true;
          _pairsFound++;
          _flippedIndices.clear();
        });
      } else {
        // MISMATCH: allow elder plenty of time to view both cards
        _isProcessing = true;
        _flipBackTimer = Timer(const Duration(milliseconds: 1200), () {
          if (mounted) {
            setState(() {
              _flippedIndices.clear();
              _isProcessing = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGameCompleted = _pairsFound == _symbols.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGameNavBar(
          gameTitle: 'Find the Matching Pairs',
          onBack: widget.onBack,
          onReset: _startNewGame,
          statusBadge: 'Pairs Found: $_pairsFound / ${_symbols.length}',
        ),
        const SizedBox(height: 20),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Instruction Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isGameCompleted
                      ? AppColors.riskLowBg
                      : AppColors.lavenderBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isGameCompleted
                        ? AppColors.riskLow.withValues(alpha: 0.3)
                        : AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isGameCompleted
                          ? LucideIcons.sparkles
                          : LucideIcons.puzzle,
                      color: isGameCompleted
                          ? AppColors.riskLow
                          : AppColors.primary,
                      size: 26,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isGameCompleted
                                ? 'Well done! You found all the matching pairs!'
                                : 'Tap any two cards to discover matching pairs.',
                            style: AppTextStyles.h4.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isGameCompleted
                                ? 'Fantastic work! Would you like to play again?'
                                : 'Take your time. There are no timers or rush.',
                            style: AppTextStyles.body.copyWith(
                              fontSize: 13.5,
                              color: AppColors.body,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Cards Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 700 ? 4 : 3;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _cards.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    itemBuilder: (context, index) {
                      final card = _cards[index];
                      final isFlipped =
                          card.isMatched || _flippedIndices.contains(index);

                      return InkWell(
                        key: ValueKey('pair_card_$index'),
                        onTap: () => _onCardTap(index),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: isFlipped
                                ? (card.isMatched
                                    ? AppColors.riskLowBg
                                    : Colors.white)
                                : AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isFlipped
                                  ? (card.isMatched
                                      ? AppColors.riskLow
                                      : AppColors.primary)
                                  : AppColors.border,
                              width: isFlipped ? 2 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.navy.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: isFlipped
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      card.symbol.icon,
                                      size: 38,
                                      color: card.symbol.color,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      card.symbol.label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: card.isMatched
                                            ? AppColors.riskLow
                                            : AppColors.navy,
                                      ),
                                    ),
                                    if (card.isMatched) ...[
                                      const SizedBox(height: 2),
                                      const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            LucideIcons.check,
                                            size: 12,
                                            color: AppColors.riskLow,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Matched',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.riskLow,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      LucideIcons.sparkles,
                                      size: 32,
                                      color: AppColors.primary
                                          .withValues(alpha: 0.6),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Tap Card',
                                      style: AppTextStyles.caption.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 28),

              if (isGameCompleted) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      key: const ValueKey('play_pairs_again_button'),
                      onPressed: _startNewGame,
                      icon: const Icon(LucideIcons.rotateCcw, size: 18),
                      label: const Text(
                        'Play Again with Fresh Cards',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                OutlinedButton.icon(
                  key: const ValueKey('restart_pairs_button'),
                  onPressed: _startNewGame,
                  icon: const Icon(LucideIcons.rotateCcw, size: 18),
                  label: const Text(
                    'Shuffle & Restart Game',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ==============================================================================
// GAME 3: REMEMBER THE ITEMS
// ==============================================================================

class _ItemsGameView extends StatefulWidget {
  final VoidCallback onBack;

  const _ItemsGameView({super.key, required this.onBack});

  @override
  State<_ItemsGameView> createState() => _ItemsGameViewState();
}

enum _ItemPhase {
  memorize,
  select,
  feedback,
}

class _ObjectItem {
  final int id;
  final String name;
  final IconData icon;
  final Color color;

  const _ObjectItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class _ItemsGameViewState extends State<_ItemsGameView> {
  static const List<_ObjectItem> _itemPool = [
    _ObjectItem(
      id: 1,
      name: 'Red Apple',
      icon: Icons.apple_rounded,
      color: Color(0xFFDC2626),
    ),
    _ObjectItem(
      id: 2,
      name: 'Story Book',
      icon: LucideIcons.bookOpen,
      color: Color(0xFF4F46E5),
    ),
    _ObjectItem(
      id: 3,
      name: 'Pink Flower',
      icon: LucideIcons.flower,
      color: Color(0xFFDB2777),
    ),
    _ObjectItem(
      id: 4,
      name: 'Wall Clock',
      icon: LucideIcons.clock,
      color: Color(0xFFD97706),
    ),
    _ObjectItem(
      id: 5,
      name: 'Tea Cup',
      icon: LucideIcons.coffee,
      color: Color(0xFF854D0E),
    ),
    _ObjectItem(
      id: 6,
      name: 'Cozy House',
      icon: Icons.home_rounded,
      color: Color(0xFF0D9488),
    ),
    _ObjectItem(
      id: 7,
      name: 'Bright Sun',
      icon: LucideIcons.sun,
      color: Color(0xFFEAB308),
    ),
    _ObjectItem(
      id: 8,
      name: 'Loving Heart',
      icon: LucideIcons.heart,
      color: Color(0xFFE11D48),
    ),
    _ObjectItem(
      id: 9,
      name: 'Brass Bell',
      icon: LucideIcons.bell,
      color: Color(0xFFF97316),
    ),
    _ObjectItem(
      id: 10,
      name: 'Brass Key',
      icon: Icons.vpn_key_rounded,
      color: Color(0xFF0284C7),
    ),
  ];

  late List<_ObjectItem> _targetItems;
  late List<_ObjectItem> _displayPool;
  final Set<int> _selectedIds = {};
  _ItemPhase _phase = _ItemPhase.memorize;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _startNewRound();
  }

  void _startNewRound() {
    final shuffled = List<_ObjectItem>.from(_itemPool)..shuffle(_random);
    final targets = shuffled.take(4).toList();
    final remaining = shuffled.skip(4).take(4).toList();
    final combined = [...targets, ...remaining]..shuffle(_random);

    setState(() {
      _targetSequenceReset(targets, combined);
    });
  }

  void _targetSequenceReset(
    List<_ObjectItem> targets,
    List<_ObjectItem> combined,
  ) {
    _targetItems = targets;
    _displayPool = combined;
    _selectedIds.clear();
    _phase = _ItemPhase.memorize;
  }

  void _startSelectionPhase() {
    setState(() {
      _selectedIds.clear();
      _phase = _ItemPhase.select;
    });
  }

  void _toggleItemSelection(int id) {
    if (_phase != _ItemPhase.select) return;
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _checkAnswers() {
    setState(() {
      _phase = _ItemPhase.feedback;
    });
  }

  void _peekOriginalItems() {
    setState(() {
      _phase = _ItemPhase.memorize;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGameNavBar(
          gameTitle: 'Remember the Items',
          onBack: widget.onBack,
          onReset: _startNewRound,
          statusBadge: _phase == _ItemPhase.memorize
              ? 'Study 4 Items'
              : (_phase == _ItemPhase.select
                  ? 'Selected: ${_selectedIds.length} of 4'
                  : 'Results Check'),
        ),
        const SizedBox(height: 20),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildInstructionBanner(),
              const SizedBox(height: 28),

              if (_phase == _ItemPhase.memorize) ...[
                _buildMemorizeView(),
              ] else if (_phase == _ItemPhase.select) ...[
                _buildSelectionView(),
              ] else if (_phase == _ItemPhase.feedback) ...[
                _buildFeedbackView(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionBanner() {
    String title = '';
    String subtitle = '';
    Color bg = AppColors.lavenderBg;
    Color iconColor = AppColors.primary;
    IconData icon = LucideIcons.bookOpen;

    switch (_phase) {
      case _ItemPhase.memorize:
        title = 'Take a look at these 4 familiar items';
        subtitle =
            'Look at each object carefully. Whenever you feel ready, tap the button below to see if you can pick them out.';
        break;
      case _ItemPhase.select:
        title = 'Which items do you remember seeing?';
        subtitle =
            'Tap all 4 items you recall from the previous screen, then tap Check Answers.';
        break;
      case _ItemPhase.feedback:
        final correctCount =
            _selectedIds.where((id) => _targetItems.any((t) => t.id == id)).length;
        if (correctCount == _targetItems.length) {
          title = 'Well done! All items correct!';
          subtitle =
              'You remembered every single item with great accuracy! Would you like to play again with a new set?';
          bg = AppColors.riskLowBg;
          iconColor = AppColors.riskLow;
          icon = LucideIcons.check;
        } else {
          title = 'Good try!';
          subtitle =
              'You remembered $correctCount out of ${_targetItems.length} items correctly. Great mental exercise! Would you like to play again?';
          bg = const Color(0xFFFEF3DC);
          iconColor = AppColors.riskModerate;
          icon = LucideIcons.rotateCcw;
        }
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.15),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.h3.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    color: AppColors.body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemorizeView() {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 20,
          runSpacing: 20,
          children: _targetItems.map((item) {
            return Container(
              width: 150,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: item.color.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(item.icon, size: 36, color: item.color),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.name,
                    style: AppTextStyles.h4.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            key: const ValueKey('ready_items_button'),
            onPressed: _startSelectionPhase,
            icon: const Icon(LucideIcons.check, size: 18),
            label: const Text(
              'I Remember These Items! Continue',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionView() {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: _displayPool.map((item) {
            final isSelected = _selectedIds.contains(item.id);
            return InkWell(
              key: ValueKey('item_option_${item.id}'),
              onTap: () => _toggleItemSelection(item.id),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 140,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primarySoft : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.navy.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.muted,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  LucideIcons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Icon(item.icon, size: 36, color: item.color),
                    const SizedBox(height: 8),
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        color:
                            isSelected ? AppColors.primary : AppColors.navy,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              key: const ValueKey('check_answers_button'),
              onPressed: _selectedIds.isNotEmpty ? _checkAnswers : null,
              icon: const Icon(LucideIcons.check, size: 18),
              label: Text(
                'Check My Answers (${_selectedIds.length} Picked)',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              key: const ValueKey('peek_items_button'),
              onPressed: _peekOriginalItems,
              icon: const Icon(LucideIcons.rotateCcw, size: 18),
              label: const Text(
                'Peek at Original Items',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeedbackView() {
    return Column(
      children: [
        Text(
          'Review Your Answers',
          style: AppTextStyles.h3.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 16),

        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: _displayPool.map((item) {
            final isTarget = _targetItems.any((t) => t.id == item.id);
            final isSelected = _selectedIds.contains(item.id);

            Color borderColor = AppColors.border;
            Color bgColor = Colors.white;
            String badgeText = '';
            Color badgeColor = AppColors.muted;

            if (isTarget && isSelected) {
              borderColor = AppColors.riskLow;
              bgColor = AppColors.riskLowBg;
              badgeText = 'Correct! ✅';
              badgeColor = AppColors.riskLow;
            } else if (isTarget && !isSelected) {
              borderColor = AppColors.riskModerate;
              bgColor = const Color(0xFFFEF3DC);
              badgeText = 'Original Item (Missed)';
              badgeColor = AppColors.riskModerate;
            } else if (!isTarget && isSelected) {
              borderColor = AppColors.riskHigh.withValues(alpha: 0.6);
              bgColor = const Color(0xFFFDE8E8);
              badgeText = 'Not in Group';
              badgeColor = AppColors.riskHigh;
            }

            return Container(
              width: 145,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Column(
                children: [
                  Icon(item.icon, size: 34, color: item.color),
                  const SizedBox(height: 6),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (badgeText.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 32),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              key: const ValueKey('play_items_new_round_button'),
              onPressed: _startNewRound,
              icon: const Icon(LucideIcons.sparkles, size: 18),
              label: const Text(
                'Play Again with New Items',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              key: const ValueKey('try_same_items_button'),
              onPressed: _startSelectionPhase,
              icon: const Icon(LucideIcons.rotateCcw, size: 18),
              label: const Text(
                'Try Same Items Again',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ==============================================================================
// COMMON GAME TOP NAVIGATION BAR
// ==============================================================================

Widget _buildGameNavBar({
  required String gameTitle,
  required VoidCallback onBack,
  required VoidCallback onReset,
  required String statusBadge,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              ElevatedButton.icon(
                key: const ValueKey('back_to_games_button'),
                onPressed: onBack,
                icon: const Icon(LucideIcons.arrowLeft, size: 18),
                label: const Text(
                  'All Games',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lavenderBg,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Flexible(
                child: Text(
                  gameTitle,
                  style: AppTextStyles.h3.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusBadge,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              key: const ValueKey('reset_game_nav_button'),
              onPressed: onReset,
              icon: const Icon(LucideIcons.rotateCcw, size: 20),
              tooltip: 'Restart Game',
              color: AppColors.muted,
            ),
          ],
        ),
      ],
    ),
  );
}
