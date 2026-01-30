import 'package:flutter/material.dart';
import 'dart:math' as math;

// Challenge Completion & Rating Screen
class ChallengeCompletionScreen extends StatefulWidget {
  final String challengeType; // 'exercise' or 'healthier'
  final String foodName;
  final int caloriesSaved;

  const ChallengeCompletionScreen({
    Key? key,
    required this.challengeType,
    required this.foodName,
    required this.caloriesSaved,
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

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // Calculate points based on rating
    final pointsEarned = _calculatePoints();

    if (!mounted) return;

    // Navigate to reward screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultRewardScreen(
          rating: _rating,
          pointsEarned: pointsEarned,
          challengeType: widget.challengeType,
          foodName: widget.foodName,
          caloriesSaved: widget.caloriesSaved,
          userNote: _noteController.text,
        ),
      ),
    );
  }

  int _calculatePoints() {
    // Base points: 50
    // Rating multiplier: rating * 10
    // Calorie bonus: caloriesSaved / 10
    final basePoints = 50;
    final ratingBonus = (_rating * 10).toInt();
    final calorieBonus = (widget.caloriesSaved / 10).toInt();
    return basePoints + ratingBonus + calorieBonus;
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
                  widget.challengeType == 'exercise'
                      ? 'You earned your ${widget.foodName}!'
                      : 'You chose the healthier option!',
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
                            '😢',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 24 : 28,
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
                            '😄',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 24 : 28,
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
                          hintText: 'How did you feel about this choice?',
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

// Result / Reward Screen (Dopamine boost!)
class ResultRewardScreen extends StatefulWidget {
  final double rating;
  final int pointsEarned;
  final String challengeType;
  final String foodName;
  final int caloriesSaved;
  final String userNote;

  const ResultRewardScreen({
    Key? key,
    required this.rating,
    required this.pointsEarned,
    required this.challengeType,
    required this.foodName,
    required this.caloriesSaved,
    required this.userNote,
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

  // Mock data - would come from backend
  final int _totalPoints = 2450;
  final int _previousPoints = 2350;
  final String _currentRank = 'Gold';
  final double _rankProgress = 0.48; // 48% to Platinum

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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF66BB6A),
              const Color(0xFF4CAF50),
            ],
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
                    final progress = (_confettiController.value + (index * 0.05)) % 1.0;
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
                              'Awesome! 🎉',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 32 : 36,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.challengeType == 'exercise'
                                  ? 'You earned your ${widget.foodName}!'
                                  : 'You chose the healthier path!',
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

                            // Calories saved (if applicable)
                            if (widget.caloriesSaved > 0)
                              _buildStatCard(
                                icon: Icons.local_fire_department_rounded,
                                iconColor: const Color(0xFFFF9800),
                                title: 'Calories Saved',
                                value: '${widget.caloriesSaved}',
                                subtitle: 'Great choice!',
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
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
                                        _currentRank,
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
                                        '$_totalPoints',
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
                              SizedBox(height: isSmallScreen ? 16 : 20),
                              // Progress bar
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Progress to Platinum',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 12 : 13,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1B5E20),
                                        ),
                                      ),
                                      Text(
                                        '${(_rankProgress * 100).toInt()}%',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 12 : 13,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF66BB6A),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: _rankProgress,
                                      minHeight: 12,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF66BB6A),
                                      ),
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
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: isSmallScreen ? 52 : 56,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Navigate to stats
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF66BB6A),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.bar_chart_rounded),
                                    const SizedBox(width: 8),
                                    Text(
                                      'View Stats',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 16 : 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: isSmallScreen ? 52 : 56,
                              child: OutlinedButton(
                                onPressed: () {
                                  // End session - go back to home
                                  Navigator.of(context).popUntil((route) => route.isFirst);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'End Session',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 16 : 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
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