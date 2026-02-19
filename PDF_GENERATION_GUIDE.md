# Financial PDF Report Generator

Complete PDF generation system for educational institution financial documents matching your UEMS design system.

## Overview

This PDF generation system provides four main financial reports:

1. **Income Statement** - Revenue vs Expenses analysis
2. **Balance Sheet** - Assets, Liabilities & Equity
3. **Cash Flow Statement** - Operating, Investing & Financing activities
4. **Tax Compliance** - BIR Form 1601-C and Audit Reports

## Design System Integration

All PDFs use your app's color scheme:
- **Primary Dark**: `#1E1033` - Main background
- **Accent Violet**: `#8B5CF6` - Headers and highlights
- **Success Green**: `#69F0AE` - Positive values
- **Error Red**: `#FF5555` - Negative values
- **Orange**: `#FFA300` - Warnings

## File Structure

```
lib/
├── services/
│   ├── financial_report_service.dart          # Base utilities & colors
│   ├── income_statement_pdf_service.dart      # Income statement generation
│   ├── balance_sheet_pdf_service.dart         # Balance sheet generation
│   ├── cash_flow_pdf_service.dart             # Cash flow generation
│   ├── tax_compliance_pdf_service.dart        # BIR & Audit reports
│   └── financial_pdf_manager.dart             # PDF file management
└── views/
    └── financial_report_generator_view.dart   # UI example
```

## Services

### 1. Financial Report Service
Base service with shared utilities for all PDF documents.

**Key Features:**
- Unified color scheme
- Table formatting helpers
- Currency and percentage formatting
- Standard headers and footers

### 2. Income Statement PDF Service

Generate income statements showing revenue vs expenses.

**Usage:**
```dart
import 'package:uems_project/services/income_statement_pdf_service.dart';

final incomeItems = [
  IncomeLineItem(
    name: 'Tuition Fees',
    amount: 1250000,
    percentage: 55.5,
  ),
];

final expenseItems = [
  ExpenseLineItem(
    name: 'Salaries',
    amount: 800000,
    percentage: 44.5,
  ),
];

final pdf = await IncomeStatementPdfService.generateIncomeStatement(
  schoolName: 'Your School Name',
  date: '2024-02-19',
  incomeItems: incomeItems,
  expenseItems: expenseItems,
);
```

### 3. Balance Sheet PDF Service

Generate balance sheets with assets, liabilities, and equity sections.

**Usage:**
```dart
import 'package:uems_project/services/balance_sheet_pdf_service.dart';

final data = BalanceSheetData(
  currentAssets: {
    'Cash at Bank': 500000,
    'Accounts Receivable': 250000,
  },
  fixedAssets: {
    'Buildings': 5000000,
    'Equipment': 1000000,
  },
  otherAssets: {
    'Goodwill': 300000,
  },
  currentLiabilities: {
    'Accounts Payable': 200000,
  },
  longTermLiabilities: {
    'Long-term Loans': 2000000,
  },
  equity: {
    'Capital': 3000000,
    'Retained Earnings': 500000,
  },
);

final pdf = await BalanceSheetPdfService.generateBalanceSheet(
  schoolName: 'Your School Name',
  date: '2024-02-19',
  data: data,
);
```

### 4. Cash Flow PDF Service

Generate cash flow statements with operating, investing, and financing activities.

**Usage:**
```dart
import 'package:uems_project/services/cash_flow_pdf_service.dart';

final data = CashFlowData(
  operatingActivities: {
    'Cash from Students': 1500000,
    'Government Grants': 250000,
    'Salary Payments': -800000,
  },
  investingActivities: {
    'Equipment Purchase': -100000,
    'Asset Sales': 50000,
  },
  financingActivities: {
    'Loan Received': 500000,
    'Loan Repayment': -100000,
  },
  beginningCashBalance: 1000000,
  endingCashBalance: 2300000,
);

final pdf = await CashFlowPdfService.generateCashFlowStatement(
  schoolName: 'Your School Name',
  date: '2024-02-19',
  data: data,
);
```

### 5. Tax Compliance PDF Service

Generate BIR Form 1601-C and audit reports.

**BIR Form 1601-C Usage:**
```dart
import 'package:uems_project/services/tax_compliance_pdf_service.dart';

final taxData = TaxWithholdingData(
  totalCompensation: 2500000,
  nonTaxableCompensation: 250000,
  taxWithheld: 225000,
  totalPaymentsMade: 200000,
  penalties: 5000,
);

final pdf = await TaxCompliancePdfService.generateBIR1601CForm(
  schoolName: 'Your School Name',
  tinNumber: '123-456-789-012',
  forTheMonth: 2,
  forTheYear: 2026,
  data: taxData,
);
```

**Audit Report Usage:**
```dart
final findings = AuditFindingsData(
  complianceItems: {
    'Financial Records': true,
    'Audit Trail': true,
    'Internal Controls': false,
  },
  majorFindings: [
    'Finding 1: Description',
    'Finding 2: Description',
  ],
  recommendations: [
    'Recommendation 1',
    'Recommendation 2',
  ],
);

final pdf = await TaxCompliancePdfService.generateAuditReport(
  schoolName: 'Your School Name',
  auditPeriod: 'January 1 - December 31, 2024',
  auditedBy: 'Certified Auditor',
  auditDate: '2024-02-19',
  findings: findings,
);
```

### 6. Financial PDF Manager

Utilities for saving, opening, and managing PDF files.

**Usage:**
```dart
import 'package:uems_project/services/financial_pdf_manager.dart';

// Generate filename with timestamp
final fileName = FinancialPdfManager.generateFileName(
  documentType: 'Income_Statement',
  schoolName: 'Demo_School',
  includeTimestamp: true,
);

// Save PDF
final filePath = await FinancialPdfManager.savePDF(
  pdf: pdf,
  fileName: fileName,
);

// Open PDF
await FinancialPdfManager.openPDF(filePath);

// Save and open in one action
await FinancialPdfManager.savePDFAndOpen(
  pdf: pdf,
  fileName: fileName,
);

// Export batch of all reports
final filePaths = await FinancialPdfManager.exportFinancialReportBatch(
  schoolName: 'Your School',
  reportDate: '2024-02-19',
  incomeStatement: incomeStatementPdf,
  balanceSheet: balanceSheetPdf,
  cashFlow: cashFlowPdf,
  taxCompliance: taxCompliancePdf,
);

// List saved reports
final reports = await FinancialPdfManager.listSavedReports();

// Get file size
final sizeMB = await FinancialPdfManager.getFileSize(filePath);

// Delete report
await FinancialPdfManager.deleteReport(filePath);
```

## Integration with Flutter Widgets

The package includes a ready-to-use view component:

```dart
import 'package:uems_project/views/financial_report_generator_view.dart';

// Use in your app
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const FinancialReportGeneratorView(),
  ),
);
```

## Data Format Requirements

### Currency
- Values should be in smallest unit (PHP/pesos)
- Automatically formatted with ₱ symbol and comma separators
- Example: `1250000` displays as `₱1,250,000.00`

### Percentages
- Decimal format (0-100)
- Automatically formatted with % symbol
- Example: `53.29` displays as `53.29%`

### Dates
- String format: `'YYYY-MM-DD'`
- Example: `DateTime.now().toString().split(' ')[0]`

## Color Codes Used in PDFs

```dart
// Revenue/Income (Green)
Color.fromARGB(255, 105, 240, 174) // #69F0AE

// Expenses (Red)
Color.fromARGB(255, 255, 85, 85) // #FF5555

// Headers (Violet)
Color.fromARGB(255, 139, 92, 246) // #8B5CF6

// Warnings (Orange)
Color.fromARGB(255, 255, 163, 0) // #FFA300
```

## Dependencies

These services use the following packages already in your pubspec.yaml:
- `pdf: ^3.10.1` - PDF generation
- `path_provider: ^2.0.15` - File system access
- `open_file: ^3.2.1` - File opening

## Features

✅ Professional PDF formatting matching your app design  
✅ Comprehensive financial documents (4 types)  
✅ Multiple section support (Assets, Liabilities, etc.)  
✅ Color-coded positive/negative values  
✅ Currency formatting with proper symbols  
✅ Batch export functionality  
✅ File management utilities  
✅ Automatic timestamp generation  
✅ BIR Tax Form 1601-C support  
✅ Audit report generation  

## File Locations

Generated PDFs are saved to:
- **Android/iOS**: App Documents Directory + `/FinancialReports/`
- **Windows/macOS**: Application Documents Directory + `/FinancialReports/`

## Error Handling

All services include try-catch blocks. Errors are printed to console and can be logged:

```dart
try {
  final pdf = await IncomeStatementPdfService.generateIncomeStatement(...);
} catch (e) {
  print('PDF Generation Error: $e');
  // Handle error appropriately
}
```

## Performance Considerations

- PDFs are generated in-memory before saving
- Large datasets may increase generation time
- Consider pagination for very large reports
- File sizes typically range from 50KB to 500KB

## Future Enhancements

- Multi-language support
- Custom logo/branding integration
- Email delivery integration
- Digital signature support
- Database integration for automatic data pulling
- Real-time data synchronization
- Export to Excel/CSV formats

## Support

For issues or questions, refer to the example implementation in:
`lib/views/financial_report_generator_view.dart`

All sample data is provided for testing and demo purposes.
