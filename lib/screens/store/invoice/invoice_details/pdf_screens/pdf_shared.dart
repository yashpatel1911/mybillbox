import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../model/invoice_details/invoice_model.dart';
import '../../../../../DBHelper/app_colors.dart';

/// Shared preview screen used by ALL 5 PDF designs.
/// The actual PDF builder function is passed in as a callback.
class PdfPreviewScreen extends StatelessWidget {
  final InvoiceModel invoice;
  final String designName;
  final Color themeColor;
  final Future<pw.Document> Function(InvoiceModel) builder;

  const PdfPreviewScreen({
    super.key,
    required this.invoice,
    required this.designName,
    required this.themeColor,
    required this.builder,
  });

  Future<File> _saveTempPdf() async {
    final doc = await builder(invoice);
    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${invoice.invoiceNumber}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> _sharePdf(BuildContext context) async {
    try {
      final file = await _saveTempPdf();
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
            Text(
              designName,
              style: const TextStyle(
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
          IconButton(
            onPressed: () => _sharePdf(context),
            tooltip: 'Share PDF',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.share_rounded,
                color: themeColor,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: PdfPreview(
        build: (format) async => (await builder(invoice)).save(),
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

/// Shared formatting helpers used by all designs
class PdfHelpers {
  static String fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(
    RegExp(r'(\d)(?=(\d{2})+(\d)\b)'),
        (m) => '${m[1]},',
  );

  static String fmtDate(String d) {
    try {
      final dt = DateTime.parse(d);
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
    } catch (_) {
      return d;
    }
  }

  static String statusLabel(String s) {
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
}