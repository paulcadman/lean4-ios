import Lean.Data.Json
import SDLBindings

open Lean

namespace Http

@[extern "lean_http_fetch_body"]
opaque fetchBody : @& String -> IO String

end Http

def appTitle : String := "Next W3 Bus"
def stopId : String := "490003211E"
def stopName : String := "Park Road"
def arrivalsUrl : String := s!"https://api.tfl.gov.uk/StopPoint/{stopId}/arrivals"
def busRoute : String := "w3"

def maxFrameDt : Float := 0.25
def warmupFrames : UInt32 := 10
def refreshPeriod : Float := 30.0

structure ArrivalPrediction where
  lineId : String
  lineName : String
  stationName : String
  destinationName : String
  towards : String
  timeToStation : Nat
  expectedArrival : String
  timestamp : String
deriving FromJson

structure AppState where
  frame : UInt32
  refreshCountdown : Float
  displayFps : Float
  lines : Array String
deriving Inhabited

initialize appState : IO.Ref AppState <- IO.mkRef {
  frame := 0
  refreshCountdown := 0.0
  displayFps := 0.0
  lines := #[]
}

def formatCountdown (seconds : Nat) : String :=
  let minutes := seconds / 60
  let remainingSeconds := seconds % 60
  if minutes == 0 then
    s!"{remainingSeconds}s"
  else
    s!"{minutes}m {remainingSeconds}s"

def parseArrivals (rawJson : String) : Except String (Array ArrivalPrediction) := do
  let json ← Json.parse rawJson
  fromJson? json

def earliestArrival? (arrivals : Array ArrivalPrediction) : Option ArrivalPrediction :=
  arrivals.foldl
    (init := none)
    fun best? arrival =>
      if arrival.lineId != busRoute then
        best?
      else
        match best? with
        | none => some arrival
        | some best =>
          if arrival.timeToStation < best.timeToStation then
            some arrival
          else
            best?

def buildLines (arrival : ArrivalPrediction) : Array String :=
  #[
    s!"Stop: {arrival.stationName} ({stopId})",
    s!"Route: {arrival.lineName.toUpper} to {arrival.destinationName}",
    s!"Next bus: {formatCountdown arrival.timeToStation}",
    "Expected arrival:",
    s!"   {arrival.expectedArrival}",
    "Updated:",
    s!"   {arrival.timestamp}",
  ]

def loadLines : IO (Array String) := do
  try
    let rawJson ← Http.fetchBody arrivalsUrl
    let arrivals ←
      match parseArrivals rawJson with
      | .ok parsed => pure parsed
      | .error err => throw <| IO.userError s!"JSON parse failed: {err}"
    match earliestArrival? arrivals with
    | some arrival => pure <| buildLines arrival
    | none =>
      pure #[
        s!"Stop: {stopName} ({stopId})",
        "No W3 arrivals are currently listed.",
        "Tap anywhere to retry."
      ]
  catch e =>
    pure #[
      s!"Stop: {stopName} ({stopId})",
      "Could not load live TfL arrivals.",
      e.toString,
      "Tap anywhere to retry."
    ]

def refreshState (state : AppState) : IO AppState := do
  let lines ← loadLines
  pure {
    frame := state.frame
    refreshCountdown := refreshPeriod
    displayFps := state.displayFps
    lines := lines
  }

def drawLine (text : String) (x y : Float) (size : UInt32) (rgb : UInt32 × UInt32 × UInt32) : IO Unit := do
  let (r, g, b) := rgb
  SDL.drawText text x y size r g b 255

@[export sdlInit]
def sdlInit : IO Unit := do
  SDL.initVideo
  SDL.setupFullscreenWindowAndRenderer appTitle
  let lines ← loadLines
  appState.set {
    frame := 0
    refreshCountdown := refreshPeriod
    displayFps := 0.0
    lines := lines
  }

@[export sdlIterate]
def sdlIterate : IO Unit := do
  let state ← appState.get
  let mut nextState := { state with frame := state.frame + 1 }

  let frameDt := min (← SDL.getFrameTime) maxFrameDt
  let instantFps := if frameDt > 0.0 then 1.0 / frameDt else 0.0
  let displayFps :=
    if state.frame < warmupFrames then
      instantFps
    else if state.displayFps <= 0.0 then
      instantFps
    else
      state.displayFps * 0.9 + instantFps * 0.1
  nextState := { nextState with displayFps := displayFps }
  let didTap ← SDL.consumeTap
  let refreshCountdown := nextState.refreshCountdown - frameDt
  nextState := { nextState with refreshCountdown := refreshCountdown }
  if didTap || refreshCountdown <= 0.0 then
    nextState ← refreshState nextState

  SDL.setRenderDrawColor 247 244 236 255
  SDL.renderClear

  drawLine appTitle 36.0 52.0 34 (18, 52, 86)

  let mut y := 118.0
  for line in nextState.lines do
    drawLine line 36.0 y 24 (35, 35, 35)
    y := y + 38.0

  let secondsToRefresh : Nat :=
    max 0.0 nextState.refreshCountdown
    |> Float.ceil
    |>.toUInt64.toNat
  let fps : Nat :=
    max 0.0 nextState.displayFps
    |> fun n => Float.floor (n + 0.5)
    |>.toUInt64.toNat
  let fpsText := s!"FPS: {fps}"
  let (fpsWidth, _) ← SDL.measureText fpsText 18
  let windowWidth ← SDL.getWindowWidth
  let fpsX := windowWidth.toFloat - fpsWidth.toFloat - 36.0

  drawLine
    s!"Auto refresh in: {secondsToRefresh}s - tap to refresh now"
    36.0
    (y + 12.0)
    18
    (110, 110, 110)

  drawLine
    fpsText
    fpsX
    36.0
    18
    (110, 110, 110)

  SDL.renderPresent
  appState.set nextState

@[export sdlEvent]
def sdlEvent (eventType : UInt32) : IO Unit := do
  SDL.recordEvent eventType

@[export sdlQuit]
def sdlQuit : IO Unit := do
  SDL.shutdown
