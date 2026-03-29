#ifndef LEAN_SDL_BINDINGS_H
#define LEAN_SDL_BINDINGS_H

#include <lean/lean.h>
#include <SDL3/SDL.h>

lean_obj_res lean_sdl_load_svg_texture(b_lean_obj_arg path_arg);
lean_obj_res lean_sdl_render_texture(b_lean_obj_arg texture, double x, double y,
                                     double width, double height);
lean_obj_res lean_sdl_init_video(void);
lean_obj_res
lean_sdl_setup_fullscreen_window_and_renderer(b_lean_obj_arg title);
lean_obj_res lean_sdl_get_window_width(void);
lean_obj_res lean_sdl_get_window_height(void);
lean_obj_res lean_sdl_set_render_draw_color(uint32_t r, uint32_t g, uint32_t b,
                                            uint32_t a);
lean_obj_res lean_sdl_render_clear(void);
lean_obj_res lean_sdl_render_fill_rect(double x, double y, double w, double h);
lean_obj_res lean_sdl_render_present(void);
lean_obj_res lean_sdl_shutdown(void);
lean_obj_res lean_sdl_get_frame_time(void);
lean_obj_res lean_sdl_is_key_down(uint32_t scancode);
lean_obj_res lean_sdl_record_event(uint32_t event_type);
lean_obj_res lean_sdl_consume_tap(void);
lean_obj_res lean_sdl_measure_text(b_lean_obj_arg text_arg, uint32_t size);
lean_obj_res lean_sdl_draw_text(b_lean_obj_arg text_arg, double x, double y,
                                uint32_t size, uint32_t r, uint32_t g,
                                uint32_t b, uint32_t a);

#endif
