package cellular.frontend.component

import com.github.ahnfelt.react4s._
import cellular.frontend.webgl.WebGlFunctions
import cellular.language.{CompileError, Compiler, DGroup, Parser, TypeContext}
import org.scalajs.dom.ext.Ajax
import org.scalajs.dom.window

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future

case class MainComponent() extends Component[NoEmit] {

    val cellularFile = State(getQueryParameter("cellular-file").getOrElse("factory.cellular"))
    val materialsFile = State(getQueryParameter("materials-file").getOrElse("materials.png"))
    val viewFile = State(getQueryParameter("view-file").getOrElse("view.glsl"))

    val cellularLoader = Loader(this, cellularFile) { url =>
        Ajax.get(url).map { request =>
            request.responseText
        }
    }

    val materialsLoader = Loader(this, materialsFile) { url =>
        WebGlFunctions.loadImage(url)
    }

    val viewCodeLoader = Loader(this, viewFile) { url =>
        Ajax.get(url).map ( request =>
            request.responseText
        )
    }

    override def render(get : Get) : Node = {

        val cellularError = get(cellularLoader) match {
            case Loader.Loading() => E.div(Text("Loading cellular code from " + get(cellularFile)))
            case Loader.Error(throwable) => E.div(Text("Failed to load " + get(cellularFile)))
            case Loader.Result(value) => Tags()
        }

        val viewError = get(viewCodeLoader) match {
            case Loader.Loading() => E.div(Text("Loading view code from " + get(viewFile)))
            case Loader.Error(throwable) => E.div(Text("Failed to load " + get(viewFile)))
            case Loader.Result(value) => Tags()
        }

        val seed = 42

        val canvas = for {
            cellular <- get(cellularLoader.result)
            viewCode <- get(viewCodeLoader.result)
            materialsImage <- get(materialsLoader.result)
        } yield {
            try {
                val definitions = new Parser(cellular).parseDefinitions()
                val stepGroupCode = Compiler.compile(definitions)
                val context = TypeContext.fromDefinitions(definitions)
                Component(CanvasComponent, context, stepGroupCode, viewCode, seed, materialsImage)
            } catch {
                case CompileError(reason, line) =>
                    E.div(Text("Cellular compile error"))
                    E.div(Text(s"$reason at line $line"))
            }
        }

        E.div(
            S.height.percent(100),
            cellularError,
            viewError,
            Tags(canvas),
        )
    }

    def getQueryParameter(name : String) : Option[String] = {
        import org.scalajs.dom.experimental.URLSearchParams
        val p = new URLSearchParams(window.location.search)
        Option(p.get(name))
    }

}