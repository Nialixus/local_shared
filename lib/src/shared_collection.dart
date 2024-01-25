part of '../local_shared.dart';

class SharedCollection {
  const SharedCollection(this.id, {required this.database})
      : assert(id.length != 0, 'Collection id shouln\'t be empty');
  final String id;
  final SharedPreferences database;

  Future<SharedResponse> create({
    bool replace = false,
  }) async {
    try {
      // [1] Get collection 📂.
      List<JSON>? collection = database.getString(id)?.decode.toList;

      // [2] Check if its allowed to create by replacing an old collection or not 💪.
      if (collection != null && !replace) {
        throw 'The collection already exists. '
            'WARNING: To proceed and replace the collection with ID `$id`, '
            'set the `replace` parameter to true. '
            'This action will irreversibly create a new empty collection.';
      }

      // [3] Create the collection 🎉.
      bool result = await database.setString(id, jsonEncode({}));

      // [4] Returning the result of creating / replacing this collection 🚀.
      return SharedMany(
        success: result,
        message: result
            ? 'The collection with ID `$id` has been successfully ${replace ? 'recreated' : 'created'}.'
            : 'Failed to ${replace ? 'recreate' : 'create'} the collection with ID `$id`. Please try again.',
        data: database.getString(id)?.decode.toList,
      );
    } catch (e) {
      // [5] Returning bad news 🧨.
      return SharedNone(message: '$e');
    }
  }

  Future<SharedResponse> read() async {
    try {
      // [1] Get collection 📂.
      JSON? collection = database.getString(id)?.decode;

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
        data: collection.toList,
      );
    } catch (e) {
      // [4] Returning bad news 🧨.
      return SharedNone(message: '$e');
    }
  }

  Future<SharedResponse> update(
    String id, {
    bool replace = false,
    bool force = false,
  }) async {
    try {
      // [1] Get current collection 📂.
      JSON? collection = database.getString(this.id)?.decode;

      // [2] Get targeted collection 📂.
      JSON? target = database.getString(id)?.decode;

      // [3] Check if the current collection id is exactly the same with the new one or not 💩.
      if (this.id == id) {
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
      if (target != null && !replace) {
        throw 'Unable to migrate the collection. '
            'Targeted collection with ID `$id` is already exist. '
            'WARNING: To proceed and replace the collection with ID `$id`, '
            'set the `replace` parameter to true. '
            'This action will irreversibly replacing everything inside targeted collection.';
      }

      // [6] Creating new collection 🎉.
      bool result = await database.setString(id, jsonEncode(collection ?? {}));

      if (result) {
        // [7] Delete the old collection 🧹.
        bool delete = await database.remove(this.id);

        // [8] Returning the result of migrating this collection 🚀.
        return SharedMany(
            success: delete,
            message: delete
                ? 'Successfully migrated collection from ID `${this.id}` to ID `$id`.'
                : 'Failed to clear the old collection after migrating to the new ID. '
                    'Please try deleting the collection with ID `${this.id}` manually.',
            data: database.getString(delete ? id : this.id)?.decode.toList);
      }

      // [9] Sending bad news 💀.
      throw 'Failed to migrate the collection from ID ${this.id} to ID $id.';
    } catch (e) {
      // [10] Catching bad news 🧨.
      return SharedNone(message: '$e');
    }
  }

  Future<SharedResponse> delete() async {
    try {
      // [1] Get collection 📂.
      JSON? collection = database.getString(id)?.decode;

      // [2] Check if collection exists or not 👻.
      if (collection == null) {
        throw 'Unable to delete the collection. '
            'The specified collection with ID `$id` does not exist.';
      }

      // [3] Deleting the collection 🧹.
      bool result = await database.remove(id);

      // [4] Returning the result of deleting this collection 🚀.
      return SharedNone(
        success: result,
        message: result
            ? 'The collection with ID `$id` has been successfully deleted.'
            : 'Failed to delete the collection with ID `$id`. Please try again.',
      );
    } catch (e) {
      // [5] Returning bad news 🧨.
      return SharedNone(message: '$e');
    }
  }

  SharedDocument doc(String id) {
    return SharedDocument(
      id,
      collection: this,
    );
  }

  SharedDocument document(String id) {
    return doc(id);
  }

  SharedManyDocument docs(List<String> ids) {
    return SharedManyDocument(ids, collection: this);
  }

  SharedManyDocument documents(List<String> ids) {
    return docs(ids);
  }

  @override
  String toString() {
    return '$runtimeType(id: $id)';
  }
}
