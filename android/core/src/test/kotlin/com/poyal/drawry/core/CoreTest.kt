package com.poyal.drawry.core

import java.io.File
import java.nio.file.Files
import java.util.Base64
import kotlin.test.*
import kotlinx.serialization.json.*

class CoreTest {
    @Test
    fun independentCryptoVector() = temp { dir ->
        val json =
            wireJson.parseToJsonElement(File(System.getenv("DRAWRY_GOLDEN")).readText()).jsonObject
        fun text(key: String) = json.getValue(key).jsonPrimitive.content
        fun bytes(key: String) = Base64.getDecoder().decode(text(key))
        assertContentEquals(
            bytes("derivedKey"),
            Backup.passwordKey(text("password"), bytes("salt")),
        )
        val source = File(dir, "cipher").apply { writeBytes(bytes("encrypted")) }
        val output = File(dir, "plain")
        ChunkCipher.decrypt(source, output, bytes("mediaKey"), text("context"))
        assertContentEquals(bytes("plaintext"), output.readBytes())
        source.appendBytes(byteArrayOf(0))
        assertFails { ChunkCipher.decrypt(source, output, bytes("mediaKey"), text("context")) }
        assertFalse(output.exists())
    }

    private fun temp(block: (File) -> Unit) {
        val dir = Files.createTempDirectory("drawry-test").toFile()
        try {
            block(dir)
        } finally {
            dir.deleteRecursively()
        }
    }

    @Test
    fun chunkRoundTripAndTamper() = temp { dir ->
        val source =
            File(dir, "plain").apply { writeBytes(ByteArray(ChunkCipher.CHUNK_SIZE + 137) { 23 }) }
        val encrypted = File(dir, "encrypted")
        val restored = File(dir, "restored")
        val key = ByteArray(32) { 7 }
        ChunkCipher.encrypt(source, encrypted, key, "test")
        ChunkCipher.decrypt(encrypted, restored, key, "test")
        assertContentEquals(source.readBytes(), restored.readBytes())
        assertFails { ChunkCipher.decrypt(encrypted, restored, key, "wrong") }
        assertFalse(restored.exists())
        encrypted.writeBytes(encrypted.readBytes().dropLast(16).toByteArray())
        assertFails { ChunkCipher.decrypt(encrypted, restored, key, "test") }
        assertFalse(restored.exists())
    }

    @Test
    fun backupRoundTrip() = temp { dir ->
        val mediaDir = File(dir, "media").apply { mkdirs() }
        val key = ByteArray(32) { 9 }
        val initial = Media(key = Base64.getEncoder().encodeToString(key), byteLength = 4)
        val media =
            initial.copy(
                original = "${initial.id}.jpg.dry",
                thumbnail = "${initial.id}.thumb.dry",
                edit =
                    EditRecipe(
                        version = 2,
                        strokes =
                            listOf(
                                InkStroke(
                                    color = "#78658F",
                                    points = listOf(InkPoint(.25, .25), InkPoint(.75, .75)),
                                )
                            ),
                    ),
            )
        val source = File(dir, "plain").apply { writeBytes(byteArrayOf(1, 2, 3, 4)) }
        media.files.forEach { ChunkCipher.encrypt(source, File(mediaDir, it), key, it) }
        val diary = Diary(headline = "한글 🌸", media = listOf(media))
        val backup = File(dir, "test.drawry")
        val recovery = ByteArray(32) { 8 }
        Backup.create(
            Snapshot(diaries = listOf(diary), preferences = Preferences()),
            mediaDir,
            backup,
            "테스트 암호1234",
            recovery,
        )
        assertEquals(
            listOf(diary),
            Backup.restore(backup, File(dir, "restore"), password = "테스트 암호1234").diaries,
        )
        assertEquals(
            listOf(diary),
            Backup.restore(backup, File(dir, "recovery"), recoveryKey = recovery).diaries,
        )
        assertFails { Backup.restore(backup, File(dir, "bad"), password = "wrong") }
        assertFalse(File(dir, "bad").exists())
        System.getenv("DRAWRY_FIXTURES")?.let {
            File(it).mkdirs()
            backup.copyTo(File(it, "kotlin.drawry"), overwrite = true)
        }
    }

    @Test
    fun swiftBackup() = temp { dir ->
        val folder = System.getenv("DRAWRY_FIXTURES") ?: return@temp
        val file = File(folder, "swift.drawry")
        if (!file.exists()) return@temp
        val snapshot = Backup.restore(file, File(dir, "swift"), password = "테스트 암호1234")
        assertEquals("한글 🌸", snapshot.diaries.first().headline)
        assertEquals(4, snapshot.diaries.first().media.first().byteLength)
        val ink = snapshot.diaries.first().media.first().edit.strokes
        assertEquals("#78658F", ink.single().color)
        assertEquals(listOf(InkPoint(.25, .25), InkPoint(.75, .75)), ink.single().points)
    }

    @Test
    fun validation() {
        assertFails { Diary().validate() }
        Diary().validate(allowEmpty = true)
        assertFalse(safeFilename("../secret"))
        assertFalse(safeFilename("/tmp/file"))
        assertFails { Diary(entryTimeMinutes = 1440).validate(allowEmpty = true) }
    }
}
