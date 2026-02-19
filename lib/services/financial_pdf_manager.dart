import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class FinancialPdfManager {
  /// Save PDF to file system and return the file path
  static Future<String> savePDF({
    required pw.Document pdf,
    required String fileName,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      
      // Create Reports directory if it doesn't exist
      final reportsDir = Directory('${directory.path}/FinancialReports');
      if (!reportsDir.existsSync()) {
        reportsDir.createSync(recursive: true);
      }
      
      // Generate file path with timestamp if needed
      final filePath = '${reportsDir.path}/$fileName';
      final file = File(filePath);
      
      // Save PDF
      final bytes = await pdf.save();
      await file.writeAsBytes(bytes);
      
      debugPrint('PDF saved to: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('Error saving PDF: $e');
      rethrow;
    }
  }

  /// Open PDF file with system default application
  static Future<void> openPDF(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        debugPrint('Could not open file: ${result.message}');
      }
    } catch (e) {
      debugPrint('Error opening PDF: $e');
      rethrow;
    }
  }

  /// Save and open PDF in one action
  static Future<void> savePDFAndOpen({
    required pw.Document pdf,
    required String fileName,
  }) async {
    final filePath = await savePDF(pdf: pdf, fileName: fileName);
    await openPDF(filePath);
  }

  /// Generate formatted filename with date and time
  static String generateFileName({
    required String documentType,
    required String schoolName,
    bool includeTimestamp = true,
  }) {
    String fileName = documentType.replaceAll(' ', '_');
    fileName += '_${schoolName.replaceAll(' ', '_')}';
    
    if (includeTimestamp) {
      final now = DateTime.now();
      final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      fileName += '_$timestamp';
    }
    
    return '$fileName.pdf';
  }

  /// List all saved financial reports
  static Future<List<FileSystemEntity>> listSavedReports() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${directory.path}/FinancialReports');
      
      if (!reportsDir.existsSync()) {
        return [];
      }
      
      return reportsDir.listSync();
    } catch (e) {
      debugPrint('Error listing reports: $e');
      return [];
    }
  }

  /// Delete a saved report
  static Future<void> deleteReport(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
        debugPrint('Report deleted: $filePath');
      }
    } catch (e) {
      debugPrint('Error deleting report: $e');
      rethrow;
    }
  }

  /// Get file size in MB
  static Future<double> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.length();
      return bytes / (1024 * 1024); // Convert to MB
    } catch (e) {
      debugPrint('Error getting file size: $e');
      return 0.0;
    }
  }

  /// Export multiple PDFs as a batch (all four financial reports)
  static Future<List<String>> exportFinancialReportBatch({
    required String schoolName,
    required String reportDate,
    required pw.Document incomeStatement,
    required pw.Document balanceSheet,
    required pw.Document cashFlow,
    required pw.Document taxCompliance,
  }) async {
    final filePaths = <String>[];

    try {
      // Save all reports
      filePaths.add(
        await savePDF(
          pdf: incomeStatement,
          fileName: generateFileName(
            documentType: 'IncomeStatement',
            schoolName: schoolName,
          ),
        ),
      );

      filePaths.add(
        await savePDF(
          pdf: balanceSheet,
          fileName: generateFileName(
            documentType: 'BalanceSheet',
            schoolName: schoolName,
          ),
        ),
      );

      filePaths.add(
        await savePDF(
          pdf: cashFlow,
          fileName: generateFileName(
            documentType: 'CashFlowStatement',
            schoolName: schoolName,
          ),
        ),
      );

      filePaths.add(
        await savePDF(
          pdf: taxCompliance,
          fileName: generateFileName(
            documentType: 'TaxCompliance_BIR1601C',
            schoolName: schoolName,
          ),
        ),
      );

      return filePaths;
    } catch (e) {
      debugPrint('Error exporting batch: $e');
      rethrow;
    }
  }
}
