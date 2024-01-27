/// A SharedPreferences-based local storage, designed as an alternative to the localstore package
library local_shared;

import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:local_shared/local_shared.dart'
    hide _StringExtension, _ListExtension, _JSONExtension;

part 'src/shared_collection.dart';
part 'src/shared_document.dart';
part 'src/shared_extension.dart';
part 'src/shared_many_document.dart';
part 'src/shared_response.dart';

/// Define Map<String, dynamic> as JSON values.
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
  /// ```dart
  /// LocalShared('app.inidia.example');
  /// ```
  LocalShared([this.id = '']);

  /// The unique identifier for this [LocalShared] database instance
  /// which will be used as prefix for [SharedPreferences].
  final String id;

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
    if (id.isNotEmpty) SharedPreferences.setPrefix('flutter.$id.');
    _db = await SharedPreferences.getInstance();
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
