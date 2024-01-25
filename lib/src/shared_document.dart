part of '../local_shared.dart';

class SharedDocument {
  const SharedDocument(this.id, {required this.collection})
      : assert(id.length != 0, 'Document id shouldn\'t be empty');
  final String id;
  final SharedCollection collection;

  Future<SharedResponse> create(
    JSON document, {
    bool replace = false,
    bool force = true,
  }) async {
    try {
      // [1] Get collection 📂.
      JSON? collection =
          this.collection.database.getString(this.collection.id)?.decode;

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
        bool result = await this.collection.database.setString(
            this.collection.id,
            ((collection ?? {})..addEntries([MapEntry(id, document)])).encode);

        // [5] Returning the result of creating this document 🚀.
        return SharedOne(
            success: result,
            message: result
                ? 'The document with ID `$id` has been successfully ${replace ? 'replaced' : 'created'}.'
                : 'Failed to ${replace ? 'replace' : 'create'} the document with ID `$id`. Please try again.',
            data: this
                .collection
                .database
                .getString(this.collection.id)
                ?.decode[id]);
      }
    } catch (e) {
      // [6] Returning bad news 🧨.
      return SharedNone(message: '$e');
    }
  }

  Future<SharedResponse> read() async {
    try {
      // [1] Get collection 📂.
      JSON? collection =
          this.collection.database.getString(this.collection.id)?.decode;

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

  Future<SharedResponse> update(
    JSON document, {
    bool force = false,
  }) async {
    try {
      // [1] Get collection 📂.
      JSON? collection =
          this.collection.database.getString(this.collection.id)?.decode;

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
      bool result = await this.collection.database.setString(
            this.collection.id,
            <String, dynamic>{
              ...collection ?? {},
              id: (collection?[id] as JSON? ?? {}).merge(document)
            }.encode,
          );

      // [5] Returning the result of updating this document 🚀.
      return SharedOne(
        success: result,
        message: result
            ? 'The document with ID `$id` has been successfully updated.'
            : 'Failed to update the document with ID `$id`. Please try again.',
        data:
            this.collection.database.getString(this.collection.id)?.decode[id],
      );
    } catch (e) {
      // [5] Returning bad news 🧨.
      return SharedNone(message: '$e');
    }
  }

  Future<SharedResponse> delete() async {
    try {
      // [1] Get collection 📂.
      JSON? collection =
          this.collection.database.getString(this.collection.id)?.decode;

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
      bool result = await this.collection.database.setString(
            this.collection.id,
            (collection..remove(id)).encode,
          );

      // [5] Returning the result of deleting this document 🚀.
      return SharedNone(
        success: result,
        message: result
            ? 'The document with ID `$id` has been successfully deleted.'
            : 'Failed to delete the document with ID `$id`. Please try again.',
      );
    } catch (e) {
      // [6] Returning bad news 🧨.
      return SharedNone(message: '$e');
    }
  }

  @override
  String toString() {
    return '$runtimeType(id: $id, collection: $collection)';
  }
}
