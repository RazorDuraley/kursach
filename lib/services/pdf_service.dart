import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import '../models/user.dart';
import '../models/health_record.dart';
import '../models/journal_entry.dart';

class PdfService {
  static Future<File> generateHealthReport({
    required User user,
    required List<HealthRecord> healthRecords,
    required List<JournalEntry> journalEntries,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Заголовок
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Отчет о состоянии здоровья',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Информация о пациенте
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blue, width: 1),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Пациент: ${user.name}',
                      style: const pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text('Возраст: ${user.age} лет'),
                    pw.Text('Email: ${user.email}'),
                    pw.Text(
                      'Период отчета: ${DateFormat('dd.MM.yyyy').format(startDate)} - ${DateFormat('dd.MM.yyyy').format(endDate)}',
                    ),
                    pw.Text(
                      'Дата формирования: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 30),
              
              // Показатели здоровья
              pw.Header(
                level: 1,
                child: pw.Text(
                  'Показатели здоровья',
                  style: const pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              ),
              
              pw.SizedBox(height: 10),
              
              _buildHealthTable(healthRecords),
              
              pw.SizedBox(height: 30),
              
              // Записи в журнале
              pw.Header(
                level: 1,
                child: pw.Text(
                  'Записи в журнале здоровья',
                  style: const pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              ),
              
              pw.SizedBox(height: 10),
              
              if (journalEntries.isNotEmpty)
                ...journalEntries.map((entry) => _buildJournalEntry(entry))
              else
                pw.Text('Записей нет', style: const pw.TextStyle(fontStyle: pw.FontStyle.italic)),
              
              pw.SizedBox(height: 50),
              
              // Подпись
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Сгенерировано приложением HealthMonitor IoT\n${user.name}\n${DateFormat('dd.MM.yyyy').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          );
        },
      ),
    );
    
    // Сохраняем файл в папку Documents
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'health_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    
    // Сохраняем PDF
    final pdfBytes = await pdf.save();
    await file.writeAsBytes(pdfBytes);
    
    return file;
  }
  
  static pw.Widget _buildHealthTable(List<HealthRecord> records) {
    final Map<String, List<HealthRecord>> groupedRecords = {};
    
    for (var record in records) {
      if (!groupedRecords.containsKey(record.type)) {
        groupedRecords[record.type] = [];
      }
      groupedRecords[record.type]!.add(record);
    }
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        // Заголовок таблицы
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue50),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Показатель', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Мин.', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Макс.', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Средн.', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Рекомендации', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        
        // Данные
        ...groupedRecords.entries.map((entry) {
          final type = entry.key;
          final values = entry.value.map((r) => r.value).toList();
          final min = values.reduce((a, b) => a < b ? a : b);
          final max = values.reduce((a, b) => a > b ? a : b);
          final avg = values.reduce((a, b) => a + b) / values.length;
          
          String recommendations = '';
          String unit = '';
          
          switch (type) {
            case 'heart_rate':
              unit = 'уд/мин';
              if (avg > 100) recommendations = 'Рекомендуется обратиться к кардиологу';
              else if (avg > 80) recommendations = 'Умеренные физические нагрузки';
              else recommendations = 'Норма';
              break;
            case 'spo2':
              unit = '%';
              if (avg < 95) recommendations = 'Требуется консультация врача';
              else if (avg < 97) recommendations = 'Дыхательные упражнения';
              else recommendations = 'Норма';
              break;
            case 'stress':
              unit = 'ед.';
              if (avg > 70) recommendations = 'Рекомендуется отдых и релаксация';
              else if (avg > 50) recommendations = 'Умеренный уровень стресса';
              else recommendations = 'Норма';
              break;
            default:
              unit = '';
          }
          
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('${_getTypeName(type)} ($unit)'),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(min.toStringAsFixed(1)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(max.toStringAsFixed(1)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(avg.toStringAsFixed(1)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(recommendations, style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          );
        }),
      ],
    );
  }
  
  static pw.Widget _buildJournalEntry(JournalEntry entry) {
    String emoji = '';
    switch (entry.type) {
      case 'symptom':
        emoji = '🤒';
        break;
      case 'medication':
        emoji = '💊';
        break;
      case 'note':
        emoji = '📝';
        break;
    }
    
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(emoji),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Text(
                  entry.title,
                  style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Text(
                DateFormat('dd.MM.yyyy HH:mm').format(entry.timestamp),
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Text(entry.description, style: const pw.TextStyle(fontSize: 12)),
          if (entry.severity != null)
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 5),
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Text(
                'Серьезность: ${entry.severity}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }
  
  static String _getTypeName(String type) {
    switch (type) {
      case 'heart_rate':
        return 'Пульс (ЧСС)';
      case 'spo2':
        return 'Кислород (SpO₂)';
      case 'stress':
        return 'Уровень стресса';
      case 'steps':
        return 'Шаги';
      case 'temperature':
        return 'Температура тела';
      default:
        return type;
    }
  }
  
  static Future<void> openFile(File file) async {
    await OpenFile.open(file.path);
  }
}