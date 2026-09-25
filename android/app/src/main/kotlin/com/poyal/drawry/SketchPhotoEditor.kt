package com.poyal.drawry

import android.graphics.Bitmap
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.poyal.drawry.core.*
import com.poyal.drawry.data.MediaStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

@Composable
fun SketchPhotoEditor(
    model: AppModel,
    item: Media,
    dismiss: () -> Unit,
    save: (EditRecipe) -> Unit,
) {
    var recipe by remember { mutableStateOf(item.edit) }
    val undo = remember { mutableStateListOf<EditRecipe>() }
    val redo = remember { mutableStateListOf<EditRecipe>() }
    var tool by remember { mutableStateOf("사진") }
    var erasing by remember { mutableStateOf(false) }
    var inkColor by remember { mutableStateOf("#302C29") }
    var width by remember { mutableDoubleStateOf(.006) }
    var text by remember { mutableStateOf("") }
    var selected by remember { mutableIntStateOf(-1) }
    var notice by remember { mutableStateOf<String?>(null) }
    fun change(next: EditRecipe) {
        if (next == recipe) return
        undo += recipe
        if (undo.size > 100) undo.removeAt(0)
        redo.clear()
        recipe = next
    }
    fun add(value: String) {
        if (recipe.overlays.size >= 100) {
            notice = "텍스트·스티커는 100개까지 넣을 수 있어요."
            return
        }
        change(recipe.copy(overlays = recipe.overlays + Overlay(text = value)))
        selected = recipe.overlays.lastIndex
    }
    val original by
        produceState<Bitmap?>(null, item.id) {
            value =
                runCatching {
                        withContext(Dispatchers.IO) {
                            MediaStore.decode(model.media.clearFile(item, original = true), 1200)
                        }
                    }
                    .getOrElse {
                        notice = "사진을 열지 못했습니다. 다시 시도해 주세요."
                        null
                    }
        }
    val baseRecipe = recipe.copy(strokes = emptyList(), overlays = emptyList())
    val base by
        produceState<Bitmap?>(null, original, baseRecipe) {
            value = null
            value =
                original?.let { withContext(Dispatchers.IO) { MediaStore.render(it, baseRecipe) } }
        }
    Dialog(
        onDismissRequest = dismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false),
    ) {
        Surface(Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
            Column(Modifier.systemBarsPadding().imePadding()) {
                Row(
                    Modifier.fillMaxWidth().padding(horizontal = 8.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    TextButton(onClick = dismiss) { Text("취소") }
                    SketchTitle("사진 꾸미기", Modifier.weight(1f), maxLines = 1)
                    TextButton(onClick = { save(recipe) }, enabled = base != null) { Text("편집 적용") }
                }
                Box(Modifier.weight(1f).fillMaxWidth().padding(horizontal = 16.dp)) {
                    if (base == null) CircularProgressIndicator()
                    else
                        AndroidView(
                            factory = { InkCanvasView(it) },
                            modifier = Modifier.fillMaxSize(),
                            update = { view ->
                                val g =
                                    InkGeometry(
                                        original!!.width.toDouble(),
                                        original!!.height.toDouble(),
                                        recipe.quarterTurns,
                                        recipe.squareCrop,
                                    )
                                if (
                                    view.geometry?.turns != g.turns ||
                                        view.geometry?.width != g.width ||
                                        view.geometry?.height != g.height
                                )
                                    view.resetViewport()
                                view.bitmap = base
                                view.geometry = g
                                view.recipe = recipe
                                view.mode =
                                    when (tool) {
                                        "낙서" -> if (erasing) "erase" else "pen"
                                        "글자" -> "text"
                                        else -> "view"
                                    }
                                view.color = inkColor
                                view.penWidth = width
                                view.onStroke = {
                                    change(recipe.copy(version = 2, strokes = recipe.strokes + it))
                                }
                                view.onErase = { id ->
                                    change(
                                        recipe.copy(
                                            strokes = recipe.strokes.filterNot { it.id == id }
                                        )
                                    )
                                }
                                view.onLimit = {
                                    notice = "사진 한 장에 256획·20,000점까지 그릴 수 있어요. 획을 지우고 이어 그려 주세요."
                                }
                                view.onPosition = { p ->
                                    if (selected in recipe.overlays.indices) {
                                        val list = recipe.overlays.toMutableList()
                                        list[selected] = list[selected].copy(x = p.x, y = p.y)
                                        change(recipe.copy(overlays = list))
                                    }
                                }
                                view.invalidate()
                            },
                        )
                }
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                    TextButton(
                        onClick = {
                            redo += recipe
                            recipe = undo.removeAt(undo.lastIndex)
                        },
                        enabled = undo.isNotEmpty(),
                    ) {
                        Text("실행 취소")
                    }
                    TextButton(
                        onClick = {
                            undo += recipe
                            recipe = redo.removeAt(redo.lastIndex)
                        },
                        enabled = redo.isNotEmpty(),
                    ) {
                        Text("다시 실행")
                    }
                }
                HorizontalDivider()
                Row(
                    Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.SpaceEvenly,
                ) {
                    listOf("사진", "필터", "글자", "낙서").forEach { label ->
                        FilterChip(
                            selected = tool == label,
                            onClick = { tool = label },
                            label = { Text(label) },
                        )
                    }
                }
                Column(
                    Modifier.fillMaxWidth()
                        .heightIn(min = 120.dp, max = 240.dp)
                        .verticalScroll(rememberScrollState())
                        .padding(horizontal = 20.dp, vertical = 8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    when (tool) {
                        "사진" -> {
                            Row {
                                TextButton(
                                    onClick = {
                                        change(
                                            recipe.copy(
                                                quarterTurns = (recipe.quarterTurns + 1) % 4
                                            )
                                        )
                                    }
                                ) {
                                    Text("90° 회전")
                                }
                                FilterChip(
                                    selected = recipe.squareCrop,
                                    onClick = {
                                        change(recipe.copy(squareCrop = !recipe.squareCrop))
                                    },
                                    label = { Text("정사각 자르기") },
                                )
                            }
                            Text(
                                "두 손가락으로 사진을 확대하고 이동할 수 있어요.",
                                style = MaterialTheme.typography.bodySmall,
                            )
                        }
                        "필터" ->
                            FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                listOf(
                                        "original" to "원본",
                                        "mono" to "흑백",
                                        "warm" to "따뜻하게",
                                        "cool" to "차갑게",
                                    )
                                    .forEach { (id, label) ->
                                        FilterChip(
                                            recipe.filter == id,
                                            { change(recipe.copy(filter = id)) },
                                            label = { Text(label) },
                                        )
                                    }
                            }
                        "글자" -> {
                            Row {
                                OutlinedTextField(
                                    text,
                                    { text = it },
                                    label = { Text("텍스트·이모지") },
                                    modifier = Modifier.weight(1f),
                                )
                                TextButton(
                                    onClick = {
                                        if (text.isNotBlank()) {
                                            add(text)
                                            text = ""
                                        }
                                    }
                                ) {
                                    Text("추가")
                                }
                            }
                            Row {
                                listOf("🌸", "❤️", "✨").forEach { emoji ->
                                    TextButton(onClick = { add(emoji) }) { Text(emoji) }
                                }
                            }
                            Text(
                                "항목을 고른 뒤 사진을 눌러 위치를 정하세요.",
                                style = MaterialTheme.typography.bodySmall,
                            )
                            FlowRow {
                                recipe.overlays.forEachIndexed { i, o ->
                                    FilterChip(
                                        selected == i,
                                        { selected = i },
                                        label = { Text(o.text.take(12)) },
                                    )
                                }
                            }
                            if (selected in recipe.overlays.indices) {
                                Slider(
                                    recipe.overlays[selected].size.toFloat(),
                                    { value ->
                                        val list = recipe.overlays.toMutableList()
                                        list[selected] =
                                            list[selected].copy(size = value.toDouble())
                                        change(recipe.copy(overlays = list))
                                    },
                                    valueRange = 0.03f..0.3f,
                                )
                                TextButton(
                                    onClick = {
                                        change(
                                            recipe.copy(
                                                overlays =
                                                    recipe.overlays.filterIndexed { i, _ ->
                                                        i != selected
                                                    }
                                            )
                                        )
                                        selected = -1
                                    }
                                ) {
                                    Text("선택한 글자 삭제")
                                }
                            }
                        }
                        "낙서" -> {
                            Row {
                                FilterChip(!erasing, { erasing = false }, label = { Text("펜") })
                                Spacer(Modifier.width(8.dp))
                                FilterChip(erasing, { erasing = true }, label = { Text("획 지우개") })
                            }
                            FlowRow(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                                listOf(
                                        "#302C29" to "검정",
                                        "#FFFFFF" to "흰색",
                                        "#78658F" to "보라",
                                        "#C54C4C" to "빨강",
                                        "#E9B949" to "노랑",
                                        "#44795A" to "초록",
                                    )
                                    .forEach { (hex, label) ->
                                        IconToggleButton(
                                            checked = inkColor == hex,
                                            onCheckedChange = {
                                                inkColor = hex
                                                erasing = false
                                            },
                                            modifier =
                                                Modifier.size(48.dp).semantics {
                                                    contentDescription = label
                                                },
                                        ) {
                                            Box(
                                                Modifier.size(40.dp)
                                                    .border(
                                                        if (inkColor == hex) 2.dp else 0.dp,
                                                        if (inkColor == hex)
                                                            MaterialTheme.colorScheme.primary
                                                        else Color.Transparent,
                                                        CircleShape,
                                                    )
                                                    .padding(6.dp)
                                                    .background(
                                                        Color(
                                                            android.graphics.Color.parseColor(hex)
                                                        ),
                                                        CircleShape,
                                                    )
                                                    .border(
                                                        1.dp,
                                                        MaterialTheme.colorScheme.outlineVariant,
                                                        CircleShape,
                                                    )
                                            )
                                        }
                                    }
                            }
                            FlowRow {
                                listOf(.003 to "가는 선", .006 to "중간 선", .012 to "굵은 선").forEach {
                                    (size, label) ->
                                    FilterChip(
                                        width == size,
                                        { width = size },
                                        label = { Text(label) },
                                    )
                                }
                            }
                            Text(
                                "한 손가락으로 그리기 · 두 손가락으로 확대/이동",
                                style = MaterialTheme.typography.bodySmall,
                            )
                        }
                    }
                }
            }
        }
        notice?.let { message ->
            AlertDialog(
                onDismissRequest = { notice = null },
                title = { Text("사진 꾸미기") },
                text = { Text(message) },
                confirmButton = { TextButton(onClick = { notice = null }) { Text("확인") } },
            )
        }
    }
}
