package cellular.mini

import java.io.FileOutputStream

import scala.io.Source

object GameProgram {

    def main(arguments : Array[String]) : Unit = {
        val Array(inPath, outPath) = arguments
        val inSource = Source.fromFile(inPath)
        val code = inSource.mkString
        inSource.close()
        val definitions = new Parser(code).parseDefinitions()
        val glsl = Compiler.compile(definitions)
        val out = new FileOutputStream(outPath)
        out.write(glsl.getBytes("UTF-8"))
        out.close()
    }

}
