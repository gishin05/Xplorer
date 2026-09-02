import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

enum BackButtonAction {
  navigateUp('Navigate Up Directory', 'Step up one directory level until root'),
  exitAtRoot('Exit at Root', 'Exit application when reaching storage root');

  final String label;
  final String description;

  const BackButtonAction(this.label, this.description);
}

class GeneralSettingsState {
  final String homeFolder;
  final bool confirmOverwrite;
  final BackButtonAction backButtonAction;

  const GeneralSettingsState({
    this.homeFolder = '/storage/emulated/0',
    this.confirmOverwrite = true,
    this.backButtonAction = BackButtonAction.navigateUp,
  });

  GeneralSettingsState copyWith({
    String? homeFolder,
    bool? confirmOverwrite,
    BackButtonAction? backButtonAction,
  }) {
    return GeneralSettingsState(
      homeFolder: homeFolder ?? this.homeFolder,
      confirmOverwrite: confirmOverwrite ?? this.confirmOverwrite,
      backButtonAction: backButtonAction ?? this.backButtonAction,
    );
  }

  Map<String, dynamic> toJson() => {
        'homeFolder': homeFolder,
        'confirmOverwrite': confirmOverwrite,
        'backButtonAction': backButtonAction.name,
      };

  factory GeneralSettingsState.fromJson(Map<String, dynamic> json) {
    return GeneralSettingsState(
      homeFolder: json['homeFolder'] as String? ?? '/storage/emulated/0',
      confirmOverwrite: json['confirmOverwrite'] as bool? ?? true,
      backButtonAction: BackButtonAction.values.firstWhere(
        (e) => e.name == json['backButtonAction'],
        orElse: () => BackButtonAction.navigateUp,
      ),
    );
  }
}

class GeneralSettingsNotifier extends StateNotifier<GeneralSettingsState> {
  GeneralSettingsNotifier() : super(const GeneralSettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/general_settings.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        state = GeneralSettingsState.fromJson(json);
      }
    } catch (_) {}
  }

  Future<void> _saveSettings() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/general_settings.json');
      await file.writeAsString(jsonEncode(state.toJson()));
    } catch (_) {}
  }

  void setHomeFolder(String path) {
    state = state.copyWith(homeFolder: path);
    _saveSettings();
  }

  void setConfirmOverwrite(bool confirm) {
    state = state.copyWith(confirmOverwrite: confirm);
    _saveSettings();
  }

  void setBackButtonAction(BackButtonAction action) {
    state = state.copyWith(backButtonAction: action);
    _saveSettings();
  }
}

final generalSettingsProvider =
    StateNotifierProvider<GeneralSettingsNotifier, GeneralSettingsState>((ref) {
  return GeneralSettingsNotifier();
});
