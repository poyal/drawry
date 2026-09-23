import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/diary/data/diary_repository.dart';
import '../features/diary/domain/diary.dart';
import '../features/backup/backup_service.dart';
import 'crypto/secure_key_port.dart';
import 'database/app_database.dart';
import 'media/media_storage.dart';

final secureKeyProvider = Provider<SecureKeyPort>(
  (ref) => PlatformSecureKeyPort(),
);

final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  final database = await openEncryptedDatabase(ref.watch(secureKeyProvider));
  ref.onDispose(database.close);
  return database;
});

final mediaStorageProvider = Provider<MediaStorage>((ref) => MediaStorage());

final backupServiceProvider = FutureProvider<BackupService>((ref) async {
  final database = await ref.watch(databaseProvider.future);
  return BackupService(database, ref.watch(secureKeyProvider));
});

final diaryRepositoryProvider = FutureProvider<DiaryRepository>((ref) async {
  final database = await ref.watch(databaseProvider.future);
  return DriftDiaryRepository(database, ref.watch(mediaStorageProvider));
});

final activeDiariesProvider = StreamProvider<List<Diary>>((ref) async* {
  final repository = await ref.watch(diaryRepositoryProvider.future);
  yield* repository.watchActive();
});

final trashDiariesProvider = StreamProvider<List<Diary>>((ref) async* {
  final repository = await ref.watch(diaryRepositoryProvider.future);
  yield* repository.watchTrash();
});

final diaryProvider = FutureProvider.family<Diary?, String>((ref, id) async {
  final repository = await ref.watch(diaryRepositoryProvider.future);
  return repository.getById(id);
});

final maintenanceProvider = FutureProvider<void>((ref) async {
  final repository = await ref.watch(diaryRepositoryProvider.future);
  await repository.purgeExpired();
  final storage = ref.watch(mediaStorageProvider);
  await storage.clearMaterializedCache();
  await storage.clearTemporaryArtifacts();
});
