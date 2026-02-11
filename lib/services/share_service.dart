import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class ShareService {
  static Future<void> shareFile(File file, {String? subject}) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: subject ?? 'HealthMonitor Report',
      text: 'Мой отчет о здоровье из приложения HealthMonitor IoT',
    );
  }
  
  static Future<File> createShareableTextFile({
    required String content,
    required String fileName,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName.txt');
    await file.writeAsString(content);
    return file;
  }
  
  static Future<void> shareHealthData(String summary) async {
    final fileName = 'health_data_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.txt';
    final file = await createShareableTextFile(
      content: summary,
      fileName: fileName,
    );
    await shareFile(file, subject: 'Мои данные здоровья');
  }
}