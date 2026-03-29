namespace SDL

opaque Texture : Type

namespace Key

def r : UInt32 := 21
def space : UInt32 := 44

end Key

@[extern "lean_sdl_init_video"]
opaque initVideo : IO Unit

@[extern "lean_sdl_setup_fullscreen_window_and_renderer"]
opaque setupFullscreenWindowAndRenderer : @& String -> IO Unit

@[extern "lean_sdl_get_window_width"]
opaque getWindowWidth : IO UInt32

@[extern "lean_sdl_get_window_height"]
opaque getWindowHeight : IO UInt32

@[extern "lean_sdl_set_render_draw_color"]
opaque setRenderDrawColor : UInt32 -> UInt32 -> UInt32 -> UInt32 -> IO Unit

@[extern "lean_sdl_render_clear"]
opaque renderClear : IO Unit

@[extern "lean_sdl_render_fill_rect"]
opaque renderFillRect : Float -> Float -> Float -> Float -> IO Unit

@[extern "lean_sdl_render_present"]
opaque renderPresent : IO Unit

@[extern "lean_sdl_shutdown"]
opaque shutdown : IO Unit

@[extern "lean_sdl_get_frame_time"]
opaque getFrameTime : IO Float

@[extern "lean_sdl_is_key_down"]
opaque isKeyDown : UInt32 → IO Bool

@[extern "lean_sdl_record_event"]
opaque recordEvent : UInt32 → IO Unit

@[extern "lean_sdl_consume_tap"]
opaque consumeTap : IO Bool

@[extern "lean_sdl_measure_text"]
opaque measureText : @& String → (size : UInt32) → IO (UInt32 × UInt32)

@[extern "lean_sdl_load_svg_texture"]
opaque loadSvgTexture : @& String → IO Texture

@[extern "lean_sdl_render_texture"]
opaque renderTexture : @& Texture → (x : Float) → (y : Float) → (width : Float) → (height : Float) → IO Unit

@[extern "lean_sdl_draw_text"]
opaque drawText : @& String → (x : Float) → (y : Float) → (size : UInt32) → (r : UInt32) → (g : UInt32) → (b : UInt32) → (a : UInt32) → IO Unit

end SDL
