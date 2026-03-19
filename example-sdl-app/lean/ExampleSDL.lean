import SDLBindings

def squareSize : Int := 120

structure AppState where
  frame : UInt32
  x : Int
  y : Int
  dx : Int
  dy : Int
  maxX : Int
  maxY : Int
deriving Inhabited

def bounce (pos vel limit : Int) : Int × Int :=
  let next := pos + vel
  if next < 0 then
    (-next, -vel)
  else if next > limit then
    (2 * limit - next, -vel)
  else
    (next, vel)

initialize appState : IO.Ref AppState <- IO.mkRef {
  frame := 0
  x := 0
  y := 0
  dx := 3
  dy := 2
  maxX := 0
  maxY := 0
}

@[export sdlInit]
def sdlInit : IO Unit := do
  SDL.initVideo
  SDL.setupWindowAndRenderer "Lean SDL Example" 640 480
  let width ← SDL.getRenderOutputWidth
  let height ← SDL.getRenderOutputHeight
  let maxX := max 0 (Int.ofNat width.toNat - squareSize)
  let maxY := max 0 (Int.ofNat height.toNat - squareSize)
  appState.set {
    frame := 0
    x := 0
    y := 0
    dx := 3
    dy := 2
    maxX := maxX
    maxY := maxY
  }

@[export sdlIterate]
def sdlIterate : IO Unit := do
  let state ← appState.get
  let (x, dx) := bounce state.x state.dx state.maxX
  let (y, dy) := bounce state.y state.dy state.maxY
  SDL.setRenderDrawColor 18 18 24 255
  SDL.renderClear
  SDL.setRenderDrawColor 45 152 218 255
  SDL.renderFillRect
    (UInt32.ofNat x.toNat)
    (UInt32.ofNat y.toNat)
    (UInt32.ofNat squareSize.toNat)
    (UInt32.ofNat squareSize.toNat)
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
