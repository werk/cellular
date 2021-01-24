package cellular.frontend

import cellular.frontend.Controller.WheelEvent
import com.github.ahnfelt.react4s.{EventHandler, MouseEvent, SyntheticEvent}
import org.scalajs.dom
import org.scalajs.dom.window

import scala.scalajs.js

class Controller() {

    var canvas : dom.html.Canvas = _
    val state = new CpuState(100, 100)

    private var pan : Option[Pan] = None

    private case class Pan(
        initialOffsetX : Double,
        initialOffsetY : Double,
        initialScreenPositionX : Double,
        initialScreenPositionY : Double,
    )

    def onMouseDown(e : MouseEvent) : Unit = {
        e.preventDefault()
        val (screenX, screenY) = eventScreenPosition(e);
        val (unitX, unitY) = eventUnitPosition(e)
        println(s"Click {Screen/Canvas: (${pretty(screenX)} / ${pretty(canvas.width)}, ${pretty(screenY)} / ${pretty(canvas.width)}), Unit: (${pretty(unitX)}, ${pretty(unitY)})}")
        pan = Some(Pan(
            initialOffsetX = state.offsetX,
            initialOffsetY = state.offsetY,
            initialScreenPositionX = screenX,
            initialScreenPositionY = screenY,
        ))
    }

    def onMouseUp(e : MouseEvent) : Unit = {
        e.preventDefault()
        pan = None
    }

    def onMouseMove(e : MouseEvent) : Unit = {
        pan.foreach { p =>
            val (screenX, screenY) = eventScreenPosition(e);
            val deltaScreenX = screenX - p.initialScreenPositionX
            val deltaScreenY = screenY - p.initialScreenPositionY
            val ratio = screenToMapRatio()
            state.offsetX = p.initialOffsetX + deltaScreenX * ratio * -1
            state.offsetY = p.initialOffsetY + deltaScreenY * ratio * -1
            //ensureViewportIsInsideMap();
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
