import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/env.dart';
import 'auth_service.dart';

/// A call to the server failed. [code] matches `functions/src/api/errors.ts`;
/// `unavailable` means the server could not be reached.
class ApiException implements Exception {
  const ApiException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'ApiException($code): $message';
}

/// Calls the server (functions/src/api/router.ts), signed in as the current
/// user. Privileged work (roles, ID checks, pushes) happens there.
class ApiClient {
  ApiClient(this._auth, {http.Client? client, String? baseUrl})
    : _http = client ?? http.Client(),
      _baseUrl = baseUrl ?? apiBaseUrl;

  final FirebaseAuth _auth;
  final http.Client _http;
  final String _baseUrl;

  static const _timeout = Duration(seconds: 30);

  /// Runs [name] and returns its result.
  Future<Map<String, dynamic>> call(
    String name, [
    Map<String, dynamic> data = const {},
  ]) async {
    final token = await _auth.currentUser?.getIdToken();
    final http.Response response;
    try {
      response = await _http
          .post(
            Uri.parse('$_baseUrl/$name'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(data),
          )
          .timeout(_timeout);
    } on http.ClientException {
      throw const ApiException('unavailable', "Can't reach the server.");
    } on TimeoutException {
      throw const ApiException('unavailable', "Can't reach the server.");
    }
    return _decode(response);
  }

  static Map<String, dynamic> _decode(http.Response response) {
    final Object? body;
    try {
      body = jsonDecode(response.body);
    } on FormatException {
      throw const ApiException('internal', 'Unexpected server response.');
    }
    if (body is! Map) {
      throw const ApiException('internal', 'Unexpected server response.');
    }
    final error = body['error'];
    if (error is Map) {
      throw ApiException(
        error['code'] as String? ?? 'internal',
        error['message'] as String? ?? 'Something went wrong.',
      );
    }
    final result = body['result'];
    return result is Map ? Map<String, dynamic>.from(result) : const {};
  }

  /// Tells the server something happened, without waiting. A failure is not
  /// the caller's problem: the write is already saved, and the server's
  /// sweep catches up on anything it missed.
  void notify(String name, Map<String, dynamic> data) {
    unawaited(
      call(name, data).then<void>(
        (_) {},
        onError: (Object e) => debugPrint('$name failed: $e'),
      ),
    );
  }
}

/// The server connection. Override in tests.
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(firebaseAuthProvider)),
);
