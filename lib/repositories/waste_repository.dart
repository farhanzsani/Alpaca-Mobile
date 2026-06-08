import 'package:alpaca_mobile/core/network/api_client.dart';
import 'package:alpaca_mobile/core/utils/result.dart';
import 'package:alpaca_mobile/models/waste_resource_model.dart';

class WasteRepository {
  WasteRepository({required ApiClient apiClient}) : _api = apiClient;
  final ApiClient _api;

  Future<Result<List<WasteResourceModel>>> getWasteResources(String ownerId, {bool? reusable}) =>
      _api.get('/waste-resources', (j) => (j as List).map((e) => WasteResourceModel.fromJson(e as Map<String, dynamic>)).toList(),
          query: {'owner_id': ownerId, if (reusable != null) 'reusable': reusable.toString()});

  Future<Result<WasteResourceModel>> getWasteResource(String id) =>
      _api.get('/waste-resources/$id', (j) => WasteResourceModel.fromJson(j as Map<String, dynamic>));

  Future<Result<WasteResourceModel>> createWasteResource(WasteResourceModel waste) =>
      _api.post('/waste-resources/create', waste.toJson(), (j) => WasteResourceModel.fromJson(j as Map<String, dynamic>));

  Future<Result<WasteResourceModel>> updateWasteResource(String id, Map<String, dynamic> data) =>
      _api.put('/waste-resources/$id', data, (j) => WasteResourceModel.fromJson(j as Map<String, dynamic>));

  Future<Result<void>> deleteWasteResource(String id) => _api.delete('/waste-resources/$id');

  // Aliases untuk backward compatibility
  Future<Result<List<WasteResourceModel>>> getWasteByOwner(String ownerId) => getWasteResources(ownerId);
  Future<Result<WasteResourceModel>> addWaste(WasteResourceModel waste) => createWasteResource(waste);
  Future<Result<WasteResourceModel>> updateWaste(WasteResourceModel waste) => updateWasteResource(waste.id, waste.toJson());
  Future<Result<void>> deleteWaste(String id) => deleteWasteResource(id);
  Future<Result<List<WasteResourceModel>>> getReusableWaste(String ownerId) => getWasteResources(ownerId, reusable: true);
  Stream<List<WasteResourceModel>> streamWaste(String ownerId) => Stream.value([]);
}
