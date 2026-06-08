import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:alpaca_mobile/core/exceptions/app_exception.dart';
import 'package:alpaca_mobile/core/utils/result.dart';

class ApiClient {
  ApiClient({String? baseUrl, http.Client? client, FirebaseAuth? auth})
      : _baseUrl = (baseUrl ?? defaultBaseUrl).replaceAll(RegExp(r'/$'), ''),
        _client = client ?? http.Client(),
        _auth = auth ?? FirebaseAuth.instance;

  static const String defaultBaseUrl = 'https://api-alpaca.vercel.app/api/v1';

  final String _baseUrl;
  final http.Client _client;
  final FirebaseAuth _auth;

  Future<Map<String, String>> _headers() async {
    print('[ApiClient] Getting headers...');
    var user = _auth.currentUser;
    print('[ApiClient] currentUser: ${user?.uid ?? "NULL"}');
    if (user == null) {
      print('[ApiClient] ❌ User is null - session expired');
      throw AuthException.sessionExpired();
    }
    
    try {
      print('[ApiClient] Getting ID token...');
      var token = await user.getIdToken();
      print('[ApiClient] Token: ${token != null ? "EXISTS (${token.length} chars)" : "NULL"}');
      if (token == null) {
        // Retry once with force refresh
        await user.reload();
        user = _auth.currentUser;
        if (user == null) throw AuthException.sessionExpired();
        token = await user.getIdToken(true);
        if (token == null) throw AuthException.sessionExpired();
      }
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } catch (e, stack) {
      print('[ApiClient] ❌ Error getting token: $e');
      print('[ApiClient] Stack: $stack');
      throw AuthException(message: 'Gagal mendapatkan token: $e');
    }
  }

  Uri _uri(String path, [Map<String, String?>? query]) {
    final uri = Uri.parse('$_baseUrl$path');
    if (query == null) return uri;
    final q = Map.fromEntries(
      query.entries.where((e) => e.value != null).map((e) => MapEntry(e.key, e.value!)),
    );
    return q.isEmpty ? uri : uri.replace(queryParameters: q);
  }

  Future<Result<T>> get<T>(String path, T Function(dynamic) fromJson,
          {Map<String, String?>? query}) =>
      _call(() async => _decode(
          await _client.get(_uri(path, query), headers: await _headers()), fromJson));

  Future<Result<T>> post<T>(
          String path, Map<String, dynamic> body, T Function(dynamic) fromJson) =>
      _call(() async => _decode(
          await _client.post(_uri(path), headers: await _headers(), body: jsonEncode(body)),
          fromJson));

  Future<Result<T>> put<T>(
          String path, Map<String, dynamic> body, T Function(dynamic) fromJson) =>
      _call(() async => _decode(
          await _client.put(_uri(path), headers: await _headers(), body: jsonEncode(body)),
          fromJson));

  Future<Result<void>> delete(String path) => _call(() async {
        _checkStatus(await _client.delete(_uri(path), headers: await _headers()));
      });

  T _decode<T>(http.Response res, T Function(dynamic) fromJson) {
    _checkStatus(res);
    return fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  void _checkStatus(http.Response res) {
    print('[ApiClient] Response: ${res.statusCode} ${res.reasonPhrase}');
    final code = res.statusCode;
    if (code >= 200 && code < 300) return;
    dynamic body;
    try { body = jsonDecode(res.body); } catch (_) {}
    final msg = body is Map ? (body['message'] ?? body['error'] ?? res.reasonPhrase) : res.reasonPhrase;
    throw switch (code) {
      401 => AuthException.sessionExpired(),
      403 => AuthException.unauthorized(),
      404 => DataException.notFound(),
      409 => DataException.duplicate(),
      422 => DataException.validationFailed(msg?.toString() ?? 'Invalid input'),
      >= 500 => NetworkException.serverError(code),
      _ => ApiException(message: msg?.toString() ?? 'HTTP $code', statusCode: code),
    };
  }

  Future<Result<T>> _call<T>(Future<T> Function() fn) async {
    try {
      return Result.success(await fn());
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(NetworkException(message: e.toString(), originalException: e));
    }
  }
}









