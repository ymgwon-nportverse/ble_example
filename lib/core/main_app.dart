import 'package:ble_test/connect/presentation/central/central_details_screen.dart';
import 'package:ble_test/core/presentation/home_screen.dart';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter/material.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      routes: {
        'peripheral': (context) {
          final route = ModalRoute.of(context);
          final eventArgs = route!.settings.arguments as DiscoveredEventArgs;
          return CentralDetailsScreen(
            eventArgs: eventArgs,
          );
        },
      },
    );
  }
}
