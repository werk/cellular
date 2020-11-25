package cellular.frontend

import cellular.frontend.component.MainComponent
import com.github.ahnfelt.react4s._

object Factory {

    def main(args : Array[String]) : Unit = {
        println("Hello from Main")
        val component = Component(MainComponent)
        ReactBridge.renderToDomById(component, "main")
    }

}
