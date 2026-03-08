/// A SharedPreferences-based local storage, designed as an alternative to the localstore package
library local_shared;

import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:local_shared/local_shared.dart' hide JSON;

part 'src/shared_collection.dart';
part 'src/shared_document.dart';
part 'src/shared_extension.dart';
part 'src/shared_many_document.dart';
part 'src/shared_response.dart';

/// Define Map&lt;String, dynamic&gt; as JSON values.
typedef JSON = Map<String, dynamic>;

/// A shorter term for [LocalShared].
typedef Shared = LocalShared;

/// Parent of [SharedCollection], [SharedDocument] and [SharedManyDocument]. Need to be initiated before used!
///
/// ```dart
/// void main() {
///   WidgetsFlutterBinding.ensureInitialized();
///   await LocalShared('DATABASE').initialize();
/// }
/// ```
///
/// and later in app, you can access it anywhere by calling this
///
/// ```dart
/// final response = await Shared.col(id).doc(id).read();
/// print(response); // SharedOne(success: true, message: '..., data: JSON) */
/// ```
class LocalShared {
  /// Default constructor of [LocalShared] containing [id] to be used as prefix in [SharedPreferences].
  ///
  /// Let [id] empty if you want to use default prefix of [SharedPreferences].
  ///
  /// ```dart
  /// LocalShared('app.inidia.example');
  /// ```
  LocalShared(this.id);

  /// The unique identifier for this [LocalShared] database instance
  /// which will be used as prefix for [SharedPreferences].
  final String id;

  /// The [FlutterSecureStorage] instance used as secured storage base.
  static FlutterSecureStorage? _storage;

  /// The [SharedPreferences] instance used as data storage base.
  static SharedPreferences? _db;

  /// Stream controller that listen changes when triggered by
  /// `create`, `update` and `delete` action on [SharedCollection], [SharedDocument] and [SharedManyDocument]
  ///
  /// this listen to [JSON] value.
  static final StreamController<JSON> _controller =
      StreamController<JSON>.broadcast();

  /// Initializes the [LocalShared] instance.
  ///
  /// Call this once inside main function after ensuring flutter initialized.
  ///
  /// ```dart
  /// Future<void> main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await LocalShared('app.inidia.example').initialize();
  /// }
  /// ```
  Future<void> initialize() async {
    _storage = FlutterSecureStorage(
        aOptions: AndroidOptions(
      sharedPreferencesName: 'flutter.$id.',
    ));
    if (id.isNotEmpty) SharedPreferences.setPrefix('flutter.$id.');
    _db = await SharedPreferences.getInstance();
  }

  /// Loaded [FlutterSecureStorage] instance from awaiting [initialize].
  ///
  /// This instance will be used in entire lifecycle of the app.
  static FlutterSecureStorage get storage {
    if (_storage != null) {
      return _storage!;
    } else {
      throw StateError("LocalShared not initialized. Call initialize() first.");
    }
  }

  /// Loaded [SharedPreferences] instance from awaiting [initialize].
  ///
  /// This instance will be used in entire lifecycle of the app.
  static SharedPreferences get preferences {
    if (_db != null) {
      return _db!;
    } else {
      throw StateError("LocalShared not initialized. Call initialize() first.");
    }
  }

  static Future<bool> _create(String id, JSON value) async {
    try {
      await storage.write(key: id, value: value.encode);
      // obsolete -> await preferences.setString(id, json);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<JSON?> _read(String key) async {
    final secure = await storage.read(key: key);
    final basic = preferences.getString(key);
    return secure?.decode ?? basic?.decode;
  }

  static Future<bool> _delete(String key) async {
    try {
      await storage.delete(key: key);
      await preferences.remove(key);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Shortcut to interact with [SharedCollection] with the given [id].
  ///
  /// ```dart
  /// // The syntax will either look like this
  /// LocalShared.col(collectionID)...
  /// // or for shorter prefix
  /// Shared.col(collectionID)...
  /// ```
  static SharedCollection col(String id) {
    return SharedCollection(id, controller: _controller);
  }

  /// Another shortcut that not so short compare to [col]
  /// which will be use to interact with [SharedCollection].
  ///
  /// Requiring [id] as its collection id.
  /// ```dart
  /// // The syntax will either look like this
  /// LocalShared.collection(collectionID)...
  /// // or for shorter prefix
  /// Shared.collection(collectionID)...
  /// ```
  static SharedCollection collection(String id) {
    return LocalShared.col(id);
  }

  /// A stream that listens for any changes when you're interacting with collections or documents
  /// through the [LocalShared.collection] or [LocalShared.col] shortcut.
  ///
  /// ```dart
  /// LocalShared.stream.listen(print);
  /// // { id: COLLECTION_ID,
  /// //   documents: [
  /// //    { id: DOCUMENT_ID,
  /// //      data: { key: value, },
  /// //    }
  /// // ]}
  /// ```
  static Stream<JSON> get stream => _controller.stream;

  /// Closes the [stream]. After calling this method,
  /// you won't be able to listen to changes anymore until you restart the app.
  static Future<void> close() => _controller.close();
}
