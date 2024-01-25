library local_shared;

import 'dart:convert';

import 'package:local_shared/src/shared_extension.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'src/shared_collection.dart';
part 'src/shared_document.dart';
part 'src/shared_many_document.dart';
part 'src/shared_response.dart';

/// A typedef for a JSON representation, which is a Map<String, dynamic> values.
typedef JSON = Map<String, dynamic>;

/// A shorter term for [LocalShared].
typedef Shared = LocalShared;

/// Parent of [SharedCollection], [SharedDocument] and [SharedManyDocument]. Need to be initiated before used!
///
/// ```dart
/// void main() {
///   WidgetsFlutterBinding.ensureInitialized();
///   await LocalShared('MY_DB').initialize();
/// }
/// ```
///
/// and later in app, you can access it anywhere by calling this
///
/// ```dart
/// final response = await Shared.col(id).doc(id).read();
/// print(response); // SharedOne(success: true, message: successfully reading data, data: {'title': 'test'}) */
/// ```
class LocalShared {
  /// Default constructor of [LocalShared] containing [id] to be used as prefix in [SharedPreferences].
  ///
  /// ```dart
  /// LocalShared('app.inidia.example');
  /// ```
  LocalShared(this.id)
      : assert(id.isNotEmpty, 'LocalShared id shouldn\'t be empty');

  /// The unique identifier for this [LocalShared] database instance
  /// which will be used as prefix for [SharedPreferences].
  final String id;

  /// The [SharedPreferences] instance used as data storage base.
  static SharedPreferences? _db;

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
    SharedPreferences.setPrefix('flutter.$id.');
    _db = await SharedPreferences.getInstance();
  }

  /// Load the [SharedPreferences] instance after calling [initialize].
  ///
  /// This instance will be used in entire lifecycle of the app.
  static SharedPreferences get preferences {
    if (_db == null) {
      throw StateError("LocalShared not initialized. Call initialize() first.");
    } else {
      return _db!;
    }
  }

  /// Shortcut to interact with [SharedCollection] with the given [id].
  ///
  /// Requiring [id] as its collection id.
  /// ```dart
  /// // The syntax will either look like this
  /// LocalShared.col(collectionID).doc(documentID).read();
  ///
  /// // or
  /// Shared.col(collectionID).doc(documentID).read();
  /// ```
  static SharedCollection col(String id) {
    return SharedCollection(id, database: preferences);
  }

  /// Another shortcut that not so short compare to [col]
  /// that will be use to interact with [SharedCollection].
  ///
  /// Requiring [id] as its collection id.
  /// ```dart
  /// // The syntax will either look like this
  /// LocalShared.collection(collectionID).document(documentID).read();
  ///
  /// // or
  /// Shared.collection(collectionID).document(documentID).read();
  /// ```
  static SharedCollection collection(String id) {
    return LocalShared.col(id);
  }
}
