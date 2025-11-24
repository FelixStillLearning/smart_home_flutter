/*
 * ESP32 MAIN CONTROLLER - Smart Home Door Access System
 * 
 * Features:
 * - DHT22 (Temperature & Humidity)
 * - MQ-2 (Gas Sensor)
 * - LDR (Light Sensor)
 * - JM-101B Fingerprint Sensor
 * - 4x4 Keypad
 * - Relay for Solenoid Door Lock
 * - Relay for Lamp Control
 * - Relay for Curtain Control
 * - MQTT Communication with ESP32-CAM
 * 
 * Hardware Connections:
 * - DHT22        → GPIO 21
 * - LDR          → GPIO 34 (ADC)
 * - MQ-2         → GPIO 35 (ADC)
 * - Fingerprint  → RX2(GPIO16), TX2(GPIO17)
 * - Keypad Rows  → GPIO 13, 12, 14, 27
 * - Keypad Cols  → GPIO 26, 25, 33, 32
 * - Relay Door   → GPIO 4
 * - Relay Lamp   → GPIO 2
 * - Relay Curtain→ GPIO 15
 * - Buzzer       → GPIO 5
 */

#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>
#include <ArduinoJson.h>
#include <Keypad.h>
#include <Adafruit_Fingerprint.h>

// ================== WIFI CONFIGURATION ==================
const char* ssid = "Virendra";        
const char* password = "Faturahman"; 

// ================== MQTT CONFIGURATION ==================
const char* mqtt_broker = "192.168.1.100";  // Laragon IP (ganti sesuai IP Laragon Anda)
const int mqtt_port = 1883;
const char* mqtt_client_id = "ESP32_MainController_001";

// MQTT Topics - Publish (ESP32 → Backend)
const char* topic_temperature = "smarthome/sensor/temperature";
const char* topic_humidity = "smarthome/sensor/humidity";
const char* topic_gas = "smarthome/sensor/gas";
const char* topic_light = "smarthome/sensor/light";
const char* topic_fingerprint = "smarthome/access/fingerprint";
const char* topic_keypad = "smarthome/access/keypad";
const char* topic_door_status = "smarthome/status/door";

// MQTT Topics - Subscribe (Backend → ESP32)
const char* topic_control_door = "smarthome/control/door";
const char* topic_control_lamp = "smarthome/control/lamp";
const char* topic_control_curtain = "smarthome/control/curtain";
const char* topic_control_buzzer = "smarthome/control/buzzer";
const char* topic_lockout = "smarthome/control/lockout";

// MQTT Topics - Communication with ESP32-CAM
const char* topic_face_detected = "smarthome/camera/face_detected";
const char* topic_unknown_face = "smarthome/camera/unknown_face";

// ================== SENSOR SETUP ==================
#define DHTPIN 21
#define DHTTYPE DHT22
#define LDR_PIN 34
#define MQ_PIN 35

DHT dht(DHTPIN, DHTTYPE);

// ================== FINGERPRINT SENSOR (JM-101B) ==================
#define FINGERPRINT_RX 16
#define FINGERPRINT_TX 17
HardwareSerial fingerprintSerial(2);
Adafruit_Fingerprint finger = Adafruit_Fingerprint(&fingerprintSerial);

// ================== KEYPAD 4x4 ==================
const byte ROWS = 4;
const byte COLS = 4;
char keys[ROWS][COLS] = {
  {'1','2','3','A'},
  {'4','5','6','B'},
  {'7','8','9','C'},
  {'*','0','#','D'}
};
byte rowPins[ROWS] = {13, 12, 14, 27};
byte colPins[COLS] = {26, 25, 33, 32};
Keypad keypad = Keypad(makeKeymap(keys), rowPins, colPins, ROWS, COLS);

String enteredPIN = "";
const int PIN_LENGTH = 6;

// ================== RELAY & ACTUATOR PINS ==================
#define RELAY_DOOR 4
#define RELAY_LAMP 2
#define RELAY_CURTAIN 15
#define BUZZER_PIN 5

// ================== DOOR LOCK CONTROL ==================
bool doorUnlocked = false;
unsigned long doorUnlockTime = 0;
const unsigned long DOOR_UNLOCK_DURATION = 5000; // 5 seconds

// ================== SYSTEM LOCKOUT (Security) ==================
bool systemLocked = false;
unsigned long lockoutEndTime = 0;

// ================== MQTT CLIENT ==================
WiFiClient espClient;
PubSubClient mqtt_client(espClient);

// ================== TIMING VARIABLES ==================
unsigned long lastSensorPublish = 0;
const unsigned long SENSOR_PUBLISH_INTERVAL = 2000; // 2 seconds

unsigned long lastFingerprintCheck = 0;
const unsigned long FINGERPRINT_CHECK_INTERVAL = 500; // 0.5 seconds

// ================== SETUP ==================
void setup() {
  Serial.begin(115200);
  Serial.println("\n\n========================================");
  Serial.println("ESP32 MAIN CONTROLLER - Smart Door Lock");
  Serial.println("========================================\n");
  
  // Initialize sensors
  dht.begin();
  Serial.println("✓ DHT22 sensor ready");
  
  // Initialize fingerprint sensor
  fingerprintSerial.begin(57600, SERIAL_8N1, FINGERPRINT_RX, FINGERPRINT_TX);
  if (finger.verifyPassword()) {
    Serial.println("✓ Fingerprint sensor ready");
  } else {
    Serial.println("✗ Fingerprint sensor not found!");
  }
  
  // Initialize relay pins
  pinMode(RELAY_DOOR, OUTPUT);
  pinMode(RELAY_LAMP, OUTPUT);
  pinMode(RELAY_CURTAIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  
  // Set all relays to OFF (LOW = OFF for active-low relay)
  digitalWrite(RELAY_DOOR, LOW);
  digitalWrite(RELAY_LAMP, LOW);
  digitalWrite(RELAY_CURTAIN, LOW);
  digitalWrite(BUZZER_PIN, LOW);
  
  Serial.println("✓ Relay modules ready");
  
  // Connect to WiFi
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\n✓ WiFi connected!");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
  
  // Setup MQTT
  mqtt_client.setServer(mqtt_broker, mqtt_port);
  mqtt_client.setCallback(mqttCallback);
  
  // Connect to MQTT
  reconnectMQTT();
  
  Serial.println("\n========================================");
  Serial.println("✓ System Ready!");
  Serial.println("========================================\n");
}

// ================== MQTT CALLBACK (Handle incoming messages) ==================
void mqttCallback(char* topic, byte* payload, unsigned int length) {
  Serial.print("📥 Message arrived [");
  Serial.print(topic);
  Serial.print("]: ");
  
  // Parse JSON payload
  StaticJsonDocument<256> doc;
  DeserializationError error = deserializeJson(doc, payload, length);
  
  if (error) {
    Serial.println("Failed to parse JSON");
    return;
  }
  
  // Print payload
  serializeJsonPretty(doc, Serial);
  Serial.println();
  
  // Handle different topics
  if (strcmp(topic, topic_control_door) == 0) {
    handleDoorControl(doc);
  }
  else if (strcmp(topic, topic_control_lamp) == 0) {
    handleLampControl(doc);
  }
  else if (strcmp(topic, topic_control_curtain) == 0) {
    handleCurtainControl(doc);
  }
  else if (strcmp(topic, topic_control_buzzer) == 0) {
    handleBuzzerControl(doc);
  }
  else if (strcmp(topic, topic_lockout) == 0) {
    handleSystemLockout(doc);
  }
  else if (strcmp(topic, topic_face_detected) == 0) {
    handleFaceDetected(doc);
  }
  else if (strcmp(topic, topic_unknown_face) == 0) {
    handleUnknownFace(doc);
  }
}

// ================== HANDLE FACE DETECTED (from ESP32-CAM) ==================
void handleFaceDetected(JsonDocument& doc) {
  int userId = doc["user_id"];
  float confidence = doc["confidence"];
  
  Serial.printf("✅ Face detected! User ID: %d, Confidence: %.2f\n", userId, confidence);
  
  if (systemLocked) {
    Serial.println("⚠️ System is locked. Access denied.");
    triggerBuzzer(3, 200); // 3 short beeps
    return;
  }
  
  if (confidence > 0.85) {
    Serial.println("🔓 Face recognized! Unlocking door...");
    unlockDoor("face", userId);
  } else {
    Serial.println("⚠️ Low confidence. Access denied.");
    triggerBuzzer(2, 300);
  }
}

// ================== HANDLE UNKNOWN FACE ==================
void handleUnknownFace(JsonDocument& doc) {
  Serial.println("⚠️ Unknown face detected!");
  
  // Trigger alarm buzzer
  triggerBuzzer(5, 100); // 5 rapid beeps
  
  // Log ke serial (backend sudah handle alert)
  Serial.println("📸 Photo captured and sent to backend");
}

// ================== HANDLE DOOR CONTROL ==================
void handleDoorControl(JsonDocument& doc) {
  String action = doc["action"].as<String>();
  
  if (systemLocked && action == "UNLOCK") {
    Serial.println("⚠️ System is locked. Remote unlock denied.");
    return;
  }
  
  if (action == "UNLOCK") {
    int userId = doc["user_id"] | 0;
    unlockDoor("remote", userId);
  } 
  else if (action == "LOCK") {
    lockDoor();
  }
}

// ================== HANDLE LAMP CONTROL ==================
void handleLampControl(JsonDocument& doc) {
  String action = doc["action"].as<String>();
  
  if (action == "ON") {
    digitalWrite(RELAY_LAMP, HIGH);
    Serial.println("💡 Lamp turned ON");
  } 
  else if (action == "OFF") {
    digitalWrite(RELAY_LAMP, LOW);
    Serial.println("💡 Lamp turned OFF");
  }
  
  // Publish status
  publishDeviceStatus("lamp", action);
}

// ================== HANDLE CURTAIN CONTROL ==================
void handleCurtainControl(JsonDocument& doc) {
  String action = doc["action"].as<String>();
  int percentage = doc["percentage"] | 100;
  
  if (action == "OPEN") {
    digitalWrite(RELAY_CURTAIN, HIGH);
    Serial.printf("🪟 Curtain opening to %d%%\n", percentage);
    
    // Simulate motor duration (percentage * 10ms per %)
    delay(percentage * 10);
    digitalWrite(RELAY_CURTAIN, LOW);
    
    Serial.println("🪟 Curtain opened");
  } 
  else if (action == "CLOSE") {
    digitalWrite(RELAY_CURTAIN, HIGH);
    Serial.println("🪟 Curtain closing");
    
    delay(percentage * 10);
    digitalWrite(RELAY_CURTAIN, LOW);
    
    Serial.println("🪟 Curtain closed");
  }
  
  publishDeviceStatus("curtain", action);
}

// ================== HANDLE BUZZER CONTROL ==================
void handleBuzzerControl(JsonDocument& doc) {
  String action = doc["action"].as<String>();
  
  if (action == "ALARM") {
    int duration = doc["duration"] | 3;
    triggerBuzzer(duration * 2, 200);
  }
}

// ================== HANDLE SYSTEM LOCKOUT ==================
void handleSystemLockout(JsonDocument& doc) {
  String action = doc["action"].as<String>();
  
  if (action == "LOCKOUT") {
    int duration = doc["duration"] | 300; // default 5 minutes
    systemLocked = true;
    lockoutEndTime = millis() + (duration * 1000);
    
    Serial.printf("🔒 SYSTEM LOCKED for %d seconds\n", duration);
    triggerBuzzer(10, 100); // Long alarm
  }
}

// ================== UNLOCK DOOR FUNCTION ==================
void unlockDoor(String method, int userId) {
  digitalWrite(RELAY_DOOR, HIGH);
  doorUnlocked = true;
  doorUnlockTime = millis();
  
  Serial.println("🔓 Door UNLOCKED");
  
  // Beep once
  triggerBuzzer(1, 500);
  
  // Publish door status
  StaticJsonDocument<256> doc;
  doc["device"] = mqtt_client_id;
  doc["status"] = "unlocked";
  doc["method"] = method;
  doc["user_id"] = userId;
  doc["timestamp"] = millis();
  
  char jsonBuffer[256];
  serializeJson(doc, jsonBuffer);
  mqtt_client.publish(topic_door_status, jsonBuffer);
}

// ================== LOCK DOOR FUNCTION ==================
void lockDoor() {
  digitalWrite(RELAY_DOOR, LOW);
  doorUnlocked = false;
  
  Serial.println("🔒 Door LOCKED");
  
  // Beep twice
  triggerBuzzer(2, 200);
  
  // Publish door status
  StaticJsonDocument<256> doc;
  doc["device"] = mqtt_client_id;
  doc["status"] = "locked";
  doc["timestamp"] = millis();
  
  char jsonBuffer[256];
  serializeJson(doc, jsonBuffer);
  mqtt_client.publish(topic_door_status, jsonBuffer);
}

// ================== BUZZER FUNCTION ==================
void triggerBuzzer(int count, int duration) {
  for (int i = 0; i < count; i++) {
    digitalWrite(BUZZER_PIN, HIGH);
    delay(duration);
    digitalWrite(BUZZER_PIN, LOW);
    if (i < count - 1) delay(duration);
  }
}

// ================== PUBLISH DEVICE STATUS ==================
void publishDeviceStatus(String deviceType, String status) {
  StaticJsonDocument<256> doc;
  doc["device"] = mqtt_client_id;
  doc["device_type"] = deviceType;
  doc["status"] = status;
  doc["timestamp"] = millis();
  
  char jsonBuffer[256];
  serializeJson(doc, jsonBuffer);
  
  String topic = "smarthome/status/" + deviceType;
  mqtt_client.publish(topic.c_str(), jsonBuffer);
}

// ================== CHECK FINGERPRINT ==================
void checkFingerprint() {
  uint8_t p = finger.getImage();
  if (p != FINGERPRINT_OK) return;
  
  p = finger.image2Tz();
  if (p != FINGERPRINT_OK) return;
  
  p = finger.fingerFastSearch();
  if (p == FINGERPRINT_OK) {
    Serial.printf("✅ Fingerprint matched! ID: %d, Confidence: %d\n", 
                  finger.fingerID, finger.confidence);
    
    if (systemLocked) {
      Serial.println("⚠️ System is locked. Access denied.");
      triggerBuzzer(3, 200);
      return;
    }
    
    // Publish fingerprint access
    StaticJsonDocument<256> doc;
    doc["device"] = mqtt_client_id;
    doc["fingerprint_id"] = finger.fingerID;
    doc["confidence"] = finger.confidence;
    doc["timestamp"] = millis();
    
    char jsonBuffer[256];
    serializeJson(doc, jsonBuffer);
    mqtt_client.publish(topic_fingerprint, jsonBuffer);
    
    // Backend will validate and send unlock command if valid
    
  } else if (p == FINGERPRINT_NOTFOUND) {
    Serial.println("❌ Fingerprint not found");
    triggerBuzzer(2, 300);
    
    // Publish failed attempt
    StaticJsonDocument<256> doc;
    doc["device"] = mqtt_client_id;
    doc["fingerprint_id"] = -1;
    doc["success"] = false;
    doc["timestamp"] = millis();
    
    char jsonBuffer[256];
    serializeJson(doc, jsonBuffer);
    mqtt_client.publish(topic_fingerprint, jsonBuffer);
  }
}

// ================== CHECK KEYPAD ==================
void checkKeypad() {
  char key = keypad.getKey();
  
  if (key) {
    Serial.print("Key pressed: ");
    Serial.println(key);
    
    // Beep feedback
    digitalWrite(BUZZER_PIN, HIGH);
    delay(50);
    digitalWrite(BUZZER_PIN, LOW);
    
    if (key == '#') {
      // Submit PIN
      if (enteredPIN.length() == PIN_LENGTH) {
        Serial.print("PIN entered: ");
        Serial.println(enteredPIN);
        
        if (systemLocked) {
          Serial.println("⚠️ System is locked. Access denied.");
          triggerBuzzer(3, 200);
          enteredPIN = "";
          return;
        }
        
        // Publish PIN for validation
        StaticJsonDocument<256> doc;
        doc["device"] = mqtt_client_id;
        doc["pin"] = enteredPIN;
        doc["timestamp"] = millis();
        
        char jsonBuffer[256];
        serializeJson(doc, jsonBuffer);
        mqtt_client.publish(topic_keypad, jsonBuffer);
        
        enteredPIN = "";
      } else {
        Serial.println("Invalid PIN length");
        triggerBuzzer(3, 100);
        enteredPIN = "";
      }
    }
    else if (key == '*') {
      // Clear PIN
      enteredPIN = "";
      Serial.println("PIN cleared");
    }
    else {
      // Add digit to PIN
      if (enteredPIN.length() < PIN_LENGTH) {
        enteredPIN += key;
        Serial.print("PIN: ");
        for (int i = 0; i < enteredPIN.length(); i++) {
          Serial.print("*");
        }
        Serial.println();
      }
    }
  }
}

// ================== PUBLISH SENSOR DATA ==================
void publishSensorData() {
  float suhu = dht.readTemperature();
  float kelembapan = dht.readHumidity();
  int nilaiLDR = analogRead(LDR_PIN);
  int nilaiMQ = analogRead(MQ_PIN);

  if (isnan(suhu) || isnan(kelembapan)) {
    Serial.println("⚠️ Failed to read DHT sensor!");
    return;
  }
  
  // Print to serial
  Serial.println("\n--- Sensor Readings ---");
  Serial.printf("Temperature: %.2f °C\n", suhu);
  Serial.printf("Humidity: %.2f %%\n", kelembapan);
  Serial.printf("Light (LDR): %d\n", nilaiLDR);
  Serial.printf("Gas (MQ-2): %d\n", nilaiMQ);
  Serial.println("----------------------\n");
  
  // Publish each sensor data
  StaticJsonDocument<200> doc;
  char jsonBuffer[200];
  
  // 1. Temperature
  doc.clear();
  doc["device"] = mqtt_client_id;
  doc["sensor"] = "DHT22";
  doc["temperature"] = round(suhu * 10) / 10.0;
  doc["timestamp"] = millis();
  serializeJson(doc, jsonBuffer);
  mqtt_client.publish(topic_temperature, jsonBuffer);
  
  // 2. Humidity
  doc.clear();
  doc["device"] = mqtt_client_id;
  doc["sensor"] = "DHT22";
  doc["humidity"] = round(kelembapan * 10) / 10.0;
  doc["timestamp"] = millis();
  serializeJson(doc, jsonBuffer);
  mqtt_client.publish(topic_humidity, jsonBuffer);
  
  // 3. Gas
  int gasPpm = map(nilaiMQ, 0, 4095, 0, 1000);
  String gasStatus;
  if (gasPpm > 500) gasStatus = "DANGER";
  else if (gasPpm > 300) gasStatus = "WARNING";
  else gasStatus = "NORMAL";
  
  doc.clear();
  doc["device"] = mqtt_client_id;
  doc["sensor"] = "MQ-2";
  doc["gas_ppm"] = gasPpm;
  doc["status"] = gasStatus;
  doc["timestamp"] = millis();
  serializeJson(doc, jsonBuffer);
  mqtt_client.publish(topic_gas, jsonBuffer);
  
  // 4. Light
  int lightLux = map(nilaiLDR, 0, 4095, 0, 1000);
  
  doc.clear();
  doc["device"] = mqtt_client_id;
  doc["sensor"] = "LDR";
  doc["light_lux"] = lightLux;
  doc["timestamp"] = millis();
  serializeJson(doc, jsonBuffer);
  mqtt_client.publish(topic_light, jsonBuffer);
}

// ================== MQTT RECONNECT ==================
void reconnectMQTT() {
  while (!mqtt_client.connected()) {
    Serial.print("Connecting to MQTT broker: ");
    Serial.println(mqtt_broker);
    
    if (mqtt_client.connect(mqtt_client_id)) {
      Serial.println("✓ MQTT connected!");
      
      // Subscribe to control topics
      mqtt_client.subscribe(topic_control_door);
      mqtt_client.subscribe(topic_control_lamp);
      mqtt_client.subscribe(topic_control_curtain);
      mqtt_client.subscribe(topic_control_buzzer);
      mqtt_client.subscribe(topic_lockout);
      
      // Subscribe to face recognition topics from ESP32-CAM
      mqtt_client.subscribe(topic_face_detected);
      mqtt_client.subscribe(topic_unknown_face);
      
      Serial.println("✓ Subscribed to all topics");
      
    } else {
      Serial.print("✗ MQTT connection failed, rc=");
      Serial.println(mqtt_client.state());
      Serial.println("Retrying in 5 seconds...");
      delay(5000);
    }
  }
}

// ================== MAIN LOOP ==================
void loop() {
  // Maintain MQTT connection
  if (!mqtt_client.connected()) {
    reconnectMQTT();
  }
  mqtt_client.loop();
  
  // Check system lockout
  if (systemLocked && millis() > lockoutEndTime) {
    systemLocked = false;
    Serial.println("🔓 System lockout ended");
  }
  
  // Auto-lock door after timeout
  if (doorUnlocked && (millis() - doorUnlockTime > DOOR_UNLOCK_DURATION)) {
    lockDoor();
  }
  
  // Publish sensor data periodically
  if (millis() - lastSensorPublish > SENSOR_PUBLISH_INTERVAL) {
    publishSensorData();
    lastSensorPublish = millis();
  }
  
  // Check fingerprint periodically
  if (millis() - lastFingerprintCheck > FINGERPRINT_CHECK_INTERVAL) {
    checkFingerprint();
    lastFingerprintCheck = millis();
  }
  
  // Check keypad continuously
  checkKeypad();
  
  // Small delay
  delay(10);
}
