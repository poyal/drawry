package com.poyal.drawry

import android.content.Intent
import android.os.Bundle
import android.os.SystemClock
import android.view.WindowManager
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.lifecycleScope
import java.io.File
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class MainActivity : FragmentActivity() {
    private val model: AppModel by viewModels()
    private var leftAt = 0L

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        setContent { DrawryApp(model, ::authenticate, ::share) }
    }

    override fun onStop() {
        leftAt = SystemClock.elapsedRealtime()
        model.background()
        super.onStop()
    }

    override fun onStart() {
        super.onStart()
        if (
            leftAt > 0 &&
                SystemClock.elapsedRealtime() - leftAt >=
                    model.state.value.preferences.graceSeconds * 1000L
        )
            model.lock()
        model.foreground()
    }

    private fun authenticate(success: () -> Unit) {
        val authenticators =
            BiometricManager.Authenticators.BIOMETRIC_WEAK or
                BiometricManager.Authenticators.DEVICE_CREDENTIAL
        if (
            BiometricManager.from(this).canAuthenticate(authenticators) !=
                BiometricManager.BIOMETRIC_SUCCESS
        ) {
            model.error("기기 설정에서 화면 잠금 또는 생체 인증을 먼저 설정해 주세요.")
            return
        }
        val prompt =
            BiometricPrompt(
                this,
                ContextCompat.getMainExecutor(this),
                object : BiometricPrompt.AuthenticationCallback() {
                    override fun onAuthenticationSucceeded(
                        result: BiometricPrompt.AuthenticationResult
                    ) {
                        success()
                    }

                    override fun onAuthenticationError(code: Int, message: CharSequence) {
                        model.error(message.toString())
                    }
                },
            )
        prompt.authenticate(
            BiometricPrompt.PromptInfo.Builder()
                .setTitle("Drawry 잠금 해제")
                .setSubtitle("기기 인증으로 기록을 보호합니다.")
                .setAllowedAuthenticators(authenticators)
                .build()
        )
    }

    private fun share(file: File) {
        val uri = FileProvider.getUriForFile(this, "$packageName.files", file)
        startActivity(
            Intent.createChooser(
                Intent(Intent.ACTION_SEND).apply {
                    type =
                        if (file.extension == "drawry") "application/octet-stream" else "image/jpeg"
                    putExtra(Intent.EXTRA_STREAM, uri)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    clipData = android.content.ClipData.newRawUri(file.name, uri)
                },
                "Drawry 공유",
            )
        )
        lifecycleScope.launch {
            delay(10 * 60 * 1000L)
            revokeUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            file.delete()
        }
    }
}
