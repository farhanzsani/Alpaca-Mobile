import 'package:alpaca_mobile/core/network/api_client.dart';
import 'package:alpaca_mobile/core/utils/result.dart';
import 'package:alpaca_mobile/models/inventory_model.dart';

class InventoryRepository {
  InventoryRepository({required ApiClient apiClient}) : _api = apiClient;
  final ApiClient _api;

  Future<Result<List<InventoryModel>>> getInventories(String ownerId, {bool? lowStock}) =>
      _api.get('/inventories', (j) => (j as List).map((e) => InventoryModel.fromJson(e as Map<String, dynamic>)).toList(),
          query: {'owner_id': ownerId, if (lowStock != null) 'low_stock': lowStock.toString()});

  Future<Result<InventoryModel>> getInventory(String id) =>
      _api.get('/inventories/$id', (j) => InventoryModel.fromJson(j as Map<String, dynamic>));

  Future<Result<InventoryModel>> createInventory(InventoryModel item) =>
      _api.post('/inventories/create', item.toJson(), (j) => InventoryModel.fromJson(j as Map<String, dynamic>));

  Future<Result<InventoryModel>> updateInventory(String id, Map<String, dynamic> data) =>
      _api.put('/inventories/$id', data, (j) => InventoryModel.fromJson(j as Map<String, dynamic>));

  Future<Result<void>> deleteInventory(String id) => _api.delete('/inventories/$id');

  // Aliases untuk backward compatibility
  Future<Result<List<InventoryModel>>> getItems(String ownerId) => getInventories(ownerId);
  Future<Result<InventoryModel>> addItem(InventoryModel item) => createInventory(item);
  Future<Result<InventoryModel>> updateItem(InventoryModel item) => updateInventory(item.id, item.toJson());
  Future<Result<void>> deleteItem(String id) => deleteInventory(id);
  Stream<List<InventoryModel>> streamItems(String ownerId) => Stream.value([]);
}
