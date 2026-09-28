/// Base class for all errors raised by the networking layer.
///
/// Having a typed hierarchy lets the UI decide how to react (e.g. redirect to
/// login on [UnauthorizedException], show a retry button on [NetworkException]).
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  /// Human-readable, already-localized message safe to show to the user.
  final String message;

  /// HTTP status code when the failure came from a server response.
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// The device could not reach the back-end (no connection, timeout, DNS...).
class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'Não foi possível conectar ao servidor. '
        'Verifique sua conexão e se a API está no ar.',
  ]);
}

/// The request timed out.
///
/// Named `ApiTimeoutException` to avoid clashing with `dart:async`'s
/// `TimeoutException`, which is what `Future.timeout()` actually throws.
class ApiTimeoutException extends ApiException {
  const ApiTimeoutException([
    super.message = 'O servidor demorou muito para responder.',
  ]);
}

/// Authentication failed or the token expired (HTTP 401/403).
class UnauthorizedException extends ApiException {
  const UnauthorizedException([
    super.message = 'Sessão expirada ou credenciais inválidas.',
  ]) : super(statusCode: 401);
}

/// The server responded with an error status (4xx/5xx).
class ServerException extends ApiException {
  const ServerException(super.message, {super.statusCode});
}
