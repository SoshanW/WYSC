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
}