APP_NAME := LeanSDLFlappy
APP_EXECUTABLE_NAME := LeanSDLFlappy
APP_LIB_TARGET := ExampleFlappyApp:static
APP_DEP_STATIC_TARGETS := Flappy:static Batteries:static
APP_DEP_STATIC_LIBS := .lake/packages/flappy/.lake/build/lib/libflappy_Flappy.a .lake/packages/batteries/.lake/build/lib/libbatteries_Batteries.a
APP_ROOT_MODULE_INITIALIZER := initialize_example__flappy_ExampleFlappy
APP_ASSETS_DIR := $(ROOT_DIR)/example-flappy/assets
SDL_APP_BUNDLE_ID ?= dev.paulcadman.LeanSDLFlappy
