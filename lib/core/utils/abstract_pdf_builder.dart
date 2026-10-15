import 'dart:convert';
import 'dart:typed_data';

class AbstractPdfBuilder {
  static Uint8List buildProjectAbstractPdf() {
    final doc = _PdfDoc();

    // ================= PAGE 1 =================
    doc.addPage();
    _drawHeader(doc, pageNumber: 1, totalPages: 3);

    // Title & Metadata
    doc.fillRect(36, 730, 523, 18, r: 0.94, g: 0.96, b: 0.98);
    doc.drawRect(36, 730, 523, 18, r: 0.80, g: 0.85, b: 0.90, lineWidth: 0.6);
    doc.drawText('OFFICIAL ENGINEERING SPECIFICATION & PROJECT ABSTRACT', 46, 735,
        font: _PFont.bold, size: 8, r: 0.12, g: 0.11, b: 0.29);

    // Section 1: Executive Summary
    doc.drawText('1. EXECUTIVE SUMMARY & PURPOSE', 36, 705,
        font: _PFont.bold, size: 10.5, r: 0.09, g: 0.12, b: 0.20);

    doc.fillRect(36, 595, 523, 98, r: 0.98, g: 0.99, b: 1.0);
    doc.drawRect(36, 595, 523, 98, r: 0.85, g: 0.88, b: 0.94, lineWidth: 0.6);
    doc.fillRect(36, 595, 4, 98, r: 0.06, g: 0.72, b: 0.51); // Green left strip

    doc.drawText(
        'The Smart Canteen Management System is an automated cross-platform solution engineered',
        48, 678, font: _PFont.regular, size: 8.5, r: 0.2, g: 0.25, b: 0.35);
    doc.drawText(
        'to eliminate congestion, queue delays, manual token handling, and non-transparent financial',
        48, 664, font: _PFont.regular, size: 8.5, r: 0.2, g: 0.25, b: 0.35);
    doc.drawText(
        'bookkeeping in institutional dining facilities and campus food courts.',
        48, 650, font: _PFont.regular, size: 8.5, r: 0.2, g: 0.25, b: 0.35);
    doc.drawText(
        'It interconnects Students, Kitchen Operations, and Administrators into a synchronized real-time',
        48, 636, font: _PFont.regular, size: 8.5, r: 0.2, g: 0.25, b: 0.35);
    doc.drawText(
        'workflow with zero-latency token dispatching, instant stock toggles, and PDF audit reporting.',
        48, 622, font: _PFont.regular, size: 8.5, r: 0.2, g: 0.25, b: 0.35);
    doc.drawText(
        'Canteen Operating Hours: 8:00 AM - 5:30 PM IST with automatic lockout outside hours.',
        48, 608, font: _PFont.bold, size: 8.5, r: 0.05, g: 0.45, b: 0.30);

    // Section 2: Technology Stack Table
    doc.drawText('2. LANGUAGES & TECHNOLOGICAL STACK', 36, 575,
        font: _PFont.bold, size: 10.5, r: 0.09, g: 0.12, b: 0.20);

    // Table Header
    doc.fillRect(36, 545, 523, 18, r: 0.12, g: 0.11, b: 0.29);
    doc.drawText('LAYER / COMPONENT', 44, 550, font: _PFont.bold, size: 8, r: 1.0, g: 1.0, b: 1.0);
    doc.drawText('TECHNOLOGY USED', 180, 550, font: _PFont.bold, size: 8, r: 1.0, g: 1.0, b: 1.0);
    doc.drawText('ARCHITECTURAL ROLE & CAPABILITY', 320, 550, font: _PFont.bold, size: 8, r: 1.0, g: 1.0, b: 1.0);

    final techRows = [
      ['Primary Language', 'Dart (v3.13+)', 'Strongly-typed object-oriented client logic and data streams'],
      ['Frontend Framework', 'Flutter SDK', 'Multi-platform native UI rendering (Web, Android, iOS, Desktop)'],
      ['State Architecture', 'Provider Architecture', 'Scoped reactive state listeners (Cart, Order, Auth, Schedule)'],
      ['Cloud Database', 'Google Cloud Firestore', 'Real-time NoSQL document streaming and cloud synchronization'],
      ['Offline Engine', 'Multi-Stream Event Bus', 'Zero-latency in-memory cache ensuring instant UI reactivity'],
      ['Document Engine', 'Pure Dart PDF 1.4 Engine', 'Standalone vector PDF document generator without native plugins'],
      ['Security & Auth', 'Role-Based Authentication', 'Granular access control (Student, Kitchen Staff, Canteen Admin)'],
    ];

    double rowY = 525;
    for (int i = 0; i < techRows.length; i++) {
      final r = techRows[i];
      if (i % 2 == 0) {
        doc.fillRect(36, rowY, 523, 18, r: 0.98, g: 0.99, b: 1.0);
      }
      doc.drawRect(36, rowY, 523, 18, r: 0.88, g: 0.90, b: 0.94, lineWidth: 0.4);

      doc.drawText(r[0], 44, rowY + 5, font: _PFont.bold, size: 7.5, r: 0.15, g: 0.20, b: 0.30);
      doc.drawText(r[1], 180, rowY + 5, font: _PFont.bold, size: 7.5, r: 0.05, g: 0.45, b: 0.30);
      doc.drawText(r[2], 320, rowY + 5, font: _PFont.regular, size: 7.5, r: 0.25, g: 0.30, b: 0.40);

      rowY -= 20;
    }

    // Section 3: Core Objectives
    doc.drawText('3. PRIMARY SYSTEM OBJECTIVES', 36, 365,
        font: _PFont.bold, size: 10.5, r: 0.09, g: 0.12, b: 0.20);

    doc.fillRect(36, 265, 523, 88, r: 0.95, g: 0.97, b: 1.0);
    doc.drawRect(36, 265, 523, 88, r: 0.75, g: 0.82, b: 0.95, lineWidth: 0.6);

    doc.drawText(
        '* Contactless Ordering: Digital dietary menu with Veg/Non-Veg filters and custom notes.',
        46, 335, font: _PFont.regular, size: 8, r: 0.15, g: 0.20, b: 0.35);
    doc.drawText(
        '* Multi-Channel Payments: Prepaid Campus Meal Pass / Wallet, UPI QR, and Cash on Counter.',
        46, 320, font: _PFont.regular, size: 8, r: 0.15, g: 0.20, b: 0.35);
    doc.drawText(
        '* Kitchen Display Terminal: Real-time ticket pipeline (Pending -> Accepted -> Preparing -> Ready -> Done).',
        46, 305, font: _PFont.regular, size: 8, r: 0.15, g: 0.20, b: 0.35);
    doc.drawText(
        '* Stock Control & Auto-Refund: 1-tap stock availability toggles and instant cancellation refund.',
        46, 290, font: _PFont.regular, size: 8, r: 0.15, g: 0.20, b: 0.35);
    doc.drawText(
        '* Audit-Ready Monthly Reporting: Verifiable revenue calculation and PDF downloads for Admin.',
        46, 275, font: _PFont.regular, size: 8, r: 0.15, g: 0.20, b: 0.35);

    _drawFooter(doc, pageNumber: 1, totalPages: 3);

    // ================= PAGE 2 =================
    doc.addPage();
    _drawHeader(doc, pageNumber: 2, totalPages: 3);

    doc.drawText('4. ROLE-BASED SYSTEM MODULES & ARCHITECTURE', 36, 730,
        font: _PFont.bold, size: 10.5, r: 0.09, g: 0.12, b: 0.20);

    // Module 1: Student
    doc.fillRect(36, 595, 523, 120, r: 0.94, g: 0.99, b: 0.96);
    doc.drawRect(36, 595, 523, 120, r: 0.06, g: 0.72, b: 0.51, lineWidth: 0.8);
    doc.drawText('MODULE A: STUDENT / USER EXPERIENCE', 46, 698,
        font: _PFont.bold, size: 9.5, r: 0.02, g: 0.45, b: 0.31);
    doc.drawText(
        '- Interactive Food Catalog: Categorized dishes (Breakfast, Lunch, Snacks, Beverages, Desserts).',
        46, 680, font: _PFont.regular, size: 8, r: 0.15, g: 0.25, b: 0.20);
    doc.drawText(
        '- Smart Tray & Cart: Real-time total calculation with tax breakdown and out-of-stock validation.',
        46, 665, font: _PFont.regular, size: 8, r: 0.15, g: 0.25, b: 0.20);
    doc.drawText(
        '- Live Token Tracking: Step-by-step 5-stage progress indicator with counter pickup alerts.',
        46, 650, font: _PFont.regular, size: 8, r: 0.15, g: 0.25, b: 0.20);
    doc.drawText(
        '- In-App Campus Wallet: Balance recharge, debit history, and automatic instant refund reversal.',
        46, 635, font: _PFont.regular, size: 8, r: 0.15, g: 0.25, b: 0.20);
    doc.drawText(
        '- Dedicated Kitchen Helpline: Need Help button providing direct chef contact (+918590626036).',
        46, 620, font: _PFont.bold, size: 8, r: 0.05, g: 0.45, b: 0.25);
    doc.drawText(
        '- Feedback & Rating: Food quality stars and canteen service suggestions.',
        46, 605, font: _PFont.regular, size: 8, r: 0.15, g: 0.25, b: 0.20);

    // Module 2: Kitchen
    doc.fillRect(36, 455, 523, 125, r: 0.95, g: 0.96, b: 1.0);
    doc.drawRect(36, 455, 523, 125, r: 0.39, g: 0.40, b: 0.95, lineWidth: 0.8);
    doc.drawText('MODULE B: KITCHEN OPERATIONS & DISPLAY TERMINAL', 46, 563,
        font: _PFont.bold, size: 9.5, r: 0.15, g: 0.20, b: 0.65);
    doc.drawText(
        '- Dual-Mode Terminal: Quick switcher between Live Orders Queue and Food Stock Control.',
        46, 545, font: _PFont.regular, size: 8, r: 0.15, g: 0.20, b: 0.35);
    doc.drawText(
        '- Order Workflow Pipeline: 1-Tap progression [Accept -> Start Preparing -> Ready -> Complete].',
        46, 530, font: _PFont.regular, size: 8, r: 0.15, g: 0.20, b: 0.35);
    doc.drawText(
        '- 1-Tap Stock Control: Prominent IN STOCK (Green) and OUT OF STOCK (Red) buttons per dish.',
        46, 515, font: _PFont.bold, size: 8, r: 0.10, g: 0.35, b: 0.55);
    doc.drawText(
        '- Cancellation & Wallet Auto-Refund: Reason selector instantly crediting student balance.',
        46, 500, font: _PFont.regular, size: 8, r: 0.15, g: 0.20, b: 0.35);
    doc.drawText(
        '- Search & Filters: Real-time token number search and categorized status chips.',
        46, 485, font: _PFont.regular, size: 8, r: 0.15, g: 0.20, b: 0.35);
    doc.drawText(
        '- Zero-Lag Synchronization: Live ticket updates received in under 10 milliseconds.',
        46, 470, font: _PFont.regular, size: 8, r: 0.15, g: 0.20, b: 0.35);

    // Module 3: Admin
    doc.fillRect(36, 315, 523, 125, r: 1.0, g: 0.98, b: 0.94);
    doc.drawRect(36, 315, 523, 125, r: 0.85, g: 0.55, b: 0.15, lineWidth: 0.8);
    doc.drawText('MODULE C: ADMINISTRATIVE GOVERNANCE & AUDIT ANALYTICS', 46, 423,
        font: _PFont.bold, size: 9.5, r: 0.65, g: 0.35, b: 0.05);
    doc.drawText(
        '- Executive KPI Dashboard: Gross revenue metrics, order volumes, and menu availability.',
        46, 405, font: _PFont.regular, size: 8, r: 0.30, g: 0.20, b: 0.10);
    doc.drawText(
        '- Menu Catalog Management: Add, edit, price, and delete dishes with images and categories.',
        46, 390, font: _PFont.regular, size: 8, r: 0.30, g: 0.20, b: 0.10);
    doc.drawText(
        '- Operating Hours Schedule: Strict daily hours (8:00 AM - 5:30 PM IST) enforcement.',
        46, 375, font: _PFont.regular, size: 8, r: 0.30, g: 0.20, b: 0.10);
    doc.drawText(
        '- User & Role Administration: Manage student, kitchen, and administrator accounts and balances.',
        46, 360, font: _PFont.regular, size: 8, r: 0.30, g: 0.20, b: 0.10);
    doc.drawText(
        '- Monthly Revenue Audit Engine: Historical Month/Year selector with accurate revenue tally.',
        46, 345, font: _PFont.bold, size: 8, r: 0.55, g: 0.25, b: 0.05);
    doc.drawText(
        '- PDF Report Export: One-click generation of certified multi-page financial audit reports.',
        46, 330, font: _PFont.regular, size: 8, r: 0.30, g: 0.20, b: 0.10);

    _drawFooter(doc, pageNumber: 2, totalPages: 3);

    // ================= PAGE 3 =================
    doc.addPage();
    _drawHeader(doc, pageNumber: 3, totalPages: 3);

    // Section 5: End-to-End Workflow
    doc.drawText('5. END-TO-END OPERATIONAL PROCEDURE (WORKFLOW)', 36, 730,
        font: _PFont.bold, size: 10.5, r: 0.09, g: 0.12, b: 0.20);

    final steps = [
      ['1. Schedule Validation', 'System verifies current IST time is within operational hours (8:00 AM - 5:30 PM).'],
      ['2. Cart & Stock Check', 'Student selects dishes; live availability is confirmed preventing out-of-stock orders.'],
      ['3. Payment & Token', 'Wallet balance deducted or UPI confirmed; unique Order ID & Token (#XX) created.'],
      ['4. Kitchen Ingestion', 'Order immediately appears in Kitchen Terminal Pending queue (<10ms latency).'],
      ['5. Preparation Flow', 'Kitchen staff accepts, starts cooking, marks ready for pickup, and completes token.'],
      ['6. Handover & Ledger', 'Student collects food; transaction finalized in the verified Monthly Revenue Ledger.'],
    ];

    double stepY = 705;
    for (final st in steps) {
      doc.fillRect(36, stepY - 14, 523, 20, r: 0.98, g: 0.99, b: 1.0);
      doc.drawRect(36, stepY - 14, 523, 20, r: 0.88, g: 0.90, b: 0.94, lineWidth: 0.4);

      doc.drawText(st[0], 46, stepY - 8, font: _PFont.bold, size: 8, r: 0.12, g: 0.11, b: 0.29);
      doc.drawText(st[1], 160, stepY - 8, font: _PFont.regular, size: 8, r: 0.25, g: 0.30, b: 0.40);

      stepY -= 24;
    }

    // Section 6: Security & Data Integrity
    doc.drawText('6. SECURITY, DATA INTEGRITY & FAULT TOLERANCE', 36, 540,
        font: _PFont.bold, size: 10.5, r: 0.09, g: 0.12, b: 0.20);

    doc.fillRect(36, 440, 523, 85, r: 0.95, g: 0.98, b: 0.96);
    doc.drawRect(36, 440, 523, 85, r: 0.10, g: 0.65, b: 0.45, lineWidth: 0.6);

    doc.drawText(
        '* Zero-Latency Synchronization: Dual-channel multi-stream event bus with local in-memory fallback.',
        46, 510, font: _PFont.regular, size: 8, r: 0.15, g: 0.25, b: 0.20);
    doc.drawText(
        '* Non-Duplicate Ledger: Deduplicated calculation factoring only completed and paid orders.',
        46, 495, font: _PFont.regular, size: 8, r: 0.15, g: 0.25, b: 0.20);
    doc.drawText(
        '* Race-Condition Protection: Atomic balance deductions and rollback refunds during cancellation.',
        46, 480, font: _PFont.regular, size: 8, r: 0.15, g: 0.25, b: 0.20);
    doc.drawText(
        '* Native Cross-Platform Compatibility: Seamless execution on Web (Chrome), Android, iOS, Windows.',
        46, 465, font: _PFont.regular, size: 8, r: 0.15, g: 0.25, b: 0.20);
    doc.drawText(
        '* Robust Serialization: ISO 8601 timestamp conversions ensuring crash-free data persistence.',
        46, 450, font: _PFont.regular, size: 8, r: 0.15, g: 0.25, b: 0.20);

    // Section 7: Certification Box
    doc.fillRect(36, 230, 523, 185, r: 0.97, g: 0.98, b: 1.0);
    doc.drawRect(36, 230, 523, 185, r: 0.70, g: 0.78, b: 0.92, lineWidth: 0.8);

    doc.drawText('7. CONCLUSION & CERTIFICATION STATEMENT', 46, 398,
        font: _PFont.bold, size: 9.5, r: 0.12, g: 0.11, b: 0.29);
    doc.drawText(
        'The Smart Canteen platform successfully unifies customer satisfaction, kitchen agility, and administrative',
        46, 380, font: _PFont.regular, size: 8, r: 0.25, g: 0.30, b: 0.40);
    doc.drawText(
        'transparency into a cohesive, high-speed digital ecosystem. Designed and tested for high-volume campus rush',
        46, 365, font: _PFont.regular, size: 8, r: 0.25, g: 0.30, b: 0.40);
    doc.drawText(
        'hours, it sets a gold standard for institutional food court automation and financial governance.',
        46, 350, font: _PFont.regular, size: 8, r: 0.25, g: 0.30, b: 0.40);

    doc.fillRect(46, 335, 503, 1, r: 0.80, g: 0.85, b: 0.90);

    doc.drawText('Project Name: SMART CANTEEN AUTOMATION SYSTEM', 46, 320,
        font: _PFont.bold, size: 8, r: 0.15, g: 0.20, b: 0.30);
    doc.drawText('Software Version: Release v1.0.0 (Production Stable)', 46, 305,
        font: _PFont.regular, size: 8, r: 0.30, g: 0.35, b: 0.45);
    doc.drawText('Helpline Hotline: +918590626036 | Operating Hours: 8:00 AM - 5:30 PM IST', 46, 290,
        font: _PFont.bold, size: 8, r: 0.05, g: 0.45, b: 0.30);
    doc.drawText('Audit Status: Certified & Validated for Institutional Deployment', 46, 275,
        font: _PFont.bold, size: 8, r: 0.12, g: 0.11, b: 0.29);
    doc.drawText('Date of Documentation: October 2026', 46, 260,
        font: _PFont.regular, size: 8, r: 0.40, g: 0.45, b: 0.55);

    _drawFooter(doc, pageNumber: 3, totalPages: 3);

    return doc.build();
  }

  static void _drawHeader(_PdfDoc doc, {required int pageNumber, required int totalPages}) {
    // Header Banner Background (Deep Indigo #1E1B4B)
    doc.fillRect(36, 755, 523, 56, r: 0.12, g: 0.11, b: 0.29);
    // Accent line (Emerald Green #10B981)
    doc.fillRect(36, 751, 523, 4, r: 0.06, g: 0.72, b: 0.51);

    // Text
    doc.drawText('SMART CANTEEN MANAGEMENT SYSTEM', 50, 788,
        font: _PFont.bold, size: 14, r: 1.0, g: 1.0, b: 1.0);
    doc.drawText('Comprehensive Project Abstract & Engineering Documentation', 50, 774,
        font: _PFont.regular, size: 8.5, r: 0.78, g: 0.82, b: 0.99);

    doc.drawText('VERSION 1.0.0', 460, 788,
        font: _PFont.bold, size: 10, r: 0.38, g: 0.87, b: 0.65);
    doc.drawText('Page $pageNumber of $totalPages', 460, 774,
        font: _PFont.regular, size: 8, r: 0.8, g: 0.85, b: 0.95);
  }

  static void _drawFooter(_PdfDoc doc, {required int pageNumber, required int totalPages}) {
    doc.fillRect(36, 50, 523, 1, r: 0.85, g: 0.88, b: 0.92);
    doc.drawText('Smart Canteen Automation Platform - Official Technical Documentation', 36, 38,
        font: _PFont.regular, size: 7.5, r: 0.5, g: 0.55, b: 0.65);
    doc.drawText('Page $pageNumber of $totalPages', 500, 38,
        font: _PFont.bold, size: 7.5, r: 0.4, g: 0.45, b: 0.55);
  }
}

enum _PFont { regular, bold, oblique }

class _PdfDoc {
  final List<String> _pageContents = [];
  int _currentPageIndex = -1;

  void addPage() {
    _pageContents.add('');
    _currentPageIndex = _pageContents.length - 1;
  }

  void _append(String cmd) {
    if (_currentPageIndex >= 0 && _currentPageIndex < _pageContents.length) {
      _pageContents[_currentPageIndex] += '$cmd\n';
    }
  }

  void fillRect(double x, double y, double w, double h,
      {required double r, required double g, required double b}) {
    final cx = x.toStringAsFixed(2);
    final cy = y.toStringAsFixed(2);
    final cw = w.toStringAsFixed(2);
    final ch = h.toStringAsFixed(2);
    final cr = r.toStringAsFixed(3);
    final cg = g.toStringAsFixed(3);
    final cb = b.toStringAsFixed(3);
    _append('q $cr $cg $cb rg $cx $cy $cw $ch re f Q');
  }

  void drawRect(double x, double y, double w, double h,
      {required double r, required double g, required double b, double lineWidth = 1.0}) {
    final cx = x.toStringAsFixed(2);
    final cy = y.toStringAsFixed(2);
    final cw = w.toStringAsFixed(2);
    final ch = h.toStringAsFixed(2);
    final cr = r.toStringAsFixed(3);
    final cg = g.toStringAsFixed(3);
    final cb = b.toStringAsFixed(3);
    final clw = lineWidth.toStringAsFixed(2);
    _append('q $clw w $cr $cg $cb RG $cx $cy $cw $ch re S Q');
  }

  void drawText(String text, double x, double y,
      {_PFont font = _PFont.regular,
      double size = 10,
      required double r,
      required double g,
      required double b}) {
    final fontName = font == _PFont.bold ? '/F2' : (font == _PFont.oblique ? '/F3' : '/F1');

    final sanitized = text
        .replaceAll('\\', '\\\\')
        .replaceAll('(', '\\(')
        .replaceAll(')', '\\)')
        .replaceAll('₹', 'Rs. ');

    final cx = x.toStringAsFixed(2);
    final cy = y.toStringAsFixed(2);
    final csize = size.toStringAsFixed(2);
    final cr = r.toStringAsFixed(3);
    final cg = g.toStringAsFixed(3);
    final cb = b.toStringAsFixed(3);

    _append('BT $fontName $csize Tf $cr $cg $cb rg 1 0 0 1 $cx $cy Tm ($sanitized) Tj ET');
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
    final int firstPageObj = 3;
    final int firstContentObj = firstPageObj + pageCount;
    final int f1Obj = firstContentObj + pageCount;
    final int f2Obj = f1Obj + 1;
    final int f3Obj = f2Obj + 1;
    final int totalObjs = f3Obj;

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

    // Page Objects
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

    // Fonts
    startObj(f1Obj);
    write('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>\nendobj\n');

    startObj(f2Obj);
    write('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>\nendobj\n');

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
