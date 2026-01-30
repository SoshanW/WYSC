import 'package:flutter/material.dart';

class RankLeaderboardScreen extends StatefulWidget {
  const RankLeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<RankLeaderboardScreen> createState() => _RankLeaderboardScreenState();
}

class _RankLeaderboardScreenState extends State<RankLeaderboardScreen> {
  int _selectedTab = 0; // 0 = Global, 1 = Friends
  final String _currentUserName = 'Arun Kumar';

  // Sample leaderboard data
  final List<Map<String, dynamic>> _globalLeaderboard = [
    {'name': 'Sarah Johnson', 'points': 8500, 'rank': 1},
    {'name': 'Mike Chen', 'points': 7200, 'rank': 2},
    {'name': 'Emma Wilson', 'points': 6800, 'rank': 3},
    {'name': 'Alex Rodriguez', 'points': 5400, 'rank': 4},
    {'name': 'Rachel Kim', 'points': 4200, 'rank': 5},
    {'name': 'Tom Anderson', 'points': 3800, 'rank': 6},
    {'name': 'Arun Kumar', 'points': 2450, 'rank': 7},
    {'name': 'James Brown', 'points': 2300, 'rank': 8},
    {'name': 'Lisa Garcia', 'points': 2100, 'rank': 9},
    {'name': 'David Lee', 'points': 1950, 'rank': 10},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Leaderboard',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF66BB6A),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tabs
          _buildTabs(),
          
          // Leaderboard content
          Expanded(
            child: _selectedTab == 0
                ? _buildGlobalLeaderboard()
                : _buildFriendsLeaderboard(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab('Global', 0, Icons.public_rounded),
          ),
          Expanded(
            child: _buildTab('Friends', 1, Icons.people_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index, IconData icon) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF66BB6A) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Colors.white
                  : const Color(0xFF1B5E20).withOpacity(0.5),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : const Color(0xFF1B5E20).withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalLeaderboard() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _globalLeaderboard.length,
      itemBuilder: (context, index) {
        final user = _globalLeaderboard[index];
        final isCurrentUser = user['name'] == _currentUserName;
        final rank = user['rank'] as int;
        final isTopThree = rank <= 3;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCurrentUser
                ? const Color(0xFF66BB6A).withOpacity(0.15)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrentUser
                  ? const Color(0xFF66BB6A)
                  : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isTopThree
                      ? _getTopThreeColor(rank - 1)
                      : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isTopThree
                      ? Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.white,
                          size: 24,
                        )
                      : Text(
                          '#$rank',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user['name'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1B5E20),
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF66BB6A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'You',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user['points']} points',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF1B5E20).withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Trophy for top 3
              if (isTopThree)
                Icon(
                  Icons.stars_rounded,
                  color: _getTopThreeColor(rank - 1),
                  size: 28,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFriendsLeaderboard() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(40),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 20),
            const Text(
              'Connect with Friends',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add friends to compete on the leaderboard',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF1B5E20).withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Add friends functionality
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF66BB6A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.person_add_rounded),
                label: const Text(
                  'Add Friends',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTopThreeColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFD700); // Gold
      case 1:
        return const Color(0xFFC0C0C0); // Silver
      case 2:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey;
    }
  }
}