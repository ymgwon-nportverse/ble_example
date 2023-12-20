import 'dart:async';
import 'dart:developer';

import 'package:ble_test/core/main_app.dart';
import 'package:ble_test/service/device_info_manager.dart';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter/material.dart';

CentralManager get centralManager => CentralManager.instance;

PeripheralManager get peripheralManager => PeripheralManager.instance;

void main() {
  runZonedGuarded(onStartUp, onCrashed);
}

void onStartUp() async {
  Logger.root.onRecord.listen(onLogRecord);
  WidgetsFlutterBinding.ensureInitialized();
  await centralManager.setUp();
  await peripheralManager.setUp();
  final deviceInfo = BLEDeviceInfo();

  ///todo
  ///디바이스 인포 나중에 name 말고 전체 map으로 보내주기
  final name = await deviceInfo.getDeviceName();
  runApp(MainApp(
    deviceInfo: name,
  ));
}

void onCrashed(Object error, StackTrace stackTrace) {
  Logger.root.shout('App crashed.', error, stackTrace);
}

void onLogRecord(LogRecord record) {
  log(
    record.message,
    time: record.time,
    sequenceNumber: record.sequenceNumber,
    level: record.level.value,
    name: record.loggerName,
    zone: record.zone,
    error: record.error,
    stackTrace: record.stackTrace,
  );
}
