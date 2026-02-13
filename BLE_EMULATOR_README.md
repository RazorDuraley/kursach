# BLE Health Tracker Emulator

Эмулятор Bluetooth Low Energy устройства (трекера) для тестирования приложения Health Monitor на Windows PC.

## Требования

- **Linux** (Ubuntu, Debian, Fedora и т.д.) или **WSL 2** на Windows
- Python 3.7+
- Bluetooth адаптер на компьютере (встроенный или USB)

## Установка

### На Linux (Ubuntu/Debian):

```bash
# Установите зависимости
sudo apt-get update
sudo apt-get install -y python3 python3-pip bluetooth bluez bluez-tools
sudo apt-get install -y python3-dbus python3-gi gir1.2-glib-2.0

# Установите Python пакеты
pip3 install dbus-python PyGObject

# Убедитесь, что Bluetooth сервис запущен
sudo systemctl start bluetooth
sudo systemctl enable bluetooth
```

### На WSL 2 (Windows):

```bash
# В WSL терминал:
sudo apt-get update
sudo apt-get install -y python3 python3-pip bluetooth bluez python3-dbus python3-gi gir1.2-glib-2.0

pip3 install dbus-python PyGObject

# Запустите BlueZ:
sudo service bluetooth start
# или
sudo systemctl start bluetooth
```

## Использование

### Запуск эмулятора:

```bash
sudo python3 ble_tracker_emulator.py
```

⚠️ **Важно**: требуется `sudo` для доступа к Bluetooth устройствам.

### В приложении Health Monitor:

1. Откройте приложение на телефоне
2. Перейдите на вкладку **Устройства**
3. Нажмите **Начать поиск** (иконка поиска)
4. Должно появиться устройство **"Flutter Health Tracker"**
5. Нажмите на него, чтобы подключиться
6. Данные будут отправляться каждые 2 секунды:
   - Heart Rate: 60-120 bpm
   - SpO₂: 95-99%
   - Stress: 30-80

### Остановка эмулятора:

Нажмите **Ctrl+C** в терминале.

## Архитектура

Эмулятор создает GATT сервис со стандартным UUID для Heart Rate Service (180d) и отправляет данные через характеристику 2a37 (Heart Rate Measurement).

Это соответствует стандарту Bluetooth LE Health Devices Profile и совместимо с приложением.

## Если не работает

### Проверьте BlueZ:
```bash
sudo systemctl status bluetooth
sudo hciconfig
```

### Проверьте Python зависимости:
```bash
python3 -c "import dbus; print('✓ dbus OK')"
python3 -c "import gi; print('✓ gi OK')"
```

### Перезагрузите BlueZ:
```bash
sudo systemctl restart bluetooth
```

### На WSL 2 проверьте, что USB адаптер проброшен:
```bash
usbipd list  # в PowerShell на Windows
```

## Notes

- Эмулятор имитирует реалистичные изменения показателей здоровья
- Данные обновляются каждые 2 секунды
- Поддерживается несколько одновременных подключений
