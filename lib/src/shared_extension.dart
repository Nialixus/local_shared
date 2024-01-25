import 'dart:convert';

import 'package:local_shared/local_shared.dart';

export 'shared_extension.dart' hide StringExtension, JSONExtension;

extension StringExtension on String {
  JSON get decode => jsonDecode(this);
}

extension ListExtension on List {
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

extension JSONExtension on JSON {
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

  String get encode {
    for (var entry in entries) {
      (entry.value as JSON).validate(
        [String, int, double, bool, List, JSON],
        key: entry.key,
      );
    }
    return jsonEncode(this);
  }

  List<JSON> get toList => [for (var item in entries) item.value];
}
