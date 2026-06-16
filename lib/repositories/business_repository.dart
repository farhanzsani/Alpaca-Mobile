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

  /// Get business by owner - uses API with fallback to Firestore
  Future<Result<BusinessLocationModel?>> getBusinessByOwner(String ownerId) async {
    try {
      // Try API first with ?mine=true filter
      final result = await _api.getPublic('/business-locations', (j) {
        final data = j is Map ? j['data'] : j;
        final locations = (data as List)
            .map((e) => BusinessLocationModel.fromJson(e as Map<String, dynamic>))
            .toList();
        // Find the one matching ownerId
        return locations.where((loc) => loc.ownerId == ownerId).toList();
      }, query: {'mine': 'false'}); // Get all, then filter by owner
      
      return result.when(
        success: (locations) {
          if (locations.isEmpty) {
            return Result.success(null);
          }
          return Result.success(locations.first as BusinessLocationModel);
        },
        failure: (exception) async {
          // Fallback to Firestore
          try {
            var snapshot = await _firestore
                .collection('business_locations')
                .where('owner_id', isEqualTo: ownerId)
                .limit(1)
                .get();
            
            if (snapshot.docs.isEmpty) {
              snapshot = await _firestore
                  .collection('business_locations')
                  .where('ownerId', isEqualTo: ownerId)
                  .limit(1)
                  .get();
            }
            
            if (snapshot.docs.isEmpty) {
              return Result.success(null);
            }
            
            final data = snapshot.docs.first.data();
            data['id'] = snapshot.docs.first.id;
            return Result.success(BusinessLocationModel.fromJson(data));
          } catch (e) {
            return Result.failure(AppException(message: 'Failed to get business: $e'));
          }
        },
      );
    } catch (e) {
      return Result.failure(AppException(message: 'Failed to get business: $e'));
    }
  }
  
  // Aliases untuk backward compatibility
  Future<Result<BusinessLocationModel>> createBusiness(BusinessLocationModel location) => createBusinessLocation(location);
  Future<Result<BusinessLocationModel>> updateBusiness(BusinessLocationModel location) => updateBusinessLocation(location.id, location.toJson());
}
