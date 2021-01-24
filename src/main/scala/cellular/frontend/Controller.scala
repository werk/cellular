package cellular.frontend

import cellular.frontend.Controller.WheelEvent
import com.github.ahnfelt.react4s.{EventHandler, MouseEvent, SyntheticEvent}
import org.scalajs.dom
import org.scalajs.dom.window

import scala.scalajs.js

class Controller() {

    var canvas : dom.html.Canvas = _
    val state = new CpuState(100, 100)

    private var selection : Option[Selection] = None
    private var pan : Option[Pan] = None

    private case class Selection(
        initialTileX : Int,
        initialTileY : Int,
    )

    private case class Pan(
        initialOffsetX : Double,
        initialOffsetY : Double,
        initialScreenPositionX : Double,
        initialScreenPositionY : Double,
        didMove : Boolean
    )

    def onMouseDown(e : MouseEvent) : Unit = {
        e.preventDefault()
        val (screenX, screenY) = eventScreenPosition(e);
        val (unitX, unitY) = eventUnitPosition(e)
        val (mapX, mapY) = eventMapPosition(e)
        val (tileX, tileY) = eventTilePosition(e)
        println(s"Click {Screen: (${pretty(screenX)}, ${pretty(screenY)}), Map: (${pretty(mapX)}, ${pretty(mapY)}), Tile: (${pretty(tileX)}, ${pretty(tileY)})}")
        if(e.button == 0) {
            val (tileX, tileY) = eventTilePosition(e)
            println((tileX, tileY))
            selection = Some(Selection(tileX, tileY))
            updateSelection(e)
        } else if(e.button == 2) {
            pan = Some(Pan(
                initialOffsetX = state.offsetX,
                initialOffsetY = state.offsetY,
                initialScreenPositionX = screenX,
                initialScreenPositionY = screenY,
                didMove = false
            ))
        }
    }

    def onMouseUp(e : MouseEvent) : Unit = {
        e.preventDefault()
        if(e.button == 0) {
            updateSelection(e)
        } else if(e.button == 2) {
            if(pan.exists(!_.didMove)) {
                selection = None
                updateSelection(e)
            }
        }
        selection = None
        pan = None
    }

    def onMouseMove(e : MouseEvent) : Unit = {
        e.preventDefault()
        if(pan.nonEmpty) {
            if(pan.exists(!_.didMove)) pan = pan.map(_.copy(didMove = true))
            pan.foreach { p =>
                val (screenX, screenY) = eventScreenPosition(e);
                val deltaScreenX = screenX - p.initialScreenPositionX
                val deltaScreenY = screenY - p.initialScreenPositionY
                val ratio = screenToMapRatio()
                state.offsetX = p.initialOffsetX + deltaScreenX * ratio * -1
                state.offsetY = p.initialOffsetY + deltaScreenY * ratio * -1
                //ensureViewportIsInsideMap();
            }
        } else if(selection.nonEmpty) {
            updateSelection(e)
        }
    }

    def onMouseWheel(e : WheelEvent) : Unit = {
        if (e.ctrlKey) e.preventDefault() // Try to avoid browser zooming
        val zoomSpeed = 0.2
        val zoomFactor = if(e.deltaY > 0) 1 + zoomSpeed else 1 / (1 + zoomSpeed)
        val (unitX, unitY) = eventUnitPosition(e)
        val mapWidth = state.zoom
        val mapHeight = state.zoom * (canvas.height.toDouble / canvas.width)
        val oldZoom = state.zoom
        state.zoom *= zoomFactor
        //ensureViewportIsInsideMap();
        val actualZoomFactor = state.zoom / oldZoom;
        val deltaOffsetX = unitX * (actualZoomFactor - 1) * mapWidth;
        val deltaOffsetY = unitY * (actualZoomFactor - 1) * mapHeight;
        state.offsetX -= deltaOffsetX
        state.offsetY -= deltaOffsetY
        //ensureViewportIsInsideMap();
    }

    private def updateSelection(event : MouseEvent) : Unit = {
        selection match {
            case Some(s) =>
                val (tileX, tileY) = eventTilePosition(event)
                state.selectionX1 = Math.min(s.initialTileX, tileX)
                state.selectionX2 = Math.max(s.initialTileX, tileX) + 1
                state.selectionY1 = Math.min(s.initialTileY, tileY)
                state.selectionY2 = Math.max(s.initialTileY, tileY) + 1
            case None =>
                state.selectionX1 = 0
                state.selectionX2 = 0
                state.selectionY1 = 0
                state.selectionY2 = 0
        }
    }

    private def screenToMapRatio() = {
        state.zoom / canvas.width;
    }

    private def eventScreenPosition(event : MouseEvent) : (Double, Double) = {
        val r = canvas.getBoundingClientRect()
        val x = event.clientX - r.left
        val cssHeight = canvas.clientHeight;
        val y = cssHeight - (event.clientY - r.top)
        val realToCssPixels = window.devicePixelRatio
        (x * realToCssPixels, y * realToCssPixels)
    }

    private def eventUnitPosition(event : MouseEvent) : (Double, Double) = {
        val (screenX, screenY) = eventScreenPosition(event);
        (screenX / canvas.width, screenY / canvas.height);
    }

    private def eventTilePosition(event : MouseEvent) : (Int, Int) = {
        val (mapX, mapY) = eventMapPosition(event);
        (mapX.toInt, mapY.toInt)
    }

    private def eventMapPosition(event : MouseEvent) : (Double, Double) = {
        val (screenX, screenY) = eventScreenPosition(event);
        screenToMapPosition(screenX, screenY)
    }

    private def screenToMapPosition(screenX : Double, screenY : Double) : (Double, Double) = {
        val ratio = this.screenToMapRatio()
        val mapX = screenX * ratio + state.offsetX + 1
        val mapY = screenY * ratio + state.offsetY + 1
        (mapX, mapY);
    }

    private def pretty(d : Double) : String = "%.2f".format(d)

}

object Controller {
    def onMouseMove(handler : MouseEvent => Unit) = EventHandler("onMouseMove", handler.asInstanceOf[SyntheticEvent => Unit])
    def onWheel(handler : WheelEvent => Unit) = EventHandler("onWheel", handler.asInstanceOf[SyntheticEvent => Unit])

    @js.native
    trait WheelEvent extends MouseEvent {
        val deltaMode : Double
        val deltaX : Double
        val deltaY : Double
        val deltaZ : Double
    }

}
