#include "LeanSDLBindings.h"
#include "lean/lean.h"
#include "resvg.h"
#include <stdbool.h>
#include <stdint.h>

#include <SDL3/SDL.h>
#include <SDL3_ttf/SDL_ttf.h>

static SDL_Window *g_window = NULL;
static SDL_Renderer *g_renderer = NULL;
static TTF_Font *g_font = NULL;
static Uint64 g_last_present_time_ns = 0;
static double g_frame_time_seconds = 0.0;
static bool g_tap_pending = false;
static const char *g_font_asset_path = "assets/SourceSansPro-Regular.ttf";

static lean_external_class *g_sdl_texture_class = NULL;

static void sdl_texture_finalizer(void *ptr) {
  if (ptr != NULL) {
    SDL_DestroyTexture((SDL_Texture *)ptr);
  }
}

static void noop_foreach(void *mod, b_lean_obj_arg fn) {}

static lean_external_class *get_sdl_texture_class(void) {
  if (g_sdl_texture_class == NULL) {
    g_sdl_texture_class =
        lean_register_external_class(&sdl_texture_finalizer, noop_foreach);
  }
  return g_sdl_texture_class;
}

static SDL_Texture *texture_of_arg(b_lean_obj_arg texture) {
  return (SDL_Texture *)lean_get_external_data(texture);
}

static lean_object *lean_sdl_texture_mk(void *texture) {
  return lean_alloc_external(get_sdl_texture_class(), texture);
}

static inline lean_obj_res lean_sdl_error(const char *msg) {
  return lean_io_result_mk_error(lean_mk_io_user_error(lean_mk_string(msg)));
}

lean_obj_res lean_sdl_record_event(uint32_t event_type) {
  switch (event_type) {
    case SDL_EVENT_MOUSE_BUTTON_DOWN:
    case SDL_EVENT_FINGER_DOWN:
      g_tap_pending = true;
      break;
    default:
      break;
  }

  return lean_io_result_mk_ok(lean_box(0));
}

static bool lean_sdl_load_default_font(void) {
  g_font = TTF_OpenFont(g_font_asset_path, 20.0f);
  return g_font != NULL;
}

lean_obj_res lean_sdl_load_svg_texture(b_lean_obj_arg path_arg) {
    const char* path = lean_string_cstr(path_arg);
    resvg_options *opts = resvg_options_create();
    resvg_render_tree *tree;
    uint32_t parse_result = resvg_parse_tree_from_file(path, opts, &tree);
    resvg_options_destroy(opts);

    if (parse_result != RESVG_OK) {
        return lean_sdl_error("resvg_parse_tree_from_file failed");
    }

    resvg_size image_size = resvg_get_image_size(tree);
    uint32_t width = image_size.width;
    uint32_t height = image_size.height;
    char* pixels = (char *)SDL_calloc((size_t)width * (size_t)height, 4);
    if (pixels == NULL) {
        resvg_tree_destroy(tree);
        return lean_sdl_error("SDL_calloc failed");
    }

    resvg_render(tree, resvg_transform_identity(), width, height, pixels);
    resvg_tree_destroy(tree);

    SDL_Surface *surface = SDL_CreateSurfaceFrom(width, height, SDL_PIXELFORMAT_RGBA32, pixels, width * 4);
    if (surface == NULL) {
        SDL_free(pixels);
        return lean_sdl_error(SDL_GetError());
    }

    SDL_Texture *texture = SDL_CreateTextureFromSurface(g_renderer, surface);
    SDL_DestroySurface(surface);
    SDL_free(pixels);

    if (texture == NULL) {
        return lean_sdl_error(SDL_GetError());
    }

    if (!SDL_SetTextureBlendMode(texture, SDL_BLENDMODE_BLEND)) {
        SDL_DestroyTexture(texture);
        return lean_sdl_error(SDL_GetError());
    }

    return lean_io_result_mk_ok(lean_sdl_texture_mk(texture));
}

lean_obj_res lean_sdl_render_texture(b_lean_obj_arg texture, double x, double y, double width, double height) {
    if (g_renderer == NULL) {
        return lean_sdl_error("renderer not initalizied");
    }
    SDL_FRect rect = {.x = (float)x, .y = (float)y, .w = (float)width, .h = (float)height};
    if (!SDL_RenderTexture(g_renderer, texture_of_arg(texture), NULL, &rect)) {
        return lean_sdl_error(SDL_GetError());
    }
    return lean_io_result_mk_ok(lean_box(0));
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

  g_last_present_time_ns = 0;
  g_frame_time_seconds = 0.0;
  g_tap_pending = false;

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

  if (TTF_WasInit() == 0 && !TTF_Init()) {
    return lean_sdl_error(SDL_GetError());
  }

  if (!lean_sdl_load_default_font()) {
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
  if (g_renderer == NULL) {
    return lean_sdl_error("renderer not initialized");
  }
  SDL_FRect rect = {.x = (double)x, .y = (double)y, .w = (double)w, .h = (double)h};
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
  g_last_present_time_ns = 0;
  g_frame_time_seconds = 0.0;
  g_tap_pending = false;
  if (TTF_WasInit() > 0) {
    TTF_Quit();
  }
  SDL_Quit();
  return lean_io_result_mk_ok(lean_box(0));
}

lean_obj_res lean_sdl_get_frame_time(void) {
  return lean_io_result_mk_ok(lean_box_float(g_frame_time_seconds));
}

lean_obj_res lean_sdl_is_key_down(uint32_t scancode) {
  const bool *keyboard = SDL_GetKeyboardState(NULL);
  if (keyboard == NULL) {
    return lean_sdl_error(SDL_GetError());
  }
  if (scancode >= SDL_SCANCODE_COUNT) {
    return lean_io_result_mk_ok(lean_box(0));
  }
  return lean_io_result_mk_ok(lean_box(keyboard[scancode] ? 1 : 0));
}

lean_obj_res lean_sdl_consume_tap(void) {
  bool pending = g_tap_pending;
  g_tap_pending = false;
  return lean_io_result_mk_ok(lean_box(pending ? 1 : 0));
}

lean_obj_res lean_sdl_measure_text(b_lean_obj_arg text_arg, uint32_t size) {
    int width = 0;
    int height = 0;
    lean_object *result = NULL;

    if (g_font == NULL) {
        return lean_sdl_error("font not initialized");
    }
    if (!TTF_SetFontSize(g_font, (float)size)) {
        return lean_sdl_error(SDL_GetError());
    }
    if (!TTF_GetStringSize(g_font, lean_string_cstr(text_arg), 0, &width, &height)) {
        return lean_sdl_error(SDL_GetError());
    }

    result = lean_alloc_ctor(0, 2, 0);
    lean_ctor_set(result, 0, lean_box_uint32((uint32_t)width));
    lean_ctor_set(result, 1, lean_box_uint32((uint32_t)height));
    return lean_io_result_mk_ok(result);
}

lean_obj_res lean_sdl_draw_text(b_lean_obj_arg text_arg, double x, double y,
                                uint32_t size, uint32_t r, uint32_t g,
                                uint32_t b, uint32_t a) {
    if (g_renderer == NULL) {
        return lean_sdl_error("renderer not initialized");
    }
    if (g_font == NULL) {
        return lean_sdl_error("font not initialized");
    }
    if (!TTF_SetFontSize(g_font, (float)size)) {
        return lean_sdl_error(SDL_GetError());
    }

    SDL_Color color = {.r = (Uint8)r, .g = (Uint8)g, .b = (Uint8)b, .a = (Uint8)a};
    SDL_Surface *surface =
        TTF_RenderText_Blended(g_font, lean_string_cstr(text_arg), 0, color);
    if (surface == NULL) {
        return lean_sdl_error(SDL_GetError());
    }

    SDL_Texture *texture = SDL_CreateTextureFromSurface(g_renderer, surface);
    if (texture == NULL) {
        SDL_DestroySurface(surface);
        return lean_sdl_error(SDL_GetError());
    }

    SDL_FRect rect = {
        .x = (float)x,
        .y = (float)y,
        .w = (float)surface->w,
        .h = (float)surface->h,
    };
    SDL_DestroySurface(surface);

    if (!SDL_RenderTexture(g_renderer, texture, NULL, &rect)) {
        SDL_DestroyTexture(texture);
        return lean_sdl_error(SDL_GetError());
    }

    SDL_DestroyTexture(texture);
    return lean_io_result_mk_ok(lean_box(0));
}
