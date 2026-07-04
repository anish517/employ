import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/providers/employee_provider.dart';

class PayslipViewScreen extends ConsumerWidget {
  const PayslipViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sal = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (sal == null) return const Scaffold(body: Center(child: Text('No salary data provided')));

    final employees = ref.watch(employeeListProvider(null));

    String empName = 'Employee';
    String empId = '';
    String dept = '';
    String desig = '';
    
    if (employees.hasValue) {
      final matched = employees.value!.where((e) => e['_id'] == sal['employeeId']).toList();
      if (matched.isNotEmpty) {
        empName = matched.first['fullName'] ?? 'Employee';
        empId = matched.first['employeeId'] ?? '';
        dept = matched.first['departmentId'] ?? 'N/A';
        desig = matched.first['designationId'] ?? 'N/A';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payslip'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading payslip PDF...')));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AppCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Text('COMPANY NAME', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
              const SizedBox(height: 4),
              const Text('Address, City, Country', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
              const SizedBox(height: 24),
              const Divider(color: AppTheme.divider),
              const SizedBox(height: 16),
              
              Text('PAYSLIP FOR ${sal['month']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 24),

              // Employee Info
              _row('Employee Name', empName),
              _row('Employee ID', empId),
              _row('Department', dept),
              _row('Designation', desig),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.divider),
              const SizedBox(height: 16),

              // Earnings
              const Text('EARNINGS', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary)),
              const SizedBox(height: 12),
              _amountRow('Basic Salary (${sal['regularHours']} hrs @ NPR ${sal['hourlyRate']})', (sal['regularHours'] * sal['hourlyRate']).toString()),
              if ((sal['overtimeHours'] ?? 0) > 0)
                _amountRow('Overtime (${sal['overtimeHours']} hrs)', ((sal['grossSalary'] ?? 0) - (sal['regularHours'] * sal['hourlyRate'])).toString()),
              
              if ((sal['bonuses'] as List?)?.isNotEmpty ?? false) ...[
                const SizedBox(height: 8),
                const Text('Bonuses:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ...((sal['bonuses'] as List).map((b) => _amountRow('  - ${b['type']}', b['amount'].toString()))),
              ],
              
              const SizedBox(height: 8),
              const Divider(color: AppTheme.divider, endIndent: 20, indent: 20),
              _amountRow('Gross Earnings', sal['grossSalary'].toString(), bold: true),
              const SizedBox(height: 24),

              // Deductions
              const Text('DEDUCTIONS', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.error)),
              const SizedBox(height: 12),
              _amountRow('Tax', sal['taxDeduction'].toString()),
              if ((sal['fines'] as List?)?.isNotEmpty ?? false) ...[
                const SizedBox(height: 8),
                const Text('Fines:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ...((sal['fines'] as List).map((f) => _amountRow('  - ${f['type']}', f['amount'].toString()))),
              ],
              if ((sal['loans'] as List?)?.isNotEmpty ?? false) ...[
                const SizedBox(height: 8),
                const Text('Loan Repayments:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ...((sal['loans'] as List).map((l) => _amountRow('  - Installment', l['amount'].toString()))),
              ],

              const SizedBox(height: 8),
              const Divider(color: AppTheme.divider, endIndent: 20, indent: 20),
              _amountRow('Total Deductions', sal['totalDeduction'].toString(), bold: true),
              const SizedBox(height: 24),

              // Net Salary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primary),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('NET SALARY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('NPR ${sal['netSalary']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.success)),
                  ],
                ),
              ),

              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Container(width: 100, height: 1, color: AppTheme.onSurface),
                      const SizedBox(height: 4),
                      const Text('Employer Signature', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                  Column(
                    children: [
                      Container(width: 100, height: 1, color: AppTheme.onSurface),
                      const SizedBox(height: 4),
                      const Text('Employee Signature', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _amountRow(String label, String amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
          Text(amount.toString(), style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }
}
