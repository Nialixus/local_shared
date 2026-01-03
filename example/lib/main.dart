import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_shared/local_shared.dart';

part 'src/collection_crud.dart';
part 'src/document_crud.dart';
part 'src/many_document_crud.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalShared('MY_DB').initialize();

  // ignore: avoid_print
  if (kDebugMode) LocalShared.stream.listen(print);

  runApp(const MaterialApp(
    title: 'Local Shared CRUD',
    home: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Scaffold(
        body: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Expanded(
              child: Center(
                child: Text(
                  'CRUD EXAMPLE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            for (int x = 0; x < 3; x++)
              Container(
                padding: const EdgeInsets.only(bottom: 20.0),
                alignment: Alignment.center,
                child: TextButton.icon(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const [
                                CollectionCRUD(),
                                DocumentCRUD(),
                                ManyDocumentCRUD()
                              ][x])),
                  style: const ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.black),
                  ),
                  icon: Icon(
                    [
                      Icons.folder,
                      Icons.book,
                      Icons.collections_bookmark_rounded
                    ][x],
                    color: Colors.white,
                  ),
                  label: SizedBox(
                    width: 150.0,
                    child: Text(
                      ['Collection', 'Document', 'Many Document'][x],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
