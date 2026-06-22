import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:alpaca_mobile/core/exceptions/app_exception.dart';
import 'package:alpaca_mobile/core/utils/result.dart';

class ApiClient {
  ApiClient({String? baseUrl, http.Client? client, FirebaseAuth? auth})
      : _baseUrl = (baseUrl ?? _getDefaultBaseUrl()).replaceAll(RegExp(r'/$'), ''),
        _client = client ?? http.Client(),
        _auth = auth ?? FirebaseAuth.instance;

  static String _getDefaultBaseUrl() {
    return 'https://api-alpaca-zeta.vercel.app/api/v1';
  }

  final String _baseUrl;
  final http.Client _client;
  final FirebaseAuth _auth;

  Future<Map<String, String>> _headers() async {
    print('[ApiClient] Getting headers...');
    var user = _auth.currentUser;
    if (user == null) {
      print('[ApiClient] currentUser is null, waiting for authStateChanges...');
      user = await _auth.authStateChanges().first;
    }
    
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
    if (query == null) {
      print('[ApiClient] Request URI: $uri');
      return uri;
    }
    final q = Map.fromEntries(
      query.entries.where((e) => e.value != null).map((e) => MapEntry(e.key, e.value!)),
    );
    final finalUri = q.isEmpty ? uri : uri.replace(queryParameters: q);
    print('[ApiClient] Request URI: $finalUri');
    return finalUri;
  }

  Future<Result<T>> get<T>(String path, T Function(dynamic) fromJson,
          {Map<String, String?>? query}) =>
      _call(() async => _decode(
          await _client.get(_uri(path, query), headers: await _headers()), fromJson));

  /// Performs a GET request without an Authorization header.
  ///
  /// Use for public endpoints that are accessible by unauthenticated users
  /// (e.g. customers browsing the product catalog).
  Future<Result<T>> getPublic<T>(String path, T Function(dynamic) fromJson,
          {Map<String, String?>? query}) =>
      _call(() async {
        print('[ApiClient] GET PUBLIC $path query: $query');
        final response = await _client.get(_uri(path, query),
            headers: const {'Content-Type': 'application/json'});
        print('[ApiClient] GET PUBLIC response: ${response.statusCode}');
        return _decode(response, fromJson);
      });

  Future<Result<T>> post<T>(
          String path, Map<String, dynamic> body, T Function(dynamic) fromJson) =>
      _call(() async {
        print('[ApiClient] POST $path with body: $body');
        return _decode(
          await _client.post(_uri(path), headers: await _headers(), body: jsonEncode(body)),
          fromJson);
      });

  Future<Result<T>> put<T>(
          String path, Map<String, dynamic> body, T Function(dynamic) fromJson) =>
      _call(() async => _decode(
          await _client.put(_uri(path), headers: await _headers(), body: jsonEncode(body)),
          fromJson));

  Future<Result<void>> delete(String path) => _call(() async {
        _checkStatus(await _client.delete(_uri(path), headers: await _headers()));
      });

  Future<Result<String>> uploadImage(File file, {String? category}) => _call(() async {
        final uri = _uri('/upload/image');
        print('[ApiClient] Upload image to: $uri');
        final request = http.MultipartRequest('POST', uri);
        
        // Add headers (without Content-Type, will be set automatically with boundary)
        final headers = await _headers();
        headers.remove('Content-Type'); // Remove to let MultipartRequest set it
        request.headers.addAll(headers);
        
        // Compress and add file
        var bytes = await file.readAsBytes();
        final filename = file.path.split(RegExp(r'[/\\]')).last;
        final sizeInMB = bytes.length / (1024 * 1024);
        
        print('[ApiClient] Original file: $filename, size: ${sizeInMB.toStringAsFixed(2)} MB');
        
        // Compress if larger than 1MB
        if (sizeInMB > 1.0) {
          try {
            final compressed = await FlutterImageCompress.compressWithFile(
              file.absolute.path,
              quality: 70,
              minWidth: 1024,
              minHeight: 1024,
            );
            if (compressed != null) {
              bytes = compressed;
              print('[ApiClient] Compressed to: ${(bytes.length / (1024 * 1024)).toStringAsFixed(2)} MB');
            }
          } catch (e) {
            print('[ApiClient] Compression failed: $e, using original');
          }
        }
        
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ));
        
        // Add category field
        if (category != null) {
          request.fields['category'] = category;
          print('[ApiClient] Upload category: $category');
        }
        
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        
        print('[ApiClient] Upload response: ${response.statusCode}');
        print('[ApiClient] Upload body: ${response.body}');
        
        _checkStatus(response);
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        
        // Backend returns: { status, data: { image_url, ... } }
        String imageUrl;
        if (json is Map) {
          final data = json['data'];
          if (data is Map) {
            imageUrl = data['image_url'] ?? '';
          } else {
            imageUrl = data?.toString() ?? '';
          }
        } else {
          imageUrl = json.toString();
        }
        
        print('[ApiClient] Extracted image URL: $imageUrl');
        return imageUrl;
      });

  T _decode<T>(http.Response res, T Function(dynamic) fromJson) {
    _checkStatus(res);
    return fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  void _checkStatus(http.Response res) {
    print('[ApiClient] Response: ${res.statusCode} ${res.reasonPhrase}');
    final code = res.statusCode;
    if (code >= 200 && code < 300) return;
    
    print('[ApiClient] Error body: ${res.body}');
    
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









