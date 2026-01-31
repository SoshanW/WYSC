import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

import '../../models/challenge_models.dart';
import '../active_challenge_screen/active_challenge_screen.dart';


class ChallengeDetailsScreen extends StatefulWidget {
  final ChallengeData challenge;
  final String craving;

  const ChallengeDetailsScreen({
    Key? key,
    required this.challenge,
    required this.craving,
  }) : super(key: key);

  @override
  State<ChallengeDetailsScreen> createState() => _ChallengeDetailsScreenState();
}

class _ChallengeDetailsScreenState extends State<ChallengeDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _timerPulseController;
  late AnimationController _slideController;
  Timer? _countdownTimer;
  Duration _timeRemaining = const Duration(hours: 24);

  @override
  void initState() {
    super.initState();
    _timerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _startCountdown();
  }

  @override
  void dispose() {
    _timerPulseController.dispose();
    _slideController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeRemaining.inSeconds > 0) {
            _timeRemaining = Duration(seconds: _timeRemaining.inSeconds - 1);
          } else {
            timer.cancel();
          }
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _startNow() {
    // Navigate to active challenge screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveChallengeScreen(
          challenge: widget.challenge,
          craving: widget.craving,
        ),
      ),
    );
  }

  void _startLater() {
    // TODO: Schedule notification and save challenge
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Challenge Scheduled! 📅',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B5E20),
          ),
        ),
        content: const Text(
          'We\'ll send you a reminder notification. Your challenge expires in 24 hours.',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF1B5E20),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'Got it',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF66BB6A),
                fontSize: 16,
              ),
            ),
          ),
        ],
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
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
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
                          Icon(
                            Icons.restaurant_rounded,
                            size: 18,
                            color: const Color(0xFF66BB6A),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.craving,
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
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Challenge icon and title
                      Center(
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _slideController,
                            curve: Curves.easeOut,
                          )),
                          child: FadeTransition(
                            opacity: _slideController,
                            child: Column(
                              children: [
                                Container(
                                  width: isSmallScreen ? 100 : 120,
                                  height: isSmallScreen ? 100 : 120,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF66BB6A).withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    widget.challenge.icon,
                                    size: isSmallScreen ? 50 : 60,
                                    color: const Color(0xFF66BB6A),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  widget.challenge.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 28 : 32,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1B5E20),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Expiry timer
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _slideController,
                          curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
                        )),
                        child: FadeTransition(
                          opacity: CurvedAnimation(
                            parent: _slideController,
                            curve: const Interval(0.2, 1.0),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFF9800).withOpacity(0.15),
                                  const Color(0xFFFF5722).withOpacity(0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFFF9800).withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                AnimatedBuilder(
                                  animation: _timerPulseController,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: 1.0 + (_timerPulseController.value * 0.1),
                                      child: Icon(
                                        Icons.timer_outlined,
                                        size: isSmallScreen ? 32 : 36,
                                        color: const Color(0xFFFF9800),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Challenge Expires In',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 13 : 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFFF9800),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDuration(_timeRemaining),
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 24 : 28,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF1B5E20),
                                          letterSpacing: 1,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Challenge details
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _slideController,
                          curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
                        )),
                        child: FadeTransition(
                          opacity: CurvedAnimation(
                            parent: _slideController,
                            curve: const Interval(0.4, 1.0),
                          ),
                          child: Container(
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
                                Text(
                                  'Challenge Overview',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 18 : 20,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1B5E20),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  widget.challenge.description,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 15 : 16,
                                    color: const Color(0xFF1B5E20).withOpacity(0.7),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Stats row
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        Icons.access_time_rounded,
                                        widget.challenge.timeEstimate,
                                        'Duration',
                                        isSmallScreen,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        Icons.local_fire_department_rounded,
                                        '${widget.challenge.caloriesBurned}',
                                        'Calories',
                                        isSmallScreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Exercises
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _slideController,
                          curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
                        )),
                        child: FadeTransition(
                          opacity: CurvedAnimation(
                            parent: _slideController,
                            curve: const Interval(0.6, 1.0),
                          ),
                          child: Container(
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
                                Text(
                                  'Exercises',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 18 : 20,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1B5E20),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ...widget.challenge.activities
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  return _buildExerciseItem(
                                    entry.key + 1,
                                    entry.value,
                                    isSmallScreen,
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Motivation quote
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _slideController,
                          curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
                        )),
                        child: FadeTransition(
                          opacity: CurvedAnimation(
                            parent: _slideController,
                            curve: const Interval(0.8, 1.0),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF66BB6A).withOpacity(0.1),
                                  const Color(0xFF4CAF50).withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.format_quote_rounded,
                                  size: 32,
                                  color: Color(0xFF66BB6A),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Balance your cravings with action. You\'ve got this!',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 15 : 16,
                                      fontStyle: FontStyle.italic,
                                      color: const Color(0xFF1B5E20),
                                      height: 1.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Bottom action buttons
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
              // Start Now button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _startNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF66BB6A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Start Now',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Start Later button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _startLater,
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
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule_rounded, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Start Later',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
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

  Widget _buildStatCard(
      IconData icon,
      String value,
      String label,
      bool isSmallScreen,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF66BB6A).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: isSmallScreen ? 28 : 32,
            color: const Color(0xFF66BB6A),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 13,
              color: const Color(0xFF1B5E20).withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseItem(int number, String exercise, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isSmallScreen ? 28 : 32,
            height: isSmallScreen ? 28 : 32,
            decoration: BoxDecoration(
              color: const Color(0xFF66BB6A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                exercise,
                style: TextStyle(
                  fontSize: isSmallScreen ? 15 : 16,
                  color: const Color(0xFF1B5E20),
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