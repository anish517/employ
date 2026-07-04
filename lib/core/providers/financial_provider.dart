import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_provider.dart';
import '../services/financial_service.dart';

// Providers
final bonusListProvider = FutureProvider.family<List<dynamic>, String?>((ref, month) async {
  final api = ref.read(apiClientProvider);
  String path = '/bonuses';
  if (month != null) path += '?month=${Uri.encodeComponent(month)}';
  final res = await api.get(path);
  return (res is Map && res['data'] is List) ? List<dynamic>.from(res['data']) : [];
});

final fineListProvider = FutureProvider.family<List<dynamic>, String?>((ref, month) async {
  final api = ref.read(apiClientProvider);
  String path = '/fines';
  if (month != null) path += '?month=${Uri.encodeComponent(month)}';
  final res = await api.get(path);
  return (res is Map && res['data'] is List) ? List<dynamic>.from(res['data']) : [];
});

final loanListProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/loans');
  return (res is Map && res['data'] is List) ? List<dynamic>.from(res['data']) : [];
});

// Services
final bonusServiceProvider = Provider((ref) => BonusService(ref.read(apiClientProvider)));
final fineServiceProvider = Provider((ref) => FineService(ref.read(apiClientProvider)));
final loanServiceProvider = Provider((ref) => LoanService(ref.read(apiClientProvider)));
