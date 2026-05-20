import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trakit/data/services/claude_service.dart';

void main() {
  group('ClaudeService', () {
    test('returns null when no API key is configured', () async {
      final svc = ClaudeService();
      expect(svc.isConfigured, isFalse);
      final r = await svc.extractExpense(
        inputText: 'Swiggy 350',
        captureSource: 'quick_add',
      );
      expect(r, isNull);
    });

    test('sends the correct headers, model, and cache_control', () async {
      http.Request? captured;
      final mock = MockClient((req) async {
        captured = req;
        return http.Response(
          jsonEncode({
            'content': [
              {
                'type': 'text',
                'text': jsonEncode({
                  'amount': 348,
                  'merchant': 'Swiggy',
                  'category': 'Food',
                  'payment_mode': 'upi',
                  'confidence': 0.95,
                }),
              },
            ],
            'usage': {
              'input_tokens': 5,
              'output_tokens': 30,
              'cache_creation_input_tokens': 4200,
              'cache_read_input_tokens': 0,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final svc = ClaudeService(client: mock, apiKey: 'sk-ant-test-key');
      await svc.extractExpense(
        inputText: 'PhonePe Paid Swiggy ₹348',
        captureSource: 'screenshot',
      );

      expect(captured, isNotNull);
      expect(captured!.url.toString(), 'https://api.anthropic.com/v1/messages');
      expect(captured!.headers['x-api-key'], 'sk-ant-test-key');
      expect(captured!.headers['anthropic-version'], '2023-06-01');
      expect(captured!.headers['content-type'], contains('application/json'));

      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['model'], 'claude-haiku-4-5');
      final system = body['system'] as List<dynamic>;
      expect(system.first['cache_control'], {'type': 'ephemeral'},
          reason: 'system block must carry the cache breakpoint');
      // The schema should constrain the response shape.
      final outputConfig = body['output_config'] as Map<String, dynamic>;
      expect(outputConfig['format']['type'], 'json_schema');
    });

    test('decodes a structured response into a map', () async {
      final mock = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'content': [
              {
                'type': 'text',
                'text': jsonEncode({
                  'amount': 2499,
                  'merchant': 'Amazon',
                  'category': 'Shopping',
                  'payment_mode': 'card',
                  'confidence': 0.94,
                }),
              },
            ],
            'usage': {'input_tokens': 1, 'output_tokens': 1},
          }),
          200,
        );
      });

      final svc = ClaudeService(client: mock, apiKey: 'sk-ant-test');
      final r = await svc.extractExpense(
        inputText: 'Amazon.in Total ₹2,499 Visa 4421',
        captureSource: 'screenshot',
      );

      expect(r, isNotNull);
      expect(r!['amount'], 2499);
      expect(r['merchant'], 'Amazon');
      expect(r['category'], 'Shopping');
      expect(r['payment_mode'], 'card');
    });

    test('returns null when the model returns non-JSON text', () async {
      final mock = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'content': [
              {'type': 'text', 'text': 'sorry, I cannot help with that'},
            ],
            'usage': {'input_tokens': 1, 'output_tokens': 1},
          }),
          200,
        );
      });

      final svc = ClaudeService(client: mock, apiKey: 'sk-ant-test');
      final r = await svc.extractExpense(
        inputText: 'malformed',
        captureSource: 'quick_add',
      );
      expect(r, isNull);
    });

    test('returns null on 4xx without throwing', () async {
      final mock = MockClient((req) async {
        return http.Response(
          jsonEncode({'type': 'error', 'error': {'type': 'authentication_error'}}),
          401,
        );
      });

      final svc = ClaudeService(client: mock, apiKey: 'sk-ant-bad');
      final r = await svc.extractExpense(
        inputText: 'whatever',
        captureSource: 'quick_add',
      );
      expect(r, isNull);
    });
  });
}
