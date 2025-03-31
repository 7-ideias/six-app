import 'package:http_interceptor/http_interceptor.dart';

class LoggingInterceptor implements InterceptorContract {
  @override
  Future<RequestData> interceptRequest({required RequestData data}) async {
    print('[HTTP] REQUEST => ${data.method} ${data.url}');
    print('[HEADERS] => ${data.headers}');
    print('[BODY] => ${data.body}');
    return data;
  }

  @override
  Future<ResponseData> interceptResponse({required ResponseData data}) async {
    print('[HTTP] RESPONSE ${data.statusCode} => ${data.body}');
    return data;
  }
}
