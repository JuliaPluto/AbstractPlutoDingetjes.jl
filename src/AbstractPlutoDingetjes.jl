
"""
A more technical package meant for people who develop widgets for other Pluto users. By using and implementing methods from this package, you can give your widget more advanced features.

This package is very small, and contains no functional code (all functionality is implemented by Pluto). This means that you can add AbstractPlutoDingetjes.jl as a dependency to your package with almost no overhead!

## Common use
Most functions in AbstractPlutoDingetjes are most useful when used with the `type`–`show`–`@htl` recipe. A basic example:

```julia
import HypertextLiteral: @htl

struct MyCoolSlider
    min::Real
    max::Real
end

function Base.show(io::IO, m::MIME"text/html", d::MyCoolSlider)
    show(io, m, @htl(
        ""\"
        <input type=range min=\$(d.min) max=\$(d.max)>
        ""\"
    ))
end

# Use:
@bind value MyCoolSlider(5, 10)
```

This example **does not use** AbstractPlutoDingetjes, but AbstractPlutoDingetjes can be used to gradually enhance this widget.
"""
module AbstractPlutoDingetjes

export Bonds, is_inside_pluto, is_supported_by_display


include_dependency("../Project.toml")
const MY_VERSION = pkgversion(@__MODULE__)


const _loaded_ref = Ref(false)
function __init__()
    _loaded_ref[] = true
end


"""
```julia
is_supported_by_display(io::IO, f::Union{Function,Module})::Bool
```

Check whether the current runtime/display (Pluto) supports a given feature from `AbstractPlutoDingetjes` (i.e. is the Pluto version new enough). This function should be used inside a `Base.show` method. The first argument should be the `io` provided to the `Base.show` method, and the second argument is the feature to check.

You can use this information to:
- Error the show method of your widget if the runtime/display does not support the required features, or
- Render a simpler version of your widget that does not depend on the advanced Pluto features.

# Example
```julia
import AbstractPlutoDingetjes: is_supported_by_display, Bonds

struct MyCoolDingetje
    values::Vector
end

function Base.show(io::IO, m::MIME"text/html", d::MyCoolDingetje)
    if !(is_supported_by_display(io, Bonds.initial_value) && is_supported_by_display(io, Bonds.transform_value))
        error("This widget does not work in the current version of Pluto.")
    end

    write(io, html"...")
end

```

See also: [`is_inside_pluto`](@ref).
"""
is_supported_by_display(io::IO, x::Any) =
    if !_loaded_ref[]
        error("`is_supported_by_display` can only be called inside a function, **after** your package has been imported. You can not call the function at top-level.")
    else
        features = get(io, :pluto_supported_integration_features, [])
        x ∈ features
    end


"""
```julia
is_inside_pluto()::Bool
```

Are we running inside a Pluto notebook?
"""
is_inside_pluto()::Bool =
    if !_loaded_ref[]
        error("`is_inside_pluto` can only be called inside a function, **after** your package has been imported. You can not call the function at top-level.")
    else
        isdefined(Main, :PlutoRunner)
    end
"""
```julia
is_inside_pluto(io::IO)::Bool
```

Are we rendering inside a Pluto notebook?

This function should be used inside a `Base.show` method, and the first argument should be the `io` provided to the `Base.show` method.

# Example
```julia
function Base.show(io::IO, m::MIME"text/html", d::MyCoolWidget)
    if is_inside_pluto(io)
        Base.show(io, m, @htl("..."))
    else
        # do something else
    end
end
```
"""
is_inside_pluto(io::IO)::Bool =
    if !_loaded_ref[]
        error("`is_inside_pluto` can only be called inside a function, **after** your package has been imported. You can not call the function at top-level.")
    else
        get(io, :is_pluto, false)
    end


include("Bonds.jl")
include("Display.jl")

end
