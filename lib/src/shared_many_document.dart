part of '../local_shared.dart';

/// Handles bulk operations for many documents in a collection.
///
/// Use `SharedCollection.docs(ids)` to update or delete multiple documents, or
/// to merge them into a single target document via [migrate].
class SharedManyDocument {
  /// Creates a new instance of [SharedManyDocument].
  ///
  /// The [ids] parameter is a list of unique identifiers for the documents, and the [collection] parameter
  /// specifies the [SharedCollection] to which the documents belong.
  const SharedManyDocument(this.ids, {required this.collection});

  /// List of unique identifiers for the documents.
  final Iterable<String> ids;

  /// The [SharedCollection] to which these documents belong.
  final SharedCollection collection;

  /// Creates multiple documents within the associated collection.
  ///
  /// Optionally, it can replace existing documents if [replace] is set to true.
  /// Optionally, it can force creating a new collection if the current collection does not exist, by setting [force] to true.
  /// Returns a [SharedResponse] of [SharedMany] indicating the success or [SharedNone] for failure of the operation.
  ///
  /// ```dart
  /// final response = await Shared.col('myCollection').docs(['id1', 'id2']).create((index) => {'key': 'value for $id'});
  /// print(response); // SharedMany(success: true, message: '...', data: <JSON>[])
  /// ```
  Future<SharedResponse> create(
    JSON Function(int index) document, {
    bool merge = false,
    bool force = true,
  }) async {
    try {
      // [1] Get collection 📂.
      JSON? collection = await Shared._read(this.collection.id);

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
          if (collection[id] != null && !merge) {
            throw 'The document already exists. '
                'WARNING: To proceed and merge the document with ID `$id`, '
                'set the `merge` parameter to true. '
                'This action will irreversibly merge the old document.';
          }
        }

        // [5] Creating the documents 🎉.
        bool result = await Shared._create(
          this.collection.id,
          ({
            ...collection,
            for (int i = 0; i < ids.length; i++)...(){
              final id = ids.elementAt(i);
              return {id:(collection?[id] as JSON? ?? {}).merge( document(i))};
            }(),  
          }),
        );

        // [6] Notify the stream about the change in the collection 📣.
        this.collection._controller.add({
          'id': this.collection.id,
          'documents': [
            for (var item
                in ((await Shared._read(this.collection.id)) ?? {}).entries)
              {'id': item.key, 'data': item.value},
          ],
        });

        // [7] Returning the result of creating these document 🚀.
        return SharedMany(
          success: result,
          message: result
              ? '${ids.length} document from specified IDs `${ids.join('`, `')}` has been successfully ${merge ? 'merged' : 'created'}.'
              : 'Failed to ${merge ? 'replace' : 'create'} ${ids.length} document from specified IDs `${ids.join('`, `')}`. Please try again.',
          data: [
            for (var id in ids) (await Shared._read(this.collection.id))?[id],
          ].where((e) => e != null).map((e) => e as JSON).toList(),
        );
      }
    } catch (e) {
      // [8] Returning bad news 🧨.
      return SharedNone(message: '$e');
    }
  }

  /// Retrieves the contents of multiple documents.
  ///
  /// Optionally, it can pass check each documents existence if [skip] is set to true.
  /// Returns a [SharedResponse] of [SharedMany] with the document data if successful and [SharedNone] for failure.
  ///
  /// ```dart
  /// final response = await Shared.col('myCollection').docs(['id1', 'id2']).read();
  /// print(response); // SharedMany(success: true, message: '...', data: <JSON>[])
  /// ```
  Future<SharedResponse> read({bool skip = true}) async {
    try {
      // [1] Get collection 📂.
      JSON? collection = await Shared._read(this.collection.id);

      // [2] Check if collection exists or not 👻.
      if (collection == null) {
        throw 'Unable to read documents. '
            'The specified collection with ID `${this.collection.id}` does not exist.';
      }

      // [3] Check if document exist or not 🕊.
      if (!skip) {
        for (String id in ids) {
          if (collection[id] == null) {
            throw 'Unable to read document. '
                'The specified document with ID `$id` does not exist. '
                'To skip checking document existence, set parameter `skip` to true.';
          }
        }
      }

      // [4] Loading selected documents 🍽.
      List<JSON> data = [
        for (var id in ids) collection[id],
      ].where((e) => e != null).map((e) => e as JSON).toList();

      // [5] Returning the result of retrieving this document 🚀.
      return SharedMany(
        success: data.isNotEmpty,
        message: data.isNotEmpty
            ? '${data.length} / ${ids.length} document from specified IDs `${ids.join('`, `')}`'
                ' has been successfully retrieved.'
            : 'There\'s no single document from specified IDs `${ids.join('`, `')}` found',
        data: data,
      );
    } catch (e) {
      // [6] Returning bad news 🧨.
      return SharedNone(message: '$e');
    }
  }

  /// Updates the contents of multiple documents within the associated collection.
  ///
  /// Optionally, it can force update if the current documents do not exist, by setting [force] to true.
  /// Returns a [SharedResponse] of [SharedMany] indicating the success or [SharedNone] for failure of the update.
  ///
  /// ```dart
  /// final response = await Shared.col('myCollection').docs(['id1', 'id2']).update((index) => {'newKey': 'newValue for $id'});
  /// print(response); // SharedMany(success: true, message: '...', data: <JSON>[])
  /// ```
  Future<SharedResponse> update(
    JSON Function(int index) document, {
    bool force = false,
  }) async {
    try {
      // [1] Get collection 📂.
      JSON? collection = await Shared._read(this.collection.id);

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
      bool result = await Shared._create(this.collection.id, {
        ...collection,
        for (int i = 0; i < ids.length; i++)
          ids.elementAt(i): (collection[ids.elementAt(i)] as JSON? ?? {}).merge(
            document(i),
          ),
      });

      // [6] Notify the stream about the change in the collection 📣.
      this.collection._controller.add({
        'id': this.collection.id,
        'documents': [
          for (var item
              in (await Shared._read(this.collection.id) ?? {}).entries)
            {'id': item.key, 'data': item.value},
        ],
      });

      // [7] Returning the result of updating these document 🚀.
      return SharedMany(
        success: result,
        message: result
            ? '${ids.length} document from specified IDs `${ids.join('`, `')}` has been successfully updated.'
            : 'Failed to update ${ids.length} documents from specified IDs `${ids.join('`, `')}`. Please try again.',
        data: [
          for (var id in ids) (await Shared._read(this.collection.id))?[id],
        ].where((e) => e != null).map((e) => e as JSON).toList(),
      );
    } catch (e) {
      // [8] Returning bad news 🧨.
      return SharedNone(message: '$e');
    }
  }

  /// Deletes multiple documents within the associated collection.
  ///
  /// Optionally, it can pass check each documents existence if [skip] is set to true.
  /// Returns a [SharedResponse] of [SharedNone] indicating the success or failure of the deletion.
  ///
  /// ```dart
  /// final response = await Shared.col('myCollection').docs(['id1', 'id2']).delete();
  /// print(response); // SharedNone(success: true, message: '...')
  /// ```
  Future<SharedResponse> delete({bool skip = true}) async {
    try {
      // [1] Get collection 📂.
      JSON? collection = await Shared._read(this.collection.id);

      // [2] Check if collection exists or not 👻.
      if (collection == null) {
        throw 'Unable to delete documents. '
            'The specified collection with ID `${this.collection.id}` does not exist.';
      }

      // [3] Watch initial length of collection
      int length = collection.length;

      for (String id in ids) {
        // [4] Check if document exists or not 🕊.
        if (collection[id] == null && !skip) {
          throw 'Unable to delete the document. '
              'The specified document with ID `$id` does not exist. '
              'To proceed without checking wether document exist or not, '
              'set parameter `skip` to true.';
        }
        // [5] Deleting the document 🧹.
        else {
          collection.remove(id);
        }
      }

      // [6] Store new collection 🚚.
      bool result = await Shared._create(
        this.collection.id,
        collection,
      );

      // [7] Notify the stream about the change in the collection 📣.
      this.collection._controller.add({
        'id': this.collection.id,
        'documents': [
          for (var item
              in ((await Shared._read(this.collection.id)) ?? {}).entries)
            {'id': item.key, 'data': item.value},
        ],
      });

      // [8] Compare initial length to current collection length 🧮.
      length = length - ((await Shared._read(this.collection.id))?.length ?? 0);

      // [9] Returning the result of deleting these document 🚀.
      return SharedNone(
        success: length == 0 ? false : result,
        message: length == 0
            ? 'There\'s no single document with ID `${ids.join('`, `')}` found'
            : result
                ? '$length document from specified IDs `${ids.join('`, `')}` has been successfully deleted.'
                : 'Failed to delete ${ids.length} document from specified IDs `${ids.join('`, `')}`. Please try again.',
      );
    } catch (e) {
      // [10] Returning bad news 🧨.
      return SharedNone(message: '$e');
    }
  }


  Future<SharedResponse> migrate(
    String id, {
    bool merge = false,
    bool force = false,
  }) async {
    try {
      // [1] Get source collection 📂.
      JSON source = (await Shared._read(collection.id)) ?? {};

      // [2] Source collection existence.
      if (source.isEmpty && !force) {
        throw 'Unable to migrate documents. '
            'The collection with ID `${collection.id}` does not exist.';
      }

      // [3] Source and destination document cannot be identical unless forced.
      if (ids.contains(id) && !force) {
        throw 'Unable to migrate documents. '
            'Source and destination document IDs cannot be the same.';
      }

      // [4] Target document
      final JSON? existingTarget = source[id] as JSON?;
      if (existingTarget != null && !merge && !force) {
        throw 'Unable to migrate documents. '
            'The target document with ID `$id` already exists. '
            'To merge with existing target, set `merge` to true.';
      }

      // [5] Collect content from source documents.
      JSON migratedData = {};
      bool hasData = false;
      for (var docId in ids) {
        if (docId == id) continue;
        final doc = source[docId];

        if (doc == null) {
          if (!force) {
            throw 'Unable to migrate documents. '
                'Source document with ID `$docId` does not exist.';
          }
          continue;
        }

        if (doc is! JSON) {
          throw 'Unable to migrate documents. '
              'Source document with ID `$docId` has invalid type.';
        }

        migratedData = hasData ? migratedData.merge(doc) : JSON.from(doc);
        hasData = true;
        source.remove(docId);
      }

      // [6] Construct final target document.
      JSON finalTarget;
      if (existingTarget != null && merge) {
        finalTarget = existingTarget.merge(migratedData);
      } else {
        finalTarget = migratedData;
      }

      // If no data is migrated and target is missing, report (unless force).
      if (!hasData && existingTarget == null && !force) {
        throw 'Unable to migrate documents. '
            'No source documents were available for migration.';
      }

      source[id] = finalTarget;

      // [7] Persist state 🎉.
      final bool result = await Shared._create(collection.id, source);

      // [8] Notify stream 📣.
      collection._controller.add({
        'id': collection.id,
        'documents': [
          for (var item in ((await Shared._read(collection.id)) ?? {}).entries)
            {'id': item.key, 'data': item.value},
        ],
      });

      // [9] Return result 🚀.
      return SharedOne(
        success: result,
        message: result
            ? 'Selected documents from IDs `${ids.join('`, `')}` have been successfully migrated to document `$id`.'
            : 'Failed to migrate selected documents to document `$id`. Please try again.',
        data: (await Shared._read(collection.id))?[id] as JSON?,
      );
    } catch (e) {
      return SharedNone(message: '$e');
    }
  }

  @override
  String toString() {
    return '$runtimeType(ids: $ids, collection: $collection)';
  }
}
