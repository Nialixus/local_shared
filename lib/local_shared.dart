/// Lightweight local storage that uses Flutter Secure Storage and SharedPreferences.
///
/// Provides a simplified API for managing collections and documents in a key/value store.
/// It is designed as an alternative to `localstore` with explicit, typed responses.
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

/// Define a dynamic map as JSON values.
typedef JSON = Map<String, dynamic>;

/// A shorter term for [LocalShared].
typedef Shared = LocalShared;

/// LocalShared is the core datastore object.
///
/// Call [initialize] once at app startup, then use [Shared.col] or [Shared.collection]
/// to access collection and document CRUD operations.
///
/// ```dart
/// WidgetsFlutterBinding.ensureInitialized();
/// await LocalShared('appId').initialize();
/// final result = await Shared.col('users').doc('user1').read();
/// ```
class LocalShared {
  /// Constructs a LocalShared instance.
  ///
  /// The [id] is used as a namespace prefix for all saved keys.
  const LocalShared(this.id);

  /// The unique identifier for this [LocalShared] database instance
  /// which will be used as prefix for [SharedPreferences].
  final String id;

  /// The [FlutterSecureStorage] instance used as secured storage base.
  static FlutterSecureStorage? _storage;

  /// The [SharedPreferences] instance used as data storage base.
  static SharedPreferences? _db;

  /// Key used to track whether the one-time bulk SP → SecureStorage migration
  /// has already been performed for this installation.
  ///
  /// Stored inside [SharedPreferences] itself so it survives app restarts
  /// and is reset automatically on a fresh install.
  static const String _migrationFlagKey = '__local_shared_migrated__';

  /// Stream controller that listen changes when triggered by
  /// `create`, `update` and `delete` action on [SharedCollection], [SharedDocument] and [SharedManyDocument]
  ///
  /// this listen to [JSON] value.
  static final StreamController<JSON> _controller =
      StreamController<JSON>.broadcast();

  /// Initializes internal storage instances.
  ///
  /// Must be called once before retrying any read/write operations.
  ///
  /// On the **first call after upgrading** to v3.1.0+, all data previously
  /// written to [SharedPreferences] is automatically bulk-migrated to
  /// [FlutterSecureStorage]. Subsequent calls skip this scan via a migration
  /// flag stored in [SharedPreferences].
  ///
  /// ```dart
  /// WidgetsFlutterBinding.ensureInitialized();
  /// await LocalShared('app.example').initialize();
  /// ```
  Future<void> initialize() async {
    _storage = FlutterSecureStorage(
      aOptions: AndroidOptions(
        // flutter_secure_storage >=11.0.0: `sharedPreferencesName` was removed.
        // Use `storageNamespace` instead — it maps to both the SharedPreferences
        // file name and the keystore alias on Android, keeping data isolated per
        // LocalShared instance and matching the naming used in prior versions.
        storageNamespace: 'flutter.$id.',
      ),
    );
    if (id.isNotEmpty) SharedPreferences.setPrefix('flutter.$id.');
    _db = await SharedPreferences.getInstance();

    // Run one-time bulk migration of all legacy SharedPreferences data
    // into FlutterSecureStorage.
    await _migrateAll();
  }

  /// Returns the initialized secure storage instance.
  ///
  /// Throws [StateError] if [initialize] has not been called.
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

  /// Performs a **one-time** bulk migration of all legacy [SharedPreferences]
  /// data to [FlutterSecureStorage].
  ///
  /// **Behaviour:**
  /// - Skips [_migrationFlagKey] itself.
  /// - For each key: validates the raw value is JSON, then writes to secure
  ///   storage only when that key doesn't already exist there (secure wins on
  ///   conflict), then removes the key from [SharedPreferences].
  /// - Non-JSON values (e.g. `bool` migration flag, app-owned non-JSON keys)
  ///   are skipped silently.
  /// - Sets [_migrationFlagKey] = `true` in [SharedPreferences] when done, so
  ///   this bulk scan only runs once per installation.
  ///
  /// Individual keys that arrive in [SharedPreferences] *after* this initial
  /// migration (e.g. via a partial migration scenario) are handled lazily by
  /// [_read] on first access.
  static Future<void> _migrateAll() async {
    // Guard: skip if already migrated.
    final alreadyMigrated = preferences.getBool(_migrationFlagKey) ?? false;
    if (alreadyMigrated) return;

    final keys = preferences.getKeys().toList();
    for (final key in keys) {
      // Never migrate the internal migration-flag key itself.
      if (key == _migrationFlagKey) continue;

      final raw = preferences.getString(key);
      if (raw == null) continue;

      try {
        // Validate the value is JSON before migrating.
        jsonDecode(raw);

        // Only write to secure storage when the key isn't already there —
        // secure storage is treated as the source of truth.
        final existing = await storage.read(key: key);
        if (existing == null) {
          await storage.write(key: key, value: raw);
        }

        // Remove the migrated key from SharedPreferences.
        await preferences.remove(key);
      } catch (_) {
        // Skip non-JSON or unwritable values silently.
      }
    }

    // Mark migration complete.
    await preferences.setBool(_migrationFlagKey, true);
  }

  /// Writes [value] to [FlutterSecureStorage].
  ///
  /// All new writes go exclusively to secure storage. [SharedPreferences] is
  /// no longer a write target as of v3.1.0.
  static Future<bool> _create(String id, JSON value) async {
    try {
      await storage.write(key: id, value: value.encode);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reads a [JSON] value for [key], with transparent lazy migration.
  ///
  /// **Priority:**
  /// 1. [FlutterSecureStorage] — primary store after migration (fast path).
  /// 2. [SharedPreferences] — legacy fallback. When a value is found here, it
  ///    is **lazily migrated** on-the-spot: written to secure storage and
  ///    removed from [SharedPreferences], so the next read is served from
  ///    secure storage without touching [SharedPreferences] again.
  static Future<JSON?> _read(String key) async {
    // 1. Fast path: secure storage (expected for all data post-migration).
    final secure = await storage.read(key: key);
    if (secure != null) {
      return secure.decode;
    }

    // 2. Legacy fallback: SharedPreferences.
    final basic = preferences.getString(key);
    if (basic == null) return null;

    // 3. Lazy migration: move this stray key to secure storage immediately.
    try {
      await storage.write(key: key, value: basic);
      await preferences.remove(key);
    } catch (_) {
      // If migration fails for any reason, still return the data from SP
      // so the caller is not blocked.
    }

    return basic.decode;
  }

  /// Deletes [key] from both [FlutterSecureStorage] and [SharedPreferences].
  ///
  /// Cleaning up both stores ensures that any partially-migrated or legacy
  /// data left in [SharedPreferences] is removed alongside the secure entry.
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
    return LocalShared.collection(id);
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
    return SharedCollection(id, controller: _controller);
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
