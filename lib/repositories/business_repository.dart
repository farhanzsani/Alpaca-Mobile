import 'package:alpaca_mobile/core/network/api_client.dart';
import 'package:alpaca_mobile/core/utils/result.dart';
import 'package:alpaca_mobile/models/business_location_model.dart';
import 'package:alpaca_mobile/core/exceptions/app_exception.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessRepository {
  BusinessRepository({required ApiClient apiClient}) : _api = apiClient;
  final ApiClient _api;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Result<List<BusinessLocationModel>>> getBusinessLocations() =>
      _api.getPublic('/business-locations', (j) {
        final data = j is Map ? j['data'] : j;
        return (data as List).map((e) => BusinessLocationModel.fromJson(e as Map<String, dynamic>)).toList();
      });

  Future<Result<BusinessLocationModel>> getBusinessLocation(String id) =>
      _api.getPublic('/business-locations/$id', (j) {
        final data = j is Map ? j['data'] : j;
        return BusinessLocationModel.fromJson(data as Map<String, dynamic>);
      });

  Future<Result<BusinessLocationModel>> createBusinessLocation(BusinessLocationModel location) async {
    try {
      return await _api.post('/business-locations/create', location.toJson(), (j) {
        final data = j is Map ? j['data'] : j;
        return BusinessLocationModel.fromJson(data as Map<String, dynamic>);
      });
    } catch (e) {
      return Result.failure(AppException(message: 'Failed to create: $e'));
    }
  }

  Future<Result<BusinessLocationModel>> updateBusinessLocation(String id, Map<String, dynamic> data) async {
    try {
      return await _api.put('/business-locations/$id', data, (j) {
        final data = j is Map ? j['data'] : j;
        return BusinessLocationModel.fromJson(data as Map<String, dynamic>);
      });
    } catch (e) {
      return Result.failure(AppException(message: 'Failed to update: $e'));
    }
  }

  Future<Result<void>> deleteBusinessLocation(String id) => _api.delete('/business-locations/$id');

  /// Fetches nearby business locations by GPS coordinates.
  ///
  /// Calls `GET /business-locations/nearby?latitude=&longitude=` and returns
  /// the list of [BusinessLocationModel] sorted by proximity.
  Future<Result<List<BusinessLocationModel>>> getNearbyBusinesses({
    required double latitude,
    required double longitude,
  }) =>
      _api.getPublic(
        '/business-locations/nearby',
        (j) {
          final data = j is Map ? j['data'] : j;
          return (data as List)
              .map((e) => BusinessLocationModel.fromJson(e as Map<String, dynamic>))
              .toList();
        },
        query: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
        },
      );

  /// Get all businesses - prioritizes API but falls back to Firestore stream
  Stream<List<BusinessLocationModel>> getAllBusinesses() {
    return _firestore.collection('business_locations')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return BusinessLocationModel.fromJson(data);
            })
            .toList());
  }

  /// Get business by owner - uses API
  Future<Result<BusinessLocationModel?>> getBusinessByOwner(String ownerId) async {
    try {
      final result = await _api.getPublic('/business-locations', (j) {
        final data = j is Map ? j['data'] : j;
        final locations = (data as List)
            .map((e) => BusinessLocationModel.fromJson(e as Map<String, dynamic>))
            .where((loc) => loc.ownerId == ownerId)
            .toList();
        return locations.isNotEmpty ? locations.first : null;
      });
      
      return result;
    } catch (e) {
      return Result.failure(AppException(message: 'Failed to get business: $e'));
    }
  }
  
  // Aliases untuk backward compatibility
  Future<Result<BusinessLocationModel>> createBusiness(BusinessLocationModel location) => createBusinessLocation(location);
  Future<Result<BusinessLocationModel>> updateBusiness(BusinessLocationModel location) => updateBusinessLocation(location.id, location.toJson());
}
