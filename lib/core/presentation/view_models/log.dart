import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:intl/intl.dart';

class Log {
  Log(
    this.type,
    this.value, [
    this.detail,
  ]) : time = DateTime.now();

  final DateTime time;
  final LogType type;
  final Uint8List value;
  final String? detail;

  @override
  String toString() {
    final type = this.type.name;
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
