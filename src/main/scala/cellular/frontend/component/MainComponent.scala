package cellular.frontend.component

import com.github.ahnfelt.react4s._
import cellular.frontend.webgl.WebGlFunctions
import cellular.mini.{Compiler, Parser, TypeContext}
import org.scalajs.dom.ext.Ajax
import org.scalajs.dom.window

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future

case class MainComponent() extends Component[NoEmit] {

    val cellularFile = State(getQueryParameter("cellular-file").getOrElse("factory/factory.cellular"))
    val materialsFile = State(getQueryParameter("materials-file").getOrElse("materials.png"))
    val stepFiles = State(getQueryParameter("step-file").map(_.split(",").toList).getOrElse {
        0.until(8).map {index => // TODO
            "step.glsl".replace(".", "-" + (index + 1) + ".")
        }.toList
    })
    val viewFile = State(getQueryParameter("view-file").getOrElse("view.glsl"))

    val cellularLoader = Loader(this, cellularFile) { url =>
        Ajax.get(url).map { request =>
            request.responseText
        }
    }

    val materialsLoader = Loader(this, materialsFile) { url =>
        WebGlFunctions.loadImage(url)
    }

    val stepCodeLoader = Loader(this, stepFiles) { urls =>
        Future.sequence(urls.map { url =>
            Ajax.get(url).map { request =>
                request.responseText
            }
        })
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

        val stepError = get(stepCodeLoader) match {
            case Loader.Loading() => E.div(Text("Loading step code from " + get(stepFiles)))
            case Loader.Error(throwable) => E.div(Text("Failed to load " + get(stepFiles)))
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
            stepCode <- get(stepCodeLoader.result)
            viewCode <- get(viewCodeLoader.result)
            materialsImage <- get(materialsLoader.result)
            definitions = new Parser(cellular).parseDefinitions()
            context = TypeContext.fromDefinitions(definitions)
        } yield Component(CanvasComponent, context, stepCode, viewCode, seed, materialsImage)

        E.div(
            S.height.percent(100),
            cellularError,
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