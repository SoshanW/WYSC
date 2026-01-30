import 'package:flutter/material.dart';
import 'package:frontend/screens/home_screen/home_screen.dart';
import 'package:frontend/screens/chat_screen/chat_screen.dart';
import 'package:frontend/screens/leaderboard_screen/leaderboard_screen.dart';
import 'package:frontend/screens/profile_screens/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ChatScreen(),
    RankLeaderboardScreen(),
    ProfileStatsScreen(),
  ];

  final List<BottomNavigationBarItem> _navigationItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.chat_bubble_outline),
      activeIcon: Icon(Icons.chat_bubble),
      label: 'Chat',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.leaderboard_outlined),
      activeIcon: Icon(Icons.leaderboard),
      label: 'Leaderboard',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.1, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  ),
              child: child,
            ),
          );
        },
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: const Color(0xFF66BB6A),
              unselectedItemColor: Colors.grey[400],
              selectedFontSize: 12,
              unselectedFontSize: 12,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
              items: _navigationItems.map((item) {
                final index = _navigationItems.indexOf(item);
                final isSelected = index == _currentIndex;

                return BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF66BB6A).withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isSelected ? item.activeIcon! : item.icon!,
                  ),
                  label: item.label,
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });

      // Add haptic feedback for better user experience
      _triggerHapticFeedback();
    }
  }

  void _triggerHapticFeedback() {
    // You can add haptic feedback here if needed
    // HapticFeedback.selectionClick();
  }
}

// Enhanced Bottom Navigation Bar with custom styling
class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavigationBarItem> items;

  const CustomBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = index == currentIndex;

            return GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF66BB6A).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isSelected
                            ? _getActiveIcon(index)
                            : _getInactiveIcon(index),
                        key: ValueKey(isSelected),
                        color: isSelected
                            ? const Color(0xFF66BB6A)
                            : Colors.grey[400],
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF66BB6A)
                            : Colors.grey[400],
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                      child: Text(item.label ?? ''),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  IconData _getActiveIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home;
      case 1:
        return Icons.chat_bubble;
      case 2:
        return Icons.leaderboard;
      case 3:
        return Icons.person;
      default:
        return Icons.home;
    }
  }

  IconData _getInactiveIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home_outlined;
      case 1:
        return Icons.chat_bubble_outline;
      case 2:
        return Icons.leaderboard_outlined;
      case 3:
        return Icons.person_outline;
      default:
        return Icons.home_outlined;
    }
  }
}
