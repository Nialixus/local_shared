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
  final json = TextEditingController(text: ' ');

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
                            final response = await Shared.col(collection.text)
                                .doc(document.text)
                                .create({
                              'title': 'The Art of Programming',
                              'author': 'Louis Wiwawan',
                              'published_year': 2023,
                              'is_best_seller': true,
                              'genres': ['Technology', 'Programming'],
                              'ratings': {
                                'average': 4.5,
                                'reviews': 120,
                              },
                              'prices': [100, 100.0, '\$100.0'],
                              'related_books': [
                                {
                                  'title': 'Coding Mastery',
                                  'author': 'Jane A. Smith'
                                },
                                {
                                  'title': 'Algorithms Unleashed',
                                  'author': 'Robert B. Johnson'
                                },
                              ],
                            });
                            this.response.text = '$response';
                            json.text = '${response.data}';
                            break;
                          case 1:
                            final response = await Shared.col(collection.text)
                                .doc(document.text)
                                .read();
                            this.response.text = '$response';
                            json.text = '${response.data}';
                            break;
                          case 2:
                            final response = await Shared.col(collection.text)
                                .doc(document.text)
                                .update({'updated_at': '${DateTime.now()}'});
                            this.response.text = '$response';
                            json.text = '${response.data}';
                            break;
                          case 3:
                            final response = await Shared.col(collection.text)
                                .doc(document.text)
                                .delete();
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
                        style: TextStyle(color: Colors.black.withOpacity(0.65)),
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
        ]),
      ),
    );
  }

  @override
  void dispose() {
    collection.dispose();
    document.dispose();
    response.dispose();
    json.dispose();
    super.dispose();
  }
}
