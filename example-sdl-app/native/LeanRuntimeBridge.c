#include "LeanRuntimeBridge.h"

#ifndef LEAN_APP_ROOT_MODULE
#error "LEAN_APP_ROOT_MODULE must be defined to the root Lean module initializer"
#endif

extern lean_object * LEAN_APP_ROOT_MODULE(uint8_t builtin);

extern void lean_initialize_runtime_module(void);
extern void lean_initialize_thread(void);

bool lean_runtime_initialize_root_module(void) {
    static bool runtime_initialized = false;

    if (!runtime_initialized) {
        lean_initialize_runtime_module();
        lean_initialize_thread();
        runtime_initialized = true;
    }

    lean_object *result = LEAN_APP_ROOT_MODULE(1);
    if (lean_io_result_is_error(result)) {
        lean_dec_ref(result);
        return false;
    }

    lean_dec_ref(result);
    return true;
}
