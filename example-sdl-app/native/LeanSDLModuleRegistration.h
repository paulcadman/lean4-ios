#ifndef LEAN_SDL_MODULE_REGISTRATION_H
#define LEAN_SDL_MODULE_REGISTRATION_H

#include "LeanRuntimeBridge.h"

#ifdef __cplusplus
extern "C" {
#endif

extern const lean_module_initializer_fn lean_sdl_app_root_modules[];
extern const size_t lean_sdl_app_root_module_count;

#ifdef __cplusplus
}
#endif

#endif
