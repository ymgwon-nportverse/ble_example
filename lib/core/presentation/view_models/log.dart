import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:convert/convert.dart';
import 'package:intl/intl.dart';

class Log {
  Log({
    required this.type,
    required this.value,
    this.detail,
    this.offset,
    this.id,
    this.centralUuid,
    this.characteristicUuid,
    this.state,
  }) : time = DateTime.now();
  final DateTime time;
  final LogType type;
  final Uint8List value;
  final String? detail;
  final int? offset;
  final int? id;
  final UUID? centralUuid;
  final UUID? characteristicUuid;
  final bool? state;

  @override
  String toString() {
    final type = this.type.toString().split('.').last;
    final formatter = DateFormat.Hms();
    final time = formatter.format(this.time);
    final message = hex.encode(value);
    if (detail == null) {
      return '[$type]$time: $message';
    } else {
      return '[$type]$time: $message /* $detail */';
    }
  }
}

enum LogType {
  read,
  write,
  notify,
  error,
}
