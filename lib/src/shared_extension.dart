part of '../local_shared.dart';

/// Extension methods for enhancing [String] functionality.
extension StringExtension on String {
  /// Decodes a JSON-formatted string into a [JSON] object.
  JSON get decode => jsonDecode(this);
}

/// Extension methods for enhancing [List] functionality.
extension ListExtension on List {
  /// Validates the types of entries in a list against a provided list of allowed types.
  ///
  /// The [type] parameter specifies the list of allowed types.
  /// The [key] parameter is used in error messages to indicate the context of the validation.
  void validate(List<Type> type, {required String key}) {
    for (final entry in this) {
      if (entry is JSON) {
        entry.validate(type, key: key);
      } else if (entry is List) {
        entry.validate(type, key: key);
      } else {
        if (!type.contains(entry.runtimeType)) {
          throw ArgumentError(
              'Invalid type for key "$key": ${entry.runtimeType}');
        }
      }
    }
  }
}

/// Extension methods for enhancing [JSON] functionality.
extension JSONExtension on JSON {
  /// Validates the types of entries in a [JSON] object against a provided list of allowed types.
  ///
  /// The [type] parameter specifies the list of allowed types.
  /// The [key] parameter is used in error messages to indicate the context of the validation.
  void validate(List<Type> type, {required String key}) {
    for (final entry in entries) {
      if (entry.value is JSON) {
        (entry.value as JSON).validate(type, key: '$key.${entry.key}');
      } else if (entry.value is List) {
        (entry.value as List).validate(type, key: '$key.${entry.key}');
      } else {
        if (!type.contains(entry.value.runtimeType)) {
          throw ArgumentError(
              'Invalid type for key "$key.${entry.key}": ${entry.value.runtimeType}');
        }
      }
    }
  }

  /// Merges the current [JSON] object with another [JSON] object.
  ///
  /// The [value] parameter is the [JSON] object to merge into the current object.
  /// The merge operation combines the key-value pairs from both objects.
  /// If a key exists in both objects and the values are themselves [JSON] or [Map] objects,
  /// the values are recursively merged.
  JSON merge(JSON value) {
    Map<String, dynamic> result = Map.from(this);

    for (var key in value.keys) {
      if (result.containsKey(key) && result[key] is Map && value[key] is Map) {
        result[key] = (result[key] as JSON).merge(value[key]);
      } else {
        result[key] = value[key];
      }
    }

    return result;
  }

  /// Encodes the [JSON] object into a JSON-formatted string.
  ///
  /// The method also performs a validation check on the types of entries in the [JSON] object.
  String get encode {
    for (var entry in entries) {
      (entry.value as JSON).validate(
        [String, int, double, bool, List, JSON],
        key: entry.key,
      );
    }
    return jsonEncode(this);
  }
}

/// Extension on [SharedResponse] providing convenience getters for handling
/// responses with one or many data items.
extension SharedResponseExtension on SharedResponse {
  /// Expect a single JSON data if the response is [SharedOne].
  ///
  /// Returns `null` if the response is not [SharedOne] type.
  ///
  /// ```dart
  /// final result = await Shared.col(id).doc(id).read();
  /// JSON? value = result.one;
  /// ```
  JSON? get one {
    if (this is SharedOne || this is SharedResponse<JSON>) {
      return data as JSON?;
    } else {
      return null;
    }
  }

  /// Expect a list of JSON data if the response is [SharedMany].
  ///
  /// Returns `null` if the response is not [SharedMany] type.
  ///
  /// ```dart
  /// final result = await Shared.col(id).read();
  /// List<JSON>? value = result.many;
  /// ```
  List<JSON>? get many {
    if (this is SharedMany || this is SharedResponse<List<JSON>>) {
      return data as List<JSON>?;
    } else {
      return null;
    }
  }
}

/// Extension on Future of [SharedResponse] providing convenience getters for handling
/// asynchronous responses with one or many data items.
extension FutureSharedResponseExtension on Future<SharedResponse> {
  /// Retrieves a single JSON data when the response is [SharedOne].
  ///
  /// Returns `null` if the response is not [SharedOne] type.
  ///
  /// ```dart
  /// JSON? result = await Shared.col(id).doc(id).read().one;
  /// ```
  Future<JSON?> get one async {
    final response = await this;
    if (response is SharedOne || response is SharedResponse<JSON>) {
      return response.data as JSON?;
    } else {
      return null;
    }
  }

  /// Retrieves a list of JSON data when the response is [SharedMany].
  ///
  /// Returns `null` if the response is not [SharedMany] type.
  ///
  /// ```dart
  /// List<JSON>? result = await Shared.col(id).read().many;
  /// ```
  Future<List<JSON>?> get many async {
    final response = await this;
    if (response is SharedMany || response is SharedResponse<List<JSON>>) {
      return response.data as List<JSON>?;
    } else {
      return null;
    }
  }
}
