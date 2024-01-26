part of '../main.dart';

class CollectionCRUD extends StatefulWidget {
  const CollectionCRUD({super.key});

  @override
  State<CollectionCRUD> createState() => _A();
}

class _A extends State<CollectionCRUD> {
  final collection = TextEditingController(text: 'MY_COLLECTION_123');
  final response = TextEditingController(text: ' ');
  final json = TextEditingController(text: ' ');

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
        body: Column(
          children: [
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
                              final response =
                                  await Shared.col(collection.text).create();
                              this.response.text = '$response';
                              json.text = '${response.data}';
                              break;
                            case 1:
                              final response =
                                  await Shared.col(collection.text).read();
                              this.response.text = '$response';
                              json.text = '${response.data}';
                              break;
                            case 2:
                              String id =
                                  'MY_COLLECTION_${Random().nextInt(1000).toString().padLeft(3, '0')}';
                              final response =
                                  await Shared.col(collection.text).update(id);
                              this.response.text = '$response';
                              json.text = '${response.data}';
                              collection.text = id;
                              break;
                            case 3:
                              final response =
                                  await Shared.col(collection.text).delete();
                              this.response.text = '$response';
                              json.text = '${response.data}';
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < 2; i++)
                      Expanded(
                        child: TextField(
                          controller: [response, json][i],
                          enabled: false,
                          expands: true,
                          maxLines: null,
                          style:
                              TextStyle(color: Colors.black.withOpacity(0.65)),
                          decoration: InputDecoration(
                            labelText: ['Response', 'JSON'][i],
                            labelStyle: const TextStyle(color: Colors.black),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                  ]..insert(1, const SizedBox(width: 20.0)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    collection.dispose();
    response.dispose();
    json.dispose();
    super.dispose();
  }
}
