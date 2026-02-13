#!/usr/bin/env python3
"""
BLE Health Tracker Emulator for Linux/WSL 2
Emulates a Bluetooth Low Energy health tracker device that your Flutter app can connect to.

Install dependencies:
  pip3 install bleak dbus-python

On WSL 2 or Linux, run:
  python3 ble_tracker_emulator.py
"""

import asyncio
import random
import sys
from datetime import datetime

try:
    import dbus
    from dbus.service import BusName, Object, method, signal
    from dbus.mainloop.glib import DBusGMainLoop
    import gi
    gi.require_version('GLib', '2.0')
    from gi.repository import GLib
except ImportError:
    print("❌ Error: Required packages not installed.")
    print("Please install: pip3 install dbus-python PyGObject")
    print("On Ubuntu/Debian: sudo apt-get install python3-dbus python3-gi gir1.2-glib-2.0")
    sys.exit(1)

# BlueZ D-Bus paths and UUIDs
SERVICE_NAME = "org.bluez"
ADAPTER_PATH = "/org/bluez/hci0"

# Standard BLE UUIDs for Health Tracker
HEART_RATE_SERVICE_UUID = "180d"
HEART_RATE_CHAR_UUID = "2a37"
DEVICE_INFO_SERVICE_UUID = "180a"
MANUFACTURER_NAME_CHAR_UUID = "2a29"

class GattCharacteristic(dbus.service.Object):
    """Represents a GATT characteristic"""
    
    def __init__(self, bus, path, uuid, flags, service):
        dbus.service.Object.__init__(self, bus, path)
        self.path = path
        self.uuid = uuid
        self.flags = flags
        self.service = service
        self.value = [0]
        self.notifying = False
        self.descriptors = []

    @dbus.service.method("org.bluez.GattCharacteristic1", out_signature='ay')
    def ReadValue(self, options=None):
        return dbus.Array(self.value, signature=dbus.Signature('y'))

    @dbus.service.method("org.bluez.GattCharacteristic1")
    def WriteValue(self, value, options=None):
        self.value = value
        print(f"  ✎ Characteristic {self.uuid} written: {list(value)}")

    @dbus.service.method("org.bluez.GattCharacteristic1")
    def StartNotify(self):
        if self.notifying:
            return
        self.notifying = True
        print(f"  🔔 Notifications started for {self.uuid}")

    @dbus.service.method("org.bluez.GattCharacteristic1")
    def StopNotify(self):
        self.notifying = False
        print(f"  🔕 Notifications stopped for {self.uuid}")

    @dbus.service.signal("org.bluez.GattCharacteristic1", signature='ay')
    def PropertiesChanged(self, props):
        pass

    @dbus.service.method("org.freedesktop.DBus.Properties", in_signature='s', out_signature='a{sv}')
    def GetAll(self, interface_name):
        if interface_name == "org.bluez.GattCharacteristic1":
            return {
                'UUID': dbus.String(self.uuid),
                'Service': dbus.ObjectPath(self.service.path),
                'Value': dbus.Array(self.value, signature=dbus.Signature('y')),
                'NotifyingClients': dbus.Array([], signature=dbus.Signature('s')),
                'Flags': dbus.Array(self.flags, signature=dbus.Signature('s')),
                'WriteAcquireSupported': dbus.Boolean(False),
                'ReadAcquireSupported': dbus.Boolean(False),
            }
        return {}

    def update_value(self, new_value):
        self.value = new_value
        if self.notifying:
            self.PropertiesChanged({'Value': dbus.Array(new_value, signature=dbus.Signature('y'))})


class GattService(dbus.service.Object):
    """Represents a GATT service"""
    
    def __init__(self, bus, path, uuid, primary=True):
        dbus.service.Object.__init__(self, bus, path)
        self.path = path
        self.uuid = uuid
        self.primary = primary
        self.characteristics = []

    @dbus.service.method("org.freedesktop.DBus.Properties", in_signature='s', out_signature='a{sv}')
    def GetAll(self, interface_name):
        if interface_name == "org.bluez.GattService1":
            return {
                'UUID': dbus.String(self.uuid),
                'Primary': dbus.Boolean(self.primary),
                'Characteristics': dbus.Array(
                    [dbus.ObjectPath(c.path) for c in self.characteristics],
                    signature=dbus.Signature('o')
                ),
            }
        return {}

    def add_characteristic(self, characteristic):
        self.characteristics.append(characteristic)


class BleTrackerEmulator:
    """BLE Health Tracker Emulator"""
    
    def __init__(self):
        DBusGMainLoop(set_as_default=True)
        self.bus = dbus.SystemBus()
        self.mainloop = GLib.MainLoop()
        self.heart_rate = 72
        self.spo2 = 97.5
        self.stress = 45
        self.hr_char = None
        
    def setup(self):
        """Setup BLE advertisement and GATT services"""
        print("🔧 Setting up BLE Health Tracker emulator...")
        
        try:
            adapter = self.bus.get_object(SERVICE_NAME, ADAPTER_PATH)
            adapter_iface = dbus.Interface(adapter, "org.bluez.Adapter1")
            
            # Power on adapter
            adapter_iface.Set("org.bluez.Adapter1", "Powered", dbus.Boolean(True))
            print("✅ Bluetooth adapter powered on")
            
            # Set adapter name and other properties
            adapter_iface.Set("org.bluez.Adapter1", "Alias", dbus.String("Flutter Health Tracker"))
            adapter_iface.Set("org.bluez.Adapter1", "Discoverable", dbus.Boolean(True))
            
            print("✅ Adapter configured as 'Flutter Health Tracker'")
            
        except Exception as e:
            print(f"⚠️  Warning: Could not configure adapter: {e}")
            print("   Make sure BlueZ is running: sudo systemctl start bluetooth")

    def create_services(self):
        """Create GATT services and characteristics"""
        print("📝 Creating GATT services...")
        
        # Heart Rate Service
        hr_service_path = "/org/bluez/example/service1"
        hr_service = GattService(self.bus, hr_service_path, HEART_RATE_SERVICE_UUID, primary=True)
        
        # Heart Rate Measurement Characteristic
        hr_char_path = hr_service_path + "/char1"
        self.hr_char = GattCharacteristic(
            self.bus,
            hr_char_path,
            HEART_RATE_CHAR_UUID,
            flags=["read", "notify"],
            service=hr_service
        )
        hr_service.add_characteristic(self.hr_char)
        
        print(f"✅ Heart Rate Service created: {HEART_RATE_SERVICE_UUID}")
        print(f"✅ Heart Rate Characteristic created: {HEART_RATE_CHAR_UUID}")
        
        return hr_service

    def start_data_updates(self):
        """Start periodic health data updates"""
        print("📊 Starting health data simulation...")
        
        def update_data():
            # Simulate realistic health data changes
            self.heart_rate += random.randint(-3, 5)
            self.heart_rate = max(60, min(120, self.heart_rate))
            
            self.spo2 += random.uniform(-0.2, 0.2)
            self.spo2 = max(95.0, min(99.0, self.spo2))
            
            self.stress += random.randint(-2, 4)
            self.stress = max(30, min(80, self.stress))
            
            # Update Heart Rate characteristic value (BLE standard format: flags byte + HR value)
            # Flags: 0x00 (8-bit HR value), HR: heart_rate
            hr_value = [0x00, int(self.heart_rate)]
            self.hr_char.update_value(hr_value)
            
            timestamp = datetime.now().strftime("%H:%M:%S")
            print(f"[{timestamp}] 💓 HR: {self.heart_rate} bpm | 🫁 SpO₂: {self.spo2:.1f}% | 🧠 Stress: {self.stress}")
            
            # Schedule next update
            GLib.timeout_add_seconds(2, update_data)
            return False
        
        # Start updates
        GLib.timeout_add_seconds(2, update_data)

    def run(self):
        """Run the emulator"""
        print("\n" + "="*60)
        print("🚀 BLE Health Tracker Emulator")
        print("="*60)
        print("\n📱 Instructions:")
        print("1. On your phone, open the Health Monitor app")
        print("2. Go to Devices tab")
        print("3. Click 'Start Search' (🔍)")
        print("4. Look for 'Flutter Health Tracker' in the list")
        print("5. Click to connect")
        print("\n💡 The tracker will broadcast:")
        print("   - Heart Rate: 60-120 bpm")
        print("   - SpO₂: 95-99%")
        print("   - Stress: 30-80")
        print("\n⏹️  Press Ctrl+C to stop the emulator\n")
        print("="*60 + "\n")
        
        try:
            self.setup()
            self.create_services()
            self.start_data_updates()
            
            print("✨ Emulator running and advertising...")
            self.mainloop.run()
            
        except KeyboardInterrupt:
            print("\n\n🛑 Shutting down...")
            self.mainloop.quit()
        except Exception as e:
            print(f"\n❌ Error: {e}")
            print("\nTroubleshooting:")
            print("- Make sure you're on Linux or WSL 2")
            print("- Run: sudo systemctl start bluetooth")
            print("- Install dependencies: pip3 install dbus-python PyGObject")
            sys.exit(1)


if __name__ == "__main__":
    emulator = BleTrackerEmulator()
    emulator.run()
