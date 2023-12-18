import 'package:ble_test/connect/presentation/central/central_screen.dart';
import 'package:ble_test/connect/presentation/peripheral/peripheral_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PageController controller;

  @override
  void initState() {
    super.initState();
    controller = PageController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: buildBody(context),
      bottomNavigationBar: buildBottomNavigationBar(context),
    );
  }

  Widget buildBody(BuildContext context) {
    return PageView.builder(
      controller: controller,
      itemBuilder: (context, i) {
        switch (i) {
          case 0:
            return const CentralScreen();
          case 1:
            return const PeripheralScreen();
          default:
            throw ArgumentError.value(i);
        }
      },
      itemCount: 2,
    );
  }

  Widget buildBottomNavigationBar(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return BottomNavigationBar(
          onTap: (i) {
            const duration = Duration(milliseconds: 300);
            const curve = Curves.ease;
            controller.animateToPage(
              i,
              duration: duration,
              curve: curve,
            );
          },
          currentIndex: controller.page?.toInt() ?? 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.radar),
              label: 'scanner',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sensors),
              label: 'advertiser',
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }
}
