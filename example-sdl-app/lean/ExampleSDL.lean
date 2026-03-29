import SDLBindings

def squareSize : Float := 120.0

def tickDt : Float := 1.0 / 60.0

def maxFrameDt : Float := 0.25

def warmupFrames : UInt32 := 100

def text : String := "Hello"

def textSize : UInt32 := 32

structure AppState where
  frame : UInt32
  x : Float
  y : Float
  dx : Float
  dy : Float
  maxX : Float
  maxY : Float
  accumulator : Float
  square : Option SDL.Texture
  textWidth : Float
  textHeight : Float
deriving Inhabited

def bounce (pos vel limit dt : Float) : Float × Float :=
  let next := pos + vel * dt
  if next < 0.0 then
    (-next, -vel)
  else if next > limit then
    (limit - (next - limit), -vel)
  else
    (next, vel)

initialize appState : IO.Ref AppState <- IO.mkRef default

@[export sdlInit]
def sdlInit : IO Unit := do
  SDL.initVideo
  SDL.setupFullscreenWindowAndRenderer "Lean SDL Example"
  let width ← SDL.getWindowWidth
  let height ← SDL.getWindowHeight
  let maxX := max 0.0 (width.toFloat - squareSize)
  let maxY := max 0.0 (height.toFloat - squareSize)
  let square ← SDL.loadSvgTexture "assets/bouncing_square.svg"
  let (textWidth, textHeight) <- SDL.measureText text textSize
  appState.set {
    frame := 0
    x := 0.0
    y := 0.0
    dx := 240.0
    dy := 120.0
    maxX := maxX
    maxY := maxY
    accumulator := 0.0
    square := some square
    textWidth := textWidth.toFloat
    textHeight := textHeight.toFloat
  }

@[export sdlIterate]
def sdlIterate : IO Unit := do
  let state ← appState.get
  let mut stepped := state
  if state.frame < warmupFrames then
    stepped := { state with frame := state.frame + 1, accumulator := 0.0 }
  else
    let frameDt := min (← SDL.getFrameTime) maxFrameDt
    let mut remaining := state.accumulator + frameDt
    while remaining >= tickDt do
      let (x, dx) := bounce stepped.x stepped.dx stepped.maxX tickDt
      let (y, dy) := bounce stepped.y stepped.dy stepped.maxY tickDt
      stepped := { stepped with
        frame := stepped.frame + 1
        x := x
        y := y
        dx := dx
        dy := dy
        accumulator := remaining - tickDt
      }
      remaining := remaining - tickDt
    stepped := { stepped with accumulator := remaining }
  SDL.setRenderDrawColor 255 255 255 255
  SDL.renderClear

  match stepped.square with
  | none => do
    SDL.setRenderDrawColor 0 0 0 255
    SDL.renderFillRect
      stepped.x
      stepped.y
      squareSize
      squareSize
  | some t => do
    SDL.renderTexture t stepped.x stepped.y squareSize squareSize

  SDL.drawText
    text
    (stepped.x + (squareSize - state.textWidth) / 2)
    (stepped.y + (squareSize - state.textHeight) / 2)
    textSize
    255 255 255 255

  SDL.renderPresent
  appState.set stepped

@[export sdlEvent]
def sdlEvent (eventType : UInt32) : IO Unit := do
  SDL.recordEvent eventType

@[export sdlQuit]
def sdlQuit : IO Unit := do
  SDL.shutdown
