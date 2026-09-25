@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)

package com.poyal.drawry

import android.graphics.Bitmap
import android.net.Uri
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.*
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.pager.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.*
import androidx.compose.ui.graphics.*
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView
import com.poyal.drawry.core.*
import com.poyal.drawry.data.MediaStore
import java.io.File
import java.time.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

@Composable
fun DrawryApp(model: AppModel, authenticate: (() -> Unit) -> Unit, share: (File) -> Unit) {
    val state by model.state.collectAsStateWithLifecycle()
    var tab by rememberSaveable { mutableIntStateOf(0) }
    var detail by remember { mutableStateOf<String?>(null) }
    SketchTheme {
        Surface(Modifier.fillMaxSize()) {
            when {
                state.erased -> CenterMessage("모든 기록과 암호화 키를 삭제했습니다. 앱을 다시 실행해 주세요.")
                !state.ready ->
                    CenterMessage(
                        if (state.error == null) "기록을 안전하게 열고 있어요"
                        else "저장소를 열 수 없습니다.\n${state.error}"
                    )
                state.locked ->
                    Column(
                        Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(32.dp),
                        verticalArrangement = Arrangement.Center,
                        horizontalAlignment = Alignment.CenterHorizontally,
                    ) {
                        Icon(Icons.Default.Lock, null, Modifier.size(56.dp))
                        SketchTitle("나만의 기록, Drawry")
                        Button(onClick = { authenticate(model::unlock) }) { Text("잠금 해제") }
                    }
                !state.preferences.onboarded ->
                    Column(
                        Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(32.dp),
                        verticalArrangement = Arrangement.Center,
                        horizontalAlignment = Alignment.CenterHorizontally,
                    ) {
                        NotebookMark()
                        SketchTitle("오늘을 나만의 그림으로")
                        Spacer(Modifier.height(24.dp))
                        Text(
                            "사진과 이야기는 이 기기에 암호화해 보관합니다. 계정이나 서버 전송 없이 사용할 수 있어요. 기기를 바꾸거나 앱을 삭제하기 전에는 암호화 백업을 만들어 주세요."
                        )
                        Spacer(Modifier.height(24.dp))
                        Button(
                            onClick = {
                                model.preferences(state.preferences.copy(onboarded = true))
                            }
                        ) {
                            Text("내 기록 시작하기")
                        }
                    }
                state.editor != null -> Editor(model, state.editor!!)
                detail != null -> {
                    val diary = state.diaries.firstOrNull { it.id == detail }
                    if (diary != null) Detail(model, diary, { detail = null }, share)
                    else LaunchedEffect(Unit) { detail = null }
                }
                else ->
                    Scaffold(
                        topBar = {
                            TopAppBar(
                                title = {
                                    SketchTitle(listOf("Drawry", "날짜로 넘겨보기", "나의 스케치북")[tab])
                                },
                                colors =
                                    TopAppBarDefaults.topAppBarColors(
                                        containerColor = MaterialTheme.colorScheme.background
                                    ),
                            )
                        },
                        bottomBar = {
                            NavigationBar(
                                containerColor = MaterialTheme.colorScheme.background,
                                tonalElevation = 0.dp,
                            ) {
                                listOf(
                                        "기록" to Icons.Default.PhotoLibrary,
                                        "캘린더" to Icons.Default.CalendarMonth,
                                        "설정" to Icons.Default.Settings,
                                    )
                                    .forEachIndexed { i, item ->
                                        NavigationBarItem(
                                            selected = tab == i,
                                            colors =
                                                NavigationBarItemDefaults.colors(
                                                    indicatorColor = Color.Transparent,
                                                    selectedIconColor =
                                                        MaterialTheme.colorScheme.primary,
                                                ),
                                            onClick = { tab = i },
                                            icon = { Icon(item.second, item.first) },
                                            label = { Text(item.first) },
                                        )
                                    }
                            }
                        },
                        floatingActionButton = {
                            if (tab != 2)
                                ExtendedFloatingActionButton(
                                    onClick = { model.startEditor() },
                                    icon = { Icon(Icons.Default.Edit, "일기 작성") },
                                    text = { Text("기록하기") },
                                    containerColor = MaterialTheme.colorScheme.primary,
                                    contentColor = MaterialTheme.colorScheme.onPrimary,
                                )
                        },
                    ) { padding ->
                        Box(Modifier.padding(padding)) {
                            when (tab) {
                                0 -> Feed(model, state, { detail = it.id })
                                1 ->
                                    CalendarScreen(
                                        state.diaries.filter { it.deletedAt == null },
                                        model,
                                        { detail = it.id },
                                    )
                                else ->
                                    Settings(model, state, authenticate, share, { detail = it.id })
                            }
                        }
                    }
            }
            if (state.busy)
                Dialog(
                    onDismissRequest = {},
                    properties =
                        DialogProperties(dismissOnBackPress = false, dismissOnClickOutside = false),
                ) {
                    Surface(shape = RoundedCornerShape(24.dp)) {
                        Column(
                            Modifier.padding(32.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                        ) {
                            CircularProgressIndicator()
                            Spacer(Modifier.height(16.dp))
                            Text("안전하게 처리하고 있어요")
                            if (state.canCancel)
                                TextButton(onClick = model::cancelOperation) { Text("취소") }
                        }
                    }
                }
            state.error?.let { message ->
                AlertDialog(
                    onDismissRequest = { model.error(null) },
                    title = { Text("확인해 주세요") },
                    text = { Text(message) },
                    confirmButton = { TextButton(onClick = { model.error(null) }) { Text("확인") } },
                )
            }
            state.restore?.let { (snapshot, _) ->
                AlertDialog(
                    onDismissRequest = model::cancelRestore,
                    title = { Text("백업 복원") },
                    text = {
                        Text(
                            "${Instant.ofEpochMilli(snapshot.createdAt).atZone(ZoneId.systemDefault()).toLocalDate()} 백업\n일기 ${snapshot.diaries.size}개 · 미디어 ${snapshot.diaries.sumOf { it.media.size }}개\n병합은 동일 ID의 현재 기록을 유지합니다. 교체는 현재 기록을 백업으로 바꿉니다."
                        )
                    },
                    confirmButton = {
                        TextButton(onClick = { model.restore(false) }) { Text("병합") }
                    },
                    dismissButton = {
                        Row {
                            TextButton(onClick = { model.restore(true) }) { Text("전체 교체") }
                            TextButton(onClick = model::cancelRestore) { Text("취소") }
                        }
                    },
                )
            }
        }
    }
}

@Composable
private fun CenterMessage(message: String) {
    Box(Modifier.fillMaxSize().padding(32.dp), contentAlignment = Alignment.Center) {
        Text(message)
    }
}

@Composable
private fun Feed(model: AppModel, state: AppState, onOpen: (Diary) -> Unit) {
    val diaries = state.diaries.filter { it.deletedAt == null }
    Column(Modifier.fillMaxSize()) {
        if (state.draft != null)
            TextButton(
                onClick = { model.startEditor() },
                modifier = Modifier.padding(horizontal = 20.dp),
            ) {
                Text("✎ 작성 중인 페이지 이어 쓰기")
            }
        if (diaries.isEmpty()) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                EmptyNotebook("아직 펼치지 않은 이야기", "오늘의 사진 한 장으로 시작해 보세요.") { model.startEditor() }
            }
        } else if (state.preferences.layout == 1) {
            LazyColumn(
                contentPadding = PaddingValues(20.dp, 8.dp, 20.dp, 104.dp),
                verticalArrangement = Arrangement.spacedBy(24.dp),
            ) {
                item {
                    Text(
                        "사진으로 채우는 나만의 스케치북",
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        style = MaterialTheme.typography.bodySmall,
                    )
                }
                items(diaries, key = { it.id }) { diary ->
                    Surface(
                        onClick = { onOpen(diary) },
                        shape = RoundedCornerShape(12.dp),
                        color = MaterialTheme.colorScheme.surface,
                        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant),
                    ) {
                        Column(Modifier.padding(16.dp)) {
                            Row(
                                Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                            ) {
                                Text(
                                    diary.entryDate,
                                    style = MaterialTheme.typography.labelMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                )
                                Text(diary.mood, style = MaterialTheme.typography.labelMedium)
                            }
                            Spacer(Modifier.height(12.dp))
                            val pager = rememberPagerState(pageCount = { diary.media.size })
                            Box {
                                HorizontalPager(pager) { page ->
                                    MediaImage(
                                        model,
                                        diary.media[page],
                                        Modifier.fillMaxWidth().aspectRatio(4f / 5f).clickable {
                                            onOpen(diary)
                                        },
                                        fit = true,
                                    )
                                }
                                PaperTape(Modifier.align(Alignment.TopCenter).offset(y = (-8).dp))
                                if (diary.media.size > 1)
                                    Text(
                                        "${pager.currentPage+1} / ${diary.media.size}",
                                        Modifier.align(Alignment.TopEnd)
                                            .padding(8.dp)
                                            .background(
                                                Color.Black.copy(alpha = .6f),
                                                RoundedCornerShape(20.dp),
                                            )
                                            .padding(horizontal = 10.dp, vertical = 4.dp),
                                        color = Color.White,
                                        style = MaterialTheme.typography.labelSmall,
                                    )
                            }
                            Spacer(Modifier.height(12.dp))
                            SketchTitle(diary.headline.ifBlank { "오늘의 한 페이지" })
                            if (diary.body.isNotBlank())
                                Text(
                                    diary.body,
                                    maxLines = 2,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                )
                            if (diary.weather.condition.isNotBlank()) {
                                Spacer(Modifier.height(8.dp))
                                WeatherText(diary.weather)
                            }
                        }
                    }
                }
            }
        } else {
            val columns = state.preferences.layout.coerceIn(2, 3)
            LazyVerticalGrid(
                columns = GridCells.Fixed(columns),
                contentPadding = PaddingValues(20.dp, 8.dp, 20.dp, 104.dp),
                horizontalArrangement = Arrangement.spacedBy(if (columns == 2) 12.dp else 4.dp),
                verticalArrangement = Arrangement.spacedBy(if (columns == 2) 16.dp else 4.dp),
            ) {
                items(diaries, key = { it.id }) { diary ->
                    Column(
                        Modifier.background(
                                MaterialTheme.colorScheme.surface,
                                RoundedCornerShape(8.dp),
                            )
                            .clickable { onOpen(diary) }
                    ) {
                        Box {
                            MediaImage(
                                model,
                                diary.media.first(),
                                Modifier.fillMaxWidth()
                                    .aspectRatio(if (columns == 2) 4f / 5f else 1f),
                            )
                            if (diary.media.size > 1)
                                Icon(
                                    Icons.Default.Collections,
                                    "사진 여러 장",
                                    Modifier.align(Alignment.TopEnd).padding(6.dp).size(18.dp),
                                    tint = Color.White,
                                )
                            if (columns == 3)
                                Text(
                                    diary.entryDate.takeLast(5),
                                    Modifier.align(Alignment.BottomStart)
                                        .background(Color.Black.copy(alpha = .55f))
                                        .padding(4.dp),
                                    color = Color.White,
                                    style = MaterialTheme.typography.labelSmall,
                                )
                        }
                        if (columns == 2) {
                            Text(
                                diary.headline.ifBlank { "오늘의 기록" },
                                Modifier.padding(horizontal = 8.dp, vertical = 6.dp),
                                maxLines = 2,
                                fontFamily = SketchFont,
                                style = MaterialTheme.typography.titleLarge,
                            )
                            Text(
                                diary.entryDate,
                                Modifier.padding(start = 8.dp, bottom = 8.dp),
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun MediaImage(
    model: AppModel,
    media: Media,
    modifier: Modifier = Modifier,
    full: Boolean = false,
    fit: Boolean = false,
    natural: Boolean = false,
) {
    val bitmap by
        produceState<Bitmap?>(null, media.thumbnail, media.rendered, full) {
            value =
                runCatching {
                        withContext(Dispatchers.IO) {
                            MediaStore.decode(
                                model.media.clearFile(
                                    media,
                                    thumbnail = !full || media.kind == "video",
                                ),
                                if (full) 1600 else 480,
                            )
                        }
                    }
                    .getOrNull()
        }
    Box(
        modifier
            .then(
                if (natural)
                    Modifier.aspectRatio(
                        bitmap?.let { (it.width.toFloat() / it.height).coerceIn(.65f, 1.8f) } ?: 1f
                    )
                else Modifier
            )
            .background(MaterialTheme.colorScheme.surfaceVariant),
        contentAlignment = Alignment.Center,
    ) {
        bitmap?.let {
            Image(
                it.asImageBitmap(),
                "일기 미디어",
                Modifier.fillMaxSize(),
                contentScale = if (full || fit || natural) ContentScale.Fit else ContentScale.Crop,
            )
        }
        if (media.kind == "video")
            Icon(
                Icons.Default.PlayCircle,
                "영상",
                tint = Color.White,
                modifier = Modifier.size(36.dp),
            )
    }
}

@Composable
private fun CalendarScreen(diaries: List<Diary>, model: AppModel, onOpen: (Diary) -> Unit) {
    var month by remember { mutableStateOf(YearMonth.now()) }
    var selected by remember { mutableStateOf(LocalDate.now()) }
    LazyColumn(contentPadding = PaddingValues(20.dp, 8.dp, 20.dp, 104.dp)) {
        item {
            Row(verticalAlignment = Alignment.CenterVertically) {
                TextButton(onClick = { month = month.minusMonths(1) }) { Text("이전") }
                Text(
                    "${month.year}년 ${month.monthValue}월",
                    Modifier.weight(1f),
                    style = MaterialTheme.typography.titleLarge,
                )
                TextButton(
                    onClick = {
                        month = YearMonth.now()
                        selected = LocalDate.now()
                    }
                ) {
                    Text("오늘")
                }
                TextButton(onClick = { month = month.plusMonths(1) }) { Text("다음") }
            }
        }
        item {
            Row {
                listOf("월", "화", "수", "목", "금", "토", "일").forEach {
                    Text(it, Modifier.weight(1f).padding(8.dp))
                }
            }
        }
        val offset = month.atDay(1).dayOfWeek.value - 1
        items((month.lengthOfMonth() + offset + 6) / 7) { week ->
            Row {
                repeat(7) { column ->
                    val day = week * 7 + column - offset + 1
                    if (day in 1..month.lengthOfMonth()) {
                        val date = month.atDay(day)
                        val entries = diaries.filter { it.entryDate == date.toString() }
                        val count = entries.size
                        Column(
                            Modifier.weight(1f)
                                .height(84.dp)
                                .background(
                                    if (date == selected) MaterialTheme.colorScheme.primaryContainer
                                    else Color.Transparent,
                                    RoundedCornerShape(12.dp),
                                )
                                .clickable { selected = date }
                                .padding(6.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                        ) {
                            Text("$day")
                            if (count > 0) {
                                Box {
                                    MediaImage(
                                        model,
                                        entries.first().media.first(),
                                        Modifier.size(30.dp),
                                    )
                                    if (count > 1)
                                        Text(
                                            "$count",
                                            Modifier.align(Alignment.BottomEnd)
                                                .background(Color.Black.copy(alpha = .6f)),
                                            color = Color.White,
                                            style = MaterialTheme.typography.labelSmall,
                                        )
                                }
                            }
                        }
                    } else Spacer(Modifier.weight(1f))
                }
            }
        }
        item {
            Text(
                selected.toString(),
                Modifier.padding(vertical = 16.dp),
                style = MaterialTheme.typography.titleMedium,
            )
        }
        val dayItems = diaries.filter { it.entryDate == selected.toString() }
        if (dayItems.isEmpty()) item { Text("이날의 기록이 없어요.") }
        items(dayItems, key = { it.id }) { diary ->
            ListItem(
                headlineContent = { Text(diary.headline.ifBlank { "오늘의 기록" }) },
                supportingContent = { Text(diary.mood) },
                leadingContent = { MediaImage(model, diary.media.first(), Modifier.size(64.dp)) },
                modifier = Modifier.clickable { onOpen(diary) },
            )
        }
    }
}

@Composable
private fun Detail(model: AppModel, diary: Diary, back: () -> Unit, share: (File) -> Unit) {
    var confirm by remember { mutableStateOf(false) }
    var sharing by remember { mutableStateOf(false) }
    var playing by remember { mutableStateOf<Media?>(null) }
    var viewing by remember { mutableStateOf<Int?>(null) }
    BackHandler(onBack = back)
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(diary.entryDate) },
                navigationIcon = {
                    IconButton(onClick = back) { Icon(Icons.Default.ArrowBack, "뒤로") }
                },
                actions = {
                    if (diary.deletedAt == null)
                        IconButton(onClick = { model.startEditor(diary) }) {
                            Icon(Icons.Default.Edit, "수정")
                        }
                },
            )
        }
    ) { padding ->
        LazyColumn(Modifier.padding(padding), contentPadding = PaddingValues(16.dp)) {
            items(diary.media, key = { it.id }) { media ->
                MediaImage(
                    model,
                    media,
                    Modifier.fillMaxWidth().clickable {
                        if (media.kind == "video") playing = media
                        else viewing = diary.media.indexOf(media)
                    },
                    full = true,
                    natural = true,
                )
                Spacer(Modifier.height(12.dp))
            }
            item { DiaryText(diary) }
            item {
                Row {
                    if (diary.deletedAt == null) {
                        TextButton(onClick = { sharing = true }) { Text("이미지 공유") }
                        TextButton(onClick = { confirm = true }) { Text("휴지통으로") }
                    } else {
                        TextButton(
                            onClick = {
                                model.trash(diary, true)
                                back()
                            }
                        ) {
                            Text("복원")
                        }
                        TextButton(onClick = { confirm = true }) { Text("영구 삭제") }
                    }
                }
            }
        }
    }
    if (confirm)
        AlertDialog(
            onDismissRequest = { confirm = false },
            title = { Text(if (diary.deletedAt == null) "휴지통으로 이동할까요?" else "영구 삭제할까요?") },
            text = {
                Text(
                    if (diary.deletedAt == null) "30일 안에 복원할 수 있습니다." else "이 기록과 미디어는 되돌릴 수 없습니다."
                )
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        confirm = false
                        if (diary.deletedAt == null) model.trash(diary) else model.purge(diary)
                        back()
                    }
                ) {
                    Text("삭제")
                }
            },
            dismissButton = { TextButton(onClick = { confirm = false }) { Text("취소") } },
        )
    if (sharing) ShareOptions(model, diary, { sharing = false }, share)
    playing?.let { VideoDialog(model, it) { playing = null } }
    viewing?.let { index ->
        PhotoViewer(model, diary.media, index, { viewing = null }, { playing = it })
    }
}

@Composable
private fun DiaryText(diary: Diary) {
    Column(
        verticalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier.padding(vertical = 16.dp),
    ) {
        SketchTitle(diary.headline.ifBlank { "오늘의 기록" })
        Text(
            "${diary.entryDate} ${"%02d:%02d".format(diary.entryTimeMinutes/60,diary.entryTimeMinutes%60)} ${diary.mood}"
        )
        if (diary.body.isNotBlank()) Text(diary.body)
        if (diary.tags.isNotEmpty())
            Text(diary.tags.joinToString(" ") { "#$it" }, color = MaterialTheme.colorScheme.primary)
        if (diary.companions.isNotEmpty()) Text("함께한 사람 · ${diary.companions.joinToString()}")
        WeatherText(diary.weather)
    }
}

@Composable
private fun WeatherText(w: Weather) {
    val text =
        buildList {
                if (w.displayMask and 1 != 0 && w.condition.isNotBlank()) add(w.condition)
                if (w.displayMask and 2 != 0) w.temperature?.let { add("${it}°C") }
                if (w.displayMask and 4 != 0) {
                    w.minimum?.let { add("최저 ${it}°C") }
                    w.maximum?.let { add("최고 ${it}°C") }
                }
                if (w.displayMask and 8 != 0 && w.precipitation) add("비·눈")
            }
            .joinToString(" · ")
    if (text.isNotEmpty()) Text(text)
}

@Composable
private fun VideoDialog(model: AppModel, media: Media, dismiss: () -> Unit) {
    val context = LocalContext.current
    val file by
        produceState<File?>(null, media.id) {
            value = runCatching { model.media.clearFile(media, original = true) }.getOrNull()
        }
    Dialog(
        onDismissRequest = dismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false),
    ) {
        Surface {
            Column {
                TextButton(onClick = dismiss) { Text("닫기") }
                file?.let { source ->
                    val player =
                        remember(source) {
                            ExoPlayer.Builder(context).build().apply {
                                setMediaItem(MediaItem.fromUri(Uri.fromFile(source)))
                                prepare()
                                playWhenReady = true
                            }
                        }
                    val lifecycle = LocalLifecycleOwner.current
                    DisposableEffect(player, lifecycle) {
                        val observer = LifecycleEventObserver { _, event ->
                            if (event == Lifecycle.Event.ON_STOP) player.pause()
                        }
                        lifecycle.lifecycle.addObserver(observer)
                        onDispose {
                            lifecycle.lifecycle.removeObserver(observer)
                            player.release()
                        }
                    }
                    AndroidView(
                        factory = { PlayerView(it).apply { this.player = player } },
                        modifier = Modifier.fillMaxWidth().height(420.dp),
                    )
                } ?: CircularProgressIndicator()
            }
        }
    }
}

@Composable
private fun EditorMediaStrip(model: AppModel, diary: Diary, decorate: (Media) -> Unit) {
    val pager = rememberPagerState(pageCount = { diary.media.size })
    val scope = rememberCoroutineScope()
    val selected = pager.currentPage.coerceIn(diary.media.indices)
    val item = diary.media[selected]
    Column(
        Modifier.fillMaxWidth()
            .background(MaterialTheme.colorScheme.surface, RoundedCornerShape(12.dp))
            .border(1.dp, MaterialTheme.colorScheme.outlineVariant, RoundedCornerShape(12.dp))
            .padding(12.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        HorizontalPager(state = pager, key = { diary.media[it].id }) { index ->
            MediaImage(
                model,
                diary.media[index],
                Modifier.fillMaxWidth().height(280.dp),
                full = true,
                fit = true,
            )
        }
        Text(
            "${selected + 1} / ${diary.media.size} · 옆으로 넘겨 보세요",
            style = MaterialTheme.typography.bodySmall,
        )
        if (diary.media.size > 1) {
            Row(
                Modifier.horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                diary.media.forEachIndexed { index, media ->
                    MediaImage(
                        model,
                        media,
                        Modifier.size(52.dp)
                            .semantics { contentDescription = "${index + 1}번째 사진 선택" }
                            .border(
                                if (selected == index) 2.dp else 1.dp,
                                if (selected == index) MaterialTheme.colorScheme.primary
                                else MaterialTheme.colorScheme.outlineVariant,
                                RoundedCornerShape(4.dp),
                            )
                            .clickable { scope.launch { pager.animateScrollToPage(index) } },
                    )
                }
            }
        }
        Row(Modifier.horizontalScroll(rememberScrollState())) {
            TextButton(onClick = { decorate(item) }) {
                Text(if (item.kind == "video") "대표 프레임" else "꾸미기")
            }
            TextButton(
                onClick = {
                    val list = diary.media.toMutableList()
                    list.removeAt(selected)
                    list.add(selected - 1, item)
                    model.updateEditor(diary.copy(media = list))
                    scope.launch { pager.scrollToPage(selected - 1) }
                },
                enabled = selected > 0,
            ) {
                Text("앞으로")
            }
            TextButton(
                onClick = {
                    model.updateEditor(diary.copy(media = diary.media.filter { it.id != item.id }))
                }
            ) {
                Text("제거")
            }
        }
    }
}

@Composable
private fun Editor(model: AppModel, diary: Diary) {
    var preview by remember { mutableStateOf(false) }
    var exit by remember { mutableStateOf(false) }
    var preserve by rememberSaveable { mutableStateOf(false) }
    var importOptions by rememberSaveable { mutableStateOf(false) }
    var editing by remember { mutableStateOf<Media?>(null) }
    var frame by remember { mutableStateOf<Media?>(null) }
    var extras by rememberSaveable { mutableStateOf(false) }
    var choosingDate by remember { mutableStateOf(false) }
    var choosingTime by remember { mutableStateOf(false) }
    val picker =
        rememberLauncherForActivityResult(ActivityResultContracts.PickMultipleVisualMedia(10)) {
            if (it.isNotEmpty()) model.import(it, preserve)
        }
    var captureVideo by remember { mutableStateOf<Boolean?>(null) }
    fun camera(isVideo: Boolean) {
        captureVideo = isVideo
    }
    captureVideo?.let { video ->
        CaptureScreen(
            video = video,
            onClose = { captureVideo = null },
            onCapture = { uri ->
                captureVideo = null
                model.import(listOf(uri), preserve)
            },
            onError = {
                model.error(it)
                captureVideo = null
            },
        )
        return
    }
    BackHandler { exit = true }
    Scaffold(
        topBar = {
            TopAppBar(
                title = { SketchTitle("오늘의 한 페이지") },
                navigationIcon = {
                    IconButton(onClick = { exit = true }) { Icon(Icons.Default.Close, "닫기") }
                },
                actions = {
                    TextButton(
                        onClick = { model.saveEditor() },
                        enabled = diary.media.isNotEmpty(),
                    ) {
                        Text("저장")
                    }
                },
            )
        }
    ) { padding ->
        LazyColumn(
            Modifier.padding(padding).imePadding(),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            item {
                if (diary.media.isEmpty()) NotebookMark(Modifier.size(88.dp))
                SketchTitle(if (diary.media.isEmpty()) "사진을 붙여 주세요" else "오늘의 장면")
                Text(
                    "${diary.media.size}/10개 · ${diary.media.sumOf {it.byteLength}/1024/1024}MB / 300MB",
                    style = MaterialTheme.typography.bodySmall,
                )
                Row {
                    TextButton(
                        onClick = {
                            picker.launch(
                                PickVisualMediaRequest(
                                    ActivityResultContracts.PickVisualMedia.ImageAndVideo
                                )
                            )
                        }
                    ) {
                        Text("보관함")
                    }
                    TextButton(onClick = { camera(false) }) { Text("사진 촬영") }
                    TextButton(onClick = { camera(true) }) { Text("영상 촬영") }
                }
                TextButton(onClick = { importOptions = !importOptions }) {
                    Text(if (importOptions) "사진 가져오기 옵션 −" else "사진 가져오기 옵션 +")
                }
                if (importOptions) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Checkbox(preserve, { preserve = it })
                        Text("사진 원본 보관")
                    }
                }
            }
            if (diary.media.isNotEmpty()) {
                item(key = "editor-media") {
                    EditorMediaStrip(model, diary) { item ->
                        if (item.kind == "video") frame = item else editing = item
                    }
                }
            }
            item {
                Field("오늘의 한 줄", diary.headline) { model.updateEditor(diary.copy(headline = it)) }
            }
            item {
                OutlinedTextField(
                    diary.body,
                    { model.updateEditor(diary.copy(body = it)) },
                    label = { Text("일기 내용 (선택)") },
                    modifier = Modifier.fillMaxWidth(),
                    minLines = 4,
                )
            }
            item {
                TextButton(onClick = { extras = !extras }) {
                    Text(if (extras) "부가 기록 접기 −" else "날짜 · 기분 · 날씨 더하기 +")
                }
            }
            if (extras) {
                item {
                    TextButton(onClick = { choosingDate = true }) {
                        Text("날짜 · ${diary.entryDate}")
                    }
                }
                item {
                    TextButton(onClick = { choosingTime = true }) {
                        Text(
                            "시간 · ${"%02d:%02d".format(diary.entryTimeMinutes/60,diary.entryTimeMinutes%60)}"
                        )
                    }
                }
                item {
                    Field("기분", diary.mood) { model.updateEditor(diary.copy(mood = it)) }
                    Row {
                        listOf("😊", "🥰", "😌", "😢", "😤").forEach { emoji ->
                            TextButton(onClick = { model.updateEditor(diary.copy(mood = emoji)) }) {
                                Text(emoji)
                            }
                        }
                    }
                }
                item {
                    TokenField("태그 (쉼표로 구분)", diary.tags) {
                        model.updateEditor(diary.copy(tags = it))
                    }
                }
                item {
                    TokenField("함께한 사람 (쉼표로 구분)", diary.companions) {
                        model.updateEditor(diary.copy(companions = it))
                    }
                }
                item {
                    WeatherEditor(diary.weather) { model.updateEditor(diary.copy(weather = it)) }
                }
            }
            item {
                TextButton(onClick = { preview = true }, enabled = diary.media.isNotEmpty()) {
                    Text("페이지 미리 보기")
                }
            }
            item { Text("변경 사항은 암호화된 초안으로 자동 저장됩니다.", style = MaterialTheme.typography.bodySmall) }
        }
    }
    if (exit)
        AlertDialog(
            onDismissRequest = { exit = false },
            title = { Text("작성 중인 기록") },
            text = { Text("초안을 보관하면 다음에 이어 쓸 수 있습니다.") },
            confirmButton = {
                TextButton(onClick = { model.leaveEditor(false) }) { Text("초안 보관") }
            },
            dismissButton = { TextButton(onClick = { model.leaveEditor(true) }) { Text("초안 폐기") } },
        )
    if (preview)
        Dialog(
            onDismissRequest = { preview = false },
            properties = DialogProperties(usePlatformDefaultWidth = false),
        ) {
            Surface(Modifier.fillMaxSize()) {
                Column(Modifier.padding(24.dp)) {
                    Row {
                        TextButton(onClick = { preview = false }) { Text("수정") }
                        Spacer(Modifier.weight(1f))
                        Button(
                            onClick = {
                                preview = false
                                model.saveEditor()
                            }
                        ) {
                            Text("암호화 저장")
                        }
                    }
                    LazyColumn {
                        item { DiaryText(diary) }
                        items(diary.media) {
                            MediaImage(
                                model,
                                it,
                                Modifier.fillMaxWidth().aspectRatio(1f),
                                full = true,
                            )
                        }
                    }
                }
            }
        }
    editing?.let {
        SketchPhotoEditor(model, it, { editing = null }) { recipe ->
            model.editMedia(it, recipe)
            editing = null
        }
    }
    frame?.let { item ->
        var seconds by remember { mutableFloatStateOf(item.representativeMillis / 1000f) }
        val bitmap by
            produceState<Bitmap?>(null, item.id, seconds) {
                kotlinx.coroutines.delay(120)
                value =
                    runCatching { model.media.previewFrame(item, (seconds * 1000).toLong()) }
                        .getOrNull()
            }
        AlertDialog(
            onDismissRequest = { frame = null },
            title = { Text("영상 대표 화면") },
            text = {
                Column {
                    bitmap?.let {
                        Image(
                            it.asImageBitmap(),
                            "선택할 대표 프레임",
                            Modifier.fillMaxWidth().height(180.dp),
                            contentScale = ContentScale.Fit,
                        )
                    }
                    Text("${"%.1f".format(seconds)}초")
                    Slider(
                        seconds,
                        { seconds = it },
                        valueRange = 0f..(item.durationMillis / 1000f - .05f).coerceAtLeast(.01f),
                    )
                }
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        model.frame(item, (seconds * 1000).toLong())
                        frame = null
                    }
                ) {
                    Text("선택")
                }
            },
            dismissButton = { TextButton(onClick = { frame = null }) { Text("취소") } },
        )
    }
    if (choosingDate) {
        val picker =
            rememberDatePickerState(
                initialSelectedDateMillis =
                    LocalDate.parse(diary.entryDate)
                        .atStartOfDay(ZoneOffset.UTC)
                        .toInstant()
                        .toEpochMilli()
            )
        DatePickerDialog(
            onDismissRequest = { choosingDate = false },
            confirmButton = {
                TextButton(
                    onClick = {
                        picker.selectedDateMillis?.let {
                            model.updateEditor(
                                diary.copy(
                                    entryDate =
                                        Instant.ofEpochMilli(it)
                                            .atZone(ZoneOffset.UTC)
                                            .toLocalDate()
                                            .toString()
                                )
                            )
                        }
                        choosingDate = false
                    }
                ) {
                    Text("선택")
                }
            },
            dismissButton = { TextButton(onClick = { choosingDate = false }) { Text("취소") } },
        ) {
            DatePicker(state = picker)
        }
    }
    if (choosingTime) {
        val picker =
            rememberTimePickerState(
                initialHour = diary.entryTimeMinutes / 60,
                initialMinute = diary.entryTimeMinutes % 60,
                is24Hour = true,
            )
        AlertDialog(
            onDismissRequest = { choosingTime = false },
            title = { Text("시간") },
            text = { TimePicker(picker) },
            confirmButton = {
                TextButton(
                    onClick = {
                        model.updateEditor(
                            diary.copy(entryTimeMinutes = picker.hour * 60 + picker.minute)
                        )
                        choosingTime = false
                    }
                ) {
                    Text("선택")
                }
            },
            dismissButton = { TextButton(onClick = { choosingTime = false }) { Text("취소") } },
        )
    }
}

@Composable
private fun Field(label: String, value: String, onChange: (String) -> Unit) {
    OutlinedTextField(value, onChange, label = { Text(label) }, modifier = Modifier.fillMaxWidth())
}

@Composable
private fun TokenField(label: String, values: List<String>, onChange: (List<String>) -> Unit) {
    var text by remember { mutableStateOf(values.joinToString(", ")) }
    Field(label, text) {
        text = it
        onChange(it.split(',').map(String::trim).filter(String::isNotEmpty))
    }
}

@Composable
private fun WeatherEditor(weather: Weather, onChange: (Weather) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text("날씨 · 직접 기록", style = MaterialTheme.typography.titleMedium)
        Field("날씨", weather.condition) { onChange(weather.copy(condition = it)) }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            listOf("기온" to weather.temperature, "최저" to weather.minimum, "최고" to weather.maximum)
                .forEachIndexed { i, pair ->
                    var text by remember { mutableStateOf(pair.second?.toString().orEmpty()) }
                    OutlinedTextField(
                        text,
                        {
                            text = it
                            val n = it.toDoubleOrNull()
                            onChange(
                                when (i) {
                                    0 -> weather.copy(temperature = n)
                                    1 -> weather.copy(minimum = n)
                                    else -> weather.copy(maximum = n)
                                }
                            )
                        },
                        label = { Text(pair.first) },
                        modifier = Modifier.weight(1f),
                    )
                }
        }
        Row(verticalAlignment = Alignment.CenterVertically) {
            Checkbox(weather.precipitation, { onChange(weather.copy(precipitation = it)) })
            Text("비 또는 눈")
        }
        Row {
            listOf(1 to "상태", 2 to "기온", 4 to "최저·최고", 8 to "강수").forEach { (mask, label) ->
                FilterChip(
                    weather.displayMask and mask != 0,
                    { onChange(weather.copy(displayMask = weather.displayMask xor mask)) },
                    label = { Text(label) },
                )
            }
        }
    }
}

@Composable
private fun ShareOptions(
    model: AppModel,
    diary: Diary,
    dismiss: () -> Unit,
    share: (File) -> Unit,
) {
    val state by model.state.collectAsStateWithLifecycle()
    var prefs by remember { mutableStateOf(state.preferences) }
    var preview by remember { mutableStateOf<File?>(null) }
    AlertDialog(
        onDismissRequest = dismiss,
        title = { Text("공유 이미지") },
        text = {
            Column(Modifier.verticalScroll(rememberScrollState())) {
                listOf(
                        "headline" to "한 줄",
                        "body" to "본문",
                        "date" to "날짜",
                        "mood" to "기분",
                        "weather" to "날씨",
                    )
                    .forEach { (field, label) ->
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Checkbox(
                                field in prefs.shareFields,
                                {
                                    prefs =
                                        prefs.copy(
                                            shareFields =
                                                if (it) prefs.shareFields + field
                                                else prefs.shareFields - field
                                        )
                                    preview = null
                                },
                            )
                            Text(label)
                        }
                    }
                Row {
                    listOf("4:5", "1:1", "9:16").forEach { ratio ->
                        FilterChip(
                            prefs.shareRatio == ratio,
                            {
                                prefs = prefs.copy(shareRatio = ratio)
                                preview = null
                            },
                            label = { Text(ratio) },
                        )
                    }
                }
                Row {
                    listOf("light" to "밝게", "dark" to "어둡게").forEach { (theme, label) ->
                        FilterChip(
                            prefs.shareTheme == theme,
                            {
                                prefs = prefs.copy(shareTheme = theme)
                                preview = null
                            },
                            label = { Text(label) },
                        )
                    }
                }
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Checkbox(
                        prefs.watermark,
                        {
                            prefs = prefs.copy(watermark = it)
                            preview = null
                        },
                    )
                    Text("Drawry 워터마크")
                }
                preview?.let { file ->
                    val image = remember(file) { MediaStore.decode(file, 600) }
                    Image(
                        image.asImageBitmap(),
                        "공유 결과",
                        Modifier.fillMaxWidth().height(240.dp),
                        contentScale = ContentScale.Fit,
                    )
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    if (preview == null) model.action { preview = model.media.share(diary, prefs) }
                    else
                        model.action {
                            model.vault.preferences(prefs)
                            model.refresh()
                            share(preview!!)
                            dismiss()
                        }
                }
            ) {
                Text(if (preview == null) "미리 보기" else "공유")
            }
        },
        dismissButton = {
            TextButton(
                onClick = {
                    preview?.delete()
                    dismiss()
                }
            ) {
                Text("취소")
            }
        },
    )
}

@Composable
private fun Settings(
    model: AppModel,
    state: AppState,
    authenticate: (() -> Unit) -> Unit,
    share: (File) -> Unit,
    open: (Diary) -> Unit,
) {
    var password by remember { mutableStateOf("") }
    var recovery by remember { mutableStateOf("") }
    var recoveryCode by remember { mutableStateOf<String?>(null) }
    var erase by remember { mutableStateOf(false) }
    var size by remember { mutableStateOf("") }
    var license by remember { mutableStateOf<String?>(null) }
    val settingsContext = LocalContext.current
    val import =
        rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
            if (uri != null) model.inspect(uri, password, recovery)
        }
    LaunchedEffect(state.diaries) {
        size =
            withContext(Dispatchers.IO) {
                val files = model.vault.mediaDirectory.listFiles().orEmpty()
                "원본 ${files.filter{!it.name.contains("thumb")&&!it.name.contains("render")}.sumOf{it.length()}/1024/1024}MB · 편집본 ${files.filter{it.name.contains("render")}.sumOf{it.length()}/1024/1024}MB · 미리 보기 ${files.filter{it.name.contains("thumb")}.sumOf{it.length()}/1024/1024}MB"
            }
    }
    LazyColumn(
        contentPadding = PaddingValues(20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        item {
            Text("화면", style = MaterialTheme.typography.titleLarge)
            Text("기록 보기 방식", style = MaterialTheme.typography.titleMedium)
            FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                listOf(1 to "카드", 2 to "2열", 3 to "3열").forEach { (count, label) ->
                    FilterChip(
                        selected = state.preferences.layout == count,
                        onClick = { model.preferences(state.preferences.copy(layout = count)) },
                        label = { Text(label) },
                    )
                }
            }
            Text(
                "기록 탭에 일기를 표시하는 방식을 선택하세요.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        item { HorizontalDivider() }
        item {
            Text("개인정보와 보안", style = MaterialTheme.typography.titleLarge)
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("앱 잠금", Modifier.weight(1f))
                Switch(
                    state.preferences.lockEnabled,
                    { enabled ->
                        authenticate {
                            model.preferences(state.preferences.copy(lockEnabled = enabled))
                        }
                    },
                )
            }
        }
        item {
            Text("다시 잠그기")
            FlowRow {
                listOf(0 to "즉시", 30 to "30초", 60 to "1분", 300 to "5분", 900 to "15분", 1800 to "30분")
                    .forEach { (seconds, label) ->
                        FilterChip(
                            state.preferences.graceSeconds == seconds,
                            { model.preferences(state.preferences.copy(graceSeconds = seconds)) },
                            label = { Text(label) },
                        )
                    }
            }
        }
        item {
            Text("기록은 기기에 암호화해 보관합니다. 계정·서버·분석 SDK를 사용하지 않으며, 공유와 백업은 직접 실행할 때만 앱 밖으로 전달됩니다.")
            Spacer(Modifier.height(16.dp))
            Text("저장 공간", style = MaterialTheme.typography.titleLarge)
            Text(size)
        }
        item {
            HorizontalDivider()
            Text("암호화 백업·복원", style = MaterialTheme.typography.titleLarge)
            OutlinedTextField(
                password,
                { password = it },
                label = { Text("백업 암호 (8자 이상)") },
                visualTransformation = PasswordVisualTransformation(),
                modifier = Modifier.fillMaxWidth(),
            )
            Field("복구 키 (암호 대신 사용)", recovery) { recovery = it }
        }
        item {
            Row {
                Button(
                    onClick = {
                        model.action(cancellable = true) { share(model.vault.export(password)) }
                    },
                    enabled = password.codePointCount(0, password.length) >= 8,
                ) {
                    Text("백업 저장")
                }
                TextButton(
                    onClick = { import.launch(arrayOf("*/*")) },
                    enabled = password.isNotEmpty() || recovery.isNotEmpty(),
                ) {
                    Text("백업 열기")
                }
            }
            TextButton(
                onClick = {
                    authenticate {
                        model.action {
                            recoveryCode =
                                withContext(Dispatchers.IO) {
                                    java.util.Base64.getEncoder()
                                        .encodeToString(model.vault.keys.get("recovery"))
                                }
                        }
                    }
                }
            ) {
                Text("복구 키 보기")
            }
        }
        item {
            HorizontalDivider()
            Text("휴지통 · 30일 보관", style = MaterialTheme.typography.titleLarge)
        }
        items(state.diaries.filter { it.deletedAt != null }, key = { it.id }) { diary ->
            ListItem(
                headlineContent = { Text(diary.headline.ifBlank { diary.entryDate }) },
                supportingContent = {
                    Text(
                        "${Instant.ofEpochMilli(diary.deletedAt!!+30L*86400_000).atZone(ZoneId.systemDefault()).toLocalDate()} 삭제 예정"
                    )
                },
                modifier = Modifier.clickable { open(diary) },
            )
        }
        item {
            HorizontalDivider()
            TextButton(onClick = { erase = true }) {
                Text("모든 데이터 삭제", color = MaterialTheme.colorScheme.error)
            }
            Text("Drawry ${BuildConfig.VERSION_NAME}")
            Text(
                "오픈소스: Kotlin·Coroutines·Serialization·AndroidX (Apache 2.0), SQLCipher (BSD).",
                style = MaterialTheme.typography.bodySmall,
            )
            TextButton(
                onClick = {
                    license =
                        listOf("SQLCipher.txt", "Apache-2.0.txt", "NanumPenScript-OFL.txt")
                            .joinToString("\n\n") {
                                settingsContext.assets.open(it).bufferedReader().use { reader ->
                                    reader.readText()
                                }
                            }
                }
            ) {
                Text("라이선스 전문")
            }
        }
    }
    recoveryCode?.let { code ->
        AlertDialog(
            onDismissRequest = { recoveryCode = null },
            title = { Text("백업 복구 키") },
            text = {
                Column {
                    Text("이 키를 안전한 곳에 별도로 보관하세요. 키를 가진 사람은 백업을 열 수 있습니다.")
                    androidx.compose.foundation.text.selection.SelectionContainer { Text(code) }
                }
            },
            confirmButton = { TextButton(onClick = { recoveryCode = null }) { Text("확인") } },
        )
    }
    license?.let { text ->
        AlertDialog(
            onDismissRequest = { license = null },
            title = { Text("오픈소스 라이선스") },
            text = { Text(text, Modifier.verticalScroll(rememberScrollState())) },
            confirmButton = { TextButton(onClick = { license = null }) { Text("닫기") } },
        )
    }
    if (erase)
        AlertDialog(
            onDismissRequest = { erase = false },
            title = { Text("모든 기록을 삭제할까요?") },
            text = { Text("일기·미디어·초안·설정과 기기의 암호화 키를 삭제합니다. 외부에 저장한 백업은 삭제되지 않습니다. 되돌릴 수 없습니다.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        erase = false
                        authenticate { model.erase() }
                    }
                ) {
                    Text("인증 후 전체 삭제")
                }
            },
            dismissButton = { TextButton(onClick = { erase = false }) { Text("취소") } },
        )
}
