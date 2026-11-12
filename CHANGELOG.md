## 3.2.0

### Security Hardening

- **Android Keystore resilience (`resetOnError: true`)**: Added `resetOnError: true` to `AndroidOptions`. When the Android Keystore key is invalidated (user removes/changes screen lock, app restore across devices, OS update, re-install with different signing key), the corrupted ciphertext is wiped automatically and a fresh key is generated — preventing `BadPaddingException` / `ServiceSpecificException` crashes.
- **Apple Keychain accessibility (iOS & macOS)**: Added `IOSOptions` and `MacOsOptions` with `KeychainAccessibility.first_unlock_this_device`. Data is accessible only after the device has been unlocked at least once since boot, preventing reads while the device is fully locked (protects against cold-boot attacks) and keeping access consistent across Apple platforms.
- **Resilient `_create` with auto-wipe retry**: If `FlutterSecureStorage.write()` throws (e.g. the Keystore key went away between operations), the entire secure storage is wiped and the write is retried once with a freshly generated key. If the retry also fails, `false` is returned gracefully — no crash.
- **Resilient `_read` with wipe-on-corrupt**: If `FlutterSecureStorage.read()` throws a decryption exception, corrupted storage is wiped and `null` is returned — callers treat this identically to a missing key (clean degradation, no crash).
- **Corrupted data parsing guard**: `decode` safely parses JSON from storage and returns `null` on corrupted or partially written strings rather than allowing an unhandled `FormatException` to bubble up.
- **Top-level collection value type checking**: `encode` gracefully handles top-level Map, List, and primitive entries without throwing `TypeError`.
- **Closed stream resilience**: All mutation events check `_controller.isClosed` before emitting, preventing `StateError` if CRUD operations run after `LocalShared.close()`.
- **Atomic migration flag safety**: `_migrateAll()` only sets the migration completion flag if all keys were migrated without Keystore-level write failures, ensuring any interrupted migration will be safely retried.
- **Storage wipe stream signal**: When an emergency wipe occurs, a sentinel event (`{'__event__': 'storage_wiped'}`) is emitted on `LocalShared.stream` for app-level handlers.
- **Safe `initialize()` re-invocation**: Wrapped `SharedPreferences.setPrefix()` in a `StateError` guard so calling `initialize()` multiple times in the same app session (or after another package has already called `SharedPreferences.getInstance()`) never throws `Bad state: setPrefix cannot be called after getInstance`.
- **Safe non-String `SharedPreferences` handling in migration**: Replaced `preferences.getString(key)` with untyped `preferences.get(key)` + `is! String` / `is! JSON` checks in `_migrateAll()` and `_read()`, preventing `TypeError` startup crashes when apps store `int`, `bool`, `double`, or `List<String>` entries in `SharedPreferences`.
- **Encode before Keystore retry in `_create()`**: JSON validation/encoding now runs before the Keystore retry `try` block, ensuring invalid Dart types (`ArgumentError`) return `SharedNone` cleanly without triggering `_wipeStorage()` on existing secure data.
- **Resilient `_delete` with no-op on key-gone**: If `delete()` throws because the key was already wiped (e.g. by a previous Keystore reset), the error is swallowed and `true` is returned — the data is effectively gone, so the operation is considered successful.

### Performance Improvements

- **Eliminated redundant post-write secure storage reads**: `SharedDocument`, `SharedCollection`, and `SharedManyDocument` previously re-read and decrypted the entire collection from `FlutterSecureStorage` after every write just to populate stream events and return values. They now reuse the already-updated in-memory collection map (`1` read + `1` write instead of `3` reads + `1` write).
- **Fixed N+1 read loop in `SharedManyDocument.create()` and `update()`**: Replaced the per-ID `Shared._read()` inside the return-data loop with an O(1) in-memory map lookup — batch operations on `N` documents now perform `1` secure read instead of `N + 2`.

### CI Fix

- Bumped GitHub Actions Flutter version from `3.22.3` → `3.27.4` (Dart 3.7). This resolves the `pub get` failure caused by `shared_preferences >=2.3.4` requiring Dart SDK `>=3.5.0` while the old runner only had Dart 3.4.4.

---

## 3.1.1

- Change documentation

## 3.1.0

### New Features

- **Secure-first storage**: All writes go exclusively to `FlutterSecureStorage`. `SharedPreferences` is no longer a write target.
- **Automatic bulk migration on `initialize()`**: On the first call after upgrading, all data in `SharedPreferences` is scanned and migrated to `FlutterSecureStorage` in a single pass. Secure storage wins on key conflicts — existing secure data is never overwritten.
- **Lazy per-key migration in `_read()`**: Any key still found in `SharedPreferences` during a read (e.g. after a partial migration) is migrated on-the-spot — written to secure storage and removed from `SharedPreferences` — so the next access is fully secure.
- **Migration guard flag**: A `__local_shared_migrated__` boolean is stored in `SharedPreferences` after the first bulk pass, so the expensive scan only runs once per installation.

### Improvements

- Delete operations now remove from both `FlutterSecureStorage` and `SharedPreferences`, handling partially-migrated or legacy data gracefully.
- Comprehensive migration test suite added (`test/src/shared_migration_test.dart`) covering bulk migration, lazy migration, secure-first writes, backward compatibility, conflict resolution, and edge cases.

### Breaking Changes

None. Fully backward-compatible. Existing apps using `SharedPreferences` as the backing store are seamlessly and automatically upgraded to `FlutterSecureStorage` on the next `initialize()` call.

---

## 1.0.0

- Initial release

## 1.0.1

- Update documentation

## 1.0.2

- Update link

## 1.0.3

- Update README

## 1.0.4

- Update extension syntax

## 1.0.5

- Remove assertion

## 2.0.0

- Add secure storage

## 2.0.1

- Replace all 'SharedPreferences' with 'Flutter Secure Storage'

## 3.0.0

- Some parameters have been replaced by different rules, which will definitely introduce breaking changes
- Full coverage test

## 4.0.0

- AI security test, bug finder, and huge amount of improvements on migrating from the use of SharedPreferences to FlutterSecureStorage