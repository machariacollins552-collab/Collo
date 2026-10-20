import 'dart:convert';
import 'dart:io';

import 'package:collins_fit_ai/models/chat_message.dart';
import 'package:collins_fit_ai/services/coach_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const String kUrl = 'https://coach.example.workers.dev';

http.Response jsonResponse(int status, Object body) => http.Response(
      jsonEncode(body),
      status,
      headers: <String, String>{'content-type': 'application/json; charset=utf-8'},
    );

List<ChatMessage> history() => <ChatMessage>[ChatMessage.user('Plan my meals today.', DateTime(2026, 10, 20))];

CoachService serviceWith(MockClient client) =>
    CoachService(client: client, retryDelay: Duration.zero, timeout: const Duration(seconds: 2));

Future<CoachException> failureOf(Future<Object?> Function() action) async {
  try {
    await action();
  } on CoachException catch (e) {
    return e;
  }
  fail('Expected a CoachException');
}

void main() {
  group('normalizeBaseUrl', () {
    test('adds https and removes trailing slashes', () {
      expect(CoachService.normalizeBaseUrl('coach.example.workers.dev'), 'https://coach.example.workers.dev');
      expect(CoachService.normalizeBaseUrl('https://coach.example.workers.dev///'), kUrl);
      expect(CoachService.normalizeBaseUrl('  $kUrl  '), kUrl);
    });

    test('rejects empty and non-https addresses', () {
      expect(CoachService.normalizeBaseUrl(''), isNull);
      expect(CoachService.normalizeBaseUrl('   '), isNull);
      expect(CoachService.normalizeBaseUrl('http://coach.example.workers.dev'), isNull);
    });
  });

  group('chat', () {
    test('sends messages to /chat and returns the reply', () async {
      late http.Request seen;
      final service = serviceWith(MockClient((http.Request request) async {
        seen = request;
        return jsonResponse(200, <String, dynamic>{'reply': '  Try beans and sukuma wiki.  '});
      }));

      final reply = await service.chat(
        baseUrl: kUrl,
        history: history(),
        context: <String, dynamic>{'currentKg': 80.5},
      );

      expect(reply, 'Try beans and sukuma wiki.');
      expect(seen.url.toString(), '$kUrl/chat');
      expect(seen.method, 'POST');
      final body = jsonDecode(seen.body) as Map<String, dynamic>;
      final messages = body['messages'] as List<dynamic>;
      expect(messages.length, 1);
      expect((messages.first as Map<String, dynamic>)['role'], 'user');
      expect((body['profile'] as Map<String, dynamic>)['currentKg'], 80.5);
    });

    test('tells the user when no server address is set', () async {
      final service = serviceWith(MockClient((http.Request request) async => jsonResponse(200, <String, dynamic>{})));
      final error = await failureOf(() => service.chat(baseUrl: '', history: history()));
      expect(error.code, 'not_configured');
    });

    test('rejects an invalid address before any network call', () async {
      var calls = 0;
      final service = serviceWith(MockClient((http.Request request) async {
        calls++;
        return jsonResponse(200, <String, dynamic>{'reply': 'x'});
      }));
      final error = await failureOf(() => service.chat(baseUrl: 'http://insecure.example', history: history()));
      expect(error.code, 'bad_url');
      expect(calls, 0);
    });

    test('quota errors are shown and not retried', () async {
      var calls = 0;
      final service = serviceWith(MockClient((http.Request request) async {
        calls++;
        return jsonResponse(429, <String, dynamic>{
          'error': <String, dynamic>{'code': 'quota_exhausted', 'message': 'Free limit reached.'},
        });
      }));
      final error = await failureOf(() => service.chat(baseUrl: kUrl, history: history()));
      expect(error.code, 'quota_exhausted');
      expect(error.message, 'Free limit reached.');
      expect(error.retryable, isFalse);
      expect(calls, 1);
    });

    test('a bad AI key on the server is not retried', () async {
      var calls = 0;
      final service = serviceWith(MockClient((http.Request request) async {
        calls++;
        return jsonResponse(502, <String, dynamic>{
          'error': <String, dynamic>{'code': 'provider_auth', 'message': 'Check the API key.'},
        });
      }));
      final error = await failureOf(() => service.chat(baseUrl: kUrl, history: history()));
      expect(error.code, 'provider_auth');
      expect(calls, 1);
    });

    test('a temporary server error is retried, then reported', () async {
      var calls = 0;
      final service = serviceWith(MockClient((http.Request request) async {
        calls++;
        return jsonResponse(502, <String, dynamic>{
          'error': <String, dynamic>{'code': 'provider_error', 'message': 'Busy.'},
        });
      }));
      final error = await failureOf(() => service.chat(baseUrl: kUrl, history: history()));
      expect(error.code, 'provider_error');
      expect(calls, 3);
    });

    test('recovers when a retry succeeds', () async {
      var calls = 0;
      final service = serviceWith(MockClient((http.Request request) async {
        calls++;
        if (calls == 1) {
          return jsonResponse(502, <String, dynamic>{
            'error': <String, dynamic>{'code': 'provider_error', 'message': 'Busy.'},
          });
        }
        return jsonResponse(200, <String, dynamic>{'reply': 'Here you go.'});
      }));
      final reply = await service.chat(baseUrl: kUrl, history: history());
      expect(reply, 'Here you go.');
      expect(calls, 2);
    });

    test('being offline gives a clear message and is retried', () async {
      var calls = 0;
      final service = serviceWith(MockClient((http.Request request) async {
        calls++;
        throw const SocketException('no network');
      }));
      final error = await failureOf(() => service.chat(baseUrl: kUrl, history: history()));
      expect(error.code, 'offline');
      expect(error.message, contains('offline'));
      expect(calls, 3);
    });

    test('a slow server times out', () async {
      final service = CoachService(
        client: MockClient((http.Request request) async {
          await Future<void>.delayed(const Duration(milliseconds: 300));
          return jsonResponse(200, <String, dynamic>{'reply': 'late'});
        }),
        retryDelay: Duration.zero,
        timeout: const Duration(milliseconds: 20),
      );
      final error = await failureOf(() => service.chat(baseUrl: kUrl, history: history()));
      expect(error.code, 'timeout');
    });

    test('an empty 200 answer is an error, never a made-up reply', () async {
      final service = serviceWith(MockClient((http.Request request) async => jsonResponse(200, <String, dynamic>{'reply': '   '})));
      final error = await failureOf(() => service.chat(baseUrl: kUrl, history: history()));
      expect(error.code, 'bad_response');
    });

    test('a non-JSON error page is handled', () async {
      final service = serviceWith(MockClient((http.Request request) async => http.Response('<html>oops</html>', 404)));
      final error = await failureOf(() => service.chat(baseUrl: kUrl, history: history()));
      expect(error.code, 'not_found');
    });
  });

  group('checkHealth', () {
    test('reports ready when the key is configured', () async {
      final service = serviceWith(MockClient((http.Request request) async {
        expect(request.url.path, '/health');
        return jsonResponse(200, <String, dynamic>{'ok': true, 'configured': true});
      }));
      final result = await service.checkHealth(kUrl);
      expect(result.ok, isTrue);
    });

    test('explains a missing AI key', () async {
      final service = serviceWith(MockClient((http.Request request) async {
        return jsonResponse(200, <String, dynamic>{'ok': true, 'configured': false});
      }));
      final result = await service.checkHealth(kUrl);
      expect(result.ok, isFalse);
      expect(result.message, contains('GEMINI_API_KEY'));
    });

    test('spots an address that is not the FitCoach server', () async {
      final service = serviceWith(MockClient((http.Request request) async => http.Response('nope', 404)));
      final result = await service.checkHealth(kUrl);
      expect(result.ok, isFalse);
      expect(result.message, contains('not the FitCoach backend'));
    });

    test('handles no connection', () async {
      final service = serviceWith(MockClient((http.Request request) async {
        throw const SocketException('no network');
      }));
      final result = await service.checkHealth(kUrl);
      expect(result.ok, isFalse);
    });

    test('asks for an address first', () async {
      final service = serviceWith(MockClient((http.Request request) async => jsonResponse(200, <String, dynamic>{})));
      final result = await service.checkHealth('');
      expect(result.ok, isFalse);
    });
  });
}
