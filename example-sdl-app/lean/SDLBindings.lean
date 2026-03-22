namespace SDL

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

end SDL
