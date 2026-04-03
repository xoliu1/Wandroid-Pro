sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  R when<R>({
    required R Function(T data) success,
    required R Function(AIException error) failure,
  }) {
    return success(data);
  }
}

class Failure<T> extends Result<T> {
  final AIException error;
  const Failure(this.error);

  R when<R>({
    required R Function(T data) success,
    required R Function(AIException error) failure,
  }) {
    return failure(error);
  }
}

sealed class AIException implements Exception {
  final String message;
  final int? code;
  final dynamic originalError;

  const AIException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

class NetworkException extends AIException {
  const NetworkException(super.message, {super.code, super.originalError});
}

class APIException extends AIException {
  const APIException(super.message, {super.code, super.originalError});
}

class ConfigException extends AIException {
  const ConfigException(super.message, {super.code, super.originalError});
}

class ParseException extends AIException {
  const ParseException(super.message, {super.code, super.originalError});
}

class CancelledException extends AIException {
  const CancelledException() : super('请求已取消');
}

class TimeoutException extends AIException {
  const TimeoutException() : super('请求超时');
}

extension ResultExtension<T> on Result<T> {
  bool get isSuccess => this is Success<T>;

  bool get isFailure => this is Failure<T>;

  T? get dataOrNull {
    return switch (this) {
      Success(:final data) => data,
      Failure() => null,
    };
  }

  AIException? get errorOrNull {
    return switch (this) {
      Success() => null,
      Failure(:final error) => error,
    };
  }

  /// 转换数据
  Result<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success(:final data) => Success(transform(data)),
      Failure(:final error) => Failure(error),
    };
  }

  /// 链式调用
  Result<R> flatMap<R>(Result<R> Function(T data) transform) {
    return switch (this) {
      Success(:final data) => transform(data),
      Failure(:final error) => Failure(error),
    };
  }

  /// 获取数据或抛出异常
  T getOrThrow() {
    return switch (this) {
      Success(:final data) => data,
      Failure(:final error) => throw error,
    };
  }

  /// 获取数据或使用默认值
  T getOrElse(T Function() defaultValue) {
    return switch (this) {
      Success(:final data) => data,
      Failure() => defaultValue(),
    };
  }
}
