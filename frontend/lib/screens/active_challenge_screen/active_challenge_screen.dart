import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

import '../../models/challenge_models.dart';

class ActiveChallengeScreen extends StatefulWidget {
  final ChallengeData challenge;
  final String craving;

  const ActiveChallengeScreen({
    super.key,
    required this.challenge,
    required this.craving,
  });

  @override
  State<ActiveChallengeScreen> createState() => _ActiveChallengeScreenState();
}

class _ActiveChallengeScreenState extends State<ActiveChallengeScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late AnimationController _confettiController;

  Timer? _challengeTimer;
  int _secondsElapsed = 0;
  int _totalSeconds = 0;
  bool _isPaused = false;
  bool _isCompleted = false;
  int _currentActivityIndex = 0;

  final List<String> _motivationalQuotes = [
    "You're doing amazing! Keep going! 💪",
    "Every rep counts! You've got this!",
    "Feel that burn? That's progress!",
    "Your future self will thank you!",
    "Strong mind, strong body!",
    "One step closer to your goal!",
    "You're stronger than you think!",
  ];

  String _currentQuote = '';

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _totalSeconds = _parseDuration(widget.challenge.timeEstimate);
    _currentQuote = _motivationalQuotes[0];
    _startChallenge();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _confettiController.dispose();
    _challengeTimer?.cancel();
    super.dispose();
  }

  int _parseDuration(String timeEstimate) {
    // Parse "15 minutes" or "20 minutes" to seconds
    final match = RegExp(r'(\d+)').firstMatch(timeEstimate);
    if (match != null) {
      return int.parse(match.group(1)!) * 60;
    }
    return 15 * 60; // Default 15 minutes
  }

  void _startChallenge() {
    _challengeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && !_isCompleted && mounted) {
        setState(() {
          _secondsElapsed++;
          _progressController.value = _secondsElapsed / _totalSeconds;

          // Change quote every 30 seconds
          if (_secondsElapsed % 30 == 0) {
            _currentQuote = _motivationalQuotes[
            math.Random().nextInt(_motivationalQuotes.length)];
          }

          if (_secondsElapsed >= _totalSeconds) {
            _completeChallenge();
          }
        });
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _completeChallenge() {
    setState(() {
      _isCompleted = true;
    });
    _challengeTimer?.cancel();
    _confettiController.forward();
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.all(32),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF66BB6A).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  size: 45,
                  color: Color(0xFF66BB6A),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Challenge Complete!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You burned ~${widget.challenge.caloriesBurned} calories!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFF1B5E20).withOpacity(0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF66BB6A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Awesome!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;
    final progress = _secondsElapsed / _totalSeconds;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF66BB6A).withOpacity(0.1),
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
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: const Text(
                              'Exit Challenge?',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            content: const Text(
                              'Are you sure you want to exit? Your progress will be lost.',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF1B5E20),
                                height: 1.5,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'Stay',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF66BB6A),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Exit',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFEF5350),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1B5E20),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF66BB6A).withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            size: 20,
                            color: Color(0xFFFF9800),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.challenge.caloriesBurned} cal',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      SizedBox(height: isSmallScreen ? 20 : 40),
                      // Challenge title
                      Text(
                        widget.challenge.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 26 : 32,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1B5E20),
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 32 : 48),
                      // Circular progress indicator
                      SizedBox(
                        width: isSmallScreen ? 240 : 280,
                        height: isSmallScreen ? 240 : 280,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background circle
                            CustomPaint(
                              size: Size.square(isSmallScreen ? 240 : 280),
                              painter: CircleProgressPainter(
                                progress: 1.0,
                                color: const Color(0xFF66BB6A).withOpacity(0.1),
                                strokeWidth: 20,
                              ),
                            ),
                            // Progress circle
                            AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, child) {
                                return CustomPaint(
                                  size: Size.square(isSmallScreen ? 240 : 280),
                                  painter: CircleProgressPainter(
                                    progress: progress,
                                    color: const Color(0xFF66BB6A),
                                    strokeWidth: 20,
                                  ),
                                );
                              },
                            ),
                            // Time display
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: 1.0 + (_pulseController.value * 0.05),
                                      child: Icon(
                                        widget.challenge.icon,
                                        size: isSmallScreen ? 50 : 60,
                                        color: const Color(0xFF66BB6A),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _formatTime(_totalSeconds - _secondsElapsed),
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 48 : 56,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1B5E20),
                                    letterSpacing: 2,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Remaining',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 15 : 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1B5E20).withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 32 : 48),
                      // Motivation text
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: Container(
                          key: ValueKey(_currentQuote),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF66BB6A).withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.emoji_events_rounded,
                                size: 28,
                                color: Color(0xFFFFB300),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _currentQuote,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 15 : 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1B5E20),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 24 : 32),
                      // Exercise instructions
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF66BB6A).withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.fitness_center_rounded,
                                  size: 22,
                                  color: Color(0xFF66BB6A),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Today\'s Exercises',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 17 : 18,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1B5E20),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...widget.challenge.activities
                                .asMap()
                                .entries
                                .map((entry) {
                              final index = entry.key;
                              final activity = entry.value;
                              return _buildExerciseItem(
                                index + 1,
                                activity,
                                isSmallScreen,
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Bottom buttons
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pause/Resume button
              if (!_isCompleted)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _togglePause,
                    icon: Icon(
                      _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      size: 24,
                    ),
                    label: Text(
                      _isPaused ? 'Resume' : 'Pause',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF66BB6A),
                      side: const BorderSide(
                        color: Color(0xFF66BB6A),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              if (!_isCompleted) const SizedBox(height: 12),
              // I'm Done button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _completeChallenge,
                  icon: const Icon(Icons.check_circle_rounded, size: 24),
                  label: const Text(
                    'I\'m Done!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF66BB6A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseItem(int number, String exercise, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isSmallScreen ? 26 : 28,
            height: isSmallScreen ? 26 : 28,
            decoration: BoxDecoration(
              color: const Color(0xFF66BB6A).withOpacity(0.15),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF66BB6A),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                exercise,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 15,
                  color: const Color(0xFF1B5E20).withOpacity(0.8),
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for circular progress
class CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  CircleProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

enum ChallengeDifficulty {
  easy,
  medium,
  hard,
}