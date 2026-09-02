import 'dart:async';
import 'dart:io';

enum AdbConnectionState { disconnected, connecting, connected, error }

class AdbBridgeService {
  AdbConnectionState _state = AdbConnectionState.disconnected;
  String? _lastError;
  Socket? _socket;
  bool _isAutoBridgeEnabled = true;
  bool _isAutoBridgeConnected = false;

  AdbConnectionState get state => _state;
  String? get lastError => _lastError;
  bool get isConnected => _state == AdbConnectionState.connected;
  bool get isAutoBridgeEnabled => _isAutoBridgeEnabled;
  bool get isAutoBridgeConnected => _isAutoBridgeConnected;

  void setAutoBridgeEnabled(bool enabled) {
    _isAutoBridgeEnabled = enabled;
  }

  void setAutoBridgeConnected(bool connected) {
    _isAutoBridgeConnected = connected;
    if (connected && _isAutoBridgeEnabled) {
      _state = AdbConnectionState.connected;
      _lastError = null;
    } else if (!connected && _socket == null) {
      _state = AdbConnectionState.disconnected;
    }
  }

  Future<bool> connect({
    required String host,
    required int port,
    String? pairingCode,
  }) async {
    _state = AdbConnectionState.connecting;
    _lastError = null;

    try {
      _socket = await Socket.connect(host, port, timeout: const Duration(seconds: 4));
      _state = AdbConnectionState.connected;
      return true;
    } catch (e) {
      _state = AdbConnectionState.error;
      _lastError = 'Connection failed: $e';
      return false;
    }
  }

  void disconnect() {
    _socket?.destroy();
    _socket = null;
    _isAutoBridgeConnected = false;
    _state = AdbConnectionState.disconnected;
    _lastError = null;
  }
}

