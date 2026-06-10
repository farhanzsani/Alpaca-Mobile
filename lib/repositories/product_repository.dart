import 'package:alpaca_mobile/core/network/api_client.dart';
import 'package:alpaca_mobile/core/utils/result.dart';
import 'package:alpaca_mobile/models/product_model.dart';

class ProductRepository {
  ProductRepository({required ApiClient apiClient}) : _api = apiClient;
  final ApiClient _api;

  Future<Result<List<ProductModel>>> getProducts(String ownerId) =>
      _api.get('/products', (j) {
        print('[ProductRepository] ===== GET /products?owner_id=$ownerId =====');
        final data = j is Map ? j['data'] : j;
        print('[ProductRepository] Received ${(data as List).length} products');
        
        final allProducts = data.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
        
        // Debug: cek owner_id dari beberapa produk
        if (allProducts.isNotEmpty) {
          print('[ProductRepository] Sample product owner_ids:');
          for (var i = 0; i < (allProducts.length > 3 ? 3 : allProducts.length); i++) {
            print('  - Product ${i + 1}: owner_id="${allProducts[i].ownerId}" (length: ${allProducts[i].ownerId.length})');
          }
          print('[ProductRepository] Looking for: "$ownerId" (length: ${ownerId.length})');
        }
        
        // Temporary fix: filter di client side karena backend belum filter
        final filtered = allProducts.where((p) => p.ownerId == ownerId).toList();
        print('[ProductRepository] Filtered to ${filtered.length} products for owner $ownerId');
        return filtered;
      }, query: {'owner_id': ownerId});

  Future<Result<List<ProductModel>>> getAllProducts() =>
      _api.get('/products', (j) {
        print('[ProductRepository] getAllProducts response: $j');
        final data = j is Map ? j['data'] : j;
        print('[ProductRepository] data extracted: $data');
        final products = (data as List).map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
        print('[ProductRepository] products parsed: ${products.length} items');
        return products;
      });

  Future<Result<ProductModel>> getProduct(String id) =>
      _api.get('/products/$id', (j) => ProductModel.fromJson(j as Map<String, dynamic>));

  Future<Result<ProductModel>> createProduct(ProductModel product) =>
      _api.post('/products/create', product.toJson(), (j) {
        print('[ProductRepository] createProduct response: $j');
        final data = j is Map ? (j['data'] ?? j) : j;
        print('[ProductRepository] data to parse: $data');
        return ProductModel.fromJson(data as Map<String, dynamic>);
      });

  Future<Result<ProductModel>> updateProduct(String id, Map<String, dynamic> data) =>
      _api.put('/products/$id', data, (j) => ProductModel.fromJson(j as Map<String, dynamic>));

  Future<Result<void>> deleteProduct(String id) => _api.delete('/products/$id');

  // Aliases untuk backward compatibility dengan ViewModel
  Future<Result<List<ProductModel>>> getProductsByOwner(String ownerId) => getProducts(ownerId);
  Future<Result<ProductModel>> addProduct(ProductModel product) => createProduct(product);
  Stream<List<ProductModel>> streamAllProducts() => Stream.value([]);
  Stream<List<ProductModel>> streamProducts(String ownerId) => Stream.value([]);
}
