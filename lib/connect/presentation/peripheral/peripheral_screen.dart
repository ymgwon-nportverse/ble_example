import 'dart:async';
import 'dart:typed_data';

import 'package:ble_test/core/presentation/view_models/log.dart';
import 'package:ble_test/main.dart';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PeripheralScreen extends StatefulWidget {
  const PeripheralScreen({super.key});

  @override
  State<PeripheralScreen> createState() => _PeripheralScreenState();
}

class _PeripheralScreenState extends State<PeripheralScreen>
    with SingleTickerProviderStateMixin {
  late final ValueNotifier<BluetoothLowEnergyState> _state;
  late final ValueNotifier<bool> _advertising;
  late final ValueNotifier<List<Log>> _logs;
  late final StreamSubscription<BluetoothLowEnergyStateChangedEventArgs>
      _stateChangedSubscription;
  late final StreamSubscription<ReadGattCharacteristicCommandEventArgs>
      _readCharacteristicCommandReceivedSubscription;
  late final StreamSubscription<WriteGattCharacteristicCommandEventArgs>
      _writeCharacteristicCommandReceivedSubscription;
  late final StreamSubscription<NotifyGattCharacteristicCommandEventArgs>
      notifyCharacteristicCommandReceivedSubscription;

  @override
  void initState() {
    super.initState();
    _state = ValueNotifier(peripheralManager.state);
    _advertising = ValueNotifier(false);
    _logs = ValueNotifier([]);
    _stateChangedSubscription = peripheralManager.stateChanged.listen(
      (eventArgs) {
        _state.value = eventArgs.state;
      },
    );
    _readCharacteristicCommandReceivedSubscription =
        peripheralManager.readCharacteristicCommandReceived.listen(
      (eventArgs) async {
        final central = eventArgs.central;
        final characteristic = eventArgs.characteristic;
        final id = eventArgs.id;
        final offset = eventArgs.offset;
        final log = Log(
          LogType.read,
          Uint8List.fromList([]),
          'central: ${central.uuid}; characteristic: ${characteristic.uuid}; id: $id; offset: $offset',
        );
        _logs.value = [
          ..._logs.value,
          log,
        ];
        // final maximumWriteLength = peripheralManager.getMaximumWriteLength(
        //   central,
        // );
        const status = true;
        final value = Uint8List.fromList([0x01, 0x02, 0x03]);
        await peripheralManager.sendReadCharacteristicReply(
          central,
          characteristic: characteristic,
          id: id,
          offset: offset,
          status: status,
          value: value,
        );
      },
    );
    _writeCharacteristicCommandReceivedSubscription =
        peripheralManager.writeCharacteristicCommandReceived.listen(
      (eventArgs) async {
        final central = eventArgs.central;
        final characteristic = eventArgs.characteristic;
        final id = eventArgs.id;
        final offset = eventArgs.offset;
        final value = eventArgs.value;
        final log = Log(
          LogType.write,
          value,
          'central: ${central.uuid}; characteristic: ${characteristic.uuid}; id: $id; offset: $offset',
        );
        _logs.value = [
          ..._logs.value,
          log,
        ];
        const status = true;
        await peripheralManager.sendWriteCharacteristicReply(
          central,
          characteristic: characteristic,
          id: id,
          offset: offset,
          status: status,
        );
      },
    );
    notifyCharacteristicCommandReceivedSubscription =
        peripheralManager.notifyCharacteristicCommandReceived.listen(
      (eventArgs) async {
        final central = eventArgs.central;
        final characteristic = eventArgs.characteristic;
        final state = eventArgs.state;
        final log = Log(
          LogType.write,
          Uint8List.fromList([]),
          'central: ${central.uuid}; characteristic: ${characteristic.uuid}; state: $state',
        );
        _logs.value = [
          ..._logs.value,
          log,
        ];
        // Write something to the central when notify started.
        if (state) {
          final value = Uint8List.fromList([0x03, 0x02, 0x01]);
          await peripheralManager.notifyCharacteristicValueChanged(
            central,
            characteristic: characteristic,
            value: value,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: buildBody(context),
    );
  }

  PreferredSizeWidget buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Advertiser'),
      actions: [
        ValueListenableBuilder(
          valueListenable: _state,
          builder: (context, state, child) {
            return ValueListenableBuilder(
              valueListenable: _advertising,
              builder: (context, advertising, child) {
                return TextButton(
                  onPressed: state == BluetoothLowEnergyState.poweredOn
                      ? () async {
                          if (advertising) {
                            await stopAdvertising();
                          } else {
                            await startAdvertising();
                          }
                        }
                      : null,
                  child: Text(
                    advertising ? 'END' : 'BEGIN',
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> startAdvertising() async {
    await peripheralManager.clearServices();
    final service = GattService(
      uuid: UUID.short(100),
      characteristics: [
        GattCharacteristic(
          uuid: UUID.short(200),
          properties: [
            GattCharacteristicProperty.read,
          ],
          descriptors: [],
        ),
        GattCharacteristic(
          uuid: UUID.short(201),
          properties: [
            GattCharacteristicProperty.read,
            GattCharacteristicProperty.write,
            GattCharacteristicProperty.writeWithoutResponse,
          ],
          descriptors: [],
        ),
        GattCharacteristic(
          uuid: UUID.short(202),
          properties: [
            GattCharacteristicProperty.notify,
            GattCharacteristicProperty.indicate,
          ],
          descriptors: [],
        ),
      ],
    );
    await peripheralManager.addService(service);
    final advertisement = Advertisement(
      name: 'hello',
      manufacturerSpecificData: ManufacturerSpecificData(
        id: 0x2e19,
        data: Uint8List.fromList([0x01, 0x02, 0x03]),
      ),
    );
    await peripheralManager.startAdvertising(advertisement);
    _advertising.value = true;
  }

  Future<void> stopAdvertising() async {
    await peripheralManager.stopAdvertising();
    _advertising.value = false;
  }

  Widget buildBody(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder(
      valueListenable: _logs,
      builder: (context, logs, child) {
        return ListView.builder(
          itemBuilder: (context, i) {
            final log = logs[i];
            final type = log.type.name.toUpperCase().characters.first;
            final Color typeColor;
            switch (log.type) {
              case LogType.read:
                typeColor = Colors.blue;
                break;
              case LogType.write:
                typeColor = Colors.amber;
                break;
              case LogType.notify:
                typeColor = Colors.red;
                break;
              default:
                typeColor = Colors.black;
            }
            final time = DateFormat.Hms().format(log.time);
            final value = log.value;
            final message = '${log.detail}; ${hex.encode(value)}';
            return Text.rich(
              TextSpan(
                text: '[$type:${value.length}]',
                children: [
                  TextSpan(
                    text: ' $time: ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.green,
                    ),
                  ),
                  TextSpan(
                    text: message,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: typeColor,
                ),
              ),
            );
          },
          itemCount: logs.length,
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _stateChangedSubscription.cancel();
    _readCharacteristicCommandReceivedSubscription.cancel();
    _writeCharacteristicCommandReceivedSubscription.cancel();
    notifyCharacteristicCommandReceivedSubscription.cancel();
    _state.dispose();
    _advertising.dispose();
    _logs.dispose();
  }
}
