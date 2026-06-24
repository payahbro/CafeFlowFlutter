import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cafe/core/errors/app_exception.dart';
import 'package:cafe/core/network/auth_token_provider.dart';

class ProductImageFile {
  const ProductImageFile({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });

  final Uint8List bytes;
  final String fileName;
  final String contentType;
}

abstract class ProductImageUploader {
  Future<String> upload({
    required ProductImageFile image,
    required String productName,
  });
}

class SupabaseProductImageUploader implements ProductImageUploader {
  SupabaseProductImageUploader({
    required this.supabaseUrl,
    required this.anonKey,
    required AuthTokenProvider authTokenProvider,
    HttpClient? client,
    DateTime Function()? now,
  }) : _authTokenProvider = authTokenProvider,
       _client = client ?? HttpClient(),
       _now = now ?? DateTime.now;

  final String supabaseUrl;
  final String anonKey;
  final AuthTokenProvider _authTokenProvider;
  final HttpClient _client;
  final DateTime Function() _now;

  @override
  Future<String> upload({
    required ProductImageFile image,
    required String productName,
  }) async {
    final token = _authTokenProvider();
    if (token == null || token.isEmpty) {
      throw AppException('Sesi login diperlukan untuk mengunggah foto.');
    }

    final objectName = _buildObjectName(productName, image.fileName);
    final uploadUri = _buildStorageUri(<String>[
      'storage',
      'v1',
      'object',
      'products',
      objectName,
    ]);

    HttpClientRequest request;
    try {
      request = await _client.postUrl(uploadUri);
      request.headers
        ..set('apikey', anonKey)
        ..set(HttpHeaders.authorizationHeader, 'Bearer $token')
        ..set(HttpHeaders.contentTypeHeader, image.contentType)
        ..set('x-upsert', 'false');
      request.contentLength = image.bytes.length;
      request.add(image.bytes);
    } catch (error) {
      throw AppException('Gagal menyiapkan upload foto: $error');
    }

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppException(
        _readErrorMessage(responseBody),
        statusCode: response.statusCode,
      );
    }

    return _buildStorageUri(<String>[
      'storage',
      'v1',
      'object',
      'public',
      'products',
      objectName,
    ]).toString();
  }

  Uri _buildStorageUri(List<String> storageSegments) {
    final baseUri = Uri.parse(supabaseUrl);
    return baseUri.replace(
      pathSegments: <String>[
        ...baseUri.pathSegments.where((segment) => segment.isNotEmpty),
        ...storageSegments,
      ],
    );
  }

  String _buildObjectName(String productName, String originalFileName) {
    final normalizedName = productName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final extension = _fileExtension(originalFileName);
    final prefix = normalizedName.isEmpty ? 'product' : normalizedName;
    return '$prefix-${_now().millisecondsSinceEpoch}.$extension';
  }

  String _fileExtension(String fileName) {
    final separatorIndex = fileName.lastIndexOf('.');
    if (separatorIndex == -1 || separatorIndex == fileName.length - 1) {
      return 'jpg';
    }
    final extension = fileName.substring(separatorIndex + 1).toLowerCase();
    return switch (extension) {
      'jpeg' || 'jpg' || 'png' || 'webp' => extension,
      _ => 'jpg',
    };
  }

  String _readErrorMessage(String responseBody) {
    if (responseBody.isNotEmpty) {
      try {
        final decoded = jsonDecode(responseBody);
        if (decoded is Map<String, dynamic>) {
          final message = decoded['message'] ?? decoded['error'];
          if (message is String && message.isNotEmpty) {
            return 'Upload foto gagal: $message';
          }
        }
      } catch (_) {
        // Fall through to the stable generic message.
      }
    }
    return 'Upload foto gagal.';
  }
}
