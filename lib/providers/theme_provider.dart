import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

enum AppThemeColor {
  teal('Traditional Teal', Color(0xFF00897B), Color(0xFF4DB6AC), Color(0xFF004D40)),
  blue('Classic Blue', Color(0xFF1E88E5), Color(0xFF64B5F6), Color(0xFF0D47A1)),
  green('Emerald Green', Color(0xFF2E7D32), Color(0xFF81C784), Color(0xFF1B5E20)),
  amber('Amber Gold', Color(0xFFFF8F00), Color(0xFFFFD54F), Color(0xFFE65100)),
  red('Crimson Red', Color(0xFFC62828), Color(0xFFE57373), Color(0xFFB71C1C)),
  purple('Purple Indigo', Color(0xFF5E35B1), Color(0xFF9575CD), Color(0xFF311B92)),
  slate('Obsidian Slate', Color(0xFF607D8B), Color(0xFFB0BEC5), Color(0xFF263238));

  final String label;
  final Color primary;
  final Color light;
  final Color dark;

  const AppThemeColor(this.label, this.primary, this.light, this.dark);
}

class ThemeNotifier extends StateNotifier<AppThemeColor> {
  ThemeNotifier() : super(AppThemeColor.teal) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/theme_pref.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        final savedName = data['theme'] as String?;
        if (savedName != null) {
          final matched = AppThemeColor.values.firstWhere(
            (t) => t.name == savedName,
            orElse: () => AppThemeColor.teal,
          );
          state = matched;
        }
      }
    } catch (_) {}
  }

  Future<void> setTheme(AppThemeColor newTheme) async {
    state = newTheme;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/theme_pref.json');
      await file.writeAsString(jsonEncode({'theme': newTheme.name}));
    } catch (_) {}
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeColor>((ref) {
  return ThemeNotifier();
});
