import 'dart:collection';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_shared/local_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Instrumented [MapBase] backing [FlutterSecureStorage] in tests.
///
/// Tracks exact read/write/delete/deleteAll call counts and supports fault
/// injection to simulate Android Keystore invalidation (`BadPaddingException`),
/// transient write errors, and corrupted payloads.
class InstrumentedSecureMap extends MapBase<String, String> {
  final Map<String, String> inner = {};

  int readCalls = 0;
  int writeCalls = 0;
  int deleteCalls = 0;
  int deleteAllCalls = 0;

  bool failReads = false;
  int failWritesRemaining = 0;
  bool failAllWrites = false;
  bool failDeletes = false;

  void resetCounters() {
    readCalls = 0;
    writeCalls = 0;
    deleteCalls = 0;
    deleteAllCalls = 0;
  }

  void resetFaults() {
    failReads = false;
    failWritesRemaining = 0;
    failAllWrites = false;
    failDeletes = false;
  }

  @override
  String? operator [](Object? key) {
    readCalls++;
    if (failReads) {
      throw PlatformException(
        code: 'Exception encountered',
        message: 'javax.crypto.BadPaddingException: Keystore key invalidated',
      );
    }
    return inner[key];
  }

  @override
  void operator []=(String key, String value) {
    writeCalls++;
    if (failAllWrites) {
      throw PlatformException(
        code: 'KEYSTORE_FATAL',
        message: 'Hardware keystore unavailable',
      );
    }
    if (failWritesRemaining > 0) {
      failWritesRemaining--;
      throw PlatformException(
        code: 'KEYSTORE_STALE',
        message: 'Stale encryption key, reset required',
      );
    }
    inner[key] = value;
  }

  @override
  bool containsKey(Object? key) => inner.containsKey(key);

  @override
  void clear() {
    deleteAllCalls++;
    inner.clear();
  }

  @override
  Iterable<String> get keys => inner.keys;

  @override
  String? remove(Object? key) {
    deleteCalls++;
    if (failDeletes) {
      throw PlatformException(
        code: 'DELETE_ERROR',
        message: 'Key entry missing during delete',
      );
    }
    return inner.remove(key);
  }
}

/// Builds a realistic, deeply nested SaaS user session/profile JSON document.
JSON makeUserDoc({
  required String userId,
  String displayName = 'Niali 🚀 日本語',
  String theme = 'dark',
  bool emailEnabled = true,
  bool pushEnabled = true,
}) {
  return {
    'userId': userId,
    'displayName': displayName,
    'bio': 'Line1\nLine2 with "quotes" & \\backslashes\\',
    'verified': true,
    'loginCount': 42,
    'balance': 1234.56,
    'negativeOffset': -7,
    'zeroValue': 0,
    'deletedAt': null,
    'roles': ['admin', 'editor', 'billing_owner'],
    'emptyTags': <dynamic>[],
    'emptyMeta': <String, dynamic>{},
    'auth': {
      'accessToken': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.payload.sig',
      'refreshToken': 'rt_live_98a76b54c32d10e',
      'expiresIn': 3600,
      'mfa': {
        'enabled': true,
        'methods': ['totp', 'webauthn'],
      },
    },
    'preferences': {
      'theme': theme,
      'locale': 'en-US',
      'notifications': {
        'channels': {
          'email': emailEnabled,
          'push': pushEnabled,
          'sms': false,
        },
        'quietHours': {'start': '22:00', 'end': '07:00'},
      },
    },
    'devices': [
      {
        'id': 'dev_ios_1',
        'os': 'iOS 18.2',
        'trusted': true,
        'lastSeen': 1762950000,
      },
      {
        'id': 'dev_android_2',
        'os': 'Android 15',
        'trusted': false,
        'lastSeen': 1762940000,
      },
    ],
  };
}

/// Builds a realistic, deeply nested e-commerce order JSON document.
JSON makeOrderDoc(int index) {
  return {
    'orderId': 'ORD-${10000 + index}',
    'customerId': 'cust_${index % 15}',
    'status': index % 3 == 0 ? 'shipped' : 'processing',
    'currency': 'USD',
    'totalAmount': double.parse((49.95 + index * 3.25).toStringAsFixed(2)),
    'isPriority': index.isEven,
    'notes': index % 5 == 0 ? null : 'Leave at front desk #$index 📦',
    'shipping': {
      'carrier': 'DHL Express',
      'address': {
        'street': '${100 + index} Market St',
        'city': 'Jakarta',
        'postalCode': '10110',
        'geo': {
          'lat': -6.2088 + (index * 0.001),
          'lng': 106.8456 + (index * 0.001),
        },
      },
    },
    'items': [
      {
        'sku': 'SKU-A-$index',
        'qty': (index % 4) + 1,
        'unitPrice': 19.99,
        'discounts': [
          {'code': 'SAVE10', 'percent': 10},
        ],
      },
      {
        'sku': 'SKU-B-$index',
        'qty': 1,
        'unitPrice': 29.96,
        'discounts': <dynamic>[],
      },
    ],
    'auditTrail': [
      {'step': 'created', 'by': 'checkout_api', 'seq': 1},
      {'step': 'paid', 'by': 'stripe_webhook', 'seq': 2},
    ],
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InstrumentedSecureMap secureStore;

  Future<void> initStorage({
    String dbId = 'prod_e2e_db',
    Map<String, Object> sp = const {},
    Map<String, String> secure = const {},
  }) async {
    secureStore = InstrumentedSecureMap();
    secureStore.inner.addAll(secure);
    FlutterSecureStorage.setMockInitialValues(secureStore);
    SharedPreferences.setMockInitialValues(Map<String, Object>.from(sp));
    await LocalShared(dbId).initialize();
    secureStore.resetCounters();
  }

  // ===========================================================================
  // Group 1: SharedCollection Full Parameter Matrix & Lifecycle
  // ===========================================================================
  group('Group 1 — SharedCollection Full Parameter Matrix & Lifecycle', () {
    setUp(() async {
      await initStorage();
    });

    test('create({replace}) permutations, ids(), read(), update({force}), delete()',
        () async {
      final col = Shared.col('tenants');

      // Missing collection: ids() == [], read() & delete() & update(force: false) fail
      expect(await col.ids(), isEmpty);
      expect((await col.read()).success, isFalse);
      expect((await col.delete()).success, isFalse);
      expect((await col.update({'d': {'a': 1}}, force: false)).success, isFalse);

      // create(replace: false) on missing -> succeeds with empty list
      final c1 = await col.create(replace: false);
      expect(c1, isA<SharedMany>());
      expect(c1.success, isTrue);
      expect(c1.many, isEmpty);
      expect(c1.message, contains('created'));

      // read() on existing empty collection -> success: true, data: []
      final emptyRead = await col.read();
      expect(emptyRead.success, isTrue);
      expect(emptyRead.many, isEmpty);
      expect(await col.ids(), isEmpty);

      // create(replace: true) on missing collection -> succeeds ('recreated')
      final cMissingReplace = await Shared.col('missing_replace').create(replace: true);
      expect(cMissingReplace.success, isTrue);
      expect(cMissingReplace.message, contains('recreated'));

      // create(replace: false) on existing -> fails
      final dup = await col.create(replace: false);
      expect(dup, isA<SharedNone>());
      expect(dup.success, isFalse);
      expect(dup.message, contains('already exists'));

      // update(force: false) on existing collection with complex JSON
      secureStore.resetCounters();
      final upd = await col.update({
        'tenant_alpha': makeUserDoc(userId: 'u_alpha'),
        'tenant_beta': makeUserDoc(
          userId: 'u_beta',
          displayName: 'Beta Corp',
          theme: 'light',
        ),
      }, force: false);
      expect(upd.success, isTrue);
      expect(upd.many, hasLength(2));
      expect(secureStore.readCalls, equals(1));
      expect(secureStore.writeCalls, equals(1));

      // update(force: true) on existing collection merges cleanly
      final updForceExisting = await col.update({
        'tenant_alpha': {'verified': false},
      }, force: true);
      expect(updForceExisting.success, isTrue);
      expect((await col.doc('tenant_alpha').read()).one!['verified'], isFalse);

      // update(force: true) on missing collection creates it
      final forcedNew = await Shared.col('forced_col').update({
        'k1': {'active': true},
      }, force: true);
      expect(forcedNew.success, isTrue);
      expect(forcedNew.many, hasLength(1));

      // create(replace: true) on populated collection preserves docs
      final replaced = await col.create(replace: true);
      expect(replaced.success, isTrue);
      expect(replaced.many, hasLength(2));
      expect(await col.ids(), containsAll(['tenant_alpha', 'tenant_beta']));

      // doc/document & docs/documents equivalence
      expect(col.doc('x').id, equals(col.document('x').id));
      expect(col.docs(['a', 'b']).ids, equals(col.documents(['a', 'b']).ids));
      expect(col.toString(), contains('tenants'));

      // delete() existing populated collection
      final del = await col.delete();
      expect(del, isA<SharedNone>());
      expect(del.success, isTrue);
      expect((await col.read()).success, isFalse);
    });

    test('SharedCollection.migrate(id, {merge, force}) all permutations',
        () async {
      // 1. Source missing, force: false -> fails
      expect(
        (await Shared.col('no_src').migrate('dst', merge: false, force: false))
            .success,
        isFalse,
      );
      expect(
        (await Shared.col('no_src').migrate('dst', merge: true, force: false))
            .success,
        isFalse,
      );

      // 2. Source missing, force: true, target missing -> creates empty target
      final forceEmpty = await Shared.col('no_src').migrate(
        'empty_dst',
        merge: false,
        force: true,
      );
      expect(forceEmpty.success, isTrue);
      expect(forceEmpty.many, isEmpty);

      // 3. Source missing, force: true, target exists:
      //    merge: false -> fails; merge: true -> preserves target
      await Shared.col('existing_dst').doc('d').create({'keep': 1});
      expect(
        (await Shared.col('no_src')
                .migrate('existing_dst', merge: false, force: true))
            .success,
        isFalse,
      );
      final forceMergeExisting = await Shared.col('no_src').migrate(
        'existing_dst',
        merge: true,
        force: true,
      );
      expect(forceMergeExisting.success, isTrue);
      expect(forceMergeExisting.many, equals([{'keep': 1}]));

      // 4. Same ID: force: false -> fails; force: true -> succeeds (1R/1W)
      await Shared.col('same_col').doc('d1').create({'v': 1});
      expect(
        (await Shared.col('same_col').migrate('same_col', force: false))
            .success,
        isFalse,
      );
      secureStore.resetCounters();
      final sameForce =
          await Shared.col('same_col').migrate('same_col', force: true);
      expect(sameForce.success, isTrue);
      expect(sameForce.many, equals([{'v': 1}]));
      expect(secureStore.readCalls, equals(1));
      expect(secureStore.writeCalls, equals(1));

      // 5. Source exists, target exists, merge: false -> fails (source kept)
      await Shared.col('src_col').doc('shared').create({
        'from': 'src',
        'nested': {'s': 1, 'conflict': 'src'},
      });
      await Shared.col('tgt_col').doc('shared').create({
        'from': 'tgt',
        'onlyTarget': true,
        'nested': {'t': 2, 'conflict': 'tgt'},
      });
      expect(
        (await Shared.col('src_col').migrate('tgt_col', merge: false)).success,
        isFalse,
      );
      expect((await Shared.col('src_col').read()).success, isTrue);

      // 6. Source exists, target exists, merge: true -> target wins on scalar conflict
      //    per `(collection ?? {}).merge(target ?? {})` contract, source deleted
      final merged =
          await Shared.col('src_col').migrate('tgt_col', merge: true);
      expect(merged.success, isTrue);
      expect((await Shared.col('src_col').read()).success, isFalse);
      final mergedDoc = (await Shared.col('tgt_col').doc('shared').read()).one!;
      expect(mergedDoc['from'], equals('tgt'));
      expect(mergedDoc['onlyTarget'], isTrue);
      expect(
        mergedDoc['nested'],
        equals({'s': 1, 't': 2, 'conflict': 'tgt'}),
      );

      // 7. Source exists, target missing, merge: false -> moves source cleanly
      final moved =
          await Shared.col('tgt_col').migrate('final_col', merge: false);
      expect(moved.success, isTrue);
      expect((await Shared.col('tgt_col').read()).success, isFalse);
      expect((await Shared.col('final_col').doc('shared').read()).success, isTrue);
    });
  });

  // ===========================================================================
  // Group 2: SharedDocument Full Parameter Matrix & Complex JSON
  // ===========================================================================
  group('Group 2 — SharedDocument Full Parameter Matrix & Complex JSON', () {
    setUp(() async {
      await initStorage();
    });

    test('create({merge, force}), read(), update({force}), delete() permutations',
        () async {
      final col = Shared.col('users');
      final doc = col.doc('usr_001');
      final payload = makeUserDoc(userId: 'usr_001');

      // Missing collection checks
      expect((await doc.read()).success, isFalse);
      expect((await doc.delete()).success, isFalse);
      expect((await doc.create(payload, force: false, merge: false)).success,
          isFalse);
      expect(
          (await doc.create(payload, force: false, merge: true)).success, isFalse);
      expect((await doc.update({'x': 1}, force: false)).success, isFalse);

      // create(force: true, merge: false) creates collection + doc (1R/1W)
      secureStore.resetCounters();
      final created = await doc.create(payload, force: true, merge: false);
      expect(created, isA<SharedOne>());
      expect(created.success, isTrue);
      expect(created.message, contains('created'));
      expect(secureStore.readCalls, equals(1));
      expect(secureStore.writeCalls, equals(1));

      // Exact complex JSON round-trip fidelity
      final readBack = await doc.read();
      expect(readBack.success, isTrue);
      final data = readBack.one!;
      expect(data['displayName'], equals('Niali 🚀 日本語'));
      expect(data['bio'], equals('Line1\nLine2 with "quotes" & \\backslashes\\'));
      expect(data['balance'], equals(1234.56));
      expect(data['negativeOffset'], equals(-7));
      expect(data['zeroValue'], equals(0));
      expect(data['deletedAt'], isNull);
      expect(data['emptyTags'], isEmpty);
      expect(data['emptyMeta'], isEmpty);
      expect((data['devices'] as List), hasLength(2));
      expect(
        (((data['auth'] as Map)['mfa'] as Map)['methods'] as List),
        equals(['totp', 'webauthn']),
      );

      // Missing doc in existing collection checks
      final missingDoc = col.doc('usr_missing');
      expect((await missingDoc.read()).success, isFalse);
      expect((await missingDoc.delete()).success, isFalse);
      expect((await missingDoc.update({'a': 1}, force: false)).success, isFalse);

      // create(force: false, merge: true) on missing doc in existing collection
      final createMissingMerge = await col
          .doc('usr_new_merge')
          .create({'fresh': true}, force: false, merge: true);
      expect(createMissingMerge.success, isTrue);
      expect(createMissingMerge.message, contains('merged'));

      // Existing doc: create(merge: false) fails for both force: true and force: false
      expect(
          (await doc.create({'x': 1}, merge: false, force: true)).success, isFalse);
      expect((await doc.create({'x': 1}, merge: false, force: false)).success,
          isFalse);

      // Existing doc: create(merge: true) overrides scalars & preserves siblings
      secureStore.resetCounters();
      final mergedCreate = await doc.create({
        'auth': {'expiresIn': 7200},
      }, merge: true, force: false);
      expect(mergedCreate.success, isTrue);
      expect((mergedCreate.one!['auth'] as Map)['expiresIn'], equals(7200));
      expect((mergedCreate.one!['auth'] as Map)['accessToken'], isNotNull);
      expect(secureStore.readCalls, equals(1));
      expect(secureStore.writeCalls, equals(1));

      // update(force: false) & update(force: true) on existing doc
      secureStore.resetCounters();
      final updated = await doc.update({
        'preferences': {
          'notifications': {
            'channels': {'email': false},
          },
        },
      }, force: false);
      expect(updated.success, isTrue);
      expect(secureStore.readCalls, equals(1));
      expect(secureStore.writeCalls, equals(1));
      final channels = ((updated.one!['preferences'] as Map)['notifications']
          as Map)['channels'] as Map;
      expect(channels, equals({'email': false, 'push': true, 'sms': false}));
      expect((updated.one!['preferences'] as Map)['theme'], equals('dark'));

      // update(force: true) on missing collection creates both collection & doc
      final forcedColDoc = Shared.col('brand_new_col').doc('d1');
      final forcedResp = await forcedColDoc.update({'v': 99}, force: true);
      expect(forcedResp.success, isTrue);
      expect(forcedResp.one, equals({'v': 99}));

      // Empty {} doc can be created, read, and deleted cleanly
      final emptyDoc = col.doc('empty_doc');
      expect((await emptyDoc.create({})).success, isTrue);
      expect((await emptyDoc.read()).one, isEmpty);
      expect((await emptyDoc.create({}, merge: false)).success, isFalse);
      expect((await emptyDoc.delete()).success, isTrue);

      // Deleting one doc leaves sibling docs intact
      secureStore.resetCounters();
      expect((await doc.delete()).success, isTrue);
      expect(secureStore.readCalls, equals(1));
      expect(secureStore.writeCalls, equals(1));
      expect((await doc.read()).success, isFalse);
      expect((await col.doc('usr_new_merge').read()).success, isTrue);
    });

    test('SharedDocument.migrate(id, {merge, force}) all permutations',
        () async {
      final col = Shared.col('doc_migrate_col');

      // 1. Missing collection, force: false -> fails; force: true -> creates target {}
      expect(
        (await col.doc('a').migrate('b', force: false)).success,
        isFalse,
      );
      final missingColForce = await col.doc('a').migrate('b', force: true);
      expect(missingColForce.success, isTrue);
      expect(missingColForce.one, isEmpty);
      expect((await col.doc('b').read()).one, isEmpty);

      // 2. Missing source doc in existing collection:
      //    force: false -> fails
      //    force: true, target exists, merge: false -> fails
      //    force: true, target exists, merge: true -> preserves target
      await col.doc('target_keep').create({'preserved': 42});
      expect(
        (await col.doc('no_source').migrate('target_keep', force: false))
            .success,
        isFalse,
      );
      expect(
        (await col
                .doc('no_source')
                .migrate('target_keep', merge: false, force: true))
            .success,
        isFalse,
      );
      final missingSrcMergeForce = await col
          .doc('no_source')
          .migrate('target_keep', merge: true, force: true);
      expect(missingSrcMergeForce.success, isTrue);
      expect(missingSrcMergeForce.one, equals({'preserved': 42}));

      // 3. Same ID: force: false -> fails; force: true -> keeps doc intact
      await col.doc('src').create({'k': 'srcVal', 'shared': 'fromSrc'});
      expect(
        (await col.doc('src').migrate('src', force: false)).success,
        isFalse,
      );
      final sameIdForce = await col.doc('src').migrate('src', force: true);
      expect(sameIdForce.success, isTrue);
      expect(sameIdForce.one, containsPair('k', 'srcVal'));

      // 4. Target exists, merge: false -> fails (even if force: true!)
      await col.doc('tgt').create({'t': 'tgtVal', 'shared': 'fromTgt'});
      expect(
        (await col.doc('src').migrate('tgt', merge: false, force: false))
            .success,
        isFalse,
      );
      expect(
        (await col.doc('src').migrate('tgt', merge: false, force: true))
            .success,
        isFalse,
      );

      // 5. Target exists, merge: true -> merges (target wins on conflict per sourceDoc.merge(targetDoc)), source removed
      secureStore.resetCounters();
      final merged = await col.doc('src').migrate('tgt', merge: true);
      expect(merged.success, isTrue);
      expect(secureStore.readCalls, equals(1));
      expect(secureStore.writeCalls, equals(1));
      expect(merged.one, equals({'k': 'srcVal', 't': 'tgtVal', 'shared': 'fromTgt'}));
      expect((await col.doc('src').read()).success, isFalse);

      // 6. Target missing, merge: false -> moves source to new ID
      final moved = await col.doc('tgt').migrate('final_doc', merge: false);
      expect(moved.success, isTrue);
      expect((await col.doc('tgt').read()).success, isFalse);
      expect((await col.doc('final_doc').read()).one,
          containsPair('k', 'srcVal'));
    });
  });

  // ===========================================================================
  // Group 3: SharedManyDocument Full Parameter Matrix & 100-Doc Batch Stress
  // ===========================================================================
  group('Group 3 — SharedManyDocument Full Parameter Matrix & 100-Doc Stress',
      () {
    setUp(() async {
      await initStorage();
    });

    test('100-doc batch create, read, update, delete with strict 1R/1W I/O',
        () async {
      const batchSize = 100;
      final ids = List<String>.generate(batchSize, (i) => 'order_$i');
      final col = Shared.col('orders');
      final sw = Stopwatch()..start();

      // 1. Batch create 100 deeply nested order docs -> 1R/1W
      secureStore.resetCounters();
      final createResp = await col.docs(ids).create((i) => makeOrderDoc(i));
      final createMs = sw.elapsedMilliseconds;
      expect(createResp, isA<SharedMany>());
      expect(createResp.success, isTrue);
      expect(createResp.many, hasLength(batchSize));
      expect(secureStore.readCalls, equals(1));
      expect(secureStore.writeCalls, equals(1));

      // 2. Batch read({skip}) all permutations
      final allRead = await col.docs(['order_0', 'order_99']).read(skip: false);
      expect(allRead.success, isTrue);
      expect(allRead.many, hasLength(2));

      final partialSkip = await col
          .docs(['order_0', 'missing_x', 'order_99']).read(skip: true);
      expect(partialSkip.success, isTrue);
      expect(partialSkip.many, hasLength(2));
      expect(partialSkip.message, contains('2 / 3'));

      final partialStrict = await col
          .docs(['order_0', 'missing_x']).read(skip: false);
      expect(partialStrict, isA<SharedNone>());
      expect(partialStrict.success, isFalse);

      final zeroHitSkip = await col.docs(['m1', 'm2']).read(skip: true);
      expect(zeroHitSkip, isA<SharedMany>());
      expect(zeroHitSkip.success, isFalse);
      expect(zeroHitSkip.many, isEmpty);

      final emptyIdsRead = await col.docs([]).read(skip: false);
      expect(emptyIdsRead, isA<SharedMany>());
      expect(emptyIdsRead.success, isFalse);
      expect(emptyIdsRead.many, isEmpty);

      // 3. Batch update 100 docs -> 1R/1W
      sw.reset();
      secureStore.resetCounters();
      final updateResp = await col.docs(ids).update((i) => {
            'status': 'delivered',
            'shipping': {
              'address': {'city': 'Bandung'},
            },
          });
      final updateMs = sw.elapsedMilliseconds;
      expect(updateResp.success, isTrue);
      expect(updateResp.many, hasLength(batchSize));
      expect(secureStore.readCalls, equals(1));
      expect(secureStore.writeCalls, equals(1));

      final addr =
          (updateResp.many![42]['shipping'] as Map)['address'] as Map;
      expect(addr['city'], equals('Bandung'));
      expect((addr['geo'] as Map)['lat'], isA<double>());

      // 4. Batch delete 40 docs -> 1R/1W
      sw.reset();
      secureStore.resetCounters();
      final deleteResp =
          await col.docs(ids.sublist(0, 40)).delete(skip: false);
      final deleteMs = sw.elapsedMilliseconds;
      expect(deleteResp, isA<SharedNone>());
      expect(deleteResp.success, isTrue);
      expect(deleteResp.message, contains('40 document'));
      expect(secureStore.readCalls, equals(1));
      expect(secureStore.writeCalls, equals(1));
      expect(await col.ids(), hasLength(60));

      // ignore: avoid_print
      print(
        '[E2E BENCHMARK] 100-doc batch: create=${createMs}ms (1R/1W), '
        'update=${updateMs}ms (1R/1W), 40-doc delete=${deleteMs}ms (1R/1W)',
      );
    });

    test('SharedManyDocument create/update/delete edge permutations & atomicity',
        () async {
      final col = Shared.col('many_edge');

      // Missing collection checks
      expect(
        (await col.docs(['a']).create((_) => {'a': 1}, force: false)).success,
        isFalse,
      );
      expect(
        (await col.docs(['a']).read(skip: true)).success,
        isFalse,
      );
      expect(
        (await col.docs(['a']).update((_) => {'a': 1}, force: false)).success,
        isFalse,
      );
      expect(
        (await col.docs(['a']).delete(skip: true)).success,
        isFalse,
      );

      // update(force: true) on missing collection creates collection + docs
      final forceUpdateCol = await col.docs(['d1', 'd2']).update(
        (i) => {'idx': i, 'keep': 'yes'},
        force: true,
      );
      expect(forceUpdateCol.success, isTrue);
      expect(forceUpdateCol.many, hasLength(2));

      // Atomicity: create(['d1', 'd3'], merge: false) must fail WITHOUT creating 'd3'
      final partialDup = await col.docs(['d3', 'd1']).create(
        (i) => {'idx': i},
        merge: false,
      );
      expect(partialDup.success, isFalse);
      expect((await col.doc('d3').read()).success, isFalse);

      // create(['d1', 'd3'], merge: true) merges d1 and creates d3
      final partialMerge = await col.docs(['d1', 'd3']).create(
        (i) => {'merged': i == 0, 'fresh': i == 1},
        merge: true,
      );
      expect(partialMerge.success, isTrue);
      expect(partialMerge.many, hasLength(2));
      expect((await col.doc('d1').read()).one, containsPair('keep', 'yes'));
      expect((await col.doc('d1').read()).one, containsPair('merged', true));

      // Atomicity: update(['d1', 'missing_u'], force: false) must NOT modify 'd1'
      final atomicUpdFail = await col.docs(['d1', 'missing_u']).update(
        (_) => {'keep': 'mutated'},
        force: false,
      );
      expect(atomicUpdFail.success, isFalse);
      expect((await col.doc('d1').read()).one, containsPair('keep', 'yes'));

      // update(['d1', 'd4'], force: true) updates d1 and creates d4
      final forcePartialUpd = await col.docs(['d1', 'd4']).update(
        (i) => {'updated': i},
        force: true,
      );
      expect(forcePartialUpd.success, isTrue);
      expect(forcePartialUpd.many, hasLength(2));
      expect((await col.doc('d4').read()).one, equals({'updated': 1}));

      // Duplicate IDs inside iterable in create(merge: true)
      final dupIdsCreate = await col.docs(['dup_x', 'dup_x']).create(
        (i) => {'pass': i},
        merge: true,
      );
      expect(dupIdsCreate.success, isTrue);
      expect((await col.doc('dup_x').read()).one, equals({'pass': 1}));

      // Empty ids = [] create / update / delete
      expect((await col.docs([]).create((_) => {})).many, isEmpty);
      expect((await col.docs([]).update((_) => {})).many, isEmpty);
      expect((await col.docs([]).delete()).success, isFalse);

      // Atomicity: delete(['d4', 'missing_d'], skip: false) must NOT delete 'd4'
      final atomicDelFail =
          await col.docs(['d4', 'missing_d']).delete(skip: false);
      expect(atomicDelFail.success, isFalse);
      expect((await col.doc('d4').read()).success, isTrue);

      // delete(['d4', 'missing_d'], skip: true) deletes d4 and reports 1 deleted
      final partialDelSkip =
          await col.docs(['d4', 'missing_d']).delete(skip: true);
      expect(partialDelSkip.success, isTrue);
      expect(partialDelSkip.message, contains('1 document'));
      expect((await col.doc('d4').read()).success, isFalse);

      // delete non-existing with skip: true returns success: false
      expect((await col.docs(['ghost']).delete(skip: true)).success, isFalse);

      // Callback throwing exception mid-batch fails cleanly without partial write
      final beforeCount = (await col.ids()).length;
      final cbThrow = await col.docs(['cb_1', 'cb_2']).create((i) {
        if (i == 1) throw StateError('boom in builder');
        return {'ok': true};
      });
      expect(cbThrow, isA<SharedNone>());
      expect(cbThrow.success, isFalse);
      expect(cbThrow.message, contains('boom in builder'));
      expect((await col.ids()).length, equals(beforeCount));

      // Callback returning invalid Dart type fails cleanly without Keystore wipe
      secureStore.resetCounters();
      final cbInvalidType = await col.docs(['cb_bad']).create(
        (_) => {'when': DateTime.now()},
      );
      expect(cbInvalidType.success, isFalse);
      expect(cbInvalidType.message, contains('Invalid type'));
      expect(secureStore.deleteAllCalls, equals(0));
    });

    test('SharedManyDocument.migrate(id, {merge, force}) all permutations',
        () async {
      final col = Shared.col('many_mig');

      // 1. Empty/missing collection: force: false -> fails; force: true -> creates {}
      expect(
        (await col.docs(['a']).migrate('tgt', force: false)).success,
        isFalse,
      );
      final forceEmpty = await col.docs(['a']).migrate('tgt', force: true);
      expect(forceEmpty.success, isTrue);
      expect(forceEmpty.one, isEmpty);

      // Reset cleanly
      await col.delete();
      await col.docs(['s1', 's2', 'tgt']).create((i) {
        if (i == 0) return {'k1': 'v1', 'shared': 'from_s1'};
        if (i == 1) return {'k2': 'v2', 'shared': 'from_s2'};
        return {'existing': true, 'shared': 'from_tgt'};
      });

      // 2. ids.contains(id): force: false -> fails; force: true -> skips target in source loop
      expect(
        (await col.docs(['s1', 'tgt']).migrate('tgt', force: false)).success,
        isFalse,
      );

      // 3. Existing target, merge: false, force: false -> fails
      expect(
        (await col.docs(['s1']).migrate('tgt', merge: false, force: false))
            .success,
        isFalse,
      );

      // 4. Existing target, merge: false, force: true -> overwrites target & removes sources
      final overwriteTarget = await col
          .docs(['s1', 'tgt'])
          .migrate('tgt', merge: false, force: true);
      expect(overwriteTarget.success, isTrue);
      expect(overwriteTarget.one, equals({'k1': 'v1', 'shared': 'from_s1'}));
      expect((await col.doc('s1').read()).success, isFalse);

      // 5. Missing one source doc: force: false -> fails atomically (s2 kept!)
      expect(
        (await col.docs(['s2', 'missing_s']).migrate('tgt',
                merge: true, force: false))
            .success,
        isFalse,
      );
      expect((await col.doc('s2').read()).success, isTrue);

      // 6. Missing one source doc + existing target, merge: true, force: true -> merges s2 into tgt
      secureStore.resetCounters();
      final forcePartialMig = await col
          .docs(['s2', 'missing_s'])
          .migrate('tgt', merge: true, force: true);
      expect(forcePartialMig.success, isTrue);
      expect(secureStore.readCalls, equals(1));
      expect(secureStore.writeCalls, equals(1));
      expect(
        forcePartialMig.one,
        equals({'k1': 'v1', 'k2': 'v2', 'shared': 'from_s2'}),
      );
      expect((await col.doc('s2').read()).success, isFalse);

      // 7. Empty ids: target missing + force: false -> fails; target exists + merge: true -> keeps target
      expect(
        (await col.docs([]).migrate('brand_new_tgt', force: false)).success,
        isFalse,
      );
      final emptyIdsExistingTgt =
          await col.docs([]).migrate('tgt', merge: true, force: false);
      expect(emptyIdsExistingTgt.success, isTrue);
      expect(emptyIdsExistingTgt.one, containsPair('k2', 'v2'));

      // 8. Invalid source doc type in raw storage
      secureStore.inner['many_mig'] = jsonEncode({
        'bad': ['not_a_map'],
      });
      final badType = await col.docs(['bad']).migrate('out');
      expect(badType.success, isFalse);
      expect(badType.message, contains('invalid type'));
    });
  });

  // ===========================================================================
  // Group 4: JSONExtension.merge, Special IDs, Concurrency & Hybrid Migration
  // ===========================================================================
  group('Group 4 — Deep Merge Rules, Special IDs, Concurrency & Hybrid Migration',
      () {
    setUp(() async {
      await initStorage();
    });

    test('JSONExtension.merge edge cases: nested maps, lists, scalar overrides, non-mutation',
        () {
      final source = <String, dynamic>{
        'scalarToMap': 'old_str',
        'mapToScalar': {'a': 1},
        'listReplace': [1, 2, 3],
        'nullVsSet': null,
        'setVsNull': 'keep_when_target_null',
        'deep': {
          'l2': {
            'l3': {'keep': true, 'override': 'src'},
          },
        },
      };
      final target = <String, dynamic>{
        'scalarToMap': {'new': 1},
        'mapToScalar': 99,
        'listReplace': [4],
        'nullVsSet': 'now_set',
        'setVsNull': null,
        'deep': {
          'l2': {
            'l3': {'override': 'tgt', 'added': 2},
          },
        },
      };

      final merged = source.merge(target);

      expect(merged['scalarToMap'], equals({'new': 1}));
      expect(merged['mapToScalar'], equals(99));
      expect(merged['listReplace'], equals([4]));
      expect(merged['nullVsSet'], equals('now_set'));
      expect(merged['setVsNull'], equals('keep_when_target_null'));
      expect(
        ((merged['deep'] as Map)['l2'] as Map)['l3'],
        equals({'keep': true, 'override': 'tgt', 'added': 2}),
      );
      // Verify inputs were not mutated
      expect(((source['deep'] as Map)['l2'] as Map)['l3'], isNot(contains('added')));
    });

    test('Special IDs (dots, hyphens, spaces, unicode) & concurrent multi-collection ops',
        () async {
      final specialCol = Shared.col('v1.tenant-cfg 🚀');
      final specialDoc = specialCol.doc('doc.sub/key 1');

      expect((await specialDoc.create({'ok': true})).success, isTrue);
      expect((await specialDoc.read()).one, equals({'ok': true}));

      // Concurrent writes across 10 independent collections
      final results = await Future.wait([
        for (int i = 0; i < 10; i++)
          Shared.col('concurrent_$i').doc('item').create({'idx': i}),
      ]);
      expect(results.every((r) => r.success), isTrue);

      for (int i = 0; i < 10; i++) {
        final r = await Shared.col('concurrent_$i').doc('item').read();
        expect(r.one, equals({'idx': i}));
      }
    });

    test('Multiple broadcast stream listeners receive events independently',
        () async {
      final listA = <JSON>[];
      final listB = <JSON>[];
      final subA = LocalShared.stream.listen(listA.add);
      final subB = LocalShared.stream.listen(listB.add);

      await Shared.col('multi_stream').doc('d1').create({'x': 1});
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(listA, hasLength(1));
      expect(listB, hasLength(1));

      await subA.cancel();
      await Shared.col('multi_stream').doc('d2').create({'x': 2});
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(listA, hasLength(1));
      expect(listB, hasLength(2));

      await subB.cancel();
    });

    test('Hybrid migration: non-JSON SP entries preserved, corrupted SP string handled safely',
        () async {
      const prefix = 'flutter.prod_e2e_db.';
      await initStorage(
        sp: {
          '${prefix}app_owned_setting': 'not-json-string',
          '${prefix}app_owned_int': 77,
          '${prefix}legacy_col': jsonEncode({'d1': {'v': 1}}),
          '${prefix}conflict_col': jsonEncode({'d1': {'src': 'sp'}}),
        },
        secure: {
          'conflict_col': jsonEncode({'d1': {'src': 'secure'}}),
        },
      );

      // Non-JSON app-owned keys must remain intact in SP
      expect(LocalShared.preferences.getString('app_owned_setting'),
          equals('not-json-string'));
      expect(LocalShared.preferences.getInt('app_owned_int'), equals(77));

      // Valid JSON migrated; conflict_col keeps secure version
      expect(LocalShared.preferences.getString('legacy_col'), isNull);
      expect((await Shared.col('legacy_col').doc('d1').read()).one,
          equals({'v': 1}));
      expect((await Shared.col('conflict_col').doc('d1').read()).one,
          equals({'src': 'secure'}));

      // Corrupted lazy fallback value in SP degrades safely without FormatException
      await LocalShared.preferences.setString('corrupt_sp', '{broken_json');
      expect((await Shared.col('corrupt_sp').read()).success, isFalse);
    });
  });

  // ===========================================================================
  // Group 5: Security, Keystore Resilience & Re-Initialization Safety
  // ===========================================================================
  group('Group 5 — Security, Keystore Resilience & Re-Init Safety', () {
    setUp(() async {
      await initStorage();
    });

    test('Keystore BadPaddingException on read triggers wipe, emits sentinel, recovers cleanly',
        () async {
      final events = <JSON>[];
      final sub = LocalShared.stream.listen(events.add);

      await Shared.col('secrets').doc('token').create({'jwt': 'abc.def.ghi'});
      expect(secureStore.inner, isNotEmpty);

      secureStore.failReads = true;
      final readResp = await Shared.col('secrets').doc('token').read();
      expect(readResp, isA<SharedNone>());
      expect(readResp.success, isFalse);

      expect(secureStore.deleteAllCalls, greaterThanOrEqualTo(1));
      expect(secureStore.inner, isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(events.any((e) => e['__event__'] == 'storage_wiped'), isTrue);

      secureStore.resetFaults();
      final recoverCreate =
          await Shared.col('secrets').doc('token').create({'jwt': 'fresh'});
      expect(recoverCreate.success, isTrue);
      expect((await Shared.col('secrets').doc('token').read()).one,
          equals({'jwt': 'fresh'}));

      await sub.cancel();
    });

    test('Transient Keystore write failure wipes, retries once, and succeeds',
        () async {
      final events = <JSON>[];
      final sub = LocalShared.stream.listen(events.add);

      await Shared.col('old_col').doc('d').create({'old': 1});

      secureStore.failWritesRemaining = 1;
      final resp =
          await Shared.col('new_col').doc('d').create({'fresh': true});

      expect(resp, isA<SharedOne>());
      expect(resp.success, isTrue);
      expect(resp.one, equals({'fresh': true}));
      expect(secureStore.deleteAllCalls, equals(1));
      expect(secureStore.inner.containsKey('old_col'), isFalse);

      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(events.any((e) => e['__event__'] == 'storage_wiped'), isTrue);

      await sub.cancel();
    });

    test('Persistent Keystore failure on write degrades gracefully preserving pre-write state',
        () async {
      await Shared.col('pre').doc('d').create({'v': 1});

      secureStore.failAllWrites = true;
      final resp = await Shared.col('pre').doc('d').update({'v': 2});

      expect(resp.success, isFalse);
      expect(resp.one, equals({'v': 1}));
    });

    test('Keystore failure on delete cleans SP and returns success without crash',
        () async {
      await Shared.col('del_resilience').doc('d').create({'k': 1});
      await LocalShared.preferences.setString(
        'del_resilience',
        jsonEncode({'d': {'k': 1}}),
      );

      secureStore.failDeletes = true;
      final delResp = await Shared.col('del_resilience').delete();

      expect(delResp, isA<SharedNone>());
      expect(delResp.success, isTrue);
      expect(LocalShared.preferences.getString('del_resilience'), isNull);
    });

    test('Corrupted truncated JSON in secure storage degrades safely to SharedNone',
        () async {
      secureStore.inner['corrupt_col'] = '{"doc1": {"key": "unterminated';

      final resp = await Shared.col('corrupt_col').read();
      expect(resp, isA<SharedNone>());
      expect(resp.success, isFalse);
      expect(await Shared.col('corrupt_col').ids(), isEmpty);
    });

    test('Invalid Dart types fail cleanly without wiping existing secure data',
        () async {
      await Shared.col('safe_existing').doc('keep').create({'ok': true});

      final badDocResp = await Shared.col('bad_input').doc('d1').create({
        'timestamp': DateTime.now(),
        'pattern': RegExp('abc'),
      });
      expect(badDocResp, isA<SharedNone>());
      expect(badDocResp.success, isFalse);
      expect(badDocResp.message, contains('Invalid type'));

      final badColResp = await Shared.col('bad_col_input').update({
        'doc1': {'timestamp': DateTime.now()},
      }, force: true);
      expect(badColResp, isA<SharedNone>());
      expect(badColResp.success, isFalse);

      // Invalid input must never wipe existing secure data
      expect(secureStore.deleteAllCalls, equals(0));
      expect((await Shared.col('safe_existing').doc('keep').read()).one,
          equals({'ok': true}));

      // Mixed scalar/list/null/nested values in document succeed cleanly
      final mixedDoc = await Shared.col('mixed_doc').doc('entry').create({
        'version': 2,
        'label': 'prod',
        'tags': ['a', 'b'],
        'nullable': null,
      });
      expect(mixedDoc.success, isTrue);
      expect(mixedDoc.one, containsPair('version', 2));
      expect(mixedDoc.one, containsPair('nullable', null));
    });

    test('Empty LocalShared id throws AssertionError in debug/test mode',
        () async {
      await expectLater(
        () => const LocalShared('').initialize(),
        throwsA(isA<AssertionError>()),
      );
    });

    test('Atomic migration retry & repeated initialize() in same process without StateError',
        () async {
      const prefix = 'flutter.prod_e2e_db.';
      final legacySecure = InstrumentedSecureMap()..failAllWrites = true;
      FlutterSecureStorage.setMockInitialValues(legacySecure);
      SharedPreferences.setMockInitialValues({
        '${prefix}legacy_a': jsonEncode({'d1': {'a': 1}}),
        '${prefix}legacy_b': jsonEncode({'d2': {'b': 2}}),
      });

      // Attempt 1: Keystore writes fail during _migrateAll()
      await const LocalShared('prod_e2e_db').initialize();
      expect(
        LocalShared.preferences.getBool('__local_shared_migrated__'),
        isNull,
      );
      expect(LocalShared.preferences.getString('legacy_a'), isNotNull);

      // Attempt 2: Keystore recovers — calling initialize() AGAIN without resetting
      // SharedPreferences mocks proves setPrefix StateError guard works in production!
      legacySecure.failAllWrites = false;
      await const LocalShared('prod_e2e_db').initialize();
      expect(
        LocalShared.preferences.getBool('__local_shared_migrated__'),
        isTrue,
      );
      expect(LocalShared.preferences.getString('legacy_a'), isNull);
      expect(LocalShared.preferences.getString('legacy_b'), isNull);
      expect((await Shared.col('legacy_a').doc('d1').read()).one,
          equals({'a': 1}));
      expect((await Shared.col('legacy_b').doc('d2').read()).one,
          equals({'b': 2}));
    });
  });

  // ===========================================================================
  // Group 6: Response Helpers & Closed Stream Final Check
  // ===========================================================================
  group('Group 6 — Response Extensions & Closed Stream Resilience', () {
    setUp(() async {
      await initStorage();
    });

    test('SharedResponse .one/.many & Future .one()/.many() & toString()',
        () async {
      final col = Shared.col('ext_col');
      await col.doc('d1').create({'hello': 'world'});
      await col.doc('d2').create({'hello': 'dart'});

      final oneSync = await col.doc('d1').read();
      expect(oneSync.one, equals({'hello': 'world'}));
      expect(oneSync.many, isNull);
      expect(oneSync.toString(), contains('SharedOne'));

      final manySync = await col.read();
      expect(manySync.many, hasLength(2));
      expect(manySync.one, isNull);
      expect(manySync.toString(), contains('SharedMany'));

      final noneSync = await col.doc('missing').read();
      expect(noneSync.one, isNull);
      expect(noneSync.many, isNull);
      expect(noneSync.toString(), contains('SharedNone'));

      expect(await col.doc('d1').read().one(), equals({'hello': 'world'}));
      expect(await col.read().many(), hasLength(2));
      expect(await col.doc('missing').read().one(), isNull);
      expect(await col.doc('missing').read().many(), isNull);
    });

    // Must run last in this isolate since LocalShared.close() closes the
    // static broadcast StreamController permanently.
    test('All CRUD mutations and Keystore wipe after LocalShared.close() never throw StateError',
        () async {
      await LocalShared.close();

      final col = Shared.col('post_close_col');
      expect((await col.create()).success, isTrue);
      expect((await col.update({'d1': {'a': 1}})).success, isTrue);
      expect((await col.migrate('post_close_col_2')).success, isTrue);

      final col2 = Shared.col('post_close_col_2');
      expect((await col2.doc('d2').create({'b': 2})).success, isTrue);
      expect((await col2.doc('d2').update({'b': 3})).success, isTrue);
      expect((await col2.doc('d2').migrate('d3')).success, isTrue);
      expect((await col2.doc('d3').delete()).success, isTrue);
      expect(
        (await col2.docs(['x', 'y']).create((i) => {'i': i})).success,
        isTrue,
      );
      expect(
        (await col2.docs(['x', 'y']).update((i) => {'u': i})).success,
        isTrue,
      );
      expect((await col2.docs(['x']).delete()).success, isTrue);
      expect((await col2.docs(['y']).migrate('z')).success, isTrue);

      // Even a Keystore wipe after close() must not throw StateError
      secureStore.failReads = true;
      final afterWipe = await col2.doc('z').read();
      expect(afterWipe.success, isFalse);

      secureStore.resetFaults();
      expect((await col2.delete()).success, isFalse); // wiped above
    });
  });
}
