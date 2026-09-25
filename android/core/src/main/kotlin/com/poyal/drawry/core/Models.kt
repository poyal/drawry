package com.poyal.drawry.core

import java.time.LocalDate
import java.time.OffsetDateTime
import java.util.Base64
import java.util.UUID
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

val wireJson = Json {
    encodeDefaults = true
    ignoreUnknownKeys = true
    explicitNulls = false
}

@Serializable
data class Weather(
    val condition: String = "",
    val temperature: Double? = null,
    val minimum: Double? = null,
    val maximum: Double? = null,
    val precipitation: Boolean = false,
    val displayMask: Int = 1,
)

@Serializable
data class Overlay(
    val id: String = UUID.randomUUID().toString(),
    val text: String = "",
    val x: Double = .5,
    val y: Double = .5,
    val size: Double = .07,
    val color: String = "#FFFFFF",
)

@Serializable
data class EditRecipe(
    val version: Int = 1,
    val quarterTurns: Int = 0,
    val squareCrop: Boolean = false,
    val filter: String = "original",
    val overlays: List<Overlay> = emptyList(),
    val strokes: List<InkStroke> = emptyList(),
)

@Serializable
data class Media(
    val id: String = UUID.randomUUID().toString(),
    val kind: String = "image",
    val mimeType: String = "image/jpeg",
    val key: String = "",
    val original: String = "",
    val thumbnail: String = "",
    val rendered: String? = null,
    val byteLength: Long = 0,
    val durationMillis: Long = 0,
    val representativeMillis: Long = 0,
    val edit: EditRecipe = EditRecipe(),
) {
    val files: List<String>
        get() = listOfNotNull(original, thumbnail, rendered)
}

@Serializable
data class Diary(
    val id: String = UUID.randomUUID().toString(),
    val entryDate: String = LocalDate.now().toString(),
    val entryTimeMinutes: Int = OffsetDateTime.now().let { it.hour * 60 + it.minute },
    val utcOffsetMinutes: Int = OffsetDateTime.now().offset.totalSeconds / 60,
    val headline: String = "",
    val body: String = "",
    val mood: String = "",
    val tags: List<String> = emptyList(),
    val companions: List<String> = emptyList(),
    val weather: Weather = Weather(),
    val media: List<Media> = emptyList(),
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = createdAt,
    val deletedAt: Long? = null,
) {
    fun validate(allowEmpty: Boolean = false) {
        UUID.fromString(id)
        LocalDate.parse(entryDate)
        require(Regex("^\\d{4}-\\d{2}-\\d{2}$").matches(entryDate))
        require(
            createdAt in 0..253402300799999L &&
                updatedAt in 0..253402300799999L &&
                (deletedAt == null || deletedAt in 0..253402300799999L)
        )
        require(entryTimeMinutes in 0..1439 && utcOffsetMinutes in -840..840)
        require(
            (allowEmpty || media.isNotEmpty()) &&
                media.size <= 10 &&
                media.map { it.id }.distinct().size == media.size
        )
        val videos = media.filter { it.kind == "video" }
        require(
            videos.size <= 3 &&
                videos.all { it.durationMillis in 1..30_000 } &&
                videos.sumOf { it.durationMillis } <= 60_000
        ) {
            MEDIA_LIMIT
        }
        require(
            media.all { it.byteLength in 0..300L * 1024 * 1024 } &&
                media.sumOf { it.byteLength } <= 300L * 1024 * 1024
        ) {
            MEDIA_LIMIT
        }
        media.forEach {
            UUID.fromString(it.id)
            require(
                it.kind in listOf("image", "video") &&
                    Base64.getDecoder().decode(it.key).size == 32 &&
                    it.files.all(::safeFilename)
            )
            require(
                it.representativeMillis >= 0 &&
                    (it.kind != "video" || it.representativeMillis < it.durationMillis)
            )
            require(
                it.edit.version in 1..2 &&
                    it.edit.quarterTurns in 0..3 &&
                    it.edit.filter in listOf("original", "mono", "warm", "cool")
            )
            it.edit.validateInk()
            require(
                it.edit.overlays.size <= 100 &&
                    it.edit.overlays.all { o ->
                        o.x in 0.0..1.0 && o.y in 0.0..1.0 && o.size in .01..0.5
                    }
            )
        }
    }
}

@Serializable
data class Preferences(
    val onboarded: Boolean = false,
    val layout: Int = 1,
    val lockEnabled: Boolean = false,
    val graceSeconds: Int = 0,
    val shareRatio: String = "4:5",
    val shareTheme: String = "light",
    val shareFields: List<String> = listOf("headline", "body", "date", "mood", "weather"),
    val watermark: Boolean = true,
) {
    fun validate() {
        require(layout in 1..3 && graceSeconds in listOf(0, 30, 60, 300, 900, 1800))
        require(shareRatio in listOf("4:5", "1:1", "9:16") && shareTheme in listOf("light", "dark"))
        require(
            shareFields.distinct().size == shareFields.size &&
                shareFields.all { it in listOf("headline", "body", "date", "mood", "weather") }
        )
    }
}

@Serializable
data class Snapshot(
    val version: Int = 2,
    val createdAt: Long = System.currentTimeMillis(),
    val diaries: List<Diary>,
    val preferences: Preferences,
) {
    fun validate() {
        require(
            version == 2 &&
                diaries.size <= 100_000 &&
                diaries.map { it.id }.distinct().size == diaries.size
        )
        preferences.validate()
        diaries.forEach { it.validate() }
        val files = diaries.flatMap { it.media }.flatMap { it.files }
        require(files.distinct().size == files.size)
    }
}

fun safeFilename(name: String) =
    Regex("^[a-zA-Z0-9][a-zA-Z0-9._-]{0,127}$").matches(name) && !name.contains("..")

const val MEDIA_LIMIT = "미디어는 10개·300MB, 영상은 3개·각 30초·합계 60초까지 가능합니다."
