import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/adb_bridge_service.dart';
import '../services/platform_channel_service.dart';
import 'file_explorer_provider.dart';

class AdbBridgeState {
  final bool isAutoBridgeEnabled;
  final bool isDevOptionsEnabled;
  final bool isAdbEnabled;
  final AdbConnectionState connectionState;
  final String? lastError;
  final bool hasDismissedPrompt;

  const AdbBridgeState({
    this.isAutoBridgeEnabled = true,
    this.isDevOptionsEnabled = false,
    this.isAdbEnabled = false,
    this.connectionState = AdbConnectionState.disconnected,
    this.lastError,
    this.hasDismissedPrompt = false,
  });

  bool get isConnected => connectionState == AdbConnectionState.connected;
  bool get canAccessProtectedData => isConnected || isDevOptionsEnabled;

  AdbBridgeState copyWith({
    bool? isAutoBridgeEnabled,
    bool? isDevOptionsEnabled,
    bool? isAdbEnabled,
    AdbConnectionState? connectionState,
    String? lastError,
    bool? hasDismissedPrompt,
  }) {
    return AdbBridgeState(
      isAutoBridgeEnabled: isAutoBridgeEnabled ?? this.isAutoBridgeEnabled,
      isDevOptionsEnabled: isDevOptionsEnabled ?? this.isDevOptionsEnabled,
      isAdbEnabled: isAdbEnabled ?? this.isAdbEnabled,
      connectionState: connectionState ?? this.connectionState,
      lastError: lastError,
      hasDismissedPrompt: hasDismissedPrompt ?? this.hasDismissedPrompt,
    );
  }
}

class AdbBridgeNotifier extends StateNotifier<AdbBridgeState> {
  final PlatformChannelService _platformService;
  final AdbBridgeService _bridgeService;

  AdbBridgeNotifier(this._platformService, this._bridgeService)
      : super(const AdbBridgeState()) {
    checkDeveloperOptionsAndBridge();
  }

  Future<void> checkDeveloperOptionsAndBridge() async {
    final devInfo = await _platformService.checkDeveloperOptions();
    final isDevOn = devInfo['isDevOptionsEnabled'] ?? false;
    final isAdbOn = devInfo['isAdbEnabled'] ?? false;
    final isAutoActive = devInfo['isAutoBridgeActive'] ?? false;

    final shouldAutoConnect = state.isAutoBridgeEnabled && (isDevOn || isAdbOn || isAutoActive);

    if (shouldAutoConnect) {
      _bridgeService.setAutoBridgeConnected(true);
      state = state.copyWith(
        isDevOptionsEnabled: isDevOn,
        isAdbEnabled: isAdbOn,
        connectionState: AdbConnectionState.connected,
        lastError: null,
      );
    } else {
      _bridgeService.setAutoBridgeConnected(false);
      state = state.copyWith(
        isDevOptionsEnabled: isDevOn,
        isAdbEnabled: isAdbOn,
        connectionState: _bridgeService.state,
      );
    }
  }

  void toggleAutoBridge(bool enabled) {
    _bridgeService.setAutoBridgeEnabled(enabled);
    state = state.copyWith(isAutoBridgeEnabled: enabled);
    checkDeveloperOptionsAndBridge();
  }

  Future<bool> openDeveloperSettings() async {
    return await _platformService.openDeveloperSettings();
  }

  Future<bool> connectManual({required String host, required int port, String? pairingCode}) async {
    state = state.copyWith(connectionState: AdbConnectionState.connecting);
    final ok = await _bridgeService.connect(host: host, port: port, pairingCode: pairingCode);
    state = state.copyWith(
      connectionState: _bridgeService.state,
      lastError: _bridgeService.lastError,
    );
    return ok;
  }

  void disconnect() {
    _bridgeService.disconnect();
    state = state.copyWith(
      connectionState: AdbConnectionState.disconnected,
      lastError: null,
    );
  }

  void dismissPrompt() {
    state = state.copyWith(hasDismissedPrompt: true);
  }
}

final adbBridgeServiceProvider = Provider<AdbBridgeService>((ref) {
  return AdbBridgeService();
});

final adbBridgeProvider =
    StateNotifierProvider<AdbBridgeNotifier, AdbBridgeState>((ref) {
  final platform = ref.watch(platformServiceProvider);
  final bridge = ref.watch(adbBridgeServiceProvider);
  return AdbBridgeNotifier(platform, bridge);
});
