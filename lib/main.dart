import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: BluetoothApp(),
    );
  }
}

class BluetoothApp extends StatefulWidget {
  const BluetoothApp({super.key});

  @override
  BluetoothAppState createState() => BluetoothAppState();
}

class BluetoothAppState extends State<BluetoothApp> {
  List<BluetoothDevice> devicesList = [];
  String scanStatus = "";
  FlutterBlue flutterBlue = FlutterBlue.instance;

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  void scanForDevices() async {
    setState(() {
      scanStatus = "Memindai perangkat...";
      devicesList.clear();
    });

    flutterBlue.startScan(timeout: const Duration(seconds: 20));

    flutterBlue.scanResults.listen((results) {
      setState(() {
        for (ScanResult r in results) {
          if (!devicesList.any((d) => d.id == r.device.id)) {
            devicesList.add(r.device);
            _fetchDeviceName(r.device);
          }
        }
      });
    }).onError((error) {
      setState(() {
        scanStatus = "Kesalahan pemindaian: $error";
      });
    });

    await Future.delayed(const Duration(seconds: 20));
    flutterBlue.stopScan();

    setState(() {
      scanStatus = devicesList.isEmpty
          ? "Tidak ada perangkat tersedia"
          : "Pindai selesai";
    });
  }

  Future<void> _fetchDeviceName(BluetoothDevice device) async {
    if (device.name.isEmpty) {
      try {
        await device.connect();
        List<BluetoothService> services = await device.discoverServices();
        await device.disconnect();
        if (services.isNotEmpty) {
          setState(() {
            int index = devicesList.indexWhere((d) => d.id == device.id);
            if (index != -1) {
              devicesList[index] =
                  device; // Update the device in the list directly
            }
          });
        }
      } catch (e) {
        print("Error fetching device name: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Device Detector'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: scanForDevices,
            child: const Text('Scan Device'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: devicesList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(devicesList[index].name.isNotEmpty
                      ? devicesList[index].name
                      : 'Unknown Device'),
                  subtitle: Text(devicesList[index].id.toString()),
                  onTap: () => connectToDevice(devicesList[index]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(scanStatus),
          ),
        ],
      ),
    );
  }

  void connectToDevice(BluetoothDevice device) async {
    await device.connect();
    // Implement further logic to handle connected device
  }
}