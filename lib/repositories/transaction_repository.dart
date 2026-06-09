import 'package:alpaca_mobile/core/network/api_client.dart';
import 'package:alpaca_mobile/core/utils/result.dart';
import 'package:alpaca_mobile/models/transaction_model.dart';

class TransactionRepository {
  TransactionRepository({required ApiClient apiClient}) : _api = apiClient;
  final ApiClient _api;

  Future<Result<List<TransactionModel>>> getTransactions(String ownerId) =>
      _api.get('/transactions', (j) {
        final data = j is Map ? j['data'] : j;
        return (data as List).map((e) => TransactionModel.fromJson(e as Map<String, dynamic>)).toList();
      }, query: {'owner_id': ownerId});

  Future<Result<TransactionModel>> getTransaction(String id) =>
      _api.get('/transactions/$id', (j) => TransactionModel.fromJson(j as Map<String, dynamic>));

  Future<Result<TransactionModel>> createTransaction(TransactionModel tx) =>
      _api.post('/transactions/create', tx.toJson(), (j) => TransactionModel.fromJson(j as Map<String, dynamic>));

  Future<Result<TransactionModel>> updateTransaction(String id, Map<String, dynamic> data) =>
      _api.put('/transactions/$id', data, (j) => TransactionModel.fromJson(j as Map<String, dynamic>));

  Future<Result<void>> deleteTransaction(String id) => _api.delete('/transactions/$id');

  // Aliases untuk backward compatibility
  Future<Result<TransactionModel>> addTransaction(TransactionModel tx) => createTransaction(tx);
  Stream<List<TransactionModel>> streamTransactions(String ownerId) => Stream.value([]);
}
