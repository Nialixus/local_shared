import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_shared/local_shared.dart';

// ---------------------------------------------------------------------------
// NOTE ON SharedPreferences MOCK KEYS
//
// LocalShared sets `SharedPreferences.setPrefix('flutter.<id>.')`.
// The MethodChannel mock for SharedPreferences stores and matches keys with
// the **full prefixed** name, so seed data must use the full key when
// pre-populating mock initial values:
//
//   'flutter.test_db.my_key'  ← correct seed key for id = 'test_db'
//   'my_key'                   ← WRONG – invisible to the prefixed instance
//
// Keys are read back / written via their short name (the prefix is stripped
// automatically by SharedPreferences), but the mock map must use the full key.
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // Constants & helpers
  // ---------------------------------------------------------------------------

  /// SharedPreferences prefix used by LocalShared('test_db').
  const spPrefix = 'flutter.test_db.';

  /// Wraps a short key with the SP prefix for mock seeding.
  String spKey(String shortKey) => '$spPrefix$shortKey';

  /// Encodes a single-document collection payload to raw JSON string.
  String collectionJson(String docId, Map<String, dynamic> docData) =>
      jsonEncode({docId: docData});

  /// Initializes LocalShared with pre-seeded storage values.
  ///
  /// [sp]     – keys must be **full-prefixed** (use [spKey] helper).
  /// [secure] – keys are short (no prefix; FlutterSecureStorage has no prefix).
  Future<void> init({
    Map<String, Object> sp = const {},
    Map<String, String> secure = const {},
  }) async {
    FlutterSecureStorage.setMockInitialValues(Map<String, String>.from(secure));
    SharedPreferences.setMockInitialValues(Map<String, Object>.from(sp));
    await const LocalShared('test_db').initialize();
  }

  // ===========================================================================
  // 1. Bulk migration on initialize()
  // ===========================================================================
  group('Bulk migration on initialize()', () {
    const col = 'migration_col';
    const doc = 'migration_doc';

    test('migrates all SP keys to secure storage on first init', () async {
      // Seed SP with the full-prefixed key so the prefixed SP instance sees it.
      final raw = collectionJson(doc, {'hello': 'world'});
      await init(sp: {spKey(col): raw});

      // Data should be readable via the library.
      final response = await Shared.col(col).read();
      expect(response.success, isTrue);
      expect(response, isA<SharedMany>());
      expect((response.data as List).first, containsPair('hello', 'world'));

      // Legacy key must be gone from SP.
      expect(LocalShared.preferences.getString(col), isNull);
    });

    test('migration flag is set after first init', () async {
      await init(sp: {spKey(col): collectionJson(doc, {'x': 1})});
      expect(
        LocalShared.preferences.getBool('__local_shared_migrated__'),
        isTrue,
      );
    });

    test('bulk migration does NOT overwrite existing secure storage data',
        () async {
      final secureRaw = collectionJson(doc, {'src': 'secure'});
      final spRaw = collectionJson(doc, {'src': 'legacy'});

      // Secure storage already has this key → SP value must NOT overwrite it.
      await init(sp: {spKey(col): spRaw}, secure: {col: secureRaw});

      final response = await Shared.col(col).read();
      expect(response.success, isTrue);
      // Secure value wins on conflict.
      expect((response.data as List).first, containsPair('src', 'secure'));
    });

    test('bulk migration skips non-JSON SP values without throwing', () async {
      // Value is not valid JSON; migration should skip it silently.
      await init(sp: {spKey('not_json_key'): 'this-is-not-valid-json!!!'});
      // If we reach here, no exception was thrown.
      expect(true, isTrue);
    });

    test('bulk migration skips the migration flag key itself', () async {
      // Pre-seed the migration flag as already true (uses full SP key).
      // Because the flag is set, _migrateAll() returns early and the
      // collection key stays in SP → it will be lazy-migrated on first read.
      await init(sp: {
        spKey('__local_shared_migrated__'): true,
        spKey(col): collectionJson(doc, {'skipped': true}),
      });

      expect(
        LocalShared.preferences.getBool('__local_shared_migrated__'),
        isTrue,
      );

      // Reading it triggers lazy migration.
      final response = await Shared.col(col).read();
      expect(response.success, isTrue);
      // Now secure storage has it.
      expect(await LocalShared.storage.read(key: col), isNotNull);
    });

    test('second initialize() skips bulk migration (flag already set)',
        () async {
      // First init: bulk-migrate SP data.
      await init(sp: {spKey(col): collectionJson(doc, {'round': 1})});
      expect(LocalShared.preferences.getString(col), isNull); // Migrated away.

      // Simulate data appearing in SP after first migration (edge case).
      await LocalShared.preferences.setString(col, collectionJson(doc, {'round': 2}));

      // Second init: flag is set, bulk migration is skipped.
      FlutterSecureStorage.setMockInitialValues(
        {col: collectionJson(doc, {'round': 1})},
      );
      SharedPreferences.setMockInitialValues({
        spKey('__local_shared_migrated__'): true,
        spKey(col): collectionJson(doc, {'round': 2}),
      });
      await const LocalShared('test_db').initialize();

      // Reading triggers lazy migration; secure (round:1) wins.
      final response = await Shared.col(col).read();
      expect(response.success, isTrue);
      expect((response.data as List).first, containsPair('round', 1));
    });

    test('multiple SP keys are all migrated in one pass', () async {
      await init(sp: {
        spKey('col_a'): collectionJson('d1', {'a': 1}),
        spKey('col_b'): collectionJson('d2', {'b': 2}),
        spKey('col_c'): collectionJson('d3', {'c': 3}),
      });

      for (final colId in ['col_a', 'col_b', 'col_c']) {
        final raw = await LocalShared.storage.read(key: colId);
        expect(raw, isNotNull,
            reason: '$colId should be in secure storage after migration');
        expect(LocalShared.preferences.getString(colId), isNull,
            reason: '$colId should be removed from SP after migration');
      }
    });
  });

  // ===========================================================================
  // 2. Lazy migration on _read()
  // ===========================================================================
  group('Lazy migration on _read (key-by-key)', () {
    const col = 'lazy_col';
    const doc = 'lazy_doc';

    setUp(() async {
      // Start with migration already flagged so bulk migration is skipped,
      // giving us precise control over lazy migration scenarios.
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues(
        {spKey('__local_shared_migrated__'): true},
      );
      await const LocalShared('test_db').initialize();
    });

    test('reading a legacy SP key migrates it to secure storage', () async {
      final raw = collectionJson(doc, {'hello': 'lazy'});
      // Inject a legacy key into SP after migration flag was set.
      await LocalShared.preferences.setString(col, raw);

      final response = await Shared.col(col).read();
      expect(response.success, isTrue);
      expect((response.data as List).first, containsPair('hello', 'lazy'));

      // Key must now be in secure storage.
      expect(await LocalShared.storage.read(key: col), isNotNull);
      // Key must be gone from SP.
      expect(LocalShared.preferences.getString(col), isNull);
    });

    test('lazy migration: secure storage wins when both stores have data',
        () async {
      await LocalShared.storage.write(
        key: col,
        value: collectionJson(doc, {'src': 'secure'}),
      );
      await LocalShared.preferences
          .setString(col, collectionJson(doc, {'src': 'legacy'}));

      final response = await Shared.col(col).read();
      expect(response.success, isTrue);
      // Secure is read first — it wins.
      expect((response.data as List).first, containsPair('src', 'secure'));
    });

    test('lazy migration preserves data integrity across subsequent CRUD',
        () async {
      final raw = collectionJson(doc, {'hello': 'world'});
      await LocalShared.preferences.setString(col, raw);

      // First read triggers lazy migration.
      await Shared.col(col).read();

      // Update via API (goes to secure storage).
      final updateResp = await Shared.col(col).doc(doc).update(
        {'extra': 'field'},
        force: true,
      );
      expect(updateResp.success, isTrue);

      // Read back and verify merged result.
      final readResp = await Shared.col(col).doc(doc).read();
      expect(readResp.success, isTrue);
      expect(readResp.data, containsPair('hello', 'world'));
      expect(readResp.data, containsPair('extra', 'field'));

      // SP should not have this key at all.
      expect(LocalShared.preferences.getString(col), isNull);
    });

    test('reading non-existent key returns SharedNone — no migration noise',
        () async {
      final response = await Shared.col('nonexistent_col').read();
      expect(response.success, isFalse);
      expect(response, isA<SharedNone>());
    });
  });

  // ===========================================================================
  // 3. New CRUD prioritizes secure storage
  // ===========================================================================
  group('New CRUD prioritizes secure storage (post-migration)', () {
    const col = 'crud_col';
    const doc = 'crud_doc';

    setUp(() async {
      await init();
    });

    test('create writes only to secure storage, NOT SharedPreferences',
        () async {
      await Shared.col(col).doc(doc).create({'key': 'value'});

      final secureRaw = await LocalShared.storage.read(key: col);
      final spRaw = LocalShared.preferences.getString(col);

      expect(secureRaw, isNotNull);
      expect(spRaw, isNull); // SP untouched.
    });

    test('update writes only to secure storage', () async {
      await Shared.col(col).doc(doc).create({'key': 'old'});
      await Shared.col(col).doc(doc).update({'key': 'new'});

      final secureRaw = await LocalShared.storage.read(key: col);
      final spRaw = LocalShared.preferences.getString(col);

      expect(secureRaw, isNotNull);
      expect(spRaw, isNull);

      final decoded = jsonDecode(secureRaw!) as Map<String, dynamic>;
      expect((decoded[doc] as Map)['key'], 'new');
    });

    test('delete removes from both secure storage and SharedPreferences',
        () async {
      // Simulate partially migrated state: data exists in both stores.
      await LocalShared.storage.write(
        key: col,
        value: collectionJson(doc, {'key': 'value'}),
      );
      await LocalShared.preferences
          .setString(col, collectionJson(doc, {'key': 'value'}));

      final response = await Shared.col(col).delete();
      expect(response.success, isTrue);

      expect(await LocalShared.storage.read(key: col), isNull);
      expect(LocalShared.preferences.getString(col), isNull);
    });

    test('create collection writes only to secure storage', () async {
      await Shared.col(col).create();

      expect(await LocalShared.storage.read(key: col), isNotNull);
      expect(LocalShared.preferences.getString(col), isNull);
    });

    test('docs().create() writes only to secure storage', () async {
      await Shared.col(col).docs(['d1', 'd2']).create(
        (i) => i == 0 ? {'a': 1} : {'b': 2},
      );

      expect(await LocalShared.storage.read(key: col), isNotNull);
      expect(LocalShared.preferences.getString(col), isNull);
    });
  });

  // ===========================================================================
  // 4. Backward compatibility — no legacy data (fresh install)
  // ===========================================================================
  group('Backward compatibility — fresh install with no SP data', () {
    const col = 'compat_col';
    const doc = 'compat_doc';

    setUp(() async {
      await init();
    });

    test('all CRUD operations work normally on a fresh install', () async {
      // Create
      final createResp =
          await Shared.col(col).doc(doc).create({'fresh': true});
      expect(createResp.success, isTrue);

      // Read
      final readResp = await Shared.col(col).doc(doc).read();
      expect(readResp.success, isTrue);
      expect(readResp.data, containsPair('fresh', true));

      // Update
      final updateResp =
          await Shared.col(col).doc(doc).update({'extra': 42});
      expect(updateResp.success, isTrue);
      expect(updateResp.data, containsPair('extra', 42));

      // Delete
      final deleteResp = await Shared.col(col).doc(doc).delete();
      expect(deleteResp.success, isTrue);

      // Verify gone
      final gone = await Shared.col(col).doc(doc).read();
      expect(gone.success, isFalse);
    });

    test('reading a missing key returns SharedNone', () async {
      final response = await Shared.col('nonexistent').read();
      expect(response.success, isFalse);
      expect(response, isA<SharedNone>());
    });

    test('migration flag is set even on fresh install with no SP data',
        () async {
      expect(
        LocalShared.preferences.getBool('__local_shared_migrated__'),
        isTrue,
      );
    });
  });

  // ===========================================================================
  // 5. Migration + Collection / ManyDocument integration
  // ===========================================================================
  group('Migration integrates correctly with collection-level operations', () {
    const col = 'integ_col';

    test('collection.migrate() after lazy migration works correctly', () async {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues(
        {spKey('__local_shared_migrated__'): true},
      );
      await const LocalShared('test_db').initialize();

      // Inject legacy SP data after flag is already set.
      await LocalShared.preferences.setString(
        col,
        jsonEncode({'d1': <String, dynamic>{'v': 1}}),
      );

      // Read triggers lazy migration.
      await Shared.col(col).read();

      // Migrate the collection to a new ID.
      final migrateResp = await Shared.col(col).migrate('integ_col_v2');
      expect(migrateResp.success, isTrue);

      // New collection is in secure storage.
      expect(
        await LocalShared.storage.read(key: 'integ_col_v2'),
        isNotNull,
      );
      // Old collection is gone.
      expect(await LocalShared.storage.read(key: col), isNull);
    });

    test('docs bulk-create after bulk migration writes only to secure storage',
        () async {
      await init(sp: {
        spKey(col):
            jsonEncode({'old': <String, dynamic>{'legacy': true}}),
      });

      // Bulk migration should have moved 'col' to secure storage.
      expect(await LocalShared.storage.read(key: col), isNotNull);
      expect(LocalShared.preferences.getString(col), isNull);

      // Add new docs — goes to secure storage.
      final resp = await Shared.col(col).docs(['d1', 'd2']).create(
        (i) => {'idx': i},
        merge: true,
      );
      expect(resp.success, isTrue);

      // SP still clean.
      expect(LocalShared.preferences.getString(col), isNull);
    });
  });

  // ===========================================================================
  // 6. Edge cases
  // ===========================================================================
  group('Edge cases', () {
    test('initialize() can be called multiple times without corrupting data',
        () async {
      await init();
      await Shared.col('edge_col').doc('d').create({'init': 1});

      // Second init with the existing secure data already in place.
      FlutterSecureStorage.setMockInitialValues(
        {'edge_col': jsonEncode({'d': <String, dynamic>{'init': 1}})},
      );
      SharedPreferences.setMockInitialValues(
        {spKey('__local_shared_migrated__'): true},
      );
      await const LocalShared('test_db').initialize();

      final response = await Shared.col('edge_col').doc('d').read();
      expect(response.success, isTrue);
      expect(response.data, containsPair('init', 1));
    });

    test('migration with completely empty SP completes without errors',
        () async {
      await init();
      expect(
        LocalShared.preferences.getBool('__local_shared_migrated__'),
        isTrue,
      );
    });

    test('write-then-read round-trip is stable across two reads', () async {
      await init();
      await Shared.col('rt_col').doc('rt_doc').create({'count': 99});

      final r1 = await Shared.col('rt_col').doc('rt_doc').read();
      final r2 = await Shared.col('rt_col').doc('rt_doc').read();

      expect(r1.data, equals(r2.data));
      expect(r1.data, containsPair('count', 99));
    });

    test('stream emits events during post-migration CRUD', () async {
      await init();

      final events = <JSON>[];
      final sub = LocalShared.stream.listen(events.add);

      await Shared.col('stream_edge').create();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(events, isNotEmpty);
      await sub.cancel();
    });

    test('delete after lazy migration cleans both stores', () async {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues(
        {spKey('__local_shared_migrated__'): true},
      );
      await const LocalShared('test_db').initialize();

      // Inject legacy SP key after migration flag was set.
      await LocalShared.preferences.setString(
        'del_col',
        jsonEncode({'d': <String, dynamic>{'bye': true}}),
      );

      // Read triggers lazy migration.
      await Shared.col('del_col').read();

      // Now delete.
      final deleteResp = await Shared.col('del_col').delete();
      expect(deleteResp.success, isTrue);

      expect(await LocalShared.storage.read(key: 'del_col'), isNull);
      expect(LocalShared.preferences.getString('del_col'), isNull);
    });

    test('update after legacy read does not re-pollute SP', () async {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues(
        {spKey('__local_shared_migrated__'): true},
      );
      await const LocalShared('test_db').initialize();

      await LocalShared.preferences.setString(
        'upd_col',
        jsonEncode({'ud': <String, dynamic>{'v': 1}}),
      );

      // Lazy migrate via read.
      await Shared.col('upd_col').read();

      // Update.
      await Shared.col('upd_col').doc('ud').update({'v': 2});

      // SP must remain clean.
      expect(LocalShared.preferences.getString('upd_col'), isNull);
      // Secure must have updated value.
      final raw = await LocalShared.storage.read(key: 'upd_col');
      expect(raw, isNotNull);
      final decoded = jsonDecode(raw!) as Map<String, dynamic>;
      expect((decoded['ud'] as Map)['v'], 2);
    });
  });
}
