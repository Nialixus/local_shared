part of '../local_shared.dart';

class SharedCollection {
  const SharedCollection(this.id)
      : assert(id.length != 0, 'id shouln\'t be empty');
  final String id;

  Future<SharedModel> create({
    bool replace = false,
  }) async {
    // [1] Load the box 📦.
    SharedPreferences databox = await SharedPreferences.getInstance();

    try {
      // [2] Get collection 📂.
      List<JSON>? collection = databox.getString(id)?.decode.toList;

      // [3] Check if its allowed to create by replacing an old collection or not 💪.
      if (collection != null && !replace) {
        throw 'The collection already exists. '
            'WARNING: To proceed and replace the collection with ID `$id`, '
            'set the `replace` parameter to true. '
            'This action will irreversibly create a new empty collection.';
      }

      // [4] Create the collection 🎉.
      bool result = await databox.setString(id, jsonEncode({}));

      // [5] Returning the result of creating / replacing this collection 🚀.
      return SharedMany(
        success: result,
        message: result
            ? 'The collection has been successfully ${replace ? 'recreated' : 'created'}.'
            : 'Failed to ${replace ? 'recreate' : 'create'} the collection. Please try again.',
        data: databox.getString(id)?.decode.toList,
      );
    } catch (e) {
      // [6] Returning bad news 🧨.
      return SharedNone(message: '$e');
    }
  }

  Future<SharedModel> read() async {
    // [1] Load the box 📦.
    SharedPreferences databox = await SharedPreferences.getInstance();

    try {
      // [2] Get collection 📂.
      JSON? collection = databox.getString(id)?.decode;

      // [3] Check if collection exists or not 👻.
      if (collection == null) {
        throw 'Unable to read the collection. '
            'The specified collection with ID `$id` does not exist.';
      }

      // [4] Returning the result of retrieving this collection 🚀.
      return SharedMany(
        success: true,
        message:
            'The collection with ID `$id` has been successfully retrieved.',
        data: collection.toList,
      );
    } catch (e) {
      // [5] Returning bad news 🧨.
      return SharedNone(message: '$e');
    }
  }

  Future<SharedModel> update(
    String id, {
    bool replace = false,
    bool force = false,
  }) async {
    // [1] Load the box 📦.
    SharedPreferences databox = await SharedPreferences.getInstance();

    try {
      // [2] Get current collection 📂.
      JSON? collection = databox.getString(this.id)?.decode;

      // [3] Get targeted collection 📂.
      JSON? target = databox.getString(id)?.decode;

      // [4] Check if the current collection id is exactly the same with the new one or not 💩.
      if (this.id == id) {
        throw 'Unable to migrate the collection. '
            'The targeted collection ID cannot be the same as the current one.';
      }

      // [5] Check if current collection exists or not 👻.
      if (collection == null && !force) {
        throw 'Unable to migrate the collection. '
            'Current collection with ID `${this.id}` does not exist. '
            'To continue by forcing with empty collection, '
            'set the `force` parameter to true. '
            'This action is literally the same as making a new empty collection.';
      }

      // [6] Check if targeted collection exist or not 👼.
      if (target != null && !replace) {
        throw 'Unable to migrate the collection. '
            'Targeted collection with ID `$id` is already exist. '
            'WARNING: To proceed and replace the collection with ID `$id`, '
            'set the `replace` parameter to true. '
            'This action will irreversibly replacing everything inside targeted collection.';
      }

      // [7] Creating new collection 🎉.
      bool result = await databox.setString(id, jsonEncode(collection ?? {}));

      if (result) {
        // [8] Delete the old collection 🧹.
        bool delete = await databox.remove(this.id);

        // [9] Returning the result of migrating this collection.
        return SharedMany(
            success: delete,
            message: delete
                ? 'Successfully migrated collection from ID `${this.id}` to ID `$id`.'
                : 'Failed to clear the old collection after migrating to the new ID. '
                    'Please try deleting the collection with ID `${this.id}` manually.',
            data: databox.getString(delete ? id : this.id)?.decode.toList);
      }

      // [10] Sending bad news 💀.
      throw 'Failed to migrate the collection from ID ${this.id} to ID $id.';
    } catch (e) {
      // [11] Returning bad news 🧨.
      return SharedNone(message: '$e');
    }
  }

  Future<SharedModel> delete() async {
    // [1] Load the box 📦.
    SharedPreferences databox = await SharedPreferences.getInstance();

    try {
      // [2] Get collection 📂.
      JSON? collection = databox.getString(id)?.decode;

      // [3] Check if collection exists or not 👻.
      if (collection == null) {
        throw 'Unable to delete the collection. '
            'The specified collection with ID `$id` does not exist.';
      }

      // [4] Deleting the collection 🧹.
      bool result = await databox.remove(id);

      // [5] Returning the result of deleting this collection 🚀.
      return SharedNone(
        success: result,
        message: result
            ? 'The collection has been successfully deleted.'
            : 'Failed to delete the collection. Please try again.',
      );
    } catch (e) {
      // [6] Returning bad news 🧨.
      return SharedNone(message: '$e');
    }
  }

  SharedDocument doc(String id) {
    return SharedDocument(
      id,
      collectionID: this.id,
    );
  }

  @override
  String toString() {
    return '$runtimeType(id: $id)';
  }
}
