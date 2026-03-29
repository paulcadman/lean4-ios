import Lake

open Lake DSL

package example_bus_times where
  srcDir := "lean"

require sdl_bindings from ".." / "sdl-bindings"

@[default_target]
lean_lib ExampleBusTimesApp where
  roots := #[`ExampleBusTimes]
  defaultFacets := #[`static]
