package cellular.language

case class CompileError(problem : String, line : Int) extends RuntimeException(s"$problem at line $line")
