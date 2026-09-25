package com.poyal.drawry

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

val SketchFont = FontFamily(Font(R.font.nanum_pen_script))

@Composable
fun SketchTheme(content: @Composable () -> Unit) {
    val dark = isSystemInDarkTheme()
    val colors =
        if (dark)
            darkColorScheme(
                primary = Color(0xFFD2BDD9),
                onPrimary = Color(0xFF302438),
                primaryContainer = Color(0xFF493C50),
                onPrimaryContainer = Color(0xFFECE0EF),
                background = Color(0xFF211E1B),
                onBackground = Color(0xFFF3EDE2),
                surface = Color(0xFF292521),
                onSurface = Color(0xFFF3EDE2),
                surfaceVariant = Color(0xFF39332D),
                onSurfaceVariant = Color(0xFFC6BEB1),
                outline = Color(0xFF9C9285),
                outlineVariant = Color(0xFF4A4239),
                secondaryContainer = Color(0xFF433A47),
                onSecondaryContainer = Color(0xFFE9D8EF),
            )
        else
            lightColorScheme(
                primary = Color(0xFF78658F),
                onPrimary = Color.White,
                primaryContainer = Color(0xFFECE4F0),
                onPrimaryContainer = Color(0xFF46364F),
                background = Color(0xFFF7F3EA),
                onBackground = Color(0xFF302C29),
                surface = Color(0xFFFFFCF5),
                onSurface = Color(0xFF302C29),
                surfaceVariant = Color(0xFFEDE7DC),
                onSurfaceVariant = Color(0xFF6E655D),
                outline = Color(0xFF83776B),
                outlineVariant = Color(0xFFDED5C7),
                secondaryContainer = Color(0xFFECE4F0),
                onSecondaryContainer = Color(0xFF5D4A71),
            )
    MaterialTheme(
        colorScheme = colors,
        shapes =
            Shapes(
                small = RoundedCornerShape(8.dp),
                medium = RoundedCornerShape(12.dp),
                large = RoundedCornerShape(16.dp),
            ),
        content = content,
    )
}

@Composable
fun SketchTitle(text: String, modifier: Modifier = Modifier, maxLines: Int = Int.MAX_VALUE) {
    Text(
        text,
        modifier,
        fontFamily = SketchFont,
        fontSize = 32.sp,
        color = MaterialTheme.colorScheme.onSurface,
        maxLines = maxLines,
        overflow = androidx.compose.ui.text.style.TextOverflow.Ellipsis,
    )
}

@Composable
fun NotebookMark(modifier: Modifier = Modifier) {
    val ink = MaterialTheme.colorScheme.primary
    val paper = MaterialTheme.colorScheme.surface
    Canvas(modifier.size(128.dp)) {
        val w = size.width
        val h = size.height
        drawRoundRect(
            paper,
            Offset(w * .14f, h * .10f),
            androidx.compose.ui.geometry.Size(w * .69f, h * .78f),
            androidx.compose.ui.geometry.CornerRadius(w * .05f),
        )
        drawRoundRect(
            ink,
            Offset(w * .14f, h * .10f),
            androidx.compose.ui.geometry.Size(w * .69f, h * .78f),
            androidx.compose.ui.geometry.CornerRadius(w * .05f),
            style = Stroke(2.dp.toPx()),
        )
        drawLine(ink, Offset(w * .26f, h * .10f), Offset(w * .26f, h * .88f), 2.dp.toPx())
        drawCircle(ink.copy(alpha = .55f), w * .055f, Offset(w * .64f, h * .33f))
        val path =
            Path().apply {
                moveTo(w * .35f, h * .60f)
                lineTo(w * .49f, h * .44f)
                lineTo(w * .58f, h * .54f)
                lineTo(w * .72f, h * .42f)
            }
        drawPath(path, ink, style = Stroke(2.dp.toPx()))
        drawLine(
            ink.copy(alpha = .4f),
            Offset(w * .36f, h * .71f),
            Offset(w * .70f, h * .71f),
            1.dp.toPx(),
        )
    }
}

@Composable
fun PaperTape(modifier: Modifier = Modifier) {
    val color = MaterialTheme.colorScheme.primary.copy(alpha = .18f)
    Canvas(modifier.size(48.dp, 12.dp)) {
        val path =
            Path().apply {
                moveTo(2f, size.height * .14f)
                lineTo(size.width, 0f)
                lineTo(size.width - 2f, size.height * .9f)
                lineTo(0f, size.height)
                close()
            }
        drawPath(path, color)
    }
}

@Composable
fun EmptyNotebook(title: String, description: String, action: (() -> Unit)? = null) {
    Column(
        Modifier.fillMaxWidth().padding(28.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        NotebookMark()
        SketchTitle(title)
        Text(
            description,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            style = MaterialTheme.typography.bodyMedium,
        )
        if (action != null)
            Button(onClick = action, modifier = Modifier.heightIn(min = 48.dp)) {
                Text("첫 페이지 채우기")
            }
    }
}
