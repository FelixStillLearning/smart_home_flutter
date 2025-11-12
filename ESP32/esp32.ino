
/*
 * ESP32 Smart Home IoT dengan MQTT
 * Modifikasi dari kode existing untuk tambah fungsi MQTT
 * 
 * Hardware:
 * - DHT22 → GPIO 21 (Temperature & Humidity)
 * - LDR   → GPIO 34 (Light Sensor)
 * - MQ2   → GPIO 35 (Gas Sensor)
 */

#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>
#include <ArduinoJson.h>

// ================== WIFI CONFIGURATION ==================
const char* ssid = "YOUR_WIFI_SSID";        // Ganti dengan SSID WiFi Anda
const char* password = "YOUR_WIFI_PASSWORD"; // Ganti dengan password WiFi Anda

// ================== MQTT CONFIGURATION ==================
const char* mqtt_broker = "broker.hivemq.com";
const int mqtt_port = 1883;
const char* mqtt_client_id = "ESP32_SmartHome_001";

// MQTT Topics - Publish
const char* topic_temperature = "smarthome/sensor/temperature";
const char* topic_humidity = "smarthome/sensor/humidity";
const char* topic_gas = "smarthome/sensor/gas";
const char* topic_light = "smarthome/sensor/light";

// ================== SENSOR SETUP ==================
#define DHTPIN 21
#define DHTTYPE DHT22
#define LDR_PIN 34
#define MQ_PIN 35

DHT dht(DHTPIN, DHTTYPE);

// ================== MQTT CLIENT ==================
WiFiClient espClient;
PubSubClient mqtt_client(espClient);



// ================== MQTT RECONNECT ==================
void reconnectMQTT() {
  while (!mqtt_client.connected()) {
    Serial.print("Connecting to MQTT broker: ");
    Serial.println(mqtt_broker);
    
    if (mqtt_client.connect(mqtt_client_id)) {
      Serial.println("✓ MQTT connected!");
    } else {
      Serial.print("✗ MQTT connection failed, rc=");
      Serial.println(mqtt_client.state());
      Serial.println("Retrying in 5 seconds...");
      delay(5000);
    }
  }
}

// ================== SETUP ==================
void setup() {
  Serial.begin(115200);
  Serial.println("\n\n========== ESP32 Smart Home IoT with MQTT ==========");
  
  // Initialize DHT sensor
  dht.begin();
  Serial.println("✓ DHT sensor ready");

  // Connect ke WiFi
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
  
  Serial.println("========== Setup Complete ==========\n");
}



// ================== PUBLISH SENSOR DATA KE MQTT ==================
void publishSensorData(float suhu, float kelembapan, int nilaiLDR, int nilaiMQ) {
  StaticJsonDocument<200> doc;
  char jsonBuffer[200];
  
  // 1. Publish Temperature
  doc.clear();
  doc["device"] = "ESP32_001";
  doc["sensor"] = "DHT22";
  doc["temperature"] = round(suhu * 10) / 10.0;  // Round to 1 decimal
  doc["timestamp"] = millis();
  
  serializeJson(doc, jsonBuffer);
  mqtt_client.publish(topic_temperature, jsonBuffer);
  Serial.print("📤 Published temperature: ");
  Serial.println(jsonBuffer);
  
  // 2. Publish Humidity
  doc.clear();
  doc["device"] = "ESP32_001";
  doc["sensor"] = "DHT22";
  doc["humidity"] = round(kelembapan * 10) / 10.0;
  doc["timestamp"] = millis();
  
  serializeJson(doc, jsonBuffer);
  mqtt_client.publish(topic_humidity, jsonBuffer);
  Serial.print("📤 Published humidity: ");
  Serial.println(jsonBuffer);
  
  // 3. Publish Gas
  // Convert analog ke PPM (simplified)
  int gasPpm = map(nilaiMQ, 0, 4095, 0, 1000);
  String gasStatus;
  if (gasPpm > 500) {
    gasStatus = "DANGER";
  } else if (gasPpm > 300) {
    gasStatus = "WARNING";
  } else {
    gasStatus = "NORMAL";
  }
  
  doc.clear();
  doc["device"] = "ESP32_001";
  doc["sensor"] = "MQ-2";
  doc["gas_ppm"] = gasPpm;
  doc["status"] = gasStatus;
  doc["timestamp"] = millis();
  
  serializeJson(doc, jsonBuffer);
  mqtt_client.publish(topic_gas, jsonBuffer);
  Serial.print("📤 Published gas: ");
  Serial.println(jsonBuffer);
  
  // 4. Publish Light
  // Convert analog ke LUX (simplified)
  int lightLux = map(nilaiLDR, 0, 4095, 0, 1000);
  
  doc.clear();
  doc["device"] = "ESP32_001";
  doc["sensor"] = "LDR";
  doc["light_lux"] = lightLux;
  doc["timestamp"] = millis();
  
  serializeJson(doc, jsonBuffer);
  mqtt_client.publish(topic_light, jsonBuffer);
  Serial.print("📤 Published light: ");
  Serial.println(jsonBuffer);
}

// ================== MAIN LOOP ==================
void loop() {
  // Maintain MQTT connection
  if (!mqtt_client.connected()) {
    reconnectMQTT();
  }
  mqtt_client.loop();
  
  // ================== BACA SENSOR ==================
  float suhu = dht.readTemperature();
  float kelembapan = dht.readHumidity();
  int nilaiLDR = analogRead(LDR_PIN);
  int nilaiMQ = analogRead(MQ_PIN);

  if (isnan(suhu) || isnan(kelembapan)) {
    Serial.println("⚠️ Gagal membaca DHT sensor!");
    delay(2000);
    return;
  }
  
  // Print sensor readings ke Serial Monitor
  Serial.println("\n--- Sensor Readings ---");
  Serial.printf("Suhu: %.2f °C\n", suhu);
  Serial.printf("Kelembapan: %.2f %%\n", kelembapan);
  Serial.printf("LDR (Raw): %d\n", nilaiLDR);
  Serial.printf("MQ2 (Raw): %d\n", nilaiMQ);
  Serial.println("----------------------\n");
  
  // ================== PUBLISH KE MQTT ==================
  publishSensorData(suhu, kelembapan, nilaiLDR, nilaiMQ);
  
  Serial.println("✅ Data published to MQTT successfully!\n");
  
  // Tunggu 2 detik sebelum loop berikutnya
  delay(2000);
}
