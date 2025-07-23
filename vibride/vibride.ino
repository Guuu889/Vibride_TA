#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define LEFT_VIBRATION_PIN  19 // GPIO untuk motor getar kiri
#define RIGHT_VIBRATION_PIN 18 // GPIO untuk motor getar kanan

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
volatile bool newCommandReceived = false;
String currentCommand = "";

void vibrateLeft(int durationMs) {
  digitalWrite(LEFT_VIBRATION_PIN, HIGH);
  delay(durationMs);
  digitalWrite(LEFT_VIBRATION_PIN, LOW);
}

void vibrateRight(int durationMs) {
  digitalWrite(RIGHT_VIBRATION_PIN, HIGH);
  delay(durationMs);
  digitalWrite(RIGHT_VIBRATION_PIN, LOW);
}

void vibrateBoth(int durationMs) {
  digitalWrite(LEFT_VIBRATION_PIN, HIGH);
  digitalWrite(RIGHT_VIBRATION_PIN, HIGH);
  delay(durationMs);
  digitalWrite(LEFT_VIBRATION_PIN, LOW);
  digitalWrite(RIGHT_VIBRATION_PIN, LOW);
}

void vibrateUTurnRight() {
  vibrateRight(100); // 0.1s ON
  delay(100);        // 0.1s OFF
  vibrateRight(100); // 0.1s ON
  delay(100);        // 0.1s OFF
  vibrateRight(100); // 0.1s ON
  delay(500);        // 0.5s pause
}

void vibrateTurnSharpLeft() {
  vibrateBoth(100);  // Kedua koin 0.1s ON
  delay(100);        // 0.1s OFF
  vibrateLeft(100);  // Kiri 0.1s ON
  delay(100);        // 0.1s OFF
  vibrateLeft(100);  // Kiri 0.1s ON
  delay(500);        // 0.5s pause
}

void vibrateTurnSharpRight() {
  vibrateBoth(100);  // Kedua koin 0.1s ON
  delay(100);        // 0.1s OFF
  vibrateRight(100); // Kanan 0.1s ON
  delay(100);        // 0.1s OFF
  vibrateRight(100); // Kanan 0.1s ON
  delay(500);        // 0.5s pause
}

void vibrateDestinationLeft() {
  vibrateLeft(100);  // Kiri 0.1s ON
  delay(100);        // 0.1s OFF
  vibrateLeft(100);  // Kiri 0.1s ON
  delay(500);        // 0.5s pause
}

void vibrateDestinationRight() {
  vibrateRight(100); // Kanan 0.1s ON
  delay(100);        // 0.1s OFF
  vibrateRight(100); // Kanan 0.1s ON
  delay(500);        // 0.5s pause
}

class MyCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    std::string value = pCharacteristic->getValue();
    String command = String(value.c_str());
    command.trim();

    Serial.print("Received Command: ");
    Serial.println(command);

    currentCommand = command;
    newCommandReceived = true;
  }
};

void setup() {
  Serial.begin(115200);

  pinMode(LEFT_VIBRATION_PIN, OUTPUT);
  pinMode(RIGHT_VIBRATION_PIN, OUTPUT);
  digitalWrite(LEFT_VIBRATION_PIN, LOW);
  digitalWrite(RIGHT_VIBRATION_PIN, LOW);

  BLEDevice::init("ESP32_BLE");
  pServer = BLEDevice::createServer();
  BLEService *pService = pServer->createService(SERVICE_UUID);
  
  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ | 
                      BLECharacteristic::PROPERTY_WRITE | 
                      BLECharacteristic::PROPERTY_NOTIFY
                    );
  pCharacteristic->setCallbacks(new MyCallbacks());
  pCharacteristic->addDescriptor(new BLE2902());
  pCharacteristic->setValue("Ready");
  pService->start();
  
  BLEAdvertising *pAdvertising = pServer->getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMaxPreferred(0x12);
  pAdvertising->start();
  Serial.println("Advertising started");
}

void loop() {
  if (newCommandReceived) {
    newCommandReceived = false;

    // Pola getaran sederhana
    if (currentCommand == "TURN_SLIGHT_LEFT") {
    vibrateLeft(1000); // 1 detik
    Serial.println("TURN_SLIGHT_LEFT vibration triggered");
    currentCommand = ""; // Reset setelah getaran selesai
}
else if (currentCommand == "FORK_LEFT") {
    vibrateLeft(1000); // 1 detik
    Serial.println("FORK_LEFT vibration triggered");
    currentCommand = ""; // Reset setelah getaran selesai
}
else if (currentCommand == "TURN_SLIGHT_RIGHT") {
    vibrateRight(1000); // 1 detik
    Serial.println("TURN_SLIGHT_RIGHT vibration triggered");
    currentCommand = ""; // Reset setelah getaran selesai
}
else if (currentCommand == "FORK_RIGHT") {
    vibrateRight(1000); // 1 detik
    Serial.println("FORK_RIGHT vibration triggered");
    currentCommand = ""; // Reset setelah getaran selesai
}
    else if (currentCommand == "TURN_LEFT") {
      vibrateLeft(500); // 0.5 detik
      Serial.println("TURN_LEFT vibration triggered");
      currentCommand = ""; // Reset setelah getaran selesai
    }
    else if (currentCommand == "TURN_RIGHT") {
      vibrateRight(500); // 0.5 detik
      Serial.println("TURN_RIGHT vibration triggered");
      currentCommand = ""; // Reset setelah getaran selesai
    }
    else if (currentCommand == "ROUNDABOUT") {
      vibrateBoth(500); // 0.5 detik
      Serial.println("ROUNDABOUT vibration triggered");
      currentCommand = ""; // Reset setelah getaran selesai
    }
    else if (currentCommand == "STOP") {
      currentCommand = ""; // Hentikan semua getaran
      digitalWrite(LEFT_VIBRATION_PIN, LOW);
      digitalWrite(RIGHT_VIBRATION_PIN, LOW);
      Serial.println("Vibration stopped");
    }
    // Mulai loop untuk pola berulang
    else if (currentCommand == "UTURN_RIGHT" || 
             currentCommand == "TURN_SHARP_LEFT" || 
             currentCommand == "TURN_SHARP_RIGHT" || 
             currentCommand == "DESTINATION_LEFT" || 
             currentCommand == "DESTINATION_RIGHT") {
      Serial.println("Starting loop for " + currentCommand);
    }
    else {
      Serial.println("Unknown command");
      currentCommand = ""; // Reset untuk perintah tidak dikenal
    }
  }

  // Loop untuk pola getaran berulang
  if (currentCommand == "UTURN_RIGHT") {
    vibrateUTurnRight();
  }
  else if (currentCommand == "TURN_SHARP_LEFT") {
    vibrateTurnSharpLeft();
  }
  else if (currentCommand == "TURN_SHARP_RIGHT") {
    vibrateTurnSharpRight();
  }
  else if (currentCommand == "DESTINATION_LEFT") {
    vibrateDestinationLeft();
  }
  else if (currentCommand == "DESTINATION_RIGHT") {
    vibrateDestinationRight();
  }
}