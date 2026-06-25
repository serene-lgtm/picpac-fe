import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'api_exception.dart';

class ApiClient {
  ApiClient({
    required String baseUrl,
    HttpClient? httpClient,
    this.timeout = const Duration(seconds: 20),
  }) : _baseUri = Uri.parse(baseUrl),
       _httpClient = httpClient ?? HttpClient();

  final Uri _baseUri;
  final HttpClient _httpClient;
  final Duration timeout;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String?> queryParameters = const {},
  }) async {
    final uri = _buildUri(path, queryParameters);
    final request = await _httpClient.getUrl(uri).timeout(timeout);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close().timeout(timeout);
    return _decodeObjectResponse(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final uri = _buildUri(path);
    final request = await _httpClient.postUrl(uri).timeout(timeout);
    request.headers
      ..set(HttpHeaders.acceptHeader, 'application/json')
      ..set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
    request.add(utf8.encode(jsonEncode(body)));
    final response = await request.close().timeout(timeout);
    return _decodeObjectResponse(response);
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final uri = _buildUri(path);
    final request = await _httpClient.putUrl(uri).timeout(timeout);
    request.headers
      ..set(HttpHeaders.acceptHeader, 'application/json')
      ..set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
    request.add(utf8.encode(jsonEncode(body)));
    final response = await request.close().timeout(timeout);
    return _decodeObjectResponse(response);
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final uri = _buildUri(path);
    final request = await _httpClient.openUrl('PATCH', uri).timeout(timeout);
    request.headers
      ..set(HttpHeaders.acceptHeader, 'application/json')
      ..set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
    request.add(utf8.encode(jsonEncode(body)));
    final response = await request.close().timeout(timeout);
    return _decodeObjectResponse(response);
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(path);
    final request = await _httpClient.deleteUrl(uri).timeout(timeout);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (body != null) {
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/json; charset=utf-8',
      );
      request.add(utf8.encode(jsonEncode(body)));
    }
    final response = await request.close().timeout(timeout);
    return _decodeObjectResponse(response);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    MultipartFilePart? file,
  }) async {
    final uri = _buildUri(path);
    final boundary = 'picpac-${DateTime.now().microsecondsSinceEpoch}';
    final request = await _httpClient.postUrl(uri).timeout(timeout);
    request.headers
      ..set(HttpHeaders.acceptHeader, 'application/json')
      ..set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );

    for (final entry in fields.entries) {
      request.write('--$boundary\r\n');
      request.write('Content-Disposition: form-data; name="${entry.key}"\r\n');
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

    final response = await request.close().timeout(timeout);
    return _decodeObjectResponse(response);
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

  Future<Map<String, dynamic>> _decodeObjectResponse(
    HttpClientResponse response,
  ) async {
    final body = await utf8.decodeStream(response);
    final statusCode = response.statusCode;
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
