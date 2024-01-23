library local_shared;

import 'dart:convert';

import 'package:local_shared/src/shared_extension.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'src/shared_model.dart';

typedef JSON = Map<String, dynamic>;

class LocalShared {
  const LocalShared(this.id) : assert(id.length != 0, 'id shouldn\'t be empty');

  /// Id of this collection.
  final String id;

  Future<SharedModel> create(
    String? id, {
    JSON document = const {},
    bool upsert = false,
  }) async {
    assert(id == null && document.isEmpty,
        'If id is not provided the document should be empty');
    assert(id != null && document.isNotEmpty,
        'If id is provided the document should not be empty');

    // [1] Load the box 📦.
    SharedPreferences databox = await SharedPreferences.getInstance();

    try {
      // [2] Load collection 🥩.
      JSON? collection = databox.getString(this.id)?.decode;
      bool isCollectionExist = collection != null;
      bool isTargetingDocument = id != null;

      if (isCollectionExist) {
      } else {
        if (isTargetingDocument) {
          if (!upsert) {}
        }

        bool isSuccess = await databox.setString(
          this.id,
          jsonEncode(document.validate()),
        );

        return SharedNone(
          success: isSuccess,
          message: isSuccess
              ? 'The collection was successfully created.'
              : 'Failed to create the collection.',
        );
      }

      // if (rawCollection != null) {
      //   // Check if collection
      //   if (id == null) {
      //     return const SharedNone(message: 'Collection already exist!');
      //   } else {
      //     JSON collection = jsonDecode(rawCollection);
      //   }
      // } else {
      //   if (id == null) {
      //     await box.
      //   }
      // }
      // if (read.keys.contains(id) && !upsert) {
      //   return const SharedNone(message: 'Document already exist!');
      // } else {
      //   await box.setString(
      //       this.id,
      //       jsonEncode({
      //         ...read,
      //         ...{id: document}
      //       }));
      //   return SharedOne(
      //     success: true,
      //     message: 'Successfully ${upsert ? 'replacing' : 'creating'} item',
      //     data: document,
      //   );
      // }
      return const SharedNone(message: 'message');
    } catch (e) {
      return SharedNone(message: e.toString());
    }
  }
}
