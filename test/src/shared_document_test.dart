import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_shared/local_shared.dart';

void main() {
  // 1. Mandatory for MethodChannels
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Shared Document Test', () {
    late SharedCollection collection;
    late SharedDocument document;
    const String collectionId = 'collection_1';
    const String documentId = 'document_1';
    const String documentId2 = 'document_2';
    const JSON data = {'key': 'value1', '1': '1'};
    const JSON data2 = {'key': 'value2', '2': '2'};

    setUp(() async {
      // 2. Initialize LocalShared
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      await const LocalShared('test_db').initialize();

      // 3. Setup the collection and document instance
      collection = Shared.collection(collectionId);
      document = collection.document(documentId);
    });

    test('Create Document', () async {
      // Arrange: Force clear the workspace
      await collection.delete();

      // Act: Create a new document (force=true by default in create)
      final response = await document.create(data);

      // Assert: Should return these values
      expect(response.success, isTrue);
      expect(response.data, data);
      expect(response, isA<SharedOne>());
      expect(response.message, contains('has been successfully created'));
    });

    test('Create Document in Non-Existing Collection (No Force)', () async {
      // Arrange: Ensure collection doesn't exist
      await collection.delete();

      // Act: Try to create document without forcing collection creation
      final response = await document.create(data, force: false);

      // Assert: Should fail
      expect(response.success, isFalse);
      expect(response, isA<SharedNone>());
      expect(response.message, contains('does not exist'));
    });

    test('Create Existing Document', () async {
      // Arrange: Mock up an existing document
      await document.create(data);

      // Act: Create a new document with the same ID
      final response = await document.create(data);

      // Assert: Should return these values
      expect(response.success, isFalse);
      expect(response, isA<SharedNone>());
      expect(response.message, contains('The document already exists'));
    });

    test('Create Existing Document Forcibly (Merge)', () async {
      // Arrange: Mock up an existing document
      await document.create(data);

      // Act: Create a new document with the same ID and merge: true
      final response = await document.create(data2, merge: true);
      
      // Assert: Should return these values
      expect(response.success, isTrue);
      expect(response.data, data.merge(data2));
      expect(response, isA<SharedOne>());
      expect(response.message, contains('has been successfully merged'));
    });

    test('Read Document', () async {
      // Arrange: Mock up document
      await document.create(data);

      // Act: Read the document
      final response = await document.read();

      // Assert: Should return these values
      expect(response.success, isTrue);
      expect(response.data, data);
      expect(response, isA<SharedOne>());
      expect(response.message, contains('has been successfully retrieved'));
    });

    test('Read Non-Existing Document', () async {
      // Arrange: Clear the collection
      await collection.create(replace: true);

      // Act: Read a document that doesn't exist
      final response = await document.read();

      // Assert: Should fail
      expect(response.success, isFalse);
      expect(response, isA<SharedNone>());
      expect(response.message, contains('does not exist'));
    });

    test('Read Document in Non-Existing Collection', () async {
      // Arrange: Delete the collection
      await collection.delete();

      // Act: Read a document when collection is gone
      final response = await document.read();

      // Assert: Should fail
      expect(response.success, isFalse);
      expect(response, isA<SharedNone>());
      expect(response.message, contains('does not exist'));
    });

    test('Update Document', () async {
      // Arrange: Mock up document
      await document.create(data);

      // Act: Update the document (merging data2)
      final response = await document.update(data2);

      // Assert: Should return merged values
      expect(response.success, isTrue);
      expect(response.data, data.merge(data2));
      expect(response, isA<SharedOne>());
      expect(response.message, contains('has been successfully updated'));
    });

    test('Update Non-Existing Document (No Force)', () async {
      // Arrange: Clear the collection
      await collection.create(replace: true);

      // Act: Update a document that doesn't exist without force
      final response = await document.update(data2, force: false);

      // Assert: Should fail
      expect(response.success, isFalse);
      expect(response, isA<SharedNone>());
      expect(response.message, contains('does not exist'));
    });

    test('Update Non-Existing Document Forcibly', () async {
      // Arrange: Clear the collection
      await collection.create(replace: true);

      // Act: Update a document that doesn't exist with force: true
      final response = await document.update(data2, force: true);

      // Assert: Should succeed and create the document
      expect(response.success, isTrue);
      expect(response.data, data2);
      expect(response, isA<SharedOne>());
      expect(response.message, contains('has been successfully updated'));
    });

    test('Migrate Document', () async {
      // Arrange: add source document
      await document.create(data);

      // Act
      final response = await document.migrate(documentId2);

      // Assert
      expect(response.success, isTrue);
      expect(response, isA<SharedOne>());
      expect(response.data, data);
      expect(response.message, contains('has been successfully migrated'));

      final readSource = await document.read();
      expect(readSource.success, isFalse);

      final readDestination = await collection.doc(documentId2).read();
      expect(readDestination.success, isTrue);
      expect(readDestination.data, data);
    });

    test('Migrate Document with Existing Target (No Merge)', () async {
      // Arrange: add source and target documents
      await document.create(data);
      await collection.doc(documentId2).create(data2);

      // Act
      final response = await document.migrate(documentId2, merge: false);

      // Assert
      expect(response.success, isFalse);
      expect(response, isA<SharedNone>());
      expect(response.message, contains('already exists'));
    });

    test('Migrate Document with Existing Target and Merge', () async {
      // Arrange: add source and target documents
      await document.create(data);
      await collection.doc(documentId2).create(data2);

      // Act
      final response = await document.migrate(documentId2, merge: true);

      // Assert
      expect(response.success, isTrue);
      expect(response, isA<SharedOne>());
      expect(response.data, data.merge(data2));

      final readSource = await document.read();
      expect(readSource.success, isFalse);

      final readDestination = await collection.doc(documentId2).read();
      expect(readDestination.success, isTrue);
      expect(readDestination.data, data.merge(data2));
    });

    test('Migrate Document to Same ID fails', () async {
      await document.create(data);

      final response = await document.migrate(documentId);

      expect(response.success, isFalse);
      expect(response, isA<SharedNone>());
      expect(response.message, contains('cannot be the same'));
    });

    test('Migrate Missing Source With Force Creates Target', () async {
      await collection.create(replace: true);

      final response = await document.migrate(documentId2, force: true);
      expect(response.success, isTrue);
      expect(response, isA<SharedOne>());
      expect(response.data, isNotNull);

      final targetRead = await collection.doc(documentId2).read();
      expect(targetRead.success, isTrue);
      expect(targetRead.data, isEmpty);
    });

    test('Migrate to Same ID with Force does nothing but succeeds', () async {
      await document.create(data);

      final response = await document.migrate(documentId, force: true);

      expect(response.success, isTrue);
      expect(response, isA<SharedOne>());
      expect(response.data, data);
    });

    test('Delete Document', () async {
      // Arrange: Mock up document
      await document.create(data);

      // Act: Delete the document
      final response = await document.delete();

      // Assert: Should return these values
      expect(response.success, isTrue);
      expect(response.message, contains('has been successfully deleted'));
      expect(response.data, isNull);
      expect(response, isA<SharedNone>());

      // Verify it's actually gone
      final readResponse = await document.read();
      expect(readResponse.success, isFalse);
    });

    test('Delete Non-Existing Document', () async {
      // Arrange: Clear the collection
      await collection.create(replace: true);

      // Act: Delete a document that doesn't exist
      final response = await document.delete();

      // Assert: Should fail
      expect(response.success, isFalse);
      expect(response, isA<SharedNone>());
      expect(response.message, contains('does not exist'));
    });
  });
}
