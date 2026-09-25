package com.poyal.drawry

import android.Manifest
import android.content.pm.PackageManager
import android.net.Uri
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.video.FileOutputOptions
import androidx.camera.video.Recording
import androidx.camera.video.VideoRecordEvent
import androidx.camera.view.CameraController
import androidx.camera.view.LifecycleCameraController
import androidx.camera.view.PreviewView
import androidx.camera.view.video.AudioConfig
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import androidx.lifecycle.compose.LocalLifecycleOwner
import java.io.File
import java.util.UUID

@Composable
fun CaptureScreen(
    video: Boolean,
    onClose: () -> Unit,
    onCapture: (Uri) -> Unit,
    onError: (String) -> Unit,
) {
    val context = LocalContext.current
    val lifecycle = LocalLifecycleOwner.current
    var allowed by remember {
        mutableStateOf(
            ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) ==
                PackageManager.PERMISSION_GRANTED
        )
    }
    val request =
        rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) {
            allowed = it[Manifest.permission.CAMERA] == true
        }
    val permissions =
        if (video) arrayOf(Manifest.permission.CAMERA, Manifest.permission.RECORD_AUDIO)
        else arrayOf(Manifest.permission.CAMERA)
    LaunchedEffect(Unit) {
        if (
            !allowed ||
                video &&
                    ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) !=
                        PackageManager.PERMISSION_GRANTED
        )
            request.launch(permissions)
    }
    val controller = remember {
        LifecycleCameraController(context).apply {
            setEnabledUseCases(
                if (video) CameraController.VIDEO_CAPTURE else CameraController.IMAGE_CAPTURE
            )
        }
    }
    var recording by remember { mutableStateOf<Recording?>(null) }
    var capturing by remember { mutableStateOf(false) }
    var discarded by remember { mutableStateOf(false) }
    var seconds by remember { mutableIntStateOf(0) }
    val output = remember {
        File(
            File(context.cacheDir, "camera").apply { mkdirs() },
            "${UUID.randomUUID()}.${if(video) "mp4" else "jpg"}",
        )
    }
    fun close() {
        discarded = true
        recording?.stop()
        if (recording == null) output.delete()
        onClose()
    }
    BackHandler { close() }
    DisposableEffect(controller, allowed) {
        if (allowed)
            runCatching { controller.bindToLifecycle(lifecycle) }
                .onFailure { onError("카메라를 사용할 수 없습니다.") }
        onDispose {
            recording?.stop()
            controller.unbind()
        }
    }
    fun complete() {
        if (discarded) output.delete()
        else onCapture(FileProvider.getUriForFile(context, "${context.packageName}.files", output))
    }
    Column(Modifier.fillMaxSize().safeDrawingPadding()) {
        TextButton(onClick = { close() }) { Text("촬영 취소") }
        if (allowed) {
            AndroidView(
                factory = { PreviewView(it).apply { this.controller = controller } },
                modifier = Modifier.weight(1f).fillMaxWidth(),
            )
            if (video) Text("${seconds}초 / 30초", Modifier.padding(16.dp))
            Button(
                enabled = !capturing || recording != null,
                modifier = Modifier.fillMaxWidth().padding(16.dp),
                onClick = {
                    if (recording != null) {
                        recording?.stop()
                        return@Button
                    }
                    if (
                        ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) !=
                            PackageManager.PERMISSION_GRANTED
                    ) {
                        request.launch(permissions)
                        return@Button
                    }
                    capturing = true
                    try {
                        val executor = ContextCompat.getMainExecutor(context)
                        if (video) {
                            val audio =
                                if (
                                    ContextCompat.checkSelfPermission(
                                        context,
                                        Manifest.permission.RECORD_AUDIO,
                                    ) == PackageManager.PERMISSION_GRANTED
                                )
                                    AudioConfig.create(true)
                                else AudioConfig.AUDIO_DISABLED
                            recording =
                                controller.startRecording(
                                    FileOutputOptions.Builder(output)
                                        .setDurationLimitMillis(30_000)
                                        .setFileSizeLimit(300L * 1024 * 1024)
                                        .build(),
                                    audio,
                                    executor,
                                ) { event ->
                                    when (event) {
                                        is VideoRecordEvent.Status ->
                                            seconds =
                                                (event.recordingStats.recordedDurationNanos /
                                                        1_000_000_000)
                                                    .toInt()
                                        is VideoRecordEvent.Finalize -> {
                                            recording = null
                                            capturing = false
                                            if (
                                                event.hasError() &&
                                                    event.error !in
                                                        listOf(
                                                            VideoRecordEvent.Finalize
                                                                .ERROR_DURATION_LIMIT_REACHED,
                                                            VideoRecordEvent.Finalize
                                                                .ERROR_FILE_SIZE_LIMIT_REACHED,
                                                        )
                                            ) {
                                                output.delete()
                                                if (!discarded) onError("영상을 저장하지 못했습니다.")
                                            } else complete()
                                        }
                                        else -> Unit
                                    }
                                }
                        } else
                            controller.takePicture(
                                ImageCapture.OutputFileOptions.Builder(output).build(),
                                executor,
                                object : ImageCapture.OnImageSavedCallback {
                                    override fun onImageSaved(
                                        results: ImageCapture.OutputFileResults
                                    ) {
                                        capturing = false
                                        complete()
                                    }

                                    override fun onError(exception: ImageCaptureException) {
                                        capturing = false
                                        output.delete()
                                        onError("사진을 저장하지 못했습니다.")
                                    }
                                },
                            )
                    } catch (e: Exception) {
                        capturing = false
                        output.delete()
                        onError("카메라를 시작하지 못했습니다.")
                    }
                },
            ) {
                Text(if (recording != null) "녹화 완료" else if (video) "영상 녹화" else "사진 촬영")
            }
        } else {
            Text("촬영하려면 카메라 권한이 필요합니다. 권한 없이 보관함의 사진은 사용할 수 있어요.", Modifier.padding(24.dp))
            Button(onClick = { request.launch(permissions) }) { Text("카메라 권한 요청") }
        }
    }
}
