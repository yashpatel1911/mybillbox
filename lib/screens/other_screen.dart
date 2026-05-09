import 'package:flutter/material.dart';
import '../DBHelper/app_colors.dart';


// ──────────────────────────────────────────────────
// SHARED WIDGETS
// ──────────────────────────────────────────────────
PreferredSizeWidget _appBar(String title, {List<Widget>? actions}) {
  return AppBar(
    backgroundColor: AppColors.cardBg,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    title: Text(title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark)),
    actions: actions ??
        [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppColors.textMedium),
            onPressed: () {},
          )
        ],
  );
}

Widget _statusBadge(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  );
}

// ──────────────────────────────────────────────────
// INVOICES SCREEN
// ──────────────────────────────────────────────────
class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: _appBar('Invoices'),
      body: Column(children: [
        // Filter chips
        Container(
          color: AppColors.cardBg,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final f in ['All', 'Paid', 'Pending', 'Overdue'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(label: f, selected: f == 'All'),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            itemCount: 12,
            itemBuilder: (_, i) => _InvoiceCard(i: i),
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new_invoice',
        onPressed: () {},
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Invoice',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  const _FilterChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.pageBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? AppColors.primary : AppColors.border),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 13,
              color: selected ? Colors.white : AppColors.textMedium,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final int i;
  const _InvoiceCard({required this.i});

  @override
  Widget build(BuildContext context) {
    final statuses = ['Paid', 'Pending', 'Overdue'];
    final colors = [AppColors.green, AppColors.orange, AppColors.red];
    final status = statuses[i % 3];
    final color  = colors[i % 3];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('#INV-10${42 - i}',
                style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 14)),
            Text('Customer ${i + 1}  •  Apr ${14 - i % 10}, 2025',
                style: const TextStyle(color: AppColors.textLight, fontSize: 11.5)),
          ],
        )),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('₹${(i + 1) * 3500}',
              style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 4),
          _statusBadge(status, color),
        ]),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────
// CUSTOMERS SCREEN
// ──────────────────────────────────────────────────
class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  static const _customers = [
    {'name': 'Rajesh Electronics', 'phone': '+91 98765 43210', 'invoices': '12', 'amount': '₹29,500'},
    {'name': 'Sharma & Sons',       'phone': '+91 87654 32109', 'invoices': '8',  'amount': '₹18,200'},
    {'name': 'Patel Traders',       'phone': '+91 76543 21098', 'invoices': '15', 'amount': '₹38,200'},
    {'name': 'Mehta Enterprises',   'phone': '+91 65432 10987', 'invoices': '5',  'amount': '₹11,500'},
    {'name': 'Gupta Bros',          'phone': '+91 54321 09876', 'invoices': '21', 'amount': '₹48,500'},
    {'name': 'Joshi & Co.',         'phone': '+91 43210 98765', 'invoices': '3',  'amount': '₹7,200'},
    {'name': 'Verma Industries',    'phone': '+91 32109 87654', 'invoices': '9',  'amount': '₹22,800'},
  ];

  static const _avatarColors = [
    AppColors.primary, AppColors.green, AppColors.orange,
    AppColors.purple, AppColors.cyan, AppColors.red, AppColors.green,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: _appBar('Customers'),
      body: Column(children: [
        Container(
          color: AppColors.cardBg,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            style: const TextStyle(color: AppColors.textDark),
            decoration: InputDecoration(
              hintText: 'Search customers...',
              hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textLight, size: 20),
              filled: true,
              fillColor: AppColors.pageBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
            itemCount: _customers.length,
            itemBuilder: (_, i) {
              final c = _customers[i];
              final color = _avatarColors[i % _avatarColors.length];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: color.withOpacity(0.12),
                    child: Text(c['name']![0],
                        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c['name']!,
                          style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(c['phone']!,
                          style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                    ],
                  )),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(c['amount']!,
                        style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('${c['invoices']} invoices',
                        style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
                  ]),
                ]),
              );
            },
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        heroTag: 'person',
        onPressed: () {},
        backgroundColor: AppColors.green,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
    );
  }
}

// ──────────────────────────────────────────────────
// REPORTS SCREEN
// ──────────────────────────────────────────────────
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: _appBar('Reports', actions: [
        IconButton(
          icon: const Icon(Icons.download_outlined, color: AppColors.textMedium),
          onPressed: () {},
        ),
      ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview cards
            const _SectionTitle('Overview'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _ReportStat('Total Billed', '₹2,48,500', Icons.account_balance_wallet_outlined, AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: _ReportStat('Collected',    '₹1,78,920', Icons.check_circle_outline,            AppColors.green)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _ReportStat('Outstanding', '₹69,580', Icons.schedule_rounded, AppColors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _ReportStat('Customers',   '47',       Icons.people_outline,   AppColors.purple)),
            ]),
            const SizedBox(height: 24),

            // Monthly bar chart
            const _SectionTitle('Monthly Trend'),
            const SizedBox(height: 12),
            _MonthlyChart(),
            const SizedBox(height: 24),

            // Top customers
            const _SectionTitle('Top Customers'),
            const SizedBox(height: 12),
            for (final row in [
              ('Gupta Bros',          '₹48,500', 0.78),
              ('Patel Traders',       '₹38,200', 0.62),
              ('Rajesh Electronics',  '₹29,500', 0.48),
              ('Sharma & Sons',       '₹18,200', 0.30),
            ])
              _TopCustomer(row.$1, row.$2, row.$3),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark));
}

class _ReportStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _ReportStat(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 12),
        Text(value,
            style: const TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(label,
            style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
      ]),
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  final months = const ['J','F','M','A','M','J','J','A','S','O','N','D'];
  final vals   = const [0.3, 0.5, 0.9, 0.6, 0.3, 0.55, 0.88, 0.4, 0.22, 0.55, 0.92, 0.58];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        SizedBox(
          height: 110,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(months.length, (i) {
              final active = vals[i] > 0.8;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Flexible(
                      child: Container(
                        height: 96 * vals[i],
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : AppColors.primary.withOpacity(0.22),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(months[i], style: const TextStyle(fontSize: 9, color: AppColors.textLight)),
                  ]),
                ),
              );
            }),
          ),
        ),
      ]),
    );
  }
}

class _TopCustomer extends StatelessWidget {
  final String name, amount;
  final double ratio;
  const _TopCustomer(this.name, this.amount, this.ratio);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(name, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500, fontSize: 13.5)),
          Text(amount, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13.5)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 5,
            backgroundColor: AppColors.pageBg,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ]),
    );
  }
}

/*// ──────────────────────────────────────────────────
// PROFILE SCREEN
// ──────────────────────────────────────────────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: _appBar('Profile', actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: AppColors.textMedium),
          onPressed: () {},
        ),
      ]),
      body: SingleChildScrollView(
        child: Column(children: [
          // Header banner
          Container(
            width: double.infinity,
            color: AppColors.cardBg,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: const Text('YP',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 30)),
                  ),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 13),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Yash Patel',
                  style: TextStyle(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.w700)),
              const Text('yash@mybillbox.in',
                  style: TextStyle(color: AppColors.textMedium, fontSize: 13)),
              const SizedBox(height: 16),
              // 3 mini stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _MiniStat('38', 'Invoices'),
                  Container(width: 1, height: 32, color: AppColors.border),
                  _MiniStat('47', 'Customers'),
                  Container(width: 1, height: 32, color: AppColors.border),
                  _MiniStat('₹2.4L', 'Revenue'),
                ],
              ),
            ]),
          ),

          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _ProfileSection('Business Info', [
                _ProfileTile(Icons.business_rounded,       'Business Name', 'Patel Enterprises',   AppColors.primary),
                _ProfileTile(Icons.phone_rounded,           'Phone',         '+91 98765 43210',      AppColors.green),
                _ProfileTile(Icons.location_on_rounded,    'Address',       'Ahmedabad, Gujarat',   AppColors.orange),
                _ProfileTile(Icons.numbers_rounded,         'GST Number',    '24AAACP1234A1Z5',      AppColors.purple),
              ]),
              const SizedBox(height: 14),
              _ProfileSection('App Settings', [
                _ProfileTile(Icons.palette_rounded,         'Theme',         'Light Mode',           AppColors.primary),
                _ProfileTile(Icons.language_rounded,        'Language',      'English',              AppColors.green),
                _ProfileTile(Icons.currency_rupee_rounded,  'Currency',      'INR (₹)',              AppColors.orange),
              ]),
              const SizedBox(height: 14),
              _ProfileSection('Account', [
                _ProfileTile(Icons.lock_reset_rounded,    'Change Password', '', AppColors.primary),
                _ProfileTile(Icons.backup_rounded,        'Backup & Restore','', AppColors.green),
                _ProfileTile(Icons.help_outline_rounded,  'Help & Support',  '', AppColors.orange),
              ]),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity, height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.logout_rounded, color: AppColors.red, size: 20),
                  label: const Text('Sign Out',
                      style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w600, fontSize: 15)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.red, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ]),
          ),
        ]),
      ),
    );
  }
}*/

class _MiniStat extends StatelessWidget {
  final String value, label;
  const _MiniStat(this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(color: AppColors.textDark, fontSize: 17, fontWeight: FontWeight.w700)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
  ]);
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<_ProfileTile> tiles;
  const _ProfileSection(this.title, this.tiles);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title.toUpperCase(),
          style: const TextStyle(color: AppColors.textLight, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: tiles.asMap().entries.map((e) => Column(children: [
            e.value,
            if (e.key < tiles.length - 1)
              const Divider(height: 1, color: AppColors.divider, indent: 52),
          ])).toList(),
        ),
      ),
    ]);
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _ProfileTile(this.icon, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(label, style: const TextStyle(color: AppColors.textDark, fontSize: 14)),
      trailing: value.isEmpty
          ? const Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 20)
          : Text(value, style: const TextStyle(color: AppColors.textMedium, fontSize: 13)),
      dense: true,
      onTap: () {},
    );
  }
}