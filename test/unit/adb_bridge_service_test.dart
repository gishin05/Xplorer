import 'package:file_manager/services/adb_bridge_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdbBridgeService Tests', () {
    late AdbBridgeService service;

    setUp(() {
      service = AdbBridgeService();
    });

    test('initial state is disconnected and autoBridgeEnabled is true', () {
      expect(service.state, equals(AdbConnectionState.disconnected));
      expect(service.isConnected, isFalse);
      expect(service.isAutoBridgeEnabled, isTrue);
      expect(service.isAutoBridgeConnected, isFalse);
    });

    test('setAutoBridgeConnected toggles connected state when autoBridge is enabled', () {
      service.setAutoBridgeConnected(true);
      expect(service.isAutoBridgeConnected, isTrue);
      expect(service.isConnected, isTrue);
      expect(service.state, equals(AdbConnectionState.connected));

      service.setAutoBridgeConnected(false);
      expect(service.isAutoBridgeConnected, isFalse);
      expect(service.isConnected, isFalse);
      expect(service.state, equals(AdbConnectionState.disconnected));
    });

    test('setAutoBridgeEnabled allows disabling auto connection', () {
      service.setAutoBridgeEnabled(false);
      expect(service.isAutoBridgeEnabled, isFalse);

      service.setAutoBridgeConnected(true);
      expect(service.isAutoBridgeConnected, isTrue);
      // Because autoBridge is disabled, connection state should not automatically become connected
      expect(service.isConnected, isFalse);
    });

    test('disconnect resets connection state and errors', () {
      service.setAutoBridgeConnected(true);
      expect(service.isConnected, isTrue);

      service.disconnect();
      expect(service.isConnected, isFalse);
      expect(service.isAutoBridgeConnected, isFalse);
      expect(service.state, equals(AdbConnectionState.disconnected));
      expect(service.lastError, isNull);
    });
  });
}
