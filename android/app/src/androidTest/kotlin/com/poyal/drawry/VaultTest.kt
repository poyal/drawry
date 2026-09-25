package com.poyal.drawry

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.poyal.drawry.core.*
import com.poyal.drawry.data.Vault
import java.io.File
import java.util.Base64
import java.util.UUID
import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class VaultTest {
    private suspend fun fixture(vault: Vault): Diary {
        val key = ChunkCipher.random(32)
        val initial = Media(key = Base64.getEncoder().encodeToString(key), byteLength = 4)
        val media =
            initial.copy(original = "${initial.id}.jpg.dry", thumbnail = "${initial.id}.thumb.dry")
        val plain = File(vault.cache, "fixture").apply { writeBytes(byteArrayOf(1, 2, 3, 4)) }
        media.files.forEach { ChunkCipher.encrypt(plain, File(vault.mediaDirectory, it), key, it) }
        plain.delete()
        return Diary(headline = "private diary", media = listOf(media))
    }

    @Test
    fun encryptedStoreDraftTrashAndRestore() = runBlocking {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val vault = Vault(context, "test-${UUID.randomUUID()}")
        try {
            vault.initialize()
            val diary = fixture(vault)
            vault.save(diary)
            val header = File(vault.root, "drawry.db").inputStream().use { it.readExactly(16) }
            assertFalse(header.toString(Charsets.US_ASCII).startsWith("SQLite format"))
            val draft = Diary(headline = "unfinished")
            vault.draft(draft)
            vault.trash(diary)
            assertEquals(draft, vault.draft())
            assertNotNull(vault.diaries().single().deletedAt)
            vault.trash(vault.diaries().single(), true)
            assertNull(vault.diaries().single().deletedAt)
            vault.preferences(Preferences(onboarded = true, lockEnabled = true, graceSeconds = 60))
            val backup = vault.export("a strong password")
            vault.save(diary.copy(headline = "local change"))
            val merged = vault.inspect(backup, "a strong password", null)
            vault.restore(merged.first, merged.second, false)
            assertEquals("local change", vault.diaries().single().headline)
            val replaced = vault.inspect(backup, "a strong password", null)
            vault.restore(replaced.first, replaced.second, true)
            assertEquals("private diary", vault.diaries().single().headline)
            assertTrue(vault.preferences().lockEnabled)
            assertEquals(60, vault.preferences().graceSeconds)
            assertNull(vault.draft())
            try {
                vault.inspect(backup, "wrong", null)
                fail("Wrong password accepted")
            } catch (_: Exception) {}
            assertEquals("private diary", vault.diaries().single().headline)
            assertTrue(vault.root.listFiles().orEmpty().none { it.name.startsWith("restore-") })
            vault.purge(diary.id)
            assertTrue(vault.diaries().isEmpty())
            assertTrue(vault.mediaDirectory.listFiles().orEmpty().isEmpty())
        } finally {
            vault.erase()
        }
    }

    @Test
    fun expiredTrashAndInvalidSaveLeaveExistingData() = runBlocking {
        val vault =
            Vault(
                InstrumentationRegistry.getInstrumentation().targetContext,
                "test-${UUID.randomUUID()}",
            )
        try {
            vault.initialize()
            val diary = fixture(vault)
            vault.save(diary)
            try {
                vault.save(diary.copy(media = emptyList()))
                fail("Invalid save accepted")
            } catch (_: IllegalArgumentException) {}
            assertEquals(1, vault.diaries().size)
            vault.save(diary.copy(deletedAt = System.currentTimeMillis() - 31L * 86400_000))
            vault.purgeExpired()
            assertTrue(vault.diaries().isEmpty())
            assertTrue(vault.mediaDirectory.listFiles().orEmpty().isEmpty())
        } finally {
            vault.erase()
        }
    }
}
