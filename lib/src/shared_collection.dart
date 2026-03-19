part of '../local_shared.dart';

/// A collection is a container of documents inside `LocalShared`.
///
/// Use this class to manage whole collections and to access document-level operations:
/// creation, reading, updating, deleting, and migration.
///
/// Recommended usage:
/// ```dart
/// final collection = Shared.col('myCollection');
/// await collection.create();
/// await collection.doc('item1').create({'value': 1});
/// ```
class SharedCollection {
  /// Creates a new instance of [SharedCollection].
  ///
  /// The [id] parameter is the unique identifier for the collection, and the [controller] is used
  /// to listen for changes triggered by create, update, and delete actions on the collection.
  SharedCollection(this.id, {required StreamController<JSON> controller})
      : _controller = controller;

  /// The unique identifier for this collection.
  final String id;

  /// The stream controller used to listen for changes in the collection.
  late final StreamController<JSON> _controller;

  Future<List<String>> ids() async {
    final result = <String>[];
    try {
      JSON? collection = await Shared._read(id);
      if (collection != null) {
        for (var item in collection.entries) {
          result.add(item.key);
        }
      }

      return result;
    } catch (e) {
      debugPrint("Failed to get ids, reason: $e");
      return result;
    }
  }

  /// Creates a new collection.
  ///
  /// Optionally, it can replace an existing collection if [replace] is set to true.
  /// Returns a [SharedResponse] of [SharedMany] that indicating the success of the operation
  /// or [SharedNone] for failure of the operation.
  ///
  /// ```dart
  /// final response = await Shared.col(id).create();
  /// print(response); // SharedMany(success: true, message: '...', data: <JSON>[])
  /// ```
  Future<SharedResponse> create({
    bool replace = false,
  }) async {
    try {
      // [1] Get collection 📂.
      JSON? collection = await Shared._read(id);

      // [2] Check if its allowed to create by replacing an old collection or not 💪.
      if (collection != null && !replace) {
        throw 'The collection already exists. '
            'To proceed and replace the collection with ID `$id`, '
            'set the `replace` parameter to true.';
      }

      // [3] Create the collection 🎉.
      collection ??= {};
      bool result = await Shared._create(id, collection);

      // [4] Notify the stream about the change in the collection 📣.
      _controller.add({
        'id': id,
        'documents': [for (var item in collection.entries) item.value]
      });

      // [5] Returning the result of creating / replacing this collection 🚀.
      return SharedMany(
        success: result,
        message: result
            ? 'The collection with ID `$id` has been successfully ${replace ? 'recreated' : 'created'}.'
            : 'Failed to ${replace ? 'recreate' : 'create'} the collection with ID `$id`. Please try again.',
        data: [for (var item in collection.entries) item.value],
      );
    } catch (e) {
      // [6] Returning bad news 🧨.
      return SharedNone(message: '$e');
    }
  }

  /// Retrieves the contents of the collection.
  ///
  /// Returns [SharedResponse] of [SharedMany] for success and [SharedNone] for failure.
  ///
  /// ```dart
  /// final response = await Shared.col(id).read();
  /// print(response); // SharedMany(success: true, message: '...', data: <JSON>[])
  /// ```
  Future<SharedResponse> read() async {
    try {
      // [1] Get collection 📂.
      JSON? collection = await Shared._read(id);

      // [2] Check if collection exists or not 👻.
      if (collection == null) {
        throw 'Unable to read the collection. '
            'The specified collection with ID `$id` does not exist.';
      }

      // [3] Returning the result of retrieving this collection 🚀.
      return SharedMany(
        success: true,
        message:
            'The collection with ID `$id` has been successfully retrieved.',
        data: [for (var item in collection.entries) item.value],
      );
    } catch (e) {
      // [4] Returning bad news 🧨.
      return SharedNone(message: '$e');
    }
  }

  /// Updates the contents of the collection.
  ///
  /// Optionally, it can force update if the current collection does not exist, by setting [force] to true.
  /// Returns a [SharedResponse] of [SharedMany] indicating success or [SharedNone] for failure.
  ///
  /// ```dart
  /// final response = await Shared.col('myCollection').update({'id': {'key': 'value'}});
  /// print(response); // SharedMany(success: true, message: '...', data: <JSON>[])
  /// ```
  Future<SharedResponse> update(JSON document, {bool force = false}) async {
    try {
      // [1] Get collection 📂.
      JSON? collection = await Shared._read(id);

      // [2] Check if collection exists or not 👻.
      if (collection == null && !force) {
        throw 'Unable to update the collection. '
            'The specified collection with ID `$id` does not exist. '
            'To forcibly continue, set the `force` parameter to true. '
            'This action will create a new collection.';
      }

      // [3] Updating the collection 🎉.
      final bool result = await Shared._create(id, (collection ?? {}).merge(document));

      // [4] Notify the stream about the change in the collection 📣.
      _controller.add({
        'id': id,
        'documents': [
          for (var entry in ((await Shared._read(id)) ?? {}).entries)
            {'id': entry.key, 'data': entry.value},
        ]
      });

      final JSON updated = (await Shared._read(id)) ?? {};

      // [5] Returning the result of updating this collection 🚀.
      return SharedMany(
        success: result,
        message: result
            ? 'The collection with ID `$id` has been successfully updated.'
            : 'Failed to update the collection with ID `$id`. Please try again.',
        data: [for (var item in updated.entries) item.value as JSON],
      );
    } catch (e) {
      // [6] Returning bad news 🧨.
      return SharedNone(message: '$e');
    }
  }

  /// Merges (migrates) the current collection to a new collection with the specified [id].
  ///
  /// If [merge] is true and the target collection exists, both collection data sets are merged.
  /// If [merge] is false, the target must not exist unless [force] is set to true.
  /// Setting [force] true will allow migration from an empty source if the source collection is missing.
  /// Returns a [SharedResponse] of [SharedMany] indicating success or [SharedNone] for failure.
  ///
  /// ```dart
  /// final response = await Shared.col(id).merge(newId);
  /// print(response); // SharedMany(success: true, message: '...', data: <JSON>[])
  /// ```
  Future<SharedResponse> migrate(
    String id, {
    bool merge = false,
    bool force = false,
  }) async {
    try {
      // [1] Get current collection 📂.
      JSON? collection = await Shared._read(this.id);

      // [2] Get targeted collection 📂.
      JSON? target = await Shared._read(id);

      // [3] Check if the current collection id is exactly the same with the new one or not 💩.
      if (this.id == id && !force) {
        throw 'Unable to migrate the collection. '
            'The targeted collection ID cannot be the same as the current one.';
      }

      // [4] Check if current collection exists or not 👻.
      if (collection == null && !force) {
        throw 'Unable to migrate the collection. '
            'Current collection with ID `${this.id}` does not exist. '
            'To continue by forcing with empty collection, '
            'set the `force` parameter to true. '
            'This action is literally the same as making a new empty collection.';
      }

      // [5] Check if targeted collection exist or not 👼.
      if (target != null && !merge && this.id != id) {
        throw 'Unable to migrate the collection. '
            'Targeted collection with ID `$id` is already exist. '
            'WARNING: To proceed and merge the collection with ID `$id`, '
            'set the `merge` parameter to true. '
            'This action will merging the current collection with the targeted one. '
            'where the same key will prioritize the current collection';
      }

      JSON merged = (collection ?? {}).merge(target ?? {});

      // [6] Creating new collection 🎉.
      bool result = await Shared._create(id, merged);

      // [7] Notify the stream about the change in the collection 📣.
      _controller.add({
        'id': id,
        'documents': [
          for (var item in merged.entries) {'id': item.key, 'data': item.value}
        ]
      });

      if (result) {
        // [8] Delete the old collection 🧹.
        bool delete = this.id == id || await Shared._delete(this.id);

        // [9] Returning the result of migrating this collection 🚀.
        return SharedMany(
          success: delete,
          message: delete
              ? 'Successfully migrated the collection from ID `${this.id}` to ID `$id`.'
              : 'Failed to clear the old collection after migrating to the new ID. '
                  'Please try deleting the collection with ID `${this.id}` manually.',
          data: [
            for (var item
                in ((await Shared._read(delete ? id : this.id)) ?? {}).entries)
              item.value
          ],
        );
      }

      // [10] Sending bad news 💀.
      throw 'Failed to migrate the collection from ID ${this.id} to ID $id.';
    } catch (e) {
      // [11] Catching bad news 🧨.
      return SharedNone(message: '$e');
    }
  }


  /// Deletes the collection.
  ///
  /// Returns a [SharedResponse] of [SharedNone] indicating the success or failure of the deletion.
  ///
  /// ```dart
  /// final response = await Shared.col(id).delete();
  /// print(response): // SharedNone(success: true, message: '...')
  /// ```
  Future<SharedResponse> delete() async {
    try {
      // [1] Get collection 📂.
      JSON? collection = await Shared._read(id);

      // [2] Check if collection exists or not 👻.
      if (collection == null) {
        throw 'Unable to delete the collection. '
            'The specified collection with ID `$id` does not exist.';
      }

      // [3] Deleting the collection 🧹.
      bool result = await Shared._delete(id);

      // [4] Notify the stream about the change in the collection 📣.
      _controller.add({});

      // [5] Returning the result of deleting this collection 🚀.
      return SharedNone(
        success: result,
        message: result
            ? 'The collection with ID `$id` has been successfully deleted.'
            : 'Failed to delete the collection with ID `$id`. Please try again.',
      );
    } catch (e) {
      // [6] Returning bad news 🧨.
      return SharedNone(message: '$e');
    }
  }

  /// A shortcut to interact with [SharedDocument] trough [SharedCollection].
  ///
  /// ```dart
  /// await Shared.col(id).doc(id)...
  /// await Shared.collection(id).doc(id)...
  /// ```
  SharedDocument doc(String id) {
    return SharedDocument(
      id,
      collection: this,
    );
  }

  /// Another shortcut to interact with [SharedDocument] that not so short compared to [doc].
  ///
  /// ```dart
  /// await Shared.col(id).document(id)...
  /// await Shared.collection(id).document(id)...
  /// ```
  SharedDocument document(String id) {
    return doc(id);
  }

  /// A shortcut to interact with [SharedManyDocument] trough [SharedCollection].
  ///
  /// ```dart
  /// await Shared.col(id).docs(id)...
  /// await Shared.collection(id).docs(id)...
  /// ```
  SharedManyDocument docs(Iterable<String> ids) {
    return SharedManyDocument(ids, collection: this);
  }

  /// Another shortcut to interact with [SharedManyDocument] that not so short compared to [docs].
  ///
  /// ```dart
  /// await Shared.col(id).documents(id)...
  /// await Shared.collection(id).documents(id)...
  /// ```
  SharedManyDocument documents(Iterable<String> ids) {
    return docs(ids);
  }

  @override
  String toString() {
    return '$runtimeType(id: $id)';
  }
}
