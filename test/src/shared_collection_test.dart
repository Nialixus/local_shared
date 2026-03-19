import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_shared/local_shared.dart';

void main() {
  // 1. Mandatory for MethodChannels
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Shared Collection Test', () {
    late SharedCollection collection;
    late SharedCollection collection2;
    late SharedDocument document;
    late SharedDocument document2;
    const String collectionId = 'collection_1';
    const String collectionId2 = 'collection_2';
    const String documentId = 'document_1';
    const JSON data = {'key': 'value1', '1': '1'};
    const JSON data2 = {'key': 'value2', '2': '2'};

    setUp(() async {
      // 2. Initialize LocalShared
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      await const LocalShared('test_db').initialize();

      // // 3. Setup the collection instance
      collection = Shared.collection(collectionId);
      collection2 = Shared.collection(collectionId2);
      document = collection.document(documentId);
      document2 = collection2.document(documentId);
    });

    test('Create Collection', () async {
      // Arrange: Clear the workspace
      await collection.delete();

      // Act: Create a new collection
      final response = await collection.create();

      // Assert: Should return these values
      expect(response.success, isTrue);
      expect(response.data, isEmpty);
      expect(response, isA<SharedMany>());
      expect(response.message, contains('has been successfully created'));
    });

    test('Create Existing Collection', () async {
      // Arrange: Mock up an existing collection
      await collection.create();

      // Act: Create a new collection with the same ID
      final response = await collection.create();

      // Assert: Should return these values
      expect(response.success, isFalse);
      expect(response, isA<SharedNone>());
      expect(response.message, contains('The collection already exists'));
    });

    test('Create Existing Collection Forcibly', () async {
      // Arrange: Mock up an existing collection
      await collection.create();
      await document.create(data);

      // Act: Create a new collection with the same ID
      final response = await collection.create(replace: true);

      // Assert: Should return these values
      expect(response.success, isTrue);
      expect(response.data, [data]);
      expect(response, isA<SharedMany>());
      expect(response.message, contains('has been successfully recreated'));
    });

    test('Read missing collection returns SharedNone', () async {
      await collection.delete();
      final response = await collection.read();
      expect(response, isA<SharedNone>());
      expect(response.success, isFalse);
      expect(response.message, contains('does not exist'));
    });

    test('IDs returns all saved document keys', () async {
      await collection.create();
      await document.create(data);
      await collection.document('document_2').create(data2);

      final ids = await collection.ids();
      expect(ids, containsAll([documentId, 'document_2']));
    });

    test('Update missing collection without force fails', () async {
      await collection.delete();
      final response = await collection.update({
        'document_1': {'key': 'updated'},
      });

      expect(response, isA<SharedNone>());
      expect(response.success, isFalse);
      expect(response.message, contains('does not exist'));
    });

    test('Delete missing collection returns SharedNone', () async {
      await collection.delete();
      final response = await collection.delete();
      expect(response, isA<SharedNone>());
      expect(response.success, isFalse);
      expect(response.message, contains('does not exist'));
    });

    test('Read Collection', () async {
      // Arrange: Mock up collection
      await collection.create();
      await document.create(data);

      // Act: Read the collection
      final response = await collection.read();

      // Assert: Should return these values
      expect(response.success, isTrue);
      expect(response.data, isA<List>());
      expect(response.data, [data]);
      expect(response, isA<SharedMany>());
      expect(response.message, contains('has been successfully retrieved'));
    });

    test('Update Collection', () async {
      // Arrange: Mock up collection
      await collection.create();
      await document.create(data);

      // Act: Update the collection with partial merge
      final response = await collection.update({
        'document_1': {
          'key': 'updated',
          'newField': 'yes',
        }
      });

      // Assert: Should return these values
      expect(response.success, isTrue);
      expect(response.data, isA<List>());
      expect(response.data, contains(equals({'key': 'updated', 'newField': 'yes', '1': '1'})));
      expect(response, isA<SharedMany>());
      expect(response.message, contains('has been successfully updated'));
    });

    test('Update Missing Collection Forcibly', () async {
      // Arrange: Ensure collection does not exist
      await collection.delete();

      // Act
      final response = await collection.update({
        'someDoc': {'value': 1}
      }, force: true);

      // Assert
      expect(response.success, isTrue);
      expect(response.data, isA<List>());
      expect(response.data, contains(equals({'value': 1})));
      expect(response, isA<SharedMany>());
      expect(response.message, contains('has been successfully updated'));
    });

    test('Migrate Collection', () async {
      // Arrange: Mock up collection
      await collection.create();
      await document.create(data);

      // Act: Migrate the collection
      final update = await collection.migrate(collectionId2);
      final response = await collection2.read();

      // Assert: Should return these values
      expect(update.success, isTrue);
      expect(update.message, contains('Successfully migrated the collection'));
      expect(response.success, isTrue);
      expect(response.data, isA<List>());
      expect(response.data, [data]);
      expect(response, isA<SharedMany>());

      final oldResponse = await collection.read();
      expect(oldResponse.success, isFalse);
      expect(oldResponse.data, isNull);
      expect(oldResponse, isA<SharedNone>());
      expect(oldResponse.message, contains('does not exist'));
    });

    test('Migrate Collection to Existing Collection', () async {
      // Arrange: Mock up collection
      await collection.create();
      await collection2.create();
      await document.create(data);

      // Act: Migrate the collection
      final update = await collection.migrate(collectionId2);
      final response = await collection2.read();

      // Assert: Should return these values
      expect(update.success, isFalse);
      expect(update.data, isNull);
      expect(update, isA<SharedNone>());
      expect(update.message, contains('is already exist'));
      expect(response.success, isTrue);
      expect(response.data, isEmpty);
      expect(response, isA<SharedMany>());
    });

    test('Migrate Collection to Existing Collection Forcibly', () async {
      // Arrange: Mock up collection
      await collection.create();
      await collection2.create();
      await document.create(data);
      await document2.create(data2);

      // Act: Migrate the collection
      final update = await collection.migrate(collectionId2, merge: true);
      final response = await collection2.read();

      // Assert: Should return these values
      expect(update.success, isTrue);
      expect(update.message, contains('Successfully migrated the collection'));
      expect(response.success, isTrue);
      expect(response.data, [data.merge(data2)]);
      expect(response, isA<SharedMany>());
    });

    test('Migrate Non Existing Collection to Existing Collection', () async {
      // Arrange: Mock up collection
      await collection.delete();
      await collection2.create();
      await document2.create(data);

      // Act: Migrate the collection
      final update = await collection.migrate(collectionId2);
      final response = await collection2.read();

      // Assert: Should return these values
      expect(update.success, isFalse);
      expect(update.message, contains('Unable to migrate the collection'));
      expect(update, isA<SharedNone>());
      expect(update.data, isNull);
      expect(response.success, isTrue);
      expect(response.data, [data]);
      expect(response, isA<SharedMany>());
    });

    test('Migrate Non Existing Collection to Existing Collection Forcibly',
        () async {
      // Arrange: Mock up collection
      await collection.delete();
      await collection2.create();
      await document2.create(data);

      // Act: Migrate the collection
      final update =
          await collection.migrate(collectionId2, merge: true, force: true);
      final response = await collection2.read();

      // Assert: Should return these values
      expect(update.success, isTrue);
      expect(update.message, contains('Successfully migrated the collection'));
      expect(response.success, isTrue);
      expect(response.data, [data]);
      expect(response, isA<SharedMany>());
    });

    test('Migrate Collection to the Same Collection', () async {
      // Arrange: Mock up collection
      await collection.create();
      await document.create(data);

      // Act: Update the collection
      final update = await collection.migrate(collectionId);
      final response = await collection.read();

      // Assert: Should return these values
      expect(update.success, isFalse);
      expect(update.message,
          contains('collection ID cannot be the same as the current one'));
      expect(update.data, isNull);
      expect(update, isA<SharedNone>());
      expect(response.success, isTrue);
      expect(response.data, [data]);
      expect(response, isA<SharedMany>());
    });

    test('Migrate Collection to the Same Collection Forcibly', () async {
      // Arrange: Mock up collection
      await collection.create();
      await document.create(data);

      // Act: Update the collection
      final update = await collection.migrate(collectionId, force: true);
      final response = await collection.read();

      // Assert: Should return these values
      expect(update.success, isTrue);
      expect(update.message, contains('Successfully migrated the collection'));
      expect(response.success, isTrue);
      expect(response.data, [data]);
      expect(response, isA<SharedMany>());
    });

    test('Migrate Documents from Collection Using SharedManyDocument', () async {
      // Arrange: Setup source collection and documents
      await collection.create();
      await document.create(data);
      await collection.document('document_2').create({'x': 'y'});

      // Act: Migrate specific documents from source into a single target document
      final response = await collection.docs([documentId, 'document_2']).migrate('merged_document');
      final targetRead = await collection.doc('merged_document').read();
      final sourceRead = await collection.read();

      // Assert: Should return these values
      expect(response.success, isTrue);
      expect(response, isA<SharedOne>());
      expect(targetRead.success, isTrue);
      expect(targetRead.one, containsPair('key', 'value1'));
      expect(targetRead.one, containsPair('x', 'y'));
      expect(sourceRead.success, isTrue);
      expect(sourceRead.data, isA<List<JSON>>());
      expect(sourceRead.data, contains(equals({'x': 'y', 'key': 'value1', '1': '1'}))); // merged doc should be new target not in source list
    });

    test('Migrate Documents to Target With Merge', () async {
      // Arrange: Setup source collection and existing target document
      await collection.create();
      await document.create(data);
      await collection.doc('merged_document').create({'1': '2'});

      // Act: Migrate with merge true into the existing target document
      final response = await collection.docs([documentId]).migrate('merged_document', merge: true);
      final targetRead = await collection.doc('merged_document').read();

      // Assert: Should merge existing target document
      expect(response.success, isTrue);
      expect(targetRead.success, isTrue);
      expect(targetRead.one, containsPair('key', 'value1'));
      expect(targetRead.one, containsPair('1', '1')); // existing value preserved by target precedence
    });

    test('Delete Collection', () async {
      // Arrange: Mock up collection
      await collection.create();
      await document.create(data);

      // Act: Delete the collection
      final response = await collection.delete();

      // Assert: Should return these values
      expect(response.success, isTrue);
      expect(response.message, contains('has been successfully deleted'));
      expect(response.data, isNull);
      expect(response, isA<SharedNone>());
    });
  });
}
