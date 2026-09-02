import 'package:flutter/material.dart';
import '../services/adb_bridge_service.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';

class AdbSetupScreen extends StatefulWidget {
  const AdbSetupScreen({super.key});

  @override
  State<AdbSetupScreen> createState() => _AdbSetupScreenState();
}

class _AdbSetupScreenState extends State<AdbSetupScreen> {
  final _hostController = TextEditingController(text: '127.0.0.1');
  final _portController = TextEditingController(text: '5555');
  final _codeController = TextEditingController();
  final _bridge = AdbBridgeService();

  bool _isConnecting = false;
  String? _statusMessage;

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _codeController.dispose();
    _bridge.disconnect();
    super.dispose();
  }

  Future<void> _handleConnect() async {
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 5555;

    setState(() {
      _isConnecting = true;
      _statusMessage = 'Connecting to $host:$port...';
    });

    final success = await _bridge.connect(host: host, port: port);

    setState(() {
      _isConnecting = false;
      if (success) {
        _statusMessage = 'Connected to Wireless ADB daemon successfully!';
      } else {
        _statusMessage = _bridge.lastError ?? 'Connection failed';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Wireless ADB Bridge'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.help_outline_rounded, color: AppColors.accentTeal, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'How Wireless ADB Works',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'On Android 11+, you can enable Wireless Debugging in Developer Options to manage files without a USB cable or rooting. Enter your device\'s local Wi-Fi port below to connect.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 12),
                _buildStep(1, 'Open Settings > Developer options > Wireless debugging'),
                _buildStep(2, 'Tap "Pair device with pairing code" or check port'),
                _buildStep(3, 'Enter the displayed Port & IP address below'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CONNECTION SETTINGS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _hostController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  cursorColor: AppColors.accentTeal,
                  decoration: const InputDecoration(
                    labelText: 'Host IP Address',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.accentTeal),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _portController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  cursorColor: AppColors.accentTeal,
                  decoration: const InputDecoration(
                    labelText: 'Wireless Debug Port (e.g. 37099 or 5555)',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.accentTeal),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  cursorColor: AppColors.accentTeal,
                  decoration: const InputDecoration(
                    labelText: 'Pairing Code (if required)',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.accentTeal),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentTeal,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isConnecting ? null : _handleConnect,
                    child: _isConnecting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Text('Connect to ADB Bridge', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                if (_statusMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _bridge.isConnected
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _bridge.isConnected
                            ? AppColors.success.withValues(alpha: 0.3)
                            : AppColors.danger.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                        fontSize: 13,
                        color: _bridge.isConnected ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accentTeal.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$num',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.accentTeal,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
