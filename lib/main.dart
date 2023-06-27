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
  List<String> logs = [];

  //　Scanning related
  List<DiscoveredDevice> devices = [];
  bool scanStarted = false;
  late StreamSubscription<DiscoveredDevice> scanStream;

  // Connection related
  bool connectedSafety = false;
  late StreamSubscription<ConnectionStateUpdate> connection;
  StreamSubscription<List<int>>? readData;

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
    scanStarted = true;
    notifyListeners();
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
  Future<void> connectToDevice(DiscoveredDevice device) async {
    Completer<void> completer = Completer();
    log = 'Connecting to ${device.name}';
    if (scanStarted) {
      await scanStream.cancel();
      scanStarted = false;
      notifyListeners();
    }
    connection = flutterReactiveBle
        .connectToDevice(
            id: device.id, connectionTimeout: Duration(seconds: 10))
        .listen((connectionState) {
      log = 'Connection state $connectionState';
      notifyListeners();
      if (connectionState.connectionState == DeviceConnectionState.connected) {
        log = 'Connected';
        connectedSafety = true;
        flutterReactiveBle.requestMtu(deviceId: device.id, mtu: 250);
        notifyListeners();
        if (!completer.isCompleted) {
          completer.complete();
        }
        readCharacteristic(device);
      }
    }, onError: (dynamic error) {
      log = 'Error $error';
      connectedSafety = false;
    });
    return completer.future;
  }

  void readCharacteristic(DiscoveredDevice device) async {
    log = 'Reading characteristic';
    notifyListeners();
    // ignore: non_constant_identifier_names
    final TxCharacteristic = QualifiedCharacteristic(
        characteristicId: Uuid.parse('6e400003-b5a3-f393-e0a9-e50e24dcca9e'),
        serviceId: Uuid.parse('6e400001-b5a3-f393-e0a9-e50e24dcca9e'),
        deviceId: device.id);
    // ignore: unused_local_variable
    final readData = flutterReactiveBle
        .subscribeToCharacteristic(TxCharacteristic)
        .listen((data) {
      log = '${DateTime.now()}: ${String.fromCharCodes(data)}';
      notifyListeners();
      logs.add(String.fromCharCodes(data));
      notifyListeners();
    }, onError: (dynamic error) {
      log = 'Error $error';
      connectedSafety = false;
      notifyListeners();
    });
    notifyListeners();
  }

  disconnectToDevice() async {
    log = 'Disconnecting';
    notifyListeners();
    await readData?.cancel();
    await connection.cancel();
    scanStarted = true;
    connectedSafety = false;
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
