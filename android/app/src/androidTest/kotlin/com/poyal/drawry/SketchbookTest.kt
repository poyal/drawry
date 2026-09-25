package com.poyal.drawry

import android.graphics.*
import android.net.Uri
import android.view.WindowManager
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.*
import com.poyal.drawry.core.*
import com.poyal.drawry.data.MediaStore
import com.poyal.drawry.data.Vault
import java.io.File
import java.util.UUID
import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class SketchbookTest {
    @Test
    fun inkRenderingAcrossRotationAndCrop() {
        val source =
            Bitmap.createBitmap(400, 300, Bitmap.Config.ARGB_8888).apply { eraseColor(Color.WHITE) }
        val stroke =
            InkStroke(
                color = "#C54C4C",
                width = .03,
                points = listOf(InkPoint(.25, .25), InkPoint(.75, .25)),
            )
        for (turn in 0..3) for (crop in listOf(false, true)) {
            val recipe =
                EditRecipe(
                    version = 2,
                    quarterTurns = turn,
                    squareCrop = crop,
                    strokes = listOf(stroke),
                )
            val rendered = MediaStore.render(source, recipe)
            val g = InkGeometry(400.0, 300.0, turn, crop)
            val p = g.project(InkPoint(.5, .25))
            assertEquals(g.width.toInt(), rendered.width)
            assertEquals(g.height.toInt(), rendered.height)
            val pixel =
                rendered.getPixel(
                    (p.x * rendered.width).toInt().coerceIn(0, rendered.width - 1),
                    (p.y * rendered.height).toInt().coerceIn(0, rendered.height - 1),
                )
            assertTrue(
                "Ink remains aligned: turn=$turn crop=$crop",
                Color.red(pixel) > Color.green(pixel) * 1.5,
            )
            rendered.recycle()
        }
        assertEquals(Color.WHITE, source.getPixel(200, 75))
        source.recycle()
    }

    @Test
    fun inkSaveDraftShareAndBackup() = runBlocking {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val vault = Vault(context, "ink-test-${UUID.randomUUID()}")
        try {
            vault.initialize()
            val store = MediaStore(context, vault)
            val plain = File(vault.cache, "source.jpg")
            val photo =
                Bitmap.createBitmap(600, 900, Bitmap.Config.ARGB_8888).apply {
                    eraseColor(Color.WHITE)
                }
            MediaStore.writeJpeg(photo, plain)
            photo.recycle()
            val media = store.import(Uri.fromFile(plain), false, false)
            val recipe =
                EditRecipe(
                    version = 2,
                    strokes = listOf(InkStroke(points = listOf(InkPoint(.3, .3), InkPoint(.7, .7)))),
                )
            val edited = store.edit(media, recipe)
            val diary =
                Diary(headline = "낙서 저장", body = "한글 긴 본문 🙂 ".repeat(80), media = listOf(edited))
            vault.draft(diary)
            assertEquals(recipe, vault.draft()!!.media.single().edit)
            vault.save(diary)
            assertEquals(recipe, vault.diaries().single().media.single().edit)
            for (ratio in listOf("1:1", "4:5", "9:16")) {
                val image =
                    BitmapFactory.decodeFile(
                        store.share(diary, Preferences(shareRatio = ratio)).path
                    )
                assertEquals(1080, image.width)
                assertEquals(
                    when (ratio) {
                        "1:1" -> 1080
                        "9:16" -> 1920
                        else -> 1350
                    },
                    image.height,
                )
                image.recycle()
            }
            val backup = vault.export("sketchbook-test-pass")
            val pending = vault.inspect(backup, "sketchbook-test-pass", null)
            vault.restore(pending.first, pending.second, true)
            assertEquals(recipe, vault.diaries().single().media.single().edit)
        } finally {
            vault.erase()
        }
    }

    /** Never seed or disable capture protection on a user's emulator. */
    @Test
    fun sketchbookScreensAndDrawingOnDedicatedQaDevice(): Unit = runBlocking {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val device = UiDevice.getInstance(instrumentation)
        assumeTrue(
            device.executeShellCommand("getprop ro.boot.qemu.avd_name").trim() ==
                "drawry-sketchbook-qa"
        )
        val context = instrumentation.targetContext
        val vault = Vault(context)
        vault.initialize()
        val stableId = "00000000-0000-4000-8000-000000000042"
        if (vault.diaries().none { it.id == stableId }) {
            val store = MediaStore(context, vault)
            val images =
                listOf(800 to 1000, 1200 to 700).mapIndexed { index, (w, h) ->
                    val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
                    val canvas = Canvas(bitmap)
                    canvas.drawColor(Color.rgb(218, 230, 219))
                    val p = Paint(Paint.ANTI_ALIAS_FLAG)
                    p.color = Color.rgb(235, 197, 127)
                    canvas.drawCircle(w * .73f, h * .25f, w * .10f, p)
                    p.color = Color.rgb(131, 159, 133)
                    val hill =
                        Path().apply {
                            moveTo(0f, h * .68f)
                            quadTo(w * .35f, h * .24f, w.toFloat(), h * .75f)
                            lineTo(w.toFloat(), h.toFloat())
                            lineTo(0f, h.toFloat())
                            close()
                        }
                    canvas.drawPath(hill, p)
                    p.color = Color.rgb(76, 111, 94)
                    canvas.drawOval(-w * .3f, h * .70f, w * .8f, h * 1.35f, p)
                    p.color = Color.WHITE
                    p.textSize = 24f
                    canvas.drawText("DRAWRY QA · SAMPLE ${index+1}", 36f, h - 36f, p)
                    val file = File(vault.cache, "sample-$index.jpg")
                    MediaStore.writeJpeg(bitmap, file)
                    bitmap.recycle()
                    store.import(Uri.fromFile(file), false, false)
                }
            vault.save(
                Diary(
                    id = stableId,
                    headline = "천천히 걸었던 오후",
                    body = "햇살이 좋아서 조금 더 걸었다.\n사진 한 장과 짧은 메모로 남기는 오늘의 페이지.",
                    mood = "😌",
                    media = images,
                )
            )
        }
        val previousStrokeCount =
            vault.diaries().first { it.id == stableId }.media.first().edit.strokes.size
        vault.preferences(vault.preferences().copy(onboarded = true, layout = 1))
        vault.close()
        ActivityScenario.launch(MainActivity::class.java).use { scenario ->
            assertTrue(device.wait(Until.hasObject(By.text("Drawry")), 15_000))
            // Only QA-generated content is ever captured. The shipping activity always sets
            // FLAG_SECURE.
            scenario.onActivity { it.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE) }
            fun capture(name: String) {
                device.waitForIdle()
                val dir = File(context.getExternalFilesDir(null), "qa-screens").apply { mkdirs() }
                device.takeScreenshot(File(dir, "$name.png"))
            }
            capture("01-feed")
            device.findObject(By.text("캘린더")).click()
            assertTrue(device.wait(Until.hasObject(By.text("오늘")), 5_000))
            capture("04-calendar")
            device.findObject(By.text("설정")).click()
            assertTrue(device.wait(Until.hasObject(By.text("기록 보기 방식")), 5_000))
            capture("05-settings")
            device.findObject(By.text("기록")).click()
            fun findByScrolling(selector: BySelector): UiObject2 {
                repeat(5) {
                    device.wait(Until.findObject(selector), 1_000)?.let {
                        return it
                    }
                    device.swipe(
                        device.displayWidth / 2,
                        device.displayHeight * 3 / 4,
                        device.displayWidth / 2,
                        device.displayHeight / 3,
                        20,
                    )
                }
                error("Missing UI element: $selector")
            }
            findByScrolling(By.text("천천히 걸었던 오후")).click()
            assertTrue(device.wait(Until.hasObject(By.desc("수정")), 5_000))
            device.wait(Until.findObject(By.desc("일기 미디어")), 5_000)!!.click()
            assertTrue(device.wait(Until.hasObject(By.text("1 / 2")), 5_000))
            capture("06-photo-viewer")
            device.findObject(By.text("닫기")).click()
            device.findObject(By.desc("수정")).click()
            assertTrue(device.wait(Until.hasObject(By.text("저장")), 5_000))
            capture("02-editor")
            findByScrolling(By.desc("2번째 사진 선택")).click()
            assertTrue(device.wait(Until.hasObject(By.text("2 / 2 · 옆으로 넘겨 보세요")), 5_000))
            device.findObject(By.desc("1번째 사진 선택")).click()
            assertTrue(device.wait(Until.hasObject(By.text("1 / 2 · 옆으로 넘겨 보세요")), 5_000))
            findByScrolling(By.text("꾸미기")).click()
            assertTrue(device.wait(Until.hasObject(By.text("낙서")), 5_000))
            device.findObject(By.text("낙서")).click()
            val drawing = device.wait(Until.findObject(By.descContains("사진 캔버스")), 5_000)!!
            val rect = drawing.visibleBounds
            device.swipe(
                rect.centerX() - 80,
                rect.centerY(),
                rect.centerX() + 80,
                rect.centerY() + 80,
                20,
            )
            assertTrue(device.wait(Until.hasObject(By.text("실행 취소").enabled(true)), 5_000))
            device.findObject(By.text("실행 취소")).click()
            device.findObject(By.text("다시 실행")).click()
            capture("03-ink-tools")
            device.findObject(By.text("편집 적용")).click()
            assertTrue(device.wait(Until.hasObject(By.text("저장")), 10_000))
            device.wait(Until.gone(By.text("안전하게 처리하고 있어요")), 10_000)
            device.findObject(By.text("저장")).click()
            assertTrue(device.wait(Until.gone(By.text("저장")), 10_000))
        }
        val reopened = Vault(context)
        try {
            reopened.initialize()
            assertEquals(
                previousStrokeCount + 1,
                reopened.diaries().first { it.id == stableId }.media.first().edit.strokes.size,
            )
        } finally {
            reopened.close()
        }
    }
}
