// Import JSON library
import 'dart:convert';
// Import HTTP client
import 'package:http/http.dart' as http;
// Import Flutter core classes
import 'package:flutter/foundation.dart';
// Import package for working with .env files
import 'package:flutter_dotenv/flutter_dotenv.dart';
// Import for persistent storage
import 'package:shared_preferences/shared_preferences.dart';

class OpenRouterClient {
  // API ключ для авторизации
  String? apiKey;
  // Базовый URL API
  String? baseUrl;
  // Заголовки HTTP запросов
  late Map<String, String> headers;

  // Singleton
  static final OpenRouterClient _instance = OpenRouterClient._internal();
  factory OpenRouterClient() => _instance;

  OpenRouterClient._internal();

  /// Инициализация клиента — сначала читаем из SharedPreferences, иначе из .env
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    apiKey = prefs.getString('openrouter_api_key') ?? "";
    baseUrl = dotenv.env['BASE_URL'] ?? "";

    _updateHeaders();

    if (kDebugMode) {
      print('OpenRouterClient initialized');
      print('Base URL: $baseUrl');
      print('API Key: ${apiKey != null ? '***HIDDEN***' : 'null'}');
    }

    if (apiKey == null || baseUrl == null) {
      throw Exception('API key or Base URL is missing');
    }
  }

  /// Обновление конфигурации во время работы (и сохранение в память)
  Future<void> updateConfig({String? apiKey, String? baseUrl}) async {
    final prefs = await SharedPreferences.getInstance();

    if (apiKey != null) {
      await prefs.setString('openrouter_api_key', apiKey);
      this.apiKey = apiKey;
    }

    if (baseUrl != null) {
      await prefs.setString('openrouter_base_url', baseUrl);
      this.baseUrl = baseUrl;
    }

    _updateHeaders();

    if (kDebugMode) {
      print('OpenRouterClient config updated');
    }
  }

  /// Формируем заголовки
  void _updateHeaders() {
    headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      'X-Title': 'AI Chat Flutter',
    };
  }

  // ===================== API методы =====================

  Future<List<Map<String, dynamic>>> getModels() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/models'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final modelsData = json.decode(response.body);
        if (modelsData['data'] != null) {
          return (modelsData['data'] as List)
              .map((model) => {
                    'id': model['id'] as String,
                    'name': model['name'] as String,
                    'pricing': {
                      'prompt': model['pricing']['prompt'] as String,
                      'completion': model['pricing']['completion'] as String,
                    },
                    'context_length': (model['context_length'] ??
                            model['top_provider']['context_length'] ??
                            0)
                        .toString(),
                  })
              .toList();
        }
        throw Exception('Invalid API response format');
      } else {
        return _defaultModels();
      }
    } catch (e) {
      if (kDebugMode) print('Error getting models: $e');
      return _defaultModels();
    }
  }

  Future<Map<String, dynamic>> sendMessage(String message, String model) async {
    try {
      final data = {
        'model': model,
        'messages': [
          {'role': 'user', 'content': message}
        ],
        'max_tokens': int.parse(dotenv.env['MAX_TOKENS'] ?? '1000'),
        'temperature': double.parse(dotenv.env['TEMPERATURE'] ?? '0.7'),
        'stream': false,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        return {
          'error': errorData['error']?['message'] ?? 'Unknown error occurred'
        };
      }
    } catch (e) {
      if (kDebugMode) print('Error sending message: $e');
      return {'error': e.toString()};
    }
  }

  Future<String> getBalance() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl?.contains('vsegpt.ru') == true
            ? '$baseUrl/balance'
            : '$baseUrl/credits'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['data'] != null) {
          if (baseUrl?.contains('vsegpt.ru') == true) {
            final credits =
                double.tryParse(data['data']['credits'].toString()) ?? 0.0;
            return '${credits.toStringAsFixed(2)}₽';
          } else {
            final credits = data['data']['total_credits'] ?? 0;
            final usage = data['data']['total_usage'] ?? 0;
            return '\$${(credits - usage).toStringAsFixed(2)}';
          }
        }
      }
      return baseUrl?.contains('vsegpt.ru') == true ? '0.00₽' : '\$0.00';
    } catch (e) {
      if (kDebugMode) print('Error getting balance: $e');
      return 'Error';
    }
  }

  String formatPricing(double pricing) {
    try {
      if (baseUrl?.contains('vsegpt.ru') == true) {
        return '${pricing.toStringAsFixed(3)}₽/K';
      } else {
        return '\$${(pricing * 1000000).toStringAsFixed(3)}/M';
      }
    } catch (e) {
      if (kDebugMode) print('Error formatting pricing: $e');
      return '0.00';
    }
  }

  List<Map<String, dynamic>> _defaultModels() {
    return [
      {'id': 'deepseek-coder', 'name': 'DeepSeek'},
      {'id': 'claude-3-sonnet', 'name': 'Claude 3.5 Sonnet'},
      {'id': 'gpt-3.5-turbo', 'name': 'GPT-3.5 Turbo'},
    ];
  }
}
