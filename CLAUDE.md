# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this package is

AbstractPlutoDingetjes.jl is a **dependency-free interface package**. It contains *no functional implementation* — every public name here is either:

1. A fallback method (e.g. `Bonds.initial_value(::Any) = missing`) that widget authors overload, or
2. A "marker" object whose `Base.show` reads a function out of the rendering `IOContext` and calls it (e.g. `_PublishToJS`, `_JSLink`, `_AutoIDGiver`).

The actual behavior lives in **Pluto's `PlutoRunner`** (in `Pluto.jl/src/runner/PlutoRunner/`). PlutoRunner sets up an `IOContext` (`default_iocontext` in `display/IOContext.jl`) with callback functions keyed by `:pluto_<thing>` symbols, and APD's show methods pull those out via `get(io, :pluto_<thing>, fallback)`.

This split exists so widget packages (PlutoUI, etc.) can depend on tiny APD instead of all of Pluto — and so APD has near-zero load cost.

## The contract with Pluto

APD ↔ PlutoRunner is coupled via three mechanisms — every new feature uses exactly these:

### 1. IOContext keys

PlutoRunner attaches a callback/value to the `IOContext`; APD's show method reads it back. Current keys:

| APD reads | PlutoRunner sets in `default_iocontext` |
| --- | --- |
| `:pluto_published_to_js` | `(io, x) -> core_published_to_js(io, x)` |
| `:pluto_with_js_link` | `(io, callback, on_cancellation) -> core_with_js_link(...)` |
| `:pluto_auto_id!` | `auto_id!` (function `IO -> String`) |
| `:pluto_supported_integration_features` | `supported_integration_features::Vector{Any}` |
| `:is_pluto` | `true` |

The pattern in APD: `get(io, :pluto_<thing>, _fallback)`. The fallback should produce a sensible no-op or stand-in so the feature degrades gracefully outside Pluto.

### 2. Feature advertisement

`PlutoRunner/src/integrations.jl` has an `Integration` block keyed on `AbstractPlutoDingetjes`'s `PkgId`. When APD is loaded inside a notebook, that block runs and calls `supported!(x...)` to append things to `supported_integration_features`. Users (or APD itself) then check support via:

```julia
AbstractPlutoDingetjes.is_supported_by_display(io, AbstractPlutoDingetjes.Display.published_to_js)
```

This reads `:pluto_supported_integration_features` from `io` and checks membership. **Always feature-check inside `isdefined(AbstractPlutoDingetjes.Display, :the_thing)` on the PlutoRunner side** so older APD versions don't crash the integration load — see existing examples in `integrations.jl`.

For **functions**, pass the function itself: `supported!(AbstractPlutoDingetjes.Display.published_to_js)`. For **macros**, use `getfield(M, Symbol("@name"))` because macros aren't accessible by bare name.

### 3. Overloadable fallback methods (Bonds)

For `Bonds.initial_value`, `transform_value`, `possible_values`, `validate_value`: APD defines a fallback that does the safe default (`missing`, identity, `NotGiven()`, `false`). Widget authors overload these for their own widget type. PlutoRunner calls them via `initial_value_getter_ref[]`, `transform_value_ref[]`, etc. — refs that get pointed at the APD functions when APD loads.

## Layout

- `src/AbstractPlutoDingetjes.jl` — `is_inside_pluto`, `is_supported_by_display`, the `_loaded_ref` init guard, top-level docstring.
- `src/Bonds.jl` — `@bind`-side hooks (the overloadable methods above).
- `src/Display.jl` — `published_to_js`, `with_js_link`, `@auto_id`. All follow the "marker struct + `Base.show` reads IOContext" pattern.

`Project.toml` declares **no runtime dependencies** beyond stdlibs. Keep it that way — every dep here becomes a transitive dep of every widget package.

## When adding a new feature

Roughly the steps, in order:

1. **In APD**: define a marker struct (or function) and a `Base.show` that reads from `io` via a `:pluto_<name>` key, with a sensible fallback. Add a docstring with a `!!! compat "Pluto x.y.z"` block (filled in once the Pluto release lands). Write usage examples that mirror existing ones (HypertextLiteral interpolation in a `Base.show` method).
2. **In PlutoRunner** (`src/runner/PlutoRunner/`):
   - Add the implementation (often a new file in `src/display/` or `src/js/`) and `include` it from `PlutoRunner.jl`.
   - Register the callback/value in `default_iocontext` (`display/IOContext.jl`).
   - Add an `isdefined(...) && supported!(...)` line to the AbstractPlutoDingetjes integration in `integrations.jl`.
3. **Bump `MY_VERSION`** in `Project.toml` (the constant `MY_VERSION = pkgversion(@__MODULE__)` in `AbstractPlutoDingetjes.jl` reads from it). The integration code in PlutoRunner asserts `v"1.0.0" <= AbstractPlutoDingetjes.MY_VERSION < v"2.0.0"` — breaking changes in APD's runtime contract require coordination with that bound.

## Gotchas

- **APD must remain functional outside Pluto.** Show methods can `@assert` that a callback exists and produce a clear error message (see the `_PublishToJS` show method) — but the *fallback* path (e.g. `_fallback_auto_id!`) must produce something usable so a widget that calls `@auto_id()` in plain HTML rendering doesn't crash.
- **`is_supported_by_display` / `is_inside_pluto` cannot be called at top level** of a package — they guard themselves via `_loaded_ref`. Always call them inside a function (typically a `Base.show` method) that has access to `io`.
- **Don't add deps to `Project.toml`.** If you need a utility, inline it.
- **`MY_VERSION < v"2.0.0"` is a hard bound** enforced by PlutoRunner — bumping to 2.x requires changing the assertion in `Pluto.jl/src/runner/PlutoRunner/src/integrations.jl` and is a coordinated breaking change.
- The companion Pluto repo on this machine is at `/Users/fons/Documents/Pluto.jl`. When making cross-repo changes, edit both checkouts in lockstep.

## Testing

No automated test suite — feature validation happens by running widgets against a development Pluto. The typical flow:

```julia
# in Pluto, in a notebook:
import Pkg; Pkg.develop(path="/Users/fons/Documents/AbstractPlutoDingetjes.jl")
```

Then exercise the feature in a cell. The "ground truth" simulation of how PlutoRunner formats output (the `script_id_counter` stack behavior, container nesting, etc.) is prototyped in [`give_me_script_id.jl`](https://github.com/fonsp/disorganised-mess/blob/main/give_me_script_id.jl)-style notebooks — that's where new IOContext-based features tend to be drafted before porting into PlutoRunner.
