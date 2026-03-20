part of '../local_shared.dart';

/// A single document stored inside a collection.
///
/// Use this class for document-level CRUD in a collection:
/// create, read, update, delete, and migrate.
///
/// Example:
/// ```dart
/// final doc = Shared.col('users').doc('userA');
/// await doc.create({'name': 'Alice'});
/// ```
class SharedDocument {
  /// Creates a new instance of [SharedDocument].
  ///
  /// The [id] parameter is the unique identifier for the document, and the [collection] parameter
  /// specifies the [SharedCollection] to which the document belongs.
  const SharedDocument(this.id, {required this.collection});

  /// The unique identifier for this document.
  final String id;

  /// The [SharedCollection] to which this document belongs.
  final SharedCollection collection;

  /// Creates a new document within the associated collection.
  ///
  /// Optionally, it can merge an existing document if [merge] is set to true.
  /// Optionally, it can force creating new collection if the current collection does not exist, by setting [force] to true.
  /// Returns a [SharedResponse] of [SharedOne] for indicating the success or [SharedNone] for failure of the operation.
  ///
  /// ```dart
  /// final response = await Shared.col('myCollection').doc('documentId').create({'key': 'value'});
  /// print(response); // SharedOne(success: true, message: '...', data: JSON)
  /// ```
  Future<SharedResponse> create(
    JSON document, {
    bool merge = false,
    bool force = true,
  }) async {
    try {
      // [1] Get collection 📂.
      JSON? collection = await Shared._read(this.collection.id);

      // [2] Check if collection exist or not 👻.
      if (collection == null && !force) {
        throw 'Unable to create the document. '
            'The specified collection with ID `${this.collection.id}` does not exist. '
            'To continue set the `force` parameter to true. '
            'This action is equivalent to creating a new empty '
            'collection and continued by creating a document within it.';
      } else {
        // [3] Check if document exists or not 🕊.
        if (collection?[id] != null && !merge) {
          throw 'The document already exists. '
              'WARNING: To proceed and merge the document with ID `$id`, '
              'set the `merge` parameter to true. '
              'This action will irreversibly merge the old document.';
        }

        JSON merged = (collection?[id] as JSON? ?? {}).merge(document);

        // [4] Creating the document 🎉.
        bool result = await Shared._create(
          this.collection.id,
          ((collection ?? {})..addEntries([MapEntry(id, merged)])),
        );

        // [5] Notify the stream about the change in the collection 📣.
        this.collection._controller.add({
          'id': this.collection.id,
          'documents': [
            for (var item
                in ((await Shared._read(this.collection.id)) ?? {}).entries)
              {'id': item.key, 'data': item.value},
          ],
        });

        // [6] Returning the result of creating this document 🚀.
        return SharedOne(
          success: result,
          message: result
              ? 'The document with ID `$id` has been successfully ${merge ? 'merged' : 'created'}.'
              : 'Failed to ${merge ? 'merge' : 'create'} the document with ID `$id`. Please try again.',
          data: (await Shared._read(this.collection.id))?[id],
        );
      }
    } catch (e) {
      // [7] Returning bad news 🧨.
      return SharedNone(message: '$e');
    }
  }

  /// Retrieves the contents of the document.
  ///
  /// Returns a [SharedResponse] of [SharedOne] with the document data if successful and [SharedNone] for failure.
  ///
  /// ```dart
  /// final response = await Shared.col('myCollection').doc('documentId').read();
  /// print(response); // SharedOne(success: true, message: '...', data: JSON)
  /// ```
  Future<SharedResponse> read() async {
    try {
      // [1] Get collection 📂.
      JSON? collection = await Shared._read(this.collection.id);

      // [2] Check if collection exists or not 👻.
      if (collection == null) {
        throw 'Unable to read the document. '
            'The specified collection with ID `${this.collection.id}` does not exist.';
      }

      // [3] Check if document exist or not 🕊.
      if (collection[id] == null) {
        throw 'Unable to read the document. '
            'The specified document with ID `$id` does not exist.';
      }

      // [4] Returning the result of retrieving this document 🚀.
      return SharedOne(
        success: true,
        message: 'The document with ID `$id` has been successfully retrieved.',
        data: collection[id],
      );
    } catch (e) {
      // [5] Returning bad news 🧨.
      return SharedNone(message: '$e');
    }
  }

  /// Updates the contents of the document within the associated collection.
  ///
  /// Optionally, it can force update if the current document does not exist, by setting [force] to true.
  /// Returns a [SharedResponse] of [SharedOne] indicating the success or [SharedNone] for failure of the update.
  ///
  /// ```dart
  /// final response = await Shared.col('myCollection').doc('documentId').update({'newKey': 'newValue'});
  /// print(response); // SharedOne(success: true, message: '...', data: JSON)
  /// ```
  Future<SharedResponse> update(JSON document, {bool force = false}) async {
    try {
      // [1] Get collection 📂.
      JSON? collection = await Shared._read(this.collection.id);

      // [2] Check if collection exists or not 👻.
      if (collection == null && !force) {
        throw '''Unable to update the document. 
        The specified collection with ID `${this.collection.id}` does not exist. 
        To forcibly continue, 
        set the `force` parameter to true. 
        This action will create a new collection and a new document.''';
      }

      // [3] Check if document exist or not 🕊.
      if (collection?[id] == null && !force) {
        throw '''Unable to update the document. 
        The specified document with ID `$id` does not exist. 
        To forcibly continue, 
        set the `force` parameter to true. 
        This action will create a new document.''';
      }

      // [4] Updating the document 💼.
      bool result = await Shared._create(this.collection.id, <String, dynamic>{
        ...(collection ?? {}),
        id: (collection?[id] as JSON? ?? {}).merge(document),
      });

      // [5] Notify the stream about the change in the collection 📣.
      this.collection._controller.add({
        'id': this.collection.id,
        'documents': [
          for (var item
              in ((await Shared._read(this.collection.id)) ?? {}).entries)
            {'id': item.key, 'data': item.value},
        ],
      });

      // [6] Returning the result of updating this document 🚀.
      return SharedOne(
        success: result,
        message: result
            ? 'The document with ID `$id` has been successfully updated.'
            : 'Failed to update the document with ID `$id`. Please try again.',
        data: (await Shared._read(this.collection.id))?[id],
      );
    } catch (e) {
      // [7] Returning bad news 🧨.
      return SharedNone(message: '$e');
    }
  }

  /// Migrates the current document to a new document ID inside the same collection.
  ///
  /// If [merge] is true and the target document already exists, data is merged with the source document.
  /// If [merge] is false, the target document must not exist unless [force] is true.
  /// If [force] is true, missing source or collection is treated as empty to allow an incremental migration.
  ///
  /// ```dart
  /// final response = await Shared.col('myCollection').doc('doc1').migrate('doc2');
  /// print(response); // SharedOne(success: true, message: '...', data: JSON)
  /// ```
  Future<SharedResponse> migrate(
    String id, {
    bool merge = false,
    bool force = false,
  }) async {
    try {
      // [1] Get collection 📂.
      JSON? collection = await Shared._read(this.collection.id);

      // [2] Check collection existence 🔍.
      if (collection == null && !force) {
        throw '''Unable to migrate the document. 
        The specified collection with ID `${this.collection.id}` does not exist.''';
      }

      // [3] Source and destination cannot be identical.
      if (this.id == id && !force) {
        throw 'Unable to migrate the document. '
            'Source and destination document IDs cannot be the same.';
      }

      // [4] Source document existence.
      if (collection?[this.id] == null && !force) {
        throw '''Unable to migrate the document. 
        The source document with ID `${this.id}` does not exist.''';
      }

      // [5] Target existence check.
      if (collection?[id] != null && !merge && this.id != id) {
        throw 'Unable to migrate the document. '
            'The target document with ID `$id` already exists. '
            'To merge with existing target, set `merge` to true.';
      }

      final JSON sourceDoc = (collection?[this.id] as JSON?) ?? {};
      final JSON targetDoc = (collection?[id] as JSON?) ?? {};
      final JSON migratedDoc = collection?[id] != null && merge
          ? sourceDoc.merge(targetDoc)
          : sourceDoc;

      // [6] Write migrated collection.
      final JSON updatedCollection = JSON.from(collection ?? {})
        ..remove(this.id)
        ..[id] = migratedDoc;

      bool result = await Shared._create(this.collection.id, updatedCollection);

      // [7] Notify stream 📣.
      this.collection._controller.add({
        'id': this.collection.id,
        'documents': [
          for (var item
              in ((await Shared._read(this.collection.id)) ?? {}).entries)
            {'id': item.key, 'data': item.value},
        ],
      });

      // [8] Return.
      if (result) {
        return SharedOne(
          success: true,
          message:
              'The document with ID `${this.id}` has been successfully migrated to ID `$id`.',
          data: migratedDoc,
        );
      }

      throw 'Failed to migrate the document from ID `${this.id}` to ID `$id`.';
    } catch (e) {
      return SharedNone(message: '$e');
    }
  }

  /// Deletes the document within the associated collection.
  ///
  /// Returns a [SharedResponse] of [SharedNone] indicating the success or failure of the deletion.
  ///
  /// ```dart
  /// final response = await Shared.col('myCollection').doc('documentId').delete();
  /// print(response): // SharedNone(success: true, message: '...')
  /// ```
  Future<SharedResponse> delete() async {
    try {
      // [1] Get collection 📂.
      JSON? collection = await Shared._read(this.collection.id);

      // [2] Check if collection exists or not 👻.
      if (collection == null) {
        throw '''Unable to delete the document. 
        The specified collection with ID `${this.collection.id}` does not exist.''';
      }

      // [3] Check if document exists or not 🕊.
      if (collection[id] == null) {
        throw 'Unable to delete the document. '
            'The specified document with ID `$id` does not exist.';
      }

      // [4] Deleting the document 🧹.
      bool result = await Shared._create(
        this.collection.id,
        (collection..remove(id)),
      );

      // [5] Notify the stream about the change in the collection 📣.
      this.collection._controller.add({
        'id': this.collection.id,
        'documents': [
          for (var item
              in (await Shared._read(this.collection.id) ?? {}).entries)
            {'id': item.key, 'data': item.value},
        ],
      });

      // [6] Returning the result of deleting this document 🚀.
      return SharedNone(
        success: result,
        message: result
            ? 'The document with ID `$id` has been successfully deleted.'
            : 'Failed to delete the document with ID `$id`. Please try again.',
      );
    } catch (e) {
      // [7] Returning bad news 🧨.
      return SharedNone(message: '$e');
    }
  }

  @override
  String toString() {
    return '$runtimeType(id: $id, collection: $collection)';
  }
}
