import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    final usageByModel =
        chatProvider.messages.fold<Map<String, Map<String, dynamic>>>(
      {},
      (map, msg) {
        if (msg.modelId != null) {
          map.putIfAbsent(
              msg.modelId!, () => {'count': 0, 'tokens': 0, 'cost': 0.0});
          map[msg.modelId]!['count']++;
          if (msg.tokens != null) map[msg.modelId]!['tokens'] += msg.tokens!;
          if (msg.cost != null) map[msg.modelId]!['cost'] += msg.cost!;
        }
        return map;
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(title: const Text('Статистика')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Всего сообщений: ${chatProvider.messages.length}'),
          Text('Баланс: ${chatProvider.balance}'),
          const SizedBox(height: 16),
          ...usageByModel.entries.map((entry) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Сообщений: ${entry.value['count']}'),
                  if (entry.value['tokens'] > 0)
                    Text('Токенов: ${entry.value['tokens']}'),
                  Text('Стоимость: ${entry.value['cost'].toStringAsFixed(4)}'),
                  const SizedBox(height: 8),
                ],
              )),
        ],
      ),
    );
  }
}
