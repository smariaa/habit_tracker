import 'package:flutter/material.dart';

class Habit {
  final String id;
  final String name; // Title
  final String category;
  final String frequency; // "daily" or "weekly"
  final DateTime createdAt; // Start date of the habit
  int currentStreak;
  List<String> completionHistory; // ISO date strings like "2025-08-31"
  String notes; // Optional notes/description
  bool completedToday;

  static const List<String> predefinedCategories = [
    'Health',
    'Study',
    'Fitness',
    'Productivity',
    'Mental Health',
    'Others',
  ];

  static IconData defaultIcon(String category) {
    switch (category) {
      case 'Health':
        return Icons.health_and_safety;
      case 'Study':
        return Icons.menu_book;
      case 'Fitness':
        return Icons.fitness_center;
      case 'Productivity':
        return Icons.work;
      case 'Mental Health':
        return Icons.self_improvement;
      default:
        return Icons.category;
    }
  }

  Habit({
    required this.id,
    required this.name,
    this.category = 'Others',
    this.frequency = 'daily',
    DateTime? createdAt, // Optional, defaults to now
    this.currentStreak = 0,
    List<String>? completionHistory,
    this.notes = '',
    this.completedToday = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        completionHistory = completionHistory ?? [];

  // Convert Habit to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'frequency': frequency,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'currentStreak': currentStreak,
      'completionHistory': completionHistory,
      'notes': notes,
      'completedToday': completedToday,
    };
  }

  // Convert Firestore Map back into Habit object
  factory Habit.fromMap(String id, Map<String, dynamic> map) {
    return Habit(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? 'Others',
      frequency: map['frequency'] ?? 'daily',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt']).toLocal()
          : DateTime.now(),
      currentStreak: (map['currentStreak'] ?? 0) as int,
      completionHistory: List<String>.from(map['completionHistory'] ?? []),
      notes: map['notes'] ?? '',
      completedToday: map['completedToday'] ?? false,
    );
  }
}
