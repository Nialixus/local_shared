library local_shared;

import 'dart:convert';

import 'package:local_shared/src/shared_extension.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'src/collection_model.dart';
part 'src/document_model.dart';
part 'src/shared_model.dart';

typedef JSON = Map<String, dynamic>;
typedef LocalShared = SharedCollection;


// class LocalShared {
//   const LocalShared(this.id) : assert(id.length != 0, 'id shouldn\'t be empty');

//   /// Id of this collection.
//   final String id;



//   Future<SharedModel> create({
//     bool replace = false,
//   }) async {
//     // [1] Load the box 📦.
//     SharedPreferences databox = await SharedPreferences.getInstance();

//     try {
//       // // [2] Load collection 🥩.
//       // JSON? collection = databox.getString(this.id)?.decode;
//       // bool isCollectionExist = collection != null;
//       // bool isTargetingDocument = id != null;
//       // bool isDocumentExist = isCollectionExist &&
//       //     isTargetingDocument &&
//       //     collection.containsKey(id);

//       switch (id != null) {
//         // Is Targeting Document
//         case true:
//           if (document.isEmpty) {
//             throw 'If id is provided, the document should not be empty';
//           }
//           break;
//         // Is Targeting Collection
//         case false:
//           if (document.isNotEmpty) {
//             throw 'If id is not provided, the document should be empty';
//           }
//           break;
//       }
//     } catch (e) {
//       return SharedNone(message: '$e');
//     }

//     //   switch (isCollectionExist) {
//     //     case true:
//     //     case false:
//     //   }

//     //   if (isCollectionExist) {
//     //     if (isTargetingDocument) {
//     //       if (isDocumentExist) {
//     //         if (replace) {
//     //           bool result = await databox.setString(
//     //             this.id,
//     //             (collection..addAll({id: document})).encode,
//     //           );

//     //           return SharedOne(
//     //             success: result,
//     //             message: result
//     //                 ? 'Successfully replacing document'
//     //                 : 'Failed to replace the document.',
//     //             data: databox.getString(this.id)?.decode[id],
//     //           );
//     //         }

//     //         throw 'The document has already been exist, set the parameter `replace` to true '
//     //             'If you want to completely recreate a new document with this `$id` as its document id';
//     //       }

//     //       bool result = await databox.setString(
//     //         this.id,
//     //         (collection..addAll({id: document})).encode,
//     //       );

//     //       return SharedOne(
//     //         success: result,
//     //         message: result
//     //             ? 'Successfully creating document'
//     //             : 'Failed to create the document.',
//     //         data: databox.getString(this.id)?.decode[id],
//     //       );
//     //     }

//     //     if (replace) {
//     //       bool result = await databox.setString(
//     //         this.id,
//     //         jsonEncode(document),
//     //       );

//     //       return SharedNone(
//     //         success: result,
//     //         message: result
//     //             ? 'Successfully replacing the collection'
//     //             : 'Failed to replace the collection.',
//     //       );
//     //     }

//     //     throw 'The collection has already been exist, set the parameter `replace` to true '
//     //         'If you want to completely recreate a new empty collection with this `${this.id}` as its collection id';
//     //   }

//     //   bool result = await databox.setString(
//     //     this.id,
//     //     jsonEncode(document),
//     //   );

//     //   return SharedNone(
//     //     success: result,
//     //     message: result
//     //         ? 'Successfully creating the collection'
//     //         : 'Failed to create the collection.',
//     //   );
//     // } catch (e) {
//     //   return SharedNone(message: e.toString());
//     // }
//   }

//   Future<SharedModel> delete() async {
//     // [1] Load the box 📦.
//     SharedPreferences databox = await SharedPreferences.getInstance();
//     bool result = await databox.remove(id);
//     return SharedNone(
//       success: result,
//       message: result
//           ? 'Successfully deleting a collection'
//           : 'Failed to delete the collection.',
//     );
//   }
// }
