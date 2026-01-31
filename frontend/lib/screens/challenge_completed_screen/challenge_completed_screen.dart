import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../services/api_service.dart';

// Challenge Completion & Rating Screen
class ChallengeCompletionScreen extends StatefulWidget {
  final String challengeType;
  final String foodName;
  final int caloriesSaved;
  final String challengeId;

  const ChallengeCompletionScreen({
    Key? key,
    required this.challengeType,
    required this.foodName,
    required this.caloriesSaved,
    required this.challengeId,
  }) : super(key: key);

  @override
  State<ChallengeCompletionScreen> createState() =>
      _ChallengeCompletionScreenState();
}

class _ChallengeCompletionScreenState extends State<ChallengeCompletionScreen>
    with SingleTickerProviderStateMixin {
  double _rating = 5.0;
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);

    try {
      final completionPercentage = (_rating * 10).toInt();

      final data = await ApiService().completeChallenge(
        widget.challengeId,
        completionPercentage,
      );

      if (!mounted) return;

      final pointsEarned = data['points_earned'] as int? ?? 0;
      final totalPoints = data['total_points'] as int? ?? 0;
      final rank = data['rank'] as String? ?? 'Bronze';

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultRewardScreen(
            rating: _rating,
            pointsEarned: pointsEarned,
            totalPoints: totalPoints,
            rank: rank,
            challengeType: widget.challengeType,
            foodName: widget.foodName,
            caloriesSaved: widget.caloriesSaved,
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
          content: Text('Failed to submit. Please try again.'),
          backgroundColor: Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF1B5E20)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 20.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Success icon
                Center(
                  child: Container(
                    width: isSmallScreen ? 100 : 120,
                    height: isSmallScreen ? 100 : 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF66BB6A),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF66BB6A).withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.challengeType == 'exercise'
                          ? Icons.directions_run_rounded
                          : Icons.eco_rounded,
                      size: isSmallScreen ? 55 : 65,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 24 : 32),

                // Title
                Text(
                  'Challenge Complete!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 26 : 30,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),

                // Subtitle
                Text(
                  'You earned your ${widget.foodName}!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 15 : 16,
                    color: const Color(0xFF1B5E20).withOpacity(0.6),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 32 : 40),

                // Rating section
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How did it feel?',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 17 : 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1B5E20),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 20 : 24),

                      // Rating slider
                      Row(
                        children: [
                          Text(
                            '1',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1B5E20).withOpacity(0.4),
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: const Color(0xFF66BB6A),
                                inactiveTrackColor:
                                    const Color(0xFF66BB6A).withOpacity(0.2),
                                thumbColor: const Color(0xFF66BB6A),
                                overlayColor:
                                    const Color(0xFF66BB6A).withOpacity(0.2),
                                trackHeight: 6,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 12,
                                ),
                              ),
                              child: Slider(
                                value: _rating,
                                min: 1,
                                max: 10,
                                divisions: 9,
                                onChanged: (value) {
                                  setState(() => _rating = value);
                                },
                              ),
                            ),
                          ),
                          Text(
                            '10',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1B5E20).withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),

                      // Rating value
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF66BB6A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_rating.toInt()}/10',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 22 : 24,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF66BB6A),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 20 : 24),

                      // Optional note
                      Text(
                        'Add a note (optional)',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _noteController,
                        maxLines: 3,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 15,
                        ),
                        decoration: InputDecoration(
                          hintText: 'How did you feel about this challenge?',
                          hintStyle: TextStyle(
                            color: const Color(0xFF1B5E20).withOpacity(0.4),
                            fontSize: isSmallScreen ? 13 : 14,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(14),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isSmallScreen ? 28 : 32),

                // Submit button
                SizedBox(
                  height: isSmallScreen ? 52 : 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF66BB6A),
                      disabledBackgroundColor:
                          const Color(0xFF66BB6A).withOpacity(0.6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Submit',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Result / Reward Screen
class ResultRewardScreen extends StatefulWidget {
  final double rating;
  final int pointsEarned;
  final int totalPoints;
  final String rank;
  final String challengeType;
  final String foodName;
  final int caloriesSaved;

  const ResultRewardScreen({
    Key? key,
    required this.rating,
    required this.pointsEarned,
    required this.totalPoints,
    required this.rank,
    required this.challengeType,
    required this.foodName,
    required this.caloriesSaved,
  }) : super(key: key);

  @override
  State<ResultRewardScreen> createState() => _ResultRewardScreenState();
}

class _ResultRewardScreenState extends State<ResultRewardScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );

    _scaleController.forward();
    _confettiController.repeat();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Confetti effect
              ...List.generate(20, (index) {
                return AnimatedBuilder(
                  animation: _confettiController,
                  builder: (context, child) {
                    final progress =
                        (_confettiController.value + (index * 0.05)) % 1.0;
                    return Positioned(
                      left: (index % 5) * (size.width / 5) + 20,
                      top: -50 + (progress * size.height),
                      child: Opacity(
                        opacity: 1 - progress,
                        child: Transform.rotate(
                          angle: progress * math.pi * 4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: [
                                Colors.yellow,
                                Colors.orange,
                                Colors.pink,
                                Colors.purple,
                                Colors.white
                              ][index % 5],
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),

              // Main content
              SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 20.0 : 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: isSmallScreen ? 30 : 40),

                      // Trophy animation
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Center(
                          child: Container(
                            width: isSmallScreen ? 120 : 140,
                            height: isSmallScreen ? 120 : 140,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 40,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.emoji_events_rounded,
                              size: isSmallScreen ? 70 : 80,
                              color: const Color(0xFFFFD700),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 28 : 32),

                      // Congratulations
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Text(
                              'Awesome!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 32 : 36,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'You earned your ${widget.foodName}!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 18,
                                color: Colors.white.withOpacity(0.95),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 32 : 40),

                      // Stats cards
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            // Points earned card
                            _buildStatCard(
                              icon: Icons.stars_rounded,
                              iconColor: const Color(0xFFFFB300),
                              title: 'Points Earned',
                              value: '+${widget.pointsEarned}',
                              subtitle: 'Rating: ${widget.rating.toInt()}/10',
                              isSmallScreen: isSmallScreen,
                            ),
                            const SizedBox(height: 16),

                            if (widget.caloriesSaved > 0)
                              _buildStatCard(
                                icon: Icons.local_fire_department_rounded,
                                iconColor: const Color(0xFFFF9800),
                                title: 'Calories',
                                value: '${widget.caloriesSaved}',
                                subtitle: 'Great effort!',
                                isSmallScreen: isSmallScreen,
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 20 : 24),

                      // Rank progress
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Rank',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 13 : 14,
                                      color: const Color(0xFF1B5E20)
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.rank,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 22 : 24,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFFFD700),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Total Points',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 13 : 14,
                                      color: const Color(0xFF1B5E20)
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${widget.totalPoints}',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 22 : 24,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF66BB6A),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 28 : 32),

                      // Action buttons
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SizedBox(
                          width: double.infinity,
                          height: isSmallScreen ? 52 : 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF66BB6A),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Back to Home',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: isSmallScreen ? 32 : 36,
            ),
          ),
          SizedBox(width: isSmallScreen ? 16 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    color: const Color(0xFF1B5E20).withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 28 : 32,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 13,
                    color: const Color(0xFF66BB6A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
