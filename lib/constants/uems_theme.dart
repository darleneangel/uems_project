import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';

/// Status color enumeration for consistent status representation
enum StatusColor { success, warning, error, pending, info }

/// Centralized theme and color constants for the UEMS application
/// Used by both Flutter UI and PDF generation services
class UEMSTheme {
  // Private constructor to prevent instantiation
  UEMSTheme._();

  // ==================== Flutter Colors ====================
  static const Color primaryDark = Color(0xFF1E1033);
  static const Color surfaceDark = Color(0xFF0F0820);
  static const Color accentViolet = Color(0xFF8B5CF6);
  static const Color successGreen = Color(0xFF69F0AE);
  static const Color warningOrange = Color(0xFFFFA300);
  static const Color errorRed = Color(0xFFFF5555);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFFF2F2F2);
  static const Color borderGrey = Color(0xFF333333);

  // ==================== PDF Colors ====================
  static const PdfColor pdfPrimaryDark = PdfColor(0.12, 0.06, 0.20); // #1E1033
  static const PdfColor pdfAccentViolet = PdfColor(0.55, 0.36, 0.96); // #8B5CF6
  static const PdfColor pdfSurfaceDark = PdfColor(0.06, 0.03, 0.13); // #0F0820
  static const PdfColor pdfSuccessGreen = PdfColor(0.41, 0.94, 0.68); // #69F0AE
  static const PdfColor pdfWarningOrange = PdfColor(1.0, 0.64, 0.0); // #FFA300
  static const PdfColor pdfErrorRed = PdfColor(1.0, 0.33, 0.33); // #FF5555
  static const PdfColor pdfTextWhite = PdfColor(1, 1, 1);
  static const PdfColor pdfTextLight = PdfColor(0.95, 0.95, 0.95);
  static const PdfColor pdfBorderGrey = PdfColor(0.2, 0.2, 0.2);

  // ==================== Material Theme ====================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primarySwatch: Colors.indigo,
      primaryColor: accentViolet,
      scaffoldBackgroundColor: surfaceDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryDark,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textLight),
        titleTextStyle: TextStyle(
          color: textWhite,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: primaryDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderGrey),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textLight),
        bodyMedium: TextStyle(color: textLight),
        titleLarge: TextStyle(
          color: textWhite,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ==================== Text Styles ====================
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textWhite,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textLight,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textLight,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Color(0xFFB0B0B0),
  );

  // ==================== Spacing Constants ====================
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 12.0;
  static const double spacingLG = 16.0;
  static const double spacingXL = 24.0;
  static const double spacingXXL = 32.0;

  // ==================== Border Radius ====================
  static const double radiusSM = 4.0;
  static const double radiusMD = 8.0;
  static const double radiusLG = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusMax = 24.0;

  // ==================== Shadow ====================
  static final BoxShadow defaultShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.3),
    blurRadius: 8,
    offset: const Offset(0, 4),
  );

  // ==================== Gradient Utilities ====================
  static LinearGradient get violetGradient {
    return LinearGradient(
      colors: [accentViolet.withValues(alpha: 0.8), primaryDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static Color getStatusColor(StatusColor status) {
    switch (status) {
      case StatusColor.success:
        return successGreen;
      case StatusColor.warning:
        return warningOrange;
      case StatusColor.error:
        return errorRed;
      case StatusColor.pending:
        return warningOrange;
      case StatusColor.info:
        return accentViolet;
    }
  }

  static PdfColor getPdfStatusColor(StatusColor status) {
    switch (status) {
      case StatusColor.success:
        return pdfSuccessGreen;
      case StatusColor.warning:
        return pdfWarningOrange;
      case StatusColor.error:
        return pdfErrorRed;
      case StatusColor.pending:
        return pdfWarningOrange;
      case StatusColor.info:
        return pdfAccentViolet;
    }
  }

  // ==================== Container Styling ====================
  static BoxDecoration get cardDecoration {
    return BoxDecoration(
      color: primaryDark,
      borderRadius: BorderRadius.circular(radiusLG),
      border: Border.all(color: borderGrey),
    );
  }

  static BoxDecoration get highlightDecoration {
    return BoxDecoration(
      color: accentViolet.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(radiusMD),
      border: Border.all(color: accentViolet.withValues(alpha: 0.3)),
    );
  }

  // ==================== Input Decoration ====================
  static InputDecoration getInputDecoration({
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    IconData? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: accentViolet) : null,
      suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: accentViolet) : null,
      filled: true,
      fillColor: primaryDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMD),
        borderSide: const BorderSide(color: borderGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMD),
        borderSide: const BorderSide(color: borderGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMD),
        borderSide: const BorderSide(color: accentViolet, width: 2),
      ),
      labelStyle: const TextStyle(color: textLight),
      hintStyle: const TextStyle(color: Color(0xFF808080)),
    );
  }

  // ==================== Button Styles ====================
  static ButtonStyle get primaryButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: accentViolet,
      foregroundColor: textWhite,
      padding: const EdgeInsets.symmetric(
        horizontal: spacingLG,
        vertical: spacingMD,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMD),
      ),
      elevation: 0,
    );
  }

  static ButtonStyle get secondaryButtonStyle {
    return OutlinedButton.styleFrom(
      foregroundColor: accentViolet,
      side: const BorderSide(color: accentViolet),
      padding: const EdgeInsets.symmetric(
        horizontal: spacingLG,
        vertical: spacingMD,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMD),
      ),
    );
  }

  // ==================== Utility Methods ====================
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  static PdfColor toPdfColor(Color color) {
    final red = color.r * 255;
    final green = color.g * 255;
    final blue = color.b * 255;
    return PdfColor(
      red / 255.0,
      green / 255.0,
      blue / 255.0,
    );
  }

  static Color fromPdfColor(PdfColor color) {
    return Color.fromARGB(
      255,
      (color.red * 255).toInt(),
      (color.green * 255).toInt(),
      (color.blue * 255).toInt(),
    );
  }
}

/// Financial Report Theme - Specific colors for financial documents
class FinancialReportTheme {
  FinancialReportTheme._();

  // Revenue colors (green tones)
  static const Color revenueLight = Color(0xFF69F0AE);
  static const Color revenueMedium = Color(0xFF52CC8A);
  static const Color revenueDark = Color(0xFF3BA366);

  // Expense colors (red tones)
  static const Color expenseLight = Color(0xFFFF5555);
  static const Color expenseMedium = Color(0xFFCC3333);
  static const Color expenseDark = Color(0xFF990000);

  // Liability colors (orange tones)
  static const Color liabilityLight = Color(0xFFFFA300);
  static const Color liabilityMedium = Color(0xFFCC8200);
  static const Color liabilityDark = Color(0xFF996100);

  // PDF equivalents
  static const PdfColor pdfRevenueLight = PdfColor(0.41, 0.94, 0.68);
  static const PdfColor pdfExpenseLight = PdfColor(1.0, 0.33, 0.33);
  static const PdfColor pdfLiabilityLight = PdfColor(1.0, 0.64, 0.0);
}
