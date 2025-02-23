package cellular.language

import java.io.{File, FileOutputStream}
import scala.io.Source

object GenerateGlsl {

    def main(arguments : Array[String]) : Unit = {
        val Array(inPath, viewPath) = arguments
        val viewFile = new File(viewPath)
        if(!viewFile.exists()) throw new RuntimeException(s"view file does not exist: $viewPath")
        val directory = viewFile.getParentFile
        val inSource = Source.fromFile(inPath)
        val code = inSource.mkString
        inSource.close()
        val definitions = new Parser(code).parseDefinitions()
        val stepGroups = Compiler.compile(definitions)
        0.until(999).foreach { index =>
            val stepFile = new File(directory, s"step-${index + 1}.glsl")
            if(stepFile.exists()) {
                stepFile.delete()
                println(s"Deleted $stepFile")
            }
        }
        stepGroups.zipWithIndex.foreach { case (glslCode, index) =>
            val stepFile = new File(directory, s"step-${index + 1}.glsl")
            val out = new FileOutputStream(stepFile)
            out.write(glslCode.getBytes("UTF-8"))
            out.close()
            println(s"Generated $stepFile")
        }
        updateView(viewFile, stepGroups.head)
    }

    def updateView(viewFile : File, stepGlsl : String) : Unit = {
        val inSource = Source.fromFile(viewFile)
        val oldViewGlsl = inSource.mkString
        inSource.close()

        val newViewGlsl = Compiler.updateViewGlsl(stepGlsl, oldViewGlsl)
        if(oldViewGlsl == newViewGlsl) {
            println(s"No change to $viewFile")
        } else {
            val out = new FileOutputStream(viewFile)
            out.write(newViewGlsl.getBytes("UTF-8"))
            out.close()
            println(s"Updated $viewFile")
        }
    }

}
