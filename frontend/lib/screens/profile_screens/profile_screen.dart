import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../services/api_service.dart';

class ProfileStatsScreen extends StatefulWidget {
  const ProfileStatsScreen({Key? key}) : super(key: key);

  @override
  State<ProfileStatsScreen> createState() => _ProfileStatsScreenState();
}

class _ProfileStatsScreenState extends State<ProfileStatsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _name = '';
  String _email = '';
  int _totalPoints = 0;
  String _rank = 'Bronze';
  List<dynamic> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final profile = await ApiService().getProfile();
      if (mounted) {
        setState(() {
          _name = profile['name'] as String? ?? ApiService().userName ?? 'User';
          _email = profile['email'] as String? ?? ApiService().userEmail ?? '';
          _totalPoints = profile['total_points'] as int? ?? 0;
          _rank = profile['rank'] as String? ?? 'Bronze';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _name = ApiService().userName ?? 'User';
          _email = ApiService().userEmail ?? '';
        });
      }
    }

    try {
      final history = await ApiService().getHistory();
      if (mounted) {
        setState(() {
          _sessions = history['sessions'] as List? ?? [];
        });
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    await ApiService().logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // App Bar with profile header
          SliverAppBar(
            expandedHeight: isSmallScreen ? 200 : 240,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF66BB6A),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(height: isSmallScreen ? 40 : 60),
                        // Profile picture
                        Container(
                          width: isSmallScreen ? 80 : 90,
                          height: isSmallScreen ? 80 : 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 45,
                            color: Color(0xFF66BB6A),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        // Name
                        Text(
                          _name.isNotEmpty ? _name : 'User',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 22 : 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Email
                        Text(
                          _email,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 20 : 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout_rounded),
                color: Colors.white,
                tooltip: 'Logout',
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Points and Rank Section
                    Row(
                      children: [
                        // Total Points
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.stars_rounded,
                            iconColor: const Color(0xFFFFB300),
                            title: 'Total Points',
                            value: '$_totalPoints',
                            subtitle: '',
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 12 : 16),
                        // Current Rank
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.emoji_events_rounded,
                            iconColor: const Color(0xFFFF6F00),
                            title: 'Current Rank',
                            value: _rank,
                            subtitle: '',
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isSmallScreen ? 20 : 24),

                    // Success Rate Card
                    _buildSuccessRateCard(isSmallScreen),

                    SizedBox(height: isSmallScreen ? 20 : 24),

                    // Achievement Stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniStatCard(
                            icon: Icons.favorite_rounded,
                            color: const Color(0xFFEF5350),
                            title: 'Cravings',
                            value: '87',
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 12 : 16),
                        Expanded(
                          child: _buildMiniStatCard(
                            icon: Icons.check_circle_rounded,
                            color: const Color(0xFF66BB6A),
                            title: 'Challenges',
                            value: '24',
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 12 : 16),
                        Expanded(
                          child: _buildMiniStatCard(
                            icon: Icons.local_fire_department_rounded,
                            color: const Color(0xFFFF9800),
                            title: 'Streak',
                            value: '12',
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isSmallScreen ? 24 : 28),

                    // Cravings History Section
                    _buildSectionHeader(
                      'Cravings History',
                      Icons.history_rounded,
                      isSmallScreen,
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    _buildCravingHistoryList(isSmallScreen),

                    SizedBox(height: isSmallScreen ? 24 : 28),

                    // Recent Challenges
                    _buildSectionHeader(
                      'Challenges Completed',
                      Icons.military_tech_rounded,
                      isSmallScreen,
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    _buildChallengesList(isSmallScreen),

                    SizedBox(height: isSmallScreen ? 24 : 28),

                    // Weekly Progress Chart
                    _buildWeeklyProgressCard(isSmallScreen),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
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
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: isSmallScreen ? 24 : 28),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 13,
              color: const Color(0xFF1B5E20).withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 26 : 28,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              color: const Color(0xFF66BB6A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessRateCard(bool isSmallScreen) {
    const successRate = 73.0;
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF66BB6A).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Success Rate',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 15 : 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                Text(
                  '${successRate.toInt()}%',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 36 : 42,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                Text(
                  'You chose healthier options\n73% of the time!',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 13,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: isSmallScreen ? 90 : 100,
            height: isSmallScreen ? 90 : 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: isSmallScreen ? 90 : 100,
                  height: isSmallScreen ? 90 : 100,
                  child: CircularProgressIndicator(
                    value: successRate / 100,
                    strokeWidth: isSmallScreen ? 8 : 10,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
                Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: isSmallScreen ? 35 : 40,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 16 : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isSmallScreen ? 28 : 32),
          SizedBox(height: isSmallScreen ? 8 : 10),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              color: const Color(0xFF1B5E20).withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isSmallScreen) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF66BB6A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF66BB6A),
            size: isSmallScreen ? 20 : 22,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1B5E20),
          ),
        ),
      ],
    );
  }

  Widget _buildCravingHistoryList(bool isSmallScreen) {
    final cravings = [
      {
        'food': 'Pizza',
        'alternative': 'Cauliflower Pizza',
        'date': 'Today, 2:30 PM',
        'saved': 280,
        'chosen': 'healthier',
      },
      {
        'food': 'Ice Cream',
        'alternative': 'Earned with exercise',
        'date': 'Yesterday',
        'saved': 0,
        'chosen': 'earned',
      },
      {
        'food': 'Burger',
        'alternative': 'Veggie Burger',
        'date': '2 days ago',
        'saved': 220,
        'chosen': 'healthier',
      },
      {
        'food': 'Chocolate Bar',
        'alternative': 'Dark Chocolate',
        'date': '3 days ago',
        'saved': 150,
        'chosen': 'healthier',
      },
    ];

    return Column(
      children: cravings.map((craving) {
        return Container(
          margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
          padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                decoration: BoxDecoration(
                  color: craving['chosen'] == 'earned'
                      ? const Color(0xFFFF9800).withOpacity(0.1)
                      : const Color(0xFF66BB6A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  craving['chosen'] == 'earned'
                      ? Icons.directions_run_rounded
                      : Icons.eco_rounded,
                  color: craving['chosen'] == 'earned'
                      ? const Color(0xFFFF9800)
                      : const Color(0xFF66BB6A),
                  size: isSmallScreen ? 22 : 24,
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      craving['food'] as String,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 15 : 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      craving['alternative'] as String,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 13,
                        color: const Color(0xFF1B5E20).withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      craving['date'] as String,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 12,
                        color: const Color(0xFF1B5E20).withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
              if (craving['saved'] as int > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: const Color(0xFFFF9800),
                      size: isSmallScreen ? 16 : 18,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '-${craving['saved']}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF66BB6A),
                      ),
                    ),
                    Text(
                      'cal',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 11,
                        color: const Color(0xFF1B5E20).withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChallengesList(bool isSmallScreen) {
    final challenges = [
      {
        'name': '7-Day Streak',
        'description': 'Made healthy choices for 7 days',
        'icon': Icons.whatshot_rounded,
        'color': const Color(0xFFFF6F00),
        'date': '5 days ago',
      },
      {
        'name': 'Exercise Master',
        'description': 'Completed 10 exercise challenges',
        'icon': Icons.fitness_center_rounded,
        'color': const Color(0xFF5E35B1),
        'date': '1 week ago',
      },
      {
        'name': 'Calorie Crusher',
        'description': 'Saved 5000 calories total',
        'icon': Icons.local_fire_department_rounded,
        'color': const Color(0xFFFF9800),
        'date': '2 weeks ago',
      },
    ];

    return Column(
      children: challenges.map((challenge) {
        return Container(
          margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
          padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                decoration: BoxDecoration(
                  color: (challenge['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  challenge['icon'] as IconData,
                  color: challenge['color'] as Color,
                  size: isSmallScreen ? 22 : 24,
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge['name'] as String,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 15 : 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      challenge['description'] as String,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 13,
                        color: const Color(0xFF1B5E20).withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.emoji_events_rounded,
                color: const Color(0xFFFFB300),
                size: isSmallScreen ? 28 : 32,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeeklyProgressCard(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 18 : 20),
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
          Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                color: const Color(0xFF66BB6A),
                size: isSmallScreen ? 22 : 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Weekly Activity',
                style: TextStyle(
                  fontSize: isSmallScreen ? 17 : 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 20 : 24),
          // Simple bar chart
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBarChartColumn('Mon', 0.6, isSmallScreen),
              _buildBarChartColumn('Tue', 0.8, isSmallScreen),
              _buildBarChartColumn('Wed', 0.9, isSmallScreen),
              _buildBarChartColumn('Thu', 0.7, isSmallScreen),
              _buildBarChartColumn('Fri', 1.0, isSmallScreen),
              _buildBarChartColumn('Sat', 0.5, isSmallScreen),
              _buildBarChartColumn('Sun', 0.4, isSmallScreen),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF66BB6A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.tips_and_updates_rounded,
                  color: Color(0xFF66BB6A),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Great week! You\'re making progress.',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13,
                      color: const Color(0xFF1B5E20),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartColumn(
    String day,
    double percentage,
    bool isSmallScreen,
  ) {
    final maxHeight = isSmallScreen ? 100.0 : 120.0;
    return Column(
      children: [
        Container(
          width: isSmallScreen ? 28 : 32,
          height: maxHeight * percentage,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [const Color(0xFF66BB6A), const Color(0xFF4CAF50)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: TextStyle(
            fontSize: isSmallScreen ? 11 : 12,
            color: const Color(0xFF1B5E20).withOpacity(0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
