package cellular.frontend.component

import java.math.BigInteger
import java.security.MessageDigest

import com.github.ahnfelt.react4s._
import org.scalajs.dom
import dom.raw.{HTMLImageElement, WebGLRenderingContext => GL}
import cellular.frontend.{CpuState, IVec2}
import cellular.frontend.webgl.FactoryGl
import cellular.frontend.webgl.FactoryGl.{FragmentShader, UniformFloat, UniformInt, UniformVec2}
import org.scalajs.dom.window

import scala.scalajs.js
import scala.util.Random

case class CanvasComponent(
    stepCodeP : P[String],
    viewCodeP : P[String],
    seedP : P[Int],
    materialsImage: P[HTMLImageElement],
) extends Component[NoEmit] {

    val state = new CpuState(100, 100)
    var pan : Option[Pan] = None
    var canvas : dom.html.Canvas = null

    override def render(get : Get) : Node = {
        val stepCode = get(stepCodeP)
        val viewCode = get(viewCodeP)
        val seed = get(seedP)
        val canvasElement = E.canvas(
            A.onMouseDown(onMouseDown),
            A.onMouseUp(onMouseUp),
            EventHandler("onMouseMove", (onMouseMove _).asInstanceOf[SyntheticEvent => Unit]),
            S.width.percent(100),
            S.height.percent(100),
        ).withRef(withCanvas(stepCode, viewCode, seed, get(materialsImage), _))
        canvasElement
    }

    def onMouseDown(e : MouseEvent) : Unit = {
        val (screenX, screenY) = eventScreenPosition(e);
        pan = Some(Pan(
            initialOffsetX = state.offsetX,
            initialOffsetY = state.offsetY,
            initialScreenPositionX = screenX,
            initialScreenPositionY = screenY,
        ))
    }

    def onMouseUp(e : MouseEvent) : Unit = {
        pan = None
    }

    def onMouseMove(e : MouseEvent) : Unit = {
        pan.foreach { p =>
            val (screenX, screenY) = eventScreenPosition(e);
            val deltaScreenX = screenX - p.initialScreenPositionX
            val deltaScreenY = screenY - p.initialScreenPositionY
            val ratio = screenToMapRatio()
            state.offsetX = p.initialOffsetX + deltaScreenX * ratio * -1
            state.offsetY = p.initialOffsetY + deltaScreenY * ratio
            //ensureViewportIsInsideMap();
        }

    }

    def screenToMapRatio() = {
        state.zoom / canvas.width;
    }

    def eventScreenPosition(event : MouseEvent) : (Double, Double) = {
        val r = canvas.getBoundingClientRect()
        val x = event.clientX - r.left
        val y = event.clientY - r.top
        val realToCssPixels = window.devicePixelRatio
        (x * realToCssPixels, y * realToCssPixels)
    }

    def withCanvas(
        stepCode : String,
        viewCode : String,
        seed : Int,
        materialsImage: HTMLImageElement,
        e : Any
    ) : Unit = if(e != null) {
        canvas = e.asInstanceOf[dom.html.Canvas]
        val gl = canvas.getContext("webgl2").asInstanceOf[GL]
        val timeUniform = new UniformFloat()
        val stepUniform = new UniformInt()
        val seedlingUniform = new UniformInt()
        val offsetUniform = new UniformVec2()
        val zoomUniform = new UniformFloat()
        val renderer = new FactoryGl(
            gl = gl,
            stepShader = FragmentShader(
                stepCode,
                List(
                    "step" -> stepUniform,
                    "seedling" -> seedlingUniform,
                ),
            ),
            viewShader = FragmentShader(
                viewCode,
                List(
                    "t" -> timeUniform,
                    "offset" -> offsetUniform,
                    "zoom" -> zoomUniform,
                ),
            ),
            materialsImage = materialsImage,
            stateSize = IVec2(state.sizeX, state.sizeY)
        )
        start(renderer, timeUniform, stepUniform, seedlingUniform, seed, offsetUniform, zoomUniform)
    }

    def start(
        renderer : FactoryGl,
        timeUniform : UniformFloat,
        stepUniform : UniformInt,
        seedlingUniform : UniformInt,
        seed : Int,
        offsetUniform : UniformVec2,
        zoomUniform : UniformFloat,
    ) {
        val t0 = System.currentTimeMillis()
        var tick = -1
        var step = -1
        val random = new Random(seed)

        def loop(x : Double) {
            val t = (System.currentTimeMillis() - t0) / 1000f
            if(t.toInt > tick) {
                tick = t.toInt
                step += 1
                seedlingUniform.value = random.nextInt()
                stepUniform.value = step
                offsetUniform.x = state.offsetX.toFloat
                offsetUniform.y = state.offsetY.toFloat
                zoomUniform.value = state.zoom.toFloat
                renderer.simulate()
            }
            timeUniform.value = t
            renderer.draw()
            dom.window.requestAnimationFrame(loop)
        }

        dom.window.requestAnimationFrame(loop)
    }


    case class Pan(
        initialOffsetX : Double,
        initialOffsetY : Double,
        initialScreenPositionX : Double,
        initialScreenPositionY : Double,
    )
}
