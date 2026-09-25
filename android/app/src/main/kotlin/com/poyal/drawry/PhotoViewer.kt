package com.poyal.drawry

import android.graphics.Bitmap
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.pager.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.poyal.drawry.core.*
import com.poyal.drawry.data.MediaStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

@Composable
fun PhotoViewer(
    model: AppModel,
    media: List<Media>,
    initial: Int,
    dismiss: () -> Unit,
    play: (Media) -> Unit,
) {
    val pager = rememberPagerState(initialPage = initial, pageCount = { media.size })
    Dialog(
        onDismissRequest = dismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false),
    ) {
        Column(Modifier.fillMaxSize().background(Color.Black).systemBarsPadding()) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                TextButton(onClick = dismiss) { Text("닫기", color = Color.White) }
                Text(
                    "${pager.currentPage+1} / ${media.size}",
                    Modifier.padding(16.dp),
                    color = Color.White,
                )
            }
            HorizontalPager(pager, Modifier.weight(1f)) { index ->
                val item = media[index]
                var loadFailed by remember(item.id, item.rendered) { mutableStateOf(false) }
                val bitmap by
                    produceState<Bitmap?>(null, item.id, item.rendered) {
                        value =
                            runCatching {
                                    withContext(Dispatchers.IO) {
                                        MediaStore.decode(
                                            model.media.clearFile(
                                                item,
                                                thumbnail = item.kind == "video",
                                            ),
                                            2560,
                                        )
                                    }
                                }
                                .getOrElse {
                                    loadFailed = true
                                    null
                                }
                    }
                Column(Modifier.fillMaxSize()) {
                    if (bitmap == null) {
                        Box(
                            Modifier.weight(1f).fillMaxWidth(),
                            contentAlignment = androidx.compose.ui.Alignment.Center,
                        ) {
                            if (loadFailed)
                                Text(
                                    "사진을 열지 못했습니다. 닫은 뒤 다시 시도해 주세요.",
                                    color = Color.White,
                                    modifier = Modifier.padding(24.dp),
                                )
                            else CircularProgressIndicator(color = Color.White)
                        }
                    }
                    bitmap?.let { photo ->
                        AndroidView(
                            factory = { InkCanvasView(it) },
                            modifier = Modifier.weight(1f).fillMaxWidth(),
                            update = { view ->
                                view.bitmap = photo
                                view.geometry =
                                    InkGeometry(
                                        photo.width.toDouble(),
                                        photo.height.toDouble(),
                                        0,
                                        false,
                                    )
                                view.mode = "view"
                                view.contentDescription = "일기 사진 · 두 손가락으로 확대, 좌우로 넘기기"
                                view.invalidate()
                            },
                        )
                    }
                    if (item.kind == "video")
                        TextButton(onClick = { play(item) }) { Text("영상 재생", color = Color.White) }
                }
            }
            Text(
                "두 손가락으로 확대 · 좌우로 넘기기",
                Modifier.padding(16.dp),
                color = Color.LightGray,
                style = MaterialTheme.typography.bodySmall,
            )
        }
    }
}
