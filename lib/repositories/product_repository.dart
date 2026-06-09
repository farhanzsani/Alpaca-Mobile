import 'package:alpaca_mobile/core/network/api_client.dart';
import 'package:alpaca_mobile/core/utils/result.dart';
import 'package:alpaca_mobile/models/product_model.dart';

class ProductRepository {
  ProductRepository({required ApiClient apiClient}) : _api = apiClient;
  final ApiClient _api;

  Future<Result<List<ProductModel>>> getProducts(String ownerId) =>
      _api.get('/products', (j) {
        final data = j is Map ? j['data'] : j;
        return (data as List).map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
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
