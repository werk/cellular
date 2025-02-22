package cellular.mini

import java.io.{File, FileOutputStream}
import scala.io.Source

object GameProgram {

    def main(arguments : Array[String]) : Unit = {
        val Array(inPath, stepPath, viewPath) = arguments
        val inSource = Source.fromFile(inPath)
        val code = inSource.mkString
        inSource.close()
        val definitions = new Parser(code).parseDefinitions()
        val glsl = Compiler.compile(definitions)
        try {
            0.until(999).foreach(index => new File(stepPath.replace(".", "-" + (index + 1) + ".")).delete())
        } catch {
            case _ : Exception =>
        }
        glsl.zipWithIndex.foreach { case (glslCode, index) =>
            val out = new FileOutputStream(stepPath.replace(".", "-" + (index + 1) + "."))
            out.write(glslCode.getBytes("UTF-8"))
            out.close()
        }
        updateView(viewPath, glsl.head)
    }

    def updateView(viewPath : String, glsl : String) : Unit = {
        val common = glsl.linesIterator.dropWhile(_ != "// BEGIN COMMON").takeWhile(_ != "// END COMMON")
        val commonCode = common.mkString("\n") + "\n// END COMMON"
        val inSource = Source.fromFile(viewPath)
        val code = inSource.mkString
        inSource.close()
        val beforeCommonCode = code.linesIterator.takeWhile(_ != "// BEGIN COMMON").mkString("\n")
        val afterCommonCode = code.linesIterator.toList.reverse.takeWhile(_ != "// END COMMON").reverse.mkString("\n")
        val newCode = beforeCommonCode + "\n" + commonCode + "\n" + afterCommonCode
        val out = new FileOutputStream(viewPath)
        out.write(newCode.getBytes("UTF-8"))
        out.close()
    }

}
