import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/habits_provider.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final habits = Provider.of<HabitsProvider>(context).habits;
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE6F4EA), Color(0xFFD0F0C0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: habits.isEmpty
            ? const Center(child: Text('Add a habit to see progress'))
            : ListView.builder(
          itemCount: habits.length,
          itemBuilder: (context, index) {
            final habit = habits[index];

            // Last 7 days completion values
            final values = List.generate(7, (i) {
              final day = today.subtract(Duration(days: 6 - i));
              final key =
                  '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
              return habit.completionHistory.contains(key) ? 1 : 0;
            });

            // Percentage completion for last 7 days
            final percent = (values.reduce((a, b) => a + b) / 7 * 100).round();

            return HabitProgressCard(
              habitName: habit.name,
              values: values,
              today: today,
              completionPercent: percent,
              currentStreak: habit.currentStreak,
            );
          },
        ),
      ),
    );
  }
}

class HabitProgressCard extends StatelessWidget {
  final String habitName;
  final List<int> values;
  final DateTime today;
  final int completionPercent;
  final int currentStreak;

  const HabitProgressCard({
    super.key,
    required this.habitName,
    required this.values,
    required this.today,
    required this.completionPercent,
    required this.currentStreak,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Habit name
            Text(
              habitName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Completion percentage & streak
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Completion: $completionPercent%'),
                Text('Streak: $currentStreak'),
              ],
            ),
            const SizedBox(height: 12),
            // 7-day bar chart
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: values
                      .asMap()
                      .entries
                      .map(
                        (e) => BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.toDouble(),
                          width: 18,
                          color: e.value == 1 ? Colors.green : Colors.grey.shade300,
                          borderRadius:
                          const BorderRadius.all(Radius.circular(4)),
                        ),
                      ],
                    ),
                  )
                      .toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final day = today.subtract(Duration(days: 6 - value.toInt()));
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text('${day.month}/${day.day}',
                                style: const TextStyle(fontSize: 12)),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
