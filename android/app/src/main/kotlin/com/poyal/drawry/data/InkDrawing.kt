package com.poyal.drawry.data

import android.graphics.*
import com.poyal.drawry.core.*

object InkDrawing {
    fun draw(
        canvas: Canvas,
        strokes: List<InkStroke>,
        geometry: InkGeometry,
        width: Float,
        height: Float,
    ) {
        val paint =
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeCap = Paint.Cap.ROUND
                strokeJoin = Paint.Join.ROUND
            }
        canvas.save()
        canvas.clipRect(0f, 0f, width, height)
        for (stroke in strokes) {
            if (stroke.points.isEmpty()) continue
            paint.color = Color.parseColor(stroke.color)
            paint.strokeWidth =
                (stroke.width * geometry.shortSide * width / geometry.width).toFloat()
            val points = stroke.points.map(geometry::project)
            if (points.size == 1) {
                paint.style = Paint.Style.FILL
                canvas.drawCircle(
                    (points[0].x * width).toFloat(),
                    (points[0].y * height).toFloat(),
                    paint.strokeWidth / 2,
                    paint,
                )
                paint.style = Paint.Style.STROKE
            } else {
                val path = Path()
                points.forEachIndexed { i, p ->
                    if (i == 0) path.moveTo((p.x * width).toFloat(), (p.y * height).toFloat())
                    else path.lineTo((p.x * width).toFloat(), (p.y * height).toFloat())
                }
                canvas.drawPath(path, paint)
            }
        }
        canvas.restore()
    }
}
