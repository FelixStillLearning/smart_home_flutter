# 🔧 Smart Home Backend - Flask + MQTT + SQLite

Backend server untuk menyimpan data sensor ke database dan menyediakan REST API.

## 🚀 Cara Running Backend

### 1. Install Dependencies
```bash
cd backend
pip install -r requirements.txt
```

### 2. Run Server
```bash
python app.py
```

Server akan berjalan di: **http://localhost:5000**

## 📡 REST API Endpoints

### Get Latest Sensor Data
```http
GET /api/sensors/latest
```

Response:
```json
{
  "temperature": {"value": 28.5, "timestamp": 1699708800},
  "humidity": {"value": 65.0, "timestamp": 1699708800},
  "gas": {"value": 150, "status": "NORMAL", "timestamp": 1699708800},
  "light": {"value": 650, "timestamp": 1699708800}
}
```

### Get Sensor History
```http
GET /api/sensors/history/temperature?limit=20
GET /api/sensors/history/humidity?limit=20
GET /api/sensors/history/gas?limit=20
GET /api/sensors/history/light?limit=20
```

### Get Door Status
```http
GET /api/door/status
```

### Control Door
```http
POST /api/control/door
Content-Type: application/json

{
  "command": "UNLOCK"
}
```

### Control Light
```http
POST /api/control/light
Content-Type: application/json

{
  "command": "ON"
}
```

### Control Curtain
```http
POST /api/control/curtain
Content-Type: application/json

{
  "position": 75
}
```

### Get Statistics
```http
GET /api/stats
```

## 🗄️ Database Schema

### Table: sensor_data
| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key |
| device_id | TEXT | Device identifier |
| sensor_type | TEXT | temperature/humidity/gas/light |
| value | REAL | Sensor value |
| unit | TEXT | Unit (°C, %, PPM, LUX) |
| status | TEXT | Status (untuk gas: NORMAL/WARNING/DANGER) |
| timestamp | INTEGER | Unix timestamp |
| created_at | DATETIME | Record creation time |

### Table: door_status
| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key |
| device_id | TEXT | Device identifier |
| status | TEXT | locked/unlocked |
| timestamp | INTEGER | Unix timestamp |
| created_at | DATETIME | Record creation time |

### Table: control_logs
| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key |
| device_type | TEXT | door/light/curtain |
| command | TEXT | Command sent |
| value | TEXT | Command value |
| source | TEXT | api/mqtt/manual |
| timestamp | INTEGER | Unix timestamp |
| created_at | DATETIME | Record creation time |

## 🔄 Arsitektur Sistem

```
ESP32 Simulator → MQTT Broker → Flask Backend (+ SQLite Database)
                      ↓                    ↓
                  Real-time           Historical Data
                                           ↓
                                      REST API
                                           ↓
                                     Flutter App
```

## 📊 Flow Data

1. **ESP32 Simulator** publish data sensor ke MQTT broker
2. **Flask Backend** subscribe MQTT topics dan simpan ke SQLite
3. **Flutter App** bisa:
   - Subscribe langsung ke MQTT untuk real-time data
   - Atau fetch dari REST API untuk historical data
4. **Control commands** bisa dari:
   - Flutter → MQTT → ESP32
   - Flutter → REST API → Backend → MQTT → ESP32
