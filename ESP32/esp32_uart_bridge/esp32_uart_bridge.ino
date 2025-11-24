/*
 * ESP32 UART BRIDGE - For Programming ESP32-CAM
 * 
 * Purpose:
 * Use regular ESP32 as USB-to-Serial adapter to program ESP32-CAM
 * 
 * Wiring:
 * ESP32 (This) → ESP32-CAM
 * GPIO17 (TX2) → U0R (RX)
 * GPIO16 (RX2) → U0T (TX)
 * GND          → GND
 * 5V           → 5V
 * 
 * For Upload Mode:
 * Connect GPIO0 of ESP32-CAM to GND
 * 
 * Usage:
 * 1. Upload this code to regular ESP32
 * 2. Wire ESP32 to ESP32-CAM as above
 * 3. Connect GPIO0 of ESP32-CAM to GND
 * 4. Select Board: "AI Thinker ESP32-CAM"
 * 5. Select Port: (Port of this ESP32)
 * 6. Upload your ESP32-CAM code
 * 7. After upload, disconnect GPIO0 from GND
 * 8. Press RST button on ESP32-CAM
 */

void setup() {
  // Serial for USB communication (to PC)
  Serial.begin(115200);
  
  // Serial2 for UART communication (to ESP32-CAM)
  // RX2 = GPIO16, TX2 = GPIO17
  Serial2.begin(115200, SERIAL_8N1, 16, 17);
  
  Serial.println("\n========================================");
  Serial.println("ESP32 UART BRIDGE FOR ESP32-CAM");
  Serial.println("========================================");
  Serial.println("✓ Bridge mode active");
  Serial.println("✓ Ready to program ESP32-CAM");
  Serial.println("\nWiring:");
  Serial.println("  ESP32 GPIO17 (TX2) → ESP32-CAM U0R");
  Serial.println("  ESP32 GPIO16 (RX2) → ESP32-CAM U0T");
  Serial.println("  ESP32 GND → ESP32-CAM GND");
  Serial.println("  ESP32 5V → ESP32-CAM 5V");
  Serial.println("\nFor upload mode:");
  Serial.println("  Connect ESP32-CAM GPIO0 → GND");
  Serial.println("========================================\n");
}

void loop() {
  // Forward data from PC (Serial) to ESP32-CAM (Serial2)
  if (Serial.available()) {
    Serial2.write(Serial.read());
  }
  
  // Forward data from ESP32-CAM (Serial2) to PC (Serial)
  if (Serial2.available()) {
    Serial.write(Serial2.read());
  }
}
