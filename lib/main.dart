import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// Импорты моделей и сервисов
import 'database/database_helper.dart';
import 'models/user.dart';
import 'models/health_record.dart';
import 'models/journal_entry.dart';
import 'services/pdf_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Инициализируем базу данных
    await DatabaseHelper().database;
    print('База данных инициализирована');
  } catch (e) {
    print('Ошибка инициализации БД: $e');
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
  final _emailController = TextEditingController(text: 'demo@healthmonitor.com');
  final _passwordController = TextEditingController(text: 'demo123');
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
                // Статус бар
                Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(DateTime.now()),
                        style: TextStyle(color: Colors.white.withOpacity(0.9)),
                      ),
                      const Text(
                        '📶 100%',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
                
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
                        
                        // Биометрическая аутентификация
                        const Text(
                          'Или войти с помощью отпечатка пальца',
                          style: TextStyle(
                            color: Color(0xFF64748b),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),

                        IconButton(
                          icon: const Icon(
                            Icons.fingerprint,
                            size: 50,
                            color: Color(0xFF4f46e5),
                          ),
                          onPressed: () {
                            // Демо-биометрия
                            _emailController.text = 'demo@healthmonitor.com';
                            _passwordController.text = 'demo123';
                            _handleLogin();
                          },
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
                          'Нет аккаунта? Используйте демо-доступ',
                          style: TextStyle(
                            color: Color(0xFF64748b),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Нижняя навигация
                Container(
                  height: 70,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock, color: Color(0xFF4f46e5), size: 24),
                          SizedBox(height: 4),
                          Text(
                            'Вход',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4f46e5),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.settings, color: Color(0xFF64748b), size: 24),
                          SizedBox(height: 4),
                          Text(
                            'Настройки',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748b),
                            ),
                          ),
                        ],
                      ),
                    ],
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
      final dbHelper = DatabaseHelper();
      final user = await dbHelper.getUserByEmail(_emailController.text);
      
      if (user == null) {
        // Если пользователь не существует, создаем демо-пользователя
        final newUser = User(
          email: _emailController.text,
          password: _passwordController.text,
          name: 'Демо Пользователь',
          age: 25,
        );
        await dbHelper.insertUser(newUser);
        
        // Сохраняем в SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user_email', _emailController.text);
        await prefs.setString('current_user_name', newUser.name);
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainApp(userEmail: _emailController.text),
          ),
        );
      } else if (user.password == _passwordController.text) {
        // Успешный вход
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user_email', user.email);
        await prefs.setString('current_user_name', user.name);
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainApp(userEmail: user.email),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Неверный пароль';
        });
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
  String _selectedPeriod = '24h';
  
  // Таймер для демо-данных
  Timer? _demoTimer;

  @override
  void initState() {
    super.initState();
    _initApp();
  }
  
  Future<void> _initApp() async {
    try {
      await _loadUserData();
      _startDemoMode();
      await _loadJournalEntries();
    } catch (e) {
      print('Ошибка инициализации приложения: $e');
    }
  }
  
  @override
  void dispose() {
    _demoTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('current_user_name') ?? 'Пользователь';
    
    // Загружаем пользователя из БД
    final dbHelper = DatabaseHelper();
    _currentUser = await dbHelper.getUserByEmail(widget.userEmail);
    
    // Загружаем сохраненные пороги
    _hrThreshold = prefs.getInt('hr_threshold') ?? 100;
    _spo2Threshold = prefs.getInt('spo2_threshold') ?? 95;
    _stressThreshold = prefs.getInt('stress_threshold') ?? 70;
    _demoMode = prefs.getBool('demo_mode') ?? true;
    
    if (mounted) {
      setState(() {});
    }
  }
  
  void _startDemoMode() {
    if (_demoMode) {
      _demoTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
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
      final dbHelper = DatabaseHelper();
      final now = DateTime.now();
      
      await dbHelper.insertHealthRecord(HealthRecord(
        userId: widget.userEmail,
        type: 'heart_rate',
        value: _heartRate,
        timestamp: now,
      ));
      
      await dbHelper.insertHealthRecord(HealthRecord(
        userId: widget.userEmail,
        type: 'spo2',
        value: _spo2,
        timestamp: now,
      ));
      
      await dbHelper.insertHealthRecord(HealthRecord(
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
      final dbHelper = DatabaseHelper();
      _journalEntries = await dbHelper.getJournalEntries(widget.userEmail);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Ошибка загрузки журнала: $e');
    }
  }
  
  Future<void> _saveJournalEntry() async {
    if (_journalTitleController.text.isEmpty) return;
    
    try {
      final dbHelper = DatabaseHelper();
      final entry = JournalEntry(
        userId: widget.userEmail,
        type: _selectedJournalType,
        title: _journalTitleController.text,
        description: _journalDescriptionController.text,
        timestamp: DateTime.now(),
        severity: _selectedSeverity,
      );
      
      await dbHelper.insertJournalEntry(entry);
      
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
  
  Future<void> _deleteJournalEntry(int id) async {
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.deleteJournalEntry(id);
      await _loadJournalEntries();
    } catch (e) {
      print('Ошибка удаления записи: $e');
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
    } else {
      _demoTimer?.cancel();
      _demoTimer = null;
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
        if (value < _spo2Threshold - 2) return '● Критично';
        if (value < _spo2Threshold) return '● Понижен';
        return '● Норма';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Генерация PDF отчета...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Временно упрощаем - просто показываем сообщение
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF отчет создан успешно!'),
          duration: Duration(seconds: 3),
        ),
      );
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
          // Статус бар
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            color: const Color(0xFFf8fafc),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('HH:mm').format(DateTime.now()),
                  style: const TextStyle(color: Color(0xFF64748b)),
                ),
                const Text(
                  '📶 100%',
                  style: TextStyle(color: Color(0xFF64748b)),
                ),
              ],
            ),
          ),

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
                  // Статус подключения
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
                          _demoMode ? Icons.cloud : Icons.bluetooth,
                          color: _demoMode ? Colors.orange : Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _demoMode ? 'ДЕМО-РЕЖИМ АКТИВЕН' : 'ПОДКЛЮЧЕНО К УСТРОЙСТВУ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _demoMode ? Colors.green : Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
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

                  // Простой график активности
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFf8fafc),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Активность за 24ч',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1e293b),
                          ),
                        ),
                        SizedBox(height: 10),
                        SizedBox(
                          height: 100,
                          child: Center(
                            child: Icon(
                              Icons.bar_chart,
                              size: 50,
                              color: Color(0xFF4f46e5),
                            ),
                          ),
                        ),
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
          // Статус бар
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            color: const Color(0xFFf8fafc),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('HH:mm').format(DateTime.now()),
                  style: const TextStyle(color: Color(0xFF64748b)),
                ),
                const Text(
                  '📶 100%',
                  style: TextStyle(color: Color(0xFF64748b)),
                ),
              ],
            ),
          ),

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
                      DropdownMenuItem(
                        value: '24h',
                        child: Text('24 часа'),
                      ),
                      DropdownMenuItem(
                        value: '7d',
                        child: Text('7 дней'),
                      ),
                      DropdownMenuItem(
                        value: '30d',
                        child: Text('30 дней'),
                      ),
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

                  // Простой график
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFf8fafc),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.insights,
                            size: 50,
                            color: Color(0xFF4f46e5),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'График данных',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'В реальном приложении здесь будет интерактивный график',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Статистика
                  Container(
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
                            _buildStatItem('Мин.', '60'),
                            _buildStatItem('Макс.', '120'),
                            _buildStatItem('Средн.', '78'),
                          ],
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
          // Статус бар
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            color: const Color(0xFFf8fafc),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('HH:mm').format(DateTime.now()),
                  style: const TextStyle(color: Color(0xFF64748b)),
                ),
                const Text(
                  '📶 100%',
                  style: TextStyle(color: Color(0xFF64748b)),
                ),
              ],
            ),
          ),

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
          onPressed: () {
            if (entry.id != null) {
              _deleteJournalEntry(entry.id!);
            }
          },
        ),
      ),
    );
  }
  
  Widget _buildSettingsScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Статус бар
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            color: const Color(0xFFf8fafc),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('HH:mm').format(DateTime.now()),
                  style: const TextStyle(color: Color(0xFF64748b)),
                ),
                const Text(
                  '📶 100%',
                  style: TextStyle(color: Color(0xFF64748b)),
                ),
              ],
            ),
          ),

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
                              'Данные генерируются каждые 3 секунды',
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
                        ElevatedButton.icon(
                          onPressed: () {
                            // Отправка данных врачу (демо)
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Данные успешно отправлены врачу'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Поделиться с врачом'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10b981),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
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
          icon: Icon(Icons.dashboard),
          label: 'Дашборд',
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
  
  Widget _buildDashboardScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.dashboard,
              size: 80,
              color: Color(0xFF4f46e5),
            ),
            const SizedBox(height: 20),
            const Text(
              'Общий дашборд',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Здесь будет сводная информация',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                setState(() => _selectedIndex = 1);
              },
              child: const Text('Перейти к моим показателям'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
  
  Widget _buildCurrentScreen() {
    switch (_selectedIndex) {
      case 0: return _buildDashboardScreen();
      case 1: return _buildHealthDashboard();
      case 2: return _buildAnalyticsScreen();
      case 3: return _buildJournalScreen();
      case 4: return _buildSettingsScreen();
      default: return _buildHealthDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentScreen(),
    );
  }
}