<p align="center">
  <img src="https://raw.githubusercontent.com/Nialixus/local_shared/main/logo.png" alt="Inidia.app Local Shared Logo" width="150">
</p>

# Type Writer Text

<a href='https://pub.dev/packages/local_shared'><img src='https://img.shields.io/pub/v/local_shared.svg?logo=flutter&color=blue&style=flat-square'/></a>\
\
A SharedPreferences-based local storage package designed as an alternative to the localstore

## Preview

![screen-capture-_1_](https://user-images.githubusercontent.com/45191605/162557654-6e98d7be-e198-4089-bc13-6b52f7e4a6e2.gif)

## Install

Add this line to your pubspec.yaml.

```yaml
dependencies:
  local_shared: ^1.0.0
```

## Initialize

Initialize the LocalShared instance in your main function after ensuring Flutter is initialized.
```dart
import 'package:local_shared/local_shared.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalShared('db').initialize();
}
```

and then later in the app access collection and document with either `LocalShared` or `Shared` prefix.
[!NOTE]
or you can made your own definition like
```dart
typedef DB = LocalShared;
```

## Collection
This guide illustrates fundamental CRUD (Create, Read, Update, Delete) operations using local_shared for collection management. Interacting with collection in local_shared can be achieved through the following methods: `Shared.col(id)` or `Shared.collection(id)`.

### Create
To initiate the creation of a new collection utilize this method:
```dart
final result = await Shared.col('myCollection').create();
print(result); // SharedMany(success: true, message: 'Collection created successfully.', data: <JSON>[])
```

### Read
To retrieve information pertaining to a collection invoke this method:
```dart
final response = await Shared.col('myCollection').read();
print(response); // SharedMany(success: true, message: '...', data: <JSON>[])
```

### Update
To migrate or change collection id implement this method:
```dart
final response = await Shared.col('myCollection').update('myNewCollection');
print(response); // SharedMany(success: true, message: '...', data: <JSON>[])
```

### Delete
To remove a collection, employ this method:
```dart
final response = await Shared.col('myCollection').delete();
print(response): // SharedNone(success: true, message: '....')
```

## Document
This guide elaborates on the essential CRUD (Create, Read, Update, Delete) operations using local_shared for document management within collections. Interacting with document in local_shared can be achieved through the following methods: `Shared.col(id).doc(id)` or `Shared.collection(id).document(id)`.

### Create
To initiate the creation of a new document, leverage this method:
```dart
final result = await Shared.col('myCollection').doc('documentId').create({'key': 'value'});
print(result); // SharedOne(success: true, message: '...', data: JSON)
```

### Read
To retrieve the contents of a document within a collection, use this method:
```dart
final response = await Shared.col('myCollection').doc('documentId').read();
print(response); // SharedOne(success: true, message: '...', data: JSON)
```

### Update
To modify the contents of a document within a collection, invoke this method:
```dart
final response = await Shared.col('myCollection').doc('documentId').update({'newKey': 'newValue'});
print(response); // SharedOne(success: true, message: '...', data: JSON)
```

### Delete
To delete a document within a collection, implement this method:
```dart
final response = await Shared.col('myCollection').doc('documentId').delete();
print(response): // SharedNone(success: true, message: '...')
```

## Many Document
This guide details the fundamental CRUD (Create, Read, Update, Delete) operations facilitated by local_shared for the management of multiple documents within collections. Interacting with many document can be achieved through the following methods: `Shared.col(id).docs([id1, id2])` or `Shared.collection(id).documents([id1, id2])`.

### Create
Initiate the creation of multiple documents with this method:
```dart
final result = await Shared.col('myCollection').docs(['docId1', 'docId2']).create((id) => {'key': 'value'});
print(result); // SharedMany(success: true, message: '...', data: <JSON>[])
```

### Read
Retrieve the contents of multiple documents within a collection using this method:
```dart
final response = await Shared.col('myCollection').docs(['docId1', 'docId2']).read();
print(response); // SharedMany(success: true, message: '...', data: <JSON>[])
```

### Update
Modify the contents of multiple documents within a collection with this method:
```dart
final response = await Shared.col('myCollection').docs(['docId1', 'docId2']).update((id) => {'newKey': 'newValue'});
print(response); // SharedMany(success: true, message: '...', data: <JSON>[])
```

### Delete
Delete multiple documents within a collection using this method;
```dart
final response = await Shared.col('myCollection').docs(['docId1', 'docId2']).delete();
print(response); // SharedNone(success: true, message: '...')
```

## Stream
LocalShared provides a JSON stream to observe changes whenever you interact with collections using the Shared.col('') syntax, which returns data for a single collection. If you engage with multiple collections, each interaction replaces the previous one.

```dart
LocalShared.stream.listen(print);

await Shared.col('myCollection').docs(['A','B']).create((id) => {'desc': 'test'});

// observed event
/*
{
id: myCollection,
documents: [
    {id: A, data: {desc: test}},
    {id: B, data: {desc: test}}
]}
*/
```

### Custom Stream
If you only want to observe changes in a specific collection, you can use the following approach:

```dart
final controller = StreamController<JSON>.broadcast();
final collection = SharedCollection('myCertainCollection', controller: controller);

controller.stream.listen(print);

await collection.docs(['A','B']).create((id) => {'desc': 'test'});

// observed event
/*
{
id: myCertainCollection,
documents: [
    {id: A, data: {desc: test}},
    {id: B, data: {desc: test}}
]}
*/
```

## Example

- <a href="https://github.com/Nialixus/typewritertext/blob/master/example/lib/main.dart">typewritertext/example/lib/main.dart</a>