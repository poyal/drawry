import 'dart:io';

import 'package:drift/native.dart';
import 'package:drawry/core/crypto/secure_key_port.dart';
import 'package:drawry/core/database/app_database.dart';
import 'package:drawry/features/backup/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;
  late AppDatabase database;
  late BackupService service;
  late PathProviderPlatform originalPathProvider;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('drawry-backup-test-');
    originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _TestPathProvider(directory.path);
    database = AppDatabase.forTesting(NativeDatabase.memory());
    service = BackupService(database, MemorySecureKeyPort());
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPathProvider;
    await database.close();
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('암호와 복구 키로 백업을 검증하고 교체 복원한다', () async {
    await database.putSetting('sample', {'version': 1});
    final backup = await service.createBackup(password: 'password-123');
    final recoveryCode = await service.recoveryCode();

    await database.putSetting('sample', {'version': 2});
    await expectLater(
      service.restoreBackup(
        source: backup,
        password: 'wrong-password',
        replaceExisting: true,
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      (await database.readSetting<Map<String, dynamic>>('sample'))?['version'],
      2,
    );

    await service.restoreBackup(
      source: backup,
      password: 'password-123',
      replaceExisting: true,
    );
    expect(
      (await database.readSetting<Map<String, dynamic>>('sample'))?['version'],
      1,
    );

    await database.putSetting('sample', {'version': 3});
    await service.restoreBackup(
      source: backup,
      recoveryCode: recoveryCode,
      replaceExisting: true,
    );
    expect(
      (await database.readSetting<Map<String, dynamic>>('sample'))?['version'],
      1,
    );
  });
}

final class _TestPathProvider extends PathProviderPlatform {
  _TestPathProvider(this.path);

  final String path;

  @override
  Future<String?> getTemporaryPath() async => path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}
