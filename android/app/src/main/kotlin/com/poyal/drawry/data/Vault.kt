package com.poyal.drawry.data

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import androidx.room.*
import androidx.sqlite.db.SupportSQLiteDatabase
import com.poyal.drawry.core.*
import java.io.File
import java.security.KeyStore
import java.util.UUID
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runInterruptible
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.serialization.encodeToString
import net.zetetic.database.sqlcipher.SupportOpenHelperFactory

@Entity(tableName = "records")
data class Record(@PrimaryKey val id: String, val kind: String, val payload: String)

@Dao
interface Records {
    @Query("SELECT * FROM records WHERE kind = :kind") suspend fun all(kind: String): List<Record>

    @Query("SELECT * FROM records WHERE id = :id") suspend fun get(id: String): Record?

    @Insert(onConflict = OnConflictStrategy.REPLACE) suspend fun put(record: Record)

    @Query("DELETE FROM records WHERE id = :id") suspend fun remove(id: String)

    @Query("DELETE FROM records WHERE kind = :kind") suspend fun removeKind(kind: String)
}

@Database(entities = [Record::class], version = 1, exportSchema = true)
abstract class VaultDatabase : RoomDatabase() {
    abstract fun records(): Records
}

class SecureKeys(private val directory: File) {
    private val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
    private val alias = "com.poyal.drawry.${directory.name}.v2"

    private fun master(): SecretKey {
        (store.getKey(alias, null) as? SecretKey)?.let {
            return it
        }
        require(!File(directory, "database.key").exists()) { "기기 보안 키를 찾을 수 없습니다. 백업에서 복원해야 합니다." }
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
            .apply {
                init(
                    KeyGenParameterSpec.Builder(
                            alias,
                            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
                        )
                        .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                        .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                        .build()
                )
            }
            .generateKey()
    }

    @Synchronized
    fun get(name: String): ByteArray {
        val file = File(directory, "$name.key")
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        if (file.exists()) {
            val bytes = file.readBytes()
            require(bytes.size == 60)
            cipher.init(
                Cipher.DECRYPT_MODE,
                master(),
                GCMParameterSpec(128, bytes.copyOfRange(0, 12)),
            )
            cipher.updateAAD(name.toByteArray())
            return cipher.doFinal(bytes.copyOfRange(12, bytes.size))
        }
        require(name != "database" || !File(directory, "drawry.db").exists()) { "데이터베이스 키가 없습니다." }
        val key = ChunkCipher.random(32)
        cipher.init(Cipher.ENCRYPT_MODE, master())
        cipher.updateAAD(name.toByteArray())
        val temporary = File(directory, "$name.key.tmp")
        temporary.writeBytes(cipher.iv + cipher.doFinal(key))
        check(temporary.renameTo(file))
        return key
    }

    fun destroy() {
        store.deleteEntry(alias)
        File(directory, "database.key").delete()
        File(directory, "recovery.key").delete()
    }
}

class Vault(context: Context, storageName: String = "native-v2") {
    val root =
        File(context.noBackupFilesDir, storageName).apply {
            require(safeFilename(storageName))
            mkdirs()
        }
    val cache =
        File(context.cacheDir, "drawry-private").apply {
            deleteRecursively()
            mkdirs()
        }
    val keys = SecureKeys(root)
    private val mutex = Mutex()
    private val db: VaultDatabase
    var mediaDirectory = File(root, "media-initial").apply { mkdirs() }
        private set

    init {
        System.loadLibrary("sqlcipher")
        val key = keys.get("database")
        db =
            Room.databaseBuilder(
                    context,
                    VaultDatabase::class.java,
                    File(root, "drawry.db").absolutePath,
                )
                .openHelperFactory(SupportOpenHelperFactory(key))
                .addCallback(
                    object : RoomDatabase.Callback() {
                        override fun onOpen(db: SupportSQLiteDatabase) {
                            db.query("PRAGMA cipher_version").use { check(it.moveToFirst()) }
                            db.query("PRAGMA secure_delete=ON").use { it.moveToFirst() }
                            db.query("PRAGMA cipher_memory_security=ON").use { it.moveToFirst() }
                        }
                    }
                )
                .build()
    }

    suspend fun initialize() =
        withContext(Dispatchers.IO) {
            db.records().get("generation")?.let { record ->
                require(safeFilename(record.payload) && record.payload.startsWith("media-"))
                mediaDirectory = File(root, record.payload).apply { mkdirs() }
            }
            root
                .listFiles()
                ?.filter {
                    (it.name.startsWith("media-") && it != mediaDirectory) ||
                        it.name.startsWith("restore-")
                }
                ?.forEach { it.deleteRecursively() }
            purgeExpired()
            collectOrphans()
        }

    suspend fun diaries(): List<Diary> =
        withContext(Dispatchers.IO) {
            db.records()
                .all("diary")
                .map { wireJson.decodeFromString<Diary>(it.payload) }
                .sortedWith(
                    compareByDescending<Diary> { it.entryDate }
                        .thenByDescending { it.entryTimeMinutes }
                )
        }

    suspend fun preferences(): Preferences =
        withContext(Dispatchers.IO) {
            db.records().get("preferences")?.let {
                wireJson.decodeFromString<Preferences>(it.payload)
            } ?: Preferences()
        }

    suspend fun preferences(value: Preferences) =
        withContext(Dispatchers.IO) {
            value.validate()
            db.records().put(Record("preferences", "setting", wireJson.encodeToString(value)))
        }

    suspend fun save(diary: Diary) =
        withContext(Dispatchers.IO) {
            mutex.withLock {
                diary.validate()
                require(diary.media.flatMap { it.files }.all { File(mediaDirectory, it).isFile })
                db.withTransaction {
                    db.records()
                        .put(
                            Record(
                                diary.id,
                                "diary",
                                wireJson.encodeToString(
                                    diary.copy(updatedAt = System.currentTimeMillis())
                                ),
                            )
                        )
                    db.records().remove("draft")
                }
                collectOrphans()
            }
        }

    suspend fun draft(): Diary? =
        withContext(Dispatchers.IO) {
            db.records().get("draft")?.let { wireJson.decodeFromString<Diary>(it.payload) }
        }

    suspend fun draft(value: Diary?) =
        withContext(Dispatchers.IO) {
            if (value == null) {
                db.records().remove("draft")
                collectOrphans()
            } else {
                value.validate(allowEmpty = true)
                db.records().put(Record("draft", "draft", wireJson.encodeToString(value)))
            }
        }

    suspend fun trash(diary: Diary, restore: Boolean = false) =
        withContext(Dispatchers.IO) {
            val value =
                diary.copy(
                    deletedAt = if (restore) null else System.currentTimeMillis(),
                    updatedAt = System.currentTimeMillis(),
                )
            db.records().put(Record(value.id, "diary", wireJson.encodeToString(value)))
        }

    fun cleanExpiredExports() {
        cache
            .listFiles()
            ?.filter {
                it.name.startsWith("Drawry-") &&
                    it.lastModified() < System.currentTimeMillis() - 600_000
            }
            ?.forEach { it.delete() }
    }

    suspend fun purge(id: String) =
        withContext(Dispatchers.IO) {
            if (draft()?.id == id) db.records().remove("draft")
            db.records().remove(id)
            collectOrphans()
            db.openHelper.writableDatabase.query("PRAGMA wal_checkpoint(TRUNCATE)").close()
        }

    suspend fun purgeExpired() {
        diaries()
            .filter {
                (it.deletedAt ?: Long.MAX_VALUE) <= System.currentTimeMillis() - 30L * 86400_000
            }
            .forEach { purge(it.id) }
    }

    suspend fun collectOrphans() {
        val keep =
            (diaries() + listOfNotNull(draft())).flatMap { it.media }.flatMap { it.files }.toSet()
        mediaDirectory.listFiles()?.filter { it.name !in keep }?.forEach { it.delete() }
    }

    suspend fun export(password: String): File =
        withContext(Dispatchers.IO) {
            mutex.withLock {
                val snapshot =
                    Snapshot(
                        diaries = diaries(),
                        preferences = preferences().copy(lockEnabled = false, graceSeconds = 0),
                    )
                File(cache, "Drawry-${System.currentTimeMillis()}.drawry").also {
                    runInterruptible {
                        Backup.create(snapshot, mediaDirectory, it, password, keys.get("recovery"))
                    }
                }
            }
        }

    suspend fun inspect(
        source: File,
        password: String?,
        recovery: ByteArray?,
    ): Pair<Snapshot, File> =
        withContext(Dispatchers.IO) {
            val stage = File(root, "restore-${UUID.randomUUID()}")
            runInterruptible { Backup.restore(source, stage, password, recovery) } to stage
        }

    suspend fun restore(snapshot: Snapshot, stage: File, replace: Boolean) =
        withContext(Dispatchers.IO) {
            mutex.withLock {
                val existing = if (replace) emptyList() else diaries()
                val ids = existing.map { it.id }.toSet()
                val incoming = snapshot.diaries.filter { it.id !in ids }
                val all = existing + incoming
                Snapshot(diaries = all, preferences = snapshot.preferences).validate()
                val next = File(root, "media-${UUID.randomUUID()}").apply { mkdirs() }
                var committed = false
                try {
                    existing
                        .flatMap { it.media }
                        .flatMap { it.files }
                        .forEach { File(mediaDirectory, it).copyTo(File(next, it)) }
                    incoming
                        .flatMap { it.media }
                        .flatMap { it.files }
                        .forEach { File(stage, it).copyTo(File(next, it)) }
                    val old = mediaDirectory
                    val prefs =
                        if (replace)
                            snapshot.preferences.copy(
                                onboarded = true,
                                lockEnabled = preferences().lockEnabled,
                                graceSeconds = preferences().graceSeconds,
                            )
                        else preferences()
                    db.withTransaction {
                        db.records().removeKind("diary")
                        db.records().remove("draft")
                        all.forEach {
                            db.records().put(Record(it.id, "diary", wireJson.encodeToString(it)))
                        }
                        db.records().put(Record("generation", "setting", next.name))
                        db.records()
                            .put(Record("preferences", "setting", wireJson.encodeToString(prefs)))
                    }
                    committed = true
                    mediaDirectory = next
                    old.deleteRecursively()
                    purgeExpired()
                } finally {
                    if (!committed) next.deleteRecursively()
                    stage.deleteRecursively()
                }
            }
        }

    fun clearCache() {
        cache.listFiles()?.forEach { it.deleteRecursively() }
    }

    fun close() {
        db.close()
    }

    fun erase() {
        db.close()
        keys.destroy()
        root.deleteRecursively()
        clearCache()
    }
}
