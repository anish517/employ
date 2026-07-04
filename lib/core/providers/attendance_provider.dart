import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_provider.dart';
import '../services/attendance_service.dart';

final attendanceListProvider = FutureProvider.family<List<dynamic>, Map<String, String>?>((ref, params) async {
  final api = ref.read(apiClientProvider);
  String path = '/attendance';
  if(params != null && params.isNotEmpty){
    final qs = params.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
    path = '$path?$qs';
  }
  final res = await api.get(path);
  return (res is Map && res['data'] is List) ? List<dynamic>.from(res['data']) : [];
});

final monthlyAttendanceProvider = FutureProvider.family<List<dynamic>, String>((ref, month) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/attendance/monthly?month=${Uri.encodeComponent(month)}');
  return (res is Map && res['data'] is List) ? List<dynamic>.from(res['data']) : [];
});

final attendanceServiceProvider = Provider((ref) => AttendanceService(ref.read(apiClientProvider)));
