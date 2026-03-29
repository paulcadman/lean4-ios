#ifndef LEAN_SDL_APP_BRIDGE_H
#define LEAN_SDL_APP_BRIDGE_H

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

bool lean_sdl_app_init(void);
bool lean_sdl_app_iterate(void);
bool lean_sdl_app_event(uint32_t event_type);
void lean_sdl_app_quit(void);

#ifdef __cplusplus
}
#endif

#endif
