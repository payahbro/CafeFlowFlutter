import 'dart:convert';
import 'dart:io';

import 'package:cafe/core/errors/app_exception.dart';

class ApiRawResponse {
  const ApiRawResponse({
    required this.bytes,
    required this.headers,
    required this.statusCode,
  });

  final List<int> bytes;
  final Map<String, String> headers;
  final int statusCode;
}

class ApiClient {
  ApiClient({required this.baseUrl, HttpClient? client})
    : _client = client ?? HttpClient();

  final String baseUrl;
  final HttpClient _client;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _request(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  Future<ApiRawResponse> getRaw(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _rawRequest(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _request(
      method: 'POST',
      path: path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _request(
      method: 'PUT',
      path: path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _request(
      method: 'PATCH',
      path: path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _request(
      method: 'DELETE',
      path: path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters == null
          ? null
          : queryParameters.map(
              (key, value) => MapEntry(key, value.toString()),
            ),
    );

    HttpClientRequest request;
    try {
      request = await _client.openUrl(method, uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      headers?.forEach(request.headers.set);

      if (body != null) {
        request.write(jsonEncode(body));
      }
    } catch (error) {
      throw AppException('Network error: $error');
    }

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    final decoded = responseBody.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(responseBody) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorObject = decoded['error'];
      if (errorObject is Map<String, dynamic>) {
        throw AppException(
          (errorObject['message'] as String?) ?? 'Request failed',
          code: errorObject['code'] as String?,
          statusCode: response.statusCode,
        );
      }

      throw AppException(
        'Request failed with status ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    return decoded;
  }

  Future<ApiRawResponse> _rawRequest({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters == null
          ? null
          : queryParameters.map(
              (key, value) => MapEntry(key, value.toString()),
            ),
    );

    HttpClientRequest request;
    try {
      request = await _client.openUrl(method, uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      headers?.forEach(request.headers.set);

      if (body != null) {
        request.write(jsonEncode(body));
      }
    } catch (error) {
      throw AppException('Network error: $error');
    }

    final response = await request.close();
    final bytes = await response.fold<List<int>>(
      <int>[],
      (previous, element) => previous..addAll(element),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final responseBody = bytes.isEmpty ? '' : utf8.decode(bytes);
      final decoded = responseBody.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(responseBody) as Map<String, dynamic>;
      final errorObject = decoded['error'];
      if (errorObject is Map<String, dynamic>) {
        throw AppException(
          (errorObject['message'] as String?) ?? 'Request failed',
          code: errorObject['code'] as String?,
          statusCode: response.statusCode,
        );
      }

      throw AppException(
        'Request failed with status ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final headersMap = <String, String>{};
    response.headers.forEach((name, values) {
      headersMap[name] = values.join(',');
    });

    return ApiRawResponse(
      bytes: bytes,
      headers: headersMap,
      statusCode: response.statusCode,
    );
  }
}
