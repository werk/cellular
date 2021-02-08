package cellular.frontend.webgl

import cellular.frontend.webgl.FactoryGl.{FragmentShader, UniformReference}
import org.scalajs.dom
import dom.raw.{HTMLCanvasElement, HTMLImageElement, WebGLBuffer, WebGLFramebuffer, WebGLProgram, WebGLTexture, WebGLRenderingContext => GL}
import cellular.frontend.IVec2
import cellular.frontend.webgl.WebGlFunctions.{DataTextureSource, ImageTextureSource}

import scala.scalajs.js.typedarray.{Float32Array, Uint32Array, Uint8Array}
import scala.scalajs.js

class FactoryGl(
    gl : GL,
    stepShader : FragmentShader,
    viewShader : FragmentShader,
    materialsImage : HTMLImageElement,
    stateSize : IVec2,
) {

    val simulateProgram = WebGlFunctions.initProgram(gl, FactoryGl.vertexCode, stepShader.code)
    val viewProgram = WebGlFunctions.initProgram(gl, FactoryGl.vertexCode, viewShader.code)

    private object textures {
        var front = WebGlFunctions.bindDataTexture(gl, DataTextureSource(stateSize))
        var back = WebGlFunctions.bindDataTexture(gl, DataTextureSource(stateSize))
        val materials = WebGlFunctions.bindDataTexture(gl, ImageTextureSource(materialsImage))
        //val inventory = WebGlFunctions.bindDataTexture(gl, DataTextureSource(inventorySize))

        def swap() = {
            val temp = front
            front = back
            back = temp
        }
    }

    private val positionBuffer : WebGLBuffer = {
        val buffer = gl.createBuffer()
        gl.bindBuffer(GL.ARRAY_BUFFER, buffer)
        gl.bufferData(
            GL.ARRAY_BUFFER,
            new Float32Array(js.Array[Float](
                -1, -1,
                1, -1,
                -1, 1,
                1, 1)),
            GL.STATIC_DRAW
        )
        buffer
    }

    private val framebuffer : WebGLFramebuffer = gl.createFramebuffer()

    var simulateCalls = 0

    def simulate() = {
        val t0 = System.currentTimeMillis()
        FactoryGl.renderSimulation(
            gl = gl,
            program = simulateProgram,
            positionBuffer = positionBuffer,
            uniforms = stepShader.uniforms,
            framebuffer = framebuffer,
            front = textures.front,
            back = textures.back,
            stateSize = stateSize,
        )
        textures.swap()
        if (simulateCalls < 3) {
            FactoryGl.elapsed(s"simulate $simulateCalls:", t0)
            simulateCalls += 1
        }
    }

    def draw() = FactoryGl.renderDraw(
        gl = gl,
        program = viewProgram,
        positionBuffer = positionBuffer,
        uniforms = viewShader.uniforms,
        materials = textures.materials,
        front = textures.front,
        canvas = gl.canvas,
    )

    def getCellValues(x : Int, y : Int, width : Int, height : Int) : List[List[Long]] = {
        //println(s"getCellValue($x, $y, $width, $height)")
        gl.bindFramebuffer(GL.FRAMEBUFFER, framebuffer)
        gl.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, textures.front, 0)
        // We are only using the R component but needs an array 4 times larger
        val array = new Uint32Array(width * height * 4)
        gl.readPixels(x, y, width, height, WebGl2.RGBA_INTEGER, GL.UNSIGNED_INT, array)
        Range(0, height).map { y =>
            Range(0, width).map { x =>
                val i = ((y * width) + x) * 4
                val l = array(i).toLong
                l
            }.toList
        }.toList
    }

    def setCellValues(x : Int, y : Int, width : Int, height : Int, values : List[List[Long]]) : Unit = {
        //println(s"setCellValues($x, $y, $width, $height, $values)")
        val array = new Uint32Array(width * height)
        Range(0, height).foreach { y =>
            val line = values(y % values.size)
            Range(0, width).foreach { x =>
                val i = (y * width) + x
                val v = line(x % line.size)
                array(i) = v.toDouble
            }
        }
        setCellArray(x, y, width, height, array)
    }

    def setCellArray(x : Int, y : Int, width : Int, height : Int, array: Uint32Array) : Unit = {
        gl.activeTexture(GL.TEXTURE0 + 0)
        gl.bindTexture(GL.TEXTURE_2D, textures.front)
        gl.texSubImage2D(GL.TEXTURE_2D, 0, x, y, width, height, WebGl2.RED_INTEGER, GL.UNSIGNED_INT, array)
    }
}

object FactoryGl {

    def elapsed(label : String, start : Long) = {
        val delta = (System.currentTimeMillis() - start) / 1000.0
        println(label + " %.2f".format(delta))
    }

    def renderSimulation(
        gl : GL,
        program : WebGLProgram,
        positionBuffer : WebGLBuffer,
        uniforms : List[(String, UniformReference)],
        framebuffer : WebGLFramebuffer,
        front : WebGLTexture,
        back : WebGLTexture,
        stateSize : IVec2
    ): Unit = {
        gl.bindFramebuffer(GL.FRAMEBUFFER, framebuffer)
        gl.framebufferTexture2D(
            target = GL.FRAMEBUFFER,
            attachment = GL.COLOR_ATTACHMENT0,
            textarget = GL.TEXTURE_2D,
            texture = back,
            level = 0
        )
        gl.activeTexture(GL.TEXTURE0 + 0)
        gl.bindTexture(GL.TEXTURE_2D, front)
        val location = gl.getUniformLocation(program, "state")
        gl.useProgram(program)
        gl.uniform1i(location, 0)
        gl.viewport(0, 0, stateSize.x, stateSize.y)
        renderCommon(gl, program, positionBuffer, uniforms)
    }

    def renderDraw(
        gl : GL,
        program : WebGLProgram,
        positionBuffer : WebGLBuffer,
        uniforms : List[(String, UniformReference)],
        materials : WebGLTexture,
        front : WebGLTexture,
        canvas : HTMLCanvasElement,
    ) : Unit = {
        gl.bindFramebuffer(GL.FRAMEBUFFER, null) // render to the canvas
        WebGlFunctions.resize(canvas)
        gl.useProgram(program)

        {
            val location = gl.getUniformLocation(program, "resolution")
            gl.uniform2f(location, canvas.width, canvas.height)
        }

        {
            gl.activeTexture(GL.TEXTURE0 + 0)
            gl.bindTexture(GL.TEXTURE_2D, front)
            val location = gl.getUniformLocation(program, "state")
            gl.uniform1i(location, 0)
        }

        {
            gl.activeTexture(GL.TEXTURE0 + 1)
            gl.bindTexture(GL.TEXTURE_2D, materials)
            val location = gl.getUniformLocation(program, "materials")
            gl.uniform1i(location, 1)
        }

        gl.viewport(0, 0, canvas.width, canvas.height)
        renderCommon(gl, program, positionBuffer, uniforms)
    }

    private def renderCommon(
        gl : GL,
        program : WebGLProgram,
        positionBuffer : WebGLBuffer,
        uniforms : List[(String, UniformReference)]
    ) = {
        uniforms.foreach { case (name, u) =>
            val location = gl.getUniformLocation(program, name)
            u match {
                case u : FactoryGl.UniformInt => gl.uniform1i(location, u.value)
                case u : FactoryGl.UniformFloat => gl.uniform1f(location, u.value)
                case u : FactoryGl.UniformVec2 => gl.uniform2f(location, u.x, u.y)
                case u : FactoryGl.UniformVec3 => gl.uniform3f(location, u.x, u.y, u.z)
                case u : FactoryGl.UniformVec4 => gl.uniform4f(location, u.x, u.y, u.z, u.w)
                case u : FactoryGl.UniformIVec2 => gl.uniform2i(location, u.x, u.y)
                case u : FactoryGl.UniformIVec3 => gl.uniform3i(location, u.x, u.y, u.z)
                case u : FactoryGl.UniformIVec4 => gl.uniform4i(location, u.x, u.y, u.z, u.w)
            }
        }

        val positionAttributeLocation = gl.getAttribLocation(program, "position")
        gl.enableVertexAttribArray(positionAttributeLocation)
        gl.bindBuffer(GL.ARRAY_BUFFER, positionBuffer)

        gl.vertexAttribPointer(
            indx = positionAttributeLocation,
            size = 2,
            `type` = GL.FLOAT,
            normalized = false,
            stride = 0,
            offset = 0
        )

        gl.drawArrays(
            mode = GL.TRIANGLE_STRIP,
            first = 0,
            count = 4
        )
    }

    case class FragmentShader(
        code : String,
        uniforms : List[(String, UniformReference)],
    )

    sealed trait UniformReference

    class UniformInt extends UniformReference {
        var value : Int = 0
    }

    class UniformFloat extends UniformReference {
        var value : Float = 0
    }

    class UniformVec2 extends UniformReference {
        var x : Float = 0
        var y : Float = 0
    }

    class UniformVec3 extends UniformReference {
        var x : Float = 0
        var y : Float = 0
        var z : Float = 0
    }

    class UniformVec4 extends UniformReference {
        var x : Float = 0
        var y : Float = 0
        var z : Float = 0
        var w : Float = 0
    }

    class UniformIVec2 extends UniformReference {
        var x : Int = 0
        var y : Int = 0
    }

    class UniformIVec3 extends UniformReference {
        var x : Int = 0
        var y : Int = 0
        var z : Int = 0
    }

    class UniformIVec4 extends UniformReference {
        var x : Int = 0
        var y : Int = 0
        var z : Int = 0
        var w : Int = 0
    }

    val vertexCode = s"""#version 300 es
precision mediump float;
in vec2 position;

void main() {
    gl_Position = vec4(position, 0, 1.0);
}
    """

}
