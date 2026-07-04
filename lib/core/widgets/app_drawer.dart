import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name ?? '/dashboard';

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primary, AppTheme.primaryLight],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                  ),
                  child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                const Text('Admin Panel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                const Text('Employee Management', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerItem(icon: Icons.dashboard_rounded, label: 'Dashboard', route: '/dashboard', currentRoute: route),
                _DrawerSection(label: 'HR'),
                _DrawerItem(icon: Icons.people_alt_rounded, label: 'Employees', route: '/employees', currentRoute: route),
                _DrawerItem(icon: Icons.business_rounded, label: 'Departments', route: '/departments', currentRoute: route),
                _DrawerItem(icon: Icons.work_outline_rounded, label: 'Designations', route: '/designations', currentRoute: route),
                _DrawerSection(label: 'Time & Attendance'),
                _DrawerItem(icon: Icons.access_time_rounded, label: 'Attendance', route: '/attendance', currentRoute: route),
                _DrawerItem(icon: Icons.event_note_rounded, label: 'Leave Management', route: '/leave', currentRoute: route),
                _DrawerItem(icon: Icons.beach_access_rounded, label: 'Holidays', route: '/holidays', currentRoute: route),
                _DrawerSection(label: 'Payroll'),
                _DrawerItem(icon: Icons.payments_rounded, label: 'Payroll', route: '/payroll', currentRoute: route),
                _DrawerItem(icon: Icons.card_giftcard_rounded, label: 'Bonuses', route: '/bonuses', currentRoute: route),
                _DrawerItem(icon: Icons.remove_circle_outline_rounded, label: 'Fines', route: '/fines', currentRoute: route),
                _DrawerItem(icon: Icons.account_balance_rounded, label: 'Loans', route: '/loans', currentRoute: route),
                _DrawerSection(label: 'Finance'),
                _DrawerItem(icon: Icons.receipt_long_rounded, label: 'Expenses', route: '/expenses', currentRoute: route),
                _DrawerItem(icon: Icons.bar_chart_rounded, label: 'Reports', route: '/reports', currentRoute: route),
                const Divider(height: 24),
                _DrawerItem(icon: Icons.settings_rounded, label: 'Settings', route: '/settings', currentRoute: route),
                _DrawerItem(icon: Icons.person_rounded, label: 'Profile', route: '/profile', currentRoute: route),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('v1.0.0', style: TextStyle(color: AppTheme.onSurface.withValues(alpha: 0.3), fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  final String label;
  const _DrawerSection({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(label.toUpperCase(),
          style: TextStyle(
            color: AppTheme.onSurface.withValues(alpha: 0.4),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          )),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;

  const _DrawerItem({required this.icon, required this.label, required this.route, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final isActive = currentRoute == route;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: isActive ? AppTheme.primary.withValues(alpha: 0.15) : Colors.transparent,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, size: 20, color: isActive ? AppTheme.secondary : AppTheme.onSurface.withValues(alpha: 0.6)),
        title: Text(label,
            style: TextStyle(
              color: isActive ? AppTheme.secondary : AppTheme.onSurface.withValues(alpha: 0.85),
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            )),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () {
          Navigator.pop(context);
          if (currentRoute != route) Navigator.pushReplacementNamed(context, route);
        },
      ),
    );
  }
}
