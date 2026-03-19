import 'package:flutter_test/flutter_test.dart';
import 'package:local_shared/local_shared.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedExtension Test', () {
    test('JSON merge should preserve existing target values and merge nested maps', () {
      final source = <String, dynamic>{
        'name': 'source',
        'meta': {'a': 1, 'b': 2},
        'field': 's',
      };
      final target = <String, dynamic>{
        'name': 'target',
        'meta': {'b': 20, 'c': 3},
        'other': true,
      };

      final merged = source.merge(target);

      expect(merged['name'], 'target');
      expect(merged['field'], 's');
      expect(merged['other'], true);
      expect(merged['meta'], isA<Map>());
      expect((merged['meta'] as Map)['a'], 1);
      expect((merged['meta'] as Map)['b'], 20);
      expect((merged['meta'] as Map)['c'], 3);
    });

    test('SharedResponse extension one/many with SharedOne and SharedMany', () {
      const one = SharedOne(success: true, message: 'ok', data: {'k': 1});
      const many = SharedMany(success: true, message: 'ok', data: [{'k': 1}]);

      expect(one.one, {'k': 1});
      expect(one.many, isNull);
      expect(many.one, isNull);
      expect(many.many, isA<List<Map<String, dynamic>>>());
    });

    test('FutureSharedResponse extension handles SharedFuture correctly', () async {
      final futureOne = Future.value(const SharedOne(success: true, message: 'ok', data: {'foo': 'bar'}));
      final futureMany = Future.value(const SharedMany(success: true, message: 'ok', data: [{'foo': 'bar'}]));

      expect(await futureOne.one(), {'foo': 'bar'});
      expect(await futureOne.many(), isNull);
      expect(await futureMany.one(), isNull);
      expect(await futureMany.many(), isA<List<Map<String, dynamic>>>());
    });
  });
}
