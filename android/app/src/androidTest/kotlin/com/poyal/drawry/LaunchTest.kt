package com.poyal.drawry

import android.content.Intent
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.By
import androidx.test.uiautomator.UiDevice
import androidx.test.uiautomator.Until
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class LaunchTest {
    @Test
    fun feedLayoutLivesInSettingsAndPersists() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        val device = UiDevice.getInstance(instrumentation)
        fun launch() {
            context.startActivity(
                context.packageManager
                    .getLaunchIntentForPackage(context.packageName)!!
                    .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK or Intent.FLAG_ACTIVITY_NEW_TASK)
            )
            assertTrue(
                device.wait(
                    { it.hasObject(By.text("내 기록 시작하기")) || it.hasObject(By.desc("일기 작성")) },
                    15_000,
                )
            )
            device.findObject(By.text("내 기록 시작하기"))?.click()
            assertTrue(device.wait(Until.hasObject(By.desc("일기 작성")), 10_000))
        }
        fun settings() {
            device.wait(Until.findObject(By.text("설정")), 5_000)!!.click()
            assertTrue(device.wait(Until.hasObject(By.text("기록 보기 방식")), 5_000))
        }
        launch()
        listOf("카드", "2열", "3열").forEach { assertFalse(device.hasObject(By.text(it))) }
        settings()
        val labels = listOf("카드", "2열", "3열")
        fun selected(label: String) = By.checked(true).hasDescendant(By.text(label))
        val original = labels.single { device.hasObject(selected(it)) }
        try {
            for (label in labels) {
                device.findObject(By.text(label)).click()
                assertTrue(device.wait(Until.hasObject(selected(label)), 5_000))
                device.wait(Until.gone(By.text("안전하게 처리하고 있어요")), 5_000)
                device.findObject(By.text("기록")).click()
                assertTrue(device.wait(Until.hasObject(By.desc("일기 작성")), 5_000))
                labels.forEach { assertFalse(device.hasObject(By.text(it))) }
                launch()
                settings()
                assertTrue(device.hasObject(selected(label)))
            }
        } finally {
            device.findObject(By.text(original))?.click()
            device.wait(Until.hasObject(selected(original)), 5_000)
            device.wait(Until.gone(By.text("안전하게 처리하고 있어요")), 5_000)
            device.findObject(By.text("기록"))?.click()
        }
    }

    @Test
    fun onboardingAndNativeEditor() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        context.startActivity(
            context.packageManager
                .getLaunchIntentForPackage(context.packageName)!!
                .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK or Intent.FLAG_ACTIVITY_NEW_TASK)
        )
        val device = UiDevice.getInstance(instrumentation)
        device.wait(Until.findObject(By.text("내 기록 시작하기")), 10_000)?.click()
        assertTrue(device.wait(Until.hasObject(By.desc("일기 작성")), 10_000))
        device.findObject(By.desc("일기 작성")).click()
        assertTrue(device.wait(Until.hasObject(By.text("보관함")), 5_000))
        assertTrue(device.hasObject(By.text("사진 촬영")))
        device.pressBack()
        device.wait(Until.findObject(By.text("초안 폐기")), 5_000)?.click()
        assertTrue(device.wait(Until.hasObject(By.text("캘린더")), 5_000))
        device.findObject(By.text("캘린더")).click()
        assertTrue(device.wait(Until.hasObject(By.text("오늘")), 5_000))
    }
}
