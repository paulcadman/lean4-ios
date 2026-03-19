#define SDL_MAIN_USE_CALLBACKS 1
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>

#include "../LeanRuntimeBridge.h"
#include "../LeanSDLAppBridge.h"
#include "../LeanSDLModuleRegistration.h"

SDL_AppResult SDL_AppInit(void **appstate, int argc, char *argv[]) {
    (void)argc;
    (void)argv;
    if (!lean_runtime_initialize_modules(lean_sdl_app_root_modules, lean_sdl_app_root_module_count)) {
        return SDL_APP_FAILURE;
    }
    if (!lean_sdl_app_init()) {
        return SDL_APP_FAILURE;
    }
    *appstate = NULL;
    return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppIterate(void *appstate) {
    (void)appstate;
    if (!lean_sdl_app_iterate()) {
        return SDL_APP_FAILURE;
    }
    return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppEvent(void *appstate, SDL_Event *event) {
    (void)appstate;
    switch (event->type) {
        case SDL_EVENT_QUIT:
        case SDL_EVENT_TERMINATING:
            return SDL_APP_SUCCESS;
        default:
            return SDL_APP_CONTINUE;
    }
}

void SDL_AppQuit(void *appstate, SDL_AppResult result) {
    (void)appstate;
    (void)result;
    lean_sdl_app_quit();
}
