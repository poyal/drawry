package com.poyal.drawry.data

import android.content.Context
import android.graphics.*
import android.media.MediaMetadataRetriever
import android.net.Uri
import androidx.exifinterface.media.ExifInterface
import com.poyal.drawry.core.*
import java.io.File
import java.util.Base64
import java.util.UUID
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runInterruptible
import kotlinx.coroutines.withContext

class MediaStore(private val context: Context, private val vault: Vault) {
    private val viewingLock = Any()
    @Volatile private var viewingAllowed = true

    fun allowViewing() {
        viewingAllowed = true
    }

    fun suspendViewing() {
        viewingAllowed = false
    }

    private val viewDir
        get() = File(vault.cache, "view").apply { mkdirs() }

    suspend fun import(uri: Uri, video: Boolean, preserveOriginal: Boolean): Media =
        runInterruptible(Dispatchers.IO) {
            val temporary = File(vault.cache, "import-${UUID.randomUUID()}")
            val created = mutableListOf<File>()
            try {
                context.contentResolver.openInputStream(uri)!!.use { input ->
                    temporary.outputStream().use { out ->
                        val buffer = ByteArray(1024 * 1024)
                        var length = 0L
                        while (true) {
                            val n = input.read(buffer)
                            if (n < 0) break
                            length += n
                            require(length <= 300L * 1024 * 1024) { MEDIA_LIMIT }
                            out.write(buffer, 0, n)
                        }
                    }
                }
                require(temporary.length() > 0)
                require(vault.root.usableSpace > temporary.length() * 2 + 32L * 1024 * 1024) {
                    "저장 공간이 부족합니다."
                }
                val key = ChunkCipher.random(32)
                val id = UUID.randomUUID().toString()
                var duration = 0L
                val image =
                    if (video)
                        withRetriever { retriever ->
                            retriever.setDataSource(temporary.path)
                            duration =
                                retriever
                                    .extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                                    ?.toLong() ?: 0
                            require(duration in 1..30_000) { MEDIA_LIMIT }
                            requireNotNull(retriever.getFrameAtTime(0)) { "영상 미리 보기를 만들 수 없습니다." }
                        }
                    else decode(temporary, 2560)
                val original =
                    "$id.${if(video) "mp4" else if(preserveOriginal) "source" else "jpg"}.dry"
                val thumbnail = "$id.thumb.dry"
                val normalized = File(vault.cache, "$id.jpg")
                val thumb = File(vault.cache, "$id.thumb.jpg")
                try {
                    if (!video && !preserveOriginal) writeJpeg(image, normalized)
                    val thumbnailBitmap = scale(image, 480)
                    writeJpeg(thumbnailBitmap, thumb)
                    if (thumbnailBitmap !== image) thumbnailBitmap.recycle()
                    val originalFile = File(vault.mediaDirectory, original)
                    created += originalFile
                    ChunkCipher.encrypt(
                        if (video || preserveOriginal) temporary else normalized,
                        originalFile,
                        key,
                        original,
                    )
                    val thumbFile = File(vault.mediaDirectory, thumbnail)
                    created += thumbFile
                    ChunkCipher.encrypt(thumb, thumbFile, key, thumbnail)
                } finally {
                    normalized.delete()
                    thumb.delete()
                    image.recycle()
                }
                Media(
                    id = id,
                    kind = if (video) "video" else "image",
                    mimeType =
                        if (video) context.contentResolver.getType(uri) ?: "video/mp4"
                        else if (preserveOriginal)
                            context.contentResolver.getType(uri) ?: "image/jpeg"
                        else "image/jpeg",
                    key = Base64.getEncoder().encodeToString(key),
                    original = original,
                    thumbnail = thumbnail,
                    byteLength = temporary.length(),
                    durationMillis = duration,
                )
            } catch (e: Exception) {
                created.forEach { it.delete() }
                throw e
            } finally {
                temporary.delete()
                if (
                    uri.authority == "${context.packageName}.files" &&
                        uri.path?.startsWith("/camera/") == true
                ) {
                    context.contentResolver.delete(uri, null, null)
                }
            }
        }

    suspend fun clearFile(
        media: Media,
        thumbnail: Boolean = false,
        original: Boolean = false,
    ): File =
        withContext(Dispatchers.IO) {
            synchronized(viewingLock) {
                check(viewingAllowed) { "앱에 복귀한 뒤 다시 열어 주세요." }
                val name =
                    if (thumbnail) media.thumbnail
                    else if (original) media.original else media.rendered ?: media.original
                val file = File(viewDir, name.removeSuffix(".dry"))
                if (!file.exists()) {
                    val partial = File(viewDir, "${UUID.randomUUID()}.part")
                    ChunkCipher.decrypt(
                        File(vault.mediaDirectory, name),
                        partial,
                        Base64.getDecoder().decode(media.key),
                        name,
                    )
                    if (!partial.renameTo(file)) {
                        partial.delete()
                        require(file.exists())
                    }
                }
                if (!viewingAllowed) {
                    file.delete()
                    error("앱에 복귀한 뒤 다시 열어 주세요.")
                }
                file
            }
        }

    suspend fun edit(media: Media, recipe: EditRecipe): Media =
        withContext(Dispatchers.IO) {
            val bitmap = decode(clearFile(media, original = true), 2560)
            val rendered = render(bitmap, recipe)
            if (rendered !== bitmap) bitmap.recycle()
            saveRendered(media, rendered, recipe)
        }

    suspend fun frame(media: Media, millis: Long): Media =
        withContext(Dispatchers.IO) {
            val original = clearFile(media, original = true)
            val image = withRetriever { r ->
                r.setDataSource(original.path)
                requireNotNull(
                    r.getFrameAtTime(millis * 1000, MediaMetadataRetriever.OPTION_CLOSEST)
                )
            }
            saveRendered(media, image, media.edit).copy(representativeMillis = millis)
        }

    suspend fun previewFrame(media: Media, millis: Long): Bitmap =
        withContext(Dispatchers.IO) {
            val source = clearFile(media, original = true)
            withRetriever { r ->
                r.setDataSource(source.path)
                scale(
                    requireNotNull(
                        r.getFrameAtTime(millis * 1000, MediaMetadataRetriever.OPTION_CLOSEST)
                    ),
                    720,
                )
            }
        }

    private fun saveRendered(media: Media, image: Bitmap, recipe: EditRecipe): Media {
        val id = UUID.randomUUID().toString()
        val rendered = "$id.render.jpg.dry"
        val thumb = "$id.thumb.dry"
        val plain = File(vault.cache, "$id.jpg")
        val thumbnail = File(vault.cache, "$id.thumb.jpg")
        val key = Base64.getDecoder().decode(media.key)
        var success = false
        try {
            writeJpeg(image, plain)
            val small = scale(image, 480)
            writeJpeg(small, thumbnail)
            if (small !== image) small.recycle()
            ChunkCipher.encrypt(plain, File(vault.mediaDirectory, rendered), key, rendered)
            ChunkCipher.encrypt(thumbnail, File(vault.mediaDirectory, thumb), key, thumb)
            success = true
            return media.copy(rendered = rendered, thumbnail = thumb, edit = recipe)
        } finally {
            if (!success) {
                File(vault.mediaDirectory, rendered).delete()
                File(vault.mediaDirectory, thumb).delete()
            }
            plain.delete()
            thumbnail.delete()
            image.recycle()
        }
    }

    suspend fun share(diary: Diary, prefs: Preferences): File =
        withContext(Dispatchers.IO) {
            val media = diary.media.first()
            val photo =
                decode(
                    clearFile(media, thumbnail = media.kind == "video" && media.rendered == null),
                    1600,
                )
            val width = 1080
            val height =
                when (prefs.shareRatio) {
                    "1:1" -> 1080
                    "9:16" -> 1920
                    else -> 1350
                }
            val result = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(result)
            val dark = prefs.shareTheme == "dark"
            canvas.drawColor(if (dark) Color.rgb(33, 30, 27) else Color.rgb(247, 243, 234))
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { isFilterBitmap = true }
            paint.color = if (dark) Color.rgb(41, 37, 33) else Color.rgb(255, 252, 245)
            canvas.drawRoundRect(24f, 24f, width - 24f, height - 24f, 16f, 16f, paint)
            val imageHeight = (height * .62).toInt()
            val fit = minOf((width - 96f) / photo.width, (imageHeight - 64f) / photo.height)
            val photoWidth = photo.width * fit
            val photoHeight = photo.height * fit
            canvas.drawBitmap(
                photo,
                null,
                RectF(
                    (width - photoWidth) / 2,
                    48f + (imageHeight - 64 - photoHeight) / 2,
                    (width + photoWidth) / 2,
                    48f + (imageHeight - 64 + photoHeight) / 2,
                ),
                paint,
            )
            photo.recycle()
            paint.color = if (dark) Color.rgb(243, 237, 226) else Color.rgb(48, 44, 41)
            paint.textSize = 34f
            val lines =
                buildList {
                        if ("date" in prefs.shareFields) add(diary.entryDate)
                        if ("headline" in prefs.shareFields) add(diary.headline)
                        if ("mood" in prefs.shareFields) add(diary.mood)
                        if ("weather" in prefs.shareFields)
                            add(
                                listOf(
                                        diary.weather.condition,
                                        diary.weather.temperature?.let { "$it°C" }.orEmpty(),
                                    )
                                    .filter { it.isNotEmpty() }
                                    .joinToString(" ")
                            )
                        if ("body" in prefs.shareFields) add(diary.body)
                    }
                    .filter { it.isNotBlank() }
            val textPaint = android.text.TextPaint(paint)
            val content = lines.joinToString("\n")
            val available = height - imageHeight - 120
            val layout =
                android.text.StaticLayout.Builder.obtain(
                        content,
                        0,
                        content.length,
                        textPaint,
                        width - 96,
                    )
                    .setIncludePad(false)
                    .setLineSpacing(10f, 1f)
                    .setMaxLines((available / 50).coerceAtLeast(1))
                    .setEllipsize(android.text.TextUtils.TruncateAt.END)
                    .build()
            canvas.save()
            canvas.translate(48f, imageHeight + 24f)
            canvas.clipRect(0, 0, width - 96, available)
            layout.draw(canvas)
            canvas.restore()
            if (prefs.watermark) {
                paint.textSize = 24f
                canvas.drawText("Drawry", 40f, height - 32f, paint)
            }
            File(vault.cache, "Drawry-share-${System.currentTimeMillis()}.jpg").also {
                writeJpeg(result, it)
                result.recycle()
            }
        }

    fun clearViewing() {
        synchronized(viewingLock) {
            if (!viewingAllowed) File(vault.cache, "view").deleteRecursively()
        }
    }

    companion object {
        private fun <T> withRetriever(block: (MediaMetadataRetriever) -> T): T {
            val retriever = MediaMetadataRetriever()
            try {
                return block(retriever)
            } finally {
                retriever.release()
            }
        }

        fun decode(file: File, maxSize: Int): Bitmap {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(file.path, bounds)
            require(bounds.outWidth > 0 && bounds.outHeight > 0) { "지원하지 않는 이미지입니다." }
            var sample = 1
            while (maxOf(bounds.outWidth, bounds.outHeight) / sample > maxSize * 2) sample *= 2
            val raw =
                requireNotNull(
                    BitmapFactory.decodeFile(
                        file.path,
                        BitmapFactory.Options().apply { inSampleSize = sample },
                    )
                )
            val orientation =
                runCatching {
                        ExifInterface(file)
                            .getAttributeInt(
                                ExifInterface.TAG_ORIENTATION,
                                ExifInterface.ORIENTATION_NORMAL,
                            )
                    }
                    .getOrDefault(1)
            val matrix =
                Matrix().apply {
                    when (orientation) {
                        2 -> setScale(-1f, 1f)
                        3 -> setRotate(180f)
                        4 -> setScale(1f, -1f)
                        5 -> {
                            setRotate(90f)
                            postScale(-1f, 1f)
                        }
                        6 -> setRotate(90f)
                        7 -> {
                            setRotate(270f)
                            postScale(-1f, 1f)
                        }
                        8 -> setRotate(270f)
                    }
                }
            val rotated = Bitmap.createBitmap(raw, 0, 0, raw.width, raw.height, matrix, true)
            if (rotated !== raw) raw.recycle()
            val result = scale(rotated, maxSize)
            if (result !== rotated) rotated.recycle()
            return result
        }

        fun scale(image: Bitmap, maxSize: Int): Bitmap {
            val factor = minOf(1.0, maxSize.toDouble() / maxOf(image.width, image.height))
            return if (factor == 1.0) image
            else
                Bitmap.createScaledBitmap(
                    image,
                    (image.width * factor).toInt().coerceAtLeast(1),
                    (image.height * factor).toInt().coerceAtLeast(1),
                    true,
                )
        }

        fun writeJpeg(image: Bitmap, file: File) {
            file.outputStream().use { check(image.compress(Bitmap.CompressFormat.JPEG, 90, it)) }
        }

        fun render(source: Bitmap, recipe: EditRecipe): Bitmap {
            recipe.validateInk()
            var current =
                Bitmap.createBitmap(
                    source,
                    0,
                    0,
                    source.width,
                    source.height,
                    Matrix().apply { postRotate(recipe.quarterTurns * 90f) },
                    true,
                )
            if (recipe.squareCrop) {
                val side = minOf(current.width, current.height)
                val cropped =
                    Bitmap.createBitmap(
                        current,
                        (current.width - side) / 2,
                        (current.height - side) / 2,
                        side,
                        side,
                    )
                if (current !== source && cropped !== current) current.recycle()
                current = cropped
            }
            val result = Bitmap.createBitmap(current.width, current.height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(result)
            val matrix = ColorMatrix()
            when (recipe.filter) {
                "mono" -> matrix.setSaturation(0f)
                "warm" -> matrix.setScale(1.1f, 1f, .9f, 1f)
                "cool" -> matrix.setScale(.9f, 1f, 1.1f, 1f)
            }
            canvas.drawBitmap(
                current,
                0f,
                0f,
                Paint(Paint.ANTI_ALIAS_FLAG).apply { colorFilter = ColorMatrixColorFilter(matrix) },
            )
            InkDrawing.draw(
                canvas,
                recipe.strokes,
                InkGeometry(
                    source.width.toDouble(),
                    source.height.toDouble(),
                    recipe.quarterTurns,
                    recipe.squareCrop,
                ),
                result.width.toFloat(),
                result.height.toFloat(),
            )
            recipe.overlays.forEach { overlay ->
                val paint =
                    Paint(Paint.ANTI_ALIAS_FLAG).apply {
                        color =
                            runCatching { Color.parseColor(overlay.color) }
                                .getOrDefault(Color.WHITE)
                        textSize = (overlay.size * result.width).toFloat()
                        textAlign = Paint.Align.CENTER
                        setShadowLayer(3f, 0f, 2f, Color.BLACK)
                    }
                canvas.drawText(
                    overlay.text,
                    (overlay.x * result.width).toFloat(),
                    (overlay.y * result.height).toFloat(),
                    paint,
                )
            }
            if (current !== source) current.recycle()
            return result
        }
    }
}
