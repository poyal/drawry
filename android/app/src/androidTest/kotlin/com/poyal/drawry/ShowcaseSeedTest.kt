package com.poyal.drawry

import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Bundle
import android.provider.MediaStore as Gallery
import androidx.room.Room
import androidx.room.withTransaction
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.UiDevice
import com.poyal.drawry.core.*
import com.poyal.drawry.data.MediaStore
import com.poyal.drawry.data.Record
import com.poyal.drawry.data.Vault
import com.poyal.drawry.data.VaultDatabase
import java.io.File
import java.time.LocalDate
import java.time.ZoneOffset
import java.util.UUID
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.encodeToString
import net.zetetic.database.sqlcipher.SupportOpenHelperFactory
import org.junit.Assert.*
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

/** Explicitly opted-in, additive manual-demo setup. Never part of the ordinary test suite. */
@RunWith(AndroidJUnit4::class)
class ShowcaseSeedTest {
    private data class Page(
        val day: Int,
        val minutes: Int,
        val title: String,
        val body: String,
        val mood: String,
        val photos: List<Int>,
    )

    @Test
    fun addPhotosAndDatedDiaries(): Unit = runBlocking {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        assumeTrue(InstrumentationRegistry.getArguments().getString("seedShowcase") == "true")
        val device = UiDevice.getInstance(instrumentation)
        check(
            device.executeShellCommand("getprop ro.boot.qemu.avd_name").trim() ==
                "drawry-sketchbook-qa"
        ) {
            "Only the explicitly selected drawry-sketchbook-qa AVD may be seeded."
        }
        val context = instrumentation.targetContext
        val input = File(context.getExternalFilesDir(null), "showcase-input")
        val ids = listOf(10, 11, 12, 15, 16, 20, 28, 29, 42, 43, 48, 237)
        ids.forEach { check(File(input, "$it.jpg").isFile) { "Missing sample photo: $it" } }
        val anchor = LocalDate.of(2026, 9, 25)
        val pages =
            listOf(
                Page(
                    0,
                    19 * 60,
                    "커피 한 잔, 오늘의 여백",
                    "조용한 자리에 앉아 잠깐 쉬었다. 사진을 넘기면 책상 위의 작은 풍경도 볼 수 있다.",
                    "☕",
                    listOf(42, 20, 48),
                ),
                Page(
                    0,
                    10 * 60 + 30,
                    "멀리 바라본 아침",
                    "나무 너머로 보이는 물빛이 좋았다. 가로 사진과 세로 사진을 한 페이지에 붙여 보았다.",
                    "😌",
                    listOf(10, 11),
                ),
                Page(
                    1,
                    17 * 60,
                    "네 장으로 남긴 풍경",
                    "마음에 드는 장면을 네 장 골랐다. 한 장씩 넘기며 서로 다른 비율을 비교해 보자.",
                    "🌿",
                    listOf(28, 29, 15, 16),
                ),
                Page(
                    2,
                    20 * 60,
                    "반가운 눈맞춤",
                    "별다른 말 없이도 기억에 남는 순간. 오늘은 사진 한 장만으로 충분하다.",
                    "🐶",
                    listOf(237),
                ),
                Page(
                    2,
                    9 * 60,
                    "책상 앞 작은 시작",
                    "책을 펼치고 메모를 꺼냈다. 조금씩 쌓이는 하루의 기록.",
                    "✏️",
                    listOf(20, 42, 48),
                ),
                Page(
                    3,
                    16 * 60 + 20,
                    "바람을 따라 걷기",
                    "잠시 화면을 내려놓고 바깥 풍경을 바라보았다. 두 장의 사진으로 남겨둔 산책.",
                    "😊",
                    listOf(12, 43),
                ),
                Page(
                    4,
                    21 * 60,
                    "오늘의 좋아하는 색",
                    "푸른색과 초록색을 모아 둔 페이지. 기분 좋은 색을 오래 기억하고 싶다.",
                    "💚",
                    listOf(16, 10, 28),
                ),
                Page(
                    4,
                    11 * 60,
                    "느긋하게 고른 네 컷",
                    "가로, 세로, 정사각형 사진을 섞었다. 넘김과 썸네일 선택, 꾸미기를 함께 테스트할 수 있는 기록이다.",
                    "✨",
                    listOf(48, 42, 15, 237),
                ),
                Page(
                    5,
                    14 * 60,
                    "빛이 머무는 곳",
                    "급하지 않게 걸었던 하루. 좋아하는 풍경 두 장을 붙이고 짧은 문장을 남긴다.",
                    "☀️",
                    listOf(29, 11),
                ),
                Page(
                    6,
                    18 * 60,
                    "천천히 채우는 페이지",
                    "사진을 붙이고 한 줄을 쓰는 일은 생각보다 오래 남는다.\n\n긴 한글 본문과 줄바꿈도 살펴볼 수 있도록 조금 더 적어 두었다. 😊 같은 풍경도 사진의 비율과 순서에 따라 다르게 보인다. 마음에 드는 장면에는 낙서를 더하고, 필요하면 실행 취소로 되돌려 보자.\n\n오늘의 기록은 여기까지.",
                    "🥰",
                    listOf(15, 28, 10),
                ),
                Page(
                    7,
                    12 * 60,
                    "점심 뒤의 작은 쉼표",
                    "커피와 메모, 오늘을 기억하게 하는 작은 것들. 제목과 본문이 함께 있는 카드용 샘플이다.",
                    "☕",
                    listOf(42, 20),
                ),
                Page(
                    25,
                    15 * 60,
                    "8월의 마지막 페이지",
                    "지난달에도 기록을 남겨 두었다. 캘린더를 8월로 넘기면 이 페이지를 찾을 수 있다.",
                    "🌤️",
                    listOf(43, 12, 16, 29),
                ),
            )
        // Use the normal encrypted media importer. Insert only new diary rows below: Vault.save()
        // intentionally clears the active draft and must NOT be used for additive demo seeding.
        val vault = Vault(context)
        vault.initialize()
        val before = vault.diaries().associateBy { it.id }
        val originalDraft = vault.draft()
        val originalPreferences = vault.preferences()
        val db =
            Room.databaseBuilder(
                    context,
                    VaultDatabase::class.java,
                    File(vault.root, "drawry.db").absolutePath,
                )
                .openHelperFactory(SupportOpenHelperFactory(vault.keys.get("database")))
                .build()
        var inserted = 0
        val galleryUris = mutableListOf<Uri>()
        val expectedIds = mutableListOf<String>()
        try {
            ids.forEachIndexed { index, id ->
                galleryUris +=
                    addToGallery(
                        context,
                        File(input, "$id.jpg"),
                        id,
                        anchor
                            .minusDays((index % 8).toLong())
                            .atStartOfDay()
                            .toInstant(ZoneOffset.ofHours(9))
                            .toEpochMilli(),
                    )
            }
            val store = MediaStore(context, vault)
            pages.forEachIndexed { index, page ->
                val id =
                    UUID.nameUUIDFromBytes("drawry-showcase-20260925-$index".toByteArray())
                        .toString()
                expectedIds += id
                if (db.records().get(id) == null) {
                    val media =
                        page.photos.map {
                            store.import(Uri.fromFile(File(input, "$it.jpg")), false, false)
                        }
                    val diary =
                        Diary(
                            id = id,
                            entryDate = anchor.minusDays(page.day.toLong()).toString(),
                            entryTimeMinutes = page.minutes,
                            utcOffsetMinutes = 540,
                            headline = page.title,
                            body = page.body + "\n\n디자인 확인용 샘플 기록 · 사진: Lorem Picsum / Unsplash.",
                            mood = page.mood,
                            tags = listOf("샘플", "사진일기"),
                            media = media,
                            weather =
                                if (index % 3 == 0)
                                    Weather(condition = "맑음", temperature = 23.0, displayMask = 3)
                                else Weather(),
                        )
                    diary.validate()
                    check(
                        diary.media
                            .flatMap { it.files }
                            .all { File(vault.mediaDirectory, it).isFile }
                    )
                    db.withTransaction {
                        check(db.records().get(id) == null) {
                            "Refusing to overwrite an existing diary"
                        }
                        db.records().put(Record(id, "diary", wireJson.encodeToString(diary)))
                    }
                    inserted++
                }
            }
            val after = vault.diaries().associateBy { it.id }
            assertTrue(
                "Existing diaries must remain unchanged",
                before.all { (id, diary) -> after[id] == diary },
            )
            assertTrue("Active draft must remain unchanged", originalDraft == vault.draft())
            assertTrue(
                "Existing preferences must remain unchanged",
                originalPreferences == vault.preferences(),
            )
            assertTrue(
                "Draft media must remain present",
                originalDraft
                    ?.media
                    ?.flatMap { it.files }
                    ?.all { File(vault.mediaDirectory, it).isFile } != false,
            )
            assertTrue("All demo diaries must exist", expectedIds.all { it in after })
            galleryUris.forEach { uri ->
                context.contentResolver.openInputStream(uri)!!.use { assertTrue(it.read() >= 0) }
            }
            instrumentation.sendStatus(
                0,
                Bundle().apply {
                    putString(
                        "stream",
                        "\nShowcase: added $inserted diaries; ${expectedIds.size} sample diaries across ${pages.map { it.day }.distinct().size} dates; ${pages.sumOf { it.photos.size }} attached photos; ${galleryUris.size} gallery images. Existing ${before.size} diaries, draft and preferences preserved.\n",
                    )
                },
            )
        } finally {
            db.close()
            vault.close()
        }
    }

    private fun addToGallery(context: Context, source: File, id: Int, taken: Long): Uri {
        val resolver = context.contentResolver
        val collection = Gallery.Images.Media.EXTERNAL_CONTENT_URI
        val name = "Drawry_sample_20260925_$id.jpg"
        val folder = "Pictures/Drawry Samples/"
        resolver
            .query(
                collection,
                arrayOf(Gallery.Images.Media._ID),
                "${Gallery.Images.Media.DISPLAY_NAME} = ? AND ${Gallery.Images.Media.RELATIVE_PATH} = ?",
                arrayOf(name, folder),
                null,
            )
            ?.use {
                if (it.moveToFirst())
                    return android.content.ContentUris.withAppendedId(collection, it.getLong(0))
            }
        val uri =
            checkNotNull(
                resolver.insert(
                    collection,
                    ContentValues().apply {
                        put(Gallery.Images.Media.DISPLAY_NAME, name)
                        put(Gallery.Images.Media.MIME_TYPE, "image/jpeg")
                        put(Gallery.Images.Media.RELATIVE_PATH, folder)
                        put(Gallery.Images.Media.DATE_TAKEN, taken)
                        put(Gallery.Images.Media.IS_PENDING, 1)
                    },
                )
            )
        resolver.openOutputStream(uri)!!.use { output ->
            source.inputStream().use { it.copyTo(output) }
        }
        resolver.update(
            uri,
            ContentValues().apply { put(Gallery.Images.Media.IS_PENDING, 0) },
            null,
            null,
        )
        return uri
    }
}
