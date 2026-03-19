#include "LeanSDLModuleRegistration.h"

lean_object * initialize_example__sdl__app_ExampleSDL(uint8_t builtin);

const lean_module_initializer_fn lean_sdl_app_root_modules[] = {
    initialize_example__sdl__app_ExampleSDL,
};

const size_t lean_sdl_app_root_module_count =
    sizeof(lean_sdl_app_root_modules) / sizeof(lean_sdl_app_root_modules[0]);
