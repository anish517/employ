import '../services/api_client.dart';

class BonusService {
  final ApiClient api;
  BonusService(this.api);

  Future<Map<String, dynamic>> createBonus(Map<String, dynamic> payload) async {
    return await api.post('/bonuses', payload);
  }

  Future<void> deleteBonus(String id) async {
    await api.delete('/bonuses/$id');
  }
}

class FineService {
  final ApiClient api;
  FineService(this.api);

  Future<Map<String, dynamic>> createFine(Map<String, dynamic> payload) async {
    return await api.post('/fines', payload);
  }

  Future<void> deleteFine(String id) async {
    await api.delete('/fines/$id');
  }
}

class LoanService {
  final ApiClient api;
  LoanService(this.api);

  Future<Map<String, dynamic>> createLoan(Map<String, dynamic> payload) async {
    return await api.post('/loans', payload);
  }

  Future<void> deleteLoan(String id) async {
    await api.delete('/loans/$id');
  }
}
