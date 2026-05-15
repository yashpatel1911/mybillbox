import 'package:flutter/material.dart';
import 'package:mybillbox/screens/store/invoice/invoice_details/pdf_screens/professional_corporate_pdf_generator.dart';
import '../../../../../DBHelper/app_colors.dart';
import '../../../../../model/invoice_details/invoice_model.dart';
import 'classic_navy_pdf_generator.dart';
import 'colorful_gradient_pdf_generator.dart';
import 'elegant_dark_pdf_generator.dart';
import 'modern_minimal_pdf_generator.dart';

class PdfDesignSelector extends StatelessWidget {
  final InvoiceModel invoice;

  const PdfDesignSelector({super.key, required this.invoice});

  static void show(BuildContext context, InvoiceModel invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PdfDesignSelector(invoice: invoice)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final designs = <_DesignOption>[
      _DesignOption(
        id: 1,
        title: 'Classic Navy',
        subtitle: 'Professional & timeless',
        accentColor: const Color(0xFF1A3C6E),
        icon: Icons.business_center_rounded,
        tag: 'POPULAR',
        tagColor: const Color(0xFF2E7D32),
      ),
      _DesignOption(
        id: 2,
        title: 'Modern Minimal',
        subtitle: 'Clean & sophisticated',
        accentColor: const Color(0xFF000000),
        icon: Icons.crop_square_rounded,
        tag: 'NEW',
        tagColor: const Color(0xFFE65100),
      ),
      _DesignOption(
        id: 3,
        title: 'Elegant Dark',
        subtitle: 'Premium & luxurious',
        accentColor: const Color(0xFFD4AF37),
        icon: Icons.diamond_outlined,
        tag: 'PREMIUM',
        tagColor: const Color(0xFFD4AF37),
      ),
      _DesignOption(
        id: 4,
        title: 'Colorful Gradient',
        subtitle: 'Vibrant & eye-catching',
        accentColor: const Color(0xFF667EEA),
        icon: Icons.gradient_rounded,
        tag: 'TRENDY',
        tagColor: const Color(0xFFEC4899),
      ),
      _DesignOption(
        id: 5,
        title: 'Corporate Pro',
        subtitle: 'Formal & structured',
        accentColor: const Color(0xFFE74C3C),
        icon: Icons.account_balance_rounded,
        tag: 'BUSINESS',
        tagColor: const Color(0xFF2C3E50),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Design',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            Text(
              'Pick a style for your invoice',
              style: TextStyle(fontSize: 11, color: AppColors.textLight),
            ),
          ],
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: designs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final design = designs[index];
          return _DesignCard(
            design: design,
            onTap: () => _openDesign(context, design.id),
          );
        },
      ),
    );
  }

  void _openDesign(BuildContext context, int designId) {
    switch (designId) {
      case 1:
        ClassicNavyPdfGenerator.showPreview(context, invoice);
        break;
      case 2:
        ModernMinimalPdfGenerator.showPreview(context, invoice);
        break;
      case 3:
        ElegantDarkPdfGenerator.showPreview(context, invoice);
        break;
      case 4:
        ColorfulGradientPdfGenerator.showPreview(context, invoice);
        break;
      case 5:
        ProfessionalCorporatePdfGenerator.showPreview(context, invoice);
        break;
    }
  }
}

class _DesignOption {
  final int id;
  final String title;
  final String subtitle;
  final Color accentColor;
  final IconData icon;
  final String tag;
  final Color tagColor;

  _DesignOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
    required this.tag,
    required this.tagColor,
  });
}

class _DesignCard extends StatelessWidget {
  final _DesignOption design;
  final VoidCallback onTap;

  const _DesignCard({required this.design, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // ── Mini PDF preview ──────────────────────────
                  SizedBox(
                    width: 90,
                    height: 116,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: design.accentColor.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _MiniPreview(design: design),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // ── Info ───────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: design.tagColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            design.tag,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: design.tagColor,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          design.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          design.subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              design.icon,
                              size: 14,
                              color: design.accentColor,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Preview & Share',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: design.accentColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: design.accentColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Mini preview thumbnail (visual representation of the design) ──
class _MiniPreview extends StatelessWidget {
  final _DesignOption design;

  const _MiniPreview({required this.design});

  @override
  Widget build(BuildContext context) {
    switch (design.id) {
      case 1:
        return _classicNavyPreview();
      case 2:
        return _modernMinimalPreview();
      case 3:
        return _elegantDarkPreview();
      case 4:
        return _colorfulGradientPreview();
      case 5:
        return _corporateProPreview();
      default:
        return Container(color: Colors.white);
    }
  }

  Widget _classicNavyPreview() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 28,
            color: const Color(0xFF1A3C6E),
            padding: const EdgeInsets.all(5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PAID',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ...List.generate(
            5,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              child: Container(height: 2.5, color: Colors.grey.shade200),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(5),
            child: Container(
              height: 5,
              width: 40,
              color: const Color(0xFF1A3C6E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernMinimalPreview() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 2, width: 24, color: Colors.black),
          const SizedBox(height: 4),
          Container(height: 5, width: 50, color: Colors.black),
          const SizedBox(height: 2),
          Container(height: 2.5, width: 32, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          ...List.generate(
            4,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 2.5),
              child: Container(height: 2, color: Colors.grey.shade300),
            ),
          ),
          const Spacer(),
          Container(height: 1, color: Colors.black),
          const SizedBox(height: 3),
          Container(height: 3.5, width: 32, color: Colors.black),
        ],
      ),
    );
  }

  Widget _elegantDarkPreview() {
    return Container(
      color: const Color(0xFF1C1C2E),
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(height: 4, width: 24, color: const Color(0xFFD4AF37)),
              Container(height: 4, width: 16, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 5),
          Container(height: 0.5, color: const Color(0xFFD4AF37)),
          const SizedBox(height: 5),
          ...List.generate(
            4,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 2.5),
              child: Container(height: 2, color: Colors.white24),
            ),
          ),
          const Spacer(),
          Container(height: 0.5, color: const Color(0xFFD4AF37)),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(height: 5, width: 32, color: const Color(0xFFD4AF37)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _colorfulGradientPreview() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 32,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF667EEA), Color(0xFFEC4899)],
              ),
            ),
            padding: const EdgeInsets.all(5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 4, width: 30, color: Colors.white),
                const SizedBox(height: 2),
                Container(height: 2.5, width: 20, color: Colors.white70),
              ],
            ),
          ),
          const SizedBox(height: 5),
          ...List.generate(
            4,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              child: Container(height: 2, color: Colors.grey.shade300),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(5),
            child: Container(
              height: 5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFFEC4899)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _corporateProPreview() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 24,
            color: const Color(0xFF2C3E50),
            padding: const EdgeInsets.all(5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(height: 3, width: 24, color: Colors.white),
                Container(height: 3, width: 12, color: const Color(0xFFE74C3C)),
              ],
            ),
          ),
          Container(height: 2, color: const Color(0xFFE74C3C)),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                4,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Container(
                    height: 1.5,
                    color: i == 0
                        ? const Color(0xFF2C3E50)
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          Container(
            margin: const EdgeInsets.all(5),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF2C3E50), width: 0.5),
            ),
            child: Container(height: 3, color: const Color(0xFFE74C3C)),
          ),
        ],
      ),
    );
  }
}
