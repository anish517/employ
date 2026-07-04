import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/dashboard_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/theme/app_theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(dashboardSummaryProvider),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authServiceProvider).logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardSummaryProvider),
        child: summary.when(
          data: (data) => _buildDashboard(context, data),
          loading: () => const LoadingView(message: 'Loading dashboard...'),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(dashboardSummaryProvider)),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Welcome back!', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 4),
                      const Text('Admin Dashboard', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Month: ${data['currentMonth'] ?? ''}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.business_center_rounded, color: Colors.white30, size: 56),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Today\'s Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _StatCard(label: 'Total Employees', value: '${data['totalEmployees'] ?? 0}', icon: Icons.people_alt_rounded, color: AppTheme.secondary),
              _StatCard(label: 'Present Today', value: '${data['presentToday'] ?? 0}', icon: Icons.check_circle_outline_rounded, color: AppTheme.success),
              _StatCard(label: 'Absent Today', value: '${data['absentToday'] ?? 0}', icon: Icons.cancel_outlined, color: AppTheme.error),
              _StatCard(label: 'Late Today', value: '${data['lateToday'] ?? 0}', icon: Icons.schedule_rounded, color: AppTheme.warning),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Payroll & HR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _BigStatCard(label: 'Pending Leaves', value: '${data['pendingLeaves'] ?? 0}', icon: Icons.pending_actions_rounded, color: AppTheme.warning, onTap: () => Navigator.pushNamed(context, '/leave'))),
            const SizedBox(width: 12),
            Expanded(child: _BigStatCard(label: 'Salary This Month', value: 'NPR ${(data['totalSalaryThisMonth'] ?? 0).toStringAsFixed(0)}', icon: Icons.payments_rounded, color: AppTheme.success, onTap: () => Navigator.pushNamed(context, '/payroll'))),
          ]),
          const SizedBox(height: 12),
          _BigStatCard(label: 'New Employees This Month', value: '${data['newEmployeesThisMonth'] ?? 0}', icon: Icons.person_add_rounded, color: AppTheme.secondary, onTap: () => Navigator.pushNamed(context, '/employees')),
          const SizedBox(height: 24),
          const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.0,
            children: [
              _QuickAction(icon: Icons.person_add_rounded, label: 'Add Employee', route: '/employees/add'),
              _QuickAction(icon: Icons.access_time_rounded, label: 'Attendance', route: '/attendance/mark'),
              _QuickAction(icon: Icons.payments_rounded, label: 'Payroll', route: '/payroll'),
              _QuickAction(icon: Icons.event_note_rounded, label: 'Leave', route: '/leave'),
              _QuickAction(icon: Icons.bar_chart_rounded, label: 'Reports', route: '/reports'),
              _QuickAction(icon: Icons.settings_rounded, label: 'Settings', route: '/settings'),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: AppTheme.onSurface.withValues(alpha: 0.6), fontSize: 11)),
          ]),
        ],
      ),
    );
  }
}

class _BigStatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _BigStatCard({required this.label, required this.value, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: AppTheme.onSurface.withValues(alpha: 0.6), fontSize: 11)),
        ])),
      ]),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  const _QuickAction({required this.icon, required this.label, required this.route});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: () => Navigator.pushNamed(context, route),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: AppTheme.secondary, size: 28),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
