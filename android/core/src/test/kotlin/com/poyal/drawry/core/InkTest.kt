package com.poyal.drawry.core

import kotlin.test.*
import kotlinx.serialization.encodeToString

class InkTest {
    @Test
    fun v1ReadsWithoutStrokesAndV2RoundTrips() {
        val old =
            """{"version":1,"quarterTurns":0,"squareCrop":false,"filter":"original","overlays":[]}"""
        assertTrue(wireJson.decodeFromString<EditRecipe>(old).strokes.isEmpty())
        val recipe =
            EditRecipe(
                version = 2,
                strokes = listOf(InkStroke(points = listOf(InkPoint(.2, .3), InkPoint(.7, .8)))),
            )
        recipe.validateInk()
        assertEquals(recipe, wireJson.decodeFromString<EditRecipe>(wireJson.encodeToString(recipe)))
        assertFails { recipe.copy(version = 1).validateInk() }
    }

    @Test
    fun transformAndCropRemainAttachedToSource() {
        for (turn in 0..3) for (square in listOf(false, true)) {
            val g = InkGeometry(400.0, 300.0, turn, square)
            for (p in listOf(InkPoint(.3, .3), InkPoint(.5, .5), InkPoint(.7, .7))) {
                val q = g.unproject(g.project(p))
                assertEquals(p.x, q.x, 1e-9)
                assertEquals(p.y, q.y, 1e-9)
            }
        }
        val rotated = InkGeometry(400.0, 300.0, 1, false).project(InkPoint(.25, .25))
        assertEquals(InkPoint(.75, .25), rotated)
        val cropped = InkGeometry(400.0, 300.0, 0, true).project(InkPoint(0.0, 0.0))
        assertTrue(cropped.x < 0) // Clip visually; do not destroy the hidden source point.
    }

    @Test
    fun boundsFiniteColorsAndStrokeErasing() {
        val stroke = InkStroke(points = listOf(InkPoint(.2, .5), InkPoint(.8, .5)))
        val recipe = EditRecipe(version = 2, strokes = listOf(stroke))
        val g = InkGeometry(400.0, 300.0, 0, false)
        assertTrue(g.hits(stroke, InkPoint(.5, .51), 12.0))
        assertFalse(g.hits(stroke, InkPoint(.5, .9), 12.0))
        assertFails { recipe.copy(strokes = listOf(stroke.copy(color = "red"))).validateInk() }
        assertFails { recipe.copy(strokes = listOf(stroke.copy(width = Double.NaN))).validateInk() }
        assertFails {
            recipe
                .copy(strokes = listOf(stroke.copy(points = listOf(InkPoint(Double.NaN, .5)))))
                .validateInk()
        }
        assertFails {
            recipe
                .copy(
                    strokes = List(257) { stroke.copy(id = java.util.UUID.randomUUID().toString()) }
                )
                .validateInk()
        }
        assertFails {
            recipe
                .copy(strokes = listOf(stroke.copy(points = List(20_001) { InkPoint(.5, .5) })))
                .validateInk()
        }
    }
}
