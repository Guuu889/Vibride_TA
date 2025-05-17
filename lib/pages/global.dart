import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class Global {
  static String? connectedDeviceId;
  static Uuid serviceUuid = Uuid.parse("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
  static Uuid characteristicUuid =
      Uuid.parse("beb5483e-36e1-4688-b7f5-ea07361b26a8");
}
