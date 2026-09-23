import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

final class ChunkedCipher {
  ChunkedCipher({this.chunkSize = 4 * 1024 * 1024});

  static const _magic = [0x44, 0x52, 0x59, 0x31]; // DRY1
  static const _nonceLength = 12;
  static const _macLength = 16;

  final int chunkSize;
  final Cipher _cipher = AesGcm.with256bits();

  Uint8List generateKey() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
  }

  Future<void> encryptFile({
    required File source,
    required File destination,
    required Uint8List key,
    required String fileId,
  }) async {
    if (key.length != 32) throw ArgumentError.value(key.length, 'key.length');
    await destination.parent.create(recursive: true);
    final input = await source.open();
    final output = await destination.open(mode: FileMode.write);
    try {
      await output.writeFrom(_magic);
      await output.writeFrom(_uint32(chunkSize));
      var index = 0;
      while (true) {
        final plain = await input.read(chunkSize);
        if (plain.isEmpty) break;
        final nonce = _randomBytes(_nonceLength);
        final box = await _cipher.encrypt(
          plain,
          secretKey: SecretKey(key),
          nonce: nonce,
          aad: utf8.encode('$fileId:$index'),
        );
        await output.writeFrom(_uint32(box.cipherText.length));
        await output.writeFrom(nonce);
        await output.writeFrom(box.cipherText);
        await output.writeFrom(box.mac.bytes);
        index++;
      }
      await output.writeFrom(_uint32(0));
      await output.flush();
    } finally {
      await input.close();
      await output.close();
    }
  }

  Future<void> decryptFile({
    required File source,
    required File destination,
    required Uint8List key,
    required String fileId,
  }) async {
    final input = await source.open();
    final output = await destination.open(mode: FileMode.write);
    var succeeded = false;
    try {
      final magic = await input.read(_magic.length);
      if (!_sameBytes(magic, _magic)) {
        throw const FormatException('Unsupported encrypted media format.');
      }
      final storedChunkSize = _readUint32(await input.read(4));
      if (storedChunkSize <= 0 || storedChunkSize > 16 * 1024 * 1024) {
        throw const FormatException('Invalid encrypted media chunk size.');
      }

      var index = 0;
      while (true) {
        final cipherLengthBytes = await input.read(4);
        if (cipherLengthBytes.length != 4) {
          throw const FormatException('Truncated encrypted media.');
        }
        final cipherLength = _readUint32(cipherLengthBytes);
        if (cipherLength == 0) break;
        if (cipherLength > storedChunkSize) {
          throw const FormatException('Invalid encrypted media chunk.');
        }
        final nonce = await input.read(_nonceLength);
        final cipherText = await input.read(cipherLength);
        final mac = await input.read(_macLength);
        if (nonce.length != _nonceLength ||
            cipherText.length != cipherLength ||
            mac.length != _macLength) {
          throw const FormatException('Truncated encrypted media chunk.');
        }
        final clear = await _cipher.decrypt(
          SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
          secretKey: SecretKey(key),
          aad: utf8.encode('$fileId:$index'),
        );
        await output.writeFrom(clear);
        index++;
      }
      await output.flush();
      succeeded = true;
    } finally {
      await input.close();
      await output.close();
      if (!succeeded && await destination.exists()) {
        await destination.delete();
      }
    }
  }

  Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  Uint8List _uint32(int value) =>
      (ByteData(4)..setUint32(0, value, Endian.big)).buffer.asUint8List();

  int _readUint32(List<int> bytes) {
    if (bytes.length != 4) throw const FormatException('Invalid uint32.');
    return ByteData.sublistView(Uint8List.fromList(bytes)).getUint32(0);
  }

  bool _sameBytes(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var i = 0; i < left.length; i++) {
      difference |= left[i] ^ right[i];
    }
    return difference == 0;
  }
}
