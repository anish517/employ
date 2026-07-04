import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_provider.dart';

final designationListProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/designations');
  return (res is Map && res['data'] is List) ? List<dynamic>.from(res['data']) : [];
});
