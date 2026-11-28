// ignore_for_file: file_names

/// Browser builds cannot bind a loopback callback port.
class ProviderLoginCallbackListener {
  static Future<ProviderLoginCallbackListener> bind() {
    throw UnsupportedError(
      'Account authorization requires the desktop or mobile app.',
    );
  }

  String get redirectUri => '';

  Future<ProviderLoginCallback?> get completion =>
      Future<ProviderLoginCallback?>.value(null);

  Future<void> close() async {}
}

class ProviderLoginCallback {
  const ProviderLoginCallback({required this.code, required this.state});

  final String code;
  final String state;
}
