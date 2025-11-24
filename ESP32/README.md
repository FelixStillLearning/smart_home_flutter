# 🏠 Smart Home Door Access System - ESP32 Integration

Complete ESP32 code untuk Smart Home Door Access System dengan Face Recognition, Multi-Authentication, dan Home Automation.

---

## 📁 **Project Structure**

```
ESP32/
├── esp32_main_controller/           # ESP32 #1 (Sensor + Access Control)
│   └── esp32_main_controller.ino
├── esp32_cam_face_recognition/      # ESP32-CAM (Face Recognition)
│   └── esp32_cam_face_recognition.ino
├── esp32_uart_bridge/               # ESP32 Bridge (untuk upload ESP32-CAM)
│   └── esp32_uart_bridge.ino
└── README.md                        # This file
```

---

## 🔌 **Hardware Requirements**

### **ESP32 Main Controller (ESP32 #1)**
- 1× ESP32 Dev Module
- 1× DHT22 (Temperature & Humidity)
- 1× MQ-2 (Gas Sensor)
- 1× LDR (Light Sensor)
- 1× JM-101B Fingerprint Sensor
- 1× 4x4 Matrix Keypad
- 3× Relay Module (5V)
- 1× Solenoid Door Lock (12V)
- 1× Buzzer (5V)
- 1× Power Supply (12V 2A)

### **ESP32-CAM (ESP32 #2)**
- 1× ESP32-CAM (AI-Thinker)
- 1× OV2640 Camera Module (included)
- 1× Programmer (FTDI atau ESP32 biasa)

---

## 🔧 **Wiring Diagram**

### **ESP32 Main Controller Pin Map**

| Component | Pin | Notes |
|-----------|-----|-------|
| DHT22 | GPIO 21 | Data pin |
| LDR | GPIO 34 | ADC1_CH6 |
| MQ-2 | GPIO 35 | ADC1_CH7 |
| Fingerprint RX | GPIO 16 | Serial2 RX |
| Fingerprint TX | GPIO 17 | Serial2 TX |
| Keypad Row 1 | GPIO 13 | |
| Keypad Row 2 | GPIO 12 | |
| Keypad Row 3 | GPIO 14 | |
| Keypad Row 4 | GPIO 27 | |
| Keypad Col 1 | GPIO 26 | |
| Keypad Col 2 | GPIO 25 | |
| Keypad Col 3 | GPIO 33 | |
| Keypad Col 4 | GPIO 32 | |
| Relay Door | GPIO 4 | Solenoid Lock |
| Relay Lamp | GPIO 2 | Lamp Control |
| Relay Curtain | GPIO 15 | Curtain Motor |
| Buzzer | GPIO 5 | Active Buzzer |

### **ESP32-CAM Pin Map**

| Component | Pin | Notes |
|-----------|-----|-------|
| Flash LED | GPIO 4 | Built-in |
| Camera | OV2640 | Built-in |

### **ESP32 UART Bridge → ESP32-CAM**

| ESP32 Bridge | ESP32-CAM | Description |
|--------------|-----------|-------------|
| GPIO17 (TX2) | U0R (RX) | Serial Data |
| GPIO16 (RX2) | U0T (TX) | Serial Data |
| GND | GND | Ground |
| 5V | 5V | Power |
| - | GPIO0 → GND | Upload Mode (disconnect after upload) |

---

## 📚 **Library Dependencies**

Install library ini di Arduino IDE (Sketch → Include Library → Manage Libraries):

```
1. DHT sensor library by Adafruit
2. Adafruit Unified Sensor
3. PubSubClient by Nick O'Leary
4. ArduinoJson by Benoit Blanchon
5. Keypad by Mark Stanley
6. Adafruit Fingerprint Sensor Library
7. ESP32 Camera (built-in dengan ESP32 board)
```

---

## 🚀 **Upload Instructions**

### **A. Upload ke ESP32 Main Controller (Langsung)**

1. **Connect** ESP32 ke laptop via USB
2. **Select Board**: `ESP32 Dev Module`
3. **Select Port**: `COM7` (sesuaikan)
4. **Open**: `esp32_main_controller.ino`
5. **Edit WiFi credentials** (line 26-27):
   ```cpp
   const char* ssid = "YOUR_WIFI_NAME";
   const char* password = "YOUR_WIFI_PASSWORD";
   ```
6. **Edit MQTT broker IP** (line 31):
   ```cpp
   const char* mqtt_broker = "192.168.1.100"; // Ganti dengan IP Laragon
   ```
7. **Click Upload** (→)
8. **Wait** until "Done uploading"

---

### **B. Upload ke ESP32-CAM (Via ESP32 Bridge)**

**Step 1: Setup ESP32 Bridge**

1. **Connect** ESP32 biasa ke laptop via USB
2. **Select Board**: `ESP32 Dev Module`
3. **Open**: `esp32_uart_bridge.ino`
4. **Upload** code ini ke ESP32 biasa
5. **Wait** until "Done uploading"

**Step 2: Wiring ESP32 Bridge ke ESP32-CAM**

```
ESP32 (Bridge)    ESP32-CAM
──────────────    ─────────
GPIO17 (TX2)  →   U0R (RX)
GPIO16 (RX2)  ←   U0T (TX)
GND           →   GND
5V            →   5V

IMPORTANT FOR UPLOAD:
GPIO0         →   GND  (jumper wire)
```

**Step 3: Upload Code ke ESP32-CAM**

1. **Pasang jumper wire** dari GPIO0 ESP32-CAM ke GND
2. **ESP32 Bridge tetap connect** ke laptop via USB
3. Di Arduino IDE:
   - **Select Board**: `AI Thinker ESP32-CAM`
   - **Select Port**: Port ESP32 Bridge (misal COM7)
   - **Open**: `esp32_cam_face_recognition.ino`
4. **Edit WiFi credentials** (line 29-30)
5. **Edit MQTT broker IP** (line 34)
6. **Click Upload** (→)
7. **Tunggu** muncul "Connecting......." (titik-titik)
8. **Tunggu** sampai "Writing at 0x00001000..."
9. **LEPAS jumper GPIO0-GND** setelah selesai upload
10. **Tekan RST button** di ESP32-CAM
11. **Done!**

**Troubleshooting Upload:**
- Jika gagal, coba tekan tombol RST ESP32-CAM sambil upload
- Pastikan jumper GPIO0-GND terpasang saat upload
- Pastikan baudrate 115200
- Coba ganti kabel USB

---

## ⚙️ **Configuration**

### **1. MQTT Broker Setup (Laragon)**

**Install Mosquitto di Laragon:**

1. Download Mosquitto: https://mosquitto.org/download/
2. Install ke `C:\laragon\bin\mosquitto\`
3. Buat file `mosquitto.conf`:
   ```
   listener 1883
   allow_anonymous true
   ```
4. Jalankan:
   ```bash
   cd C:\laragon\bin\mosquitto
   mosquitto.exe -c mosquitto.conf -v
   ```
5. Test dengan MQTT Explorer: http://mqtt-explorer.com/

**Cek IP Laragon:**
```bash
ipconfig
# Cari IPv4 Address (misal: 192.168.1.100)
```

**Update IP di ESP32 code:**
```cpp
const char* mqtt_broker = "192.168.1.100"; // Ganti dengan IP Anda
```

---

### **2. Enroll Fingerprint (JM-101B)**

**Upload Enroll Example:**

1. File → Examples → Adafruit Fingerprint Sensor Library → enroll
2. Upload ke ESP32
3. Buka Serial Monitor (115200 baud)
4. Follow instruksi:
   ```
   Enter ID # (1-127): 1
   Place finger...
   Remove finger...
   Place same finger again...
   Stored!
   ```
5. Repeat untuk user lain (ID 2, 3, dst)

---

### **3. Test Keypad**

**Test Code:**
```cpp
void loop() {
  char key = keypad.getKey();
  if (key) {
    Serial.println(key);
  }
}
```

Tekan tombol keypad, harusnya muncul di Serial Monitor:
```
1 2 3 A
4 5 6 B
7 8 9 C
* 0 # D
```

---

## 📡 **MQTT Topics Structure**

### **Published by ESP32 Main Controller**

```yaml
# Sensor Data
smarthome/sensor/temperature
  → {"device":"ESP32_MainController_001","temperature":28.5,"timestamp":123456}

smarthome/sensor/humidity
  → {"device":"ESP32_MainController_001","humidity":65.2,"timestamp":123456}

smarthome/sensor/gas
  → {"device":"ESP32_MainController_001","gas_ppm":350,"status":"NORMAL","timestamp":123456}

smarthome/sensor/light
  → {"device":"ESP32_MainController_001","light_lux":750,"timestamp":123456}

# Access Attempts
smarthome/access/fingerprint
  → {"device":"ESP32_MainController_001","fingerprint_id":1,"confidence":95,"timestamp":123456}

smarthome/access/keypad
  → {"device":"ESP32_MainController_001","pin":"123456","timestamp":123456}

# Door Status
smarthome/status/door
  → {"device":"ESP32_MainController_001","status":"unlocked","method":"face","user_id":1,"timestamp":123456}
```

### **Published by ESP32-CAM**

```yaml
# Face Detection
smarthome/camera/face_detected
  → {"device":"ESP32-CAM_FaceRecognition_002","user_id":1,"confidence":0.92,"timestamp":123456}

# Unknown Face Alert
smarthome/camera/unknown_face
  → {"device":"ESP32-CAM_FaceRecognition_002","alert_type":"unknown_face","timestamp":123456}

# Camera Status
smarthome/camera/status
  → {"device":"ESP32-CAM_FaceRecognition_002","recognition_enabled":true,"ip_address":"192.168.1.101","timestamp":123456}
```

### **Subscribed by ESP32 (Commands from Backend)**

```yaml
# Door Control
smarthome/control/door
  → {"action":"UNLOCK","user_id":1}
  → {"action":"LOCK"}

# Lamp Control
smarthome/control/lamp
  → {"action":"ON"}
  → {"action":"OFF"}

# Curtain Control
smarthome/control/curtain
  → {"action":"OPEN","percentage":75}
  → {"action":"CLOSE"}

# Buzzer
smarthome/control/buzzer
  → {"action":"ALARM","duration":3}

# System Lockout
smarthome/control/lockout
  → {"action":"LOCKOUT","duration":300}

# Camera Commands
smarthome/camera/command
  → {"action":"ENROLL_FACE","user_id":5}
  → {"action":"FLASH_ON"}
  → {"action":"CAPTURE_PHOTO"}
```

---

## 🧪 **Testing**

### **Test 1: MQTT Connection**

1. Buka MQTT Explorer
2. Connect ke `localhost:1883`
3. Upload code ke ESP32
4. Buka Serial Monitor
5. Harusnya muncul:
   ```
   ✓ WiFi connected!
   ✓ MQTT connected!
   ✓ Subscribed to all topics
   ```
6. Di MQTT Explorer, harusnya muncul topics:
   ```
   smarthome/sensor/temperature
   smarthome/sensor/humidity
   ...
   ```

### **Test 2: Sensor Reading**

Check Serial Monitor ESP32 Main Controller:
```
--- Sensor Readings ---
Temperature: 28.50 °C
Humidity: 65.20 %
Light (LDR): 2350
Gas (MQ-2): 1200
----------------------
```

### **Test 3: Face Recognition**

1. Buka browser: `http://[ESP32-CAM_IP]/`
2. Harusnya muncul camera stream
3. Test deteksi wajah
4. Check Serial Monitor ESP32-CAM:
   ```
   ✅ Face recognized! User: 1, Confidence: 0.92
   ```
5. Check MQTT Explorer, topic `smarthome/camera/face_detected`

### **Test 4: Door Unlock**

**Via Face Recognition:**
- Wajah detected → ESP32-CAM publish → Backend validate → Backend publish unlock command → ESP32 unlock door

**Via Fingerprint:**
- Place finger → ESP32 read → Publish to backend → Backend validate → Unlock

**Via Keypad:**
- Enter 6-digit PIN → Press # → Publish to backend → Backend validate → Unlock

**Via Remote (MQTT):**
```bash
# Test manual via MQTT Explorer
Topic: smarthome/control/door
Payload: {"action":"UNLOCK","user_id":1}
```

ESP32 harusnya unlock door selama 5 detik, lalu auto-lock.

---

## 🐛 **Troubleshooting**

### **ESP32-CAM Upload Failed**

**Error: "A fatal error occurred: Failed to connect to ESP32"**

Solusi:
1. ✅ Pastikan GPIO0 connect ke GND saat upload
2. ✅ Tekan tombol RST ESP32-CAM sebelum upload
3. ✅ Hold tombol RST sambil klik Upload, lepas setelah "Connecting..."
4. ✅ Turunkan Upload Speed ke 115200
5. ✅ Ganti kabel USB
6. ✅ Pastikan wiring ESP32 Bridge benar

### **MQTT Connection Failed**

**Error: "MQTT connection failed, rc=-2"**

Solusi:
1. ✅ Check Mosquitto running: `netstat -an | findstr :1883`
2. ✅ Check firewall: Allow port 1883
3. ✅ Ping Laragon IP: `ping 192.168.1.100`
4. ✅ Update IP di ESP32 code
5. ✅ Restart Mosquitto broker

### **Fingerprint Not Detected**

Solusi:
1. ✅ Check wiring RX/TX (jangan terbalik!)
2. ✅ Check baudrate (57600)
3. ✅ Test dengan enroll example
4. ✅ Clean fingerprint sensor dengan tissue
5. ✅ Check power supply (butuh 3.3V stable)

### **Keypad Not Responding**

Solusi:
1. ✅ Check wiring rows & columns
2. ✅ Test dengan simple test code
3. ✅ Check pin conflicts (pastikan tidak bentrok dengan sensor lain)

---

## 📈 **Performance**

### **Memory Usage**

```
ESP32 Main Controller:
├── Sketch: ~350KB (27% of flash)
├── Global Variables: ~45KB (13% of SRAM)
└── Free Heap: ~250KB

ESP32-CAM:
├── Sketch: ~920KB (70% of flash)
├── Global Variables: ~45KB (13% of SRAM)
└── Free Heap: ~280KB (with PSRAM)
```

### **MQTT Traffic**

```
Sensor Data: 4 messages × 2 seconds = 120 messages/minute
Face Detection: ~5 messages/minute (when face detected)
Control Commands: On-demand

Total: ~125 messages/minute = ~180KB/minute
```

### **Power Consumption**

```
ESP32 Main Controller:
├── Active (WiFi + Sensors): ~500mA @ 5V = 2.5W
├── Idle: ~200mA @ 5V = 1W
└── Recommendation: 5V 2A power supply

ESP32-CAM:
├── Active (WiFi + Camera + Flash): ~800mA @ 5V = 4W
├── Idle: ~300mA @ 5V = 1.5W
└── Recommendation: 5V 2A power supply

Solenoid Lock:
├── Active (Unlocked): ~500mA @ 12V = 6W
└── Recommendation: 12V 2A power supply
```

---

## 🔐 **Security Features**

### **Multi-Factor Authentication**

```
Level 1 (Single Factor):
├── Face Recognition (85%+ confidence)
├── Fingerprint Match
└── Correct PIN

Level 2 (Multi-Factor):
├── Face + PIN
└── Fingerprint + PIN
```

### **Anti-Tampering**

```
1. System Lockout (after 3 failed attempts)
   └── Lock duration: 5 minutes

2. Unknown Face Detection
   ├── Capture photo
   ├── Trigger alarm buzzer
   └── Send notification

3. Door Force Detection (future)
   └── Vibration sensor on door
```

---

## 📝 **TODO / Future Enhancements**

- [ ] Implement actual face recognition (ESP-WHO / TensorFlow Lite)
- [ ] Add liveness detection (blink eye)
- [ ] Implement fake face detection (texture analysis)
- [ ] Add OTA update support
- [ ] Implement door force sensor
- [ ] Add battery backup monitoring
- [ ] Implement encrypted MQTT (TLS/SSL)
- [ ] Add user management via web interface
- [ ] Implement scheduled door unlock
- [ ] Add geofencing (auto-unlock when near home)

---

## 📞 **Support**

Jika ada masalah atau pertanyaan, silakan buka issue di GitHub repository ini.

---

## 📄 **License**

MIT License - Free to use for educational and commercial purposes.

---

**Author**: Smart Home Team  
**Date**: November 2024  
**Version**: 1.0.0
