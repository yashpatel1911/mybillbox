import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../model/invoice_details/invoice_model.dart';
import '../../../../DBHelper/app_colors.dart';

class InvoicePdfGenerator {
  static const _navy = PdfColor.fromInt(0xFF1A3C6E);
  static const _navyLight = PdfColor.fromInt(0xFFBBDEFB);
  static const _green = PdfColor.fromInt(0xFF2E7D32);
  static const _orange = PdfColor.fromInt(0xFFE65100);
  static const _red = PdfColor.fromInt(0xFFC62828);
  static const _lightGrey = PdfColor.fromInt(0xFFF5F5F5);
  static const _border = PdfColor.fromInt(0xFFDDDDDD);
  static const _textDark = PdfColor.fromInt(0xFF1A1A1A);
  static const _textMedium = PdfColor.fromInt(0xFF555555);
  static const _textLight = PdfColor.fromInt(0xFF888888);

  static void showPreview(BuildContext context, InvoiceModel invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _PdfPreviewScreen(invoice: invoice)),
    );
  }

  static Future<pw.Document> buildPdf(InvoiceModel invoice) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final bold = await PdfGoogleFonts.nunitoBold();

    String fmt(double v) => v
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+(\d)\b)'), (m) => '${m[1]},');

    PdfColor statusColor(String s) {
      switch (s) {
        case 'paid':
          return _green;
        case 'partial':
          return _navy;
        case 'overdue':
          return _red;
        default:
          return _orange;
      }
    }

    String statusLabel(String s) {
      switch (s) {
        case 'paid':
          return 'PAID';
        case 'partial':
          return 'PARTIAL';
        case 'overdue':
          return 'OVERDUE';
        default:
          return 'PENDING';
      }
    }

    String fmtDate(String d) {
      try {
        return DateFormat('dd-MM-yyyy').format(DateTime.parse(d));
      } catch (_) {
        return d;
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: _navy,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          invoice.shop?.shName ?? 'My Shop',
                          style: pw.TextStyle(
                            font: bold,
                            fontSize: 20,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'INVOICE',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                            color: _navyLight,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        invoice.invoiceNumber,
                        style: pw.TextStyle(
                          font: bold,
                          fontSize: 13,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Date: ${fmtDate(invoice.invoiceDate)}',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 9,
                          color: _navyLight,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: pw.BoxDecoration(
                          color: statusColor(invoice.paymentStatus),
                          borderRadius: pw.BorderRadius.circular(20),
                        ),
                        child: pw.Text(
                          statusLabel(invoice.paymentStatus),
                          style: pw.TextStyle(
                            font: bold,
                            fontSize: 9,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 18),

            // ── Customer ─────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: _lightGrey,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: _border, width: 0.5),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'BILL TO',
                          style: pw.TextStyle(
                            font: bold,
                            fontSize: 8,
                            color: _textLight,
                            letterSpacing: 1.5,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          invoice.customerName,
                          style: pw.TextStyle(
                            font: bold,
                            fontSize: 13,
                            color: _textDark,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Mobile: ${invoice.customerMobile}',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                            color: _textMedium,
                          ),
                        ),
                        if (invoice.notes != null &&
                            invoice.notes!.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Note: ${invoice.notes}',
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 8,
                              color: _textLight,
                              fontStyle: pw.FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 18),

            // ── Items label ───────────────────────────────
            pw.Text(
              'ITEMS',
              style: pw.TextStyle(
                font: bold,
                fontSize: 8,
                color: _textLight,
                letterSpacing: 1.5,
              ),
            ),
            pw.SizedBox(height: 6),

            // ── Items table ───────────────────────────────
            pw.Table(
              border: pw.TableBorder.all(color: _border, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3.5),
                1: const pw.FixedColumnWidth(50),
                2: const pw.FixedColumnWidth(40),
                3: const pw.FixedColumnWidth(65),
                4: const pw.FixedColumnWidth(65),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: _navy),
                  children: [
                    _th('Product Name', bold),
                    _th('Size', bold, center: true),
                    _th('Qty', bold, center: true),
                    _th('Price', bold, right: true),
                    _th('Total', bold, right: true),
                  ],
                ),
                ...invoice.items.asMap().entries.map((e) {
                  final item = e.value;
                  final bg = e.key.isEven ? PdfColors.white : _lightGrey;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: bg),
                    children: [
                      _td(
                        item.productName,
                        font,
                        sub: item.itemDiscount > 0
                            ? 'Discount: -Rs.${fmt(item.itemDiscount)}'
                            : null,
                      ),
                      _td(item.size ?? '-', font, center: true),
                      _td('${item.quantity}', font, center: true),
                      _td('Rs.${fmt(item.unitPrice)}', font, right: true),
                      _td('Rs.${fmt(item.totalPrice)}', font, right: true),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 14),

            // ── Totals ────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.SizedBox(
                  width: 220,
                  child: pw.Column(
                    children: [
                      _tr(
                        'Subtotal',
                        'Rs.${fmt(invoice.subTotal)}',
                        font,
                        bold,
                      ),
                      if (invoice.discountAmount > 0)
                        _tr(
                          'Discount${invoice.discountType == "percent" ? " (${invoice.discountValue.toStringAsFixed(0)}%)" : " (flat)"}',
                          '- Rs.${fmt(invoice.discountAmount)}',
                          font,
                          bold,
                          valueColor: _red,
                        ),
                      pw.Divider(color: _border, thickness: 0.5),
                      _tr(
                        'Grand Total',
                        'Rs.${fmt(invoice.totalAmount)}',
                        font,
                        bold,
                        isHeader: true,
                      ),
                      pw.SizedBox(height: 4),
                      _tr(
                        'Amount Paid',
                        'Rs.${fmt(invoice.amountPaid)}',
                        font,
                        bold,
                        valueColor: _green,
                      ),
                      if (invoice.amountDue > 0)
                        _tr(
                          'Amount Due',
                          'Rs.${fmt(invoice.amountDue)}',
                          font,
                          bold,
                          valueColor: _red,
                        ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 16),

            // ── Payment status banner ─────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: _tint(statusColor(invoice.paymentStatus), 0.08),
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(
                  color: _tint(statusColor(invoice.paymentStatus), 0.3),
                  width: 0.5,
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Payment Status',
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 10,
                      color: _textMedium,
                    ),
                  ),
                  pw.Text(
                    statusLabel(invoice.paymentStatus),
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 11,
                      color: statusColor(invoice.paymentStatus),
                    ),
                  ),
                ],
              ),
            ),

            pw.Spacer(),

            // ── Footer ───────────────────────────────────
            pw.Divider(color: _border, thickness: 0.5),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text(
                'Thank you for your business!',
                style: pw.TextStyle(font: bold, fontSize: 11, color: _navy),
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Center(
              child: pw.Text(
                'Generated by MyBillBox',
                style: pw.TextStyle(font: font, fontSize: 7, color: _textLight),
              ),
            ),
          ],
        ),
      ),
    );

    return pdf;
  }

  static pw.Widget _th(
    String text,
    pw.Font bold, {
    bool center = false,
    bool right = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 7),
      alignment: right
          ? pw.Alignment.centerRight
          : center
          ? pw.Alignment.center
          : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(font: bold, fontSize: 8, color: PdfColors.white),
      ),
    );
  }

  static pw.Widget _td(
    String text,
    pw.Font font, {
    bool center = false,
    bool right = false,
    String? sub,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      alignment: right
          ? pw.Alignment.centerRight
          : center
          ? pw.Alignment.center
          : pw.Alignment.centerLeft,
      child: pw.Column(
        crossAxisAlignment: right
            ? pw.CrossAxisAlignment.end
            : center
            ? pw.CrossAxisAlignment.center
            : pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            text,
            style: pw.TextStyle(font: font, fontSize: 9, color: _textDark),
          ),
          if (sub != null) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              sub,
              style: pw.TextStyle(font: font, fontSize: 7, color: _red),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _tr(
    String label,
    String value,
    pw.Font font,
    pw.Font bold, {
    bool isHeader = false,
    PdfColor? valueColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: isHeader ? bold : font,
              fontSize: isHeader ? 11 : 9,
              color: isHeader ? _textDark : _textMedium,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: bold,
              fontSize: isHeader ? 13 : 10,
              color: valueColor ?? (isHeader ? _textDark : _textMedium),
            ),
          ),
        ],
      ),
    );
  }

  static PdfColor _tint(PdfColor c, double opacity) => PdfColor(
    c.red * opacity + (1 - opacity),
    c.green * opacity + (1 - opacity),
    c.blue * opacity + (1 - opacity),
  );
}

// ─────────────────────────────────────────────────────────────────
// In-app PDF preview screen
// ─────────────────────────────────────────────────────────────────
class _PdfPreviewScreen extends StatelessWidget {
  final InvoiceModel invoice;

  const _PdfPreviewScreen({required this.invoice});

  Future<File> _saveTempPdf() async {
    final doc = await InvoicePdfGenerator.buildPdf(invoice);
    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${invoice.invoiceNumber}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  // ── Share PDF (user picks app from share sheet) ──
  Future<void> _sharePdf(BuildContext context) async {
    try {
      final file = await _saveTempPdf();
      final phone = _cleanPhone(invoice.customerMobile);
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Invoice ${invoice.invoiceNumber}\n'
            'Customer: ${invoice.customerName}\n'
            'Amount: Rs.${invoice.totalAmount.toStringAsFixed(0)}\n'
            'Status: ${invoice.paymentStatus.toUpperCase()}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // ── Open WhatsApp chat directly to customer number ──
  Future<void> _openWhatsApp(BuildContext context) async {
    try {
      final phone = _cleanPhone(invoice.customerMobile);
      final message = Uri.encodeComponent(
        'Hello ${invoice.customerName},\n'
        'Please find your invoice ${invoice.invoiceNumber}\n'
        'Amount: Rs.${invoice.totalAmount.toStringAsFixed(0)}\n'
        'Status: ${invoice.paymentStatus.toUpperCase()}',
      );
      final uri = Uri.parse('whatsapp://send?phone=$phone&text=$message');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open WhatsApp: $e')));
      }
    }
  }

  // ── Clean phone: strip non-digits, add India +91 ──
  String _cleanPhone(String mobile) {
    final raw = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    return raw.length == 10 ? '91$raw' : raw;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.textDark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Invoice Preview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            Text(
              invoice.invoiceNumber,
              style: const TextStyle(fontSize: 11, color: AppColors.textLight),
            ),
          ],
        ),
        actions: [
          // ── WhatsApp: open chat with customer number ──
          IconButton(
            onPressed: () => _openWhatsApp(context),
            tooltip: 'WhatsApp ${invoice.customerMobile}',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'WA',
                style: TextStyle(
                  color: Color(0xFF25D366),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          // ── General share (WhatsApp, Gmail, Drive, etc.) ──
          IconButton(
            onPressed: () => _sharePdf(context),
            tooltip: 'Share PDF',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.share_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: PdfPreview(
        build: (format) async {
          final doc = await InvoicePdfGenerator.buildPdf(invoice);
          return doc.save();
        },
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: false,
        allowSharing: false,
        useActions: false,
        initialPageFormat: PdfPageFormat.a4,
        pdfFileName: '${invoice.invoiceNumber}.pdf',
        dpi: 150,
        maxPageWidth: 1200,
        scrollViewDecoration: BoxDecoration(color: Colors.grey[900]),
        previewPageMargin: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
        padding: const EdgeInsets.all(0),
      ),
    );
  }
}
