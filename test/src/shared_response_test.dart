import 'package:flutter_test/flutter_test.dart';
import 'package:local_shared/local_shared.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedResponse Test', () {
    test('SharedOne behavior and toString', () {
      const response = SharedOne(success: true, message: 'OK', data: {'key': 'value'});
      expect(response.success, isTrue);
      expect(response.message, 'OK');
      expect(response.data, {'key': 'value'});
      expect(response.one, {'key': 'value'});
      expect(response.many, isNull);
      final toString = response.toString();
      expect(toString, contains('SharedOne')); 
      expect(toString, contains('success: true'));
    });

    test('SharedMany behavior and extension', () {
      const response = SharedMany(success: true, message: 'Many', data: [{'a': 1}, {'b': 2}]);
      expect(response.success, isTrue);
      expect(response.message, 'Many');
      expect(response.data, hasLength(2));
      expect(response.many, isA<List<Map<String, dynamic>>>());
      expect(response.one, isNull);
      final toString = response.toString();
      expect(toString, contains('SharedMany'));
      expect(toString, contains('success: true'));

      expect(response.many, contains(equals({'a': 1})));
    });

    test('SharedNone behavior', () {
      const response = SharedNone(success: false, message: 'None');
      expect(response.success, isFalse);
      expect(response.message, 'None');
      expect(response.data, isNull);
      expect(response.one, isNull);
      expect(response.many, isNull);
      expect(response.toString(), contains('SharedNone'));
    });

    test('FutureSharedResponse extension one/many methods', () async {
      final one = Future.value(const SharedOne(success: true, message: 'OK', data: {'a': 123})).one();
      final many = Future.value(const SharedMany(success: true, message: 'Many', data: [{'name': 'x'}])).many();

      expect(await one, {'a': 123});
      expect(await many, isA<List<Map<String, dynamic>>>());
      expect(await many, hasLength(1));
    });

    test('SharedResponse base toString includes data only when present', () {
      const noData = SharedNone(success: true, message: 'No data');
      expect(noData.toString(), contains('success: true'));
      expect(noData.toString(), contains('message: No data'));
      expect(noData.toString(), isNot(contains('data:')));
    });
  });
}
