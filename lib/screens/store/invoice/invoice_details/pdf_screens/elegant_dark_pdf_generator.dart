import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../../model/invoice_details/invoice_model.dart';
import 'pdf_shared.dart';

class ElegantDarkPdfGenerator {
  static const _dark = PdfColor.fromInt(0xFF1C1C2E);
  static const _darkSurface = PdfColor.fromInt(0xFF252540);
  static const _gold = PdfColor.fromInt(0xFFD4AF37);
  static const _goldLight = PdfColor.fromInt(0xFFE5C76A);
  static const _white = PdfColor.fromInt(0xFFFFFFFF);
  static const _textWhite = PdfColor.fromInt(0xFFF5F5F5);
  static const _textMuted = PdfColor.fromInt(0xFFAAAAB8);
  static const _divider = PdfColor.fromInt(0xFF3D3D5C);
  static const _green = PdfColor.fromInt(0xFF4ADE80);
  static const _red = PdfColor.fromInt(0xFFF87171);

  static void showPreview(BuildContext context, InvoiceModel invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          invoice: invoice,
          designName: 'Elegant Dark',
          themeColor: const Color(0xFFD4AF37),
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
      default:
        return _gold;
    }
  }

  static Future<pw.Document> buildPdf(InvoiceModel invoice) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.playfairDisplayRegular();
    final bold = await PdfGoogleFonts.playfairDisplayBold();
    final body = await PdfGoogleFonts.nunitoRegular();
    final bodyBold = await PdfGoogleFonts.nunitoBold();

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
        build: (ctx) => pw.Container(
          color: _dark,
          padding: const pw.EdgeInsets.all(36),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Gold ornament top ─────────────────────────
              pw.Row(
                children: [
                  pw.Container(height: 1, width: 50, color: _gold),
                  pw.SizedBox(width: 8),
                  pw.Container(
                    width: 6,
                    height: 6,
                    decoration: pw.BoxDecoration(
                      color: _gold,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(child: pw.Container(height: 1, color: _gold)),
                ],
              ),
              pw.SizedBox(height: 18),

              // ── Header ─────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        if (logoImage != null) ...[
                          pw.Container(
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: _gold, width: 1),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            padding: const pw.EdgeInsets.all(3),
                            child: pw.ClipRRect(
                              horizontalRadius: 2,
                              verticalRadius: 2,
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
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                invoice.shop?.shName ?? 'My Shop',
                                maxLines: 1,
                                overflow: pw.TextOverflow.clip,
                                style: pw.TextStyle(
                                  font: bold,
                                  fontSize: 22,
                                  color: _textWhite,
                                ),
                              ),
                              pw.SizedBox(height: 3),
                              if (invoice.shop?.shAddress?.isNotEmpty == true)
                                pw.Text(
                                  invoice.shop!.shAddress!,
                                  maxLines: 2,
                                  style: pw.TextStyle(
                                    font: body,
                                    fontSize: 8,
                                    color: _textMuted,
                                    lineSpacing: 1.5,
                                  ),
                                ),
                              if (invoice.shop?.shContact?.isNotEmpty == true)
                                pw.Text(
                                  'Tel: ${invoice.shop!.shContact}',
                                  maxLines: 1,
                                  style: pw.TextStyle(
                                    font: body,
                                    fontSize: 8,
                                    color: _textMuted,
                                  ),
                                ),
                              if (invoice.shop?.shGst?.isNotEmpty == true)
                                pw.Text(
                                  'GST: ${invoice.shop!.shGst}',
                                  maxLines: 1,
                                  style: pw.TextStyle(
                                    font: body,
                                    fontSize: 8,
                                    color: _gold,
                                  ),
                                ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                '• EST. INVOICE •',
                                style: pw.TextStyle(
                                  font: body,
                                  fontSize: 8,
                                  color: _gold,
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
                        'INVOICE',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 28,
                          color: _gold,
                          letterSpacing: 4,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        invoice.invoiceNumber,
                        style: pw.TextStyle(
                          font: bodyBold,
                          fontSize: 11,
                          color: _textWhite,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 24),
              pw.Container(height: 0.5, color: _divider),
              pw.SizedBox(height: 24),

              // ── Bill to + meta ─────────────────────────────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('— BILLED TO',
                            style: pw.TextStyle(
                                font: body,
                                fontSize: 8,
                                color: _gold,
                                letterSpacing: 2)),
                        pw.SizedBox(height: 8),
                        pw.Text(invoice.customerName,
                            style: pw.TextStyle(
                                font: bold,
                                fontSize: 16,
                                color: _textWhite)),
                        pw.SizedBox(height: 3),
                        pw.Text(invoice.customerMobile,
                            style: pw.TextStyle(
                                font: body,
                                fontSize: 10,
                                color: _textMuted)),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('— DATE',
                          style: pw.TextStyle(
                              font: body,
                              fontSize: 8,
                              color: _gold,
                              letterSpacing: 2)),
                      pw.SizedBox(height: 8),
                      pw.Text(PdfHelpers.fmtDate(invoice.invoiceDate),
                          style: pw.TextStyle(
                              font: bodyBold,
                              fontSize: 12,
                              color: _textWhite)),
                      pw.SizedBox(height: 10),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                              color: _statusColor(invoice.paymentStatus),
                              width: 1),
                          borderRadius: pw.BorderRadius.circular(2),
                        ),
                        child: pw.Text(
                          PdfHelpers.statusLabel(invoice.paymentStatus),
                          style: pw.TextStyle(
                            font: bodyBold,
                            fontSize: 9,
                            color: _statusColor(invoice.paymentStatus),
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 24),

              // ── Items table ────────────────────────────────
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: _darkSurface,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: _divider, width: 0.5),
                ),
                child: pw.Column(
                  children: [
                    // Header row
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: _gold, width: 0.8),
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 5,
                            child: pw.Text('DESCRIPTION',
                                style: pw.TextStyle(
                                    font: body,
                                    fontSize: 8,
                                    color: _gold,
                                    letterSpacing: 1.5)),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text('SIZE',
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                    font: body,
                                    fontSize: 8,
                                    color: _gold,
                                    letterSpacing: 1.5)),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text('QTY',
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                    font: body,
                                    fontSize: 8,
                                    color: _gold,
                                    letterSpacing: 1.5)),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text('UNIT',
                                textAlign: pw.TextAlign.right,
                                style: pw.TextStyle(
                                    font: body,
                                    fontSize: 8,
                                    color: _gold,
                                    letterSpacing: 1.5)),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text('AMOUNT',
                                textAlign: pw.TextAlign.right,
                                style: pw.TextStyle(
                                    font: body,
                                    fontSize: 8,
                                    color: _gold,
                                    letterSpacing: 1.5)),
                          ),
                        ],
                      ),
                    ),
                    ...invoice.items.asMap().entries.map((e) {
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
                                color: _divider, width: 0.3),
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
                                          font: bodyBold,
                                          fontSize: 11,
                                          color: _textWhite)),
                                  if (item.itemDiscount > 0) ...[
                                    pw.SizedBox(height: 2),
                                    pw.Text(
                                      'Discount −Rs.${PdfHelpers.fmt(item.itemDiscount)}',
                                      style: pw.TextStyle(
                                          font: body,
                                          fontSize: 7,
                                          color: _red),
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
                                      font: body,
                                      fontSize: 10,
                                      color: _textMuted)),
                            ),
                            pw.Expanded(
                              flex: 1,
                              child: pw.Text('${item.quantity}',
                                  textAlign: pw.TextAlign.center,
                                  style: pw.TextStyle(
                                      font: body,
                                      fontSize: 10,
                                      color: _textMuted)),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(
                                  'Rs.${PdfHelpers.fmt(item.unitPrice)}',
                                  textAlign: pw.TextAlign.right,
                                  style: pw.TextStyle(
                                      font: body,
                                      fontSize: 10,
                                      color: _textMuted)),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(
                                  'Rs.${PdfHelpers.fmt(item.totalPrice)}',
                                  textAlign: pw.TextAlign.right,
                                  style: pw.TextStyle(
                                      font: bodyBold,
                                      fontSize: 11,
                                      color: _goldLight)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // ── Totals ─────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 240,
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: _darkSurface,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: _gold, width: 0.5),
                    ),
                    child: pw.Column(
                      children: [
                        _row('Subtotal',
                            'Rs.${PdfHelpers.fmt(invoice.subTotal)}',
                            body, bodyBold),
                        if (invoice.discountAmount > 0)
                          _row(
                            'Discount',
                            '−Rs.${PdfHelpers.fmt(invoice.discountAmount)}',
                            body, bodyBold,
                            valueColor: _red,
                          ),
                        pw.SizedBox(height: 6),
                        pw.Container(height: 0.5, color: _gold),
                        pw.SizedBox(height: 6),
                        _row(
                          'TOTAL',
                          'Rs.${PdfHelpers.fmt(invoice.totalAmount)}',
                          bodyBold, bodyBold,
                          isHeader: true,
                        ),
                        pw.SizedBox(height: 8),
                        _row('Paid',
                            'Rs.${PdfHelpers.fmt(invoice.amountPaid)}',
                            body, bodyBold, valueColor: _green),
                        if (invoice.amountDue > 0)
                          _row('Due',
                              'Rs.${PdfHelpers.fmt(invoice.amountDue)}',
                              body, bodyBold, valueColor: _red),
                      ],
                    ),
                  ),
                ],
              ),

              if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 16),
                pw.Text(
                  '"${invoice.notes}"',
                  style: pw.TextStyle(
                      font: font,
                      fontSize: 10,
                      color: _textMuted,
                      fontStyle: pw.FontStyle.italic),
                ),
              ],

              pw.Spacer(),

              // ── Gold ornament bottom ──────────────────────
              pw.Row(
                children: [
                  pw.Expanded(child: pw.Container(height: 1, color: _gold)),
                  pw.SizedBox(width: 8),
                  pw.Container(
                    width: 6,
                    height: 6,
                    decoration: pw.BoxDecoration(
                      color: _gold,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Container(height: 1, width: 50, color: _gold),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Thank you for your patronage',
                  style: pw.TextStyle(font: font, fontSize: 12, color: _gold),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'MyBillBox',
                  style: pw.TextStyle(
                      font: body, fontSize: 7, color: _textMuted),
                ),
              ),
            ],
          ),
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
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: isHeader ? bold : font,
              fontSize: isHeader ? 11 : 9,
              color: isHeader ? _gold : _textMuted,
              letterSpacing: isHeader ? 1.5 : 0,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: bold,
              fontSize: isHeader ? 15 : 10,
              color: valueColor ?? (isHeader ? _goldLight : _textWhite),
            ),
          ),
        ],
      ),
    );
  }
}