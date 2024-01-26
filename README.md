<p align="center">
  <img src="https://raw.githubusercontent.com/Nialixus/local_shared/main/logo.png" alt="Inidia.app Local Shared Logo" width="150">
</p>

# Local Shared

<a href='https://pub.dev/packages/local_shared'><img src='https://img.shields.io/pub/v/local_shared.svg?logo=flutter&color=blue&style=flat-square'/></a>\
\
SharedPreferences-based local storage, designed as a multi-platform alternative to the localstore package

## Preview

![screen-capture-_1_](https://user-images.githubusercontent.com/45191605/162557654-6e98d7be-e198-4089-bc13-6b52f7e4a6e2.gif)

## Install

Add this line to your pubspec.yaml.

```yaml
dependencies:
  local_shared: ^1.0.0
```

## Initialize

Start by initializing the LocalShared instance in your main function, ensuring Flutter is properly initialized.
```dart
import 'package:local_shared/local_shared.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalShared('db').initialize();
}
```

and next, interact with collections and documents using either the `LocalShared` or `Shared` prefix. 
You can even create a custom definition for added convenience.
```dart
typedef DB = LocalShared;
```

## Collection | [View Code](https://github.com/Nialixus/local_shared/blob/main/example/lib/src/collection_crud.dart)
[Collection CRUD Preview](https://github.com/Nialixus/local_shared/assets/45191605/cadda35c-32c8-4c60-9848-a2099e2377f3)

This guide illustrates fundamental CRUD (Create, Read, Update, Delete) operations for collection management. Interacting with it can be achieved through the following methods: `Shared.col(id)` or `Shared.collection(id)`.

### Create
To initiate the creation of a new collection utilize this method:
```dart
final result = await Shared.col('myCollection').create();
print(result); // SharedMany(success: true, message: '...', data: <JSON>[])
```

### Read
To retrieve information pertaining to a collection, invoke this method:
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
final response = await Shared.col('myNewCollection').delete();
print(response): // SharedNone(success: true, message: '....')
```

## Document | [View Code](https://github.com/Nialixus/local_shared/blob/main/example/lib/src/document_crud.dart)
[Document CRUD Preview](https://github.com/Nialixus/local_shared/assets/45191605/e8848c32-b9c2-4406-a0d4-ae8b0caad64f)

This guide elaborates on the essential CRUD (Create, Read, Update, Delete) operations for document management within collections. Interacting with document can be achieved through the following methods: `Shared.col(id).doc(id)` or `Shared.collection(id).document(id)`.

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

## Many Document | [View Code](https://github.com/Nialixus/local_shared/blob/main/example/lib/src/many_document_crud.dart)
[Many Document CRUD Preview](https://github.com/Nialixus/local_shared/assets/45191605/8cb30d72-ec7e-4b4c-8516-c4f12702e879)

This guide details the fundamental CRUD (Create, Read, Update, Delete) operations for the management of multiple documents within collections. Interacting with this can be achieved through the following methods: `Shared.col(id).docs([id1, id2])` or `Shared.collection(id).documents([id1, id2])`.

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
`LocalShared` offers a JSON stream for observing changes in collections when using the Shared.col(id) syntax. If you interact with multiple collections, the stream exclusively displays data from the latest collection you engage with.

```dart
LocalShared.stream.listen(print);

await Shared.col('myCollection').docs(['A','B']).create((id) => {'desc': 'test'});
```
Result:
> {id: myCollection,
> documents: [
>     {id: A, data: {desc: test}},
>     {id: B, data: {desc: test}}
> ]}

### Custom Stream
If you only want to observe changes in a specific collection, you can use the following approach:

```dart
final controller = StreamController<JSON>.broadcast();
final collection = SharedCollection('myCertainCollection', controller: controller);

controller.stream.listen(print);

await collection.docs(['A','B']).create((id) => {'desc': 'test'});
```
Result:

> {id: myCertainCollection,
> documents: [
>     {id: A, data: {desc: test}},
>     {id: B, data: {desc: test}}
> ]}

## Extension
To simplify matters, there's an extension to handle response data from SharedResponse. 
If you're expecting SharedResponse to return `JSON?`, call this method:
```dart
JSON? result = await Shared.col(id).doc(id).read().one;
```

Alternatively, if you're expecting SharedResponse to return a `List<JSON>?`, call this method:
```dart
List<JSON>? result = await Shared.col(id).read().many;
```

## Example
- <a href="https://github.com/Nialixus/local_shared/blob/main/example/lib/main.dart">local_shared/example/lib/main.dart</a>
