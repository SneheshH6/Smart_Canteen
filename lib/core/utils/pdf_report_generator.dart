import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'pdf_downloader.dart';

export '../../models/monthly_revenue_report_data.dart';
import '../../models/monthly_revenue_report_data.dart';


/// Pure Dart Valid PDF 1.4 Document Generator & Exporter
class PdfReportGenerator {
  /// Generates the PDF binary bytes and triggers download
  static Future<void> generateAndDownloadReport(MonthlyRevenueReportData report) async {
    final pdfBytes = buildReportPdf(report);
    final filename = 'Smart_Canteen_Revenue_Report_${report.monthName}_${report.year}.pdf';
    PdfDownloader.download(pdfBytes, filename);
  }

  /// Builds a standard PDF 1.4 binary
  static Uint8List buildReportPdf(MonthlyRevenueReportData data) {
    final doc = _PdfBuilder();

    // ---- PAGE 1: Executive Summary, Key Metrics, Payment Breakdown, Top Dishes ----
    doc.addPage();
    _renderPageHeader(doc, data, pageNumber: 1, totalPages: 2);
    _renderKpiCards(doc, data);
    _renderPaymentBreakdown(doc, data);
    _renderTopDishes(doc, data);
    _renderPageFooter(doc, pageNumber: 1, totalPages: 2);

    // ---- PAGE 2: Detailed Order Audit Transactions Log ----
    doc.addPage();
    _renderPageHeader(doc, data, pageNumber: 2, totalPages: 2);
    _renderOrderTransactionsLog(doc, data);
    _renderPageFooter(doc, pageNumber: 2, totalPages: 2);

    return doc.build();
  }

  static void _renderPageHeader(
    _PdfBuilder doc,
    MonthlyRevenueReportData data, {
    required int pageNumber,
    required int totalPages,
  }) {
    // Header Banner Background (Deep Indigo #1E1B4B)
    doc.fillRect(36, 755, 523, 56, r: 0.12, g: 0.11, b: 0.29);

    // Accent line (Emerald Green #10B981)
    doc.fillRect(36, 751, 523, 4, r: 0.06, g: 0.72, b: 0.51);

    // Header Text
    doc.drawText('SMART CANTEEN MANAGEMENT SYSTEM', 50, 788,
        font: _PdfFont.helveticaBold, size: 14, r: 1.0, g: 1.0, b: 1.0);
    doc.drawText('Official Campus Food & Beverage Financial Audit', 50, 774,
        font: _PdfFont.helvetica, size: 9, r: 0.78, g: 0.82, b: 0.99);

    // Report Period Tag (Right aligned)
    final periodText = 'PERIOD: ${data.monthName.toUpperCase()} ${data.year}';
    doc.drawText(periodText, 390, 788,
        font: _PdfFont.helveticaBold, size: 10, r: 0.38, g: 0.87, b: 0.65);

    final genDate = DateFormat('dd MMM yyyy, hh:mm a').format(data.generatedAt);
    doc.drawText('Generated: $genDate', 390, 774,
        font: _PdfFont.helvetica, size: 8, r: 0.8, g: 0.85, b: 0.95);
  }

  static void _renderKpiCards(_PdfBuilder doc, MonthlyRevenueReportData data) {
    // Section Title
    doc.drawText('MONTHLY FINANCIAL & ORDER SUMMARY', 36, 730,
        font: _PdfFont.helveticaBold, size: 11, r: 0.09, g: 0.12, b: 0.20);

    const double startY = 650;
    const double cardH = 68;
    const double cardW = 122;
    const double gap = 11;

    // Card 1: Total Revenue (Emerald Accent)
    _drawKpiCard(
      doc,
      x: 36,
      y: startY,
      w: cardW,
      h: cardH,
      title: 'TOTAL REVENUE',
      value: 'Rs. ${data.totalRevenue.toStringAsFixed(0)}',
      subtitle: 'Paid & Completed',
      bgR: 0.93, bgG: 0.99, bgB: 0.96,
      borderR: 0.06, borderG: 0.72, borderB: 0.51,
      valR: 0.02, valG: 0.45, valB: 0.31,
    );

    // Card 2: Total Orders
    _drawKpiCard(
      doc,
      x: 36 + (cardW + gap),
      y: startY,
      w: cardW,
      h: cardH,
      title: 'TOTAL ORDERS',
      value: '${data.totalOrders}',
      subtitle: 'Processed Tokens',
      bgR: 0.95, bgG: 0.97, bgB: 1.0,
      borderR: 0.39, borderG: 0.40, borderB: 0.95,
      valR: 0.15, valG: 0.20, valB: 0.65,
    );

    // Card 3: Completed Orders
    _drawKpiCard(
      doc,
      x: 36 + (cardW + gap) * 2,
      y: startY,
      w: cardW,
      h: cardH,
      title: 'COMPLETED',
      value: '${data.completedOrders}',
      subtitle: '${data.completionRate.toStringAsFixed(1)}% Success Rate',
      bgR: 0.92, bgG: 0.98, bgB: 0.99,
      borderR: 0.01, borderG: 0.52, borderB: 0.78,
      valR: 0.05, valG: 0.35, valB: 0.55,
    );

    // Card 4: Cancelled / Active
    _drawKpiCard(
      doc,
      x: 36 + (cardW + gap) * 3,
      y: startY,
      w: cardW,
      h: cardH,
      title: 'CANCELLED',
      value: '${data.cancelledOrders}',
      subtitle: '${data.pendingOrders + data.preparingOrders + data.readyOrders} Active in Kitchen',
      bgR: 1.0, bgG: 0.95, bgB: 0.95,
      borderR: 0.94, borderG: 0.27, borderB: 0.27,
      valR: 0.75, valG: 0.10, valB: 0.10,
    );
  }

  static void _drawKpiCard(
    _PdfBuilder doc, {
    required double x,
    required double y,
    required double w,
    required double h,
    required String title,
    required String value,
    required String subtitle,
    required double bgR, required double bgG, required double bgB,
    required double borderR, required double borderG, required double borderB,
    required double valR, required double valG, required double valB,
  }) {
    // Fill Card
    doc.fillRect(x, y, w, h, r: bgR, g: bgG, b: bgB);
    // Border Card
    doc.drawRect(x, y, w, h, r: borderR, g: borderG, b: borderB, lineWidth: 0.8);
    // Left decorative strip
    doc.fillRect(x, y, 4, h, r: borderR, g: borderG, b: borderB);

    // Text Content
    doc.drawText(title, x + 10, y + h - 16,
        font: _PdfFont.helveticaBold, size: 7.5, r: 0.35, g: 0.40, b: 0.50);
    doc.drawText(value, x + 10, y + h - 36,
        font: _PdfFont.helveticaBold, size: 14, r: valR, g: valG, b: valB);
    doc.drawText(subtitle, x + 10, y + h - 52,
        font: _PdfFont.helvetica, size: 7, r: 0.40, g: 0.45, b: 0.55);
  }

  static void _renderPaymentBreakdown(_PdfBuilder doc, MonthlyRevenueReportData data) {
    const double tableW = 523;

    // Section Header
    doc.drawText('PAYMENT METHODS BREAKDOWN & COLLECTION AUDIT', 36, 630,
        font: _PdfFont.helveticaBold, size: 10, r: 0.09, g: 0.12, b: 0.20);

    // Table Header Row
    doc.fillRect(36, 608, tableW, 18, r: 0.94, g: 0.96, b: 0.98);
    doc.drawRect(36, 608, tableW, 18, r: 0.80, g: 0.85, b: 0.90, lineWidth: 0.6);

    doc.drawText('PAYMENT METHOD / CHANNEL', 46, 613,
        font: _PdfFont.helveticaBold, size: 8, r: 0.20, g: 0.25, b: 0.35);
    doc.drawText('TXN COUNT', 250, 613,
        font: _PdfFont.helveticaBold, size: 8, r: 0.20, g: 0.25, b: 0.35);
    doc.drawText('AMOUNT COLLECTED (INR)', 360, 613,
        font: _PdfFont.helveticaBold, size: 8, r: 0.20, g: 0.25, b: 0.35);
    doc.drawText('REVENUE SHARE', 480, 613,
        font: _PdfFont.helveticaBold, size: 8, r: 0.20, g: 0.25, b: 0.35);

    double currentY = 588;
    for (int i = 0; i < data.paymentStats.length; i++) {
      final stat = data.paymentStats[i];
      final isEven = i % 2 == 0;
      if (isEven) {
        doc.fillRect(36, currentY, tableW, 18, r: 0.98, g: 0.99, b: 1.0);
      }
      doc.drawRect(36, currentY, tableW, 18, r: 0.88, g: 0.90, b: 0.94, lineWidth: 0.4);

      doc.drawText(stat.method, 46, currentY + 5,
          font: _PdfFont.helveticaBold, size: 8.5, r: 0.15, g: 0.20, b: 0.30);
      doc.drawText('${stat.count} orders', 250, currentY + 5,
          font: _PdfFont.helvetica, size: 8.5, r: 0.30, g: 0.35, b: 0.45);
      doc.drawText('Rs. ${stat.totalAmount.toStringAsFixed(2)}', 360, currentY + 5,
          font: _PdfFont.helveticaBold, size: 8.5, r: 0.05, g: 0.45, b: 0.30);
      doc.drawText('${stat.percentage.toStringAsFixed(1)}%', 480, currentY + 5,
          font: _PdfFont.helveticaBold, size: 8.5, r: 0.10, g: 0.20, b: 0.60);

      currentY -= 20;
    }

    // Total Row
    doc.fillRect(36, currentY, tableW, 20, r: 0.90, g: 0.95, b: 0.93);
    doc.drawRect(36, currentY, tableW, 20, r: 0.06, g: 0.72, b: 0.51, lineWidth: 0.8);

    doc.drawText('TOTAL VERIFIED COLLECTIONS', 46, currentY + 6,
        font: _PdfFont.helveticaBold, size: 9, r: 0.05, g: 0.35, b: 0.25);
    doc.drawText('${data.completedOrders + data.pendingOrders + data.preparingOrders + data.readyOrders} paid txns', 250, currentY + 6,
        font: _PdfFont.helveticaBold, size: 8.5, r: 0.05, g: 0.35, b: 0.25);
    doc.drawText('Rs. ${data.totalRevenue.toStringAsFixed(2)}', 360, currentY + 6,
        font: _PdfFont.helveticaBold, size: 9, r: 0.02, g: 0.45, b: 0.25);
    doc.drawText('100.0%', 480, currentY + 6,
        font: _PdfFont.helveticaBold, size: 9, r: 0.02, g: 0.45, b: 0.25);
  }

  static void _renderTopDishes(_PdfBuilder doc, MonthlyRevenueReportData data) {
    const double startY = 445;
    const double tableW = 523;

    doc.drawText('TOP SELLING FOOD & BEVERAGES', 36, startY,
        font: _PdfFont.helveticaBold, size: 10, r: 0.09, g: 0.12, b: 0.20);

    // Table Header
    doc.fillRect(36, startY - 22, tableW, 18, r: 0.94, g: 0.96, b: 0.98);
    doc.drawRect(36, startY - 22, tableW, 18, r: 0.80, g: 0.85, b: 0.90, lineWidth: 0.6);

    doc.drawText('RANK / ITEM NAME', 46, startY - 17,
        font: _PdfFont.helveticaBold, size: 8, r: 0.20, g: 0.25, b: 0.35);
    doc.drawText('PORTIONS SOLD', 270, startY - 17,
        font: _PdfFont.helveticaBold, size: 8, r: 0.20, g: 0.25, b: 0.35);
    doc.drawText('TOTAL ITEM REVENUE', 400, startY - 17,
        font: _PdfFont.helveticaBold, size: 8, r: 0.20, g: 0.25, b: 0.35);

    double curY = startY - 42;
    final topList = data.topFoods.take(8).toList();

    if (topList.isEmpty) {
      doc.drawText('No sales records recorded for this selected month period.', 46, curY + 4,
          font: _PdfFont.helveticaOblique, size: 8.5, r: 0.5, g: 0.5, b: 0.5);
    } else {
      for (int i = 0; i < topList.length; i++) {
        final item = topList[i];
        final rank = i + 1;
        if (i % 2 == 0) {
          doc.fillRect(36, curY, tableW, 17, r: 0.98, g: 0.99, b: 1.0);
        }
        doc.drawRect(36, curY, tableW, 17, r: 0.88, g: 0.90, b: 0.94, lineWidth: 0.4);

        doc.drawText('#$rank  ${item.name}', 46, curY + 5,
            font: _PdfFont.helveticaBold, size: 8.5, r: 0.15, g: 0.20, b: 0.30);
        doc.drawText('${item.quantity} units', 270, curY + 5,
            font: _PdfFont.helvetica, size: 8.5, r: 0.30, g: 0.35, b: 0.45);
        doc.drawText('Rs. ${item.revenue.toStringAsFixed(2)}', 400, curY + 5,
            font: _PdfFont.helveticaBold, size: 8.5, r: 0.05, g: 0.45, b: 0.30);

        curY -= 19;
      }
    }

    // Official Verification Note at bottom of Page 1
    doc.fillRect(36, 85, tableW, 44, r: 0.97, g: 0.98, b: 1.0);
    doc.drawRect(36, 85, tableW, 44, r: 0.75, g: 0.82, b: 0.95, lineWidth: 0.6);
    doc.drawText('AUDIT CERTIFICATION STATEMENT:', 46, 114,
        font: _PdfFont.helveticaBold, size: 8, r: 0.15, g: 0.25, b: 0.55);
    doc.drawText(
        'This financial report represents actual verified transactions processed through the Smart Canteen Cloud Ledger.',
        46,
        102,
        font: _PdfFont.helvetica,
        size: 7.5,
        r: 0.30,
        g: 0.35,
        b: 0.45);
    doc.drawText(
        'Calculated strictly excluding cancelled/refunded tokens. Authorized for Canteen Administrative Records.',
        46,
        91,
        font: _PdfFont.helvetica,
        size: 7.5,
        r: 0.30,
        g: 0.35,
        b: 0.45);
  }

  static void _renderOrderTransactionsLog(_PdfBuilder doc, MonthlyRevenueReportData data) {
    const double startY = 730;
    const double tableW = 523;

    doc.drawText('DETAILED MONTHLY ORDERS AUDIT LOG', 36, startY,
        font: _PdfFont.helveticaBold, size: 11, r: 0.09, g: 0.12, b: 0.20);

    // Table Header
    doc.fillRect(36, startY - 22, tableW, 18, r: 0.94, g: 0.96, b: 0.98);
    doc.drawRect(36, startY - 22, tableW, 18, r: 0.80, g: 0.85, b: 0.90, lineWidth: 0.6);

    doc.drawText('TOKEN #', 42, startY - 17,
        font: _PdfFont.helveticaBold, size: 8, r: 0.20, g: 0.25, b: 0.35);
    doc.drawText('DATE / TIME', 95, startY - 17,
        font: _PdfFont.helveticaBold, size: 8, r: 0.20, g: 0.25, b: 0.35);
    doc.drawText('STUDENT / USER', 190, startY - 17,
        font: _PdfFont.helveticaBold, size: 8, r: 0.20, g: 0.25, b: 0.35);
    doc.drawText('ITEMS ORDERED', 290, startY - 17,
        font: _PdfFont.helveticaBold, size: 8, r: 0.20, g: 0.25, b: 0.35);
    doc.drawText('PAYMENT', 430, startY - 17,
        font: _PdfFont.helveticaBold, size: 8, r: 0.20, g: 0.25, b: 0.35);
    doc.drawText('AMOUNT (INR)', 490, startY - 17,
        font: _PdfFont.helveticaBold, size: 8, r: 0.20, g: 0.25, b: 0.35);

    double curY = startY - 40;
    final orderList = data.orders.take(28).toList();

    if (orderList.isEmpty) {
      doc.drawText('No order records found for this period.', 46, curY + 4,
          font: _PdfFont.helveticaOblique, size: 9, r: 0.5, g: 0.5, b: 0.5);
    } else {
      for (int i = 0; i < orderList.length; i++) {
        final order = orderList[i];
        final isEven = i % 2 == 0;
        if (isEven) {
          doc.fillRect(36, curY, tableW, 18, r: 0.98, g: 0.99, b: 1.0);
        }
        doc.drawRect(36, curY, tableW, 18, r: 0.90, g: 0.92, b: 0.95, lineWidth: 0.4);

        // Format Date
        final dateStr = DateFormat('dd/MM HH:mm').format(order.createdAt);
        // Clean items summary (max 22 chars)
        String itemsStr = order.foodItemsSummary;
        if (itemsStr.length > 24) {
          itemsStr = '${itemsStr.substring(0, 22)}...';
        }
        // Clean student name (max 16 chars)
        String studentStr = order.studentName;
        if (studentStr.length > 16) {
          studentStr = '${studentStr.substring(0, 15)}...';
        }

        // Color by status
        double r = 0.15, g = 0.20, b = 0.30;
        if (order.isCompleted) {
          r = 0.05; g = 0.45; b = 0.30;
        } else if (order.isCancelled) {
          r = 0.75; g = 0.15; b = 0.15;
        }

        doc.drawText(order.tokenNumber, 42, curY + 5,
            font: _PdfFont.helveticaBold, size: 8, r: r, g: g, b: b);
        doc.drawText(dateStr, 95, curY + 5,
            font: _PdfFont.helvetica, size: 7.5, r: 0.35, g: 0.40, b: 0.45);
        doc.drawText(studentStr, 190, curY + 5,
            font: _PdfFont.helvetica, size: 7.5, r: 0.20, g: 0.25, b: 0.35);
        doc.drawText(itemsStr, 290, curY + 5,
            font: _PdfFont.helvetica, size: 7.5, r: 0.25, g: 0.30, b: 0.40);
        doc.drawText(order.paymentMethod, 430, curY + 5,
            font: _PdfFont.helvetica, size: 7.5, r: 0.30, g: 0.35, b: 0.45);
        doc.drawText('Rs. ${order.totalAmount.toStringAsFixed(0)}', 495, curY + 5,
            font: _PdfFont.helveticaBold, size: 8, r: r, g: g, b: b);

        curY -= 20;
      }
    }
  }

  static void _renderPageFooter(_PdfBuilder doc, {required int pageNumber, required int totalPages}) {
    // Footer line
    doc.fillRect(36, 50, 523, 1, r: 0.85, g: 0.88, b: 0.92);

    doc.drawText('Smart Canteen Automation Platform - Confidential Audit Document', 36, 38,
        font: _PdfFont.helvetica, size: 7.5, r: 0.5, g: 0.55, b: 0.65);
    doc.drawText('Page $pageNumber of $totalPages', 500, 38,
        font: _PdfFont.helveticaBold, size: 7.5, r: 0.4, g: 0.45, b: 0.55);
  }
}

enum _PdfFont {
  helvetica,
  helveticaBold,
  helveticaOblique,
}

/// Pure Dart Stream Builder for PDF 1.4 Documents
class _PdfBuilder {
  final List<String> _pageContents = [];
  int _currentPageIndex = -1;

  void addPage() {
    _pageContents.add('');
    _currentPageIndex = _pageContents.length - 1;
  }

  void _append(String command) {
    if (_currentPageIndex >= 0 && _currentPageIndex < _pageContents.length) {
      _pageContents[_currentPageIndex] += '$command\n';
    }
  }

  void fillRect(double x, double y, double width, double height,
      {required double r, required double g, required double b}) {
    final cleanX = x.toStringAsFixed(2);
    final cleanY = y.toStringAsFixed(2);
    final cleanW = width.toStringAsFixed(2);
    final cleanH = height.toStringAsFixed(2);
    final cleanR = r.toStringAsFixed(3);
    final cleanG = g.toStringAsFixed(3);
    final cleanB = b.toStringAsFixed(3);
    _append('q $cleanR $cleanG $cleanB rg $cleanX $cleanY $cleanW $cleanH re f Q');
  }

  void drawRect(double x, double y, double width, double height,
      {required double r, required double g, required double b, double lineWidth = 1.0}) {
    final cleanX = x.toStringAsFixed(2);
    final cleanY = y.toStringAsFixed(2);
    final cleanW = width.toStringAsFixed(2);
    final cleanH = height.toStringAsFixed(2);
    final cleanR = r.toStringAsFixed(3);
    final cleanG = g.toStringAsFixed(3);
    final cleanB = b.toStringAsFixed(3);
    final cleanLw = lineWidth.toStringAsFixed(2);
    _append('q $cleanLw w $cleanR $cleanG $cleanB RG $cleanX $cleanY $cleanW $cleanH re S Q');
  }

  void drawText(String text, double x, double y,
      {_PdfFont font = _PdfFont.helvetica,
      double size = 10,
      required double r,
      required double g,
      required double b}) {
    final fontName = font == _PdfFont.helveticaBold
        ? '/F2'
        : (font == _PdfFont.helveticaOblique ? '/F3' : '/F1');

    // Escape parenthesis and backslashes for PDF string literals
    final sanitizedText = text
        .replaceAll('\\', '\\\\')
        .replaceAll('(', '\\(')
        .replaceAll(')', '\\)')
        .replaceAll('₹', 'Rs. ');

    final cleanX = x.toStringAsFixed(2);
    final cleanY = y.toStringAsFixed(2);
    final cleanSize = size.toStringAsFixed(2);
    final cleanR = r.toStringAsFixed(3);
    final cleanG = g.toStringAsFixed(3);
    final cleanB = b.toStringAsFixed(3);

    _append('BT $fontName $cleanSize Tf $cleanR $cleanG $cleanB rg 1 0 0 1 $cleanX $cleanY Tm ($sanitizedText) Tj ET');
  }

  Uint8List build() {
    final StringBuffer buffer = StringBuffer();
    final List<int> byteOffsets = [];

    void write(String str) {
      buffer.write(str);
    }

    // Header
    write('%PDF-1.4\n%\xE2\xE3\xCF\xD3\n');

    final int pageCount = _pageContents.length;
    // Objects mapping:
    // 1: Catalog
    // 2: Pages
    // 3..(2+pageCount): Page objects
    // (3+pageCount)..(2+2*pageCount): Content streams
    // Font objects: F1 (Helvetica), F2 (Helvetica-Bold), F3 (Helvetica-Oblique)
    final int firstPageObj = 3;
    final int firstContentObj = firstPageObj + pageCount;
    final int f1Obj = firstContentObj + pageCount;
    final int f2Obj = f1Obj + 1;
    final int f3Obj = f2Obj + 1;
    final int totalObjs = f3Obj;

    // Helper to record offset
    void startObj(int objNum) {
      byteOffsets.add(utf8.encode(buffer.toString()).length);
      write('$objNum 0 obj\n');
    }

    // 1. Catalog
    startObj(1);
    write('<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');

    // 2. Pages
    startObj(2);
    final kidsStr = List.generate(pageCount, (i) => '${firstPageObj + i} 0 R').join(' ');
    write('<< /Type /Pages /Kids [$kidsStr] /Count $pageCount >>\nendobj\n');

    // Page Objects (3 .. 2+pageCount)
    for (int i = 0; i < pageCount; i++) {
      final pageObjNum = firstPageObj + i;
      final contentObjNum = firstContentObj + i;
      startObj(pageObjNum);
      write('<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595.28 841.89] /Contents $contentObjNum 0 R /Resources << /Font << /F1 $f1Obj 0 R /F2 $f2Obj 0 R /F3 $f3Obj 0 R >> >> >>\nendobj\n');
    }

    // Content Stream Objects
    for (int i = 0; i < pageCount; i++) {
      final contentObjNum = firstContentObj + i;
      final contentStream = _pageContents[i];
      final contentBytes = utf8.encode(contentStream);
      startObj(contentObjNum);
      write('<< /Length ${contentBytes.length} >>\nstream\n$contentStream\nendstream\nendobj\n');
    }

    // Font 1: Helvetica
    startObj(f1Obj);
    write('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>\nendobj\n');

    // Font 2: Helvetica-Bold
    startObj(f2Obj);
    write('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>\nendobj\n');

    // Font 3: Helvetica-Oblique
    startObj(f3Obj);
    write('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Oblique /Encoding /WinAnsiEncoding >>\nendobj\n');

    // XRef Table
    final int xrefOffset = utf8.encode(buffer.toString()).length;
    write('xref\n0 ${totalObjs + 1}\n0000000000 65535 f \n');
    for (final offset in byteOffsets) {
      final offsetStr = offset.toString().padLeft(10, '0');
      write('$offsetStr 00000 n \n');
    }

    // Trailer
    write('trailer\n<< /Size ${totalObjs + 1} /Root 1 0 R >>\nstartxref\n$xrefOffset\n%%EOF\n');

    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }
}
