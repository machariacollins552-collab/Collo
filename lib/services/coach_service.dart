import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/config.dart';
import '../models/chat_message.dart';

/// A problem talking to FitCoach, with a message that is safe to show the user.
class CoachException implements Exception {
  const CoachException({required this.code, required this.message, this.retryable = false});

  /// Short machine-readable reason, for example `offline` or `quota_exhausted`.
  final String code;

  /// Friendly text for the screen.
  final String message;

  /// Whether trying the same request again might work.
  final bool retryable;

  @override
  String toString() => 'CoachException($code): $message';
}

class HealthResult {
  const HealthResult({required this.ok, required this.message});

  final bool ok;
  final String message;
}

/// Talks to YOUR backend (never directly to the AI provider). If anything goes wrong the
/// user is told - there are no scripted "pretend AI" replies.
class CoachService {
  CoachService({
    http.Client? client,
    this.retryDelay = const Duration(milliseconds: 900),
    this.timeout = AppConfig.requestTimeout,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration retryDelay;
  final Duration timeout;

  /// Returns a clean `https://host` address without a trailing slash, or null if invalid.
  static String? normalizeBaseUrl(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;
    if (!s.contains('://')) s = 'https://$s';
    final uri = Uri.tryParse(s);
    if (uri == null || uri.host.isEmpty || uri.scheme != 'https') return null;
    var out = uri.toString();
    while (out.endsWith('/')) {
      out = out.substring(0, out.length - 1);
    }
    return out;
  }

  Future<String> chat({
    required String baseUrl,
    required List<ChatMessage> history,
    Map<String, dynamic>? context,
  }) async {
    if (baseUrl.trim().isEmpty) {
      throw const CoachException(
        code: 'not_configured',
        message: "FitCoach's AI server isn't connected yet. "
            'Open Profile, then AI connection, and paste your server address.',
      );
    }
    final base = normalizeBaseUrl(baseUrl);
    if (base == null) {
      throw const CoachException(
        code: 'bad_url',
        message: 'The AI server address looks wrong. It must start with https:// '
            '(check Profile, then AI connection).',
      );
    }

    final uri = Uri.parse('$base/chat');
    final payload = jsonEncode(<String, dynamic>{
      'messages': <Map<String, String>>[
        for (final m in history)
          <String, String>{'role': m.isUser ? 'user' : 'assistant', 'content': m.text},
      ],
      if (context != null) 'profile': context,
    });
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      if (AppConfig.appToken.isNotEmpty) 'X-App-Token': AppConfig.appToken,
    };

    for (var attempt = 0;; attempt++) {
      try {
        final response = await _client.post(uri, headers: headers, body: payload).timeout(timeout);
        return _parseReply(response);
      } catch (e) {
        final error = _asCoachException(e);
        if (!error.retryable || attempt >= AppConfig.maxRetries) {
          throw error;
        }
      }
      await Future<void>.delayed(retryDelay * (attempt + 1));
    }
  }

  /// Checks that the server is reachable and has its AI key configured. No retries.
  Future<HealthResult> checkHealth(String baseUrl) async {
    if (baseUrl.trim().isEmpty) {
      return const HealthResult(ok: false, message: 'Paste your server address first.');
    }
    final base = normalizeBaseUrl(baseUrl);
    if (base == null) {
      return const HealthResult(ok: false, message: 'The address must start with https://');
    }
    try {
      final response = await _client
          .get(Uri.parse('$base/health'), headers: <String, String>{'Accept': 'application/json'})
          .timeout(AppConfig.healthTimeout);
      if (response.statusCode == 404) {
        return const HealthResult(
          ok: false,
          message: 'Reached a server, but it is not the FitCoach backend. Check the address.',
        );
      }
      if (response.statusCode != 200) {
        return HealthResult(ok: false, message: 'The server answered with an error (${response.statusCode}).');
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map && decoded['ok'] == true) {
        if (decoded['configured'] == true) {
          return const HealthResult(ok: true, message: 'Connected. FitCoach AI is ready.');
        }
        return const HealthResult(
          ok: false,
          message: 'The server is reachable, but its AI key is not set yet (add the GEMINI_API_KEY secret).',
        );
      }
      return const HealthResult(ok: false, message: 'Unexpected answer from that address.');
    } catch (e) {
      final error = _asCoachException(e);
      return HealthResult(ok: false, message: error.message);
    }
  }

  String _parseReply(http.Response response) {
    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {
      body = null;
    }

    if (response.statusCode == 200) {
      final reply = body == null ? null : body['reply'];
      if (reply is String && reply.trim().isNotEmpty) return reply.trim();
      throw const CoachException(
        code: 'bad_response',
        message: 'FitCoach sent back an empty answer. Please try again.',
        retryable: true,
      );
    }

    String? code;
    String? serverMessage;
    final err = body == null ? null : body['error'];
    if (err is Map) {
      if (err['code'] is String) code = err['code'] as String;
      if (err['message'] is String) serverMessage = err['message'] as String;
    }
    throw _mapStatus(response.statusCode, code, serverMessage);
  }

  CoachException _mapStatus(int status, String? code, String? serverMessage) {
    if (status == 429) {
      if (code == 'quota_exhausted') {
        return CoachException(
          code: 'quota_exhausted',
          message: serverMessage ??
              'FitCoach has reached its free usage limit for now. Please try again later.',
        );
      }
      return CoachException(
        code: 'rate_limited',
        message: serverMessage ?? "You're sending messages quickly. Please wait a moment and try again.",
      );
    }
    if (status == 401 || status == 403) {
      return CoachException(
        code: 'unauthorized',
        message: serverMessage ?? 'This app is not allowed to use that AI server. Check the server settings.',
      );
    }
    if (status == 404) {
      return const CoachException(
        code: 'not_found',
        message: "Couldn't find the AI service at that address. Check Profile, then AI connection.",
      );
    }
    if (status == 400 || status == 413 || status == 415 || status == 422) {
      return CoachException(
        code: code ?? 'invalid_request',
        message: serverMessage ?? "That message couldn't be sent. Try shortening or rewording it.",
      );
    }
    if (status == 503 && code == 'not_configured') {
      return CoachException(
        code: 'server_not_configured',
        message: serverMessage ?? "The AI service isn't fully set up yet. The server owner needs to add the AI key.",
      );
    }
    if (status >= 500) {
      return CoachException(
        code: code ?? 'server_error',
        message: serverMessage ?? 'The AI service is having trouble right now. Please try again in a moment.',
        retryable: code != 'provider_auth' && code != 'model_unavailable' && code != 'not_configured',
      );
    }
    return CoachException(
      code: code ?? 'http_$status',
      message: serverMessage ?? 'Something went wrong (error $status). Please try again.',
    );
  }

  CoachException _asCoachException(Object error) {
    if (error is CoachException) return error;
    if (error is TimeoutException) {
      return const CoachException(
        code: 'timeout',
        message: 'FitCoach took too long to answer. Check your connection and try again.',
        retryable: true,
      );
    }
    if (error is SocketException) {
      return const CoachException(
        code: 'offline',
        message: "You're offline, or the AI server can't be reached. "
            'Your tracking still works - live chat needs internet.',
        retryable: true,
      );
    }
    if (error is http.ClientException) {
      return const CoachException(
        code: 'network',
        message: "Couldn't reach the AI server. Check your internet connection and the server address.",
        retryable: true,
      );
    }
    return const CoachException(
      code: 'unknown',
      message: 'Something unexpected went wrong. Please try again.',
    );
  }

  void dispose() => _client.close();
}
