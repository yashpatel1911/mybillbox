import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mybillbox/screens/store/category/category_page.dart';
import 'package:mybillbox/screens/store/invoice/purchase_screen.dart';
import 'package:mybillbox/screens/store/products/product_page.dart';
import '../../../DBHelper/app_colors.dart';
import '../expense_ui/expense_categories_screen.dart';
import '../expense_ui/expenses_screen.dart';

class StoreManagementScreen extends StatelessWidget {
  const StoreManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.pageBg,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Store Management',
          style: GoogleFonts.lato(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Text(
              'Manage your store',
              style: GoogleFonts.lato(
                color: AppColors.textDark,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Everything you need in one place',
              style: GoogleFonts.lato(
                color: AppColors.textLight,
                fontSize: 11.5,
              ),
            ),
            const SizedBox(height: 18),

            // ── Row 1 ──
            Row(
              children: [
                Expanded(
                  child: _PremiumCard(
                    icon: Icons.category_rounded,
                    title: 'Categories',
                    subtitle: 'Organize products',
                    gradientStart: const Color(0xFF667EEA),
                    gradientEnd: const Color(0xFF764BA2),
                    onTap: () => Get.to(() => CategoryPage()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PremiumCard(
                    icon: Icons.inventory_2_rounded,
                    title: 'Products',
                    subtitle: 'Manage inventory',
                    gradientStart: const Color(0xFF00C9A7),
                    gradientEnd: const Color(0xFF00A8CC),
                    onTap: () =>
                        Get.to(() => ProductPage(catId: 0, categoryName: '')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Row 2 ──
            Row(
              children: [
                Expanded(
                  child: _PremiumCard(
                    icon: Icons.receipt_long_rounded,
                    title: 'Expense Types',
                    subtitle: 'Categorize spending',
                    gradientStart: const Color(0xFFFF9966),
                    gradientEnd: const Color(0xFFFF5E62),
                    onTap: () => Get.to(() => const ExpenseCategoriesScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PremiumCard(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Expenses',
                    subtitle: 'Track spending',
                    gradientStart: const Color(0xFFFF6A88),
                    gradientEnd: const Color(0xFFD32F2F),
                    onTap: () => Get.to(() => const ExpensesScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Row 3 ──
            Row(
              children: [
                Expanded(
                  child: _PremiumCard(
                    icon: Icons.shopping_cart_rounded,
                    title: 'Purchases',
                    subtitle: 'Stock & vendors',
                    gradientStart: const Color(0xFF5B86E5),
                    gradientEnd: const Color(0xFF36D1DC),
                    onTap: () {
                      Get.to(() => const PurchaseScreen());
                    },
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Premium gradient card with subtle pattern
// ─────────────────────────────────────────
class _PremiumCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color gradientStart;
  final Color gradientEnd;
  final VoidCallback onTap;

  const _PremiumCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientStart,
    required this.gradientEnd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: Colors.white.withOpacity(0.2),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [gradientStart, gradientEnd],
            ),
            boxShadow: [
              BoxShadow(
                color: gradientEnd.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Stack(
            children: [
              // ── Decorative circles ──
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -10,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),

              // ── Content ──
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icon container
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),

                    // Text
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.lato(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.lato(
                            fontSize: 10.5,
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Arrow indicator (top-right) ──
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_outward_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
