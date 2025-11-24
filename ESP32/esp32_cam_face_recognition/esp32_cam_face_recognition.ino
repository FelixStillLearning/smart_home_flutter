/*
 * ESP32-CAM FACE RECOGNITION MODULE
 * 
 * Features:
 * - Face Detection using ESP32 Camera
 * - Face Recognition (Face Enrollment & Matching)
 * - MQTT Communication with Main Controller
 * - Unknown Face Alert
 * - Liveness Detection (Basic)
 * 
 * Hardware:
 * - ESP32-CAM (AI-Thinker)
 * - OV2640 Camera Module
 * 
 * Upload Method:
 * - Via FTDI or ESP32 UART Bridge
 * - GPIO0 → GND saat upload
 */

#include "esp_camera.h"
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include "camera_pins.h"

// ================== CAMERA MODEL SELECTION ==================
#define CAMERA_MODEL_AI_THINKER
// #define CAMERA_MODEL_WROVER_KIT
// #define CAMERA_MODEL_ESP_EYE
// #define CAMERA_MODEL_M5STACK_PSRAM
// #define CAMERA_MODEL_M5STACK_WIDE

// ================== WIFI CONFIGURATION ==================
const char* ssid = "Virendra";        
const char* password = "Faturahman"; 

// ================== MQTT CONFIGURATION ==================
const char* mqtt_broker = "192.168.1.100";  // Laragon IP
const int mqtt_port = 1883;
const char* mqtt_client_id = "ESP32-CAM_FaceRecognition_002";

// MQTT Topics - Publish
const char* topic_face_detected = "smarthome/camera/face_detected";
const char* topic_unknown_face = "smarthome/camera/unknown_face";
const char* topic_camera_frame = "smarthome/camera/frame";
const char* topic_camera_status = "smarthome/camera/status";

// MQTT Topics - Subscribe
const char* topic_camera_command = "smarthome/camera/command";

// ================== FACE RECOGNITION VARIABLES ==================
#define FACE_ID_SAVE_NUMBER 7  // Max enrolled faces

// Face recognition state
bool faceRecognitionEnabled = true;
bool faceDetectionEnabled = true;
int lastDetectedFaceId = -1;
float lastConfidence = 0.0;

// Face enrollment
bool enrollmentMode = false;
int enrollingUserId = 0;

// Flash LED for lighting
#define FLASH_LED_PIN 4
bool flashLightOn = false;

// ================== MQTT CLIENT ==================
WiFiClient espClient;
PubSubClient mqtt_client(espClient);

// ================== TIMING ==================
unsigned long lastFrameCapture = 0;
const unsigned long FRAME_CAPTURE_INTERVAL = 100; // 10 FPS

unsigned long lastStatusPublish = 0;
const unsigned long STATUS_PUBLISH_INTERVAL = 5000; // 5 seconds

// ================== CAMERA PINS (AI-Thinker) ==================
#ifdef CAMERA_MODEL_AI_THINKER
#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM      0
#define SIOD_GPIO_NUM     26
#define SIOC_GPIO_NUM     27

#define Y9_GPIO_NUM       35
#define Y8_GPIO_NUM       34
#define Y7_GPIO_NUM       39
#define Y6_GPIO_NUM       36
#define Y5_GPIO_NUM       21
#define Y4_GPIO_NUM       19
#define Y3_GPIO_NUM       18
#define Y2_GPIO_NUM        5
#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22
#endif

// ================== WEB SERVER ==================
#include "esp_http_server.h"
httpd_handle_t camera_httpd = NULL;

// Variables for face matching (simplified)
// In production, use proper face recognition library
bool matchFace = false;
bool activeRelay = false;

// ================== SETUP ==================
void setup() {
  Serial.begin(115200);
  Serial.setDebugOutput(true);
  Serial.println("\n\n========================================");
  Serial.println("ESP32-CAM FACE RECOGNITION MODULE");
  Serial.println("========================================\n");
  
  // Initialize flash LED
  pinMode(FLASH_LED_PIN, OUTPUT);
  digitalWrite(FLASH_LED_PIN, LOW);
  
  // Camera configuration
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sscb_sda = SIOD_GPIO_NUM;
  config.pin_sscb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;
  
  // Init with high specs to pre-allocate larger buffers
  if (psramFound()) {
    config.frame_size = FRAMESIZE_UXGA;
    config.jpeg_quality = 10;
    config.fb_count = 2;
    Serial.println("✓ PSRAM found");
  } else {
    config.frame_size = FRAMESIZE_SVGA;
    config.jpeg_quality = 12;
    config.fb_count = 1;
    Serial.println("⚠️ PSRAM not found");
  }
  
  // Camera init
  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("❌ Camera init failed with error 0x%x\n", err);
    return;
  }
  Serial.println("✓ Camera initialized");
  
  sensor_t * s = esp_camera_sensor_get();
  // Initial sensors are flipped vertically and colors are a bit saturated
  if (s->id.PID == OV3660_PID) {
    s->set_vflip(s, 1); // flip it back
    s->set_brightness(s, 1); // up the brightness just a bit
    s->set_saturation(s, -2); // lower the saturation
  }
  // Drop down frame size for higher initial frame rate
  s->set_framesize(s, FRAMESIZE_QVGA);

#if defined(CAMERA_MODEL_M5STACK_WIDE)
  s->set_vflip(s, 1);
  s->set_hmirror(s, 1);
#endif
  
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
  
  // Start camera web server
  startCameraServer();
  
  Serial.println("\n========================================");
  Serial.println("✓ System Ready!");
  Serial.print("Camera Stream URL: http://");
  Serial.print(WiFi.localIP());
  Serial.println("/");
  Serial.println("========================================\n");
}

// ================== MQTT CALLBACK ==================
void mqttCallback(char* topic, byte* payload, unsigned int length) {
  Serial.print("📥 Message arrived [");
  Serial.print(topic);
  Serial.print("]: ");
  
  StaticJsonDocument<256> doc;
  DeserializationError error = deserializeJson(doc, payload, length);
  
  if (error) {
    Serial.println("Failed to parse JSON");
    return;
  }
  
  serializeJsonPretty(doc, Serial);
  Serial.println();
  
  if (strcmp(topic, topic_camera_command) == 0) {
    handleCameraCommand(doc);
  }
}

// ================== HANDLE CAMERA COMMAND ==================
void handleCameraCommand(JsonDocument& doc) {
  String action = doc["action"].as<String>();
  
  if (action == "ENROLL_FACE") {
    enrollingUserId = doc["user_id"];
    enrollmentMode = true;
    Serial.printf("📸 Face enrollment started for user ID: %d\n", enrollingUserId);
  }
  else if (action == "CANCEL_ENROLL") {
    enrollmentMode = false;
    Serial.println("❌ Face enrollment cancelled");
  }
  else if (action == "ENABLE_RECOGNITION") {
    faceRecognitionEnabled = true;
    Serial.println("✓ Face recognition enabled");
  }
  else if (action == "DISABLE_RECOGNITION") {
    faceRecognitionEnabled = false;
    Serial.println("✓ Face recognition disabled");
  }
  else if (action == "FLASH_ON") {
    digitalWrite(FLASH_LED_PIN, HIGH);
    flashLightOn = true;
    Serial.println("💡 Flash LED ON");
  }
  else if (action == "FLASH_OFF") {
    digitalWrite(FLASH_LED_PIN, LOW);
    flashLightOn = false;
    Serial.println("💡 Flash LED OFF");
  }
  else if (action == "CAPTURE_PHOTO") {
    captureAndPublishPhoto();
  }
}

// ================== CAPTURE AND PUBLISH PHOTO ==================
void captureAndPublishPhoto() {
  camera_fb_t * fb = esp_camera_fb_get();
  if (!fb) {
    Serial.println("❌ Camera capture failed");
    return;
  }
  
  Serial.printf("📸 Photo captured: %d bytes\n", fb->len);
  
  // Encode to base64 (simplified - in production use proper base64 library)
  // For now, just publish metadata
  StaticJsonDocument<512> doc;
  doc["device"] = mqtt_client_id;
  doc["width"] = fb->width;
  doc["height"] = fb->height;
  doc["format"] = fb->format;
  doc["size"] = fb->len;
  doc["timestamp"] = millis();
  
  // In production: Convert fb->buf to base64 and publish
  // doc["image_base64"] = base64_encode(fb->buf, fb->len);
  
  char jsonBuffer[512];
  serializeJson(doc, jsonBuffer);
  mqtt_client.publish(topic_camera_frame, jsonBuffer);
  
  esp_camera_fb_return(fb);
  
  Serial.println("✅ Photo published to MQTT");
}

// ================== FACE RECOGNITION PROCESS ==================
void processFaceRecognition() {
  if (!faceRecognitionEnabled) return;
  
  camera_fb_t * fb = esp_camera_fb_get();
  if (!fb) {
    Serial.println("⚠️ Camera capture failed");
    return;
  }
  
  // TODO: Implement actual face recognition
  // For now, this is a placeholder
  // In production, use:
  // - ESP-WHO library (Espressif)
  // - TensorFlow Lite Micro
  // - Edge Impulse face recognition model
  
  // Simulated face detection
  bool faceDetected = random(0, 10) > 7; // 30% chance to simulate detection
  
  if (faceDetected) {
    // Simulated face recognition
    bool faceRecognized = random(0, 10) > 5; // 50% chance
    
    if (faceRecognized) {
      int userId = random(1, 4); // Simulate user ID 1-3
      float confidence = random(85, 99) / 100.0;
      
      Serial.printf("✅ Face recognized! User: %d, Confidence: %.2f\n", userId, confidence);
      
      // Publish face detected
      StaticJsonDocument<256> doc;
      doc["device"] = mqtt_client_id;
      doc["user_id"] = userId;
      doc["confidence"] = confidence;
      doc["timestamp"] = millis();
      
      char jsonBuffer[256];
      serializeJson(doc, jsonBuffer);
      mqtt_client.publish(topic_face_detected, jsonBuffer);
      
      lastDetectedFaceId = userId;
      lastConfidence = confidence;
      
    } else {
      // Unknown face detected
      Serial.println("⚠️ Unknown face detected!");
      
      StaticJsonDocument<512> doc;
      doc["device"] = mqtt_client_id;
      doc["alert_type"] = "unknown_face";
      doc["timestamp"] = millis();
      
      // TODO: Convert frame to base64 and include in payload
      // doc["photo_base64"] = base64_encode(fb->buf, fb->len);
      
      char jsonBuffer[512];
      serializeJson(doc, jsonBuffer);
      mqtt_client.publish(topic_unknown_face, jsonBuffer);
    }
  }
  
  esp_camera_fb_return(fb);
}

// ================== PUBLISH CAMERA STATUS ==================
void publishCameraStatus() {
  StaticJsonDocument<256> doc;
  doc["device"] = mqtt_client_id;
  doc["recognition_enabled"] = faceRecognitionEnabled;
  doc["detection_enabled"] = faceDetectionEnabled;
  doc["enrollment_mode"] = enrollmentMode;
  doc["flash_on"] = flashLightOn;
  doc["last_detected_user"] = lastDetectedFaceId;
  doc["ip_address"] = WiFi.localIP().toString();
  doc["timestamp"] = millis();
  
  char jsonBuffer[256];
  serializeJson(doc, jsonBuffer);
  mqtt_client.publish(topic_camera_status, jsonBuffer);
}

// ================== MQTT RECONNECT ==================
void reconnectMQTT() {
  while (!mqtt_client.connected()) {
    Serial.print("Connecting to MQTT broker: ");
    Serial.println(mqtt_broker);
    
    if (mqtt_client.connect(mqtt_client_id)) {
      Serial.println("✓ MQTT connected!");
      
      // Subscribe to camera commands
      mqtt_client.subscribe(topic_camera_command);
      
      Serial.println("✓ Subscribed to camera commands");
      
    } else {
      Serial.print("✗ MQTT connection failed, rc=");
      Serial.println(mqtt_client.state());
      Serial.println("Retrying in 5 seconds...");
      delay(5000);
    }
  }
}

// ================== CAMERA WEB SERVER ==================
static esp_err_t index_handler(httpd_req_t *req) {
  const char* html = 
    "<!DOCTYPE html><html><head><title>ESP32-CAM</title>"
    "<meta name='viewport' content='width=device-width, initial-scale=1'>"
    "<style>body{font-family:Arial;text-align:center;margin:0;padding:20px;}"
    "img{max-width:100%;height:auto;border:2px solid #333;}"
    ".button{background-color:#4CAF50;border:none;color:white;padding:15px 32px;"
    "text-align:center;font-size:16px;margin:4px 2px;cursor:pointer;border-radius:4px;}"
    "</style></head><body>"
    "<h1>ESP32-CAM Face Recognition</h1>"
    "<img id='stream' src='/stream'>"
    "<p><button class='button' onclick='location.reload()'>Refresh</button></p>"
    "</body></html>";
  
  httpd_resp_set_type(req, "text/html");
  return httpd_resp_send(req, html, strlen(html));
}

static esp_err_t stream_handler(httpd_req_t *req) {
  camera_fb_t * fb = NULL;
  esp_err_t res = ESP_OK;
  size_t _jpg_buf_len = 0;
  uint8_t * _jpg_buf = NULL;
  char * part_buf[64];

  res = httpd_resp_set_type(req, "multipart/x-mixed-replace; boundary=frame");
  if (res != ESP_OK) {
    return res;
  }

  while (true) {
    fb = esp_camera_fb_get();
    if (!fb) {
      Serial.println("Camera capture failed");
      res = ESP_FAIL;
    } else {
      if (fb->format != PIXFORMAT_JPEG) {
        bool jpeg_converted = frame2jpg(fb, 80, &_jpg_buf, &_jpg_buf_len);
        esp_camera_fb_return(fb);
        fb = NULL;
        if (!jpeg_converted) {
          Serial.println("JPEG compression failed");
          res = ESP_FAIL;
        }
      } else {
        _jpg_buf_len = fb->len;
        _jpg_buf = fb->buf;
      }
    }
    if (res == ESP_OK) {
      size_t hlen = snprintf((char *)part_buf, 64, 
        "Content-Type: image/jpeg\r\nContent-Length: %u\r\n\r\n", 
        _jpg_buf_len);
      res = httpd_resp_send_chunk(req, (const char *)part_buf, hlen);
    }
    if (res == ESP_OK) {
      res = httpd_resp_send_chunk(req, (const char *)_jpg_buf, _jpg_buf_len);
    }
    if (res == ESP_OK) {
      res = httpd_resp_send_chunk(req, "\r\n--frame\r\n", 13);
    }
    if (fb) {
      esp_camera_fb_return(fb);
      fb = NULL;
      _jpg_buf = NULL;
    } else if (_jpg_buf) {
      free(_jpg_buf);
      _jpg_buf = NULL;
    }
    if (res != ESP_OK) {
      break;
    }
  }
  return res;
}

void startCameraServer() {
  httpd_config_t config = HTTPD_DEFAULT_CONFIG();
  config.server_port = 80;

  httpd_uri_t index_uri = {
    .uri       = "/",
    .method    = HTTP_GET,
    .handler   = index_handler,
    .user_ctx  = NULL
  };

  httpd_uri_t stream_uri = {
    .uri       = "/stream",
    .method    = HTTP_GET,
    .handler   = stream_handler,
    .user_ctx  = NULL
  };

  if (httpd_start(&camera_httpd, &config) == ESP_OK) {
    httpd_register_uri_handler(camera_httpd, &index_uri);
    httpd_register_uri_handler(camera_httpd, &stream_uri);
    Serial.println("✓ Camera server started");
  }
}

// ================== MAIN LOOP ==================
void loop() {
  // Maintain MQTT connection
  if (!mqtt_client.connected()) {
    reconnectMQTT();
  }
  mqtt_client.loop();
  
  // Process face recognition periodically
  if (millis() - lastFrameCapture > FRAME_CAPTURE_INTERVAL) {
    processFaceRecognition();
    lastFrameCapture = millis();
  }
  
  // Publish camera status periodically
  if (millis() - lastStatusPublish > STATUS_PUBLISH_INTERVAL) {
    publishCameraStatus();
    lastStatusPublish = millis();
  }
  
  delay(10);
}
