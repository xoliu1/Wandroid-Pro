import 'package:dio/dio.dart';

class BaseResp<T> {
  final T? data;
  final int errorCode;
  final String errorMsg;
   Response<dynamic>? rawResponse;

  BaseResp({
    required this.data,
    required this.errorCode,
    required this.errorMsg,
    this.rawResponse,  // 移除了下划线前缀，改为合法的参数名
  });

  factory BaseResp.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    return BaseResp<T>(
      data: fromJsonT != null && json['data'] != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      errorCode: json['errorCode'] ?? 0,
      errorMsg: json['errorMsg'] ?? '',
    );
  }

  bool get isSuccess => errorCode == 0;
  bool get needLogin => errorCode == -1001;
}
