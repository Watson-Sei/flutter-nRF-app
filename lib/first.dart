import 'package:bluetooth_service/main.dart';
import 'package:bluetooth_service/second.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FirstScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("First Screen"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('This is the first screen'),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SecondScreen()),
                  );
                },
                child: const Text('Go to second screen')),
            if (Provider.of<BluetoothProvider>(context, listen: true)
                .connectedSafety)
              ElevatedButton(
                  onPressed: () {
                    Provider.of<BluetoothProvider>(context, listen: false)
                        .disconnectToDevice();
                  },
                  child: const Text('Disconnect')),
            Text(
                '${Provider.of<BluetoothProvider>(context, listen: true).logs}')
          ],
        ),
      ),
    );
  }
}
