import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:ble_test/connect/presentation/rssi_widget.dart';
import 'package:ble_test/core/presentation/view_models/log.dart';
import 'package:ble_test/main.dart';
import 'package:ble_test/service/utils.dart';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CentralDetailsScreen extends StatefulWidget {
  const CentralDetailsScreen({
    super.key,
    required this.eventArgs,
  });
  final DiscoveredEventArgs eventArgs;

  @override
  State<CentralDetailsScreen> createState() => _CentralDetailsScreenState();
}

class _CentralDetailsScreenState extends State<CentralDetailsScreen> {
  late final ValueNotifier<bool> state;
  late final DiscoveredEventArgs eventArgs;
  late final ValueNotifier<List<GattService>> services;
  late final ValueNotifier<List<GattCharacteristic>> characteristics;
  late final ValueNotifier<GattService?> service;
  late final ValueNotifier<GattCharacteristic?> characteristic;
  late final ValueNotifier<GattCharacteristicWriteType> writeType;
  late final ValueNotifier<int> maximumWriteLength;
  late final ValueNotifier<int> rssi;
  late final ValueNotifier<List<Log>> logs;
  late final TextEditingController writeController;
  late final StreamSubscription<PeripheralStateChangedEventArgs>
      stateChangedSubscription;
  late final StreamSubscription<GattCharacteristicValueChangedEventArgs>
      valueChangedSubscription;
  late final Timer rssiTimer;

  @override
  void initState() {
    super.initState();
    eventArgs = widget.eventArgs;
    state = ValueNotifier(false);
    services = ValueNotifier([]);
    characteristics = ValueNotifier([]);
    service = ValueNotifier(null);
    characteristic = ValueNotifier(null);
    writeType = ValueNotifier(GattCharacteristicWriteType.withResponse);
    maximumWriteLength = ValueNotifier(0);
    rssi = ValueNotifier(-100);
    logs = ValueNotifier([]);
    writeController = TextEditingController();
    stateChangedSubscription = centralManager.peripheralStateChanged.listen(
      (eventArgs) {
        if (eventArgs.peripheral != this.eventArgs.peripheral) {
          return;
        }
        final state = eventArgs.state;
        this.state.value = state;
        if (!state) {
          services.value = [];
          characteristics.value = [];
          service.value = null;
          characteristic.value = null;
          logs.value = [];
        }
      },
    );
    valueChangedSubscription = centralManager.characteristicValueChanged.listen(
      (eventArgs) {
        final characteristic = this.characteristic.value;
        if (eventArgs.characteristic != characteristic) {
          return;
        }
        const type = LogType.notify;
        final log = Log(type: type, value: eventArgs.value);
        logs.value = [
          ...logs.value,
          log,
        ];
      },
    );
    rssiTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) async {
        final state = this.state.value;
        if (state) {
          rssi.value = await centralManager.readRSSI(eventArgs.peripheral);
        } else {
          rssi.value = -100;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (state.value) {
          final peripheral = eventArgs.peripheral;
          await centralManager.disconnect(peripheral);
        }
        return true;
      },
      child: Scaffold(
        appBar: buildAppBar(context),
        body: buildBody(context),
      ),
    );
  }

  PreferredSizeWidget buildAppBar(BuildContext context) {
    final title = eventArgs.advertisement.name ?? '';
    return AppBar(
      title: Text(title),
      actions: [
        ValueListenableBuilder(
          valueListenable: state,
          builder: (context, state, child) {
            return TextButton(
              onPressed: () async {
                final peripheral = eventArgs.peripheral;
                if (state) {
                  await centralManager.disconnect(peripheral);
                  maximumWriteLength.value = 0;
                  rssi.value = 0;
                } else {
                  await centralManager.connect(peripheral);
                  services.value =
                      await centralManager.discoverGATT(peripheral);
                  maximumWriteLength.value =
                      await centralManager.getMaximumWriteLength(
                    peripheral,
                    type: writeType.value,
                  );
                  rssi.value = await centralManager.readRSSI(peripheral);
                }
              },
              child: Text(state ? 'DISCONNECT' : 'CONNECT'),
            );
          },
        ),
      ],
    );
  }

  Widget buildBody(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ValueListenableBuilder(
            valueListenable: services,
            builder: (context, services, child) {
              final items = services.map((service) {
                return DropdownMenuItem(
                  value: service,
                  child: Text(
                    '${service.uuid}',
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              }).toList();
              return ValueListenableBuilder(
                valueListenable: service,
                builder: (context, service, child) {
                  return DropdownButton(
                    isExpanded: true,
                    items: items,
                    hint: const Text('CHOOSE A SERVICE'),
                    value: service,
                    onChanged: (service) async {
                      this.service.value = service;
                      characteristic.value = null;
                      if (service == null) {
                        return;
                      }
                      characteristics.value = service.characteristics;
                    },
                  );
                },
              );
            },
          ),
          ValueListenableBuilder(
            valueListenable: characteristics,
            builder: (context, characteristics, child) {
              final items = characteristics.map((characteristic) {
                return DropdownMenuItem(
                  value: characteristic,
                  child: Text(
                    '${characteristic.uuid}',
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              }).toList();
              return ValueListenableBuilder(
                valueListenable: characteristic,
                builder: (context, characteristic, child) {
                  return DropdownButton(
                    isExpanded: true,
                    items: items,
                    hint: const Text('CHOOSE A CHARACTERISTIC'),
                    value: characteristic,
                    onChanged: (characteristic) {
                      this.characteristic.value = characteristic;
                    },
                  );
                },
              );
            },
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: logs,
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
                    final message = type == LogType.write.name
                        ? Utils.typeConverter(log.value)
                        : hex.encode(value);
                    return Text.rich(
                      TextSpan(
                        text: '[$type: current write length [${value.length}]',
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
            ),
          ),
          Row(
            children: [
              ValueListenableBuilder(
                valueListenable: writeType,
                builder: (context, writeType, child) {
                  return ToggleButtons(
                    onPressed: (i) async {
                      final type = GattCharacteristicWriteType.values[i];
                      this.writeType.value = type;
                      maximumWriteLength.value =
                          await centralManager.getMaximumWriteLength(
                        eventArgs.peripheral,
                        type: type,
                      );
                    },
                    constraints: const BoxConstraints(
                      minWidth: 0.0,
                      minHeight: 0.0,
                    ),
                    borderRadius: BorderRadius.circular(4.0),
                    isSelected: GattCharacteristicWriteType.values
                        .map((type) => type == writeType)
                        .toList(),
                    children: GattCharacteristicWriteType.values.map((type) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        child: Text(type.name),
                      );
                    }).toList(),
                  );
                  // final segments =
                  //     GattCharacteristicWriteType.values.map((type) {
                  //   return ButtonSegment(
                  //     value: type,
                  //     label: Text(type.name),
                  //   );
                  // }).toList();
                  // return SegmentedButton(
                  //   segments: segments,
                  //   selected: {writeType},
                  //   showSelectedIcon: false,
                  //   style: OutlinedButton.styleFrom(
                  //     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  //     padding: EdgeInsets.zero,
                  //     visualDensity: VisualDensity.compact,
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(8.0),
                  //     ),
                  //   ),
                  // );
                },
              ),
              const SizedBox(width: 8.0),
              ValueListenableBuilder(
                valueListenable: state,
                builder: (context, state, child) {
                  return ValueListenableBuilder(
                    valueListenable: maximumWriteLength,
                    builder: (context, maximumWriteLength, child) {
                      return Text('max: $maximumWriteLength');
                    },
                  );
                },
              ),
              const Spacer(),
              ValueListenableBuilder(
                valueListenable: rssi,
                builder: (context, rssi, child) {
                  return RssiWidget(rssi);
                },
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 16.0),
            height: 160.0,
            child: ValueListenableBuilder(
              valueListenable: characteristic,
              builder: (context, characteristic, child) {
                final bool canNotify, canRead, canWrite;
                if (characteristic == null) {
                  canNotify = canRead = canWrite = false;
                } else {
                  final properties = characteristic.properties;
                  canNotify = properties.contains(
                    GattCharacteristicProperty.notify,
                  );
                  canRead = properties.contains(
                    GattCharacteristicProperty.read,
                  );
                  canWrite = properties.contains(
                    GattCharacteristicProperty.write,
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: writeController,
                        enabled: canWrite,
                        expands: true,
                        maxLines: null,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: characteristic != null && canNotify
                              ? () => centralManager.notifyCharacteristic(
                                    characteristic,
                                    state: true,
                                  )
                              : null,
                          child: const Text('NOTIFY'),
                        ),
                        TextButton(
                          onPressed: characteristic != null && canRead
                              ? () async {
                                  final value = await centralManager
                                      .readCharacteristic(characteristic);
                                  const type = LogType.read;
                                  final log = Log(type: type, value: value);
                                  logs.value = [...logs.value, log];
                                }
                              : null,
                          child: const Text('READ'),
                        ),
                        TextButton(
                          onPressed: characteristic != null && canWrite
                              ? () async {
                                  final text = writeController.text;
                                  final elements = utf8.encode(text);
                                  final value = Uint8List.fromList(elements);
                                  final type = writeType.value;
                                  await centralManager.writeCharacteristic(
                                    characteristic,
                                    value: value,
                                    type: type,
                                  );
                                  final log =
                                      Log(type: LogType.write, value: value);
                                  logs.value = [...logs.value, log];
                                }
                              : null,
                          child: const Text('WRITE'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    rssiTimer.cancel();
    stateChangedSubscription.cancel();
    valueChangedSubscription.cancel();
    state.dispose();
    services.dispose();
    characteristics.dispose();
    service.dispose();
    characteristic.dispose();
    writeType.dispose();
    maximumWriteLength.dispose();
    rssi.dispose();
    logs.dispose();
    writeController.dispose();
  }
}
