import 'package:flutter/material.dart';

class RssiWidget extends StatelessWidget {
  const RssiWidget(
    this.rssi, {
    super.key,
  });
  final int rssi;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    if (rssi > -70) {
      icon = Icons.wifi_rounded;
    } else if (rssi > -100) {
      icon = Icons.wifi_2_bar_rounded;
    } else {
      icon = Icons.wifi_1_bar_rounded;
    }
    return Icon(icon);
  }
}
