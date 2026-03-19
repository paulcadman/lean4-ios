namespace SDL

@[extern "lean_sdl_init_video"]
opaque initVideo : IO Unit

@[extern "lean_sdl_setup_window_and_renderer"]
opaque setupWindowAndRenderer : @& String -> UInt32 -> UInt32 -> IO Unit

@[extern "lean_sdl_get_render_output_width"]
opaque getRenderOutputWidth : IO UInt32

@[extern "lean_sdl_get_render_output_height"]
opaque getRenderOutputHeight : IO UInt32

@[extern "lean_sdl_set_render_draw_color"]
opaque setRenderDrawColor : UInt32 -> UInt32 -> UInt32 -> UInt32 -> IO Unit

@[extern "lean_sdl_render_clear"]
opaque renderClear : IO Unit

@[extern "lean_sdl_render_fill_rect"]
opaque renderFillRect : UInt32 -> UInt32 -> UInt32 -> UInt32 -> IO Unit

@[extern "lean_sdl_render_present"]
opaque renderPresent : IO Unit

@[extern "lean_sdl_shutdown"]
opaque shutdown : IO Unit

end SDL
