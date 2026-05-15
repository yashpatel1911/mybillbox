import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../../model/invoice_details/invoice_model.dart';
import 'pdf_shared.dart';

class ClassicNavyPdfGenerator {
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
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          invoice: invoice,
          designName: 'Classic Navy',
          themeColor: const Color(0xFF1A3C6E),
          builder: buildPdf,
        ),
      ),
    );
  }

  static PdfColor _statusColor(String s) {
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

  static Future<pw.Document> buildPdf(InvoiceModel invoice) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final bold = await PdfGoogleFonts.nunitoBold();

    pw.MemoryImage? logoImage;
    final logoUrl = invoice.shop?.shLogoUrl;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      try {
        final response = await http
            .get(Uri.parse(logoUrl))
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          logoImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (_) {}
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────
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
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        if (logoImage != null) ...[
                          pw.ClipRRect(
                            horizontalRadius: 6,
                            verticalRadius: 6,
                            child: pw.Image(
                              logoImage,
                              width: 52,
                              height: 52,
                              fit: pw.BoxFit.cover,
                            ),
                          ),
                          pw.SizedBox(width: 14),
                        ],
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                invoice.shop?.shName ?? 'My Shop',
                                maxLines: 1,
                                overflow: pw.TextOverflow.clip,
                                style: pw.TextStyle(
                                  font: bold,
                                  fontSize: 20,
                                  color: PdfColors.white,
                                ),
                              ),
                              pw.SizedBox(height: 3),
                              if (invoice.shop?.shAddress?.isNotEmpty == true)
                                pw.Text(
                                  invoice.shop!.shAddress!,
                                  maxLines: 2,
                                  style: pw.TextStyle(
                                    font: font,
                                    fontSize: 8,
                                    color: _navyLight,
                                    lineSpacing: 1.5,
                                  ),
                                ),
                              if (invoice.shop?.shContact?.isNotEmpty == true)
                                pw.Text(
                                  'Ph: ${invoice.shop!.shContact}',
                                  maxLines: 1,
                                  style: pw.TextStyle(
                                    font: font,
                                    fontSize: 8,
                                    color: _navyLight,
                                  ),
                                ),
                              if (invoice.shop?.shGst?.isNotEmpty == true)
                                pw.Text(
                                  'GST: ${invoice.shop!.shGst}',
                                  maxLines: 1,
                                  style: pw.TextStyle(
                                    font: font,
                                    fontSize: 8,
                                    color: _navyLight,
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
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 12),
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
                        'Date: ${PdfHelpers.fmtDate(invoice.invoiceDate)}',
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
                          color: _statusColor(invoice.paymentStatus),
                          borderRadius: pw.BorderRadius.circular(20),
                        ),
                        child: pw.Text(
                          PdfHelpers.statusLabel(invoice.paymentStatus),
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

            // ── Customer ────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: _lightGrey,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: _border, width: 0.5),
              ),
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
                  if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
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
            pw.SizedBox(height: 18),

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

            // ── Items table ─────────────────────────────────
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
                  decoration: const pw.BoxDecoration(color: _navy),
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
                            ? 'Discount: -Rs.${PdfHelpers.fmt(item.itemDiscount)}'
                            : null,
                      ),
                      _td(item.size ?? '-', font, center: true),
                      _td('${item.quantity}', font, center: true),
                      _td('Rs.${PdfHelpers.fmt(item.unitPrice)}', font,
                          right: true),
                      _td('Rs.${PdfHelpers.fmt(item.totalPrice)}', font,
                          right: true),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 14),

            // ── Totals ──────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.SizedBox(
                  width: 220,
                  child: pw.Column(
                    children: [
                      _tr('Subtotal',
                          'Rs.${PdfHelpers.fmt(invoice.subTotal)}', font, bold),
                      if (invoice.discountAmount > 0)
                        _tr(
                          'Discount${invoice.discountType == "percent" ? " (${invoice.discountValue.toStringAsFixed(0)}%)" : " (flat)"}',
                          '- Rs.${PdfHelpers.fmt(invoice.discountAmount)}',
                          font,
                          bold,
                          valueColor: _red,
                        ),
                      pw.Divider(color: _border, thickness: 0.5),
                      _tr(
                        'Grand Total',
                        'Rs.${PdfHelpers.fmt(invoice.totalAmount)}',
                        font,
                        bold,
                        isHeader: true,
                      ),
                      pw.SizedBox(height: 4),
                      _tr(
                        'Amount Paid',
                        'Rs.${PdfHelpers.fmt(invoice.amountPaid)}',
                        font,
                        bold,
                        valueColor: _green,
                      ),
                      if (invoice.amountDue > 0)
                        _tr(
                          'Amount Due',
                          'Rs.${PdfHelpers.fmt(invoice.amountDue)}',
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

            // ── Banner ──────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: _tint(_statusColor(invoice.paymentStatus), 0.08),
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(
                  color: _tint(_statusColor(invoice.paymentStatus), 0.3),
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
                    PdfHelpers.statusLabel(invoice.paymentStatus),
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 11,
                      color: _statusColor(invoice.paymentStatus),
                    ),
                  ),
                ],
              ),
            ),

            pw.Spacer(),
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
                style:
                pw.TextStyle(font: font, fontSize: 7, color: _textLight),
              ),
            ),
          ],
        ),
      ),
    );
    return pdf;
  }

  static pw.Widget _th(String text, pw.Font bold,
      {bool center = false, bool right = false}) {
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

  static pw.Widget _td(String text, pw.Font font,
      {bool center = false, bool right = false, String? sub}) {
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
          pw.Text(text,
              style: pw.TextStyle(font: font, fontSize: 9, color: _textDark)),
          if (sub != null) ...[
            pw.SizedBox(height: 2),
            pw.Text(sub,
                style: pw.TextStyle(font: font, fontSize: 7, color: _red)),
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
          pw.Text(label,
              style: pw.TextStyle(
                font: isHeader ? bold : font,
                fontSize: isHeader ? 11 : 9,
                color: isHeader ? _textDark : _textMedium,
              )),
          pw.Text(value,
              style: pw.TextStyle(
                font: bold,
                fontSize: isHeader ? 13 : 10,
                color: valueColor ?? (isHeader ? _textDark : _textMedium),
              )),
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