import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'api_exception.dart';

class ApiClient {
  ApiClient({
    required String baseUrl,
    HttpClient? httpClient,
    this.accessTokenProvider,
    this.onUnauthorized,
    this.timeout = const Duration(seconds: 20),
  }) : _baseUri = Uri.parse(baseUrl),
       _httpClient = httpClient ?? HttpClient();

  final Uri _baseUri;
  final HttpClient _httpClient;
  final String? Function()? accessTokenProvider;
  final Future<bool> Function()? onUnauthorized;
  final Duration timeout;

  Future<bool>? _refreshInFlight;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String?> queryParameters = const {},
    bool requiresAuth = true,
  }) {
    return _sendWithRefresh(
      requiresAuth: requiresAuth,
      send: () async {
        final uri = _buildUri(path, queryParameters);
        final request = await _httpClient.getUrl(uri).timeout(timeout);
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        _setAuthorizationHeader(request, requiresAuth: requiresAuth);
        return request.close().timeout(timeout);
      },
    );
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
    bool requiresAuth = true,
  }) {
    return _sendWithRefresh(
      requiresAuth: requiresAuth,
      send: () async {
        final uri = _buildUri(path);
        final request = await _httpClient.postUrl(uri).timeout(timeout);
        request.headers
          ..set(HttpHeaders.acceptHeader, 'application/json')
          ..set(
            HttpHeaders.contentTypeHeader,
            'application/json; charset=utf-8',
          );
        _setAuthorizationHeader(request, requiresAuth: requiresAuth);
        request.add(utf8.encode(jsonEncode(body)));
        return request.close().timeout(timeout);
      },
    );
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    required Map<String, dynamic> body,
    bool requiresAuth = true,
  }) {
    return _sendWithRefresh(
      requiresAuth: requiresAuth,
      send: () async {
        final uri = _buildUri(path);
        final request = await _httpClient.putUrl(uri).timeout(timeout);
        request.headers
          ..set(HttpHeaders.acceptHeader, 'application/json')
          ..set(
            HttpHeaders.contentTypeHeader,
            'application/json; charset=utf-8',
          );
        _setAuthorizationHeader(request, requiresAuth: requiresAuth);
        request.add(utf8.encode(jsonEncode(body)));
        return request.close().timeout(timeout);
      },
    );
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    required Map<String, dynamic> body,
    bool requiresAuth = true,
  }) {
    return _sendWithRefresh(
      requiresAuth: requiresAuth,
      send: () async {
        final uri = _buildUri(path);
        final request = await _httpClient
            .openUrl('PATCH', uri)
            .timeout(timeout);
        request.headers
          ..set(HttpHeaders.acceptHeader, 'application/json')
          ..set(
            HttpHeaders.contentTypeHeader,
            'application/json; charset=utf-8',
          );
        _setAuthorizationHeader(request, requiresAuth: requiresAuth);
        request.add(utf8.encode(jsonEncode(body)));
        return request.close().timeout(timeout);
      },
    );
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) {
    return _sendWithRefresh(
      requiresAuth: requiresAuth,
      send: () async {
        final uri = _buildUri(path);
        final request = await _httpClient.deleteUrl(uri).timeout(timeout);
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        _setAuthorizationHeader(request, requiresAuth: requiresAuth);
        if (body != null) {
          request.headers.set(
            HttpHeaders.contentTypeHeader,
            'application/json; charset=utf-8',
          );
          request.add(utf8.encode(jsonEncode(body)));
        }
        return request.close().timeout(timeout);
      },
    );
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    MultipartFilePart? file,
    bool requiresAuth = true,
  }) {
    return _sendMultipart(
      'POST',
      path,
      fields: fields,
      file: file,
      requiresAuth: requiresAuth,
    );
  }

  Future<Map<String, dynamic>> putMultipart(
    String path, {
    required Map<String, String> fields,
    MultipartFilePart? file,
    bool requiresAuth = true,
  }) {
    return _sendMultipart(
      'PUT',
      path,
      fields: fields,
      file: file,
      requiresAuth: requiresAuth,
    );
  }

  Future<Map<String, dynamic>> _sendMultipart(
    String method,
    String path, {
    required Map<String, String> fields,
    MultipartFilePart? file,
    required bool requiresAuth,
  }) {
    return _sendWithRefresh(
      requiresAuth: requiresAuth,
      send: () async {
        final uri = _buildUri(path);
        final boundary = 'picpac-${DateTime.now().microsecondsSinceEpoch}';
        final request = await _httpClient.openUrl(method, uri).timeout(timeout);
        request.headers
          ..set(HttpHeaders.acceptHeader, 'application/json')
          ..set(
            HttpHeaders.contentTypeHeader,
            'multipart/form-data; boundary=$boundary',
          );
        _setAuthorizationHeader(request, requiresAuth: requiresAuth);

        for (final entry in fields.entries) {
          request.write('--$boundary\r\n');
          request.write(
            'Content-Disposition: form-data; name="${entry.key}"\r\n',
          );
          request.write('Content-Type: text/plain; charset=utf-8\r\n\r\n');
          request.add(utf8.encode(entry.value));
          request.write('\r\n');
        }
        if (file != null) {
          request.write('--$boundary\r\n');
          request.write(
            'Content-Disposition: form-data; name="${file.fieldName}"; '
            'filename="${file.fileName}"\r\n',
          );
          request.write('Content-Type: ${file.contentType}\r\n\r\n');
          request.add(await file.bytes);
          request.write('\r\n');
        }
        request.write('--$boundary--\r\n');

        return request.close().timeout(timeout);
      },
    );
  }

  Future<Map<String, dynamic>> _sendWithRefresh({
    required bool requiresAuth,
    required Future<HttpClientResponse> Function() send,
  }) async {
    var response = await send();
    var body = await utf8.decodeStream(response);

    if (_shouldRefresh(response.statusCode, requiresAuth)) {
      final refreshed = await _refreshAuthorization();
      if (refreshed) {
        response = await send();
        body = await utf8.decodeStream(response);
      }
    }

    return _decodeObjectBody(body, response.statusCode);
  }

  bool _shouldRefresh(int statusCode, bool requiresAuth) {
    if (!requiresAuth) return false;
    final token = accessTokenProvider?.call()?.trim();
    return statusCode == 401 && token != null && token.isNotEmpty;
  }

  Future<bool> _refreshAuthorization() async {
    final active = _refreshInFlight;
    if (active != null) {
      return active;
    }
    final future = onUnauthorized?.call() ?? Future<bool>.value(false);
    _refreshInFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_refreshInFlight, future)) {
        _refreshInFlight = null;
      }
    }
  }

  Uri _buildUri(
    String path, [
    Map<String, String?> queryParameters = const {},
  ]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final filteredQuery = <String, String>{};
    for (final entry in queryParameters.entries) {
      final value = entry.value;
      if (value != null && value.isNotEmpty) {
        filteredQuery[entry.key] = value;
      }
    }
    return _baseUri.replace(
      path: '${_baseUri.path.replaceFirst(RegExp(r'/$'), '')}$normalizedPath',
      queryParameters: filteredQuery.isEmpty ? null : filteredQuery,
    );
  }

  String resolveUrl(String url) {
    final value = url.trim();
    if (value.isEmpty) return '';
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) {
      if (uri.scheme == 'http' && !_isLocalHost(uri.host)) {
        return uri.replace(scheme: 'https').toString();
      }
      return uri.toString();
    }
    if (value.startsWith('//')) {
      return '${_baseUri.scheme}:$value';
    }
    final firstSegment = value.split('/').first;
    if (firstSegment.contains('.') && !value.startsWith('/')) {
      return 'https://$value';
    }
    return _baseUri.resolve(value).toString();
  }

  bool _isLocalHost(String host) {
    return host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '0.0.0.0' ||
        host == '::1';
  }

  Map<String, dynamic> _decodeObjectBody(String body, int statusCode) {
    if (statusCode < 200 || statusCode >= 300) {
      throw ApiException(body.isEmpty ? '请求失败' : body, statusCode: statusCode);
    }
    if (body.isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw ApiException('接口返回格式不是 JSON object', statusCode: statusCode);
  }

  void _setAuthorizationHeader(
    HttpClientRequest request, {
    required bool requiresAuth,
  }) {
    if (!requiresAuth) return;
    final token = accessTokenProvider?.call()?.trim();
    if (token == null || token.isEmpty) return;
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
  }
}

class MultipartFilePart {
  MultipartFilePart({
    required this.fieldName,
    required this.fileName,
    required this.contentType,
    required this.bytes,
  });

  final String fieldName;
  final String fileName;
  final String contentType;
  final Future<List<int>> bytes;
}
