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
      await LocalShared('test_db').initialize();
      
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

      // Act: Update the collection
      final update = await collection.update(collectionId2);
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

      test('Update Collection to Existing Collection', () async {
      // Arrange: Mock up collection
      await collection.create();
      await collection2.create();
      await document.create(data);

      // Act: Update the collection
      final update = await collection.update(collectionId2);
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

    test('Update Collection to Existing Collection Forcibly', () async {
      // Arrange: Mock up collection
      await collection.create();
      await collection2.create();
      await document.create(data);
      await document2.create(data2);

      // Act: Update the collection
      final update = await collection.update(collectionId2, merge: true);
      final response = await collection2.read();

      // Assert: Should return these values
      expect(update.success, isTrue);
      expect(update.message, contains('Successfully migrated the collection'));
      expect(response.success, isTrue);
      expect(response.data, [data.merge(data2)]);
      expect(response, isA<SharedMany>());
    });

    test('Update Non Existing Collection to Existing Collection', () async {
      // Arrange: Mock up collection
      await collection.delete();
      await collection2.create();
      await document2.create(data);

      // Act: Update the collection
      final update = await collection.update(collectionId2);
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

    
    test('Update Non Existing Collection to Existing Collection Forcibly', () async {
      // Arrange: Mock up collection
      await collection.delete();
      await collection2.create();
      await document2.create(data);

      // Act: Update the collection
      final update = await collection.update(collectionId2, merge: true, force: true);
      final response = await collection2.read();

      // Assert: Should return these values
      expect(update.success, isTrue);
      expect(update.message, contains('Successfully migrated the collection'));
      expect(response.success, isTrue);
      expect(response.data, [data]);
      expect(response, isA<SharedMany>());
    });

     test('Update Collection to the Same Collection', () async {
      // Arrange: Mock up collection
      await collection.create();
      await document.create(data);

      // Act: Update the collection
      final update = await collection.update(collectionId);
      final response = await collection.read();

      // Assert: Should return these values
      expect(update.success, isFalse);
      expect(update.message, contains('collection ID cannot be the same as the current one'));
      expect(update.data, isNull);
      expect(update, isA<SharedNone>());
      expect(response.success, isTrue);
      expect(response.data, [data]);
      expect(response, isA<SharedMany>());
    });

    test('Update Collection to the Same Collection Forcibly', () async {
      // Arrange: Mock up collection
      await collection.create();
      await document.create(data);

      // Act: Update the collection
      final update = await collection.update(collectionId, force: true);
      final response = await collection.read();

      // Assert: Should return these values
      expect(update.success, isTrue);
      expect(update.message, contains('Successfully migrated the collection'));
      expect(response.success, isTrue);
      expect(response.data, [data]);
      expect(response, isA<SharedMany>());
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