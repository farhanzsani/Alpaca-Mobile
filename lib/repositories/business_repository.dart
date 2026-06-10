import 'package:alpaca_mobile/core/network/api_client.dart';
import 'package:alpaca_mobile/core/utils/result.dart';
import 'package:alpaca_mobile/models/business_location_model.dart';

class BusinessRepository {
  BusinessRepository({required ApiClient apiClient}) : _api = apiClient;
  final ApiClient _api;

  Future<Result<List<BusinessLocationModel>>> getBusinessLocations() =>
      _api.get('/business-locations', (j) {
        final data = j is Map ? j['data'] : j;
        return (data as List).map((e) => BusinessLocationModel.fromJson(e as Map<String, dynamic>)).toList();
      });

  Future<Result<BusinessLocationModel>> getBusinessLocation(String id) =>
      _api.get('/business-locations/$id', (j) => BusinessLocationModel.fromJson(j as Map<String, dynamic>));

  Future<Result<BusinessLocationModel>> createBusinessLocation(BusinessLocationModel location) =>
      _api.post('/business-locations/create', location.toJson(), (j) => BusinessLocationModel.fromJson(j as Map<String, dynamic>));

  Future<Result<BusinessLocationModel>> updateBusinessLocation(String id, Map<String, dynamic> data) =>
      _api.put('/business-locations/$id', data, (j) => BusinessLocationModel.fromJson(j as Map<String, dynamic>));

  Future<Result<void>> deleteBusinessLocation(String id) => _api.delete('/business-locations/$id');

  // Aliases untuk backward compatibility
  Stream<List<BusinessLocationModel>> getAllBusinesses() => Stream.value([]);
  Future<Result<BusinessLocationModel?>> getBusinessByOwner(String ownerId) async {
    final all = await getBusinessLocations();
    return all.map((list) {
      try {
        return list.firstWhere((b) => b.ownerId == ownerId);
      } catch (_) {
        return null;
      }
    });
  }
  Future<Result<BusinessLocationModel>> createBusiness(BusinessLocationModel location) => createBusinessLocation(location);
  Future<Result<BusinessLocationModel>> updateBusiness(BusinessLocationModel location) => updateBusinessLocation(location.id, location.toJson());
}
