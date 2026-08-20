import 'package:http_interceptor/http_interceptor.dart';

class LoggingInterceptor implements HttpInterceptor {
  @override
  Future<bool> shouldInterceptRequest({required BaseRequest request}) async {
    return true;
  }

  @override
  Future<bool> shouldInterceptResponse({required BaseResponse response}) async {
    return true;
  }

  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async {
    print('[HTTP] REQUEST => ${request.method} ${request.url}');
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    print('[HTTP] RESPONSE ${response.statusCode}');

    return response;
  }
}
