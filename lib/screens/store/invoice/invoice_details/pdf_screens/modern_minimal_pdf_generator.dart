import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../../model/invoice_details/invoice_model.dart';
import 'pdf_shared.dart';

class ModernMinimalPdfGenerator {
  static const _black = PdfColor.fromInt(0xFF000000);
  static const _darkGrey = PdfColor.fromInt(0xFF1A1A1A);
  static const _mediumGrey = PdfColor.fromInt(0xFF666666);
  static const _lightGrey = PdfColor.fromInt(0xFFAAAAAA);
  static const _borderGrey = PdfColor.fromInt(0xFFEAEAEA);
  static const _bgGrey = PdfColor.fromInt(0xFFFAFAFA);
  static const _green = PdfColor.fromInt(0xFF10B981);
  static const _red = PdfColor.fromInt(0xFFEF4444);
  static const _amber = PdfColor.fromInt(0xFFF59E0B);

  static void showPreview(BuildContext context, InvoiceModel invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          invoice: invoice,
          designName: 'Modern Minimal',
          themeColor: const Color(0xFF000000),
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
    final font = await PdfGoogleFonts.interRegular();
    final medium = await PdfGoogleFonts.interMedium();
    final bold = await PdfGoogleFonts.interBold();

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
        margin: const pw.EdgeInsets.all(48),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Top accent line ─────────────────────────────
            pw.Container(height: 3, width: 60, color: _black),
            pw.SizedBox(height: 20),

            // ── Header ──────────────────────────────────────
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (logoImage != null) ...[
                        pw.ClipRRect(
                          horizontalRadius: 4,
                          verticalRadius: 4,
                          child: pw.Image(
                            logoImage,
                            width: 44,
                            height: 44,
                            fit: pw.BoxFit.cover,
                          ),
                        ),
                        pw.SizedBox(width: 12),
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
                                color: _darkGrey,
                                letterSpacing: -0.5,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            if (invoice.shop?.shAddress?.isNotEmpty == true)
                              pw.Text(
                                invoice.shop!.shAddress!,
                                maxLines: 2,
                                style: pw.TextStyle(
                                  font: font,
                                  fontSize: 9,
                                  color: _mediumGrey,
                                  lineSpacing: 1.5,
                                ),
                              ),
                            if (invoice.shop?.shContact?.isNotEmpty == true ||
                                invoice.shop?.shGst?.isNotEmpty == true)
                              pw.Text(
                                [
                                  if (invoice.shop?.shContact?.isNotEmpty ==
                                      true)
                                    invoice.shop!.shContact!,
                                  if (invoice.shop?.shGst?.isNotEmpty == true)
                                    'GST ${invoice.shop!.shGst}',
                                ].join('  ·  '),
                                maxLines: 1,
                                style: pw.TextStyle(
                                  font: font,
                                  fontSize: 9,
                                  color: _mediumGrey,
                                ),
                              ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'INVOICE',
                              style: pw.TextStyle(
                                font: medium,
                                fontSize: 9,
                                color: _lightGrey,
                                letterSpacing: 4,
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
                      '#${invoice.invoiceNumber}',
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: 16,
                        color: _darkGrey,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      PdfHelpers.fmtDate(invoice.invoiceDate),
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 10,
                        color: _mediumGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 36),

            // ── Bill To / Status side by side ───────────────
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BILLED TO',
                        style: pw.TextStyle(
                          font: medium,
                          fontSize: 8,
                          color: _lightGrey,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        invoice.customerName,
                        style: pw.TextStyle(
                          font: bold,
                          fontSize: 14,
                          color: _darkGrey,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        invoice.customerMobile,
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                          color: _mediumGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'STATUS',
                        style: pw.TextStyle(
                          font: medium,
                          fontSize: 8,
                          color: _lightGrey,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 8,
                            height: 8,
                            decoration: pw.BoxDecoration(
                              color: _statusColor(invoice.paymentStatus),
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.SizedBox(width: 6),
                          pw.Text(
                            PdfHelpers.statusLabel(invoice.paymentStatus),
                            style: pw.TextStyle(
                              font: bold,
                              fontSize: 13,
                              color: _statusColor(invoice.paymentStatus),
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 36),

            // ── Items ───────────────────────────────────────
            pw.Container(height: 1, color: _black),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 10),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 5,
                    child: pw.Text('ITEM',
                        style: pw.TextStyle(
                            font: medium,
                            fontSize: 8,
                            color: _lightGrey,
                            letterSpacing: 1.5)),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text('SIZE',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                            font: medium,
                            fontSize: 8,
                            color: _lightGrey,
                            letterSpacing: 1.5)),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text('QTY',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                            font: medium,
                            fontSize: 8,
                            color: _lightGrey,
                            letterSpacing: 1.5)),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('PRICE',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            font: medium,
                            fontSize: 8,
                            color: _lightGrey,
                            letterSpacing: 1.5)),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('TOTAL',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            font: medium,
                            fontSize: 8,
                            color: _lightGrey,
                            letterSpacing: 1.5)),
                  ),
                ],
              ),
            ),
            pw.Container(height: 0.5, color: _borderGrey),

            ...invoice.items.map((item) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 12),
              child: pw.Column(
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 5,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(item.productName,
                                style: pw.TextStyle(
                                    font: medium,
                                    fontSize: 11,
                                    color: _darkGrey)),
                            if (item.itemDiscount > 0) ...[
                              pw.SizedBox(height: 2),
                              pw.Text(
                                '−Rs.${PdfHelpers.fmt(item.itemDiscount)} discount',
                                style: pw.TextStyle(
                                    font: font,
                                    fontSize: 8,
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
                                font: font,
                                fontSize: 10,
                                color: _mediumGrey)),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text('${item.quantity}',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                                font: font,
                                fontSize: 10,
                                color: _mediumGrey)),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                            'Rs.${PdfHelpers.fmt(item.unitPrice)}',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                                font: font,
                                fontSize: 10,
                                color: _mediumGrey)),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                            'Rs.${PdfHelpers.fmt(item.totalPrice)}',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                                font: medium,
                                fontSize: 11,
                                color: _darkGrey)),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Container(height: 0.5, color: _borderGrey),
                ],
              ),
            )),

            pw.SizedBox(height: 20),

            // ── Totals ──────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.SizedBox(
                  width: 240,
                  child: pw.Column(
                    children: [
                      _row('Subtotal',
                          'Rs.${PdfHelpers.fmt(invoice.subTotal)}',
                          font, medium),
                      if (invoice.discountAmount > 0)
                        _row(
                          'Discount',
                          '−Rs.${PdfHelpers.fmt(invoice.discountAmount)}',
                          font,
                          medium,
                          valueColor: _red,
                        ),
                      pw.SizedBox(height: 8),
                      pw.Container(height: 1, color: _black),
                      pw.SizedBox(height: 8),
                      _row(
                        'Total',
                        'Rs.${PdfHelpers.fmt(invoice.totalAmount)}',
                        bold,
                        bold,
                        isHeader: true,
                      ),
                      pw.SizedBox(height: 12),
                      _row('Paid',
                          'Rs.${PdfHelpers.fmt(invoice.amountPaid)}',
                          font, medium, valueColor: _green),
                      if (invoice.amountDue > 0)
                        _row('Due',
                            'Rs.${PdfHelpers.fmt(invoice.amountDue)}',
                            font, medium, valueColor: _red),
                    ],
                  ),
                ),
              ],
            ),

            if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
              pw.SizedBox(height: 24),
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: _bgGrey,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'NOTES',
                      style: pw.TextStyle(
                        font: medium,
                        fontSize: 8,
                        color: _lightGrey,
                        letterSpacing: 2,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      invoice.notes!,
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 10,
                        color: _mediumGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            pw.Spacer(),
            pw.Container(height: 1, color: _borderGrey),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Thank you.',
                  style: pw.TextStyle(
                      font: bold, fontSize: 11, color: _darkGrey),
                ),
                pw.Text(
                  'MyBillBox',
                  style: pw.TextStyle(
                      font: font, fontSize: 8, color: _lightGrey),
                ),
              ],
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
      pw.Font medium, {
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
              font: isHeader ? medium : font,
              fontSize: isHeader ? 12 : 10,
              color: isHeader ? _darkGrey : _mediumGrey,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: medium,
              fontSize: isHeader ? 16 : 10,
              color: valueColor ?? (isHeader ? _darkGrey : _mediumGrey),
            ),
          ),
        ],
      ),
    );
  }
}