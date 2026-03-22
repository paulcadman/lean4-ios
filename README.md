## lean4-ios

This repository contains a modified Lean4 source tree with changes to let the
Lean runtime and stage0 standard library be built with the iOS toolchain and
linked into iOS apps.

It also includes:

### A SDL iOS app 

This app demonstrates a Lean program that uses SDL to make an SDL app with animated 2D graphics.

```
make -C example-sdl-app run-sim-app
```

This is the SDL app running in an iOS simulator:

https://github.com/user-attachments/assets/aa9b99ea-b496-4393-a35a-fe3d0679409e

## A minimal example iOS app

This app demonstrates how a Lean function can be called from an iOS app.

```
make -C example-app sim-app
```

This is what the example app looks like:

![Screenshot of the simulator running the example app](assets/hello-lean.png)

The build works as follows:

1. [example-app/lean/Example.lean](example-app/lean/Example.lean) is compiled to C.
2. The generated C is compiled for the iOS target.
3. [example-app/native/LeanIOSBridge.cpp](example-app/native/LeanIOSBridge.cpp)
   initializes the Lean module and exposes a small C interface.
4. [example-app/native/App/main.swift](example-app/native/App/main.swift) calls
   that bridge from a native iOS app.
5. The app is linked against the compiled Lean object, the iOS-built stage0
   `libInit.a` and `libleanrt.a`.
   
## Useful Makefile targets:

- `make runtime` - builds the Lean4 runtime for iOS
- `make stdlib-init` - builds the Lean4 stage0 standard library for iOS
- `make -C example-app sim-app` - builds example-app for iOS simulator
- `make -C example-app run-sim-app` - starts a simulator, deploys / runs the iOS example app
- `make -C example-sdl-app sim-app` - build the example-sdl-app for iOS simulator 
- `make -C example-sdl-app run-sim-app` - starts a simulator, deploys / runs the iOS example SDL app
