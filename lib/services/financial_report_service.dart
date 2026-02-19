import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class FinancialReportService {
  // Color scheme matching the app's design system
  static const PdfColor primaryDark = PdfColor(0.12, 0.06, 0.20); // #1E1033
  static const PdfColor accentViolet = PdfColor(0.55, 0.36, 0.96); // #8B5CF6
  static const PdfColor successGreen = PdfColor(0.41, 0.94, 0.68); // #69F0AE
  static const PdfColor warningOrange = PdfColor(1.0, 0.64, 0.0); // #FFA300
  static const PdfColor errorRed = PdfColor(1.0, 0.33, 0.33); // #FF5555
  static const PdfColor textWhite = PdfColor(1, 1, 1);
  static const PdfColor textLight = PdfColor(0.95, 0.95, 0.95);
  static const PdfColor borderGrey = PdfColor(0.2, 0.2, 0.2);
  static const PdfColor textDark = PdfColor(0.12, 0.12, 0.14);
  static const PdfColor textMuted = PdfColor(0.45, 0.45, 0.5);
  static const PdfColor surfaceLight = PdfColor(0.98, 0.98, 0.99);
  static const PdfColor surfaceAlt = PdfColor(0.94, 0.94, 0.96);
  static const PdfColor borderLight = PdfColor(0.84, 0.84, 0.88);

  // Create header for financial documents
  static pw.Widget buildHeader(String title, String schoolName, String date) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          schoolName,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: textMuted,
            letterSpacing: 0.3,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: textDark,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'As of $date',
              style: pw.TextStyle(
                fontSize: 9,
                color: textMuted,
              ),
            ),
            pw.Container(
              width: 96,
              height: 2,
              color: accentViolet,
            ),
          ],
        ),
        pw.SizedBox(height: 14),
      ],
    );
  }

  static pw.Widget buildSubtitle(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
        color: textMuted,
      ),
    );
  }

  static pw.Widget buildSectionCard({
    required String title,
    required PdfColor accent,
    required pw.Widget child,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: surfaceLight,
        border: pw.Border.all(color: borderLight),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: surfaceAlt,
              border: pw.Border(
                bottom: pw.BorderSide(color: borderLight),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 6,
                  height: 12,
                  decoration: pw.BoxDecoration(
                    color: accent,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ],
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }

  // Create table header row
  static pw.TableRow buildTableHeaderRow(List<String> headers) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: surfaceAlt,
        border: pw.Border(
          bottom: pw.BorderSide(color: borderLight, width: 1),
        ),
      ),
      children: headers
          .map((header) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: pw.Text(
                  header,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ))
          .toList(),
    );
  }

  // Create standard table row
  static pw.TableRow buildTableRow(
    List<String> cells, {
    bool isTotal = false,
    bool isSubtotal = false,
    bool isPositive = false,
    bool isNegative = false,
  }) {
    PdfColor backgroundColor = surfaceLight;

    if (isTotal) {
      backgroundColor = surfaceAlt;
    } else if (isSubtotal) {
      backgroundColor = PdfColor(0.92, 0.92, 0.95);
    }

    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: backgroundColor,
        border: pw.Border(
          bottom: pw.BorderSide(
            color: borderLight,
            width: isTotal ? 1 : 0.5,
          ),
        ),
      ),
      children: cells
          .asMap()
          .entries
          .map((entry) {
            int index = entry.key;
            String cell = entry.value;
            bool isAmount = index > 0; // Assume first column is label

            // All text is dark/black for readability
            PdfColor textColor = textDark;

            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              child: pw.Text(
                cell,
                style: pw.TextStyle(
                  fontSize: isTotal ? 10 : 9,
                  fontWeight: isTotal || isSubtotal ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: textColor,
                ),
                textAlign: isAmount ? pw.TextAlign.right : pw.TextAlign.left,
              ),
            );
          })
          .toList(),
    );
  }

  // Create footer with page numbers and digital signature area
  static pw.Widget buildFooter(String documentType, {String? auditNotes}) {
    return pw.Column(
      children: [
        pw.Divider(color: borderLight),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Document: $documentType',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: textMuted,
                  ),
                ),
                if (auditNotes != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Notes: $auditNotes',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: textMuted,
                    ),
                  ),
                ],
              ],
            ),
            pw.Text(
              'Page __/__',
              style: pw.TextStyle(
                fontSize: 8,
                color: textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Format currency with PHP prefix
  static String formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return 'PHP $formatted';
  }

  // Format percentage
  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(2)}%';
  }
}
