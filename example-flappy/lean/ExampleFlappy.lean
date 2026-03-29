import Batteries.Data.Rat
import Flappy
import SDLBindings

open Flappy

def maxFrameDt : Float := 0.25

def warmupFrames : UInt32 := 5

def makeConfig (width height : Nat) : IO Config := do
  let pipeConfig := {
    speed := 180
    width := 80
    spacing := 300
    gapSize := 180
    margin := 80
    color := { r := 0, g := 100, b := 0, a := 255 }
  }
  let windowConfig := {
    width := width
    height := height
    backgroundColor := { r := 135, g := 206, b := 235, a := 255 }
    scoreTextColor := { r := 0, g := 0, b := 0, a := 255 }
  }

  let gameOverText := "GAME OVER"
  let gameOverSize := 40
  let (tw, th) ← SDL.measureText gameOverText gameOverSize

  let gameOver := {
    text := gameOverText
    color := { r := 255, g := 0, b := 0, a := 255 }
    size := gameOverSize.toNat
    position := ((width - tw.toNat) / 2 , (height - th.toNat) / 3)
  }

  {
    yScale := 2
    window := windowConfig
    bird := { x := width / 3, flapVelocity := -13 }
    gravityStep := 1
    pipe := pipeConfig
    gameOver
  } |> pure

structure Assets where
  birdyUp : SDL.Texture
  birdyDown : SDL.Texture

namespace Assets

def load : IO Assets := do
  let birdyUp ← SDL.loadSvgTexture "assets/birdy_up_forall.svg"
  let birdyDown ← SDL.loadSvgTexture "assets/birdy_down_forall.svg"
  pure { birdyUp, birdyDown }

end Assets

def colorComponents (c : Flappy.Color) : UInt32 × UInt32 × UInt32 × UInt32 :=
  (c.r.toUInt32, c.g.toUInt32, c.b.toUInt32, c.a.toUInt32)

variable
  {m}
  [Monad m]
  [MonadReaderOf Assets m]
  [MonadLiftT IO m]

instance : Flappy.MonadRender m where
  drawRectangle r c := do
    let (red, green, blue, alpha) := colorComponents c
    SDL.setRenderDrawColor red green blue alpha
    SDL.renderFillRect
      r.x
      r.y
      r.width
      r.height
  clearBackground c := do
    let (red, green, blue, alpha) := colorComponents c
    SDL.setRenderDrawColor red green blue alpha
    SDL.renderClear
  drawAsset name dest := do
    let assets ← readThe Assets
    let texture := match name with
      | .birdyUp => assets.birdyUp
      | .birdyDown => assets.birdyDown
    SDL.renderTexture
      texture
      dest.x
      dest.y
      dest.width
      dest.height
  drawText text x y size c := do
    let (red, green, blue, alpha) := colorComponents c
    SDL.drawText
      text
      x.toFloat
      y.toFloat
      size.toUInt32
      red
      green
      blue
      alpha

structure AppState where
  frame : UInt32
  accumulator : Float
  config : Config
  assets : Assets
  game : State

initialize appState : IO.Ref (Option AppState) <- IO.mkRef none

def initGameState (config : Config) : IO State := do
  let bytes ← IO.getRandomBytes 8
  let seed : Nat := bytes.toUInt64BE! |>.toNat
  pure {
    bird := {
      y := config.yScale * config.window.height / 3
      velocity := config.bird.flapVelocity
    }
    pipes := []
    randGen := mkStdGen seed
  }

def stepGame (config : Config) (game : State) (isSpaceDown : Bool) : IO State :=
  ((game.step isSpaceDown : ReaderT Config IO State).run config)

def hasCollision (config : Config) (game : State) : IO Bool :=
  ((game.hasCollision : ReaderT Config IO Bool).run config)

def renderGame (config : Config) (assets : Assets) (game : State) : IO Unit := do
  (((game.render : ReaderT Config (ReaderT Assets IO) Unit).run config).run assets)

@[export sdlInit]
def sdlInit : IO Unit := do
  SDL.initVideo
  SDL.setupFullscreenWindowAndRenderer "Lean SDL Flappy"
  let width ← SDL.getWindowWidth
  let height ← SDL.getWindowHeight
  let config ← makeConfig width.toNat height.toNat
  let assets ← Assets.load
  let game ← initGameState config
  appState.set <| some {
    frame := 0
    accumulator := 0.0
    config := config
    assets := assets
    game := game
  }

@[export sdlIterate]
def sdlIterate : IO Unit := do
  let some state ← appState.get
    | throw <| IO.userError "app not initialized"

  let mut frame := state.frame
  let mut accumulator := state.accumulator
  let mut game := state.game

  if frame < warmupFrames then
    frame := frame + 1
    accumulator := 0.0
  else
    let frameDt := min (← SDL.getFrameTime) maxFrameDt
    let tickDt := state.config.tickDt
    let mut remaining := accumulator + frameDt
    while remaining >= tickDt do
      let isSpaceDown ← SDL.isKeyDown SDL.Key.space
      let didTap ← SDL.consumeTap
      let shouldFlap := isSpaceDown || didTap
      let isRestartDown ← SDL.isKeyDown SDL.Key.r
      if !(← hasCollision state.config game) then
        game ← stepGame state.config game shouldFlap
      else if isRestartDown || didTap then
        game ← initGameState state.config
      remaining := remaining - tickDt
      frame := frame + 1
    accumulator := remaining

  renderGame state.config state.assets game
  SDL.renderPresent
  appState.set <| some {
    frame := frame
    accumulator := accumulator
    config := state.config
    assets := state.assets
    game := game
  }

@[export sdlEvent]
def sdlEvent (eventType : UInt32) : IO Unit := do
  SDL.recordEvent eventType

@[export sdlQuit]
def sdlQuit : IO Unit := do
  appState.set none
  SDL.shutdown
