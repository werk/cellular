package cellular.frontend

import cellular.frontend.component.MainComponent
import com.github.ahnfelt.react4s._

object Factory {

    def main(args : Array[String]) : Unit = {
        val component = Component(MainComponent)
        ReactBridge.renderToDomById(component, "main")
    }

}
