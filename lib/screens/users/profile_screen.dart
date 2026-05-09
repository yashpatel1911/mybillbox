import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../DBHelper/app_colors.dart';
import '../../provider/profile_provider.dart';
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
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day} ${m[d.month - 1]} ${d.year}';
    } catch (_) { return iso; }
  }

  void _logout() => showDialog(
    context: context,
    builder: (ctx) => _ConfirmDialog(
      icon: Icons.logout_rounded,
      title: 'Sign Out?',
      message: 'You will need to log in again.',
      confirmLabel: 'Sign Out',
      onConfirm: () {
        Navigator.pop(ctx);
        // TODO: SessionManager().clear(); Get.offAll(LoginScreen());
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
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (p.profile == null) {
            return _ErrorState(message: p.errorMessage, onRetry: p.getProfile);
          }

          final pr = p.profile!;
          final color = _roleColor(pr.role);
          final shop = pr.shop;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: p.getProfile,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Hero header ──
                SliverToBoxAdapter(
                  child: _HeroHeader(
                    initials: _initials(pr.name),
                    name: pr.name,
                    username: pr.username,
                    role: pr.role,
                    isActive: pr.isActive,
                    color: color,
                    onEdit: () {/* TODO */},
                  ),
                ),

                // ── Quick contact strip ──
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -22),
                    child: _QuickContactStrip(
                      mobile: pr.contactNo,
                      email: pr.email,
                    ),
                  ),
                ),

                // ── Body ──
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Shop card (admin only) — featured prominently
                      if (shop != null) ...[
                        _ShopCard(shop: shop, accent: color),
                        const SizedBox(height: 18),
                      ],

                      _SectionHeader('Account Details'),
                      _DetailGroup([
                        _DetailRow(
                          icon: Icons.badge_outlined,
                          label: 'Role',
                          value: pr.role,
                          accent: color,
                        ),
                        _DetailRow(
                          icon: pr.isActive
                              ? Icons.verified_rounded
                              : Icons.block_rounded,
                          label: 'Status',
                          value: pr.isActive ? 'Active' : 'Inactive',
                          accent: pr.isActive ? AppColors.green : AppColors.red,
                        ),
                        if (pr.createdAt != null)
                          _DetailRow(
                            icon: Icons.event_rounded,
                            label: 'Member Since',
                            value: _date(pr.createdAt!),
                            accent: AppColors.purple,
                          ),
                      ]),

                      const SizedBox(height: 18),
                      _SectionHeader('Preferences'),
                      _DetailGroup([
                        _DetailRow(
                          icon: Icons.dark_mode_outlined,
                          label: 'Theme',
                          value: 'Light',
                          accent: AppColors.primary,
                        ),
                        _DetailRow(
                          icon: Icons.translate_rounded,
                          label: 'Language',
                          value: 'English',
                          accent: AppColors.green,
                        ),
                        _DetailRow(
                          icon: Icons.attach_money_rounded,
                          label: 'Currency',
                          value: 'INR (₹)',
                          accent: AppColors.orange,
                        ),
                      ]),

                      const SizedBox(height: 18),
                      _SectionHeader('Account'),
                      _ActionGroup([
                        _ActionRow(
                          icon: Icons.lock_reset_rounded,
                          label: 'Change Password',
                          subtitle: 'Update your account password',
                          accent: AppColors.purple,
                          onTap: _changePwd,
                        ),
                        _ActionRow(
                          icon: Icons.support_agent_rounded,
                          label: 'Help & Support',
                          subtitle: 'Get help with your account',
                          accent: AppColors.cyan,
                          onTap: () {/* TODO */},
                        ),
                        _ActionRow(
                          icon: Icons.logout_rounded,
                          label: 'Sign Out',
                          subtitle: 'Log out from this device',
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
// HERO HEADER — gradient banner with floating avatar
// ════════════════════════════════════════════════════
class _HeroHeader extends StatelessWidget {
  final String initials, name, username, role;
  final bool isActive;
  final Color color;
  final VoidCallback onEdit;

  const _HeroHeader({
    required this.initials,
    required this.name,
    required this.username,
    required this.role,
    required this.isActive,
    required this.color,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
        20,
        46,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.18), color.withOpacity(0.04)],
        ),
      ),
      child: Column(children: [
        // Top bar
        Row(children: [
          const Text('Profile',
              style: TextStyle(
                  color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w700)),
          const Spacer(),
          Material(
            color: AppColors.cardBg,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onEdit,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.edit_rounded, size: 18, color: AppColors.textMedium),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 22),

        // Avatar with status ring
        Stack(alignment: Alignment.center, children: [
          // Outer subtle ring
          Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.25), width: 2),
            ),
          ),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.7)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 16, offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(initials,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800, fontSize: 28)),
          ),
          // Status dot
          Positioned(
            bottom: 4, right: 4,
            child: Container(
              width: 18, height: 18,
              decoration: BoxDecoration(
                color: isActive ? AppColors.green : AppColors.red,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.pageBg, width: 2.5),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // Name
        Text(name,
            style: const TextStyle(
                color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),

        // Username
        Text('@$username',
            style: const TextStyle(
                color: AppColors.textMedium, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),

        // Role pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 8, offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(role,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700,
                    fontSize: 11, letterSpacing: 0.5)),
          ]),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════
// QUICK CONTACT STRIP — floats over header bottom
// ════════════════════════════════════════════════════
class _QuickContactStrip extends StatelessWidget {
  final String mobile;
  final String? email;
  const _QuickContactStrip({required this.mobile, this.email});

  @override
  Widget build(BuildContext context) {
    final hasEmail = email?.isNotEmpty == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(children: [
        Expanded(child: _ContactItem(
          icon: Icons.phone_rounded,
          color: AppColors.green,
          label: 'Mobile',
          value: mobile,
        )),
        if (hasEmail) ...[
          Container(width: 1, height: 32, color: AppColors.border),
          Expanded(child: _ContactItem(
            icon: Icons.mail_rounded,
            color: AppColors.orange,
            label: 'Email',
            value: email!,
          )),
        ],
      ]),
    );
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  const _ContactItem({
    required this.icon, required this.color,
    required this.label, required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textLight, fontSize: 10.5,
                    fontWeight: FontWeight.w500, letterSpacing: 0.3)),
            const SizedBox(height: 1),
            Text(value,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════
// SHOP CARD — featured admin-only block
// ════════════════════════════════════════════════════
class _ShopCard extends StatelessWidget {
  final dynamic shop; // ShopModel
  final Color accent;
  const _ShopCard({required this.shop, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: [
        // Header band
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [accent.withOpacity(0.12), accent.withOpacity(0.04)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.18),
                    blurRadius: 8, offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(Icons.storefront_rounded, color: accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(shop.shName,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textDark, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                const Text('YOUR BUSINESS',
                    style: TextStyle(
                        color: AppColors.textLight, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 0.6)),
              ]),
            ),
          ]),
        ),

        // Details
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(children: [
            _ShopRow(Icons.location_on_outlined, shop.shAddress, isMultiline: true),
            const SizedBox(height: 10),
            _ShopRow(Icons.phone_outlined, shop.shContactNo),
            if (shop.shEmail?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              _ShopRow(Icons.mail_outline_rounded, shop.shEmail!),
            ],
            if (shop.gstNo?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              _ShopRow(Icons.receipt_long_outlined, 'GST: ${shop.gstNo}'),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _ShopRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isMultiline;
  const _ShopRow(this.icon, this.text, {this.isMultiline = false});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: 1),
        child: Icon(icon, size: 15, color: AppColors.textLight),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(text,
            maxLines: isMultiline ? 2 : 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: AppColors.textDark, fontSize: 13,
                fontWeight: FontWeight.w500, height: 1.4)),
      ),
    ]);
  }
}

// ════════════════════════════════════════════════════
// SECTION HEADER
// ════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
      child: Text(title.toUpperCase(),
          style: const TextStyle(
              color: AppColors.textLight, fontSize: 10.5,
              fontWeight: FontWeight.w700, letterSpacing: 0.8)),
    );
  }
}

// ════════════════════════════════════════════════════
// DETAIL GROUP — read-only rows
// ════════════════════════════════════════════════════
class _DetailGroup extends StatelessWidget {
  final List<Widget> children;
  const _DetailGroup(this.children);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        children: List.generate(children.length, (i) => Container(
          decoration: BoxDecoration(
            border: i == children.length - 1
                ? null
                : const Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
          ),
          child: children[i],
        )),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color accent;
  const _DetailRow({
    required this.icon, required this.label,
    required this.value, required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: accent),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.textMedium, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        Text(value,
            style: const TextStyle(
                color: AppColors.textDark, fontSize: 13.5, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════
// ACTION GROUP — tappable rows with subtitle
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
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        children: List.generate(children.length, (i) => Container(
          decoration: BoxDecoration(
            border: i == children.length - 1
                ? null
                : const Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
          ),
          child: children[i],
        )),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color accent;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDestructive ? AppColors.red : AppColors.textDark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(
                      color: textColor, fontSize: 13.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(color: AppColors.textLight, fontSize: 11.5)),
            ]),
          ),
          Icon(Icons.chevron_right_rounded,
              color: isDestructive
                  ? AppColors.red.withOpacity(0.6)
                  : AppColors.textLight,
              size: 18),
        ]),
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.10), shape: BoxShape.circle),
            child: const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 32),
          ),
          const SizedBox(height: 12),
          const Text('Could not load profile',
              style: TextStyle(
                  color: AppColors.textDark, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(message ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ]),
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

  const _ConfirmDialog({
    required this.icon, required this.title,
    required this.message, required this.confirmLabel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.red, size: 26),
          ),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textLight, fontSize: 12.5, height: 1.4)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(confirmLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}