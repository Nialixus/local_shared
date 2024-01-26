part of '../local_shared.dart';

/// Represents a document within a [SharedCollection] in [LocalShared] storage.
///
/// Documents are individual pieces of data stored within a collection.
/// This class provides methods for creating, reading, updating, and deleting documents
/// within the context of a specific collection.
/// ---
/// ```dart
/// // Create a new document within a collection
/// final result = await Shared.col('myCollection').doc('documentId').create({'key': 'value'});
/// print(response); // SharedOne(success: true, message: '...', data: JSON)
/// ```
/// ---
/// ```dart
/// // Read the contents of a document within a collection
/// final response = await Shared.col('myCollection').doc('documentId').read();
/// print(response); // SharedOne(success: true, message: '...', data: JSON)
/// ```
/// ---
/// ```dart
/// // Update the contents of a document within a collection
/// final response = await Shared.col('myCollection').doc('documentId').update({'newKey': 'newValue'});
/// print(response); // SharedOne(success: true, message: '...', data: JSON)
/// ```
/// ---
/// ```dart
/// // Delete a document within a collection
/// final response = await Shared.col('myCollection').doc('documentId').delete();
/// print(response): // SharedNone(success: true, message: '...')
/// ```
class SharedDocument {
  /// Creates a new instance of [SharedDocument].
  ///
  /// The [id] parameter is the unique identifier for the document, and the [collection] parameter
  /// specifies the [SharedCollection] to which the document belongs.
  ///
  /// Throws an assertion error if [id] is empty.
  const SharedDocument(this.id, {required this.collection})
      : assert(id.length != 0, 'Document id shouldn\'t be empty');

  /// The unique identifier for this document.
  final String id;

  /// The [SharedCollection] to which this document belongs.
  final SharedCollection collection;

  /// Creates a new document within the associated collection.
  ///
  /// Optionally, it can replace an existing document if [replace] is set to true.
  /// Optionally, it can force creating new collection if the current collection does not exist, by setting [force] to true.
  /// Returns a [SharedResponse] of [SharedOne] for indicating the success or [SharedNone] for failure of the operation.
  ///
  /// ```dart
  /// final response = await Shared.col('myCollection').doc('documentId').create({'key': 'value'});
  /// print(response); // SharedOne(success: true, message: '...', data: JSON)
  /// ```
  Future<SharedResponse> create(
    JSON document, {
    bool replace = false,
    bool force = true,
  }) async {
    try {
      // [1] Get collection 📂.
      JSON? collection =
          Shared.preferences.getString(this.collection.id)?.decode;

      // [2] Check if collection exist or not 👻.
      if (collection == null && !force) {
        throw 'Unable to create the document. '
            'The specified collection with ID `${this.collection.id}` does not exist. '
            'To continue set the `force` parameter to true. '
            'This action is equivalent to creating a new empty '
            'collection and continued by creating a document within it.';
      } else {
        // [3] Check if document exists or not 🕊.
        if (collection?[id] != null && !replace) {
          throw 'The document already exists. '
              'WARNING: To proceed and replace the document with ID `$id`, '
              'set the `replace` parameter to true. '
              'This action will irreversibly replace the old document.';
        }

        // [4] Creating the document 🎉.
        bool result = await Shared.preferences.setString(this.collection.id,
            ((collection ?? {})..addEntries([MapEntry(id, document)])).encode);

        // [5] Notify the stream about the change in the collection 📣.
        this.collection._controller.add({
          'id': this.collection.id,
          'documents': [
            for (var item
                in (Shared.preferences.getString(this.collection.id)?.decode ??
                        {})
                    .entries)
              {'id': item.key, 'data': item.value}
          ]
        });

        // [6] Returning the result of creating this document 🚀.
        return SharedOne(
            success: result,
            message: result
                ? 'The document with ID `$id` has been successfully ${replace ? 'replaced' : 'created'}.'
                : 'Failed to ${replace ? 'replace' : 'create'} the document with ID `$id`. Please try again.',
            data: Shared.preferences.getString(this.collection.id)?.decode[id]);
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
      JSON? collection =
          Shared.preferences.getString(this.collection.id)?.decode;

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
  Future<SharedResponse> update(
    JSON document, {
    bool force = false,
  }) async {
    try {
      // [1] Get collection 📂.
      JSON? collection =
          Shared.preferences.getString(this.collection.id)?.decode;

      // [2] Check if collection exists or not 👻.
      if (collection == null && !force) {
        throw 'Unable to update the document. '
            'The specified collection with ID `${this.collection.id}` does not exist. '
            'To forcibly continue, '
            'set the `force` parameter to true. '
            'This action will create a new collection and a new document.';
      }

      // [3] Check if document exist or not 🕊.
      if (collection?[id] == null && !force) {
        throw 'Unable to update the document. '
            'The specified document with ID `$id` does not exist. '
            'To forcibly continue, '
            'set the `force` parameter to true. '
            'This action will create a new document.';
      }

      // [4] Updating the document 💼.
      bool result = await Shared.preferences.setString(
        this.collection.id,
        <String, dynamic>{
          ...collection ?? {},
          id: (collection?[id] as JSON? ?? {}).merge(document)
        }.encode,
      );

      // [5] Notify the stream about the change in the collection 📣.
      this.collection._controller.add({
        'id': this.collection.id,
        'documents': [
          for (var item
              in (Shared.preferences.getString(this.collection.id)?.decode ??
                      {})
                  .entries)
            {'id': item.key, 'data': item.value}
        ]
      });

      // [6] Returning the result of updating this document 🚀.
      return SharedOne(
        success: result,
        message: result
            ? 'The document with ID `$id` has been successfully updated.'
            : 'Failed to update the document with ID `$id`. Please try again.',
        data: Shared.preferences.getString(this.collection.id)?.decode[id],
      );
    } catch (e) {
      // [7] Returning bad news 🧨.
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
      JSON? collection =
          Shared.preferences.getString(this.collection.id)?.decode;

      // [2] Check if collection exists or not 👻.
      if (collection == null) {
        throw 'Unable to delete the document. '
            'The specified collection with ID `${this.collection.id}` does not exist.';
      }

      // [3] Check if document exists or not 🕊.
      if (collection[id] == null) {
        throw 'Unable to delete the document. '
            'The specified document with ID `$id` does not exist.';
      }

      // [4] Deleting the document 🧹.
      bool result = await Shared.preferences.setString(
        this.collection.id,
        (collection..remove(id)).encode,
      );

      // [5] Notify the stream about the change in the collection 📣.
      this.collection._controller.add({
        'id': this.collection.id,
        'documents': [
          for (var item
              in (Shared.preferences.getString(this.collection.id)?.decode ??
                      {})
                  .entries)
            {'id': item.key, 'data': item.value}
        ]
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
