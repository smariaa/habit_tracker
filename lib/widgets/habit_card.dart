import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habits_provider.dart';
import 'package:intl/intl.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  const HabitCard({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    final habitsProvider = Provider.of<HabitsProvider>(context, listen: false);

    void _showEditDialog() {
      final nameCtrl = TextEditingController(text: habit.name);
      final notesCtrl = TextEditingController(text: habit.notes);
      String category = habit.category;
      String frequency = habit.frequency;
      DateTime startDate = habit.createdAt;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Edit Habit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: Habit.predefinedCategories
                      .map((c) => DropdownMenuItem(
                    value: c,
                    child: Row(
                      children: [
                        Icon(Habit.defaultIcon(c)),
                        const SizedBox(width: 8),
                        Text(c),
                      ],
                    ),
                  ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) category = val;
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: frequency,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  ],
                  onChanged: (val) {
                    if (val != null) frequency = val;
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Start Date:'),
                    const SizedBox(width: 12),
                    Text(
                        '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}'),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) startDate = picked;
                      },
                      child: const Text('Select'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final updatedHabit = Habit(
                  id: habit.id,
                  name: name,
                  category: category,
                  frequency: frequency,
                  createdAt: startDate,
                  currentStreak: habit.currentStreak,
                  completionHistory: habit.completionHistory,
                  notes: notesCtrl.text.trim(),
                  completedToday: habit.completedToday,
                );
                await habitsProvider.updateHabit(updatedHabit);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        leading: GestureDetector(
          onTap: () async {
            await habitsProvider.toggleCompletion(habit);
          },
          child: Icon(
            Icons.check_circle,
            color: habit.completedToday ? Colors.green : Colors.grey,
            size: 30,
          ),
        ),
        title: Text(habit.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Habit.defaultIcon(habit.category), size: 16),
                      const SizedBox(width: 4),
                      Text(habit.category, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('Streak: ${habit.currentStreak}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                    'Frequency: ${habit.frequency[0].toUpperCase()}${habit.frequency.substring(1)}',
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 12),
                Text(
                    'Start: ${DateFormat('yyyy-MM-dd').format(habit.createdAt)}',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            if (value == 'delete') {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Habit'),
                  content: const Text('Are you sure you want to delete this habit?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(_, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(_, true),
                        child: const Text('Delete')),
                  ],
                ),
              );
              if (confirm == true) {
                await habitsProvider.removeHabit(habit.id);
              }
            } else if (value == 'edit') {
              _showEditDialog();
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
        ),
        onTap: () async {
          await habitsProvider.toggleCompletion(habit);
        },
      ),
    );
  }
}
