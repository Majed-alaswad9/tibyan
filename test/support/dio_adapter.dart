import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

class StubDioAdapter implements HttpClientAdapter {
  StubDioAdapter(this.respond);
  final FutureOr<ResponseBody> Function(RequestOptions) respond;
  bool closed = false;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => respond(options);
  @override
  void close({bool force = false}) {
    closed = true;
  }
}
