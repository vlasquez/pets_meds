import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'domain/entities/app_settings.dart';
import 'domain/usecases/reschedule_reminders.dart';
import 'injection.dart';
import 'utils/strings.dart';
import 'presentation/blocs/pets/pets_bloc.dart';
import 'presentation/blocs/settings/settings_bloc.dart';
import 'presentation/screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  await _rescheduleReminders();
  runApp(const PetMedsApp());
}

/// Re-arms treatment reminders on startup so one-shot schedules keep
/// firing. Localized with the device locale (no BuildContext yet).
Future<void> _rescheduleReminders() async {
  final s = S(WidgetsBinding.instance.platformDispatcher.locale);
  try {
    await sl<RescheduleReminders>()(
      title: (petName) => s.reminderTitle(petName),
      body: (t) =>
          s.reminderBody(t.medicationName, s.formatDose(t.doseAmount, t.doseUnit)),
    );
  } catch (_) {
    // Never block app launch on reminder rescheduling.
  }
}

class PetMedsApp extends StatelessWidget {
  const PetMedsApp({super.key});

  ThemeMode _themeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SettingsBloc(
            getSettings: sl(),
            saveSettings: sl(),
          )..add(const SettingsRequested()),
        ),
        BlocProvider(
          create: (_) => PetsBloc(
            getPets: sl(),
            savePet: sl(),
            deletePet: sl(),
          )..add(const PetsRequested()),
        ),
      ],
      child: BlocBuilder<SettingsBloc, AppSettings>(
        builder: (context, settings) {
          return MaterialApp(
            title: 'Pet Meds',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.teal,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            themeMode: _themeMode(settings.themeMode),
            locale: settings.languageCode == null
                ? null
                : Locale(settings.languageCode!),
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('es')],
            // Force 24h / AM-PM across the app (time labels and pickers)
            // when the user overrides the system default.
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              final use24h = switch (settings.hourFormat) {
                AppHourFormat.system => mq.alwaysUse24HourFormat,
                AppHourFormat.h24 => true,
                AppHourFormat.h12 => false,
              };
              return MediaQuery(
                data: mq.copyWith(alwaysUse24HourFormat: use24h),
                child: child!,
              );
            },
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
