import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../injection.dart';
import '../../l10n/strings.dart';
import '../blocs/today/today_bloc.dart';
import '../blocs/treatments/treatments_bloc.dart';
import 'home_screen.dart';
import 'pets_screen.dart';
import 'treatments_screen.dart';

/// Root screen: bottom navigation with Home (today's treatments),
/// Pets (pet list) and Treatments (all medications).
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => TodayBloc(
            getPets: sl(),
            getAllMedications: sl(),
            getDoseHistory: sl(),
            logDose: sl(),
          )..add(const TodayRequested()),
        ),
        BlocProvider(
          create: (_) => TreatmentsBloc(
            getPets: sl(),
            getAllMedications: sl(),
            saveMedication: sl(),
            deleteMedication: sl(),
          )..add(const TreatmentsRequested()),
        ),
      ],
      child: Builder(
        builder: (context) {
          final s = S.of(context);
          return Scaffold(
            body: IndexedStack(
              index: _index,
              children: const [
                HomeScreen(),
                PetsScreen(),
                TreatmentsScreen(),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) {
                setState(() => _index = i);
                // Refresh the tab's data when it becomes visible.
                if (i == 0) {
                  context.read<TodayBloc>().add(const TodayRequested());
                } else if (i == 2) {
                  context
                      .read<TreatmentsBloc>()
                      .add(const TreatmentsRequested());
                }
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: s.homeTab,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.pets_outlined),
                  selectedIcon: const Icon(Icons.pets),
                  label: s.petsTab,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.medication_outlined),
                  selectedIcon: const Icon(Icons.medication),
                  label: s.treatmentsTab,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
