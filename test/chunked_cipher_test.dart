import 'dart:io';
import 'dart:typed_data';

import 'package:drawry/core/crypto/chunked_cipher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChunkedCipher', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('drawry-cipher-test-');
    });

    tearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    test('여러 청크를 암호화하고 원본으로 복원한다', () async {
      final cipher = ChunkedCipher(chunkSize: 128);
      final source = File('${directory.path}/source.bin');
      final encrypted = File('${directory.path}/encrypted.bin');
      final restored = File('${directory.path}/restored.bin');
      final input = Uint8List.fromList(
        List<int>.generate(1025, (index) => (index * 31) % 256),
      );
      await source.writeAsBytes(input);
      final key = cipher.generateKey();

      await cipher.encryptFile(
        source: source,
        destination: encrypted,
        key: key,
        fileId: 'test-media',
      );
      await cipher.decryptFile(
        source: encrypted,
        destination: restored,
        key: key,
        fileId: 'test-media',
      );

      expect(await restored.readAsBytes(), input);
      expect(await encrypted.readAsBytes(), isNot(input));
    });

    test('잘못된 키로 복호화하면 출력 파일을 남기지 않는다', () async {
      final cipher = ChunkedCipher(chunkSize: 64);
      final source = File('${directory.path}/source.bin');
      final encrypted = File('${directory.path}/encrypted.bin');
      final restored = File('${directory.path}/restored.bin');
      await source.writeAsBytes(List<int>.generate(200, (index) => index));
      await cipher.encryptFile(
        source: source,
        destination: encrypted,
        key: cipher.generateKey(),
        fileId: 'test-media',
      );

      await expectLater(
        cipher.decryptFile(
          source: encrypted,
          destination: restored,
          key: cipher.generateKey(),
          fileId: 'test-media',
        ),
        throwsA(anything),
      );
      expect(await restored.exists(), isFalse);
    });
  });
}
