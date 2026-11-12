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

## 3.1.1

- Change documentation