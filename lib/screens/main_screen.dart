import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mybillbox/screens/store/employee/employees_screen.dart';
import 'package:mybillbox/screens/store/store_management_screen.dart';
import 'package:mybillbox/screens/users/profile_screen.dart';
import 'package:provider/provider.dart';
import '../DBHelper/app_colors.dart';
import '../DBHelper/session_manager.dart'; // ⚠️ adjust import to your SessionManager path
import '../provider/category_provider.dart';
import '../provider/product_provider.dart';
import 'dashboard_screen.dart';
import 'other_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _idx = 0;

  // ── All possible nav items ──
  static const _allItems = [
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _NavItem(Icons.storefront_rounded, Icons.receipt_rounded, 'Store'),
    _NavItem(Icons.people_outline, Icons.people_rounded, 'Customers'),
    _NavItem(Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Reports'),
    _NavItem(Icons.person_outline, Icons.person_rounded, 'Profile'),
  ];

  // ── All possible screens (same order as _allItems) ──
  static const _allScreens = [
    DashboardScreen(),
    StoreManagementScreen(),
    EmployeesScreen(),
    ReportsScreen(),
    ProfileScreen(),
  ];

  // ── Role-based filtered lists ──
  bool get _isAdmin => SessionManager().role == 'ADMIN';

  List<_NavItem> get _items =>
      _isAdmin ? _allItems : [_allItems[0], _allItems[4]]; // Home + Profile

  List<Widget> get _screens =>
      _isAdmin ? _allScreens : [_allScreens[0], _allScreens[4]];

  void _tap(int i) {
    HapticFeedback.selectionClick();
    setState(() => _idx = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: _BottomNav(
        items: _items,
        current: _idx,
        onTap: _tap,
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem(this.icon, this.activeIcon, this.label);
}

// ────────────────────────────────────────────────
// BOTTOM NAV BAR
// ────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final List<_NavItem> items;
  final int current;
  final void Function(int) onTap;

  const _BottomNav({
    required this.items,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(
              items.length,
                  (i) => Expanded(
                child: _NavTile(
                  item: items[i],
                  isActive: current == i,
                  onTap: () => onTap(i),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.14,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    if (widget.isActive) _ctrl.forward();
    _apiCalls();
  }

  _apiCalls() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(
        context,
        listen: false,
      ).getProducts(context, catId: 0);
      Provider.of<CategoryProvider>(
        context,
        listen: false,
      ).getCategory(context);
    });
  }

  @override
  void didUpdateWidget(_NavTile old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive)
      _ctrl.forward();
    else if (!widget.isActive && old.isActive)
      _ctrl.reverse();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Top indicator bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 3,
              width: widget.isActive ? 28 : 0,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Icon pill
            Transform.scale(
              scale: _scale.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.isActive ? widget.item.activeIcon : widget.item.icon,
                  size: 22,
                  color: widget.isActive
                      ? AppColors.primary
                      : AppColors.textLight,
                ),
              ),
            ),
            const SizedBox(height: 3),

            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10.5,
                fontFamily: 'Poppins',
                fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
                color: widget.isActive
                    ? AppColors.primary
                    : AppColors.textLight,
              ),
              child: Text(widget.item.label),
            ),
          ],
        ),
      ),
    );
  }
}