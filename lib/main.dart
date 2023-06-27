import 'dart:async';

import 'package:bluetooth_service/first.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class BluetoothProvider extends ChangeNotifier {
  // ReactiveBle instance
  final flutterReactiveBle = FlutterReactiveBle();
  String log = 'this is log';

  //　Scanning related
  List<DiscoveredDevice> devices = [];
  bool scanStarted = false;
  late StreamSubscription<DiscoveredDevice> scanStream;

  // Connection related
  bool connectedSafety = false;
  late Stream<ConnectionStateUpdate>? connection;
  Stream<List<int>>? readData;

  BluetoothProvider() {
    scanDevice();
  }

  // Scan for devices
  void scanDevice() async {
    log = 'Permission check...';
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
      if (!status.isGranted) {
        return;
      }
    }
    log = 'Scanning...';
    if (scanStarted) {
      await scanStream.cancel();
    }
    scanStream = flutterReactiveBle.scanForDevices(
      withServices: [],
    ).listen((device) {
      if (!devices.any((existingDevice) => existingDevice.id == device.id)) {
        log = 'Found ${device.name}';
        devices.add(device);
        notifyListeners();
      }
    }, onError: (e) {
      log = 'Error $e';
      notifyListeners();
    });
  }

  // Connect to the first device in the list
  void connectToDevice(DiscoveredDevice device) async {
    log = 'Connecting to ${device.name}';
    notifyListeners();
    if (scanStarted) {
      await scanStream.cancel();
      scanStarted = false;
    }
    connection = flutterReactiveBle.connectToDevice(
      id: device.id,
    );
    connection!.listen((connectionState) {
      log = 'Connection state $connectionState';
      notifyListeners();
      if (connectionState.connectionState == DeviceConnectionState.connected) {
        log = 'Connected';
        connectedSafety = true;
        notifyListeners();
        flutterReactiveBle.requestMtu(deviceId: device.id, mtu: 250);
        readCharacteristic(device);
      }
    });
  }

  void readCharacteristic(DiscoveredDevice device) async {
    log = 'Reading characteristic';
    notifyListeners();
    // ignore: non_constant_identifier_names
    final TxCharacteristic = QualifiedCharacteristic(
        characteristicId: Uuid.parse(''),
        serviceId: Uuid.parse(''),
        deviceId: device.id);
    // ignore: unused_local_variable
    final readData = flutterReactiveBle
        .subscribeToCharacteristic(TxCharacteristic)
        .listen(
            (data) => log = '${DateTime.now()}: ${String.fromCharCodes(data)}',
            onError: (dynamic error) {
      log = 'Error $error';
      connectedSafety = false;
      notifyListeners();
    });
    notifyListeners();
  }
}

void main() {
  runApp(ChangeNotifierProvider(
    create: (context) => BluetoothProvider(),
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FirstScreen(),
    );
  }
}
