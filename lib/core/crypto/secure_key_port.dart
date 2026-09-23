import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SecureKeyPort {
  Future<Uint8List> getOrCreateDatabaseKey();

  Future<Uint8List> getOrCreateRecoveryKey();

  Future<void> destroyAllKeys();
}

final class PlatformSecureKeyPort implements SecureKeyPort {
  PlatformSecureKeyPort({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.unlocked_this_device,
            ),
          );

  static const _databaseKeyName = 'drawry.database-key.v1';
  static const _recoveryKeyName = 'drawry.recovery-key.v1';

  final FlutterSecureStorage _storage;

  @override
  Future<Uint8List> getOrCreateDatabaseKey() =>
      _getOrCreate(_databaseKeyName, length: 32);

  @override
  Future<Uint8List> getOrCreateRecoveryKey() =>
      _getOrCreate(_recoveryKeyName, length: 32);

  Future<Uint8List> _getOrCreate(String name, {required int length}) async {
    final stored = await _storage.read(key: name);
    if (stored != null) {
      final decoded = base64Url.decode(stored);
      if (decoded.length == length) return Uint8List.fromList(decoded);
      await _storage.delete(key: name);
    }

    final random = Random.secure();
    final bytes = Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
    await _storage.write(key: name, value: base64UrlEncode(bytes));
    return bytes;
  }

  @override
  Future<void> destroyAllKeys() => _storage.deleteAll();
}

final class MemorySecureKeyPort implements SecureKeyPort {
  Uint8List? _databaseKey;
  Uint8List? _recoveryKey;

  @override
  Future<Uint8List> getOrCreateDatabaseKey() async =>
      _databaseKey ??= Uint8List.fromList(List<int>.generate(32, (i) => i));

  @override
  Future<Uint8List> getOrCreateRecoveryKey() async => _recoveryKey ??=
      Uint8List.fromList(List<int>.generate(32, (i) => 255 - i));

  @override
  Future<void> destroyAllKeys() async {
    _databaseKey?.fillRange(0, _databaseKey!.length, 0);
    _recoveryKey?.fillRange(0, _recoveryKey!.length, 0);
    _databaseKey = null;
    _recoveryKey = null;
  }
}
