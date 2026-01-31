import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../models/challenge_models.dart';
import '../challenge_details_screen/challenge_details_screen.dart';

class SoloChallengeSuggestionsScreen extends StatefulWidget {
  final String craving;
  final int estimatedCalories;

  const SoloChallengeSuggestionsScreen({
    Key? key,
    required this.craving,
    this.estimatedCalories = 500,
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
  bool _isLoading = true;
  List<ChallengeData> _challenges = [];

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _loadChallenges();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadChallenges() async {
    // TODO: Implement LLM integration to generate challenges
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _challenges = _generateMockChallenges();
        _isLoading = false;
      });
    }
  }

  List<ChallengeData> _generateMockChallenges() {
    // Mock data - replace with actual LLM-generated challenges
    return [
      ChallengeData(
        id: '1',
        title: 'Quick Cardio Blast',
        description: 'Get your heart pumping with this energizing workout',
        activities: [
          'Jumping jacks - 3 sets of 30',
          'High knees - 2 minutes',
          'Burpees - 3 sets of 10',
        ],
        timeEstimate: '15 minutes',
        caloriesBurned: widget.estimatedCalories,
        difficulty: ChallengeDifficulty.medium,
        icon: Icons.fitness_center_rounded,
      ),
      ChallengeData(
        id: '2',
        title: 'Lower Body Power',
        description: 'Strengthen your legs and glutes',
        activities: [
          'Squats - 4 sets of 15',
          'Lunges - 3 sets of 12 each leg',
          'Wall sit - 3 sets of 45 seconds',
        ],
        timeEstimate: '20 minutes',
        caloriesBurned: widget.estimatedCalories,
        difficulty: ChallengeDifficulty.hard,
        icon: Icons.directions_run_rounded,
      ),
      ChallengeData(
        id: '3',
        title: 'Core Strengthener',
        description: 'Build a stronger core with these exercises',
        activities: [
          'Plank - 3 sets of 60 seconds',
          'Russian twists - 3 sets of 20',
          'Bicycle crunches - 3 sets of 15',
        ],
        timeEstimate: '12 minutes',
        caloriesBurned: widget.estimatedCalories,
        difficulty: ChallengeDifficulty.easy,
        icon: Icons.accessibility_new_rounded,
      ),
      ChallengeData(
        id: '4',
        title: 'Brisk Walk Challenge',
        description: 'Easy on the joints, great for burning calories',
        activities: [
          'Brisk walk - 25 minutes',
          'Include 2 minutes of light jogging every 5 minutes',
        ],
        timeEstimate: '25 minutes',
        caloriesBurned: widget.estimatedCalories,
        difficulty: ChallengeDifficulty.easy,
        icon: Icons.directions_walk_rounded,
      ),
    ];
  }

  void _onChallengeSelected(int index) {
    setState(() {
      _selectedChallengeIndex = index;
    });
  }

  void _confirmChallenge() {
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

    // Navigate to challenge details screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChallengeDetailsScreen(
          challenge: _challenges[_selectedChallengeIndex!],
          craving: widget.craving,
        ),
      ),
    );
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
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose Your Challenge',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 26 : 30,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1B5E20),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              // Challenge list
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
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
            onPressed: _confirmChallenge,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF66BB6A),
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: const Color(0xFF66BB6A).withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
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

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: 3,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.6),
                    Colors.white.withOpacity(0.3),
                  ],
                  stops: [
                    _shimmerController.value - 0.3,
                    _shimmerController.value,
                    _shimmerController.value + 0.3,
                  ].map((e) => e.clamp(0.0, 1.0)).toList(),
                ),
              ),
            );
          },
        );
      },
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
                // Activities
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF66BB6A).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What to do:',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF66BB6A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...challenge.activities.map((activity) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF66BB6A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  activity,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 13 : 14,
                                    color: const Color(0xFF1B5E20),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Time estimate and calories
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.access_time_rounded,
                      challenge.timeEstimate,
                      isSmallScreen,
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      Icons.local_fire_department_rounded,
                      '${challenge.caloriesBurned} cal',
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

  Widget _buildDifficultyBadge(ChallengeDifficulty difficulty, bool isSmallScreen) {
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
