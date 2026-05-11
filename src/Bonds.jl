module Bonds
import ..AbstractPlutoDingetjes

export initial_value, transform_value, possible_values, validate_value
export NotGiven, InfinitePossibilities

"""
The initial value of a bond. In a notebook containing `@bind x my_widget`, this will be used in two cases:
1. The value of `x` will be set to `x = AbstractPlutoDingetjes.Bonds.initial_value(my_widget)` during the `@bind` call. This initial value will be used in cells that use `x`, until the widget is rendered in the browser and the first value is received.
2. When running a notebook file without Pluto, e.g. `shell> julia my_notebook.jl`, this value will be used for `x`.

When not overloaded for your widget, it defaults to returning `missing`.

# Example
```julia
import HypertextLiteral: @htl

struct MySlider
    range::AbstractRange{<:Real}
end

function Base.show(io::IO, m::MIME"text/html", s::MySlider)
    show(io, m, @htl(
        "<input type=range min=\$(first(s.values)) step=\$(step(s.values)) max=\$(last(s.values))>"
    ))
end

function AbstractPlutoDingetjes.Bonds.initial_value(s::MySlider)
    first(s.range)
end

# Add the following for the same functionality on Pluto versions 0.17.0 and below. Will be ignored in future Pluto versions. See the compat info below.
Base.get(s::MySlider) = first(s.range)

```

!!! info "Note about `transform_value`"
    If you are also using [`transform_value`](@ref) for your widget, then the value returned by `initial_value` should be the value **after** transformation.


!!! compat "Pluto 0.17.1"
    This feature only works in Pluto version 0.17.1 or above.

    Older versions of Pluto used a `Base.get` overload for this (to avoid the need for the AbstractPlutoDingetjes package, but we changed our minds 💕). To support all versions of Pluto, use both methods of declaring the initial value.

    Use [`AbstractPlutoDingetjes.is_supported_by_display`](@ref) if you want to check support inside your widget.

"""
initial_value(bond::Any) = missing




"""
Transform a value received from the browser before assigning it to the bound julia variable. In a notebook containing `@bind x my_widget`, Pluto will run `x = AbstractPlutoDingetjes.Bonds.transform_value(my_widget, \$value_from_javascript)`. Without this hook, widgets in JavaScript can only return simple types (numbers, dictionaries, vectors) into bound variables.

When not overloaded for your widget, it defaults to returning the value unchanged, i.e. `x = \$value_from_javascript`.

# Example
```julia
import HypertextLiteral: @htl

struct MyVectorSlider
    values::Vector{<:Any} # note! a vector of arbitrary objects, not just numbers
end

function Base.show(io::IO, m::MIME"text/html", s::MyVectorSlider)
    show(io, m, @htl(
        "<input type=range min=1 max=\$(length(s.values))>"
    ))
end

AbstractPlutoDingetjes.Bonds.transform_value(s::MyVectorSlider, value_from_javascript::Int) = s.values[value_from_javascript]
```

!!! compat "Pluto 0.17.1"
    This feature only works in Pluto version 0.17.1 or above. Values are not transformed in older versions.

    Use [`AbstractPlutoDingetjes.is_supported_by_display`](@ref) if you want to check support inside your widget.

"""
transform_value(bond::Any, value_from_javascript::Any) = value_from_javascript




"`NotGiven()` is the default return value of `possible_values(::Any)`, if you have not defined an overload."
struct NotGiven end
"Return `InfinitePossibilities()` from your overload of [`possible_values`](@ref) to signify that your bond has no finite set of possible values."
struct InfinitePossibilities end


"""
The possible values of a bond. This is used when generating precomputed PlutoSliderServer states, see [https://github.com/JuliaPluto/PlutoSliderServer.jl/pull/29](https://github.com/JuliaPluto/PlutoSliderServer.jl/pull/29). Not relevant outside of this use (for now...).

The returned value should be an iterable object that you can call `length` on (like a `Vector` or a `Generator` without filter) or return [`InfinitePossibilities()`](@ref) if this set is inifinite.

# Examples
```julia
import HypertextLiteral: @htl

struct MySlider
    range::AbstractRange{<:Real}
end

function Base.show(io::IO, m::MIME"text/html", s::MySlider)
    show(io, m, @htl(
        "<input type=range min=\$(first(s.values)) step=\$(step(s.values)) max=\$(last(s.values))>"
    ))
end

AbstractPlutoDingetjes.Bonds.possible_values(s::MySlider) = s.range
```

```julia
import HypertextLiteral: @htl

struct MyTextBox end

Base.show(io::IO, m::MIME"text/html", s::MyTextBox) = show(io, m, @htl("<input type=text>"))

AbstractPlutoDingetjes.Bonds.possible_values(s::MySlider) = AbstractPlutoDingetjes.Bonds.InfinitePossibilities()
```

!!! info "Note about `transform_value`"
    If you are also using [`transform_value`](@ref) for your widget, then the values returned by `possible_values` should be the values **before** transformation.

!!! compat "Pluto 0.17.3"
    This feature only works in Pluto version 0.17.3 or above.

"""
possible_values(bond::Any) = NotGiven()


"""
Validate a value received from the browser before "doing the pluto thing". In a notebook containing `@bind x my_widget`, Pluto will run `AbstractPlutoDingetjes.Bonds.validate_value(my_widget, \$value_from_javascript)`. If the result is `false`, then the value from JavaScript is considered "invalid" or "insecure", and no further code will be executed.

This is a protection measure when using your widget on a public PlutoSliderServer, where people could write fake requests that set bonds to arbitrary values.

The returned value should be a `Boolean`.

# Example
```julia
import HypertextLiteral: @htl

struct MySlider
    range::AbstractRange{<:Real}
end

function Base.show(io::IO, m::MIME"text/html", s::MySlider)
    show(io, m, @htl(
        "<input type=range min=\$(first(s.values)) step=\$(step(s.values)) max=\$(last(s.values))>"
    ))
end

function AbstractPlutoDingetjes.Bonds.validate_value(s::MySlider, from_browser::Real)
    first(s.range) <= from_browser <= last(s.range)
end
```

!!! info "Note about `transform_value`"
    If you are also using [`transform_value`](@ref) for your widget, then the value validated by `validate_value` will be the value **before** transformation.

!!! info
    The fallback method is `validate_value(::Any, ::Any) = false`. In the example above, this means that if the value is not a `Real`, it is automatically considered invalid.

!!! compat "Pluto TODO"
    This feature only works in Pluto version TODO: NOT RELEASED YET or above.

"""
validate_value(bond::Any, input::Any) = false


end
