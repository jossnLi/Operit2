// ignore_for_file: file_names

import 'dart:async';
import 'dart:io';

/// Authorization code returned to a random loopback callback port.
class ProviderLoginCallback {
  const ProviderLoginCallback({required this.code, required this.state});

  final String code;
  final String state;
}

/// Listens for a browser authorization callback on an OS-assigned port.
class ProviderLoginCallbackListener {
  ProviderLoginCallbackListener._(this._server, this.redirectUri) {
    _server.listen(_handleRequest, onError: _handleServerError);
  }

  /// Binds IPv4 loopback; the redirect host is explicit so the browser and
  /// provider both use the same address family.
  static Future<ProviderLoginCallbackListener> bind() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final redirectUri = 'http://127.0.0.1:${server.port}/auth/callback';
    return ProviderLoginCallbackListener._(server, redirectUri);
  }

  final HttpServer _server;
  final String redirectUri;
  final Completer<ProviderLoginCallback?> _completion =
      Completer<ProviderLoginCallback?>();
  bool _closed = false;

  Future<ProviderLoginCallback?> get completion => _completion.future;

  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    if (!_completion.isCompleted) {
      _completion.complete(null);
    }
    await _server.close(force: true);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    if (request.uri.path != '/auth/callback') {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    final code = request.uri.queryParameters['code'] ?? '';
    final state = request.uri.queryParameters['state'] ?? '';
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write(
        '<!doctype html><html><body>Authorization complete. You can return to Operit.</body></html>',
      );
    await request.response.close();
    if (code.isEmpty) {
      if (!_completion.isCompleted) {
        _completion.completeError(
          StateError('Authorization callback did not include a code'),
        );
      }
      await close();
      return;
    }
    if (!_completion.isCompleted) {
      _completion.complete(ProviderLoginCallback(code: code, state: state));
    }
    await close();
  }

  void _handleServerError(Object error, StackTrace stackTrace) {
    if (!_completion.isCompleted) {
      _completion.completeError(error, stackTrace);
    }
    unawaited(close());
  }
}
