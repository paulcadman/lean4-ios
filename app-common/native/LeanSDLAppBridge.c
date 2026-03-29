#include "LeanSDLAppBridge.h"

#include <lean/lean.h>

lean_object * sdlInit(void);
lean_object * sdlIterate(void);
lean_object * sdlEvent(uint32_t eventType);
lean_object * sdlQuit(void);

bool lean_sdl_app_init(void) {
    lean_object *result = sdlInit();
    if (lean_io_result_is_error(result)) {
        lean_dec_ref(result);
        return false;
    }
    lean_dec_ref(result);
    return true;
}

bool lean_sdl_app_iterate(void) {
    lean_object *result = sdlIterate();
    if (lean_io_result_is_error(result)) {
        lean_dec_ref(result);
        return false;
    }
    lean_dec_ref(result);
    return true;
}

bool lean_sdl_app_event(uint32_t eventType) {
    lean_object *result = sdlEvent(eventType);
    if (lean_io_result_is_error(result)) {
        lean_dec_ref(result);
        return false;
    }
    lean_dec_ref(result);
    return true;
}

void lean_sdl_app_quit(void) {
    lean_object *result = sdlQuit();
    lean_dec_ref(result);
}
