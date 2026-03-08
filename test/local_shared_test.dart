import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_shared/local_shared.dart';

void main() {
  // 1. Mandatory for any test using plugins (MethodChannels)
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Local Shared Test', () {
    
    setUp(() {
      // 2. Provide mock values for SharedPreferences before every test
      // This prevents the "Binding not initialized" and plugin errors
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('Local Shared Initialization', () async {
      final db = LocalShared('test_db');

      // Now this call will succeed because the binding and mocks are ready
      await db.initialize();

      expect(db, isNotNull);
    });
  });
}