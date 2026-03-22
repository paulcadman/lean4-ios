.DEFAULT_GOAL := sim-app

ROOT_DIR := ..

LEAN_SRC_DIR := $(ROOT_DIR)/lean4
SIMULATOR_SDK ?= iphonesimulator
IOS_DEPLOYMENT_TARGET ?= 16.0
SIMULATOR_TARGET ?= arm64-apple-ios$(IOS_DEPLOYMENT_TARGET)-simulator
SIMULATOR_SDK_TAG := $(subst -,_,$(subst .,_,$(SIMULATOR_TARGET)))
SIMULATOR_DEVICE ?= iPhone 16
SDL_APP_BUNDLE_ID ?= dev.paulcadman.LeanSDLExample

BUILD_DIR := $(ROOT_DIR)/build
SIM_RUNTIME_BUILD_DIR := $(BUILD_DIR)/lean4-$(SIMULATOR_SDK_TAG)-runtime
SIM_IOS_BUILD_DIR := $(BUILD_DIR)/ios-lean-$(SIMULATOR_SDK_TAG)
SIM_RUNTIME_LIB := $(SIM_RUNTIME_BUILD_DIR)/lib/lean/libleanrt.a
SIM_STDLIB_INIT_LIB := $(SIM_IOS_BUILD_DIR)/lib/libInit.a
SIMULATOR_SDK_PATH := $(shell xcrun --sdk $(SIMULATOR_SDK) --show-sdk-path)

SDL_XCODE_DIR := $(ROOT_DIR)/third-party/SDL/Xcode/SDL
SDL_XCODE_PROJECT := $(SDL_XCODE_DIR)/SDL.xcodeproj
SDL_BUILD_DIR := $(BUILD_DIR)/sdl3
SDL_MODULE_CACHE_DIR := $(SDL_BUILD_DIR)/ModuleCache
SDL_BUILD_HOME := $(SDL_BUILD_DIR)/home
SDL_SIM_ARCHIVE := $(SDL_BUILD_DIR)/SDL3-iphonesimulator.xcarchive
SDL_DEVICE_ARCHIVE := $(SDL_BUILD_DIR)/SDL3-iphoneos.xcarchive
SDL_XCFRAMEWORK := $(SDL_BUILD_DIR)/SDL3.xcframework
SDL_XCFRAMEWORK_INFO := $(SDL_XCFRAMEWORK)/Info.plist
SDL_SIM_FRAMEWORK := $(SDL_XCFRAMEWORK)/ios-arm64_x86_64-simulator/SDL3.framework

APP_NATIVE_DIR := native
APP_BUILD_DIR := $(BUILD_DIR)/ios-sdl-sim-app
APP_OBJ_DIR := $(APP_BUILD_DIR)/obj
APP_DIR := $(APP_BUILD_DIR)/LeanSDLExample.app
APP_BIN := $(APP_DIR)/LeanSDLExample
APP_INFO_PLIST := $(APP_DIR)/Info.plist
APP_FRAMEWORKS_DIR := $(APP_DIR)/Frameworks
APP_SDL_FRAMEWORK := $(APP_FRAMEWORKS_DIR)/SDL3.framework
APP_LIB_TARGET := ExampleSDLApp:static
APP_BINDINGS_SRC := $(APP_NATIVE_DIR)/LeanSDLBindings.c
APP_BINDINGS_HEADER := $(APP_NATIVE_DIR)/LeanSDLBindings.h
APP_BINDINGS_OBJ := $(APP_OBJ_DIR)/LeanSDLBindings.o
APP_RUNTIME_BRIDGE_SRC := $(APP_NATIVE_DIR)/LeanRuntimeBridge.c
APP_RUNTIME_BRIDGE_HEADER := $(APP_NATIVE_DIR)/LeanRuntimeBridge.h
APP_RUNTIME_BRIDGE_OBJ := $(APP_OBJ_DIR)/LeanRuntimeBridge.o
APP_BRIDGE_SRC := $(APP_NATIVE_DIR)/LeanSDLAppBridge.c
APP_BRIDGE_HEADER := $(APP_NATIVE_DIR)/LeanSDLAppBridge.h
APP_BRIDGE_OBJ := $(APP_OBJ_DIR)/LeanSDLAppBridge.o
APP_REGISTRATION_SRC := $(APP_NATIVE_DIR)/LeanSDLModuleRegistration.c
APP_REGISTRATION_HEADER := $(APP_NATIVE_DIR)/LeanSDLModuleRegistration.h
APP_REGISTRATION_OBJ := $(APP_OBJ_DIR)/LeanSDLModuleRegistration.o
APP_MAIN_SRC := $(APP_NATIVE_DIR)/App/main.c
APP_MAIN_OBJ := $(APP_OBJ_DIR)/main.o
APP_INFO_PLIST_SRC := $(APP_NATIVE_DIR)/App/Info.plist
APP_LAUNCH_STORYBOARD_SRC := $(APP_NATIVE_DIR)/App/LaunchScreen.storyboard
APP_LAUNCH_STORYBOARD_DEST := $(APP_DIR)/LaunchScreen.storyboard

APP_PROJECT_CFLAGS := -Wall -Werror

.PHONY: sim-runtime sdl3-xcframework app-lib sim-app run-sim-app clean

sim-runtime:
	$(MAKE) -C $(ROOT_DIR) IOS_SDK="$(SIMULATOR_SDK)" IOS_TARGET="$(SIMULATOR_TARGET)" IOS_DEPLOYMENT_TARGET="$(IOS_DEPLOYMENT_TARGET)" runtime stdlib-init

$(SDL_XCFRAMEWORK_INFO):
	rm -rf $(SDL_SIM_ARCHIVE) $(SDL_DEVICE_ARCHIVE) $(SDL_XCFRAMEWORK)
	mkdir -p $(SDL_MODULE_CACHE_DIR) $(SDL_BUILD_HOME)
	HOME=$(abspath $(SDL_BUILD_HOME)) xcodebuild archive \
	  -project $(SDL_XCODE_PROJECT) \
	  -scheme SDL3 \
	  -configuration Release \
	  -archivePath $(abspath $(SDL_SIM_ARCHIVE)) \
	  -destination 'generic/platform=iOS Simulator' \
	  -derivedDataPath $(abspath $(SDL_BUILD_DIR))/DerivedData \
	  CLANG_MODULE_CACHE_PATH=$(abspath $(SDL_MODULE_CACHE_DIR)) \
	  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
	  SKIP_INSTALL=NO
	HOME=$(abspath $(SDL_BUILD_HOME)) xcodebuild archive \
	  -project $(SDL_XCODE_PROJECT) \
	  -scheme SDL3 \
	  -configuration Release \
	  -archivePath $(abspath $(SDL_DEVICE_ARCHIVE)) \
	  -destination 'generic/platform=iOS' \
	  -derivedDataPath $(abspath $(SDL_BUILD_DIR))/DerivedData \
	  CLANG_MODULE_CACHE_PATH=$(abspath $(SDL_MODULE_CACHE_DIR)) \
	  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
	  SKIP_INSTALL=NO
	HOME=$(abspath $(SDL_BUILD_HOME)) xcodebuild -create-xcframework \
	  -framework $(abspath $(SDL_SIM_ARCHIVE))/Products/Library/Frameworks/SDL3.framework \
	  -framework $(abspath $(SDL_DEVICE_ARCHIVE))/Products/Library/Frameworks/SDL3.framework \
	  -output $(abspath $(SDL_XCFRAMEWORK))

sdl3-xcframework: $(SDL_XCFRAMEWORK_INFO)

app-lib: sim-runtime
	LEAN_CC="$(abspath $(ROOT_DIR)/scripts/ios-leanc.sh)" \
	LEAN_AR="$(abspath $(ROOT_DIR)/scripts/ios-ar.sh)" \
	IOS_SDK="$(SIMULATOR_SDK)" \
	IOS_TARGET="$(SIMULATOR_TARGET)" \
	IOS_DEPLOYMENT_TARGET="$(IOS_DEPLOYMENT_TARGET)" \
	LEAN_RUNTIME_INCLUDE="$(abspath $(SIM_RUNTIME_BUILD_DIR))/include" \
	LEAN_STAGE0_INCLUDE="$(abspath $(LEAN_SRC_DIR))/stage0/src/include" \
	LEAN_SRC_INCLUDE="$(abspath $(LEAN_SRC_DIR))/src/include" \
	lake build $(APP_LIB_TARGET)

$(APP_BINDINGS_OBJ): $(APP_BINDINGS_SRC) $(APP_BINDINGS_HEADER) $(SDL_XCFRAMEWORK_INFO)
	mkdir -p $(APP_OBJ_DIR)
	xcrun --sdk $(SIMULATOR_SDK) clang \
	  -target $(SIMULATOR_TARGET) \
	  -isysroot $(SIMULATOR_SDK_PATH) \
	  -mios-simulator-version-min=$(IOS_DEPLOYMENT_TARGET) \
	  -I$(SIM_RUNTIME_BUILD_DIR)/include \
	  -I$(LEAN_SRC_DIR)/stage0/src/include \
	  -I$(LEAN_SRC_DIR)/src/include \
	  -F$(dir $(SDL_SIM_FRAMEWORK)) \
	  $(APP_PROJECT_CFLAGS) \
	  -c $(APP_BINDINGS_SRC) \
	  -o $(APP_BINDINGS_OBJ)

$(APP_RUNTIME_BRIDGE_OBJ): $(APP_RUNTIME_BRIDGE_SRC) $(APP_RUNTIME_BRIDGE_HEADER)
	mkdir -p $(APP_OBJ_DIR)
	xcrun --sdk $(SIMULATOR_SDK) clang \
	  -target $(SIMULATOR_TARGET) \
	  -isysroot $(SIMULATOR_SDK_PATH) \
	  -mios-simulator-version-min=$(IOS_DEPLOYMENT_TARGET) \
	  -I$(SIM_RUNTIME_BUILD_DIR)/include \
	  -I$(LEAN_SRC_DIR)/stage0/src/include \
	  -I$(LEAN_SRC_DIR)/src/include \
	  -I$(APP_NATIVE_DIR) \
	  $(APP_PROJECT_CFLAGS) \
	  -c $(APP_RUNTIME_BRIDGE_SRC) \
	  -o $(APP_RUNTIME_BRIDGE_OBJ)

$(APP_BRIDGE_OBJ): $(APP_BRIDGE_SRC) $(APP_BRIDGE_HEADER) $(APP_RUNTIME_BRIDGE_HEADER)
	mkdir -p $(APP_OBJ_DIR)
	xcrun --sdk $(SIMULATOR_SDK) clang \
	  -target $(SIMULATOR_TARGET) \
	  -isysroot $(SIMULATOR_SDK_PATH) \
	  -mios-simulator-version-min=$(IOS_DEPLOYMENT_TARGET) \
	  -I$(SIM_RUNTIME_BUILD_DIR)/include \
	  -I$(LEAN_SRC_DIR)/stage0/src/include \
	  -I$(LEAN_SRC_DIR)/src/include \
	  -I$(APP_NATIVE_DIR) \
	  $(APP_PROJECT_CFLAGS) \
	  -c $(APP_BRIDGE_SRC) \
	  -o $(APP_BRIDGE_OBJ)

$(APP_REGISTRATION_OBJ): $(APP_REGISTRATION_SRC) $(APP_REGISTRATION_HEADER) $(APP_RUNTIME_BRIDGE_HEADER)
	mkdir -p $(APP_OBJ_DIR)
	xcrun --sdk $(SIMULATOR_SDK) clang \
	  -target $(SIMULATOR_TARGET) \
	  -isysroot $(SIMULATOR_SDK_PATH) \
	  -mios-simulator-version-min=$(IOS_DEPLOYMENT_TARGET) \
	  -I$(SIM_RUNTIME_BUILD_DIR)/include \
	  -I$(LEAN_SRC_DIR)/stage0/src/include \
	  -I$(LEAN_SRC_DIR)/src/include \
	  -I$(APP_NATIVE_DIR) \
	  $(APP_PROJECT_CFLAGS) \
	  -c $(APP_REGISTRATION_SRC) \
	  -o $(APP_REGISTRATION_OBJ)

$(APP_MAIN_OBJ): $(APP_MAIN_SRC) $(SDL_XCFRAMEWORK_INFO) $(APP_REGISTRATION_HEADER)
	mkdir -p $(APP_OBJ_DIR)
	xcrun --sdk $(SIMULATOR_SDK) clang \
	  -target $(SIMULATOR_TARGET) \
	  -isysroot $(SIMULATOR_SDK_PATH) \
	  -mios-simulator-version-min=$(IOS_DEPLOYMENT_TARGET) \
	  -I$(SIM_RUNTIME_BUILD_DIR)/include \
	  -I$(LEAN_SRC_DIR)/stage0/src/include \
	  -I$(LEAN_SRC_DIR)/src/include \
	  -I$(APP_NATIVE_DIR) \
	  -F$(dir $(SDL_SIM_FRAMEWORK)) \
	  $(APP_PROJECT_CFLAGS) \
	  -c $(APP_MAIN_SRC) \
	  -o $(APP_MAIN_OBJ)

$(APP_SDL_FRAMEWORK): $(SDL_XCFRAMEWORK_INFO)
	mkdir -p $(APP_FRAMEWORKS_DIR)
	rm -rf $(APP_SDL_FRAMEWORK)
	cp -R $(SDL_SIM_FRAMEWORK) $(APP_SDL_FRAMEWORK)

$(APP_BIN): app-lib $(SDL_XCFRAMEWORK_INFO) $(APP_BINDINGS_OBJ) $(APP_RUNTIME_BRIDGE_OBJ) $(APP_BRIDGE_OBJ) $(APP_REGISTRATION_OBJ) $(APP_MAIN_OBJ)
	mkdir -p $(APP_DIR)
	APP_LIB_PATH="$$(lake query $(APP_LIB_TARGET))"; \
	xcrun --sdk $(SIMULATOR_SDK) clang++ \
	  -target $(SIMULATOR_TARGET) \
	  -isysroot $(SIMULATOR_SDK_PATH) \
	  -mios-simulator-version-min=$(IOS_DEPLOYMENT_TARGET) \
	  -F$(dir $(SDL_SIM_FRAMEWORK)) \
	  $(APP_MAIN_OBJ) \
	  "$$APP_LIB_PATH" \
	  $(APP_BINDINGS_OBJ) \
	  $(APP_RUNTIME_BRIDGE_OBJ) \
	  $(APP_BRIDGE_OBJ) \
	  $(APP_REGISTRATION_OBJ) \
	  $(SIM_STDLIB_INIT_LIB) \
	  $(SIM_RUNTIME_LIB) \
	  -framework SDL3 \
	  -framework UIKit \
	  -framework Foundation \
	  -Xlinker -rpath -Xlinker @executable_path/Frameworks \
	  -o $(APP_BIN)

$(APP_INFO_PLIST): $(APP_INFO_PLIST_SRC)
	mkdir -p $(APP_DIR)
	cp $(APP_INFO_PLIST_SRC) $(APP_INFO_PLIST)

$(APP_LAUNCH_STORYBOARD_DEST): $(APP_LAUNCH_STORYBOARD_SRC)
	mkdir -p $(APP_DIR)
	cp $(APP_LAUNCH_STORYBOARD_SRC) $(APP_LAUNCH_STORYBOARD_DEST)

sim-app: $(APP_BIN) $(APP_INFO_PLIST) $(APP_LAUNCH_STORYBOARD_DEST) $(APP_SDL_FRAMEWORK)

run-sim-app: sim-app
	if ! xcrun simctl list devices booted | grep -q "Booted"; then \
	  xcrun simctl boot "$(SIMULATOR_DEVICE)" >/dev/null 2>&1 || true; \
	  open -a Simulator; \
	  xcrun simctl bootstatus "$(SIMULATOR_DEVICE)" -b; \
	fi
	xcrun simctl install booted $(APP_DIR)
	xcrun simctl launch booted $(SDL_APP_BUNDLE_ID)

clean:
	rm -rf $(APP_BUILD_DIR) $(SDL_BUILD_DIR)
