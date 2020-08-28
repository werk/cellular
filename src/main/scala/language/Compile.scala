package language

import language.Language._

object Compile {

    def main(args : Array[String]) : Unit = {

        println(compile(experiments.SandAndWater.declarations))
    }

    def compile(declarations : List[Declaration]) : String = {
        val settersAndGetters = declarations.collect{case t : DTrait => compileTrait(t)}
        val (ruleFunctions, ruleUsages) = declarations.collect{case g : DGroup => compileGroup(g)}.unzip

        blocks(List(
            head,
            blocks(settersAndGetters),
            blocks(ruleFunctions),
            makeMain(blocks(ruleUsages))
        ))
    }

    val head : String = lines(
        s"precision mediump float;",
        s"uniform sampler2D state;",
        s"uniform vec2 scale;",
        s"uniform float seedling;",
        s"uniform int step;",
    )

    // Generate a getter and a setter
    def compileTrait(t : DTrait) : String = lines(
        s"uint get_${t.name}(uint number) {",
        s"    return -1;",
        s"}",
        s"",
        s"bool set_${t.name}(uint number, uint value) {",
        s"    return -1;",
        s"}",
    )

    def compileGroup(g : DGroup) : (String, String) = {
        val ruleFunctions = blocks(g.reactions.map(Reactions.compile))

        val didGroup = s"bool did_${g.name} = false;"
        val didReactions = g.reactions.map(r =>
            s"bool did_${r.name} = false;"
        )

        (ruleFunctions, lines(didGroup :: didReactions : _*))
    }

    def makeMain(ruleUsages : String) : String = lines(
        "void main() {",
        "    // read pp_0_0 etc.",
        indent(ruleUsages),
        "    // write own pixel, e.g. pp_0_1.!",
        "}",
    )

    def lines(strings : String*) : String = strings.mkString("\n")

    def blocks(blocks : List[String]) : String = blocks.mkString("\n\n")

    def indent(code : String) : String = {
        code.split('\n').map(line =>
            if(line.nonEmpty) "    " + line
            else line
        ).mkString("\n")
    }

}
