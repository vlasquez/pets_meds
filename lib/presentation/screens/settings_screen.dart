import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../domain/entities/app_settings.dart';
import '../../l10n/strings.dart';
import '../blocs/settings/settings_bloc.dart';

const _contactEmail = 'andresvelasquezp92@gmail.com';
// Note: keep in sync with docs/index.html (privacy policy).

/// Settings tab: language and theme.
/// Expects a [SettingsBloc] to be provided above it (app level).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _themeLabel(S s, AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return s.systemDefault;
      case AppThemeMode.light:
        return s.lightTheme;
      case AppThemeMode.dark:
        return s.darkTheme;
    }
  }

  String _languageLabel(S s, String? code) {
    switch (code) {
      case 'es':
        return s.spanish;
      case 'en':
        return s.english;
      default:
        return s.systemDefault;
    }
  }

  Future<void> _pickLanguage(BuildContext context, AppSettings settings) async {
    final s = S.of(context);
    final bloc = context.read<SettingsBloc>();
    final selected = await showDialog<_LanguageChoice>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(s.language),
        children: [
          for (final choice in const [
            _LanguageChoice(null),
            _LanguageChoice('es'),
            _LanguageChoice('en'),
          ])
            RadioListTile<_LanguageChoice>(
              value: choice,
              groupValue: _LanguageChoice(settings.languageCode),
              title: Text(_languageLabel(s, choice.code)),
              onChanged: (v) => Navigator.of(ctx).pop(v),
            ),
        ],
      ),
    );
    if (selected != null) {
      bloc.add(LanguageChanged(selected.code));
    }
  }

  Future<void> _pickTheme(BuildContext context, AppSettings settings) async {
    final s = S.of(context);
    final bloc = context.read<SettingsBloc>();
    final selected = await showDialog<AppThemeMode>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(s.theme),
        children: [
          for (final mode in AppThemeMode.values)
            RadioListTile<AppThemeMode>(
              value: mode,
              groupValue: settings.themeMode,
              title: Text(_themeLabel(s, mode)),
              onChanged: (v) => Navigator.of(ctx).pop(v),
            ),
        ],
      ),
    );
    if (selected != null) {
      bloc.add(ThemeModeChanged(selected));
    }
  }

  Future<void> _showAbout(BuildContext context) async {
    final s = S.of(context);
    final info = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.about),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pet Meds — 101 Labs',
                style: Theme.of(ctx).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text('${s.versionLabel}: ${info.version} (${info.buildNumber})'),
            const SizedBox(height: 8),
            Text('${s.contactLabel}:'),
            const SelectableText(_contactEmail),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTab)),
      body: BlocBuilder<SettingsBloc, AppSettings>(
        builder: (context, settings) {
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(s.language),
                subtitle: Text(_languageLabel(s, settings.languageCode)),
                onTap: () => _pickLanguage(context, settings),
              ),
              ListTile(
                leading: const Icon(Icons.brightness_6),
                title: Text(s.theme),
                subtitle: Text(_themeLabel(s, settings.themeMode)),
                onTap: () => _pickTheme(context, settings),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(s.about),
                onTap: () => _showAbout(context),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Wrapper so a null language code ("system") can be a radio value.
class _LanguageChoice {
  final String? code;
  const _LanguageChoice(this.code);

  @override
  bool operator ==(Object other) =>
      other is _LanguageChoice && other.code == code;

  @override
  int get hashCode => code.hashCode;
}
