import 'package:flutter/material.dart';

import '../../models/challenge_models.dart';
import '../../services/api_service.dart';
import '../challenge_details_screen/challenge_details_screen.dart';

class SoloChallengeSuggestionsScreen extends StatefulWidget {
  final String craving;
  final int estimatedCalories;
  final String sessionId;
  final List<ChallengeData> challenges;
  final int regenerationsRemaining;

  const SoloChallengeSuggestionsScreen({
    Key? key,
    required this.craving,
    this.estimatedCalories = 0,
    required this.sessionId,
    required this.challenges,
    this.regenerationsRemaining = 3,
  }) : super(key: key);

  @override
  State<SoloChallengeSuggestionsScreen> createState() =>
      _SoloChallengeSuggestionsScreenState();
}

class _SoloChallengeSuggestionsScreenState
    extends State<SoloChallengeSuggestionsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  int? _selectedChallengeIndex;
  bool _isConfirming = false;
  bool _isRegenerating = false;
  late List<ChallengeData> _challenges;
  late int _regenerationsRemaining;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _challenges = List.from(widget.challenges);
    _regenerationsRemaining = widget.regenerationsRemaining;
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _onChallengeSelected(int index) {
    setState(() {
      _selectedChallengeIndex = index;
    });
  }

  Future<void> _regenerateChallenges() async {
    if (_regenerationsRemaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No more re-prompts available!'),
          backgroundColor: Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isRegenerating = true;
    });

    try {
      final data = await ApiService().regenerateChallenges(widget.sessionId);

      if (!mounted) return;

      final challengesList = (data['challenges'] as List?) ?? [];
      final newChallenges = challengesList
          .asMap()
          .entries
          .map((e) => ChallengeData.fromApiChallenge(
                e.value as Map<String, dynamic>,
                e.key,
              ))
          .toList();

      setState(() {
        _challenges = newChallenges;
        _regenerationsRemaining = data['regenerations_remaining'] as int? ?? 0;
        _selectedChallengeIndex = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New challenges loaded! 💪'),
          backgroundColor: Color(0xFF66BB6A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to get new challenges'),
          backgroundColor: Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRegenerating = false;
        });
      }
    }
  }

  Future<void> _confirmChallenge() async {
    if (_selectedChallengeIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a challenge first!'),
          backgroundColor: Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isConfirming = true);

    try {
      final challenge = _challenges[_selectedChallengeIndex!];

      final data = await ApiService().selectChallenge(
        widget.sessionId,
        challenge.description,
        int.tryParse(challenge.timeEstimate.replaceAll(RegExp(r'[^0-9]'), '')) ?? 15,
      );

      if (!mounted) return;

      final challengeId = data['challenge_id'] as String;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChallengeDetailsScreen(
            challenge: challenge,
            craving: widget.craving,
            challengeId: challengeId,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          backgroundColor: Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF8F9FA),
              const Color(0xFFE8F5E9).withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Craving: ${widget.craving}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 18 : 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1B5E20),
                            ),
                          ),
                          if (widget.estimatedCalories > 0)
                            Text(
                              '~${widget.estimatedCalories} calories',
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF1B5E20).withOpacity(0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Title & Regenerate button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Choose Your Challenge',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 24 : 28,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1B5E20),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    // Regenerate button
                    GestureDetector(
                      onTap: _isRegenerating || _regenerationsRemaining <= 0
                          ? null
                          : _regenerateChallenges,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _regenerationsRemaining > 0
                              ? const Color(0xFF66BB6A).withOpacity(0.15)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _regenerationsRemaining > 0
                                ? const Color(0xFF66BB6A).withOpacity(0.3)
                                : Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isRegenerating)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF66BB6A),
                                ),
                              )
                            else
                              Icon(
                                Icons.refresh_rounded,
                                size: 18,
                                color: _regenerationsRemaining > 0
                                    ? const Color(0xFF66BB6A)
                                    : Colors.grey,
                              ),
                            const SizedBox(width: 6),
                            Text(
                              '$_regenerationsRemaining left',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _regenerationsRemaining > 0
                                    ? const Color(0xFF66BB6A)
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Challenge list
              Expanded(
                child: _challenges.isEmpty
                    ? Center(
                        child: Text(
                          'No challenges available',
                          style: TextStyle(
                            fontSize: 16,
                            color: const Color(0xFF1B5E20).withOpacity(0.6),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                        itemCount: _challenges.length,
                        itemBuilder: (context, index) {
                          return _buildChallengeCard(
                            _challenges[index],
                            index,
                            isSmallScreen,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      // Floating action button
      floatingActionButton: _selectedChallengeIndex != null
          ? TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                height: 56,
                child: ElevatedButton(
                  onPressed: _isConfirming ? null : _confirmChallenge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF66BB6A),
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: const Color(0xFF66BB6A).withOpacity(0.4),
                    disabledBackgroundColor: const Color(0xFF66BB6A).withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isConfirming
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue with Challenge',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 22),
                          ],
                        ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildChallengeCard(
    ChallengeData challenge,
    int index,
    bool isSmallScreen,
  ) {
    final isSelected = _selectedChallengeIndex == index;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _onChallengeSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF66BB6A)
                  : const Color(0xFF66BB6A).withOpacity(0.1),
              width: isSelected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFF66BB6A).withOpacity(0.2)
                    : const Color(0xFF66BB6A).withOpacity(0.05),
                blurRadius: isSelected ? 20 : 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon
                    Container(
                      width: isSmallScreen ? 50 : 56,
                      height: isSmallScreen ? 50 : 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF66BB6A).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        challenge.icon,
                        size: isSmallScreen ? 26 : 30,
                        color: const Color(0xFF66BB6A),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title and difficulty
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challenge.title,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 18 : 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1B5E20),
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildDifficultyBadge(
                            challenge.difficulty,
                            isSmallScreen,
                          ),
                        ],
                      ),
                    ),
                    // Selection indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? const Color(0xFF66BB6A)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF66BB6A)
                              : const Color(0xFF66BB6A).withOpacity(0.3),
                          width: 2.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Description
                Text(
                  challenge.description,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 15,
                    color: const Color(0xFF1B5E20).withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                // Time estimate
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.access_time_rounded,
                      challenge.timeEstimate,
                      isSmallScreen,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(
      ChallengeDifficulty difficulty, bool isSmallScreen) {
    Color color;
    String label;

    switch (difficulty) {
      case ChallengeDifficulty.easy:
        color = const Color(0xFF4CAF50);
        label = 'Easy';
        break;
      case ChallengeDifficulty.medium:
        color = const Color(0xFFFF9800);
        label = 'Medium';
        break;
      case ChallengeDifficulty.hard:
        color = const Color(0xFFEF5350);
        label = 'Hard';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: isSmallScreen ? 11 : 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF66BB6A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isSmallScreen ? 16 : 18,
            color: const Color(0xFF66BB6A),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1B5E20),
            ),
          ),
        ],
      ),
    );
  }
}
