part of '../main.dart';

class CollectionCRUD extends StatefulWidget {
  const CollectionCRUD({super.key});

  @override
  State<CollectionCRUD> createState() => _A();
}

class _A extends State<CollectionCRUD> {
  final collection = TextEditingController(text: 'MY_COLLECTION_123');
  final response = TextEditingController(text: ' ');

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 227, 212, 248),
          title: TextField(
            controller: collection,
            decoration: const InputDecoration(
              labelText: 'Collection ID',
              labelStyle: TextStyle(color: Color.fromARGB(200, 64, 9, 141)),
              border: InputBorder.none,
            ),
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
                            final result =
                                await LocalShared(collection.text).create();
                            response.text = '$result';
                            break;
                          case 1:
                            final result =
                                await LocalShared(collection.text).read();
                            response.text = '$result';
                          case 2:
                            String id =
                                'MY_COLLECTION_${Random().nextInt(1000).toString().padLeft(3, '0')}';
                            final result =
                                await LocalShared(collection.text).update(id);
                            response.text = '$result';
                            collection.text = id;
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
