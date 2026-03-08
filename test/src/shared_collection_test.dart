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
    const String collectionId = 'collection_1';
    const String collectionId2 = 'collection_2';
    const String documentId = 'document_1';
    const JSON data = {'key': 'value'};

    setUp(() async {
      // 2. Initialize LocalShared
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      await LocalShared('test_db').initialize();
      
      // // 3. Setup the collection instance
      collection = Shared.collection(collectionId);
      collection2 = Shared.collection(collectionId2);
      document = collection.document(documentId);
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

    test('Update Collection to Different ID', () async {
      // Arrange: Mock up collection
      await collection.create();
      await document.create(data);

      // Act: Read the collection
      final response = await collection.update(collectionId2);

      // Assert: Should return these values
      expect(response.success, isTrue);
      expect(response.data, isA<List>());
      expect(response.data, [data]);
      expect(response, isA<SharedMany>());
      expect(response.message, contains('Successfully migrated the collection'));

      final oldResponse = await collection.read();
      expect(oldResponse.success, isFalse);
      expect(oldResponse.data, isNull);
      expect(oldResponse, isA<SharedNone>());
      expect(oldResponse.message, contains('does not exist'));
    });

      test('Update Collection to Existing Different ID', () async {
      // Arrange: Mock up collection
      await collection.create();
      await collection2.create();
      await document.create(data);

      // Act: Read the collection
      final response = await collection.update(collectionId2);
      print(response);

      // Assert: Should return these values
      expect(response.success, isFalse);
      expect(response.data, isNull);
      expect(response, isA<SharedNone>());
      expect(response.message, contains('is already exist'));
    });

    test('Update Collection to Existing Different ID Forcibly', () async {
      // Arrange: Mock up collection
      await collection.create();
      await collection2.create();
      await document.create(data);

      // Act: Read the collection
      final response = await collection.update(collectionId2);
      print(response);

      // Assert: Should return these values
      expect(response.success, isFalse);
      expect(response.data, isNull);
      expect(response, isA<SharedNone>());
      expect(response.message, contains('is already exist'));
    });

     test('Update Collection to Same ID', () async {
      // Arrange: Mock up collection
      await collection.create();
      await document.create(data);

      // Act: Read the collection
      final response = await collection.update(collectionId);

      // Assert: Should return these values
      expect(response.success, isFalse);
      expect(response.data, isNull);
      expect(response, isA<SharedNone>());
      expect(response.message, contains('collection ID cannot be the same as the current one'));
    });

   

  //   test('Shared Collection Migration (Update)', () async {
  //     // Arrange: Create initial collection
  //     await collection.create();
  //     const String newCollectionId = 'archived_users';

  //     // Act: Migrate to a new ID
  //     final response = await collection.update(newCollectionId);

  //     // Assert
  //     expect(response.success, isTrue);
  //     expect(response.message, contains('Successfully migrated'));
      
  //     // Verify old one is gone and new one exists via a read attempt
  //     final oldRead = await collection.read(); // Should fail
  //     expect(oldRead.success, isFalse);
  //   });

  //   test('Shared Collection Deletion', () async {
  //     // Arrange
  //     await collection.create();

  //     // Act
  //     final response = await collection.delete();

  //     // Assert
  //     expect(response.success, isTrue);
  //     expect(response.message, contains('successfully deleted'));
  //   });

  //   test('Shared Collection Shortcut Factory', () async {
  //     // This tests the .doc() and .docs() methods
  //     final singleDoc = collection.doc('user_1');
  //     final multiDocs = collection.docs(['user_1', 'user_2']);

  //     expect(singleDoc, isA<SharedDocument>());
  //     expect(multiDocs, isA<SharedManyDocument>());
  //     expect(singleDoc.id, equals('user_1'));
  //   });

  //   test('Shared Collection Stream Notification', () async {
  //     // Arrange: Listen to the controller
  //     bool wasNotified = false;
  //     controller.stream.listen((data) {
  //       if (data['id'] == collectionId) {
  //         wasNotified = true;
  //       }
  //     });

  //     // Act
  //     await collection.create();

  //     // Assert: Wait a moment for stream microtask
  //     await Future.delayed(Duration.zero);
  //     expect(wasNotified, isTrue);
  //   });
  });
}