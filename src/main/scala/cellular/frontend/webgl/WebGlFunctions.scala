package cellular.frontend.webgl

import cellular.frontend.IVec2
import org.scalajs.dom
import org.scalajs.dom.Event
import org.scalajs.dom.raw.WebGLRenderingContext._
import org.scalajs.dom.raw._

import scala.concurrent.{Future, Promise}

object WebGlFunctions {


    def getContexts(canvas : HTMLCanvasElement) : WebGLRenderingContext = {
        val context = canvas.getContext("webgl") || canvas.getContext("experimental-webgl")
        if (context == null) throw new RuntimeException("This browser does not support WebGL.")
        context.asInstanceOf[WebGLRenderingContext]
    }

    private def initShader(gl : WebGLRenderingContext, code: String, shaderType : Int) : WebGLShader = {
        val shaderTypeName =
            if(shaderType == VERTEX_SHADER) "vertex shader"
            else if(shaderType == FRAGMENT_SHADER) "fragment shader"
            else throw new RuntimeException(s"Invalid shader type: $shaderType")

        println("Compiling " + shaderTypeName + "...")
        val start = System.currentTimeMillis()

        val shader = gl.createShader(shaderType)
        gl.shaderSource(shader, code)
        gl.compileShader(shader)

        val status = gl.getShaderParameter(shader, COMPILE_STATUS).asInstanceOf[Boolean]

        println("Shader compiled in " + ((System.currentTimeMillis() - start) / 1000) + " seconds.")

        if(!status) {
            val error = s"Failed to compile $shaderTypeName: ${gl.getShaderInfoLog(shader)}"
            println(error)
            println("Code")
            println(code)
            throw new RuntimeException(error)
        }

        shader
    }

    def initVertexShader(gl : WebGLRenderingContext, code: String) : WebGLShader = initShader(gl, code, VERTEX_SHADER)
    def initFragmentShader(gl : WebGLRenderingContext, code: String) : WebGLShader = initShader(gl, code, FRAGMENT_SHADER)

    def initProgram(gl : WebGLRenderingContext, vertexShader: WebGLShader, fragmentShader: WebGLShader) : WebGLProgram = {

        println("Linking program...")
        val start = System.currentTimeMillis()

        val shaderProgram = gl.createProgram()
        gl.attachShader(shaderProgram, vertexShader)
        gl.attachShader(shaderProgram, fragmentShader)
        gl.linkProgram(shaderProgram)

        val success = gl.getProgramParameter(shaderProgram, LINK_STATUS).asInstanceOf[Boolean]

        println("Program linked in " + ((System.currentTimeMillis() - start) / 1000) + " seconds.")

        if (!success) {
            val logLines = gl.getProgramInfoLog(shaderProgram).linesIterator.toList
            if(logLines.size <= 300) println(logLines.mkString("\n"))
            else println((logLines.take(100) ++ List("...") ++ logLines.takeRight(100)).mkString("\n"))
            gl.deleteProgram(shaderProgram)
            throw new RuntimeException("Failed to link program")
        }

        shaderProgram
    }

    def initProgram(gl : WebGLRenderingContext, vertexShader: String, fragmentShader: String) : WebGLProgram = {
        initProgram(gl, initVertexShader(gl, vertexShader), initFragmentShader(gl, fragmentShader))
    }

    def activateTexture(gl : WebGLRenderingContext, texture : WebGLTexture, uniformLocation : WebGLUniformLocation): Unit = {
        gl.activeTexture(TEXTURE0)
        gl.bindTexture(TEXTURE_2D, texture)
        gl.uniform1i(uniformLocation, 0)
    }
    def bindDataTexture(gl : WebGLRenderingContext, source : TextureSource) : WebGLTexture = {
        val texture = gl.createTexture()
        gl.bindTexture(TEXTURE_2D, texture)
        source match {
            case ImageTextureSource(loadedImage) =>
                gl.texImage2D(TEXTURE_2D, 0, RGBA, RGBA, UNSIGNED_BYTE, loadedImage)
            case DataTextureSource(size) =>
                gl.texImage2D(
                    target = TEXTURE_2D,
                    level = 0,
                    internalformat = WebGl2.R32UI,
                    width = size.x,
                    height = size.y,
                    border = 0,
                    format = WebGl2.RED_INTEGER,
                    `type` = UNSIGNED_INT,
                    pixels = null
                );
        }

        gl.texParameteri(TEXTURE_2D, TEXTURE_WRAP_S, CLAMP_TO_EDGE);
        gl.texParameteri(TEXTURE_2D, TEXTURE_WRAP_T, CLAMP_TO_EDGE);
        gl.texParameteri(TEXTURE_2D, TEXTURE_MIN_FILTER, NEAREST);
        gl.texParameteri(TEXTURE_2D, TEXTURE_MAG_FILTER, NEAREST);
        gl.bindTexture(TEXTURE_2D, null)
        texture
    }

    def clear(gl : WebGLRenderingContext, clearColor : (Double, Double, Double, Double)): Unit = {

        // Blending
        //gl.blendFunc(ONE, ONE)
        gl.blendFunc(SRC_ALPHA, ONE_MINUS_SRC_ALPHA)
        gl.enable(BLEND)
        gl.disable(DEPTH_TEST)

        val (r, g, b, a) = clearColor
        gl.clearColor(r, g, b, a)
        gl.clear(COLOR_BUFFER_BIT)

        // Set the view port
        gl.viewport(0, 0, gl.canvas.width, gl.canvas.height)
    }

    def resize(canvas : HTMLCanvasElement) {
        val realToCSSPixels = dom.window.devicePixelRatio
        val displayWidth = Math.floor(canvas.clientWidth * realToCSSPixels).toInt
        val displayHeight = Math.floor(canvas.clientHeight * realToCSSPixels).toInt

        if (canvas.width != displayWidth || canvas.height != displayHeight) {
            canvas.width = displayWidth
            canvas.height = displayHeight
        }
    }

    def loadImage(url : String) : Future[HTMLImageElement] = {
        val image = dom.document.createElement("img").asInstanceOf[HTMLImageElement]
        image.src = url
        if (image.complete) {
            Future.successful(image)
        } else {
            val p = Promise[HTMLImageElement]()
            image.onload = { _ : Event =>
                p.success(image)
            }
            p.future
        }
    }

    sealed trait TextureSource
    case class ImageTextureSource(loadedImage : HTMLImageElement) extends TextureSource
    case class DataTextureSource(size : IVec2) extends TextureSource
}