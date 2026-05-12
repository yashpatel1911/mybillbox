import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:mybillbox/DBHelper/app_constant.dart';
import 'package:provider/provider.dart';
import '../../DBHelper/app_colors.dart';
import '../../DBHelper/session_manager.dart';
import '../../provider/profile_provider.dart';
import '../login_screen.dart';
import 'change_password_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _roleColors = {
    'ADMIN': AppColors.red,
    'MANAGER': AppColors.orange,
    'EMPLOYEE': AppColors.primary,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ProfileProvider>().getProfile(),
    );
  }

  Color _roleColor(String r) =>
      _roleColors[r.toUpperCase()] ?? AppColors.primary;

  String _initials(String n) {
    if (n.isEmpty) return '?';
    final parts = n.trim().split(RegExp(r'\s+'));
    return parts.length == 1
        ? parts.first[0].toUpperCase()
        : (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String _date(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      const m = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${d.day} ${m[d.month - 1]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  void _logout() => showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.45),
    builder: (ctx) => _ConfirmDialog(
      icon: Icons.logout_rounded,
      title: 'Sign Out?',
      message: 'You\'ll need to sign in again to access your account.',
      confirmLabel: 'Sign Out',
      onConfirm: () async {
        Navigator.pop(ctx);
        await SessionManager().setPreference('token', '');
        await SessionManager().setPreference('name', '');
        await SessionManager().setPreference('role', '');
        await SessionManager().setPreference('has_shop', '0');
        await SessionManager().setPreference('status', 'Logout');
        if (!mounted) return;
        AppConstant.successMessage('Signed out successfully', context);
        Get.offAll(() => const LoginScreen());
      },
    ),
  );

  void _changePwd() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const ChangePasswordSheet(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Consumer<ProfileProvider>(
        builder: (_, p, __) {
          if (p.loading && p.profile == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (p.profile == null) {
            return _ErrorState(message: p.errorMessage, onRetry: p.getProfile);
          }

          final pr = p.profile!;
          final roleColor = _roleColor(pr.role);
          final shop = pr.shop;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: p.getProfile,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Top bar ──
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                      child: Row(
                        children: [
                          const Text(
                            'Profile',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Material(
                            color: AppColors.cardBg,
                            shape: const CircleBorder(),
                            elevation: 0,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                /* TODO */
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(9),
                                child: Icon(
                                  Icons.edit_rounded,
                                  size: 17,
                                  color: AppColors.textMedium,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Identity card (avatar + name + role + contacts) ──
                      _IdentityCard(
                        initials: _initials(pr.name),
                        name: pr.name,
                        username: pr.username,
                        role: pr.role,
                        isActive: pr.isActive,
                        roleColor: roleColor,
                        mobile: pr.contactNo,
                        email: pr.email,
                      ),

                      const SizedBox(height: 14),

                      // ── Shop card ──
                      if (shop != null) ...[
                        _ShopCard(shop: shop),
                        const SizedBox(height: 16),
                      ],

                      // ── Account details (2x2 grid) ──
                      const _SectionHeader('Account'),
                      const SizedBox(height: 8),
                      _AccountGrid(
                        role: pr.role,
                        roleColor: roleColor,
                        isActive: pr.isActive,
                        memberSince: pr.createdAt != null
                            ? _date(pr.createdAt!)
                            : '-',
                      ),

                      const SizedBox(height: 16),

                      // ── Actions list ──
                      const _SectionHeader('Actions'),
                      const SizedBox(height: 8),
                      _ActionGroup([
                        _ActionRow(
                          icon: Icons.lock_reset_rounded,
                          label: 'Change Password',
                          accent: AppColors.purple,
                          onTap: _changePwd,
                        ),
                        _ActionRow(
                          icon: Icons.support_agent_rounded,
                          label: 'Help & Support',
                          accent: AppColors.primary,
                          onTap: () {
                            /* TODO */
                          },
                        ),
                        _ActionRow(
                          icon: Icons.logout_rounded,
                          label: 'Sign Out',
                          accent: AppColors.red,
                          isDestructive: true,
                          onTap: _logout,
                        ),
                      ]),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// IDENTITY CARD — avatar, name, role pill, contacts
// ════════════════════════════════════════════════════
class _IdentityCard extends StatelessWidget {
  final String initials, name, username, role;
  final bool isActive;
  final Color roleColor;
  final String mobile;
  final String? email;

  const _IdentityCard({
    required this.initials,
    required this.name,
    required this.username,
    required this.role,
    required this.isActive,
    required this.roleColor,
    required this.mobile,
    this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with status dot
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [roleColor, roleColor.withOpacity(0.78)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: roleColor.withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.green : AppColors.textLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.cardBg, width: 2.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Name, username, role pill
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '@$username',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMedium,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Role pill (color-tinted bg, dot, role text)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: roleColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            role.toUpperCase(),
                            style: TextStyle(
                              color: roleColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Contact strip ──
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Column(
              children: [
                Container(height: 0.5, color: AppColors.border),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ContactTile(
                        icon: Icons.phone_rounded,
                        accent: AppColors.green,
                        label: 'MOBILE',
                        value: mobile,
                      ),
                    ),
                    if (email?.isNotEmpty == true) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ContactTile(
                          icon: Icons.mail_rounded,
                          accent: AppColors.orange,
                          label: 'EMAIL',
                          value: email!,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String label, value;

  const _ContactTile({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 13, color: accent),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════
// SHOP CARD — logo (tap-to-zoom), name, compact details
// ════════════════════════════════════════════════════

class _ShopCard extends StatelessWidget {
  final dynamic shop;

  const _ShopCard({required this.shop});

  void _openLogoZoom(BuildContext context) {
    final url = shop.shLogo as String?;
    if (url == null || url.isEmpty) return;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.88),
      builder: (_) =>
          _LogoZoomDialog(imageUrl: url, shopName: shop.shName as String),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLogo = shop.shLogo != null && (shop.shLogo as String).isNotEmpty;
    final hasEmail = shop.shEmail?.isNotEmpty == true;
    final hasGst = shop.gstNo?.isNotEmpty == true;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: AppColors.primary),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header: logo + business label + name ──
                      Row(
                        children: [
                          GestureDetector(
                            onTap: hasLogo
                                ? () => _openLogoZoom(context)
                                : null,
                            child: Hero(
                              tag: 'shop-logo-${shop.shId}',
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(11),
                                  border: hasLogo
                                      ? Border.all(
                                          color: AppColors.border,
                                          width: 0.8,
                                        )
                                      : null,
                                ),
                                clipBehavior: Clip.antiAlias,
                                alignment: Alignment.center,
                                child: hasLogo
                                    ? Image.network(
                                        shop.shLogo as String,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (_, child, prog) {
                                          if (prog == null) return child;
                                          return const Center(
                                            child: SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                              Icons.storefront_rounded,
                                              color: AppColors.primary,
                                              size: 22,
                                            ),
                                      )
                                    : const Icon(
                                        Icons.storefront_rounded,
                                        color: AppColors.primary,
                                        size: 22,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'YOUR BUSINESS',
                                  style: TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  shop.shName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textDark,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      Container(height: 0.5, color: AppColors.border),
                      const SizedBox(height: 10),

                      // ── Address (full-width, can wrap to 2 lines) ──
                      _ShopChip(
                        icon: Icons.location_on_outlined,
                        text: shop.shAddress,
                        maxLines: 2,
                      ),

                      const SizedBox(height: 8),

                      // ── Phone + Email row (or Phone alone) ──
                      Row(
                        children: [
                          Expanded(
                            child: _ShopChip(
                              icon: Icons.phone_outlined,
                              text: shop.shContactNo,
                            ),
                          ),
                          if (hasEmail) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ShopChip(
                                icon: Icons.mail_outline_rounded,
                                text: shop.shEmail!,
                              ),
                            ),
                          ],
                        ],
                      ),

                      // ── GST (own row, full-width) ──
                      if (hasGst) ...[
                        const SizedBox(height: 8),
                        _ShopChip(
                          icon: Icons.receipt_long_outlined,
                          text: 'GST: ${shop.gstNo}',
                        ),
                      ],
                    ],
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

// Updated _ShopChip — now supports multi-line text
class _ShopChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final int maxLines;

  const _ShopChip({required this.icon, required this.text, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1.5),
          child: Icon(icon, size: 13, color: AppColors.textLight),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMedium,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════
// SECTION HEADER (small caps label)
// ════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textLight,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// ACCOUNT GRID — 2x2 tiles
// ════════════════════════════════════════════════════
class _AccountGrid extends StatelessWidget {
  final String role;
  final Color roleColor;
  final bool isActive;
  final String memberSince;

  const _AccountGrid({
    required this.role,
    required this.roleColor,
    required this.isActive,
    required this.memberSince,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.shield_outlined,
                accent: roleColor,
                label: 'ROLE',
                value: role,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: isActive ? Icons.verified_rounded : Icons.block_rounded,
                accent: isActive ? AppColors.green : AppColors.red,
                label: 'STATUS',
                value: isActive ? 'Active' : 'Inactive',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.calendar_today_rounded,
                accent: AppColors.purple,
                label: 'MEMBER SINCE',
                value: memberSince,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: Icons.currency_rupee_rounded,
                accent: AppColors.orange,
                label: 'CURRENCY',
                value: 'INR (₹)',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String label, value;

  const _StatTile({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 14, color: accent),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// ACTION GROUP — grouped list of tappable rows
// ════════════════════════════════════════════════════
class _ActionGroup extends StatelessWidget {
  final List<Widget> children;

  const _ActionGroup(this.children);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: List.generate(
            children.length,
            (i) => Container(
              decoration: BoxDecoration(
                border: i == children.length - 1
                    ? null
                    : const Border(
                        bottom: BorderSide(color: AppColors.border, width: 0.5),
                      ),
              ),
              child: children[i],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDestructive ? AppColors.red : AppColors.textDark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 14, color: accent),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDestructive
                  ? AppColors.red.withOpacity(0.6)
                  : AppColors.textLight,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// LOGO ZOOM DIALOG — full-screen with pinch & pan
// ════════════════════════════════════════════════════
class _LogoZoomDialog extends StatelessWidget {
  final String imageUrl;
  final String shopName;

  const _LogoZoomDialog({required this.imageUrl, required this.shopName});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
          Center(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, prog) {
                  if (prog == null) return child;
                  return const SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 60,
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 70,
            child: Text(
              shopName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: Material(
              color: Colors.white.withOpacity(0.15),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// ERROR STATE
// ════════════════════════════════════════════════════
class _ErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const _ErrorState({this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.red,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load profile',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textLight, fontSize: 12),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// CONFIRM DIALOG
// ════════════════════════════════════════════════════
class _ConfirmDialog extends StatelessWidget {
  final IconData icon;
  final String title, message, confirmLabel;
  final VoidCallback onConfirm;
  final bool isDestructive;

  const _ConfirmDialog({
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
    this.isDestructive = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDestructive ? AppColors.red : AppColors.primary;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack,
        tween: Tween(begin: 0.92, end: 1.0),
        builder: (_, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.06),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [accent, accent.withOpacity(0.78)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.30),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMedium,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.border,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: onConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: accent.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          confirmLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
