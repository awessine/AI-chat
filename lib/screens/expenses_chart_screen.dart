import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/chat_provider.dart';
import '../models/message.dart';

class ExpensesChartScreen extends StatelessWidget {
  const ExpensesChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    // Группировка расходов по дням
    final Map<DateTime, double> expensesByDay = {};
    for (final ChatMessage msg in chatProvider.messages) {
      if (msg.cost != null) {
        // Если в ChatMessage нет времени, подставляем текущую дату
        final date = DateTime.now();
        final day = DateTime(date.year, date.month, date.day);
        expensesByDay[day] = (expensesByDay[day] ?? 0) + msg.cost!;
      }
    }

    final sortedDays = expensesByDay.keys.toList()..sort();
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedDays.length; i++) {
      spots.add(FlSpot(i.toDouble(), expensesByDay[sortedDays[i]] ?? 0));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(title: const Text('График расходов')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: spots.isEmpty
            ? const Center(child: Text('Нет данных для отображения'))
            : LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval:
                            _calculateInterval(expensesByDay.values.toList()),
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < sortedDays.length) {
                            final d = sortedDays[index];
                            return Text('${d.day}.${d.month}');
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withValues(),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  double _calculateInterval(List<double> values) {
    if (values.isEmpty) return 1;
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    return maxVal / 5;
  }
}
