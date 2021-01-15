package cellular.frontend.component

import com.github.ahnfelt.react4s._
import cellular.frontend.webgl.WebGlFunctions
import org.scalajs.dom.ext.Ajax
import org.scalajs.dom.window

import scala.concurrent.ExecutionContext.Implicits.global

case class MainComponent() extends Component[NoEmit] {

    val materialsFile = State(getQueryParameter("materials-file").getOrElse("materials.png"))
    val stepFile = State(getQueryParameter("step-file").getOrElse("step.glsl"))
    val viewFile = State(getQueryParameter("view-file").getOrElse("view.glsl"))

    val materialsLoader = Loader(this, materialsFile) { url =>
        WebGlFunctions.loadImage(url)
    }

    val stepCodeLoader = Loader(this, stepFile) { url =>
        Ajax.get(url).map { request =>
            request.responseText
        }
    }

    val viewCodeLoader = Loader(this, viewFile) { url =>
        Ajax.get(url).map ( request =>
            request.responseText
        )
    }

    override def render(get : Get) : Node = {
        val stepError = get(stepCodeLoader) match {
            case Loader.Loading() => E.div(Text("Loading step code from " + get(stepFile)))
            case Loader.Error(throwable) => E.div(Text("Failed to load " + get(stepFile)))
            case Loader.Result(value) => Tags()
        }

        val viewError = get(viewCodeLoader) match {
            case Loader.Loading() => E.div(Text("Loading view code from " + get(viewFile)))
            case Loader.Error(throwable) => E.div(Text("Failed to load " + get(viewFile)))
            case Loader.Result(value) => Tags()
        }

        val seed = 42

        val canvas = for {
            stepCode <- get(stepCodeLoader.result)
            viewCode <- get(viewCodeLoader.result)
            materialsImage <- get(materialsLoader.result)
        } yield Component(CanvasComponent, stepCode, viewCode, seed, materialsImage)

        //val glsl = compile(SandAndWater.declarations)
        E.div(
            S.height.percent(100),
            viewError,
            stepError,
            Tags(canvas),
        )
    }

    def getQueryParameter(name : String) : Option[String] = {
        import org.scalajs.dom.experimental.URLSearchParams
        val p = new URLSearchParams(window.location.search)
        Option(p.get(name))
    }

}