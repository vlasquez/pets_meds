import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'injection.dart';
import 'l10n/strings.dart';
import 'presentation/blocs/pets/pets_bloc.dart';
import 'presentation/screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const PetMedsApp());
}

class PetMedsApp extends StatelessWidget {
  const PetMedsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PetsBloc(
        getPets: sl(),
        savePet: sl(),
        deletePet: sl(),
      )..add(const PetsRequested()),
      child: MaterialApp(
        title: 'Pet Meds',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('es')],
        home: const MainScreen(),
      ),
    );
  }
}
