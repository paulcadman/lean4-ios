.DEFAULT_GOAL := all

LEAN_SRC_DIR := lean4
LEAN_PREFIX := $(shell lean --print-prefix)
IOS_SDK ?= iphonesimulator
IOS_DEPLOYMENT_TARGET ?= 16.0
IOS_TARGET ?= arm64-apple-ios$(IOS_DEPLOYMENT_TARGET)-simulator
SDK_TAG := $(subst -,_,$(subst .,_,$(IOS_TARGET)))

BUILD_DIR := build
LEAN_RUNTIME_BUILD_DIR := $(BUILD_DIR)/lean4-$(SDK_TAG)-runtime
IOS_BUILD_DIR := $(BUILD_DIR)/ios-lean-$(SDK_TAG)
LIB_DIR := $(IOS_BUILD_DIR)/lib

RUNTIME_LIB := $(LEAN_RUNTIME_BUILD_DIR)/lib/lean/libleanrt.a
STAGE0_STDLIB_DIR := $(LEAN_SRC_DIR)/stage0/stdlib
STDLIB_INIT_LIB_LEANMAKE := $(LIB_DIR)/libInit.a
STDLIB_STD_LIB_LEANMAKE := $(LIB_DIR)/libStd.a
STDLIB_LEAN_LIB_LEANMAKE := $(LIB_DIR)/libLean.a

AR := xcrun --sdk $(IOS_SDK) ar
IOS_LEANC := $(abspath scripts/ios-leanc.sh)
RUNTIME_CONFIG_STAMP := $(LEAN_RUNTIME_BUILD_DIR)/CMakeCache.txt

.PHONY: all runtime stdlib-init stdlib-std stdlib-lean clean

all: runtime stdlib-init stdlib-std stdlib-lean

runtime: $(RUNTIME_CONFIG_STAMP)
	cmake --build $(LEAN_RUNTIME_BUILD_DIR) --target leanrt -j4

stdlib-init: $(STDLIB_INIT_LIB_LEANMAKE)

stdlib-std: $(STDLIB_STD_LIB_LEANMAKE)

stdlib-lean: $(STDLIB_LEAN_LIB_LEANMAKE)

$(RUNTIME_CONFIG_STAMP): $(LEAN_SRC_DIR)/src/CMakeLists.txt $(LEAN_SRC_DIR)/src/runtime/CMakeLists.txt $(LEAN_SRC_DIR)/src/config.h.in $(LEAN_SRC_DIR)/CMakeLists.txt Makefile
	cmake -S $(LEAN_SRC_DIR)/src -B $(LEAN_RUNTIME_BUILD_DIR) -G "Unix Makefiles" \
		-DSTAGE=0 \
		-DCMAKE_SYSTEM_NAME=iOS \
		-DCMAKE_OSX_SYSROOT=$(IOS_SDK) \
		-DCMAKE_OSX_ARCHITECTURES=arm64 \
		-DCMAKE_OSX_DEPLOYMENT_TARGET=$(IOS_DEPLOYMENT_TARGET) \
		-DCMAKE_BUILD_TYPE=Release \
		-DUSE_MIMALLOC=OFF \
		-DUSE_LIBUV=OFF \
		-DUSE_GMP=OFF

$(STDLIB_INIT_LIB_LEANMAKE): runtime $(IOS_LEANC)
	mkdir -p $(LIB_DIR)
	cd $(STAGE0_STDLIB_DIR) && \
	IOS_SDK="$(IOS_SDK)" \
	IOS_TARGET="$(IOS_TARGET)" \
	IOS_DEPLOYMENT_TARGET="$(IOS_DEPLOYMENT_TARGET)" \
	LEAN_RUNTIME_INCLUDE="$(abspath $(LEAN_RUNTIME_BUILD_DIR))/include" \
	LEAN_STAGE0_INCLUDE="$(abspath $(LEAN_SRC_DIR))/stage0/src/include" \
	LEAN_SRC_INCLUDE="$(abspath $(LEAN_SRC_DIR))/src/include" \
	$(LEAN_PREFIX)/bin/leanmake \
	  lib \
		-j8 \
	  LEANC="$(IOS_LEANC)" \
	  LEAN_AR="$(AR)" \
	  PKG=Init \
	  C_ONLY=1 \
	  C_OUT=. \
	  OUT="$(abspath $(IOS_BUILD_DIR))/leanmake" \
	  TEMP_OUT="$(abspath $(IOS_BUILD_DIR))/leanmake/temp" \
	  LIB_OUT="$(abspath $(LIB_DIR))"

$(STDLIB_STD_LIB_LEANMAKE): $(STDLIB_INIT_LIB_LEANMAKE)
	mkdir -p $(LIB_DIR)
	cd $(STAGE0_STDLIB_DIR) && \
	IOS_SDK="$(IOS_SDK)" \
	IOS_TARGET="$(IOS_TARGET)" \
	IOS_DEPLOYMENT_TARGET="$(IOS_DEPLOYMENT_TARGET)" \
	LEAN_RUNTIME_INCLUDE="$(abspath $(LEAN_RUNTIME_BUILD_DIR))/include" \
	LEAN_STAGE0_INCLUDE="$(abspath $(LEAN_SRC_DIR))/stage0/src/include" \
	LEAN_SRC_INCLUDE="$(abspath $(LEAN_SRC_DIR))/src/include" \
	$(LEAN_PREFIX)/bin/leanmake \
	  lib \
		-j8 \
	  LEANC="$(IOS_LEANC)" \
	  LEAN_AR="$(AR)" \
	  PKG=Std \
	  C_ONLY=1 \
	  C_OUT=. \
	  OUT="$(abspath $(IOS_BUILD_DIR))/leanmake" \
	  TEMP_OUT="$(abspath $(IOS_BUILD_DIR))/leanmake/temp" \
	  LIB_OUT="$(abspath $(LIB_DIR))"

$(STDLIB_LEAN_LIB_LEANMAKE): $(STDLIB_STD_LIB_LEANMAKE)
	mkdir -p $(LIB_DIR)
	cd $(STAGE0_STDLIB_DIR) && \
	IOS_SDK="$(IOS_SDK)" \
	IOS_TARGET="$(IOS_TARGET)" \
	IOS_DEPLOYMENT_TARGET="$(IOS_DEPLOYMENT_TARGET)" \
	LEAN_RUNTIME_INCLUDE="$(abspath $(LEAN_RUNTIME_BUILD_DIR))/include" \
	LEAN_STAGE0_INCLUDE="$(abspath $(LEAN_SRC_DIR))/stage0/src/include" \
	LEAN_SRC_INCLUDE="$(abspath $(LEAN_SRC_DIR))/src/include" \
	$(LEAN_PREFIX)/bin/leanmake \
	  lib \
		-j8 \
	  LEANC="$(IOS_LEANC)" \
	  LEAN_AR="$(AR)" \
	  PKG=Lean \
	  C_ONLY=1 \
	  C_OUT=. \
	  OUT="$(abspath $(IOS_BUILD_DIR))/leanmake" \
	  TEMP_OUT="$(abspath $(IOS_BUILD_DIR))/leanmake/temp" \
	  LIB_OUT="$(abspath $(LIB_DIR))"

clean:
	rm -rf $(BUILD_DIR)
