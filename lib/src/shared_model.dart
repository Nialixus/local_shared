part of '../local_shared.dart';

abstract class SharedModel<T extends Object> {
  const SharedModel({
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

class SharedOne extends SharedModel<JSON> {
  const SharedOne({
    super.success,
    required super.message,
    required super.data,
  });
}

class SharedMany extends SharedModel<List<JSON>> {
  const SharedMany({
    super.success,
    required super.message,
    required super.data,
  });
}

class SharedNone extends SharedModel {
  const SharedNone({
    super.success,
    required super.message,
  }) : super(data: null);
}
