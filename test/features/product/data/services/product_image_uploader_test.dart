import 'dart:io';
import 'dart:typed_data';

import 'package:cafe/features/product/data/services/product_image_uploader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpServer server;
  late Uri supabaseUrl;
  late HttpRequest capturedRequest;
  late Uint8List capturedBody;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    supabaseUrl = Uri.parse('http://${server.address.host}:${server.port}');

    server.listen((request) async {
      capturedRequest = request;
      capturedBody = Uint8List.fromList(
        await request.fold<List<int>>(
          <int>[],
          (bytes, chunk) => bytes..addAll(chunk),
        ),
      );
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write('{"Key":"products/double-shot-espresso-123.jpg"}');
      await request.response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
  });

  test('uploads image bytes and returns the public product URL', () async {
    final uploader = SupabaseProductImageUploader(
      supabaseUrl: supabaseUrl.toString(),
      anonKey: 'anon-key',
      authTokenProvider: () => 'access-token',
      now: () => DateTime.fromMillisecondsSinceEpoch(123),
    );
    final image = ProductImageFile(
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
      fileName: 'camera photo.JPG',
      contentType: 'image/jpeg',
    );

    final result = await uploader.upload(
      image: image,
      productName: 'Double Shot Espresso',
    );

    expect(capturedRequest.method, 'POST');
    expect(
      capturedRequest.uri.path,
      '/storage/v1/object/products/double-shot-espresso-123.jpg',
    );
    expect(capturedRequest.headers.value('apikey'), 'anon-key');
    expect(
      capturedRequest.headers.value(HttpHeaders.authorizationHeader),
      'Bearer access-token',
    );
    expect(capturedRequest.headers.contentType?.mimeType, 'image/jpeg');
    expect(capturedBody, <int>[1, 2, 3]);
    expect(
      result,
      '${supabaseUrl.toString()}'
      '/storage/v1/object/public/products/double-shot-espresso-123.jpg',
    );
  });
}
