#ifndef LEAN_RUNTIME_BRIDGE_H
#define LEAN_RUNTIME_BRIDGE_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#include <lean/lean.h>

#ifdef __cplusplus
extern "C" {
#endif

bool lean_runtime_initialize_root_module(void);

#ifdef __cplusplus
}
#endif

#endif
