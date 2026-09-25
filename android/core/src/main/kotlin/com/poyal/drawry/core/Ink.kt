package com.poyal.drawry.core

import java.util.UUID
import kotlin.math.*
import kotlinx.serialization.Serializable

@Serializable data class InkPoint(val x: Double, val y: Double)

@Serializable
data class InkStroke(
    val id: String = UUID.randomUUID().toString(),
    val color: String = "#302C29",
    val width: Double = .006,
    val points: List<InkPoint> = emptyList(),
)

const val MAX_INK_STROKES = 256
const val MAX_INK_POINTS = 20_000

fun EditRecipe.validateInk() {
    require(version in 1..2 && (version == 2 || strokes.isEmpty()))
    require(
        strokes.size <= MAX_INK_STROKES &&
            strokes.sumOf { it.points.size.toLong() } <= MAX_INK_POINTS
    )
    require(strokes.map { it.id }.distinct().size == strokes.size)
    strokes.forEach { stroke ->
        UUID.fromString(stroke.id)
        require(Regex("^#[0-9A-Fa-f]{6}$").matches(stroke.color))
        require(
            stroke.width.isFinite() && stroke.width in 0.001..0.05 && stroke.points.isNotEmpty()
        )
        require(
            stroke.points.all {
                it.x.isFinite() && it.y.isFinite() && it.x in 0.0..1.0 && it.y in 0.0..1.0
            }
        )
    }
}

/** Original is orientation-normalized. Output is clockwise-rotated, then center-cropped. */
class InkGeometry(
    val sourceWidth: Double,
    val sourceHeight: Double,
    val turns: Int,
    val square: Boolean,
) {
    init {
        require(sourceWidth > 0 && sourceHeight > 0 && turns in 0..3)
    }

    private val rotatedWidth = if (turns % 2 == 0) sourceWidth else sourceHeight
    private val rotatedHeight = if (turns % 2 == 0) sourceHeight else sourceWidth
    val width = if (square) min(rotatedWidth, rotatedHeight) else rotatedWidth
    val height = if (square) width else rotatedHeight
    private val dx = (rotatedWidth - width) / 2
    private val dy = (rotatedHeight - height) / 2
    val shortSide = min(sourceWidth, sourceHeight)

    fun project(p: InkPoint): InkPoint {
        val x = p.x * sourceWidth
        val y = p.y * sourceHeight
        val q =
            when (turns) {
                1 -> InkPoint(sourceHeight - y, x)
                2 -> InkPoint(sourceWidth - x, sourceHeight - y)
                3 -> InkPoint(y, sourceWidth - x)
                else -> InkPoint(x, y)
            }
        return InkPoint((q.x - dx) / width, (q.y - dy) / height)
    }

    fun unproject(p: InkPoint): InkPoint {
        val x = p.x.coerceIn(0.0, 1.0) * width + dx
        val y = p.y.coerceIn(0.0, 1.0) * height + dy
        val q =
            when (turns) {
                1 -> InkPoint(y, sourceHeight - x)
                2 -> InkPoint(sourceWidth - x, sourceHeight - y)
                3 -> InkPoint(sourceWidth - y, x)
                else -> InkPoint(x, y)
            }
        return InkPoint(
            (q.x / sourceWidth).coerceIn(0.0, 1.0),
            (q.y / sourceHeight).coerceIn(0.0, 1.0),
        )
    }

    fun hits(stroke: InkStroke, point: InkPoint, tolerance: Double): Boolean {
        val pts = stroke.points.map { project(it).let { q -> InkPoint(q.x * width, q.y * height) } }
        val p = InkPoint(point.x * width, point.y * height)
        val radius = tolerance + stroke.width * shortSide / 2
        if (pts.size == 1) return hypot(p.x - pts[0].x, p.y - pts[0].y) <= radius
        return pts.zipWithNext().any { (a, b) ->
            val vx = b.x - a.x
            val vy = b.y - a.y
            val length = vx * vx + vy * vy
            val t =
                if (length == 0.0) 0.0
                else (((p.x - a.x) * vx + (p.y - a.y) * vy) / length).coerceIn(0.0, 1.0)
            hypot(p.x - a.x - t * vx, p.y - a.y - t * vy) <= radius
        }
    }
}
