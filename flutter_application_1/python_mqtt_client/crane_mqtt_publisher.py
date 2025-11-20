import paho.mqtt.client as mqtt
import json
import time
import random
from datetime import datetime

print("🚀 Starting Crane MQTT Publisher with Actual Counter Values...")

# ✅ USE YOUR COMPANY'S BROKER IP
client = mqtt.Client()
client.connect("YOUR DEVICE IP", 1883, 60)  # ← YOUR COMPANY BROKER

# Initialize counter
counter = 1

while True:
    data = {
        "hoist_up": counter,           # ⬆️ ACTUAL VALUE: 1, 2, 3, 4...
        "hoist_down": counter,         # ⬆️ ACTUAL VALUE: 1, 2, 3, 4...
        "ct_left": counter,            # ⬆️ ACTUAL VALUE: 1, 2, 3, 4...
        "ct_right": counter,           # ⬆️ ACTUAL VALUE: 1, 2, 3, 4...
        "lt_forward": counter,         # ⬆️ ACTUAL VALUE: 1, 2, 3, 4...
        "lt_reverse": counter,         # ⬆️ ACTUAL VALUE: 1, 2, 3, 4...
        "switch": counter,             # ⬆️ ACTUAL VALUE: 1, 2, 3, 4...
        "total_duration": "45:22:15",
        "current_load": round(random.uniform(100.0, 1000.0), 2),
        "is_powered_on": random.choice([0, 1]),
        "timestamp": datetime.now().isoformat() + "Z"
    }
    
    json_data = json.dumps(data)
    client.publish("crane/operations", json_data)
    
    print(f"✅ COUNTER VALUE: {counter}")
    print(f"   HOIST: ↑{counter} ↓{counter}")
    print(f"   CT: ←{counter} →{counter}") 
    print(f"   LT: ↗{counter} ↙{counter}")
    print(f"   SWITCH: {counter}")
    print(f"   LOAD: {data['current_load']}kg")
    print(f"   POWER: {'ON' if data['is_powered_on'] else 'OFF'}")
    print("---")
    
    counter += 1  # Increase for next message
    time.sleep(1)  # Wait 1 second between messages