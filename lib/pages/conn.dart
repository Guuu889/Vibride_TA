import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ta/pages/global.dart';
import 'profile.dart';
import 'dart:async';

class ConnPage extends StatefulWidget {
  const ConnPage({Key? key}) : super(key: key);

  @override
  _ConnPageState createState() => _ConnPageState();
}

class _ConnPageState extends State<ConnPage> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  bool isConnected = false;
  bool isScanning = false;
  List<DiscoveredDevice> discoveredDevices = [];
  String? connectedDeviceId;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;

  // BLE UUIDs (must match ESP32)
  final Uuid serviceUuid = Uuid.parse("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
  final Uuid characteristicUuid =
      Uuid.parse("beb5483e-36e1-4688-b7f5-ea07361b26a8");

  @override
  void initState() {
    super.initState();
    // Request Bluetooth permissions if needed (handled by the OS)
  }

  void _startScan() {
    if (isScanning) return;
    setState(() {
      isScanning = true;
      discoveredDevices.clear();
    });

    try {
      _scanSubscription = _ble.scanForDevices(
        withServices: [serviceUuid],
        scanMode: ScanMode.lowLatency,
      ).listen((device) {
        setState(() {
          if (!discoveredDevices.any((d) => d.id == device.id)) {
            discoveredDevices.add(device);
          }
        });
      }, onError: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning: $e')),
        );
        setState(() {
          isScanning = false;
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting scan: $e')),
      );
      setState(() {
        isScanning = false;
      });
    }
  }

  void _stopScan() {
    _scanSubscription?.cancel();
    setState(() {
      isScanning = false;
    });
  }

  void _connectToDevice(DiscoveredDevice device) async {
    _stopScan();
    try {
      _connectionSubscription = _ble
          .connectToDevice(
        id: device.id,
        servicesWithCharacteristicsToDiscover: {
          serviceUuid: [characteristicUuid]
        },
        connectionTimeout: const Duration(seconds: 10),
      )
          .listen((connectionState) {
        if (connectionState.connectionState ==
            DeviceConnectionState.connected) {
          setState(() {
            isConnected = true;
            Global.connectedDeviceId = device.id;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connected to ${device.name ?? device.id}')),
          );
        } else if (connectionState.connectionState ==
            DeviceConnectionState.disconnected) {
          setState(() {
            isConnected = false;
            Global.connectedDeviceId = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Disconnected')),
          );
        }
      }, onError: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error: $e')),
        );
        setState(() {
          isConnected = false;
          connectedDeviceId = null;
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect: $e')),
      );
    }
  }

  void _disconnect() async {
    if (connectedDeviceId != null) {
      _connectionSubscription?.cancel();
      setState(() {
        isConnected = false;
        connectedDeviceId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disconnected')),
      );
    }
  }

  @override
  void dispose() {
    _stopScan();
    _connectionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        'Konektivitas',
                        style: TextStyle(
                          fontFamily: 'Aileron',
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Koneksi",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: isConnected ? _disconnect : _startScan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isConnected
                                ? Colors.green.shade300
                                : Colors.blue.shade200,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            isConnected
                                ? "TERHUBUNG"
                                : isScanning
                                    ? "MEMINDAI..."
                                    : "HUBUNGKAN",
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (isScanning)
                      const Center(child: CircularProgressIndicator()),
                    Expanded(
                      child: ListView.builder(
                        itemCount: discoveredDevices.length,
                        itemBuilder: (context, index) {
                          final device = discoveredDevices[index];
                          return ListTile(
                            title: Text(device.name ?? 'Unknown Device'),
                            subtitle: Text(device.id),
                            onTap: () => _connectToDevice(device),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
