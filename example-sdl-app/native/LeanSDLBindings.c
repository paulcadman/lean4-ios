#include "LeanSDLBindings.h"
#include <stdbool.h>
#include <stdint.h>

#include <SDL3/SDL.h>

static SDL_Window *g_window = NULL;
static SDL_Renderer *g_renderer = NULL;
static Uint64 g_last_present_time_ns = 0;
static double g_frame_time_seconds = 0.0;

static inline lean_obj_res lean_sdl_error(const char *msg) {
  return lean_io_result_mk_error(lean_mk_io_user_error(lean_mk_string(msg)));
}

lean_obj_res lean_sdl_init_video(void) {
  if (!SDL_Init(SDL_INIT_VIDEO)) {
    return lean_sdl_error(SDL_GetError());
  }
  return lean_io_result_mk_ok(lean_box(0));
}

lean_obj_res
lean_sdl_setup_fullscreen_window_and_renderer(b_lean_obj_arg title) {
  int point_width = 0;
  int point_height = 0;
  SDL_WindowFlags window_flags =
      SDL_WINDOW_BORDERLESS | SDL_WINDOW_HIGH_PIXEL_DENSITY;

  if (g_renderer != NULL) {
    SDL_DestroyRenderer(g_renderer);
    g_renderer = NULL;
  }

  if (g_window != NULL) {
    SDL_DestroyWindow(g_window);
    g_window = NULL;
  }

  g_window = SDL_CreateWindow(lean_string_cstr(title), 0, 0, window_flags);
  if (g_window == NULL) {
    return lean_sdl_error(SDL_GetError());
  }

  g_renderer = SDL_CreateRenderer(g_window, NULL);
  if (g_renderer == NULL) {
    SDL_DestroyWindow(g_window);
    g_window = NULL;
    return lean_sdl_error(SDL_GetError());
  }
  if (!SDL_SetRenderVSync(g_renderer, 1)) {
    SDL_DestroyRenderer(g_renderer);
    g_renderer = NULL;
    SDL_DestroyWindow(g_window);
    g_window = NULL;
    return lean_sdl_error(SDL_GetError());
  }

  if (!SDL_GetWindowSize(g_window, &point_width, &point_height)) {
    return lean_sdl_error(SDL_GetError());
  }

  if (!SDL_SetRenderLogicalPresentation(g_renderer, point_width, point_height,
                                        SDL_LOGICAL_PRESENTATION_STRETCH)) {
    return lean_sdl_error(SDL_GetError());
  }

  return lean_io_result_mk_ok(lean_box(0));
}

static lean_obj_res lean_sdl_get_window_dimension(bool want_width) {
  int width = 0;
  int height = 0;
  if (g_window == NULL) {
    return lean_sdl_error("window not initialized");
  }
  if (!SDL_GetWindowSize(g_window, &width, &height)) {
    return lean_sdl_error(SDL_GetError());
  }
  return lean_io_result_mk_ok(
      lean_box_uint32((uint32_t)(want_width ? width : height)));
}

lean_obj_res lean_sdl_get_window_width(void) {
  return lean_sdl_get_window_dimension(true);
}

lean_obj_res lean_sdl_get_window_height(void) {
  return lean_sdl_get_window_dimension(false);
}

lean_obj_res lean_sdl_set_render_draw_color(uint32_t r, uint32_t g, uint32_t b,
                                            uint32_t a) {
  if (g_renderer == NULL) {
    return lean_sdl_error("renderer not initialized");
  }
  if (!SDL_SetRenderDrawColor(g_renderer, (Uint8)r, (Uint8)g, (Uint8)b,
                              (Uint8)a)) {
    return lean_sdl_error(SDL_GetError());
  }
  return lean_io_result_mk_ok(lean_box(0));
}

lean_obj_res lean_sdl_render_clear(void) {
  if (g_renderer == NULL) {
    return lean_sdl_error("renderer not initialized");
  }
  if (!SDL_RenderClear(g_renderer)) {
    return lean_sdl_error(SDL_GetError());
  }
  return lean_io_result_mk_ok(lean_box(0));
}

lean_obj_res lean_sdl_render_fill_rect(double x, double y, double w, double h) {
  SDL_FRect rect;
  if (g_renderer == NULL) {
    return lean_sdl_error("renderer not initialized");
  }
  rect.x = (float)x;
  rect.y = (float)y;
  rect.w = (float)w;
  rect.h = (float)h;
  if (!SDL_RenderFillRect(g_renderer, &rect)) {
    return lean_sdl_error(SDL_GetError());
  }
  return lean_io_result_mk_ok(lean_box(0));
}

lean_obj_res lean_sdl_render_present(void) {
  if (g_renderer == NULL) {
    return lean_sdl_error("renderer not initialized");
  }
  if (!SDL_RenderPresent(g_renderer)) {
    return lean_sdl_error(SDL_GetError());
  }

  Uint64 now = SDL_GetTicksNS();
  if (g_last_present_time_ns != 0 && now >= g_last_present_time_ns) {
    g_frame_time_seconds =
        (double)(now - g_last_present_time_ns) / 1000000000.0;
  } else {
    g_frame_time_seconds = 0.0;
  }
  g_last_present_time_ns = now;
  return lean_io_result_mk_ok(lean_box(0));
}

lean_obj_res lean_sdl_shutdown(void) {
  if (g_renderer != NULL) {
    SDL_DestroyRenderer(g_renderer);
    g_renderer = NULL;
  }
  if (g_window != NULL) {
    SDL_DestroyWindow(g_window);
    g_window = NULL;
  }
  SDL_Quit();
  return lean_io_result_mk_ok(lean_box(0));
}

lean_obj_res lean_sdl_get_frame_time(void) {
  return lean_io_result_mk_ok(lean_box_float(g_frame_time_seconds));
}
