import 'dart:async';

import 'package:fixpk/core/network/bounded_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'timeouts cancel the transport instead of leaving a write running',
    () async {
      var aborted = false;
      final client = BoundedClient(
        MockClient.streaming((request, body) {
          unawaited(
            (request as http.Abortable).abortTrigger!.then(
              (_) => aborted = true,
            ),
          );
          return Completer<http.StreamedResponse>().future;
        }),
        requestTimeout: const Duration(milliseconds: 10),
      );
      addTearDown(client.close);
      await expectLater(
        client.post(Uri.parse('https://example.test/rest/v1/quotes')),
        throwsA(isA<TimeoutException>()),
      );
      await Future<void>.delayed(Duration.zero);
      expect(aborted, isTrue);
    },
  );

  test('forwarding preserves authorization and multipart boundaries', () async {
    final client = BoundedClient(
      MockClient((request) async {
        expect(request.headers['apikey'], 'publishable-test-key');
        expect(
          request.headers['content-type'],
          startsWith('multipart/form-data; boundary='),
        );
        expect(request.body, contains('fixture image'));
        return http.Response('saved', 201);
      }),
    );
    addTearDown(client.close);
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse('https://example.test/storage/v1/object/files/test'),
          )
          ..headers['apikey'] = 'publishable-test-key'
          ..files.add(
            http.MultipartFile.fromString(
              'file',
              'fixture image',
              filename: 'test.txt',
            ),
          );
    final response = await http.Response.fromStream(await client.send(request));
    expect(response.statusCode, 201);
  });

  test('a stalled write times out without being sent a second time', () async {
    var calls = 0;
    final client = BoundedClient(
      MockClient((_) {
        calls++;
        return Completer<http.Response>().future;
      }),
      requestTimeout: const Duration(milliseconds: 10),
    );
    addTearDown(client.close);
    await expectLater(
      client.post(Uri.parse('https://example.test/rest/v1/quotes')),
      throwsA(isA<TimeoutException>()),
    );
    expect(calls, 1);
  });

  test('a stalled response body also times out', () async {
    final body = StreamController<List<int>>();
    final client = BoundedClient(
      MockClient.streaming(
        (_, _) async => http.StreamedResponse(body.stream, 200),
      ),
      requestTimeout: const Duration(milliseconds: 10),
    );
    addTearDown(() {
      client.close();
      unawaited(body.close());
    });
    await expectLater(
      client.get(Uri.parse('https://example.test/rest/v1/services')),
      throwsA(isA<TimeoutException>()),
    );
  });

  test(
    'slow attachment upload uses the longer budget and keeps response metadata',
    () async {
      final client = BoundedClient(
        MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 25));
          return http.Response(
            'saved',
            201,
            headers: {'x-request-id': 'upload-1'},
          );
        }),
        requestTimeout: const Duration(milliseconds: 1),
        uploadTimeout: const Duration(seconds: 1),
      );
      addTearDown(client.close);
      final response = await client.post(
        Uri.parse(
          'https://example.test/storage/v1/object/request-attachments/file',
        ),
      );
      expect(response.statusCode, 201);
      expect(response.body, 'saved');
      expect(response.headers['x-request-id'], 'upload-1');
    },
  );
}
