package cellular.frontend

import cellular.language.Value

class CpuState(val sizeX : Int, val sizeY : Int) {
    var step : Int = 0
    var offsetX : Double = 0 //sizeX / 2.0
    var offsetY : Double = 0 //sizeY / 2.0
    var zoom : Double = 40
    var selectionX1 : Int = 0
    var selectionY1 : Int = 0
    var selectionX2 : Int = 0
    var selectionY2 : Int = 0

    val zoomMin : Double = 5;
    val zoomMax : Double = Math.min(sizeX, sizeY);

    var inventory = Map[Value, Int]()

    var paused = false
}

