import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

Dio createDio() => Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
  ),
)..interceptors.add(NetworkLogInterceptor());

/// Logs metadata only: never headers, payloads, URL credentials, paths or queries.
class NetworkLogInterceptor extends Interceptor {
  NetworkLogInterceptor({void Function(String)? log})
    : _log = log ?? debugPrint;
  final void Function(String) _log;
  static const _timerKey = 'tibyan.network.timer';

  String _target(RequestOptions options) =>
      '${options.method} ${options.uri.origin}';
  String _elapsed(RequestOptions options) {
    final timer = options.extra.remove(_timerKey) as Stopwatch?;
    timer?.stop();
    return '${timer?.elapsedMilliseconds ?? 0}ms';
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      options.extra[_timerKey] = Stopwatch()..start();
      _log('[HTTP] ${_target(options)} started');
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      _log(
        '[HTTP] ${_target(response.requestOptions)} ${response.statusCode} ${_elapsed(response.requestOptions)}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      _log(
        '[HTTP] ${_target(err.requestOptions)} ${err.response?.statusCode ?? '-'} ${err.type.name} ${_elapsed(err.requestOptions)}',
      );
    }
    handler.next(err);
  }
}
