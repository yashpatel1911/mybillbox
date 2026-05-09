import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'environment.dart';

/// Unified API helper for all HTTP calls.
///
/// All methods build the URL as: [Environment.apiUrl] + [endpoint].
/// Auth is optional — pass [token] to include `Authorization: Bearer <token>`.
class Api {
  static const _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ──────────────────────────────────────────────────
  // PUBLIC METHODS
  // ──────────────────────────────────────────────────

  /// GET request. [query] adds URL query params (?key=value&...).
  static Future<dynamic> get(
    String endpoint, {
    Map<String, String>? query,
    String? token,
  }) {
    return _send(method: 'GET', endpoint: endpoint, query: query, token: token);
  }

  /// POST request with JSON body.
  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) {
    return _send(method: 'POST', endpoint: endpoint, body: body, token: token);
  }

  /// PUT request with JSON body.
  static Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) {
    return _send(method: 'PUT', endpoint: endpoint, body: body, token: token);
  }

  /// PATCH request with JSON body.
  static Future<dynamic> patch(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) {
    return _send(method: 'PATCH', endpoint: endpoint, body: body, token: token);
  }

  /// DELETE request.
  static Future<dynamic> delete(String endpoint, {String? token}) {
    return _send(method: 'DELETE', endpoint: endpoint, token: token);
  }

  /// Multipart upload. Defaults to POST; pass [method] = 'PUT' or 'PATCH'
  /// for multipart updates.
  static Future<dynamic> uploadFiles(
    String endpoint, {
    required Map<String, String> files,
    Map<String, String>? fields,
    String method = 'POST',
    String? token,
  }) async {
    final url = _buildUrl(endpoint);
    _log('$method (multipart)', url, fields);

    final request = http.MultipartRequest(method, Uri.parse(url));

    if (token != null && token.trim().isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';

    if (fields != null) request.fields.addAll(fields);

    for (final entry in files.entries) {
      request.files.add(
        await http.MultipartFile.fromPath(entry.key, entry.value),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _parse(response, url);
  }

  // ──────────────────────────────────────────────────
  // INTERNAL
  // ──────────────────────────────────────────────────

  static String _buildUrl(String endpoint, [Map<String, String>? query]) {
    final base = Environment().apiUrl + endpoint;
    if (query == null || query.isEmpty) return base;
    final qs = query.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');
    return base.contains('?') ? '$base&$qs' : '$base?$qs';
  }

  static Map<String, String> _headers(String? token) {
    final h = Map<String, String>.from(_jsonHeaders);
    if (token != null && token.trim().isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  static Future<dynamic> _send({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    String? token,
  }) async {
    final url = _buildUrl(endpoint, query);
    final headers = _headers(token);
    final encodedBody = body != null ? jsonEncode(body) : null;

    _log(method, url, body);

    try {
      final uri = Uri.parse(url);
      final http.Response response;

      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(uri, headers: headers, body: encodedBody);
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: encodedBody);
          break;
        case 'PATCH':
          response = await http.patch(uri, headers: headers, body: encodedBody);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      return _parse(response, url);
    } catch (e) {
      dev.log('❌ $method $url → $e');
      rethrow;
    }
  }

  static dynamic _parse(http.Response response, String url) {
    final ct = response.headers['content-type'] ?? '';
    final preview = response.body.length > 400
        ? '${response.body.substring(0, 400)}…'
        : response.body;

    dev.log('📥 ${response.statusCode} $url\n   CT: $ct\n   Body: $preview');

    final looksLikeHtml = response.body.trimLeft().startsWith('<');
    if (!ct.contains('application/json') || looksLikeHtml) {
      throw Exception(
        'Server returned non-JSON (status ${response.statusCode}). '
        'URL: $url',
      );
    }

    try {
      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Invalid JSON response: $e');
    }
  }

  static void _log(String method, String url, dynamic body) {
    dev.log('🌐 $method $url');
    if (body != null) {
      try {
        dev.log('   Body: ${body is String ? body : jsonEncode(body)}');
      } catch (_) {
        dev.log('   Body: $body');
      }
    }
  }
}
