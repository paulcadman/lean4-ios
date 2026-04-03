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
HOST_LEAN_BUILD_DIR := $(BUILD_DIR)/lean4-host-nogmp
HOST_LEAN_STAGE1_BUILD_DIR := $(HOST_LEAN_BUILD_DIR)/stage1

RUNTIME_LIB := $(LEAN_RUNTIME_BUILD_DIR)/lib/lean/libleanrt.a
STAGE0_STDLIB_DIR := $(LEAN_SRC_DIR)/stage0/stdlib
STDLIB_INIT_LIB_LEANMAKE := $(LIB_DIR)/libInit.a
STDLIB_STD_LIB_LEANMAKE := $(LIB_DIR)/libStd.a
STDLIB_LEAN_LIB_LEANMAKE := $(LIB_DIR)/libLean.a
SIM_STDLIB_OLEAN_DIR := $(HOST_LEAN_STAGE1_BUILD_DIR)/lib/lean

AR := xcrun --sdk $(IOS_SDK) ar
IOS_LEANC := $(abspath scripts/ios-leanc.sh)
RUNTIME_CONFIG_STAMP := $(LEAN_RUNTIME_BUILD_DIR)/CMakeCache.txt
HOST_CONFIG_STAMP := $(HOST_LEAN_BUILD_DIR)/Makefile
CCACHE ?=

ifneq ($(strip $(CCACHE)),)
CMAKE_CCACHE_ARGS := -DCMAKE_C_COMPILER_LAUNCHER=$(CCACHE) -DCMAKE_CXX_COMPILER_LAUNCHER=$(CCACHE)
endif

.PHONY: all runtime stdlib-init stdlib-std stdlib-lean host-lean-stdlib host-lean-stdlib-fresh host-oleans clean

all: runtime stdlib-init stdlib-std stdlib-lean

runtime: $(RUNTIME_CONFIG_STAMP)
	cmake --build $(LEAN_RUNTIME_BUILD_DIR) --target leanrt -j4

stdlib-init: $(STDLIB_INIT_LIB_LEANMAKE)

stdlib-std: $(STDLIB_STD_LIB_LEANMAKE)

stdlib-lean: $(STDLIB_LEAN_LIB_LEANMAKE)

host-oleans:
	if [ -f $(SIM_STDLIB_OLEAN_DIR)/Lean/Elab/Frontend.olean ]; then \
		exit 0; \
	fi
	$(MAKE) host-lean-stdlib
	test -f $(SIM_STDLIB_OLEAN_DIR)/Lean/Elab/Frontend.olean

host-lean-stdlib: $(HOST_CONFIG_STAMP)
	cmake --build $(HOST_LEAN_BUILD_DIR) --target stage1-configure -j4
	cmake --build $(HOST_LEAN_STAGE1_BUILD_DIR) --target make_stdlib -j4

host-lean-stdlib-fresh:
	rm -rf $(HOST_LEAN_BUILD_DIR)/stage0 $(HOST_LEAN_BUILD_DIR)/stage1
	$(MAKE) host-lean-stdlib

$(RUNTIME_CONFIG_STAMP): $(LEAN_SRC_DIR)/src/CMakeLists.txt $(LEAN_SRC_DIR)/src/runtime/CMakeLists.txt $(LEAN_SRC_DIR)/src/config.h.in $(LEAN_SRC_DIR)/CMakeLists.txt Makefile
	cmake -S $(LEAN_SRC_DIR)/src -B $(LEAN_RUNTIME_BUILD_DIR) -G "Unix Makefiles" \
		-DSTAGE=0 \
		-DCMAKE_SYSTEM_NAME=iOS \
		-DCMAKE_OSX_SYSROOT=$(IOS_SDK) \
		-DCMAKE_OSX_ARCHITECTURES=arm64 \
		-DCMAKE_OSX_DEPLOYMENT_TARGET=$(IOS_DEPLOYMENT_TARGET) \
		-DCMAKE_BUILD_TYPE=Release \
		$(CMAKE_CCACHE_ARGS) \
		-DUSE_MIMALLOC=OFF \
		-DUSE_LIBUV=OFF \
		-DUSE_GMP=OFF

$(HOST_CONFIG_STAMP): $(LEAN_SRC_DIR)/CMakeLists.txt $(LEAN_SRC_DIR)/src/CMakeLists.txt $(LEAN_SRC_DIR)/stage0/src/CMakeLists.txt $(LEAN_SRC_DIR)/src/config.h.in $(LEAN_SRC_DIR)/stage0/src/config.h.in Makefile
	cmake -S $(LEAN_SRC_DIR) -B $(HOST_LEAN_BUILD_DIR) \
		$(CMAKE_CCACHE_ARGS) \
		-DUSE_GMP=OFF \
		-DUSE_LIBUV=OFF

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
