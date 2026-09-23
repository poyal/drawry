import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/crypto/chunked_cipher.dart';
import '../../core/crypto/secure_key_port.dart';
import '../../core/database/app_database.dart';

final class BackupService {
  BackupService(this._database, this._keys, {ChunkedCipher? cipher})
    : _cipher = cipher ?? ChunkedCipher();

  static const _magic = 'DRBK1';
  static const _iterations = 210000;

  final AppDatabase _database;
  final SecureKeyPort _keys;
  final ChunkedCipher _cipher;
  final Cipher _wrapCipher = AesGcm.with256bits();

  Future<String> recoveryCode() async =>
      base64UrlEncode(await _keys.getOrCreateRecoveryKey()).replaceAll('=', '');

  Future<File> createBackup({required String password}) async {
    if (password.length < 8) {
      throw const FormatException('백업 암호는 8자 이상이어야 합니다.');
    }
    final temporary = await getTemporaryDirectory();
    final work = await _createWorkDirectory(temporary, 'export-');
    try {
      final payloadDirectory = Directory(p.join(work.path, 'payload'));
      await payloadDirectory.create();
      final snapshot = await _database.exportSnapshot();
      await File(p.join(payloadDirectory.path, 'snapshot.json')).writeAsString(
        jsonEncode({
          'format': 'drawry-backup',
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          ...snapshot,
        }),
        flush: true,
      );

      final support = await getApplicationSupportDirectory();
      final mediaDirectory = Directory(p.join(support.path, 'secure', 'media'));
      final stagedMedia = Directory(p.join(payloadDirectory.path, 'media'));
      await stagedMedia.create();
      if (await mediaDirectory.exists()) {
        await for (final entity in mediaDirectory.list()) {
          if (entity is File) {
            await entity.copy(
              p.join(stagedMedia.path, p.basename(entity.path)),
            );
          }
        }
      }

      final zip = File(p.join(work.path, 'payload.zip'));
      await ZipFileEncoder().zipDirectory(
        payloadDirectory,
        filename: zip.path,
        level: ZipFileEncoder.store,
      );

      final dataKey = _cipher.generateKey();
      final salt = _cipher.generateKey().sublist(0, 16);
      final passwordKey = await _derivePasswordKey(password, salt);
      final recoveryKey = await _keys.getOrCreateRecoveryKey();
      final passwordWrap = await _wrap(dataKey, passwordKey, 'password');
      final recoveryWrap = await _wrap(dataKey, recoveryKey, 'recovery');
      final header = utf8.encode(
        jsonEncode({
          'version': 1,
          'salt': base64UrlEncode(salt),
          'iterations': _iterations,
          'passwordWrap': passwordWrap,
          'recoveryWrap': recoveryWrap,
        }),
      );

      final encryptedPayload = File(p.join(work.path, 'payload.dry'));
      await _cipher.encryptFile(
        source: zip,
        destination: encryptedPayload,
        key: dataKey,
        fileId: 'drawry-backup-v1',
      );
      dataKey.fillRange(0, dataKey.length, 0);
      passwordKey.fillRange(0, passwordKey.length, 0);

      final output = File(
        p.join(
          temporary.path,
          'Drawry-${DateTime.now().toIso8601String().replaceAll(':', '-')}.drawry',
        ),
      );
      final sink = output.openWrite();
      sink.add(utf8.encode(_magic));
      sink.add(_uint32(header.length));
      sink.add(header);
      await sink.addStream(encryptedPayload.openRead());
      await sink.close();
      return output;
    } finally {
      if (await work.exists()) await work.delete(recursive: true);
    }
  }

  Future<void> restoreBackup({
    required File source,
    String? password,
    String? recoveryCode,
    required bool replaceExisting,
  }) async {
    if ((password == null || password.isEmpty) &&
        (recoveryCode == null || recoveryCode.isEmpty)) {
      throw const FormatException('백업 암호 또는 복구 키를 입력하세요.');
    }
    final temporary = await getTemporaryDirectory();
    final work = await _createWorkDirectory(temporary, 'restore-');
    try {
      final input = await source.open();
      final magic = utf8.decode(await input.read(_magic.length));
      if (magic != _magic) throw const FormatException('Drawry 백업 파일이 아닙니다.');
      final headerLength = _readUint32(await input.read(4));
      if (headerLength <= 0 || headerLength > 1024 * 1024) {
        throw const FormatException('백업 머리말이 올바르지 않습니다.');
      }
      final header =
          jsonDecode(utf8.decode(await input.read(headerLength)))
              as Map<String, dynamic>;
      if (header['version'] != 1) {
        throw const FormatException('지원하지 않는 백업 버전입니다.');
      }
      final encryptedPayload = File(p.join(work.path, 'payload.dry'));
      final payloadOffset = await input.position();
      await input.close();
      final payloadSink = encryptedPayload.openWrite();
      await payloadSink.addStream(source.openRead(payloadOffset));
      await payloadSink.close();

      Uint8List keyEncryptionKey;
      Map<String, dynamic> wrapped;
      String aad;
      if (password != null && password.isNotEmpty) {
        final salt = base64Url.decode(header['salt'] as String);
        keyEncryptionKey = await _derivePasswordKey(password, salt);
        wrapped = (header['passwordWrap'] as Map<String, dynamic>);
        aad = 'password';
      } else {
        keyEncryptionKey = _decodeRecoveryCode(recoveryCode!);
        wrapped = (header['recoveryWrap'] as Map<String, dynamic>);
        aad = 'recovery';
      }
      final dataKey = await _unwrap(wrapped, keyEncryptionKey, aad);
      keyEncryptionKey.fillRange(0, keyEncryptionKey.length, 0);
      final zip = File(p.join(work.path, 'payload.zip'));
      await _cipher.decryptFile(
        source: encryptedPayload,
        destination: zip,
        key: dataKey,
        fileId: 'drawry-backup-v1',
      );
      dataKey.fillRange(0, dataKey.length, 0);

      final extracted = Directory(p.join(work.path, 'extracted'));
      await extractFileToDisk(zip.path, extracted.path);
      final snapshotFile = File(p.join(extracted.path, 'snapshot.json'));
      if (!await snapshotFile.exists()) {
        throw const FormatException('백업 데이터가 누락되었습니다.');
      }
      final snapshot =
          jsonDecode(await snapshotFile.readAsString()) as Map<String, dynamic>;
      if (snapshot['format'] != 'drawry-backup') {
        throw const FormatException('백업 형식이 올바르지 않습니다.');
      }

      final support = await getApplicationSupportDirectory();
      final vault = Directory(p.join(support.path, 'secure', 'media'));
      final mediaSource = Directory(p.join(extracted.path, 'media'));
      await _validateBackupMedia(snapshot, mediaSource);

      // Keep a complete rollback copy until both the database and encrypted
      // files have been restored. A malformed or incomplete backup must never
      // leave the existing diary half-replaced.
      final previousSnapshot = await _database.exportSnapshot();
      final rollbackMedia = Directory(p.join(work.path, 'rollback-media'));
      await rollbackMedia.create();
      await _copyFlatFiles(vault, rollbackMedia);
      try {
        await _database.restoreSnapshot(
          snapshot,
          replaceExisting: replaceExisting,
        );
        if (replaceExisting && await vault.exists()) {
          await vault.delete(recursive: true);
        }
        await vault.create(recursive: true);
        await _copyFlatFiles(mediaSource, vault);
      } catch (error, stackTrace) {
        await _database.restoreSnapshot(
          previousSnapshot,
          replaceExisting: true,
        );
        if (await vault.exists()) await vault.delete(recursive: true);
        await vault.create(recursive: true);
        await _copyFlatFiles(rollbackMedia, vault);
        Error.throwWithStackTrace(error, stackTrace);
      }
    } on SecretBoxAuthenticationError {
      throw const FormatException('백업 암호 또는 복구 키가 맞지 않습니다.');
    } finally {
      if (await work.exists()) await work.delete(recursive: true);
    }
  }

  Future<Directory> _createWorkDirectory(
    Directory temporary,
    String prefix,
  ) async {
    final base = Directory(p.join(temporary.path, 'drawry-backup-work'));
    await base.create(recursive: true);
    return base.createTemp(prefix);
  }

  Future<void> _copyFlatFiles(Directory source, Directory destination) async {
    if (!await source.exists()) return;
    await destination.create(recursive: true);
    await for (final entity in source.list()) {
      if (entity is File) {
        await entity.copy(p.join(destination.path, p.basename(entity.path)));
      }
    }
  }

  Future<void> _validateBackupMedia(
    Map<String, dynamic> snapshot,
    Directory mediaSource,
  ) async {
    final mediaRows = snapshot['media'] as List<dynamic>? ?? const [];
    for (final value in mediaRows) {
      final row = value as Map<String, dynamic>;
      for (final key in ['encryptedPath', 'thumbnailPath', 'renderedPath']) {
        final name = row[key] as String?;
        if (name == null) continue;
        if (name != p.basename(name) || name.contains('..')) {
          throw const FormatException('백업에 안전하지 않은 미디어 경로가 있습니다.');
        }
        if (!await File(p.join(mediaSource.path, name)).exists()) {
          throw FormatException('백업 미디어가 누락되었습니다: $name');
        }
      }
    }
  }

  Future<Uint8List> _derivePasswordKey(String password, List<int> salt) async {
    final algorithm = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _iterations,
      bits: 256,
    );
    final key = await algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    return Uint8List.fromList(await key.extractBytes());
  }

  Future<Map<String, String>> _wrap(
    Uint8List dataKey,
    Uint8List wrappingKey,
    String aad,
  ) async {
    final nonce = _cipher.generateKey().sublist(0, 12);
    final box = await _wrapCipher.encrypt(
      dataKey,
      secretKey: SecretKey(wrappingKey),
      nonce: nonce,
      aad: utf8.encode(aad),
    );
    return {
      'nonce': base64UrlEncode(nonce),
      'cipherText': base64UrlEncode(box.cipherText),
      'mac': base64UrlEncode(box.mac.bytes),
    };
  }

  Future<Uint8List> _unwrap(
    Map<String, dynamic> encoded,
    Uint8List wrappingKey,
    String aad,
  ) async => Uint8List.fromList(
    await _wrapCipher.decrypt(
      SecretBox(
        base64Url.decode(encoded['cipherText'] as String),
        nonce: base64Url.decode(encoded['nonce'] as String),
        mac: Mac(base64Url.decode(encoded['mac'] as String)),
      ),
      secretKey: SecretKey(wrappingKey),
      aad: utf8.encode(aad),
    ),
  );

  Uint8List _decodeRecoveryCode(String value) {
    // '-' is part of the base64url alphabet and must not be treated as a
    // visual separator. Only pasted whitespace is ignored.
    final normalized = value.replaceAll(RegExp(r'\s'), '');
    final padding = '=' * ((4 - normalized.length % 4) % 4);
    final decoded = base64Url.decode('$normalized$padding');
    if (decoded.length != 32) {
      throw const FormatException('복구 키 형식이 올바르지 않습니다.');
    }
    return Uint8List.fromList(decoded);
  }

  Uint8List _uint32(int value) =>
      (ByteData(4)..setUint32(0, value, Endian.big)).buffer.asUint8List();

  int _readUint32(List<int> bytes) {
    if (bytes.length != 4) throw const FormatException('백업 파일이 잘렸습니다.');
    return ByteData.sublistView(Uint8List.fromList(bytes)).getUint32(0);
  }
}
