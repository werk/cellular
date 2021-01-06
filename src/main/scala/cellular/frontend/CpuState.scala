package cellular.frontend

class CpuState(val sizeX : Int, val sizeY : Int) {
    var step : Int = 0
    var offsetX : Double = 0 //sizeX / 2.0
    var offsetY : Double = 0 //sizeY / 2.0
    var zoom : Double = 40

    val zoomMin : Double = 5;
    val zoomMax : Double = Math.min(sizeX, sizeY);
}

