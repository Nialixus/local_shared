part of '../local_shared.dart';

abstract class SharedResponse<T extends Object> {
  const SharedResponse({
    this.success = false,
    required this.message,
    this.data,
  });

  final bool success;
  final String message;
  final T? data;

  @override
  String toString() {
    String content = {
      'success': success,
      'message': message,
      if (data != null) 'data': data,
    }.toString();
    return '$runtimeType(${content.substring(1, content.length - 1)})';
  }
}

class SharedOne extends SharedResponse<JSON> {
  const SharedOne({
    super.success,
    required super.message,
    required super.data,
  });
}

class SharedMany extends SharedResponse<List<JSON>> {
  const SharedMany({
    super.success,
    required super.message,
    required super.data,
  });
}

class SharedNone extends SharedResponse {
  const SharedNone({
    super.success,
    required super.message,
  }) : super(data: null);
}
