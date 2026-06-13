import 'dart:convert';
import 'dart:io';

import 'package:cafe/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpServer server;
  late Uri baseUri;
  Map<String, dynamic>? capturedHeaders;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUri = Uri.parse('http://${server.address.host}:${server.port}');
    capturedHeaders = null;

    server.listen((request) async {
      capturedHeaders = <String, dynamic>{
        'authorization': request.headers.value(HttpHeaders.authorizationHeader),
      };
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(<String, dynamic>{'success': true}));
      await request.response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
  });

  test('adds bearer token from auth token provider', () async {
    final client = ApiClient(
      baseUrl: baseUri.toString(),
      authTokenProvider: () => 'token-123',
    );

    await client.get('/profile');

    expect(capturedHeaders?['authorization'], 'Bearer token-123');
  });
}
