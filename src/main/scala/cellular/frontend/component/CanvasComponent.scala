package cellular.frontend.component

import java.math.BigInteger
import java.security.MessageDigest

import com.github.ahnfelt.react4s._
import org.scalajs.dom
import dom.raw.{HTMLImageElement, WebGLRenderingContext => GL}
import cellular.frontend.IVec2
import cellular.frontend.webgl.FactoryGl
import cellular.frontend.webgl.FactoryGl.{FragmentShader, UniformFloat, UniformInt}

import scala.util.Random

case class CanvasComponent(
    stepCodeP : P[String],
    viewCodeP : P[String],
    seedP : P[Int],
    materialsImage: P[HTMLImageElement],
) extends Component[NoEmit] {

    override def render(get : Get) : Node = {
        val stepCode = get(stepCodeP)
        val viewCode = get(viewCodeP)
        val seed = get(seedP)
        val canvas = E.canvas(
            S.width.percent(100),
            S.height.percent(100),
        ).withRef(withCanvas(stepCode, viewCode, seed, get(materialsImage), _))
        canvas
    }

    def withCanvas(
        stepCode : String,
        viewCode : String,
        seed : Int,
        materialsImage: HTMLImageElement,
        e : Any
    ) : Unit = if(e != null) {
        val canvas = e.asInstanceOf[dom.html.Canvas]
        val gl = canvas.getContext("webgl2").asInstanceOf[GL]
        val timeUniform = new UniformFloat()
        val stepUniform = new UniformInt()
        val seedlingUniform = new UniformInt()
        val renderer = new FactoryGl(
            gl = gl,
            stepShader = FragmentShader(
                stepCode,
                List("step" -> stepUniform, "seedling" -> seedlingUniform),
            ),
            viewShader = FragmentShader(
                viewCode,
                List("t" -> timeUniform),
            ),
            materialsImage = materialsImage,
            stateSize = IVec2(100, 100)
        )
        start(renderer, timeUniform, stepUniform, seedlingUniform, seed)
    }

    def start(
        renderer : FactoryGl,
        timeUniform : UniformFloat,
        stepUniform : UniformInt,
        seedlingUniform : UniformInt,
        seed : Int
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
                println(s"Simulate $step")
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
