import SDLBindings

def squareSize : Float := 120.0

structure AppState where
  frame : UInt32
  x : Float
  y : Float
  dx : Float
  dy : Float
  maxX : Float
  maxY : Float
deriving Inhabited

def bounce (pos vel limit : Float) : Float × Float :=
  let next := pos + vel
  if next < 0.0 then
    (-next, -vel)
  else if next > limit then
    (limit - (next - limit), -vel)
  else
    (next, vel)

initialize appState : IO.Ref AppState <- IO.mkRef {
  frame := 0
  x := 0.0
  y := 0.0
  dx := 0.0
  dy := 0.0
  maxX := 0.0
  maxY := 0.0
}

@[export sdlInit]
def sdlInit : IO Unit := do
  SDL.initVideo
  SDL.setupFullscreenWindowAndRenderer "Lean SDL Example"
  let width ← SDL.getWindowWidth
  let height ← SDL.getWindowHeight
  let maxX := max 0.0 (width.toFloat - squareSize)
  let maxY := max 0.0 (height.toFloat - squareSize)
  appState.set {
    frame := 0
    x := 0.0
    y := 0.0
    dx := 2.0
    dy := 2.0
    maxX := maxX
    maxY := maxY
  }

@[export sdlIterate]
def sdlIterate : IO Unit := do
  let state ← appState.get
  let (x, dx) := bounce state.x state.dx state.maxX
  let (y, dy) := bounce state.y state.dy state.maxY
  SDL.setRenderDrawColor 255 255 255 255
  SDL.renderClear
  SDL.setRenderDrawColor 0 0 0 255
  SDL.renderFillRect
    x
    y
    squareSize
    squareSize
  SDL.renderPresent
  appState.set {
    frame := state.frame + 1
    x := x
    y := y
    dx := dx
    dy := dy
    maxX := state.maxX
    maxY := state.maxY
  }

@[export sdlQuit]
def sdlQuit : IO Unit := do
  SDL.shutdown
