import 'package:bluetooth_service/first.dart';
import 'package:bluetooth_service/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SecondScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Second Screen"),
      ),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('${Provider.of<BluetoothProvider>(context, listen: true).log}'),
          ElevatedButton(
            onPressed: () {
              Provider.of<BluetoothProvider>(context, listen: false)
                  .scanDevice();
            },
            child: const Text('Scan Devices'),
          ),
          Consumer<BluetoothProvider>(
            builder: (context, bluetoothProvider, child) {
              return Expanded(
                child: ListView.builder(
                  itemCount: bluetoothProvider.devices.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(bluetoothProvider.devices[index].id),
                      subtitle: Text(bluetoothProvider.devices[index].id),
                      onTap: () {
                        bluetoothProvider
                            .connectToDevice(bluetoothProvider.devices[index]);
                        if (bluetoothProvider.connectedSafety) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => FirstScreen()),
                          );
                        }
                      },
                    );
                  },
                ),
              );
            },
          )
        ]),
      ),
    );
  }
}
