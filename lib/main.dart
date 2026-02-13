import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

// Импорты моделей и сервисов
import 'services/hive_service.dart';
import 'models/user.dart';
import 'models/health_record.dart';
import 'models/journal_entry.dart';
import 'services/pdf_service.dart';
import 'services/share_service.dart';
import 'services/ble_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Инициализируем Hive (сервис HiveService)
    await HiveService().init();
    print('Hive инициализирован');
  } catch (e) {
    print('Ошибка инициализации Hive: $e');
  }
  
  runApp(const HealthMonitorApp());
}

class HealthMonitorApp extends StatelessWidget {
  const HealthMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HealthMonitor IoT',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AuthScreen(),
    );
  }
}

// ========== ЭКРАН АВТОРИЗАЦИИ ==========
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Заголовок
                const Text(
                  'HealthMonitor IoT',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Мониторинг здоровья в реальном времени',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 40),
                
                // Форма входа
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const Text(
                          'Вход в систему',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1e293b),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Поле email
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            filled: true,
                            fillColor: const Color(0xFFf8fafc),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Введите email';
                            }
                            if (!value.contains('@')) {
                              return 'Некорректный email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Поле пароля
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Пароль',
                            filled: true,
                            fillColor: const Color(0xFFf8fafc),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Введите пароль';
                            }
                            if (value.length < 6) {
                              return 'Пароль должен быть не менее 6 символов';
                            }
                            return null;
                          },
                        ),

                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),
                        
                        // Ссылка на регистрацию
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                            );
                          },
                          child: const Text('Зарегистрироваться'),
                        ),

                        const SizedBox(height: 20),

                        // Кнопка входа
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4f46e5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 5,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Войти',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),

                        const SizedBox(height: 20),
                        const Text(
                          'Нет аккаунта? Зарегистрируйтесь',
                          style: TextStyle(
                            color: Color(0xFF64748b),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),


              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final hive = HiveService();
      final existing = await hive.getUserByEmail(_emailController.text);

      if (existing == null) {
        // Если пользователь не существует, создаем демо-пользователя через HiveService
        final newUser = await hive.registerUser(
          _emailController.text,
          _passwordController.text,
          'Демо Пользователь',
          25,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user_email', newUser.email);
        await prefs.setString('current_user_name', newUser.name);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainApp(userEmail: newUser.email),
          ),
        );
      } else {
        // Аутентификация через HiveService (учтет хеширование пароля)
        final auth = await hive.authenticateUser(_emailController.text, _passwordController.text);
        if (auth != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('current_user_email', auth.email);
          await prefs.setString('current_user_name', auth.name);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainApp(userEmail: auth.email),
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Неверный пароль';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка входа: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

// ========== ГЛАВНОЕ ПРИЛОЖЕНИЕ ==========
class MainApp extends StatefulWidget {
  final String userEmail;
  
  const MainApp({super.key, required this.userEmail});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 1;
  bool _demoMode = true;
  User? _currentUser;
  String _userName = '';
  
  // Данные для отображения
  double _heartRate = 72.0;
  double _spo2 = 98.0;
  double _stress = 45.0;
  int _steps = 1250;
  double _temperature = 36.6;
  String _sleepPhase = 'awake';
  
  // Пороги
  int _hrThreshold = 100;
  int _spo2Threshold = 95;
  int _stressThreshold = 70;
  
  // Журнал
  List<JournalEntry> _journalEntries = [];
  final TextEditingController _journalTitleController = TextEditingController();
  final TextEditingController _journalDescriptionController = TextEditingController();
  String _selectedJournalType = 'symptom';
  String? _selectedSeverity;
  
  // Графики
  String _selectedMetric = 'heart_rate';
  String _selectedPeriod = '5m';

  // BLE устройства
  final _bleService = BleService();
  List<dynamic> _foundDevices = [];
  bool _isScanning = false;
  List<BluetoothDevice> _systemConnectedDevices = [];
  StreamSubscription? _bleScanSub;

  Color _chartColorForMetric(String metric) {
    switch (metric) {
      case 'heart_rate':
        return Colors.red;
      case 'spo2':
        return Colors.blue;
      case 'stress':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  DateTimeRange _getPeriodRange(String period) {
    final now = DateTime.now();
    switch (period) {
      case '24h':
        return DateTimeRange(start: now.subtract(const Duration(hours: 24)), end: now);
      case '7d':
        return DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
      case '30d':
        return DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);
      default:
        return DateTimeRange(start: now.subtract(const Duration(hours: 24)), end: now);
    }
  }

  Widget _buildLineChartFromRecords(List<HealthRecord> records, Color color) {
    if (records.isEmpty) {
      return Container(
        color: Colors.white,
        child: const Center(
          child: Text('Нет данных для отображения', style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    
    // Сортируем по времени (возрастающе)
    records.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (records.isEmpty) {
      return Container(
        color: Colors.white,
        child: const Center(
          child: Text('Нет данных для отображения', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final minY = records.map((r) => r.value).reduce((a, b) => a < b ? a : b);
    final maxY = records.map((r) => r.value).reduce((a, b) => a > b ? a : b);
    
    // Обрабатываем случай когда все значения одинаковые
    double actualMinY = minY;
    double actualMaxY = maxY;
    if (minY == maxY) {
      actualMinY = minY - 5;
      actualMaxY = maxY + 5;
    }
    
    final paddingY = (actualMaxY - actualMinY) * 0.1;

    // Нормализуем X - используем индексы вместо миллисекунд
    final spots = <FlSpot>[];
    for (int i = 0; i < records.length; i++) {
      spots.add(FlSpot(i.toDouble(), records[i].value));
    }

    double leftInterval = (actualMaxY - actualMinY) / 4;
    if (leftInterval <= 0) leftInterval = actualMaxY == 0 ? 1 : actualMaxY / 4;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: leftInterval > 0 ? leftInterval : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: (records.length / 4).clamp(1.0, double.infinity),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < records.length) {
                  final dt = records[index].timestamp;
                  final totalDays = records.last.timestamp.difference(records.first.timestamp).inDays;
                  final txt = totalDays >= 2 ? DateFormat('dd.MM').format(dt) : DateFormat('HH:mm').format(dt);
                  return Text(txt, style: const TextStyle(fontSize: 10, color: Colors.grey));
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: leftInterval > 0 ? leftInterval : 1,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(0),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              reservedSize: 40,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: color.withOpacity(0.12)),
          ),
        ],
        minY: (actualMinY - paddingY).clamp(0, double.infinity),
        maxY: actualMaxY + paddingY,
        minX: 0,
        maxX: (records.length - 1).toDouble(),
      ),
    );
  }

  Widget _buildSparkline(String metric) {
    return FutureBuilder<List<HealthRecord>>(
      future: Future(() => HiveService().getHealthRecords(widget.userEmail, type: metric)),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
        final records = snap.data ?? [];
        return SizedBox(height: 100, child: _buildLineChartFromRecords(records.reversed.toList(), _chartColorForMetric(metric)));
      },
    );
  }
  
  // Таймер для демо-данных
  Timer? _demoTimer;

  @override
  void initState() {
    super.initState();
    _initApp();
  }
  
  Future<void> _initApp() async {
    try {
      await _ensureTestUserExists();  // Создаем тестового пользователя если его нет
      await _loadUserData();
      await _loadConnectedDevices();
      _startDemoMode();
      await _loadJournalEntries();
    } catch (e) {
      print('Ошибка инициализации приложения: $e');
    }
  }

  Future<bool> _ensurePermissions() async {
    try {
      if (Platform.isAndroid) {
        final statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.location,
        ].request();

        if (statuses[Permission.bluetoothScan]?.isGranted == true &&
            statuses[Permission.bluetoothConnect]?.isGranted == true) {
          return true;
        }

        // If location is required on older Android
        if (statuses[Permission.location]?.isGranted == true) return true;

        return false;
      }
      return true;
    } catch (e) {
      print('Ошибка запроса прав: $e');
      return false;
    }
  }

  Future<void> _loadConnectedDevices() async {
    try {
      final list = await _bleService.getConnectedDevices();
      if (mounted) {
        setState(() {
          _systemConnectedDevices = list;
        });
      }
    } catch (e) {
      print('Ошибка загрузки подключённых устройств: $e');
    }
  }
  
  @override
  void dispose() {
    _demoTimer?.cancel();
    _bleScanSub?.cancel();
    _bleService.dispose();
    _journalTitleController.dispose();
    _journalDescriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('current_user_name') ?? 'Пользователь';
    
    // Загружаем пользователя из БД
    final hive = HiveService();
    _currentUser = await hive.getUserByEmail(widget.userEmail);
    
    // Загружаем сохраненные пороги
    _hrThreshold = prefs.getInt('hr_threshold') ?? 100;
    _spo2Threshold = prefs.getInt('spo2_threshold') ?? 95;
    _stressThreshold = prefs.getInt('stress_threshold') ?? 70;
    _demoMode = prefs.getBool('demo_mode') ?? true;
    
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _ensureTestUserExists() async {
    try {
      final hive = HiveService();
      final testEmail = 'test@test.com';
      final testPassword = '123456';
      
      // Проверяем, существует ли уже тестовый пользователь
      var testUser = await hive.getUserByEmail(testEmail);
      
      if (testUser == null) {
        // Создаем тестового пользователя
        testUser = await hive.registerUser(
          testEmail,
          testPassword,
          'Test User',
          30,
        );
        print('Создан тестовый пользователь: $testEmail');
        
        // Заполняем БД данными на неделю и 24 часа
        final now = DateTime.now();
        final oneWeekAgo = now.subtract(const Duration(days: 7));
        final oneDayAgo = now.subtract(const Duration(hours: 24));
        
        // Генерируем данные за неделю (по одному значению в час)
        for (int i = 0; i < 168; i++) {
          final timestamp = oneWeekAgo.add(Duration(hours: i));
          
          // Heart Rate: 60-100 bpm
          final hr = 70.0 + (i % 20).toDouble() - 10;
          await hive.addHealthRecord(HealthRecord(
            id: 'hr_week_$i',
            userId: testUser.email,
            type: 'heart_rate',
            value: hr,
            timestamp: timestamp,
          ));
          
          // SpO2: 95-99%
          final spo2 = 96.0 + ((i * 3) % 8).toDouble() / 2;
          await hive.addHealthRecord(HealthRecord(
            id: 'spo2_week_$i',
            userId: testUser.email,
            type: 'spo2',
            value: spo2,
            timestamp: timestamp,
          ));
          
          // Stress: 30-80
          final stress = 50.0 + (i % 30).toDouble() - 15;
          await hive.addHealthRecord(HealthRecord(
            id: 'stress_week_$i',
            userId: testUser.email,
            type: 'stress',
            value: stress,
            timestamp: timestamp,
          ));
        }
        
        // Генерируем данные за последние 24 часа (каждые 10 минут)
        for (int i = 0; i < 144; i++) {
          final timestamp = oneDayAgo.add(Duration(minutes: i * 10));
          
          // Heart Rate: варьируем от 60 до 95
          final hr = 72.0 + (i % 15).toDouble() - 7.5;
          await hive.addHealthRecord(HealthRecord(
            id: 'hr_day_$i',
            userId: testUser.email,
            type: 'heart_rate',
            value: hr,
            timestamp: timestamp,
          ));
          
          // SpO2: 96-99%
          final spo2 = 97.0 + ((i * 7) % 12).toDouble() / 4;
          await hive.addHealthRecord(HealthRecord(
            id: 'spo2_day_$i',
            userId: testUser.email,
            type: 'spo2',
            value: spo2,
            timestamp: timestamp,
          ));
          
          // Stress: 35-75
          final stress = 55.0 + (i % 25).toDouble() - 12.5;
          await hive.addHealthRecord(HealthRecord(
            id: 'stress_day_$i',
            userId: testUser.email,
            type: 'stress',
            value: stress,
            timestamp: timestamp,
          ));
        }
        
        print('Заполнена база данных тестовыми данными (неделя + 24 часа)');
      }
    } catch (e) {
      print('Ошибка создания тестового пользователя: $e');
    }
  }
  
  void _startDemoMode() {
    if (_demoMode) {
      _demoTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (mounted) {
          _updateDemoData();
          _saveDemoDataToDatabase();
        }
      });
    }
  }
  
  void _updateDemoData() {
    if (!mounted) return;
    
    setState(() {
      final now = DateTime.now();
      final hour = now.hour;
      
      // Суточные колебания пульса
      double hourFactor = 0.5 * (hour / 12).clamp(0.0, 1.0);
      _heartRate = 72 + hourFactor * 10 + (now.second % 20) - 10;
      _heartRate = _heartRate.clamp(60.0, 120.0);
      
      // Случайные события
      if (now.second % 15 == 0) {
        _heartRate += 25; // Скачок пульса
        _spo2 = 94.0 + (now.millisecond % 100) / 100;
      } else {
        _spo2 = 97.0 + (now.millisecond % 300) / 100;
      }
      
      _stress = 40 + (now.second % 30);
      _steps += 5 + (now.second % 10);
      _temperature = 36.6 + (now.millisecond % 100) / 100 - 0.5;
      
      // Фаза сна
      if (hour >= 23 || hour <= 6) {
        _sleepPhase = now.second % 2 == 0 ? 'deep' : 'light';
      } else {
        _sleepPhase = 'awake';
      }
    });
  }
  
  Future<void> _saveDemoDataToDatabase() async {
    if (_currentUser == null) return;
    
    try {
      final hive = HiveService();
      final now = DateTime.now();

      await hive.addHealthRecord(HealthRecord(
        id: 'hr_${DateTime.now().millisecondsSinceEpoch}',
        userId: widget.userEmail,
        type: 'heart_rate',
        value: _heartRate,
        timestamp: now,
      ));

      await hive.addHealthRecord(HealthRecord(
        id: 'spo2_${DateTime.now().millisecondsSinceEpoch}',
        userId: widget.userEmail,
        type: 'spo2',
        value: _spo2,
        timestamp: now,
      ));

      await hive.addHealthRecord(HealthRecord(
        id: 'stress_${DateTime.now().millisecondsSinceEpoch}',
        userId: widget.userEmail,
        type: 'stress',
        value: _stress,
        timestamp: now,
      ));
    } catch (e) {
      print('Ошибка сохранения данных: $e');
    }
  }
  
  Future<void> _loadJournalEntries() async {
    try {
      final hive = HiveService();
      _journalEntries = await hive.getJournalEntries(widget.userEmail);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Ошибка загрузки журнала: $e');
    }
  }

  Future<List<HealthRecord>> _fetchAggregatedRecords(String userId, String metric, String period) async {
    final hive = HiveService();
    final now = DateTime.now();

    DateTime start;
    if (period == '5m') {
      start = now.subtract(const Duration(minutes: 5));
      final records = hive.getHealthRecordsByPeriod(userId, metric, start, now);
      return records;
    } else if (period == '1h') {
      start = now.subtract(const Duration(hours: 1));
      final records = hive.getHealthRecordsByPeriod(userId, metric, start, now);
      return records;
    } else if (period == '24h') {
      start = now.subtract(const Duration(hours: 24));
      final raw = hive.getHealthRecordsByPeriod(userId, metric, start, now);
      // aggregate per hour
      return _aggregate(raw, Duration(hours: 1));
    } else if (period == '7d') {
      start = now.subtract(const Duration(days: 7));
      final raw = hive.getHealthRecordsByPeriod(userId, metric, start, now);
      // aggregate per day
      return _aggregate(raw, Duration(days: 1));
    }

    return [];
  }

  List<HealthRecord> _aggregate(List<HealthRecord> raw, Duration bucket) {
    if (raw.isEmpty) return [];
    raw.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final buckets = <int, List<HealthRecord>>{};
    for (var r in raw) {
      final key = (r.timestamp.millisecondsSinceEpoch / bucket.inMilliseconds).floor();
      buckets.putIfAbsent(key, () => []).add(r);
    }

    final result = <HealthRecord>[];
    for (var entry in buckets.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
      final list = entry.value;
      final avg = list.map((e) => e.value).reduce((a, b) => a + b) / list.length;
      final ts = DateTime.fromMillisecondsSinceEpoch(entry.key * bucket.inMilliseconds);
      result.add(HealthRecord(id: 'agg_${ts.millisecondsSinceEpoch}', userId: list.first.userId, type: list.first.type, value: avg, timestamp: ts));
    }

    return result;
  }
  
  Future<void> _saveJournalEntry() async {
    if (_journalTitleController.text.isEmpty) return;
    
    try {
      final hive = HiveService();
      final entry = JournalEntry(
        id: 'je_${DateTime.now().millisecondsSinceEpoch}',
        userId: widget.userEmail,
        type: _selectedJournalType,
        title: _journalTitleController.text,
        description: _journalDescriptionController.text,
        timestamp: DateTime.now(),
        severity: _selectedSeverity,
      );
      
      await hive.addJournalEntry(entry);
      
      _journalTitleController.clear();
      _journalDescriptionController.clear();
      _selectedSeverity = null;
      
      await _loadJournalEntries();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Запись сохранена'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Ошибка сохранения записи: $e');
    }
  }
  
  Future<void> _deleteJournalEntry(String id) async {
    try {
      final hive = HiveService();
      await hive.deleteJournalEntry(id);
      await _loadJournalEntries();
    } catch (e) {
      print('Ошибка удаления записи: $e');
    }
  }

  // ========== BLE МЕТОДЫ ==========
  Future<void> _startBleScanning() async {
    if (_isScanning) return;

    final ok = await _ensurePermissions();
    if (!ok) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Необходимо разрешение на Bluetooth/местоположение')));
      return;
    }

    setState(() => _isScanning = true);
    _foundDevices.clear();

    try {
      // Получаем уже подключенные устройства в системе
      final connectedDevices = await _bleService.getConnectedDevices();
      print('Найдено подключенных устройств: ${connectedDevices.length}');
      for (var device in connectedDevices) {
        print('Подключенное устройство: ${device.platformName ?? device.name ?? device.id.id}');
        _foundDevices.add(device);
      }
      if (mounted && connectedDevices.isNotEmpty) {
        setState(() {});
      }

      await _bleService.startScan(timeout: const Duration(seconds: 8));

      await _bleScanSub?.cancel();
      _bleScanSub = _bleService.deviceStream.listen((scanResult) {
        final device = scanResult.device;
        final id = device.id.id;

        if (!mounted) return;

        final idx = _foundDevices.indexWhere((d) {
          if (d is ScanResult) {
            return d.device.id.id == id;
          } else if (d is BluetoothDevice) {
            return d.id.id == id;
          }
          return false;
        });
        
        if (idx >= 0) {
          // Обновляем существующую запись (чтобы обновлять RSSI)
          setState(() => _foundDevices[idx] = scanResult);
        } else {
          setState(() => _foundDevices.add(scanResult));
        }
      });
    } catch (e) {
      print('Ошибка сканирования: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка сканирования: $e')));
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _stopBleScanning() async {
    await _bleService.stopScan();
    await _bleScanSub?.cancel();
    if (mounted) setState(() => _isScanning = false);
  }

  Future<void> _connectToDevice(dynamic device) async {
    try {
      BluetoothDevice bd;
      String dispName = '';
      if (device is ScanResult) {
        bd = device.device;
        dispName = bd.platformName ?? bd.name ?? bd.id.id;
      } else if (device is BluetoothDevice) {
        bd = device;
        dispName = bd.platformName ?? bd.name ?? bd.id.id;
      } else {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Подключение к $dispName...')),
      );
      
      final success = await _bleService.connect(bd);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Подключено к $dispName')),
        );
        setState(() => _foundDevices.clear());
        await _stopBleScanning();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка подключения'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Ошибка подключения: $e');
    }
  }
  
  void _toggleDemoMode(bool value) async {
    setState(() {
      _demoMode = value;
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('demo_mode', value);
    
    if (value) {
      _startDemoMode();
      // Отключаем BLE при включении демо-режима
      await _bleService.disconnect();
    } else {
      _demoTimer?.cancel();
      _demoTimer = null;
      // Включаем BLE при отключении демо-режима
      _startBleScanning();
    }
  }
  
  Future<void> _updateThreshold(String type, int value) async {
    final prefs = await SharedPreferences.getInstance();
    
    switch (type) {
      case 'heart_rate':
        setState(() => _hrThreshold = value);
        await prefs.setInt('hr_threshold', value);
        break;
      case 'spo2':
        setState(() => _spo2Threshold = value);
        await prefs.setInt('spo2_threshold', value);
        break;
      case 'stress':
        setState(() => _stressThreshold = value);
        await prefs.setInt('stress_threshold', value);
        break;
    }
  }
  
  Color _getStatusColor(String metric, double value) {
    switch (metric) {
      case 'heart_rate':
        if (value > _hrThreshold + 20) return Colors.red;
        if (value > _hrThreshold) return Colors.orange;
        return Colors.green;
      case 'spo2':
        if (value < _spo2Threshold - 2) return Colors.red;
        if (value < _spo2Threshold) return Colors.orange;
        return Colors.green;
      case 'stress':
        if (value > _stressThreshold + 20) return Colors.red;
        if (value > _stressThreshold) return Colors.orange;
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
  
  String _getStatusText(String metric, double value) {
    switch (metric) {
      case 'heart_rate':
        if (value > _hrThreshold + 20) return '● Критично';
        if (value > _hrThreshold) return '● Повышен';
        return '● Норма';
      case 'spo2':
        if (value <= _spo2Threshold - 3) return '● Критично';  // <= 92
        if (value < _spo2Threshold) return '● Понижен';        // 93-94
        return '● Норма';  // >= 95
      case 'stress':
        if (value > _stressThreshold + 20) return '● Критично';
        if (value > _stressThreshold) return '● Повышен';
        return '● Норма';
      default:
        return '● Норма';
    }
  }
  
  Future<void> _generatePdfReport() async {
    if (_currentUser == null) return;
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Генерация PDF отчета...'), duration: Duration(seconds: 2)));

      final hive = HiveService();
      final records = hive.getHealthRecords(widget.userEmail);
      final journal = hive.getJournalEntries(widget.userEmail);
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 7));

      final file = await PdfService.generateHealthReport(
        user: _currentUser!,
        healthRecords: records,
        journalEntries: journal,
        startDate: start,
        endDate: now,
      );

      // Предложить открыть и поделиться — пользователь может выбрать Telegram
      await ShareService.shareFile(file, subject: 'Отчет о состоянии здоровья');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Отчет создан и открыт для отправки')));
    } catch (e) {
      print('Ошибка создания отчета: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_email');
    await prefs.remove('current_user_name');
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }
  
  Widget _buildHealthDashboard() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Заголовок
          Container(
            height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4f46e5), Color(0xFF7c3aed)],
              ),
            ),
            child: Center(
              child: Text(
                'Моё здоровье',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Статус подключения / Поиск BLE
                  if (_demoMode)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFf0f9ff),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFbae6fd)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cloud,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'ДЕМО-РЕЖИМ АКТИВЕН',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_bleService.isConnected)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFe0f5f4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF4db8b1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.bluetooth_connected,
                            color: Color(0xFF0891b2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ПОДКЛЮЧЕНО: ${_bleService.connectedDevice?.platformName ?? "Устройство"}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0891b2),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isScanning ? null : _startBleScanning,
                          icon: const Icon(Icons.bluetooth_searching),
                          label: Text(_isScanning ? 'Поиск...' : 'Найти BLE трекер'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0891b2),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 45),
                          ),
                        ),
                        if (_foundDevices.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          FutureBuilder<List<BluetoothDevice>>(
                            future: _bleService.getConnectedDevices(),
                            builder: (context, connectedSnap) {
                              // Комбинируем найденные устройства с подключенными
                              final displayDevices = List.from(_foundDevices);
                              if (connectedSnap.hasData) {
                                for (var connDevice in connectedSnap.data!) {
                                  final idx = displayDevices.indexWhere((d) {
                                    if (d is ScanResult) return d.device.id.id == connDevice.id.id;
                                    if (d is BluetoothDevice) return d.id.id == connDevice.id.id;
                                    return false;
                                  });
                                  if (idx < 0) {
                                    displayDevices.add(connDevice);
                                  }
                                }
                              }
                              
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFf5f3ff),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFc4b5fd)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Найденные устройства:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    ...displayDevices.map((item) {
                                      BluetoothDevice? dev;
                                      ScanResult? scan;
                                      bool isMedical = false;
                                      
                                      if (item is ScanResult) {
                                        scan = item;
                                        dev = scan.device;
                                        isMedical = _isMedicalDevice(scan);
                                      } else if (item is BluetoothDevice) {
                                        dev = item;
                                        isMedical = false;
                                      }
                                      
                                      if (dev == null) return const SizedBox.shrink();
                                      
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: GestureDetector(
                                          onTap: () => _connectToDevice(dev!),
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFc4b5fd)),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 28,
                                                  height: 28,
                                                  decoration: BoxDecoration(
                                                    color: isMedical ? Colors.green : Colors.red,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: isMedical
                                                      ? const Center(
                                                          child: Icon(Icons.check, size: 16, color: Colors.white),
                                                        )
                                                      : const SizedBox.shrink(),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        dev.platformName ?? dev.name ?? 'Unknown device',
                                                        style: const TextStyle(fontSize: 14),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        scan != null ? 'RSSI: ${scan.rssi} dBm' : 'Подключено',
                                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),

                  const SizedBox(height: 20),

                  // Карточка пульса
                  _buildMetricCard(
                    'Пульс (ЧСС)',
                    '${_heartRate.toStringAsFixed(0)} уд/мин',
                    Icons.favorite,
                    _getStatusColor('heart_rate', _heartRate),
                    _getStatusText('heart_rate', _heartRate),
                  ),

                  // Карточка кислорода
                  _buildMetricCard(
                    'Кислород (SpO₂)',
                    '${_spo2.toStringAsFixed(1)}%',
                    Icons.air,
                    _getStatusColor('spo2', _spo2),
                    _getStatusText('spo2', _spo2),
                  ),

                  // Карточка стресса
                  _buildMetricCard(
                    'Стресс (HRV)',
                    '${_stress.toStringAsFixed(0)} ед.',
                    Icons.psychology,
                    _getStatusColor('stress', _stress),
                    _getStatusText('stress', _stress),
                  ),

                  const SizedBox(height: 20),

                  // График ЧСС (спарклайн)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFf8fafc),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Пульс — последние значения',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1e293b),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildSparkline('heart_rate'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Кнопка подробной статистики
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _selectedIndex = 2);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4f46e5),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Подробная статистика'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
  
  /// Проверяет, является ли устройство медицинским на основе UUIDs и других характеристик
  bool _isMedicalDevice(ScanResult scanResult) {
    final adv = scanResult.advertisementData;
    
    // Медицинские UUIDs для здравоохранения
    final medicalServiceUuids = [
      '180d', // Heart Rate Service
      '180a', // Device Information Service
      '181f', // Health Thermometer Service
      '1823', // Pulse Oximeter Service
      '180e', // Battery Service (часто используется с медицинскими)
    ];
    
    // Проверяем Service UUIDs
    if (adv?.serviceUuids != null && adv!.serviceUuids!.isNotEmpty) {
      for (var uuid in adv.serviceUuids!) {
        final uuidLower = uuid.toString().toLowerCase();
        if (medicalServiceUuids.any((medUuid) => uuidLower.contains(medUuid))) {
          return true;
        }
      }
    }
    
    // Проверяем характеристики в названии (медицинские устройства часто содержат такие слова)
    final deviceName = (scanResult.device.platformName ?? 
                        scanResult.device.name ?? 
                        '').toLowerCase();
    
    // Слова, которые указывают на медицинские устройства
    final medicalKeywords = [
      'health',
      'heart',
      'pulse', 
      'oximeter',
      'spo2',
      'ecg',
      'bp',
      'blood pressure',
      'monitor',
      'medical',
      'tracker',
      'band',
      'watch',
    ];
    
    // Слова, указывающие на немедицинские устройства (наушники, динамики и т.д.)
    final nonMedicalKeywords = [
      'headphone',
      'earphone',
      'earbuds',
      'speaker',
      'audio',
      'wireless',
      'keyboard',
      'mouse',
      'tablet',
      'phone',
      'camera',
    ];
    
    // Если это явно немедицинское устройство, отмечаем как non-medical
    for (var keyword in nonMedicalKeywords) {
      if (deviceName.contains(keyword)) {
        return false;
      }
    }
    
    // Если это явно медицинское устройство, отмечаем как medical
    for (var keyword in medicalKeywords) {
      if (deviceName.contains(keyword)) {
        return true;
      }
    }
    
    // Если есть Manufacturer Data, это обычно BLE устройство
    if (adv?.manufacturerData != null && adv!.manufacturerData!.isNotEmpty) {
      // Но если мы не знаем, что это медицинское, считаем его немедицинским
      return false;
    }
    
    // По умолчанию: если устройство имеет какую-то информацию, но мы не знаем, что это медицинское, считаем его немедицинским
    return false;
  }
  
  Widget _buildMetricCard(String title, String value, IconData icon, Color statusColor, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFf8fafc),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: statusColor, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1e293b),
                ),
              ),
              Text(
                status,
                style: TextStyle(color: statusColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0f172a),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnalyticsScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Заголовок
          Container(
            height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4f46e5), Color(0xFF7c3aed)],
              ),
            ),
            child: const Center(
              child: Text(
                'Аналитика',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Статистика показателей',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1e293b),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Анализ данных за различные периоды',
                    style: TextStyle(
                      color: Color(0xFF64748b),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Выбор показателя
                  DropdownButtonFormField<String>(
                    value: _selectedMetric,
                    items: const [
                      DropdownMenuItem(
                        value: 'heart_rate',
                        child: Text('Пульс (ЧСС)'),
                      ),
                      DropdownMenuItem(
                        value: 'spo2',
                        child: Text('Кислород (SpO₂)'),
                      ),
                      DropdownMenuItem(
                        value: 'stress',
                        child: Text('Уровень стресса'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedMetric = value!);
                    },
                    decoration: InputDecoration(
                      labelText: 'Показатель',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Выбор периода
                  DropdownButtonFormField<String>(
                    value: _selectedPeriod,
                    items: const [
                      DropdownMenuItem(value: '5m', child: Text('5 минут')),
                      DropdownMenuItem(value: '1h', child: Text('1 час')),
                      DropdownMenuItem(value: '24h', child: Text('24 часа (по часам)')),
                      DropdownMenuItem(value: '7d', child: Text('7 дней (по дням)')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedPeriod = value!);
                    },
                    decoration: InputDecoration(
                      labelText: 'Период',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Интерактивный график по выбранному показателю
                  FutureBuilder<List<HealthRecord>>(
                    key: ValueKey('$_selectedMetric-$_selectedPeriod'),
                    future: _fetchAggregatedRecords(widget.userEmail, _selectedMetric, _selectedPeriod),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) return SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                      final records = snap.data ?? [];
                      return Container(
                        height: 240,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFf8fafc),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'График: ${_selectedMetric == 'heart_rate' ? 'Пульс' : _selectedMetric == 'spo2' ? 'SpO₂' : 'Стресс'}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Expanded(child: _buildLineChartFromRecords(records, _chartColorForMetric(_selectedMetric))),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Статистика за выбранный период (использует HiveService)
                  FutureBuilder<Map<String, dynamic>>(
                    key: ValueKey('stats-$_selectedMetric-$_selectedPeriod'),
                    future: Future(() {
                      final range = _getPeriodRange(_selectedPeriod);
                      return HiveService().getHealthStatistics(widget.userEmail, _selectedMetric, range.start, range.end);
                    }),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) return SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
                      final stats = snap.data ?? {'min': 0, 'max': 0, 'avg': 0};
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFf0f9ff),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.bar_chart, color: Color(0xFF0369a1)),
                                SizedBox(width: 8),
                                Text(
                                  'Статистика за период',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0369a1),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStatItem('Мин.', (stats['min'] ?? 0).toStringAsFixed(1)),
                                _buildStatItem('Макс.', (stats['max'] ?? 0).toStringAsFixed(1)),
                                _buildStatItem('Средн.', (stats['avg'] ?? 0).toStringAsFixed(1)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
  
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748b),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1e293b),
          ),
        ),
      ],
    );
  }
  
  Widget _buildJournalScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Заголовок
          Container(
            height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4f46e5), Color(0xFF7c3aed)],
              ),
            ),
            child: const Center(
              child: Text(
                'Журнал здоровья',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_systemConnectedDevices.isNotEmpty) ...[
                    const Text(
                      'Системно подключённые устройства',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1e293b),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._systemConnectedDevices.map((dev) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () => _connectToDevice(dev),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFe5e7eb)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.devices, size: 20, color: Color(0xFF0369a1)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dev.platformName ?? dev.name ?? dev.id.id,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Системное подключение — нажмите, чтобы подключиться в приложении',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'Новая запись',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1e293b),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Выбор типа записи
                  Row(
                    children: [
                      _buildJournalTypeButton('🤒 Симптом', 'symptom'),
                      _buildJournalTypeButton('💊 Лекарство', 'medication'),
                      _buildJournalTypeButton('📝 Заметка', 'note'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Заголовок
                  TextField(
                    controller: _journalTitleController,
                    decoration: InputDecoration(
                      labelText: 'Заголовок',
                      filled: true,
                      fillColor: const Color(0xFFf8fafc),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Описание
                  TextField(
                    controller: _journalDescriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Описание',
                      filled: true,
                      fillColor: const Color(0xFFf8fafc),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Серьезность (только для симптомов)
                  if (_selectedJournalType == 'symptom')
                    DropdownButtonFormField<String>(
                      value: _selectedSeverity,
                      items: const [
                        DropdownMenuItem(
                          value: 'Низкая',
                          child: Text('Низкая'),
                        ),
                        DropdownMenuItem(
                          value: 'Средняя',
                          child: Text('Средняя'),
                        ),
                        DropdownMenuItem(
                          value: 'Высокая',
                          child: Text('Высокая'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedSeverity = value);
                      },
                      decoration: InputDecoration(
                        labelText: 'Серьезность',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Кнопка сохранения
                  ElevatedButton.icon(
                    onPressed: _saveJournalEntry,
                    icon: const Icon(Icons.save),
                    label: const Text('Сохранить запись'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10b981),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Последние записи
                  const Text(
                    'Последние записи',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1e293b),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_journalEntries.isEmpty)
                    const Center(
                      child: Text(
                        'Записей пока нет',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ..._journalEntries.map((entry) => _buildJournalEntryCard(entry)),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
  
  Widget _buildJournalTypeButton(String text, String type) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        child: ElevatedButton(
          onPressed: () {
            setState(() => _selectedJournalType = type);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedJournalType == type 
                ? const Color(0xFFe0e7ff) 
                : const Color(0xFFf8fafc),
            foregroundColor: _selectedJournalType == type 
                ? const Color(0xFF4f46e5) 
                : const Color(0xFF64748b),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(text),
        ),
      ),
    );
  }
  
  Widget _buildJournalEntryCard(JournalEntry entry) {
    String emoji = '';
    Color color = Colors.grey;
    
    switch (entry.type) {
      case 'symptom':
        emoji = '🤒';
        color = Colors.red;
        break;
      case 'medication':
        emoji = '💊';
        color = Colors.green;
        break;
      case 'note':
        emoji = '📝';
        color = Colors.blue;
        break;
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Text(emoji),
        ),
        title: Text(entry.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.description),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd.MM.yyyy HH:mm').format(entry.timestamp),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (entry.severity != null)
              Chip(
                label: Text(entry.severity!),
                backgroundColor: color.withOpacity(0.2),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteJournalEntry(entry.id),
        ),
      ),
    );
  }
  
  Widget _buildSettingsScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Заголовок
          Container(
            height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4f46e5), Color(0xFF7c3aed)],
              ),
            ),
            child: const Center(
              child: Text(
                'Настройки',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Профиль
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Профиль',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1e293b),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  'АТ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1e293b),
                                  ),
                                ),
                                Text(
                                  _currentUser?.email ?? widget.userEmail,
                                  style: const TextStyle(
                                    color: Color(0xFF64748b),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _logout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Выйти из аккаунта'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Демо-режим
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Режим работы',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1e293b),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          title: const Text('Демо-режим'),
                          subtitle: const Text('Генерация тестовых данных'),
                          value: _demoMode,
                          onChanged: _toggleDemoMode,
                        ),
                          if (_demoMode)
                          const Padding(
                            padding: EdgeInsets.only(left: 16, top: 8),
                            child: Text(
                              'Данные генерируются каждые 2 секунды',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Пороги уведомлений
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Пороги уведомлений',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1e293b),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Настройте значения для цветовой индикации',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        
                        // Порог ЧСС
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Порог ЧСС'),
                                Text('$_hrThreshold уд/мин'),
                              ],
                            ),
                            Slider(
                              value: _hrThreshold.toDouble(),
                              min: 60,
                              max: 140,
                              divisions: 16,
                              label: '$_hrThreshold уд/мин',
                              onChanged: (value) {
                                _updateThreshold('heart_rate', value.round());
                              },
                            ),
                          ],
                        ),
                        
                        const Divider(height: 30),
                        
                        // Порог SpO₂
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Порог SpO₂'),
                                Text('$_spo2Threshold%'),
                              ],
                            ),
                            Slider(
                              value: _spo2Threshold.toDouble(),
                              min: 90,
                              max: 100,
                              divisions: 10,
                              label: '$_spo2Threshold%',
                              onChanged: (value) {
                                _updateThreshold('spo2', value.round());
                              },
                            ),
                          ],
                        ),
                        
                        const Divider(height: 30),
                        
                        // Порог стресса
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Порог стресса'),
                                Text('$_stressThreshold ед.'),
                              ],
                            ),
                            Slider(
                              value: _stressThreshold.toDouble(),
                              min: 30,
                              max: 100,
                              divisions: 14,
                              label: '$_stressThreshold ед.',
                              onChanged: (value) {
                                _updateThreshold('stress', value.round());
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Отчеты
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Отчеты',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1e293b),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _generatePdfReport,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Создать PDF отчет'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4f46e5),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                
                // Подпись
                Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  child: Text(
                    'Таров А.А. 2026',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
  
  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() => _selectedIndex = index);
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF4f46e5),
      unselectedItemColor: const Color(0xFF64748b),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.bluetooth),
          label: 'Устройства',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: 'Здоровье',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Аналитика',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book),
          label: 'Журнал',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Настройки',
        ),
      ],
    );
  }
  
  Widget _buildDevicesScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Заголовок
          Container(
            height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4f46e5), Color(0xFF7c3aed)],
              ),
            ),
            child: const Center(
              child: Text(
                'BLE Устройства',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Статус подключения
                  if (_bleService.isConnected)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFe0f5f4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF0891b2), width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bluetooth_connected, color: Color(0xFF0891b2), size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Подключено',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF0891b2),
                                      ),
                                    ),
                                    Text(
                                      _bleService.connectedDevice?.platformName ?? 'Устройство',
                                      style: const TextStyle(
                                        color: Color(0xFF0f766e),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  await _bleService.disconnect();
                                  setState(() {});
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Отключить'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Поиск устройств',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1e293b),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _isScanning ? null : () async {
                            await _startBleScanning();
                            setState(() {});
                          },
                          icon: Icon(_isScanning ? Icons.hourglass_bottom : Icons.bluetooth_searching),
                          label: Text(_isScanning ? 'Поиск...' : 'Начать поиск'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0891b2),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        if (_isScanning)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFCD34D)),
                              ),
                              child: const Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(Color(0xFFDC2626)),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Сканирование... Ожидайте 8 секунд'),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  
                  const SizedBox(height: 24),

                  // Подключённые устройства (системные + подключённые приложением)
                  Builder(builder: (context) {
                    final combined = <BluetoothDevice>[];
                    combined.addAll(_systemConnectedDevices);
                    if (_bleService.connectedDevice != null && !combined.any((d) => d.id.id == _bleService.connectedDevice!.id.id)) {
                      combined.insert(0, _bleService.connectedDevice!);
                    }

                    if (combined.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.bluetooth_disabled, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            const Text(
                              'Нет подключённых Bluetooth устройств',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4b5563),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Нажмите "Начать поиск" чтобы подключить устройство',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Подключённых устройств: ${combined.length}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1e293b)),
                        ),
                        const SizedBox(height: 12),
                        ...combined.map((dev) {
                          final isAppConnected = _bleService.connectedDevice?.id.id == dev.id.id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFe5e7eb), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.bluetooth_connected, size: 24, color: Color(0xFF0369a1)),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dev.platformName ?? dev.name ?? dev.id.id,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF1e293b)),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isAppConnected ? 'Подключено в приложении' : 'Подключено в системе',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isAppConnected)
                                    ElevatedButton(
                                      onPressed: () async {
                                        await _bleService.disconnect();
                                        await _loadConnectedDevices();
                                        setState(() {});
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                      child: const Text('Отключить'),
                                    )
                                  else
                                    ElevatedButton(
                                      onPressed: () async {
                                        await _connectToDevice(dev);
                                        await _loadConnectedDevices();
                                        setState(() {});
                                      },
                                      child: const Text('Подключиться'),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }),

                  const SizedBox(height: 24),

                  // Справка
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info, color: Color(0xFFD97706), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'О подключении',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Включите Bluetooth на вашем устройстве\n'
                          '• Убедитесь, что трекер включен и находится рядом\n'
                          '• Приложение поддерживает устройства с датчиками пульса, SpO₂ и стресса\n'
                          '• После подключения данные автоматически синхронизируются',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
  

  Widget _buildCurrentScreen() {
    switch (_selectedIndex) {
      case 0: return _buildDevicesScreen();
      case 1: return _buildHealthDashboard();
      case 2: return _buildAnalyticsScreen();
      case 3: return _buildJournalScreen();
      case 4: return _buildSettingsScreen();
      default: return _buildDevicesScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildCurrentScreen();
  }

}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => (v == null || v.isEmpty) ? 'Enter name' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => (v == null || !v.contains('@')) ? 'Enter valid email' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) => (v == null || v.length < 6) ? 'Min 6 chars' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final hive = HiveService();
      final user = await hive.registerUser(
        _emailController.text,
        _passwordController.text,
        _nameController.text.isEmpty ? 'User' : _nameController.text,
        int.tryParse(_ageController.text) ?? 30,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_email', user.email);
      await prefs.setString('current_user_name', user.name);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MainApp(userEmail: user.email)),
        (_) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

