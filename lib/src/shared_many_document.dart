part of '../local_shared.dart';

class SharedManyDocument {
  const SharedManyDocument(this.ids, {required this.collection})
      : assert(ids.length != 0, 'Documents id shouln\'t be empty');
  final List<String> ids;
  final SharedCollection collection;

  Future<SharedResponse> create(
    JSON Function(String id) document, {
    bool replace = false,
    bool force = true,
  }) async {
    try {
      // [1] Get collection 📂.
      JSON? collection =
          this.collection.database.getString(this.collection.id)?.decode;

      // [2] Check if collection exist or not 👻.
      if (collection == null && !force) {
        throw 'Unable to create documents. '
            'The specified collection with ID `${this.collection.id}` does not exist. '
            'To continue set the `force` parameter to true. '
            'This action is equivalent to creating a new empty '
            'collection and continued by creating documents within it.';
      } else {
        // [3] Make the collection null safety ⛑.
        collection = collection ?? {};

        // [4] Check if document exists or not 🕊.
        for (String id in ids) {
          if (collection[id] != null && !replace) {
            throw 'The document already exists. '
                'WARNING: To proceed and replace the document with ID `$id`, '
                'set the `replace` parameter to true. '
                'This action will irreversibly replace the old document.';
          }
        }

        // [5] Creating the documents 🎉.
        bool result = await this.collection.database.setString(
            this.collection.id,
            ({...collection, for (var id in ids) id: document(id)}).encode);

        // [6] Returning the result of creating these document 🚀.
        return SharedMany(
          success: result,
          message: result
              ? '${ids.length} document with ID `${ids.join('`, `')}` has been successfully ${replace ? 'replaced' : 'created'}.'
              : 'Failed to ${replace ? 'replace' : 'create'} ${ids.length} document with ID `${ids.join('`, `')}`. Please try again.',
          data: [
            for (var id in ids)
              this.collection.database.getString(this.collection.id)?.decode[id]
          ].where((e) => e != null).map((e) => e as JSON).toList(),
        );
      }
    } catch (e) {
      // [7] Returning bad news 🧨.
      return SharedNone(message: '$e');
    }
  }

  Future<SharedResponse> read({bool skip = true}) async {
    try {
      // [1] Get collection 📂.
      JSON? collection =
          this.collection.database.getString(this.collection.id)?.decode;

      // [2] Check if collection exists or not 👻.
      if (collection == null) {
        throw 'Unable to read documents. '
            'The specified collection with ID `${this.collection.id}` does not exist.';
      }

      // [3] Check if document exist or not 🕊.
      if (!skip) {
        for (String id in ids) {
          if (collection[id] == null) {
            throw 'Unable to read documents. '
                'The specified document with ID `$id` does not exist.';
          }
        }
      }

      // [4] Loading selected documents 🍽.
      List<JSON> data = [for (var id in ids) collection[id]]
          .where((e) => e != null)
          .map((e) => e as JSON)
          .toList();

      // [4] Returning the result of retrieving this document 🚀.
      return SharedMany(
        success: data.isNotEmpty,
        message: data.isNotEmpty
            ? '${data.length} document with ID `${ids.join('`, `')}`'
                ' has been successfully retrieved.'
            : 'There\'s no single document with ID `${ids.join('`, `')}` found',
        data: data,
      );
    } catch (e) {
      // [5] Returning bad news 🧨.
      return SharedNone(message: '$e');
    }
  }

  Future<SharedResponse> update(
    JSON Function(String id) document, {
    bool force = false,
  }) async {
    try {
      // [1] Get collection 📂.
      JSON? collection =
          this.collection.database.getString(this.collection.id)?.decode;

      // [2] Check if collection exists or not 👻.
      if (collection == null && !force) {
        throw 'Unable to update documents. '
            'The specified collection with ID `${this.collection.id}` does not exist. '
            'To forcibly continue, '
            'set the `force` parameter to true. '
            'This action will create a new collection and create new documents within it.';
      }

      // [3] Make the collection null safety ⛑.
      collection = collection ?? {};

      // [4] Check if document exist or not 🕊.
      for (String id in ids) {
        if (collection[id] == null && !force) {
          throw 'Unable to update the document. '
              'The specified document with ID `$id` does not exist. '
              'To forcibly continue, '
              'set the `force` parameter to true. '
              'This action will create a new document.';
        }
      }

      // [5] Updating the document 💼.
      bool result = await this.collection.database.setString(
            this.collection.id,
            {
              ...collection,
              for (var id in ids)
                id: (collection[id] as JSON? ?? {}).merge(document(id))
            }.encode,
          );

      // [6] Returning the result of updating these document 🚀.
      return SharedMany(
        success: result,
        message: result
            ? '${ids.length} document with ID `${ids.join('`, `')}` has been successfully updated.'
            : 'Failed to update ${ids.length} documents with ID `${ids.join('`, `')}`. Please try again.',
        data: [
          for (var id in ids)
            this.collection.database.getString(this.collection.id)?.decode[id]
        ].where((e) => e != null).map((e) => e as JSON).toList(),
      );
    } catch (e) {
      // [7] Returning bad news 🧨.
      return SharedNone(message: '$e');
    }
  }

  Future<SharedResponse> delete({bool skip = true}) async {
    try {
      // [1] Get collection 📂.
      JSON? collection =
          this.collection.database.getString(this.collection.id)?.decode;

      // [2] Check if collection exists or not 👻.
      if (collection == null) {
        throw 'Unable to delete documents. '
            'The specified collection with ID `${this.collection.id}` does not exist.';
      }

      // [3] Watch initial length of collection
      int length = collection.length;

      for (String id in ids) {
        // [3] Check if document exists or not 🕊.
        if (collection[id] == null && !skip) {
          throw 'Unable to delete the document. '
              'The specified document with ID `$id` does not exist. '
              'To proceed without checking wether document exist or not, '
              'set parameter `skip` to true.';
        }
        // [4] Deleting the document 🧹.
        else {
          collection.remove(id);
        }
      }

      // [5] Store new collection 🚚.
      bool result = await this.collection.database.setString(
            this.collection.id,
            collection.encode,
          );

      // [6] Compare initial length to current collection length 🧮.
      length = length -
          (this
                  .collection
                  .database
                  .getString(this.collection.id)
                  ?.decode
                  .length ??
              0);

      // [6] Returning the result of deleting these document 🚀.
      return SharedNone(
        success: length == 0 ? false : result,
        message: length == 0
            ? 'There\'s no single document with ID `${ids.join('`, `')}` found'
            : result
                ? '$length document with ID `${ids.join('`, `')}` has been successfully deleted.'
                : 'Failed to delete ${ids.length} document with ID `${ids.join('`, `')}`. Please try again.',
      );
    } catch (e) {
      // [7] Returning bad news 🧨.
      return SharedNone(message: '$e');
    }
  }

  @override
  String toString() {
    return '$runtimeType(ids: $ids, collection: $collection)';
  }
}
