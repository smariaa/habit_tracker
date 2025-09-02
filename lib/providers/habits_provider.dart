import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../services/firebase_service.dart';

class HabitsProvider extends ChangeNotifier {
  final FirebaseService _fs = FirebaseService();
  String? _userId;
  List<Habit> _habits = [];

  List<Habit> get habits => _habits;

  void setUser(String uid) {
    if (_userId == uid) return;
    _userId = uid;
    _listenToHabits();
  }

  void _listenToHabits() {
    if (_userId == null) return;
    _fs.habitsStream(_userId!).listen((list) {
      _habits = list;
      notifyListeners();
    });
  }

  // Add new habit
  Future<void> addHabit(Habit h) async {
    if (_userId == null) throw Exception('User not set');
    await _fs.addOrUpdateHabit(_userId!, h);
  }

  // Update existing habit
  Future<void> updateHabit(Habit h) async {
    if (_userId == null) throw Exception('User not set');
    await _fs.addOrUpdateHabit(_userId!, h);
  }

  // Delete habit
  Future<void> removeHabit(String id) async {
    if (_userId == null) throw Exception('User not set');
    await _fs.deleteHabit(_userId!, id);
  }

  // Toggle completion for today
  Future<void> toggleCompletion(Habit habit) async {
    if (_userId == null) throw Exception('User not set');
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final wasCompleted = habit.completionHistory.contains(todayKey);

    List<String> newHistory = List.from(habit.completionHistory);
    if (wasCompleted) {
      newHistory.remove(todayKey);
    } else {
      newHistory.add(todayKey);
    }

    int newStreak = _calculateStreak(newHistory);

    final updated = Habit(
      id: habit.id,
      name: habit.name,
      category: habit.category,
      frequency: habit.frequency,
      createdAt: habit.createdAt,
      currentStreak: newStreak,
      completionHistory: newHistory,
      notes: habit.notes,
      completedToday: !wasCompleted,
    );

    await updateHabit(updated);
  }

  // Calculate current streak
  int _calculateStreak(List<String> historyDates) {
    if (historyDates.isEmpty) return 0;
    final sorted = historyDates.map((s) => DateTime.parse(s)).toList()..sort();
    final today = DateTime.now();
    int streak = 0;
    DateTime check = DateTime(today.year, today.month, today.day);
    final set = sorted.map((d) => DateTime(d.year, d.month, d.day)).toSet();
    while (set.contains(check)) {
      streak++;
      check = check.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
