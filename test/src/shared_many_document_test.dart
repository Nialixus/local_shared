import 'dart:convert';
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
      await const LocalShared('test_db').initialize();
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

      final response =
          await collection.docs(['docA']).create((_) => {'a': 9}, merge: false);
      expect(response, isA<SharedNone>());
      expect(response.success, isFalse);
    });

    test('Create new docs without collection and force false fails', () async {
      await collection.delete();
      final response = await collection.docs(['docA', 'docB']).create(
          (index) => index == 0 ? docA : docB,
          force: false);

      expect(response, isA<SharedNone>());
      expect(response.success, isFalse);
      expect(response.message, contains('does not exist'));
    });

    test('Create existing docs with merge should succeed', () async {
      await collection.docs(['docA']).create((_) => docA);
      final response =
          await collection.docs(['docA']).create((_) => {'c': 3}, merge: true);

      expect(response, isA<SharedMany>());
      expect(response.success, isTrue);
      final stored = (await collection.docs(['docA']).read()).many;
      expect(stored, isNotNull);
      expect(stored!.first, containsPair('c', 3));
      expect(stored.first, containsPair('a', 1));
    });

    test('Update missing documents without force fails', () async {
      await collection.docs(['docA']).create((_) => docA);

      final response = await collection.docs(['docA', 'docB']).update(
          (index) => index == 0 ? {'a': 10} : {'b': 20},
          force: false);

      expect(response, isA<SharedNone>());
      expect(response.success, isFalse);
      expect(response.message, contains('does not exist'));
    });

    test('Delete missing documents without skip fails', () async {
      await collection.docs(['docA']).create((_) => docA);

      final response =
          await collection.docs(['docA', 'docB']).delete(skip: false);

      expect(response, isA<SharedNone>());
      expect(response.success, isFalse);
      expect(response.message, contains('does not exist'));
    });

    test('Delete documents when collection is missing fails', () async {
      await collection.delete();

      final response = await collection.docs(['docA', 'docB']).delete();

      expect(response, isA<SharedNone>());
      expect(response.success, isFalse);
      expect(response.message, contains('does not exist'));
    });

    test('Read missing docs with default skip returns no results message',
        () async {
      // Ensure the collection exists first by creating a different document
      await collection.doc('dummy').create({'foo': 'bar'});

      final response = await collection.docs(['docA']).read();

      expect(response, isA<SharedMany>());
      expect(response.success, isFalse);
      expect(response.message, contains("There's no single document"));
      expect(response.data, isEmpty);
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
      expect(
          (await collection.docs(['docA', 'docB']).read()).many, hasLength(2));
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

    test('Delete docs not found returns no single document message', () async {
      await collection.docs(['docA', 'docB']).create((index) {
        return index == 0 ? docA : docB;
      });

      final response = await collection.docs(['docC']).delete();
      expect(response, isA<SharedNone>());
      expect(response.success, isFalse);
      expect(response.message,
          contains("There's no single document with ID `docC` found"));
    });

    test('Migrate many documents into one target document', () async {
      await collection.docs(['docA', 'docB']).create((index) {
        return index == 0 ? docA : docB;
      });

      final response =
          await collection.docs(['docA', 'docB']).migrate('target');
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

      final response =
          await collection.docs(['docA']).migrate('target', merge: false);
      expect(response, isA<SharedNone>());
      expect(response.success, isFalse);
    });

    test('Migrate into existing target with merge succeeds', () async {
      await collection.docs(['docA', 'docB']).create((index) {
        return index == 0 ? docA : docB;
      });
      await collection.doc('target').create({'existing': true});

      final response =
          await collection.docs(['docA']).migrate('target', merge: true);
      expect(response, isA<SharedOne>());
      expect(response.success, isTrue);
      expect((await collection.doc('target').read()).one,
          containsPair('existing', true));
    });

    test('Migrate fails when source collection is empty and force is false',
        () async {
      await collection.delete();
      final response =
          await collection.docs(['docA']).migrate('target', force: false);
      expect(response, isA<SharedNone>());
      expect(response.success, isFalse);
      expect(response.message, contains('does not exist'));
    });

    test('Migrate fails when target ID is in source IDs and force is false',
        () async {
      await collection.docs(['docA']).create((_) => docA);
      final response = await collection
          .docs(['docA', 'target']).migrate('target', force: false);
      expect(response, isA<SharedNone>());
      expect(response.success, isFalse);
      expect(response.message,
          contains('Source and destination document IDs cannot be the same'));
    });

    test(
        'Migrate fails if target document exists and neither merge nor force is true',
        () async {
      await collection.docs(['docA']).create((_) => docA);
      await collection.doc('target').create({'existing': true});
      final response = await collection
          .docs(['docA']).migrate('target', merge: false, force: false);
      expect(response, isA<SharedNone>());
      expect(response.success, isFalse);
      expect(response.message, contains('already exists'));
    });

    test(
        'Migrate fails if a requested source document is missing and force is false',
        () async {
      await collection.docs(['docA']).create((_) => docA);
      final response = await collection
          .docs(['docA', 'docB']).migrate('target', force: false);
      expect(response, isA<SharedNone>());
      expect(response.success, isFalse);
      expect(response.message,
          contains('Source document with ID `docB` does not exist'));
    });

    test(
        'Migrate fails if no source documents are found and target doesn\'t exist, unless force is true',
        () async {
      final response =
          await collection.docs(['docB']).migrate('target', force: true);
      expect(response, isA<SharedOne>());
      expect(response.success, isTrue);

      final response2 =
          await collection.docs(['docB']).migrate('target2', force: false);
      expect(response2, isA<SharedNone>());
      expect(response2.success, isFalse);
      expect(response2.message, contains('does not exist'));
    });

    test('Migrate fails if a source document has invalid type', () async {
      await collection.docs(['docA']).create((_) => docA);
      // Inject invalid data directly into storage
      await LocalShared.storage.write(
        key: collectionId,
        value: jsonEncode({
          'docA': ['not', 'a', 'map'],
          'other': {}
        }),
      );

      final response = await collection.docs(['docA']).migrate('target');
      expect(response, isA<SharedNone>());
      expect(response.success, isFalse);
      expect(response.message, contains('has invalid type'));
    });

    test('Migrate with no data and missing target fails without force',
        () async {
      // Ensure the collection exists first
      await collection.doc('dummy').create({'foo': 'bar'});

      final emptyIdsCollection = SharedManyDocument([], collection: collection);
      final response = await emptyIdsCollection.migrate('target', force: false);
      expect(response, isA<SharedNone>());
      expect(response.success, isFalse);
      expect(response.message,
          contains('No source documents were available for migration'));
    });

    test('toString returns expected format', () {
      final many = collection.docs(['docA', 'docB']);
      expect(
          many.toString(),
          contains(
              'SharedManyDocument(ids: [docA, docB], collection: $collection)'));
    });
  });
}
