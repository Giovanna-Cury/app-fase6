import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_exception.dart';

/// Thin, reusable wrapper around the `http` package.
///
/// Responsibilities:
///  * builds the full URL from [AppConfig.apiBaseUrl] + a relative path;
///  * injects JSON and Authorization (Bearer) headers automatically;
///  * applies a timeout;
///  * decodes JSON and converts transport/HTTP errors into typed
///    [ApiException]s so the rest of the app never deals with raw `http` types.
///
/// It intentionally avoids `dart:io` so the same code compiles for mobile,
/// desktop AND web.
class ApiClient {
  ApiClient({String? baseUrl, http.Client? client})
      : _baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  String? _authToken;

  /// Stores the Bearer token used on every subsequent request.
  /// Pass `null` to clear it (e.g. on logout).
  void setAuthToken(String? token) => _authToken = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<dynamic> get(String path) =>
      _send(() => _client.get(_uri(path), headers: _headers));

  Future<dynamic> post(String path, {Object? body}) => _send(
        () => _client.post(
          _uri(path),
          headers: _headers,
          body: body == null ? null : jsonEncode(body),
        ),
      );

  Future<dynamic> put(String path, {Object? body}) => _send(
        () => _client.put(
          _uri(path),
          headers: _headers,
          body: body == null ? null : jsonEncode(body),
        ),
      );

  Future<dynamic> delete(String path) =>
      _send(() => _client.delete(_uri(path), headers: _headers));

  /// Executes [request], applying the timeout and mapping every failure mode
  /// into a typed [ApiException].
  Future<dynamic> _send(Future<http.Response> Function() request) async {
    late final http.Response response;
    try {
      response = await request().timeout(AppConfig.requestTimeout);
    } on TimeoutException {
      throw const ApiTimeoutException();
    } catch (e) {
      // Covers http.ClientException, SocketException (IO) and any other
      // transport-level failure without importing dart:io.
      if (kDebugMode) debugPrint('[ApiClient] network error: $e');
      throw const NetworkException();
    }
    // Response handling is kept OUTSIDE the try above so the typed
    // ApiExceptions it throws are not swallowed by the network catch.
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    final status = response.statusCode;

    if (status == 401 || status == 403) {
      throw const UnauthorizedException();
    }

    if (status >= 200 && status < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        throw const ServerException('Resposta inválida do servidor.');
      }
    }

    // Try to extract a "message" field from a JSON error body.
    String message = 'Erro ${response.statusCode} ao acessar o servidor.';
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map && decoded['message'] is String) {
        message = decoded['message'] as String;
      }
    } catch (_) {
      // keep default message
    }

    if (kDebugMode) {
      debugPrint('API error [$status] ${response.request?.url}: '
          '${response.body}');
    }
    throw ServerException(message, statusCode: status);
  }

  void dispose() => _client.close();
}
