package cellular.frontend

import cellular.frontend.Controller.WheelEvent
import cellular.frontend.Recipes.Recipe
import cellular.frontend.webgl.FactoryGl
import cellular.mini.{Codec, PropertyValue, TypeContext, Value}
import com.github.ahnfelt.react4s.{EventHandler, KeyboardEvent, MouseEvent, SyntheticEvent}
import org.scalajs.dom
import org.scalajs.dom.window

import scala.collection.mutable
import scala.scalajs.js

class Controller(context : TypeContext) {

    var canvas : dom.html.Canvas = _
    var factoryGl : FactoryGl = _
    val state = new CpuState(100, 100)
    var clipboard : Option[List[List[Value]]] = None

    private var selectionFrom : Option[Selection] = None
    private var pan : Option[Pan] = None

    private case class Selection(
        initialTileX : Int,
        initialTileY : Int,
    )

    private case class Pan(
        initialOffsetX : Double,
        initialOffsetY : Double,
        initialScreenPositionX : Double,
        initialScreenPositionY : Double,
        didMove : Boolean
    )

    private case class Rectangle(
        x : Int,
        y : Int,
        width : Int,
        height : Int,
    )

    def onKeyDown(e : KeyboardEvent) : Unit = {
        if(e.key == "1") tryBuild(Recipes.ladder)
        if(e.key == "2") tryBuild(Recipes.signUp)
        if(e.key == "3") tryBuild(Recipes.signDown)
        if(e.key == "4") tryBuild(Recipes.bigChest)
        if(e.key == "5") tryBuild(Recipes.factory)
        if(e.key == "r") {
            replaceTilesInSelection { tile =>
                takeResources(tile)
            }
            logInventory()
        }
        if(e.ctrlKey && (e.key == "c" || e.key == "x")) {
            e.preventDefault()
            getSelection().foreach { s =>
                val values = factoryGl.getCellValues(s.x, s.y, s.width, s.height)
                val decoded = decode(values)
                if(s.width == 1 && s.height == 1) {
                    println("Values, decoded, re-encoded:")
                    println(values.map(_.mkString(", ")).mkString(".\n"))
                    println(decoded.map(_.mkString(", ")).mkString(".\n"))
                    val encoded = encode(decoded)
                    println(encoded.map(_.mkString(", ")).mkString(".\n"))
                }
                clipboard = Some(decoded)
            }
        }
        if(e.ctrlKey && e.key == "x") {
            e.preventDefault()
            replaceTilesInSelection { _ =>
                Value(0, "Cave", List(
                    PropertyValue(0, "Foreground", Value(0, "None", List())),
                    PropertyValue(0, "Background", Value(0, "None", List())),
                ))
            }
        }
        if(e.ctrlKey && e.key == "v") {
            e.preventDefault()
            clipboard.foreach { values =>
                getSelection().foreach { s =>
                    val encoded = encode(values)
                    val width = Math.max(s.width, values.head.size)
                    val height = Math.max(s.height, values.size)
                    factoryGl.setCellValues(s.x, s.y, width, height, encoded)
                }
            }
        }
        if(!e.ctrlKey && e.key == "d") {
            e.preventDefault()
            replaceTilesInSelection {
                case v@Value(_, "Rock", properties) =>
                    v.copy(properties = properties.map {
                        case p@PropertyValue(_, "Dig", pv@Value(_, dig, List())) =>
                            p.copy(value = pv.copy(material = if(dig == "1") "0" else "1"))
                        case p => p
                    })
                case v => v
            }
        }
    }

    def onMouseDown(e : MouseEvent) : Unit = {
        e.preventDefault()
        val (screenX, screenY) = eventScreenPosition(e);
        if(e.button == 0) {
            val (tileX, tileY) = eventTilePosition(e)
            selectionFrom = Some(Selection(tileX, tileY))
            updateSelection(e)
        } else if(e.button == 2) {
            pan = Some(Pan(
                initialOffsetX = state.offsetX,
                initialOffsetY = state.offsetY,
                initialScreenPositionX = screenX,
                initialScreenPositionY = screenY,
                didMove = false
            ))
        }
    }

    def onMouseUp(e : MouseEvent) : Unit = {
        e.preventDefault()
        if(e.button == 0) {
            updateSelection(e)
        } else if(e.button == 2) {
            if(pan.exists(!_.didMove)) {
                selectionFrom = None
                updateSelection(e)
            }
        }
        selectionFrom = None
        pan = None
    }

    def onMouseMove(e : MouseEvent) : Unit = {
        e.preventDefault()
        if(pan.nonEmpty) {
            if(pan.exists(!_.didMove)) pan = pan.map(_.copy(didMove = true))
            pan.foreach { p =>
                val (screenX, screenY) = eventScreenPosition(e);
                val deltaScreenX = screenX - p.initialScreenPositionX
                val deltaScreenY = screenY - p.initialScreenPositionY
                val ratio = screenToMapRatio()
                state.offsetX = p.initialOffsetX + deltaScreenX * ratio * -1
                state.offsetY = p.initialOffsetY + deltaScreenY * ratio * -1
                //ensureViewportIsInsideMap();
            }
        } else if(selectionFrom.nonEmpty) {
            updateSelection(e)
        }
    }

    def onMouseWheel(e : WheelEvent) : Unit = {
        if (e.ctrlKey) e.preventDefault() // Try to avoid browser zooming
        val zoomSpeed = 0.2
        val zoomFactor = if(e.deltaY > 0) 1 + zoomSpeed else 1 / (1 + zoomSpeed)
        val (unitX, unitY) = eventUnitPosition(e)
        val mapWidth = state.zoom
        val mapHeight = state.zoom * (canvas.height.toDouble / canvas.width)
        val oldZoom = state.zoom
        state.zoom *= zoomFactor
        //ensureViewportIsInsideMap();
        val actualZoomFactor = state.zoom / oldZoom;
        val deltaOffsetX = unitX * (actualZoomFactor - 1) * mapWidth;
        val deltaOffsetY = unitY * (actualZoomFactor - 1) * mapHeight;
        state.offsetX -= deltaOffsetX
        state.offsetY -= deltaOffsetY
        //ensureViewportIsInsideMap();
    }

    private def tryBuild(recipe : Recipe) = {
        getSelection().foreach { s =>
            val encoded = encode(recipe.tiles)
            val width = Math.max(s.width, recipe.tiles.head.size)
            val height = Math.max(s.height, recipe.tiles.size)
            factoryGl.setCellValues(s.x, s.y, width, height, encoded)
        }
    }


    private def takeResources(tile : Value) : Value = {
        modifyProperties(tile, {
            case ("Foreground", foreground) =>
                modifyProperties(foreground, {
                    case ("Content", content) if content.material != "None" =>
                        inventoryPut(content, 1)
                        content.copy(material = "None")
                })
            case ("BuildingVariant", building) =>
                val content = building.properties.find(_.property == "Content").map(_.value)
                modifyProperties(building, {
                    case ("BigContentCount" | "SmallContentCount", count) =>
                        val n = count.material.toInt
                        inventoryPut(content.get, n)
                        count.copy(material = "0")
                }
                )
        })
    }

    private def modifyProperties(v : Value, pf : PartialFunction[(String, Value), Value]) : Value = {
        val newProperties = v.properties.map { p =>
            val f = pf.lift
            f(p.property, p.value).map(newValue => p.copy(value = newValue)).getOrElse(p)
        }
        v.copy(properties = newProperties)
    }

    private def inventoryPut(value : Value, count : Int) : Unit = {
        state.inventory = state.inventory.updated(value, state.inventory.getOrElse(value, 0) + count)
    }

    private def logInventory(): Unit = {
        println("Inventory:")
        state.inventory.foreach { case (value, count) =>
            println(s"    $count $value")
        }
    }

    private def decode(integers : List[List[Long]]) : List[List[Value]] = {
        integers.map(_.map(n => Codec.decodeValue(context, context.properties("Tile"), n.toInt)))
    }

    private def encode(values : List[List[Value]]) : List[List[Long]] = {
        values.map(_.map(v => Codec.encodeValue(context, context.properties("Tile"), v)))
    }

    private def getSelection() : Option[Rectangle] = {
        val width = Math.abs(state.selectionX1 - state.selectionX2)
        val height = Math.abs(state.selectionY1 - state.selectionY2)
        if(width > 0 && height > 0) Some(Rectangle(
            x = Math.min(state.selectionX1, state.selectionX2),
            y = Math.min(state.selectionY1, state.selectionY2),
            width = width,
            height = height,
        )) else None
    }

    private def replaceTilesInSelection(body : Value => Value) : Unit = {
        getSelection().foreach { s =>
            //val start = System.currentTimeMillis()
            val values = factoryGl.getCellValues(s.x, s.y, s.width, s.height)
            //FactoryGl.elapsed("getCellValues", start)
            val decoder = new CodecCache[Long, Value](n => Codec.decodeValue(context, context.properties("Tile"), n.toInt))
            val encoder = new CodecCache[Value, Long](v => Codec.encodeValue(context, context.properties("Tile"), v).toLong)
            val decoded = values.map(_.map(n => decoder(n)))
            //FactoryGl.elapsed("decode", start)
            val changed = decoded.map(_.map(body))
            //FactoryGl.elapsed("change", start)
            val encoded = changed.map(_.map(v => encoder(v)))
            //FactoryGl.elapsed("encode", start)
            factoryGl.setCellValues(s.x, s.y, s.width, s.height, encoded)
            //FactoryGl.elapsed("setCellValues", start)
            //println(decoder.cache.size -> encoder.cache.size)
        }
    }

    private class CodecCache[K, V](body : K => V) {
        val cache = mutable.HashMap[K, V]()
        def apply(input : K) : V = cache.getOrElseUpdate(input, body(input))
    }

    private def updateSelection(event : MouseEvent) : Unit = {
        selectionFrom match {
            case Some(s) =>
                val (tileX, tileY) = eventTilePosition(event)
                state.selectionX1 = Math.min(s.initialTileX, tileX)
                state.selectionX2 = Math.max(s.initialTileX, tileX) + 1
                state.selectionY1 = Math.min(s.initialTileY, tileY)
                state.selectionY2 = Math.max(s.initialTileY, tileY) + 1
            case None =>
                state.selectionX1 = 0
                state.selectionX2 = 0
                state.selectionY1 = 0
                state.selectionY2 = 0
        }
    }

    private def screenToMapRatio() = {
        state.zoom / canvas.width;
    }

    private def eventScreenPosition(event : MouseEvent) : (Double, Double) = {
        val r = canvas.getBoundingClientRect()
        val x = event.clientX - r.left
        val cssHeight = canvas.clientHeight;
        val y = cssHeight - (event.clientY - r.top)
        val realToCssPixels = window.devicePixelRatio
        (x * realToCssPixels, y * realToCssPixels)
    }

    private def eventUnitPosition(event : MouseEvent) : (Double, Double) = {
        val (screenX, screenY) = eventScreenPosition(event);
        (screenX / canvas.width, screenY / canvas.height);
    }

    private def eventTilePosition(event : MouseEvent) : (Int, Int) = {
        val (mapX, mapY) = eventMapPosition(event);
        (mapX.toInt, mapY.toInt)
    }

    private def eventMapPosition(event : MouseEvent) : (Double, Double) = {
        val (screenX, screenY) = eventScreenPosition(event);
        screenToMapPosition(screenX, screenY)
    }

    private def screenToMapPosition(screenX : Double, screenY : Double) : (Double, Double) = {
        val ratio = this.screenToMapRatio()
        val mapX = screenX * ratio + state.offsetX
        val mapY = screenY * ratio + state.offsetY
        (mapX, mapY);
    }

    private def pretty(d : Double) : String = "%.2f".format(d)

}

object Controller {
    def onMouseMove(handler : MouseEvent => Unit) = EventHandler("onMouseMove", handler.asInstanceOf[SyntheticEvent => Unit])
    def onWheel(handler : WheelEvent => Unit) = EventHandler("onWheel", handler.asInstanceOf[SyntheticEvent => Unit])

    @js.native
    trait WheelEvent extends MouseEvent {
        val deltaMode : Double
        val deltaX : Double
        val deltaY : Double
        val deltaZ : Double
    }

}
