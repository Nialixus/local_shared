import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_shared/local_shared.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Shared Many Document Test', () {
    late SharedCollection collection;
    const String collectionId = 'collection_many';
    const JSON docA = {'a': 1};
    const JSON docB = {'b': 2};

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      await LocalShared('test_db').initialize();
      collection = Shared.collection(collectionId);
      await collection.delete();
    });

    test('Create multiple documents', () async {
      final response = await collection.docs(['docA', 'docB']).create((index) {
        return index == 0 ? docA : docB;
      });

      expect(response, isA<SharedMany>());
      expect(response.success, isTrue);
      expect(response.data, hasLength(2));
      expect(response.data, containsAll([docA, docB]));
    });

    test('Create existing docs without merge should fail', () async {
      await collection.docs(['docA', 'docB']).create((index) {
        return index == 0 ? docA : docB;
      });

      final response = await collection.docs(['docA']).create((_) => {'a': 9}, merge: false);
      expect(response, isA<SharedNone>());
      expect(response.success, isFalse);
    });

    test('Create existing docs with merge should succeed', () async {
      await collection.docs(['docA']).create((_) => docA);
      final response = await collection.docs(['docA']).create((_) => {'c': 3}, merge: true);

      expect(response, isA<SharedMany>());
      expect(response.success, isTrue);
      final stored = (await collection.docs(['docA']).read()).many;
      expect(stored, isNotNull);
      expect(stored!.first, containsPair('c', 3));
      expect(stored.first, containsPair('a', 1));
    });

    test('Read missing doc with skip false throws', () async {
      final response = await collection.docs(['docA']).read(skip: false);
      expect(response, isA<SharedNone>());
      expect(response.success, isFalse);
    });

    test('Update existing docs and force missing', () async {
      await collection.docs(['docA']).create((_) => docA);
      final response = await collection.docs(['docA', 'docB']).update((index) {
        return index == 0 ? {'a': 10} : {'b': 20};
      }, force: true);

      expect(response, isA<SharedMany>());
      expect(response.success, isTrue);
      expect((await collection.docs(['docA', 'docB']).read()).many, hasLength(2));
    });

    test('Delete existing docs', () async {
      await collection.docs(['docA', 'docB']).create((index) {
        return index == 0 ? docA : docB;
      });

      final response = await collection.docs(['docA']).delete();
      expect(response, isA<SharedNone>());
      expect(response.success, isTrue);
      final rest = (await collection.read()).data as List<JSON>?;
      expect(rest, hasLength(1));
    });

    test('Migrate many documents into one target document', () async {
      await collection.docs(['docA', 'docB']).create((index) {
        return index == 0 ? docA : docB;
      });

      final response = await collection.docs(['docA', 'docB']).migrate('target');
      expect(response, isA<SharedOne>());
      expect(response.success, isTrue);

      final target = (await collection.doc('target').read()).one;
      expect(target, isNotNull);
      expect(target, containsPair('a', 1));
      expect(target, containsPair('b', 2));

      final remaining = await collection.read();
      expect((remaining.data as List<JSON>), hasLength(1));
      expect((remaining.data as List<JSON>).first, equals(target));
    });

    test('Migrate into existing target without merge fails', () async {
      await collection.docs(['docA', 'docB']).create((index) {
        return index == 0 ? docA : docB;
      });
      await collection.doc('target').create({'existing': true});

      final response = await collection.docs(['docA']).migrate('target', merge: false);
      expect(response, isA<SharedNone>());
      expect(response.success, isFalse);
    });

    test('Migrate into existing target with merge succeeds', () async {
      await collection.docs(['docA', 'docB']).create((index) {
        return index == 0 ? docA : docB;
      });
      await collection.doc('target').create({'existing': true});

      final response = await collection.docs(['docA']).migrate('target', merge: true);
      expect(response, isA<SharedOne>());
      expect(response.success, isTrue);
      expect((await collection.doc('target').read()).one, containsPair('existing', true));
    });
  });
}
