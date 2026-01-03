part of '../main.dart';

class ManyDocumentCRUD extends StatefulWidget {
  const ManyDocumentCRUD({super.key});

  @override
  State<ManyDocumentCRUD> createState() => _C();
}

class _C extends State<ManyDocumentCRUD> {
  final collection = TextEditingController(text: 'MY_COLLECTION_123');
  final documents = TextEditingController(text: 'MY_DOCUMENT_123, A, b, 3');
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
                  controller: documents,
                  decoration: const InputDecoration(
                    labelText: 'Document IDs',
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
                        final ids = documents.text
                            .split(',')
                            .map((e) => e.trim())
                            .toList();

                        switch (x) {
                          case 0:
                            final response = await Shared.col(collection.text)
                                .docs(ids)
                                .create((id) => {
                                      'book_id': id,
                                      'author': 'Louis Wiwawan',
                                      'published_year': Random().nextInt(1000),
                                      'genres': [
                                        'Technology',
                                        'Programming'
                                      ][Random().nextInt(2)],
                                    });
                            this.response.text = '$response';
                            json.text = '${response.data}';
                            break;
                          case 1:
                            final response = await Shared.col(collection.text)
                                .docs(ids)
                                .read();
                            this.response.text = '$response';
                            json.text = '${response.data}';
                            break;
                          case 2:
                            final response = await Shared.col(collection.text)
                                .docs(ids)
                                .update((id) => {
                                      'updated_at': DateTime.now().toString(),
                                    });
                            this.response.text = '$response';
                            json.text = '${response.data}';
                            break;
                          case 3:
                            final response = await Shared.col(collection.text)
                                .docs(ids)
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
                        style: TextStyle(color: Colors.black.withValues(alpha:  0.65)),
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
    documents.dispose();
    response.dispose();
    json.dispose();
    super.dispose();
  }
}
