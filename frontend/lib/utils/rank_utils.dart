import 'package:flutter/material.dart';

/// Returns the appropriate color for a given rank name
Color getRankColor(String rank) {
  switch (rank.toLowerCase()) {
    case 'beginner':
      return const Color(0xFF8BC34A); // Light green for beginner
    case 'bronze':
      return const Color(0xFFCD7F32); // Bronze color
    case 'silver':
      return const Color(0xFF9E9E9E); // Silver color (darker for visibility)
    case 'gold':
      return const Color(0xFFFFD700); // Gold color
    case 'platinum':
      return const Color(0xFF78909C); // Platinum blue-grey
    case 'diamond':
      return const Color(0xFF00BCD4); // Diamond cyan
    case 'master':
      return const Color(0xFF9C27B0); // Purple for master
    case 'grandmaster':
      return const Color(0xFFFF5722); // Deep orange for grandmaster
    case 'legend':
      return const Color(0xFFE91E63); // Pink for legend
    default:
      return const Color(0xFF8BC34A); // Default to beginner green
  }
}

/// Returns a gradient for rank backgrounds
List<Color> getRankGradient(String rank) {
  switch (rank.toLowerCase()) {
    case 'beginner':
      return [const Color(0xFF8BC34A), const Color(0xFF689F38)];
    case 'bronze':
      return [const Color(0xFFCD7F32), const Color(0xFF8B4513)];
    case 'silver':
      return [const Color(0xFFBDBDBD), const Color(0xFF757575)];
    case 'gold':
      return [const Color(0xFFFFD700), const Color(0xFFDAA520)];
    case 'platinum':
      return [const Color(0xFF90A4AE), const Color(0xFF607D8B)];
    case 'diamond':
      return [const Color(0xFF4DD0E1), const Color(0xFF00ACC1)];
    case 'master':
      return [const Color(0xFF9C27B0), const Color(0xFF6A1B9A)];
    case 'grandmaster':
      return [const Color(0xFFFF5722), const Color(0xFFE64A19)];
    case 'legend':
      return [const Color(0xFFE91E63), const Color(0xFFC2185B)];
    default:
      return [const Color(0xFF8BC34A), const Color(0xFF689F38)];
  }
}

/// Returns the icon color for a rank (for use on light backgrounds)
Color getRankIconColor(String rank) {
  switch (rank.toLowerCase()) {
    case 'beginner':
      return const Color(0xFF8BC34A);
    case 'bronze':
      return const Color(0xFFCD7F32);
    case 'silver':
      return const Color(0xFF757575); // Darker silver for visibility
    case 'gold':
      return const Color(0xFFFFB300);
    case 'platinum':
      return const Color(0xFF546E7A); // Darker blue-grey for platinum
    case 'diamond':
      return const Color(0xFF00ACC1); // Darker cyan for diamond
    case 'master':
      return const Color(0xFF9C27B0);
    case 'grandmaster':
      return const Color(0xFFFF5722);
    case 'legend':
      return const Color(0xFFE91E63);
    default:
      return const Color(0xFF8BC34A);
  }
}

/// Returns text color that contrasts well with the rank color
Color getRankTextColor(String rank) {
  switch (rank.toLowerCase()) {
    case 'silver':
    case 'platinum':
      return const Color(0xFF424242); // Dark text for light colors
    default:
      return getRankColor(rank);
  }
}
