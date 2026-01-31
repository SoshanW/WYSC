import 'package:flutter/material.dart';

/// Challenge difficulty levels
enum ChallengeDifficulty {
  easy,
  medium,
  hard,
}

/// Data model for a fitness challenge
class ChallengeData {
  final String id;
  final String title;
  final String description;
  final List<String> activities;
  final String timeEstimate;
  final int caloriesBurned;
  final ChallengeDifficulty difficulty;
  final IconData icon;

  ChallengeData({
    required this.id,
    required this.title,
    required this.description,
    required this.activities,
    required this.timeEstimate,
    required this.caloriesBurned,
    required this.difficulty,
    required this.icon,
  });

  /// Create a copy of the challenge with modified fields
  ChallengeData copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? activities,
    String? timeEstimate,
    int? caloriesBurned,
    ChallengeDifficulty? difficulty,
    IconData? icon,
  }) {
    return ChallengeData(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      activities: activities ?? this.activities,
      timeEstimate: timeEstimate ?? this.timeEstimate,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      difficulty: difficulty ?? this.difficulty,
      icon: icon ?? this.icon,
    );
  }

  /// Convert to JSON (for future API integration)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'activities': activities,
      'timeEstimate': timeEstimate,
      'caloriesBurned': caloriesBurned,
      'difficulty': difficulty.toString().split('.').last,
      'icon': icon.codePoint,
    };
  }

  /// Create from JSON (for future API integration)
  factory ChallengeData.fromJson(Map<String, dynamic> json) {
    return ChallengeData(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      activities: (json['activities'] as List).cast<String>(),
      timeEstimate: json['timeEstimate'] as String,
      caloriesBurned: json['caloriesBurned'] as int,
      difficulty: ChallengeDifficulty.values.firstWhere(
            (e) => e.toString().split('.').last == json['difficulty'],
        orElse: () => ChallengeDifficulty.medium,
      ),
      icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
    );
  }

  /// Create from backend API challenge format
  factory ChallengeData.fromApiChallenge(Map<String, dynamic> json, int index) {
    final difficultyStr = (json['difficulty'] as String? ?? 'medium').toLowerCase();
    ChallengeDifficulty difficulty;
    switch (difficultyStr) {
      case 'easy':
        difficulty = ChallengeDifficulty.easy;
        break;
      case 'hard':
        difficulty = ChallengeDifficulty.hard;
        break;
      default:
        difficulty = ChallengeDifficulty.medium;
    }

    final timeLimit = json['time_limit'] as int? ?? 15;
    final description = json['description'] as String? ?? 'Complete this challenge';

    // Pick an icon based on the index
    const icons = [
      Icons.fitness_center_rounded,
      Icons.directions_run_rounded,
      Icons.accessibility_new_rounded,
      Icons.directions_walk_rounded,
      Icons.sports_gymnastics,
    ];

    return ChallengeData(
      id: '${index + 1}',
      title: 'Challenge ${index + 1}',
      description: description,
      activities: [description],
      timeEstimate: '$timeLimit minutes',
      caloriesBurned: 0,
      difficulty: difficulty,
      icon: icons[index % icons.length],
    );
  }
}