import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_provider.dart';
import '../services/report_service.dart';

final reportServiceProvider = Provider((ref) => ReportService(ref.read(apiClientProvider)));

final attendanceReportProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, month) async {
  return await ref.read(reportServiceProvider).getAttendanceReport(month);
});

final salaryReportProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, month) async {
  return await ref.read(reportServiceProvider).getSalaryReport(month);
});

final leaveReportProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, month) async {
  return await ref.read(reportServiceProvider).getLeaveReport(month);
});
