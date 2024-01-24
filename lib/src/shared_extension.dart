import 'dart:convert';

import 'package:local_shared/local_shared.dart';

export 'shared_extension.dart'
    hide DynamicExtension, StringExtension, JSONExtension;

extension DynamicExtension on dynamic {
  T? validate<T extends dynamic>([
    List<Type> allowed = const [String, int, double, bool, JSON, List<dynamic>],
  ]) {
    if (this == null) {
      return null;
    } else if (this is List) {
      return this.map((item) => item.validate(allowed)).toList() as T?;
    } else if (this is JSON) {
      Map<String, T> result = {};
      this.forEach((key, nestedValue) {
        result[key] = nestedValue.validate(allowed);
      });
      return result as T?;
    } else if (!allowed.contains(runtimeType)) {
      throw ArgumentError('Invalid data type: $runtimeType');
    }

    return this as T?;
  }
}

extension StringExtension on String {
  JSON get decode => jsonDecode(this);
}

extension JSONExtension on JSON {
  String get encode => jsonEncode(this);
  List<JSON> get toList => [for (var item in entries) item.value];
}
