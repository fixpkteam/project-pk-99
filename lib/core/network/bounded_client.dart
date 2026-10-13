import 'dart:async';

import 'package:http/http.dart' as http;

/// Bounds both connection and body reads. Never blindly retries writes.
class BoundedClient extends http.BaseClient {
  BoundedClient(
    this._inner, {
    this.requestTimeout = const Duration(seconds: 20),
    this.uploadTimeout = const Duration(minutes: 5),
  });
  final http.Client _inner;
  final Duration requestTimeout;
  final Duration uploadTimeout;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final isUpload = request.url.path.contains('/storage/v1/object/');
    final limit = isUpload ? uploadTimeout : requestTimeout;
    final abort = Completer<void>();
    void cancel() {
      if (!abort.isCompleted) abort.complete();
    }

    final forwarded = _AbortableForwardRequest(request, abort.future);
    final response = await _inner
        .send(forwarded)
        .timeout(
          limit,
          onTimeout: () {
            cancel();
            throw TimeoutException('The connection timed out.', limit);
          },
        );
    return http.StreamedResponse(
      response.stream.timeout(
        limit,
        onTimeout: (sink) {
          cancel();
          sink.addError(TimeoutException('The response timed out.', limit));
          sink.close();
        },
      ),
      response.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() => _inner.close();
}

/// Preserves streamed/multipart bodies without buffering a second copy.
class _AbortableForwardRequest extends http.BaseRequest with http.Abortable {
  _AbortableForwardRequest(this.original, Future<void> timeout)
    : abortTrigger = original is http.Abortable && original.abortTrigger != null
          ? Future.any([timeout, original.abortTrigger!])
          : timeout,
      super(original.method, original.url) {
    followRedirects = original.followRedirects;
    maxRedirects = original.maxRedirects;
    persistentConnection = original.persistentConnection;
  }
  final http.BaseRequest original;
  @override
  final Future<void> abortTrigger;

  @override
  http.ByteStream finalize() {
    final body = original.finalize();
    // Multipart requests add their boundary header during finalization.
    headers.addAll(original.headers);
    contentLength = original.contentLength;
    super.finalize();
    return body;
  }
}
