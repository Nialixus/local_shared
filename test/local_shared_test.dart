import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_shared/local_shared.dart';

void main() {
  // 1. Mandatory for any test using plugins (MethodChannels)
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Local Shared Test', () {
    setUp(() {
      // provide mock values for SharedPreferences so initialization works
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('storage and preferences getters require initialize', () {
      expect(() => LocalShared.storage, throwsStateError);
      expect(() => LocalShared.preferences, throwsStateError);
    });

    test('Initialization', () async {
      const db = LocalShared('test_db');
      await db.initialize();
      expect(db, isNotNull);
      expect(Shared.col('collection'), isA<SharedCollection>());
    });

    test('col and collection return equivalent objects', () {
      final col = Shared.col('my_collection');
      final col2 = Shared.collection('my_collection');
      expect(col2, isA<SharedCollection>());
      expect(col.id, equals(col2.id));
      expect(col.toString(), contains('my_collection'));
    });

    test('create/read/delete collection operations', () async {
      const db = LocalShared('test_db_2');
      await db.initialize();

      final collection = Shared.col('test_collection');
      await collection.delete();

      final createResp = await collection.create();
      expect(createResp.success, isTrue);
      expect(createResp, isA<SharedMany>());
      expect(createResp.data, isEmpty);

      final readResp = await collection.read();
      expect(readResp.success, isTrue);
      expect(readResp.data, isA<List<JSON>>());
      expect((readResp.data as List).isEmpty, isTrue);

      final deleteResp = await collection.delete();
      expect(deleteResp.success, isTrue);
      expect(deleteResp, isA<SharedNone>());
    });

    test('stream emits events on collection mutations', () async {
      final completed = <JSON>[];
      final sub = LocalShared.stream.listen((event) {
        completed.add(event);
      });

      const db = LocalShared('test_db_stream');
      await db.initialize();

      final coll = Shared.col('stream_collection');
      await coll.delete();
      await coll.create();

      // allow asynchronous stream event dispatch
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(completed, isNotEmpty);

      await sub.cancel();
      await LocalShared.close();
    });
  });
}