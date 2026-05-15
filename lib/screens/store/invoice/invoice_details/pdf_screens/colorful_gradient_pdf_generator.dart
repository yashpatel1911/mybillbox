import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../../model/invoice_details/invoice_model.dart';
import 'pdf_shared.dart';

class ColorfulGradientPdfGenerator {
  static const _purple = PdfColor.fromInt(0xFF667EEA);
  static const _pink = PdfColor.fromInt(0xFFEC4899);
  static const _purpleLight = PdfColor.fromInt(0xFFEEF2FF);
  static const _pinkLight = PdfColor.fromInt(0xFFFDF2F8);
  static const _textDark = PdfColor.fromInt(0xFF1F2937);
  static const _textMedium = PdfColor.fromInt(0xFF6B7280);
  static const _textLight = PdfColor.fromInt(0xFF9CA3AF);
  static const _border = PdfColor.fromInt(0xFFE5E7EB);
  static const _green = PdfColor.fromInt(0xFF10B981);
  static const _red = PdfColor.fromInt(0xFFEF4444);
  static const _amber = PdfColor.fromInt(0xFFF59E0B);

  static void showPreview(BuildContext context, InvoiceModel invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          invoice: invoice,
          designName: 'Colorful Gradient',
          themeColor: const Color(0xFF667EEA),
          builder: buildPdf,
        ),
      ),
    );
  }

  static PdfColor _statusColor(String s) {
    switch (s) {
      case 'paid':
        return _green;
      case 'overdue':
        return _red;
      case 'partial':
        return _amber;
      default:
        return _amber;
    }
  }

  static Future<pw.Document> buildPdf(InvoiceModel invoice) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.poppinsRegular();
    final medium = await PdfGoogleFonts.poppinsMedium();
    final bold = await PdfGoogleFonts.poppinsBold();

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
        margin: pw.EdgeInsets.zero,
        build: (ctx) => pw.Stack(
          children: [
            // ── Background decorative circles ──────────────
            pw.Positioned(
              top: -60,
              right: -60,
              child: pw.Container(
                width: 200,
                height: 200,
                decoration: pw.BoxDecoration(
                  color: _purpleLight,
                  shape: pw.BoxShape.circle,
                ),
              ),
            ),
            pw.Positioned(
              bottom: -80,
              left: -80,
              child: pw.Container(
                width: 240,
                height: 240,
                decoration: pw.BoxDecoration(
                  color: _pinkLight,
                  shape: pw.BoxShape.circle,
                ),
              ),
            ),

            pw.Container(
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // ── Header card with gradient ────────────
                  pw.Container(
                    padding: const pw.EdgeInsets.all(22),
                    decoration: pw.BoxDecoration(
                      gradient: const pw.LinearGradient(
                        begin: pw.Alignment.topLeft,
                        end: pw.Alignment.bottomRight,
                        colors: [_purple, _pink],
                      ),
                      borderRadius: pw.BorderRadius.circular(16),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              if (logoImage != null) ...[
                                pw.Container(
                                  padding: const pw.EdgeInsets.all(4),
                                  decoration: pw.BoxDecoration(
                                    color: PdfColors.white,
                                    borderRadius: pw.BorderRadius.circular(12),
                                  ),
                                  child: pw.ClipRRect(
                                    horizontalRadius: 8,
                                    verticalRadius: 8,
                                    child: pw.Image(
                                      logoImage,
                                      width: 48,
                                      height: 48,
                                      fit: pw.BoxFit.cover,
                                    ),
                                  ),
                                ),
                                pw.SizedBox(width: 14),
                              ],
                              pw.Expanded(
                                child: pw.Column(
                                  crossAxisAlignment:
                                  pw.CrossAxisAlignment.start,
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
                                    if (invoice.shop?.shAddress?.isNotEmpty ==
                                        true)
                                      pw.Text(
                                        invoice.shop!.shAddress!,
                                        maxLines: 2,
                                        style: pw.TextStyle(
                                          font: font,
                                          fontSize: 8,
                                          color: PdfColors.white,
                                          lineSpacing: 1.5,
                                        ),
                                      ),
                                    if (invoice.shop?.shContact?.isNotEmpty ==
                                        true)
                                      pw.Text(
                                        'Ph: ${invoice.shop!.shContact}',
                                        maxLines: 1,
                                        style: pw.TextStyle(
                                          font: font,
                                          fontSize: 8,
                                          color: PdfColors.white,
                                        ),
                                      ),
                                    if (invoice.shop?.shGst?.isNotEmpty == true)
                                      pw.Text(
                                        'GST: ${invoice.shop!.shGst}',
                                        maxLines: 1,
                                        style: pw.TextStyle(
                                          font: font,
                                          fontSize: 8,
                                          color: PdfColors.white,
                                        ),
                                      ),
                                    pw.SizedBox(height: 3),
                                    pw.Text(
                                      'Invoice',
                                      style: pw.TextStyle(
                                        font: medium,
                                        fontSize: 11,
                                        color: PdfColors.white,
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
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.white,
                                borderRadius: pw.BorderRadius.circular(20),
                              ),
                              child: pw.Text(
                                PdfHelpers.statusLabel(invoice.paymentStatus),
                                style: pw.TextStyle(
                                  font: bold,
                                  fontSize: 9,
                                  color: _statusColor(invoice.paymentStatus),
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 10),
                            pw.Text(
                              invoice.invoiceNumber,
                              style: pw.TextStyle(
                                font: bold,
                                fontSize: 13,
                                color: PdfColors.white,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              PdfHelpers.fmtDate(invoice.invoiceDate),
                              style: pw.TextStyle(
                                font: font,
                                fontSize: 9,
                                color: PdfColors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 18),

                  // ── Bill to ────────────────────────────────
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(12),
                      border: pw.Border.all(color: _border, width: 0.5),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: 4,
                          height: 40,
                          decoration: pw.BoxDecoration(
                            gradient: const pw.LinearGradient(
                              begin: pw.Alignment.topCenter,
                              end: pw.Alignment.bottomCenter,
                              colors: [_purple, _pink],
                            ),
                            borderRadius: pw.BorderRadius.circular(2),
                          ),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Billed to',
                                  style: pw.TextStyle(
                                      font: medium,
                                      fontSize: 9,
                                      color: _textLight)),
                              pw.SizedBox(height: 2),
                              pw.Text(invoice.customerName,
                                  style: pw.TextStyle(
                                      font: bold,
                                      fontSize: 14,
                                      color: _textDark)),
                              pw.SizedBox(height: 1),
                              pw.Text(invoice.customerMobile,
                                  style: pw.TextStyle(
                                      font: font,
                                      fontSize: 10,
                                      color: _textMedium)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 18),

                  // ── Items header ───────────────────────────
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: pw.BoxDecoration(
                      gradient: pw.LinearGradient(
                        colors: [
                          _tint(_purple, 0.95),
                          _tint(_pink, 0.95),
                        ],
                      ),
                      borderRadius: const pw.BorderRadius.only(
                        topLeft: pw.Radius.circular(12),
                        topRight: pw.Radius.circular(12),
                      ),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 5,
                          child: pw.Text('Item',
                              style: pw.TextStyle(
                                  font: bold,
                                  fontSize: 9,
                                  color: _purple)),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text('Size',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                  font: bold,
                                  fontSize: 9,
                                  color: _purple)),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text('Qty',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                  font: bold,
                                  fontSize: 9,
                                  color: _purple)),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text('Price',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                  font: bold,
                                  fontSize: 9,
                                  color: _purple)),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text('Total',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                  font: bold,
                                  fontSize: 9,
                                  color: _pink)),
                        ),
                      ],
                    ),
                  ),
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: const pw.BorderRadius.only(
                        bottomLeft: pw.Radius.circular(12),
                        bottomRight: pw.Radius.circular(12),
                      ),
                      border: pw.Border.all(color: _border, width: 0.5),
                    ),
                    child: pw.Column(
                      children: invoice.items.asMap().entries.map((e) {
                        final item = e.value;
                        final isLast = e.key == invoice.items.length - 1;
                        return pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: pw.BoxDecoration(
                            border: isLast
                                ? null
                                : const pw.Border(
                              bottom: pw.BorderSide(
                                  color: _border, width: 0.3),
                            ),
                          ),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Expanded(
                                flex: 5,
                                child: pw.Column(
                                  crossAxisAlignment:
                                  pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(item.productName,
                                        style: pw.TextStyle(
                                            font: medium,
                                            fontSize: 11,
                                            color: _textDark)),
                                    if (item.itemDiscount > 0) ...[
                                      pw.SizedBox(height: 2),
                                      pw.Text(
                                        '−Rs.${PdfHelpers.fmt(item.itemDiscount)} off',
                                        style: pw.TextStyle(
                                            font: font,
                                            fontSize: 8,
                                            color: _pink),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              pw.Expanded(
                                flex: 1,
                                child: pw.Text(item.size ?? '-',
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(
                                        font: font,
                                        fontSize: 10,
                                        color: _textMedium)),
                              ),
                              pw.Expanded(
                                flex: 1,
                                child: pw.Text('${item.quantity}',
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(
                                        font: medium,
                                        fontSize: 10,
                                        color: _textDark)),
                              ),
                              pw.Expanded(
                                flex: 2,
                                child: pw.Text(
                                    'Rs.${PdfHelpers.fmt(item.unitPrice)}',
                                    textAlign: pw.TextAlign.right,
                                    style: pw.TextStyle(
                                        font: font,
                                        fontSize: 10,
                                        color: _textMedium)),
                              ),
                              pw.Expanded(
                                flex: 2,
                                child: pw.Text(
                                    'Rs.${PdfHelpers.fmt(item.totalPrice)}',
                                    textAlign: pw.TextAlign.right,
                                    style: pw.TextStyle(
                                        font: bold,
                                        fontSize: 11,
                                        color: _purple)),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  pw.SizedBox(height: 18),

                  // ── Totals ────────────────────────────────
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Container(
                        width: 240,
                        padding: const pw.EdgeInsets.all(16),
                        decoration: pw.BoxDecoration(
                          gradient: pw.LinearGradient(
                            begin: pw.Alignment.topLeft,
                            end: pw.Alignment.bottomRight,
                            colors: [_tint(_purple, 0.92), _tint(_pink, 0.92)],
                          ),
                          borderRadius: pw.BorderRadius.circular(12),
                        ),
                        child: pw.Column(
                          children: [
                            _row('Subtotal',
                                'Rs.${PdfHelpers.fmt(invoice.subTotal)}',
                                font, bold),
                            if (invoice.discountAmount > 0)
                              _row(
                                'Discount',
                                '−Rs.${PdfHelpers.fmt(invoice.discountAmount)}',
                                font, bold,
                                valueColor: _red,
                              ),
                            pw.SizedBox(height: 6),
                            pw.Container(height: 1, color: PdfColors.white),
                            pw.SizedBox(height: 6),
                            _row(
                              'Total',
                              'Rs.${PdfHelpers.fmt(invoice.totalAmount)}',
                              bold, bold,
                              isHeader: true,
                            ),
                            pw.SizedBox(height: 8),
                            _row('Paid',
                                'Rs.${PdfHelpers.fmt(invoice.amountPaid)}',
                                font, bold, valueColor: _green),
                            if (invoice.amountDue > 0)
                              _row('Due',
                                  'Rs.${PdfHelpers.fmt(invoice.amountDue)}',
                                  font, bold, valueColor: _red),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (invoice.notes != null &&
                      invoice.notes!.isNotEmpty) ...[
                    pw.SizedBox(height: 18),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: _purpleLight,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.all(4),
                            decoration: pw.BoxDecoration(
                              color: _purple,
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Text('!',
                                style: pw.TextStyle(
                                    font: bold,
                                    fontSize: 9,
                                    color: PdfColors.white)),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Expanded(
                            child: pw.Text(
                              invoice.notes!,
                              style: pw.TextStyle(
                                  font: font,
                                  fontSize: 10,
                                  color: _textMedium),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  pw.Spacer(),

                  // ── Footer ────────────────────────────────
                  pw.Container(
                    padding: const pw.EdgeInsets.all(14),
                    decoration: pw.BoxDecoration(
                      gradient: const pw.LinearGradient(
                        colors: [_purple, _pink],
                      ),
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Thanks for shopping with us!',
                          style: pw.TextStyle(
                              font: bold,
                              fontSize: 12,
                              color: PdfColors.white),
                        ),
                        pw.Text(
                          'MyBillBox',
                          style: pw.TextStyle(
                              font: font,
                              fontSize: 9,
                              color: PdfColors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return pdf;
  }

  static pw.Widget _row(
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
              color: isHeader ? PdfColors.white : _tint(PdfColors.white, 0.9),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: bold,
              fontSize: isHeader ? 15 : 10,
              color: valueColor ?? PdfColors.white,
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