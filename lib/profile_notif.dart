import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import '../pages/global.dart';

class ProfileNotifPage extends StatefulWidget {
  @override
  _ProfileNotifPageState createState() => _ProfileNotifPageState();
}

class _ProfileNotifPageState extends State<ProfileNotifPage> {
  bool isBatteryLow = false;
  bool isHeadsetConnected = true;
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  final List<String> vibrationNotifications = [
    "Belok kiri",
    "Belok kanan",
    "Putar balik ke kanan",
    "Ambil cabang jalan kiri",
    "Ambil cabang jalan kanan",
    "Ambil belokan kiri",
    "Ambil belokan kanan",
    "Belok tajam ke kiri",
    "Belok tajam ke kanan",
    "Belok bundaran",
    "Lokasi tujuan di kiri",
    "Lokasi tujuan di kanan",
  ];

  Future<void> sendVibrationCommand(String command) async {
    if (Global.connectedDeviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak ada ESP32 yang terhubung')),
      );
      return;
    }

    try {
      final qualifiedCharacteristic = QualifiedCharacteristic(
        serviceId: Global.serviceUuid,
        characteristicId: Global.characteristicUuid,
        deviceId: Global.connectedDeviceId!,
      );
      await _ble.writeCharacteristicWithoutResponse(
        qualifiedCharacteristic,
        value: command.codeUnits,
      );
      print('Mengirim perintah vibrasi: $command');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Getaran $command dikirim ke ESP32')),
      );
    } catch (e) {
      print('Error mengirim perintah vibrasi: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim perintah: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0E1756),
      body: Stack(
        children: [
          Positioned(
            top: 40,
            left: 16,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.arrow_back, color: Color(0xFF0E1756)),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.87,
              decoration: BoxDecoration(
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
                    SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Notifikasi',
                        style: TextStyle(
                          fontFamily: 'Aileron',
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "NOTIFIKASI HEADSET VIBRASI",
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: vibrationNotifications.length,
                        itemBuilder: (context, index) {
                          return vibrationTestItem(
                              vibrationNotifications[index]);
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

  Widget notificationItem(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Color(0xFF0E1756),
          ),
        ],
      ),
    );
  }

  Widget vibrationTestItem(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (title == "Belok kiri") {
                sendVibrationCommand("TURN_LEFT");
              } else if (title == "Belok kanan") {
                sendVibrationCommand("TURN_RIGHT");
              } else if (title == "Putar balik ke kanan") {
                sendVibrationCommand("UTURN_RIGHT");
              } else if (title == "Ambil cabang jalan kiri") {
                sendVibrationCommand("FORK_LEFT");
              } else if (title == "Ambil cabang jalan kanan") {
                sendVibrationCommand("FORK_RIGHT");
              } else if (title == "Ambil belokan kiri") {
                sendVibrationCommand("TURN_SLIGHT_LEFT");
              } else if (title == "Ambil belokan kanan") {
                sendVibrationCommand("TURN_SLIGHT_RIGHT");
              } else if (title == "Belok tajam ke kiri") {
                sendVibrationCommand("TURN_SHARP_LEFT");
              } else if (title == "Belok tajam ke kanan") {
                sendVibrationCommand("TURN_SHARP_RIGHT");
              } else if (title == "Belok bundaran") {
                sendVibrationCommand("ROUNDABOUT");
              } else if (title == "Lokasi tujuan di kiri") {
                sendVibrationCommand("DESTINATION_LEFT");
              } else if (title == "Lokasi tujuan di kanan") {
                sendVibrationCommand("DESTINATION_RIGHT");
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade100,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              "TEST",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
