import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/employees/presentation/employee_list_screen.dart';
import 'features/employees/presentation/employee_add_screen.dart';
import 'features/employees/presentation/employee_detail_screen.dart';
import 'features/attendance/presentation/attendance_screen.dart';
import 'features/attendance/presentation/attendance_mark_screen.dart';
import 'features/leave/presentation/leave_list_screen.dart';
import 'features/leave/presentation/leave_request_screen.dart';
import 'features/leave/presentation/leave_types_screen.dart';
import 'features/payroll/presentation/payroll_screen.dart';
import 'features/payroll/presentation/payslip_view_screen.dart';
import 'features/bonuses/presentation/bonuses_screen.dart';
import 'features/bonuses/presentation/bonus_add_screen.dart';
import 'features/fines/presentation/fines_screen.dart';
import 'features/fines/presentation/fine_add_screen.dart';
import 'features/loans/presentation/loans_screen.dart';
import 'features/loans/presentation/loan_add_screen.dart';
import 'features/expenses/presentation/expenses_screen.dart';
import 'features/holidays/presentation/holidays_screen.dart';
import 'features/reports/presentation/reports_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/department/presentation/department_screen.dart';
import 'features/designation/presentation/designation_screen.dart';

void main() => runApp(const ProviderScope(child: MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (c) => const LoginScreen(),
        '/dashboard': (c) => const DashboardScreen(),
        '/employees': (c) => const EmployeeListScreen(),
        '/employees/add': (c) => const EmployeeAddScreen(),
        '/employees/detail': (c) => const EmployeeDetailScreen(),
        '/departments': (c) => const DepartmentScreen(),
        '/designations': (c) => const DesignationScreen(),
        '/attendance': (c) => const AttendanceScreen(),
        '/attendance/mark': (c) => const AttendanceMarkScreen(),
        '/leave': (c) => const LeaveListScreen(),
        '/leave/request': (c) => const LeaveRequestScreen(),
        '/leave/types': (c) => const LeaveTypesScreen(),
        '/payroll': (c) => const PayrollScreen(),
        '/payroll/payslip': (c) => const PayslipViewScreen(),
        '/bonuses': (c) => const BonusesScreen(),
        '/bonuses/add': (c) => const BonusAddScreen(),
        '/fines': (c) => const FinesScreen(),
        '/fines/add': (c) => const FineAddScreen(),
        '/loans': (c) => const LoansScreen(),
        '/loans/add': (c) => const LoanAddScreen(),
        '/expenses': (c) => const ExpensesScreen(),
        '/holidays': (c) => const HolidaysScreen(),
        '/reports': (c) => const ReportsScreen(),
        '/settings': (c) => const SettingsScreen(),
        '/profile': (c) => const ProfileScreen(),
      },
    );
  }
}
