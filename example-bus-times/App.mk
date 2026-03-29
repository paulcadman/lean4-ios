APP_NAME := LeanBusTimes
APP_EXECUTABLE_NAME := LeanBusTimes
APP_LIB_TARGET := ExampleBusTimesApp:static
APP_DEP_STATIC_LIBS = $(APP_OBJ_DIR)/HttpBridge.o
APP_ROOT_MODULE_INITIALIZER := initialize_example__bus__times_ExampleBusTimes
APP_ASSETS_DIR := assets
SDL_APP_BUNDLE_ID ?= dev.paulcadman.LeanBusTimes
