import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_provider.dart';
import '../services/holiday_service.dart';

final holidayListProvider = FutureProvider.family<List<dynamic>, String?>((ref, year) async {
  final api = ref.read(apiClientProvider);
  String path = '/holidays';
  if (year != null && year.isNotEmpty) {
    path = '$path?year=${Uri.encodeComponent(year)}';
  }
  final res = await api.get(path);
  return (res is Map && res['data'] is List) ? List<dynamic>.from(res['data']) : [];
});

final holidayServiceProvider = Provider((ref) => HolidayService(ref.read(apiClientProvider)));
