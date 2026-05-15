import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../../model/invoice_details/invoice_model.dart';
import 'pdf_shared.dart';

class ProfessionalCorporatePdfGenerator {
  static const _primary = PdfColor.fromInt(0xFF2C3E50);
  static const _accent = PdfColor.fromInt(0xFFE74C3C);
  static const _bg = PdfColor.fromInt(0xFFECF0F1);
  static const _bgLight = PdfColor.fromInt(0xFFF8F9FA);
  static const _textDark = PdfColor.fromInt(0xFF2C3E50);
  static const _textMedium = PdfColor.fromInt(0xFF7F8C8D);
  static const _textLight = PdfColor.fromInt(0xFFBDC3C7);
  static const _border = PdfColor.fromInt(0xFFE0E0E0);
  static const _green = PdfColor.fromInt(0xFF27AE60);
  static const _amber = PdfColor.fromInt(0xFFF39C12);

  static void showPreview(BuildContext context, InvoiceModel invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          invoice: invoice,
          designName: 'Corporate Pro',
          themeColor: const Color(0xFF2C3E50),
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
        return _accent;
      default:
        return _amber;
    }
  }

  static Future<pw.Document> buildPdf(InvoiceModel invoice) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final medium = await PdfGoogleFonts.robotoMedium();
    final bold = await PdfGoogleFonts.robotoBold();

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
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Top header bar ──────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 36, vertical: 22),
              decoration: const pw.BoxDecoration(color: _primary),
              child: pw.Row(
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
                            padding: const pw.EdgeInsets.all(3),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: pw.BorderRadius.circular(2),
                            ),
                            child: pw.ClipRRect(
                              horizontalRadius: 0,
                              verticalRadius: 0,
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
                                  fontSize: 20,
                                  color: PdfColors.white,
                                ),
                              ),
                              pw.SizedBox(height: 3),
                              pw.Container(
                                height: 2,
                                width: 40,
                                color: _accent,
                              ),
                              pw.SizedBox(height: 4),
                              if (invoice.shop?.shAddress?.isNotEmpty == true)
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
                              if (invoice.shop?.shContact?.isNotEmpty == true)
                                pw.Text(
                                  'Tel: ${invoice.shop!.shContact}',
                                  maxLines: 1,
                                  style: pw.TextStyle(
                                    font: font,
                                    fontSize: 8,
                                    color: PdfColors.white,
                                  ),
                                ),
                              if (invoice.shop?.shGst?.isNotEmpty == true)
                                pw.Text(
                                  'GSTIN: ${invoice.shop!.shGst}',
                                  maxLines: 1,
                                  style: pw.TextStyle(
                                    font: medium,
                                    fontSize: 8,
                                    color: _accent,
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
                          font: bold,
                          fontSize: 28,
                          color: PdfColors.white,
                          letterSpacing: 6,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ── Red accent stripe ───────────────────────────
            pw.Container(height: 4, color: _accent),

            pw.Padding(
              padding: const pw.EdgeInsets.all(36),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // ── Meta row (Invoice #, Date, Status) ────
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: _metaCard('INVOICE NO.', invoice.invoiceNumber,
                            medium, bold),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        child: _metaCard(
                            'DATE',
                            PdfHelpers.fmtDate(invoice.invoiceDate),
                            medium,
                            bold),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(12),
                          decoration: pw.BoxDecoration(
                            color: _statusColor(invoice.paymentStatus),
                            borderRadius: pw.BorderRadius.circular(2),
                          ),
                          child: pw.Column(
                            crossAxisAlignment:
                            pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('STATUS',
                                  style: pw.TextStyle(
                                      font: medium,
                                      fontSize: 7,
                                      color: PdfColors.white,
                                      letterSpacing: 1.5)),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                PdfHelpers.statusLabel(invoice.paymentStatus),
                                style: pw.TextStyle(
                                  font: bold,
                                  fontSize: 13,
                                  color: PdfColors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 22),

                  // ── Bill To section ───────────────────────
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: _bgLight,
                      border: pw.Border(
                        left: pw.BorderSide(color: _accent, width: 3),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('BILL TO',
                            style: pw.TextStyle(
                                font: bold,
                                fontSize: 8,
                                color: _accent,
                                letterSpacing: 2)),
                        pw.SizedBox(height: 6),
                        pw.Text(invoice.customerName,
                            style: pw.TextStyle(
                                font: bold,
                                fontSize: 14,
                                color: _textDark)),
                        pw.SizedBox(height: 2),
                        pw.Text('Mobile: ${invoice.customerMobile}',
                            style: pw.TextStyle(
                                font: font,
                                fontSize: 10,
                                color: _textMedium)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 22),

                  // ── Items table ───────────────────────────
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: _primary, width: 1),
                    ),
                    child: pw.Table(
                      columnWidths: {
                        0: const pw.FlexColumnWidth(3.5),
                        1: const pw.FixedColumnWidth(50),
                        2: const pw.FixedColumnWidth(40),
                        3: const pw.FixedColumnWidth(70),
                        4: const pw.FixedColumnWidth(70),
                      },
                      children: [
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(color: _primary),
                          children: [
                            _th('DESCRIPTION', bold),
                            _th('SIZE', bold, center: true),
                            _th('QTY', bold, center: true),
                            _th('RATE', bold, right: true),
                            _th('AMOUNT', bold, right: true),
                          ],
                        ),
                        ...invoice.items.asMap().entries.map((e) {
                          final item = e.value;
                          final bg =
                          e.key.isEven ? PdfColors.white : _bgLight;
                          return pw.TableRow(
                            decoration: pw.BoxDecoration(
                              color: bg,
                              border: const pw.Border(
                                bottom: pw.BorderSide(
                                    color: _border, width: 0.5),
                              ),
                            ),
                            children: [
                              _td(item.productName, medium,
                                  sub: item.itemDiscount > 0
                                      ? 'Discount: −Rs.${PdfHelpers.fmt(item.itemDiscount)}'
                                      : null),
                              _td(item.size ?? '-', font, center: true),
                              _td('${item.quantity}', font, center: true),
                              _td('Rs.${PdfHelpers.fmt(item.unitPrice)}', font,
                                  right: true),
                              _td('Rs.${PdfHelpers.fmt(item.totalPrice)}',
                                  bold,
                                  right: true),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 22),

                  // ── Totals (side by side: notes + totals) ─
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: invoice.notes != null &&
                            invoice.notes!.isNotEmpty
                            ? pw.Container(
                          padding: const pw.EdgeInsets.all(12),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                                color: _border, width: 0.5),
                          ),
                          child: pw.Column(
                            crossAxisAlignment:
                            pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('NOTES',
                                  style: pw.TextStyle(
                                      font: bold,
                                      fontSize: 8,
                                      color: _primary,
                                      letterSpacing: 1.5)),
                              pw.SizedBox(height: 6),
                              pw.Text(invoice.notes!,
                                  style: pw.TextStyle(
                                      font: font,
                                      fontSize: 9,
                                      color: _textMedium)),
                            ],
                          ),
                        )
                            : pw.SizedBox(),
                      ),
                      pw.SizedBox(width: 16),
                      pw.Expanded(
                        flex: 4,
                        child: pw.Container(
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: _primary, width: 1),
                          ),
                          child: pw.Column(
                            children: [
                              _trStripe('Subtotal',
                                  'Rs.${PdfHelpers.fmt(invoice.subTotal)}',
                                  font, medium,
                                  bg: PdfColors.white),
                              if (invoice.discountAmount > 0)
                                _trStripe(
                                  'Discount',
                                  '−Rs.${PdfHelpers.fmt(invoice.discountAmount)}',
                                  font, medium,
                                  bg: _bgLight, valueColor: _accent,
                                ),
                              _trStripe(
                                'GRAND TOTAL',
                                'Rs.${PdfHelpers.fmt(invoice.totalAmount)}',
                                bold, bold,
                                bg: _primary,
                                labelColor: PdfColors.white,
                                valueColor: PdfColors.white,
                                isHeader: true,
                              ),
                              _trStripe(
                                'Amount Paid',
                                'Rs.${PdfHelpers.fmt(invoice.amountPaid)}',
                                font, medium,
                                bg: PdfColors.white, valueColor: _green,
                              ),
                              if (invoice.amountDue > 0)
                                _trStripe(
                                  'Amount Due',
                                  'Rs.${PdfHelpers.fmt(invoice.amountDue)}',
                                  font, medium,
                                  bg: _bgLight, valueColor: _accent,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 30),

                  // ── Signature line ────────────────────────
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Container(height: 0.5, width: 150, color: _primary),
                          pw.SizedBox(height: 4),
                          pw.Text('Authorized Signature',
                              style: pw.TextStyle(
                                  font: medium,
                                  fontSize: 9,
                                  color: _textMedium)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.Spacer(),

            // ── Footer bar ────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 36, vertical: 14),
              decoration: const pw.BoxDecoration(color: _primary),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Thank you for your business',
                    style: pw.TextStyle(
                        font: bold,
                        fontSize: 11,
                        color: PdfColors.white,
                        letterSpacing: 0.5),
                  ),
                  pw.Text(
                    'Generated by MyBillBox',
                    style: pw.TextStyle(
                        font: font, fontSize: 8, color: _textLight),
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

  // ── Meta card (Invoice #, Date) ────────────────────────────────
  static pw.Widget _metaCard(
      String label, String value, pw.Font medium, pw.Font bold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _bg,
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  font: medium,
                  fontSize: 7,
                  color: _textMedium,
                  letterSpacing: 1.5)),
          pw.SizedBox(height: 4),
          pw.Text(value,
              style:
              pw.TextStyle(font: bold, fontSize: 13, color: _textDark)),
        ],
      ),
    );
  }

  static pw.Widget _th(String text, pw.Font bold,
      {bool center = false, bool right = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      alignment: right
          ? pw.Alignment.centerRight
          : center
          ? pw.Alignment.center
          : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(
            font: bold,
            fontSize: 8,
            color: PdfColors.white,
            letterSpacing: 1.2),
      ),
    );
  }

  static pw.Widget _td(String text, pw.Font font,
      {bool center = false, bool right = false, String? sub}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
              style: pw.TextStyle(font: font, fontSize: 10, color: _textDark)),
          if (sub != null) ...[
            pw.SizedBox(height: 2),
            pw.Text(sub,
                style:
                pw.TextStyle(font: font, fontSize: 7, color: _accent)),
          ],
        ],
      ),
    );
  }

  static pw.Widget _trStripe(
      String label,
      String value,
      pw.Font font,
      pw.Font bold, {
        required PdfColor bg,
        PdfColor? labelColor,
        PdfColor? valueColor,
        bool isHeader = false,
      }) {
    return pw.Container(
      color: bg,
      padding:
      const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                font: isHeader ? bold : font,
                fontSize: isHeader ? 11 : 10,
                color: labelColor ?? _textMedium,
                letterSpacing: isHeader ? 1 : 0,
              )),
          pw.Text(value,
              style: pw.TextStyle(
                font: bold,
                fontSize: isHeader ? 14 : 11,
                color: valueColor ?? _textDark,
              )),
        ],
      ),
    );
  }
}