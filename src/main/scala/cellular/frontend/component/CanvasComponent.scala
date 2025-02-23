package cellular.frontend.component

import cellular.frontend.webgl.FactoryGl
import cellular.frontend.webgl.FactoryGl.{FragmentShader, UniformFloat, UniformIVec4, UniformInt, UniformVec2}
import cellular.frontend.{Controller, IVec2, InitialMap}
import cellular.language.TypeContext
import com.github.ahnfelt.react4s._
import org.scalajs.dom
import org.scalajs.dom.raw.{Event, HTMLImageElement, WebGLRenderingContext => GL}

import scala.scalajs.js
import scala.util.Random

case class CanvasComponent(
    context : P[TypeContext],
    stepCodeP : P[List[String]],
    viewCodeP : P[String],
    seedP : P[Int],
    materialsImage: P[HTMLImageElement],
) extends Component[NoEmit] {

    val sizeX = 1000
    val sizeY = 1000
    var controller = new Controller(Get.Unsafe(context), sizeX, sizeY)

    case class GlobalHandlers(
        onKeyDown : KeyboardEvent => Unit,
        onCut : Event => Unit,
        onCopy : Event => Unit,
        onPaste : Event => Unit,
    )
    var globalHandlers : Option[GlobalHandlers] = None

    override def componentWillRender(get : Get) : Unit = {
        if(globalHandlers.isEmpty) {
            val handlers = GlobalHandlers(
                onKeyDown = controller.onKeyDown(_),
                onCut = controller.onCut(_),
                onCopy = controller.onCopy(_),
                onPaste = controller.onPaste(_)
            )
            globalHandlers = Some(handlers)
            dom.document.addEventListener("keydown", handlers.onKeyDown, useCapture = false)
            dom.document.addEventListener("cut", handlers.onCut, useCapture = false)
            dom.document.addEventListener("copy", handlers.onCopy, useCapture = false)
            dom.document.addEventListener("paste", handlers.onPaste, useCapture = false)
        }
    }

    override def componentWillUnmount(get : Get) : Unit = {
        for(handlers <- globalHandlers) {
            dom.document.removeEventListener("keydown", handlers.onKeyDown, useCapture = false)
            dom.document.removeEventListener("cut", handlers.onCut, useCapture = false)
            dom.document.removeEventListener("copy", handlers.onCopy, useCapture = false)
            dom.document.removeEventListener("paste", handlers.onPaste, useCapture = false)
        }
    }

    override def render(get : Get) : Node = {
        val stepCode = get(stepCodeP)
        val viewCode = get(viewCodeP)
        val seed = get(seedP)
        val canvasElement = E.canvas(
            A.onMouseDown(controller.onMouseDown),
            A.onMouseUp(controller.onMouseUp),
            Controller.onMouseMove(controller.onMouseMove),
            Controller.onWheel(controller.onMouseWheel),
            S.width.percent(100),
            S.height.percent(100),
        ).withRef(withCanvas(stepCode, viewCode, seed, get(materialsImage), _))
        canvasElement
    }

    def withCanvas(
        stepCode : List[String],
        viewCode : String,
        seed : Int,
        materialsImage: HTMLImageElement,
        e : Any
    ) : Unit = if(e != null) {
        val canvas = e.asInstanceOf[dom.html.Canvas]
        controller.canvas = canvas
        val gl = canvas.getContext("webgl2").asInstanceOf[GL]
        dom.document.asInstanceOf[js.Dynamic].gl = gl // TODO remove
        val timeUniform = new UniformFloat()
        val stepUniform = new UniformInt()
        val seedlingUniform = new UniformInt()
        val offsetUniform = new UniformVec2()
        val zoomUniform = new UniformFloat()
        val selectionUniform = new UniformIVec4()
        val renderer = new FactoryGl(
            gl = gl,
            stepShaders = stepCode.map { code => FragmentShader(
                code,
                List(
                    "step" -> stepUniform,
                    "seedling" -> seedlingUniform,
                ),
            )},
            viewShader = FragmentShader(
                viewCode,
                List(
                    "t" -> timeUniform,
                    "offset" -> offsetUniform,
                    "zoom" -> zoomUniform,
                    "selection" -> selectionUniform,
                ),
            ),
            materialsImage = materialsImage,
            stateSize = IVec2(controller.state.sizeX, controller.state.sizeY)
        )
        controller.factoryGl = renderer
        val c = Get.Unsafe(context)
        generateMap(renderer, c)
        start(renderer, timeUniform, stepUniform, seedlingUniform, seed, offsetUniform, zoomUniform, selectionUniform)
    }

    def generateMap(renderer : FactoryGl, context : TypeContext) {
        val map = new InitialMap(context, sizeX, sizeY).array
        renderer.setCellArray(0, 0, sizeX, sizeY, map)
    }

    def start(
        renderer : FactoryGl,
        timeUniform : UniformFloat,
        stepUniform : UniformInt,
        seedlingUniform : UniformInt,
        seed : Int,
        offsetUniform : UniformVec2,
        zoomUniform : UniformFloat,
        selectionUniform : UniformIVec4,
    ) {
        val t0 = System.currentTimeMillis()
        var tick = -1
        var step = -1
        val random = new Random(seed)

        def loop(x : Double) {
            val t = (System.currentTimeMillis() - t0) / 100f
            offsetUniform.x = controller.state.offsetX.toFloat
            offsetUniform.y = controller.state.offsetY.toFloat
            zoomUniform.value = controller.state.zoom.toFloat
            selectionUniform.x = controller.state.selectionX1
            selectionUniform.y = controller.state.selectionY1
            selectionUniform.z = controller.state.selectionX2
            selectionUniform.w = controller.state.selectionY2
            if(t.toInt > tick && !controller.state.paused) {
                tick = t.toInt
                step += 1
                seedlingUniform.value = random.nextInt()
                stepUniform.value = step
                renderer.simulate()
            }
            timeUniform.value = t
            renderer.draw()
            dom.window.requestAnimationFrame(loop)
        }

        dom.window.requestAnimationFrame(loop)
    }
}
