part of '../main.dart';

class DocumentCRUD extends StatefulWidget {
  const DocumentCRUD({super.key});

  @override
  State<DocumentCRUD> createState() => _B();
}

class _B extends State<DocumentCRUD> {
  final collection = TextEditingController(text: 'MY_COLLECTION_123');
  final document = TextEditingController(text: 'MY_DOCUMENT_123');
  final response = TextEditingController(text: ' ');

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 227, 212, 248),
          title: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: collection,
                  decoration: const InputDecoration(
                    labelText: 'Collection ID',
                    labelStyle:
                        TextStyle(color: Color.fromARGB(200, 64, 9, 141)),
                    border: InputBorder.none,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: document,
                  decoration: const InputDecoration(
                    labelText: 'Document ID',
                    labelStyle:
                        TextStyle(color: Color.fromARGB(200, 64, 9, 141)),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: Column(children: [
          ColoredBox(
            color: const Color.fromARGB(255, 227, 212, 248),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  4,
                  (x) => TextButton.icon(
                      onPressed: () async {
                        switch (x) {
                          case 0:
                            final result = await LocalShared(collection.text)
                                .doc(document.text)
                                .create({
                              'name': 'Boi wonder',
                              'description':
                                  'Hi there 🤚, this is just a simple document',
                            });
                            response.text = '$result';
                            break;
                          case 2:
                            response.text =
                                'There is no `update` feature in collection 😐';
                            break;
                          case 3:
                            final result =
                                await LocalShared(collection.text).delete();
                            response.text = '$result';
                            break;
                        }
                      },
                      icon: Container(
                        height: kToolbarHeight,
                        alignment: Alignment.center,
                        child: Icon([
                          Icons.add,
                          Icons.remove_red_eye_sharp,
                          Icons.edit,
                          Icons.delete
                        ][x]),
                      ),
                      label: Container(
                          height: kToolbarHeight,
                          alignment: Alignment.center,
                          child: Text(
                              ['CREATE', 'READ', 'UPDATE', 'DELETE'][x])))),
            ),
          ),
          Expanded(
              child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
              controller: response,
              enabled: false,
              expands: true,
              maxLines: null,
              style: TextStyle(color: Colors.black.withOpacity(0.65)),
              decoration: const InputDecoration(
                labelText: 'Response',
                labelStyle: TextStyle(color: Colors.black),
                border: OutlineInputBorder(),
              ),
            ),
          ))
        ]),
      ),
    );
  }

  @override
  void dispose() {
    collection.dispose();
    response.dispose();
    super.dispose();
  }
}
