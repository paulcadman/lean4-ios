.DEFAULT_GOAL := sim-app

ROOT_DIR := ..

LEAN_SRC_DIR := $(ROOT_DIR)/lean4
SIMULATOR_SDK ?= iphonesimulator
IOS_DEPLOYMENT_TARGET ?= 16.0
SIMULATOR_TARGET ?= arm64-apple-ios$(IOS_DEPLOYMENT_TARGET)-simulator
SIMULATOR_SDK_TAG := $(subst -,_,$(subst .,_,$(SIMULATOR_TARGET)))
SIMULATOR_DEVICE ?= iPhone 16
APP_BUNDLE_ID ?= dev.paulcadman.LeanIOSExample

BUILD_DIR := $(ROOT_DIR)/build
SIM_RUNTIME_BUILD_DIR := $(BUILD_DIR)/lean4-$(SIMULATOR_SDK_TAG)-runtime
SIM_IOS_BUILD_DIR := $(BUILD_DIR)/ios-lean-$(SIMULATOR_SDK_TAG)
SIM_RUNTIME_LIB := $(SIM_RUNTIME_BUILD_DIR)/lib/lean/libleanrt.a
SIM_STDLIB_INIT_LIB := $(SIM_IOS_BUILD_DIR)/lib/libInit.a
SIMULATOR_SDK_PATH := $(shell xcrun --sdk $(SIMULATOR_SDK) --show-sdk-path)

APP_LEAN_DIR := lean
APP_NATIVE_DIR := native
APP_BUILD_DIR := $(BUILD_DIR)/ios-sim-app
APP_OBJ_DIR := $(APP_BUILD_DIR)/obj
APP_MODULE_CACHE_DIR := $(APP_BUILD_DIR)/module-cache
APP_DIR := $(APP_BUILD_DIR)/LeanIOSExample.app
APP_BIN := $(APP_DIR)/LeanIOSExample
APP_INFO_PLIST := $(APP_DIR)/Info.plist
APP_LIB_TARGET := ExampleApp:static
APP_LAKE_BUILD_DIR := .lake/build
APP_BRIDGE_SRC := $(APP_NATIVE_DIR)/LeanIOSBridge.cpp
APP_BRIDGE_HEADER := $(APP_NATIVE_DIR)/LeanIOSBridge.h
APP_BRIDGE_OBJ := $(APP_OBJ_DIR)/LeanIOSBridge.o
APP_MAIN_SRC := $(APP_NATIVE_DIR)/App/main.swift
APP_INFO_PLIST_SRC := $(APP_NATIVE_DIR)/App/Info.plist

.PHONY: sim-runtime app-lib sim-app run-sim-app clean

sim-runtime:
	$(MAKE) -C $(ROOT_DIR) IOS_SDK="$(SIMULATOR_SDK)" IOS_TARGET="$(SIMULATOR_TARGET)" IOS_DEPLOYMENT_TARGET="$(IOS_DEPLOYMENT_TARGET)" runtime stdlib-init

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

$(APP_BRIDGE_OBJ): $(APP_BRIDGE_SRC) $(APP_BRIDGE_HEADER)
	mkdir -p $(APP_OBJ_DIR)
	xcrun --sdk $(SIMULATOR_SDK) clang++ \
	  -target $(SIMULATOR_TARGET) \
	  -isysroot $(SIMULATOR_SDK_PATH) \
	  -mios-simulator-version-min=$(IOS_DEPLOYMENT_TARGET) \
	  -I$(SIM_RUNTIME_BUILD_DIR)/include \
	  -I$(LEAN_SRC_DIR)/stage0/src/include \
	  -I$(LEAN_SRC_DIR)/src \
	  -I$(LEAN_SRC_DIR)/src/include \
	  -I$(APP_NATIVE_DIR) \
	  -c $(APP_BRIDGE_SRC) \
	  -o $(APP_BRIDGE_OBJ)

$(APP_BIN): app-lib $(APP_BRIDGE_OBJ) $(APP_MAIN_SRC)
	mkdir -p $(APP_DIR) $(APP_MODULE_CACHE_DIR)
	APP_LIB_PATH="$$(lake query $(APP_LIB_TARGET))"; \
	xcrun --sdk $(SIMULATOR_SDK) swiftc \
	  -parse-as-library \
	  -target $(SIMULATOR_TARGET) \
	  -sdk $(SIMULATOR_SDK_PATH) \
	  -module-cache-path $(APP_MODULE_CACHE_DIR) \
	  -import-objc-header $(APP_BRIDGE_HEADER) \
	  $(APP_MAIN_SRC) \
	  "$$APP_LIB_PATH" \
	  $(APP_BRIDGE_OBJ) \
	  $(SIM_STDLIB_INIT_LIB) \
	  $(SIM_RUNTIME_LIB) \
	  -framework UIKit \
	  -framework Foundation \
	  -Xlinker -lc++ \
	  -o $(APP_BIN)

$(APP_INFO_PLIST): $(APP_INFO_PLIST_SRC)
	mkdir -p $(APP_DIR)
	cp $(APP_INFO_PLIST_SRC) $(APP_INFO_PLIST)

sim-app: $(APP_BIN) $(APP_INFO_PLIST)

run-sim-app: sim-app
	if ! xcrun simctl list devices booted | grep -q "Booted"; then \
	  xcrun simctl boot "$(SIMULATOR_DEVICE)" >/dev/null 2>&1 || true; \
	  open -a Simulator; \
	  xcrun simctl bootstatus "$(SIMULATOR_DEVICE)" -b; \
	fi
	xcrun simctl install booted $(APP_DIR)
	xcrun simctl launch booted $(APP_BUNDLE_ID)

clean:
	rm -rf $(APP_BUILD_DIR) $(APP_LAKE_BUILD_DIR)
