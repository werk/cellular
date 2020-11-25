package cellular.frontend.component

import com.github.ahnfelt.react4s._
import cellular.frontend.webgl.WebGlFunctions
import org.scalajs.dom.ext.Ajax

import scala.concurrent.ExecutionContext.Implicits.global

case class MainComponent() extends Component[NoEmit] {

    val materialsLoader = Loader(this, State("materials.png")) { url =>
        WebGlFunctions.loadImage(url)
    }

    val stepCodeLoader = Loader(this, State("step.glsl")) { url =>
        Ajax.get(url).map { request =>
            request.responseText
        }
    }

    val viewCodeLoader = Loader(this, State("view.glsl")) { url =>
        Ajax.get(url).map ( request =>
            request.responseText
        )
    }

    override def render(get : Get) : Node = {
        val stepError = get(stepCodeLoader) match {
            case Loader.Loading() => Text("Loading step code")
            case Loader.Error(throwable) => Text("Failed to step view code")
            case Loader.Result(value) => Tags()
        }

        val viewError = get(viewCodeLoader) match {
            case Loader.Loading() => Text("Loading view code")
            case Loader.Error(throwable) => Text("Failed to load view code")
            case Loader.Result(value) => Tags()
        }

        val canvas = for {
            stepCode <- get(stepCodeLoader.result)
            viewCode <- get(viewCodeLoader.result)
            materialsImage <- get(materialsLoader.result)
        } yield Component(CanvasComponent, stepCode, viewCode, materialsImage)

        //val glsl = compile(SandAndWater.declarations)
        E.div(
            S.height.percent(100),
            viewError,
            stepError,
            Tags(canvas),
        )
    }

}