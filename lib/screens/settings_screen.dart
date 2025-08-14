import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/chat_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  String _provider = 'openRouter'; // 'openRouter' | 'vsegpt'
  String? _selectedModel;

  @override
  void initState() {
    super.initState();
    final chat = context.read<ChatProvider>();

    // Определяем провайдера по baseUrl (getter уже есть в ChatProvider)
    final isVsegpt = chat.baseUrl?.contains('vsegpt.ru') == true;
    _provider = isVsegpt ? 'vsegpt' : 'openRouter';

    // Текущая выбранная модель
    _selectedModel = chat.currentModel;

    // API-ключ: если в твоём OpenRouterClient есть публичный геттер apiKey — можешь сюда подставить
    // _apiKeyController.text = chat.apiKey ?? '';
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final models = chat.availableModels;
    final uniqueModels =
        {for (var model in models) model['id']: model}.values.toList();

    _selectedModel = uniqueModels.any((m) => m['id'] == _selectedModel)
        ? _selectedModel
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF262626),
        title: const Text('Настройки провайдера'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              'Выберите провайдера, модель и введите API ключ',
              style: GoogleFonts.roboto(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Провайдер
            DropdownButtonFormField<String>(
              value: _provider,
              dropdownColor: const Color(0xFF333333),
              decoration: const InputDecoration(
                labelText: 'Провайдер',
                labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'openRouter',
                  child: Text('OpenRouter'),
                ),
                DropdownMenuItem(
                  value: 'vsegpt',
                  child: Text('VSEGPT'),
                ),
              ],
              onChanged: (val) {
                if (val == null) return;
                setState(() {
                  _provider = val;
                  // Модель пока не трогаем — окончательно проверим на сохранении
                });
              },
            ),

            const SizedBox(height: 20),

            // Модель (как в chat_screen — имя + цены + контекст)
            DropdownButtonFormField<String>(
              value: _selectedModel,
              isExpanded: true,
              isDense: true,
              dropdownColor: const Color(0xFF333333),
              decoration: const InputDecoration(
                labelText: 'Модель',
                labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              items: uniqueModels.map<DropdownMenuItem<String>>((model) {
                return DropdownMenuItem<String>(
                  value: model['id'] as String?,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (model['name'] ?? '') as String,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedModel = val),
            ),

            const SizedBox(height: 20),

            // API Key
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'API Key',
                labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                hintText: 'Оставьте пустым, чтобы не менять',
                hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final apiKey = _apiKeyController.text.trim() ?? "";
                  final providerKey = _provider; // 'openRouter' | 'vsegpt'
                  final modelId = _selectedModel ?? chat.currentModel;

                  try {
                    await chat.updateSettings(
                      provider: providerKey,
                      apiKey: apiKey.isEmpty
                          ? null
                          : apiKey, // null => не менять ключ
                      modelId: modelId,
                    );

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Настройки применены'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 1),
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ошибка: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
