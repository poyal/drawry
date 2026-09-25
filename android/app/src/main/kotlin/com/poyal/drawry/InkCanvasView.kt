package com.poyal.drawry

import android.content.Context
import android.graphics.*
import android.view.MotionEvent
import android.view.ScaleGestureDetector
import android.view.View
import com.poyal.drawry.core.*
import com.poyal.drawry.data.InkDrawing
import kotlin.math.*

/** Only vector paths are redrawn while dragging; the filtered bitmap is cached by the caller. */
class InkCanvasView(context: Context) : View(context) {
    var bitmap: Bitmap? = null
    var geometry: InkGeometry? = null
    var recipe = EditRecipe()
    var mode = "view"
    var color = "#302C29"
    var penWidth = .006
    var onStroke: (InkStroke) -> Unit = {}
    var onErase: (String) -> Unit = {}
    var onPosition: (InkPoint) -> Unit = {}
    var onLimit: () -> Unit = {}
    private var zoom = 1f
    private var panX = 0f
    private var panY = 0f
    private var previousX = 0f
    private var previousY = 0f
    private var multi = false
    private var active: InkStroke? = null
    private var limited = false
    private val area = RectF()
    private val scaleDetector =
        ScaleGestureDetector(
            context,
            object : ScaleGestureDetector.SimpleOnScaleGestureListener() {
                override fun onScale(detector: ScaleGestureDetector): Boolean {
                    zoom = (zoom * detector.scaleFactor).coerceIn(1f, 5f)
                    if (zoom == 1f) {
                        panX = 0f
                        panY = 0f
                    }
                    invalidate()
                    return true
                }
            },
        )

    init {
        contentDescription = "사진 캔버스 · 한 손가락으로 그리기, 두 손가락으로 확대와 이동"
        isFocusable = true
    }

    fun resetViewport() {
        zoom = 1f
        panX = 0f
        panY = 0f
        active = null
        invalidate()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val photo = bitmap ?: return
        val g = geometry ?: return
        val fit = min(width.toFloat() / photo.width, height.toFloat() / photo.height)
        val w = photo.width * fit * zoom
        val h = photo.height * fit * zoom
        panX = panX.coerceIn(-max(0f, (w - width) / 2), max(0f, (w - width) / 2))
        panY = panY.coerceIn(-max(0f, (h - height) / 2), max(0f, (h - height) / 2))
        area.set(
            (width - w) / 2 + panX,
            (height - h) / 2 + panY,
            (width + w) / 2 + panX,
            (height + h) / 2 + panY,
        )
        canvas.save()
        canvas.clipRect(0, 0, width, height)
        canvas.drawBitmap(
            photo,
            null,
            area,
            Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG),
        )
        canvas.translate(area.left, area.top)
        InkDrawing.draw(
            canvas,
            recipe.strokes + listOfNotNull(active),
            g,
            area.width(),
            area.height(),
        )
        canvas.clipRect(0f, 0f, area.width(), area.height())
        recipe.overlays.forEach { overlay ->
            val paint =
                Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color =
                        runCatching { Color.parseColor(overlay.color) }.getOrDefault(Color.WHITE)
                    textSize = (overlay.size * area.width()).toFloat()
                    textAlign = Paint.Align.CENTER
                    setShadowLayer(3f, 0f, 2f, Color.BLACK)
                }
            canvas.drawText(
                overlay.text,
                (overlay.x * area.width()).toFloat(),
                (overlay.y * area.height()).toFloat(),
                paint,
            )
        }
        canvas.restore()
    }

    private fun point(x: Float, y: Float) =
        InkPoint(
            ((x - area.left) / area.width()).toDouble().coerceIn(0.0, 1.0),
            ((y - area.top) / area.height()).toDouble().coerceIn(0.0, 1.0),
        )

    private fun sample(x: Float, y: Float) {
        val g = geometry ?: return
        if (mode == "erase") {
            val p = point(x, y)
            recipe.strokes
                .lastOrNull {
                    g.hits(it, p, 12 * resources.displayMetrics.density * g.width / area.width())
                }
                ?.let { onErase(it.id) }
        } else if (mode == "pen" && !limited) {
            val current = active ?: return
            if (recipe.strokes.sumOf { it.points.size } + current.points.size >= MAX_INK_POINTS) {
                if (current.points.isNotEmpty()) onStroke(current)
                active = null
                limited = true
                onLimit()
                return
            }
            val p = g.unproject(point(x, y))
            val last = current.points.lastOrNull()
            if (
                last == null ||
                    hypot((p.x - last.x) * g.sourceWidth, (p.y - last.y) * g.sourceHeight) >
                        g.width / area.width()
            )
                active = current.copy(points = current.points + p)
        }
        invalidate()
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        if (bitmap == null || area.isEmpty) return false
        scaleDetector.onTouchEvent(event)
        val cx =
            (0 until event.pointerCount).sumOf { event.getX(it).toDouble() }.toFloat() /
                event.pointerCount
        val cy =
            (0 until event.pointerCount).sumOf { event.getY(it).toDouble() }.toFloat() /
                event.pointerCount
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                multi = false
                limited = false
                parent?.requestDisallowInterceptTouchEvent(mode != "view" || zoom > 1)
                if (mode == "pen" && area.contains(event.x, event.y)) {
                    if (
                        recipe.strokes.size >= MAX_INK_STROKES ||
                            recipe.strokes.sumOf { it.points.size } >= MAX_INK_POINTS
                    ) {
                        limited = true
                        onLimit()
                    } else {
                        active = InkStroke(color = color, width = penWidth)
                        sample(event.x, event.y)
                    }
                } else if (mode == "erase") sample(event.x, event.y)
            }
            MotionEvent.ACTION_POINTER_DOWN -> {
                multi = true
                active = null
                parent?.requestDisallowInterceptTouchEvent(true)
            }
            MotionEvent.ACTION_MOVE -> {
                if (event.pointerCount > 1 || (mode == "view" && zoom > 1)) {
                    panX += cx - previousX
                    panY += cy - previousY
                } else if (!multi) sample(event.x, event.y)
            }
            MotionEvent.ACTION_UP -> {
                if (!multi) {
                    active?.takeIf { it.points.isNotEmpty() }?.let(onStroke)
                    if (mode == "text" && area.contains(event.x, event.y))
                        onPosition(point(event.x, event.y))
                    performClick()
                }
                active = null
                parent?.requestDisallowInterceptTouchEvent(false)
            }
            MotionEvent.ACTION_CANCEL -> {
                active = null
                parent?.requestDisallowInterceptTouchEvent(false)
            }
        }
        previousX = cx
        previousY = cy
        invalidate()
        return true
    }

    override fun performClick(): Boolean {
        super.performClick()
        return true
    }
}
