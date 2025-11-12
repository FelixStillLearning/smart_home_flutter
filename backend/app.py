# Smart Home IoT Backend - Flask + MQTT + SQLite
# Backend untuk menyimpan data sensor ke database dan menyediakan REST API

from flask import Flask, jsonify, request
from flask_cors import CORS
import paho.mqtt.client as mqtt
import json
import sqlite3
from datetime import datetime
import threading
import time

app = Flask(__name__)
CORS(app)  # Enable CORS untuk Flutter

# ================== KONFIGURASI ==================
MQTT_BROKER = "broker.hivemq.com"
MQTT_PORT = 1883
MQTT_CLIENT_ID = "Flask_Backend_SmartHome"

# Database
DB_NAME = "smart_home.db"

# MQTT Topics
TOPIC_TEMPERATURE = "smarthome/sensor/temperature"
TOPIC_HUMIDITY = "smarthome/sensor/humidity"
TOPIC_GAS = "smarthome/sensor/gas"
TOPIC_LIGHT = "smarthome/sensor/light"
TOPIC_DOOR_STATUS = "smarthome/door/status"

# ================== DATABASE SETUP ==================
def init_db():
    """Inisialisasi database SQLite"""
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    
    # Table untuk sensor data
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS sensor_data (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            device_id TEXT NOT NULL,
            sensor_type TEXT NOT NULL,
            value REAL NOT NULL,
            unit TEXT,
            status TEXT,
            timestamp INTEGER NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Table untuk door status
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS door_status (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            device_id TEXT NOT NULL,
            status TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Table untuk control logs
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS control_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            device_type TEXT NOT NULL,
            command TEXT NOT NULL,
            value TEXT,
            source TEXT DEFAULT 'api',
            timestamp INTEGER NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    conn.commit()
    conn.close()
    print("[DB] ✅ Database initialized")

def insert_sensor_data(device_id, sensor_type, value, unit, status=None, timestamp=None):
    """Insert data sensor ke database"""
    if timestamp is None:
        timestamp = int(time.time())
    
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO sensor_data (device_id, sensor_type, value, unit, status, timestamp)
        VALUES (?, ?, ?, ?, ?, ?)
    ''', (device_id, sensor_type, value, unit, status, timestamp))
    conn.commit()
    conn.close()

def insert_door_status(device_id, status, timestamp=None):
    """Insert door status ke database"""
    if timestamp is None:
        timestamp = int(time.time())
    
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO door_status (device_id, status, timestamp)
        VALUES (?, ?, ?)
    ''', (device_id, status, timestamp))
    conn.commit()
    conn.close()

def insert_control_log(device_type, command, value=None, source='api'):
    """Insert control log ke database"""
    timestamp = int(time.time())
    
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO control_logs (device_type, command, value, source, timestamp)
        VALUES (?, ?, ?, ?, ?)
    ''', (device_type, command, value, source, timestamp))
    conn.commit()
    conn.close()

# ================== MQTT HANDLER ==================
mqtt_client = None

# Buffer untuk menyimpan data sensor terbaru (untuk disimpan setiap 5 detik)
latest_sensor_data = {
    'temperature': None,
    'humidity': None,
    'gas': None,
    'light': None,
    'door': None
}

def on_connect(client, userdata, flags, rc, properties=None):
    """Callback saat connected ke MQTT (paho-mqtt 2.0+ compatible)"""
    if rc == 0:
        print(f"[MQTT] ✅ Connected to {MQTT_BROKER}")
        # Subscribe ke semua topics
        client.subscribe(TOPIC_TEMPERATURE)
        client.subscribe(TOPIC_HUMIDITY)
        client.subscribe(TOPIC_GAS)
        client.subscribe(TOPIC_LIGHT)
        client.subscribe(TOPIC_DOOR_STATUS)
        print("[MQTT] 📡 Subscribed to all sensor topics")
    else:
        print(f"[MQTT] ❌ Connection failed with code {rc}")

def on_message(client, userdata, msg):
    """Callback saat menerima data dari MQTT - simpan ke buffer"""
    try:
        topic = msg.topic
        payload = json.loads(msg.payload.decode('utf-8'))
        
        print(f"[MQTT] 📨 {topic}: {payload}")
        
        # Update buffer dengan data terbaru
        device_id = payload.get('device', 'UNKNOWN')
        timestamp = payload.get('timestamp', int(time.time()))
        
        if topic == TOPIC_TEMPERATURE:
            latest_sensor_data['temperature'] = {
                'device_id': device_id,
                'value': payload.get('temperature'),
                'timestamp': timestamp
            }
            
        elif topic == TOPIC_HUMIDITY:
            latest_sensor_data['humidity'] = {
                'device_id': device_id,
                'value': payload.get('humidity'),
                'timestamp': timestamp
            }
            
        elif topic == TOPIC_GAS:
            latest_sensor_data['gas'] = {
                'device_id': device_id,
                'value': payload.get('gas_ppm'),
                'status': payload.get('status', 'NORMAL'),
                'timestamp': timestamp
            }
            
        elif topic == TOPIC_LIGHT:
            latest_sensor_data['light'] = {
                'device_id': device_id,
                'value': payload.get('light_lux'),
                'timestamp': timestamp
            }
            
        elif topic == TOPIC_DOOR_STATUS:
            latest_sensor_data['door'] = {
                'device_id': device_id,
                'status': payload.get('status'),
                'timestamp': timestamp
            }
            
    except Exception as e:
        print(f"[MQTT] ❌ Error processing message: {e}")

def save_to_database_periodically():
    """Background thread untuk menyimpan data ke database setiap 5 detik"""
    print("[DB] 🔄 Starting periodic database save (every 5 seconds)...")
    
    while True:
        try:
            time.sleep(5)  # Tunggu 5 detik
            
            # Simpan semua data yang ada di buffer
            saved_count = 0
            
            if latest_sensor_data['temperature']:
                data = latest_sensor_data['temperature']
                insert_sensor_data(data['device_id'], 'temperature', data['value'], '°C', timestamp=data['timestamp'])
                saved_count += 1
                
            if latest_sensor_data['humidity']:
                data = latest_sensor_data['humidity']
                insert_sensor_data(data['device_id'], 'humidity', data['value'], '%', timestamp=data['timestamp'])
                saved_count += 1
                
            if latest_sensor_data['gas']:
                data = latest_sensor_data['gas']
                insert_sensor_data(data['device_id'], 'gas', data['value'], 'PPM', data['status'], data['timestamp'])
                saved_count += 1
                
            if latest_sensor_data['light']:
                data = latest_sensor_data['light']
                insert_sensor_data(data['device_id'], 'light', data['value'], 'LUX', timestamp=data['timestamp'])
                saved_count += 1
                
            if latest_sensor_data['door']:
                data = latest_sensor_data['door']
                insert_door_status(data['device_id'], data['status'], data['timestamp'])
                saved_count += 1
            
            if saved_count > 0:
                print(f"[DB] 💾 Saved {saved_count} records to database")
            
        except Exception as e:
            print(f"[DB] ❌ Error saving to database: {e}")

def start_mqtt_client():
    """Start MQTT client dalam background thread"""
    global mqtt_client
    
    # Untuk paho-mqtt 2.0+, perlu callback_api_version
    mqtt_client = mqtt.Client(
        callback_api_version=mqtt.CallbackAPIVersion.VERSION2,
        client_id=MQTT_CLIENT_ID
    )
    mqtt_client.on_connect = on_connect
    mqtt_client.on_message = on_message
    
    try:
        print(f"[MQTT] Connecting to {MQTT_BROKER}:{MQTT_PORT}...")
        mqtt_client.connect(MQTT_BROKER, MQTT_PORT, 60)
        mqtt_client.loop_start()
        print("[MQTT] 🟢 MQTT client started")
    except Exception as e:
        print(f"[MQTT] ❌ Connection failed: {e}")

# ================== REST API ENDPOINTS ==================

@app.route('/')
def index():
    """Homepage API"""
    return jsonify({
        "status": "online",
        "service": "Smart Home IoT Backend",
        "version": "1.0.0",
        "endpoints": {
            "sensor_latest": "/api/sensors/latest",
            "sensor_history": "/api/sensors/history/<type>",
            "door_status": "/api/door/status",
            "control_door": "/api/control/door",
            "control_light": "/api/control/light",
            "control_curtain": "/api/control/curtain"
        }
    })

@app.route('/api/sensors/latest', methods=['GET'])
def get_latest_sensors():
    """Get data sensor terbaru (latest)"""
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    
    # Get latest temperature
    cursor.execute('''
        SELECT value, timestamp FROM sensor_data 
        WHERE sensor_type = 'temperature' 
        ORDER BY id DESC LIMIT 1
    ''')
    temp = cursor.fetchone()
    
    # Get latest humidity
    cursor.execute('''
        SELECT value, timestamp FROM sensor_data 
        WHERE sensor_type = 'humidity' 
        ORDER BY id DESC LIMIT 1
    ''')
    hum = cursor.fetchone()
    
    # Get latest gas
    cursor.execute('''
        SELECT value, status, timestamp FROM sensor_data 
        WHERE sensor_type = 'gas' 
        ORDER BY id DESC LIMIT 1
    ''')
    gas = cursor.fetchone()
    
    # Get latest light
    cursor.execute('''
        SELECT value, timestamp FROM sensor_data 
        WHERE sensor_type = 'light' 
        ORDER BY id DESC LIMIT 1
    ''')
    light = cursor.fetchone()
    
    conn.close()
    
    return jsonify({
        "temperature": {"value": temp[0], "timestamp": temp[1]} if temp else None,
        "humidity": {"value": hum[0], "timestamp": hum[1]} if hum else None,
        "gas": {"value": gas[0], "status": gas[1], "timestamp": gas[2]} if gas else None,
        "light": {"value": light[0], "timestamp": light[1]} if light else None
    })

@app.route('/api/sensors/history/<sensor_type>', methods=['GET'])
def get_sensor_history(sensor_type):
    """Get historical data sensor (max 100 data terakhir)"""
    limit = request.args.get('limit', 100, type=int)
    
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    
    cursor.execute('''
        SELECT value, status, timestamp, created_at FROM sensor_data 
        WHERE sensor_type = ? 
        ORDER BY id DESC LIMIT ?
    ''', (sensor_type, limit))
    
    rows = cursor.fetchall()
    conn.close()
    
    data = []
    for row in rows:
        data.append({
            "value": row[0],
            "status": row[1],
            "timestamp": row[2],
            "created_at": row[3]
        })
    
    return jsonify({
        "sensor_type": sensor_type,
        "count": len(data),
        "data": list(reversed(data))  # Reverse agar oldest -> newest
    })

@app.route('/api/door/status', methods=['GET'])
def get_door_status():
    """Get status pintu terbaru"""
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    
    cursor.execute('''
        SELECT status, timestamp FROM door_status 
        ORDER BY id DESC LIMIT 1
    ''')
    row = cursor.fetchone()
    conn.close()
    
    if row:
        return jsonify({
            "status": row[0],
            "timestamp": row[1]
        })
    else:
        return jsonify({"status": "unknown", "timestamp": 0})

@app.route('/api/control/door', methods=['POST'])
def control_door():
    """Kontrol pintu (LOCK/UNLOCK)"""
    data = request.json
    command = data.get('command', '').upper()
    
    if command not in ['LOCK', 'UNLOCK']:
        return jsonify({"error": "Invalid command. Use LOCK or UNLOCK"}), 400
    
    # Publish langsung command (bukan JSON) ke MQTT
    if mqtt_client and mqtt_client.is_connected():
        mqtt_client.publish("smarthome/control/door", command)
        insert_control_log('door', command, source='api')
        
        return jsonify({
            "success": True,
            "command": command,
            "message": f"Door {command.lower()} command sent"
        })
    else:
        return jsonify({"error": "MQTT not connected"}), 503

@app.route('/api/control/light', methods=['POST'])
def control_light():
    """Kontrol lampu (ON/OFF)"""
    data = request.json
    command = data.get('command', '').upper()
    
    if command not in ['ON', 'OFF']:
        return jsonify({"error": "Invalid command. Use ON or OFF"}), 400
    
    # Publish langsung command (bukan JSON) ke MQTT
    if mqtt_client and mqtt_client.is_connected():
        mqtt_client.publish("smarthome/control/light", command)
        insert_control_log('light', command, source='api')
        
        return jsonify({
            "success": True,
            "command": command,
            "message": f"Light turned {command.lower()}"
        })
    else:
        return jsonify({"error": "MQTT not connected"}), 503

@app.route('/api/control/curtain', methods=['POST'])
def control_curtain():
    """Kontrol gorden (position 0-100)"""
    data = request.json
    position = data.get('position', 0)
    
    if not (0 <= position <= 100):
        return jsonify({"error": "Position must be between 0-100"}), 400
    
    # Publish langsung angka (bukan JSON) ke MQTT
    if mqtt_client and mqtt_client.is_connected():
        mqtt_client.publish("smarthome/control/curtain", str(position))
        insert_control_log('curtain', 'SET_POSITION', str(position), source='api')
        
        return jsonify({
            "success": True,
            "position": position,
            "message": f"Curtain position set to {position}%"
        })
    else:
        return jsonify({"error": "MQTT not connected"}), 503

@app.route('/api/stats', methods=['GET'])
def get_stats():
    """Get statistik database"""
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    
    cursor.execute('SELECT COUNT(*) FROM sensor_data')
    total_sensors = cursor.fetchone()[0]
    
    cursor.execute('SELECT COUNT(*) FROM door_status')
    total_door = cursor.fetchone()[0]
    
    cursor.execute('SELECT COUNT(*) FROM control_logs')
    total_controls = cursor.fetchone()[0]
    
    conn.close()
    
    return jsonify({
        "total_sensor_records": total_sensors,
        "total_door_records": total_door,
        "total_control_logs": total_controls,
        "mqtt_connected": mqtt_client.is_connected() if mqtt_client else False
    })

# ================== MAIN ==================
if __name__ == '__main__':
    print("=" * 60)
    print("🏠 Smart Home IoT Backend - Flask + MQTT + SQLite")
    print("=" * 60)
    
    # Initialize database
    init_db()
    
    # Start MQTT client dalam thread terpisah
    mqtt_thread = threading.Thread(target=start_mqtt_client, daemon=True)
    mqtt_thread.start()
    
    # Start periodic database save (every 5 seconds)
    db_save_thread = threading.Thread(target=save_to_database_periodically, daemon=True)
    db_save_thread.start()
    
    # Wait for MQTT to connect
    time.sleep(2)
    
    print("\n🚀 Starting Flask API Server...")
    print("📡 API available at: http://localhost:5000")
    print("📊 Endpoints: http://localhost:5000/\n")
    
    # Run Flask app
    app.run(host='0.0.0.0', port=5000, debug=True, use_reloader=False)
