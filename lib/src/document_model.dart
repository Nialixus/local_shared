part of '../local_shared.dart';

class SharedDocument {
  const SharedDocument(this.id, {required this.collectionID});
  final String id;
  final String collectionID;

  Future<SharedModel> create(
    JSON document, {
    bool replace = false,
    bool force = true,
  }) async {
    // [1] Load the box 📦.
    SharedPreferences databox = await SharedPreferences.getInstance();

    try {
      // [2] Get collection 📂.
      JSON? collection = databox.getString(collectionID)?.decode;

      if (collection == null && !force) {
        throw 'Unable to create the document. '
            'The specified collection with ID `$collectionID` does not exist. '
            'To continue set the `force` parameter to true. '
            'This action is equivalent to creating a new empty '
            'collection and continued by creating a document within it.';
      } else {
        collection = collection ?? {};
        if (collection.containsKey(id) && !replace) {
          throw 'The document already exists. '
              'WARNING: To proceed and replace the document with ID `$id`, '
              'set the `replace` parameter to true. '
              'This action will irreversibly replace the old document.';
        }

        collection.addEntries([MapEntry(id, document)]);

        bool result = await databox.setString(collectionID, collection.encode);
        return SharedOne(
            success: result,
            message: result
                ? 'The document has been successfully ${replace ? 'replaced' : 'created'}.'
                : 'Failed to ${replace ? 'replace' : 'create'} the document. Please try again.',
            data: databox.getString(collectionID)?.decode[id]);
      }
    } catch (e) {
      return SharedNone(message: '$e');
    }
  }

  Future<SharedModel> read() async {
    return const SharedNone(message: 'message');
  }

  Future<SharedModel> update() async {
    return const SharedNone(message: 'message');
  }

  Future<SharedModel> delete() async {
    return const SharedNone(message: 'message');
  }

  @override
  String toString() {
    return '$runtimeType(id: $id, collection_id: $collectionID)';
  }
}
