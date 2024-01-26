part of '../local_shared.dart';

/// Represents the response of an operation in [LocalShared].
///
/// A [SharedResponse] contains information about the success or failure of an operation,
/// along with an optional data payload. This is an abstract class, and concrete implementations
/// include [SharedOne], [SharedMany], and [SharedNone].
///
/// Usage example:
/// ```dart
/// final response = SharedOne(success: true, message: 'Operation successful', data: {'key': 'value'});
/// print(response); // SharedOne(success: true, message: 'Operation successful', data: {'key': 'value'})
/// ```
abstract class SharedResponse<T extends Object> {
  /// Creates a new instance of [SharedResponse].
  ///
  /// The [success] parameter indicates whether the operation was successful or not.
  /// The [message] parameter provides additional information about the operation.
  /// The [data] parameter holds the data payload of the response.
  const SharedResponse({
    this.success = false,
    required this.message,
    this.data,
  });

  /// Indicates whether the operation was successful.
  final bool success;

  /// Additional information about the operation.
  final String message;

  /// The data payload of the response.
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

/// Represents a response containing a single data item.
///
/// [SharedOne] is used when an operation results in a single data item.
/// The data item is typically represented as a JSON object.
///
/// Usage example:
/// ```dart
/// final response = SharedOne(success: true, message: 'Operation successful', data: {'key': 'value'});
/// print(response); // SharedOne(success: true, message: 'Operation successful', data: {'key': 'value'})
/// ```
class SharedOne extends SharedResponse<JSON> {
  /// Creates a new instance of [SharedOne].
  ///
  /// The [success] parameter indicates whether the operation was successful or not.
  /// The [message] parameter provides additional information about the operation.
  /// The [data] parameter holds the single data item of the response.
  const SharedOne({
    super.success,
    required super.message,
    required super.data,
  });
}

/// Represents a response containing a list of data items.
///
/// [SharedMany] is used when an operation results in multiple data items.
/// The data items are typically represented as a list of JSON objects.
///
/// Usage example:
/// ```dart
/// final response = SharedMany(success: true, message: 'Operation successful', data: [{'key': 'value1'}, {'key': 'value2'}]);
/// print(response); // SharedMany(success: true, message: 'Operation successful', data: [{'key': 'value1'}, {'key': 'value2'}])
/// ```
class SharedMany extends SharedResponse<List<JSON>> {
  /// Creates a new instance of [SharedMany].
  ///
  /// The [success] parameter indicates whether the operation was successful or not.
  /// The [message] parameter provides additional information about the operation.
  /// The [data] parameter holds the list of data items of the response.
  const SharedMany({
    super.success,
    required super.message,
    required super.data,
  });
}

/// Represents a response indicating the absence of data.
///
/// [SharedNone] is used when an operation does not produce any data.
///
/// Usage example:
/// ```dart
/// final response = SharedNone(success: true, message: 'Operation successful');
/// print(response); // SharedNone(success: true, message: 'Operation successful')
/// ```
class SharedNone extends SharedResponse {
  /// Creates a new instance of [SharedNone].
  ///
  /// The [success] parameter indicates whether the operation was successful or not.
  /// The [message] parameter provides additional information about the operation.
  const SharedNone({
    super.success,
    required super.message,
  }) : super(data: null);
}
