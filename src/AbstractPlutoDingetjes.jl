
"""
An abstract package to be implemented by packages/people who create widgets/*dingetjes* for Pluto. If you are just happy using Pluto to make cool stuff, you probably don't want to use this package directly.

Take a look at [`PlutoAbstractDingetjes.Bonds`](@ref).
"""
module AbstractPlutoDingetjes



module Bonds

"""
The initial value of a bond. In a notebook containing `@bind x my_widget`, this will be used in two cases:
1. The value of `x` will be set to `x = PlutoAbstractDingetjes.initial_value(my_widget)` during the `@bind` call. This initial value will be used in cells that use `x`, until the widget is rendered in the browser and the first value is received.
2. When running a notebook file without Pluto, e.g. `shell> julia my_notebook.jl`, this value will be used for `x`.

When not overloaded for your widget, it defaults to returning `missing`.

# Example
```julia
struct MySlider
    range::AbstractRange{<:Real}
end

Base.show(io::IO, m::MIME"text/html", s::MySlider) = show(io, m, HTML("<input type=range min=\$(first(s.values)) step=\$(step(s.values)) max=\$(last(s.values))>"))

PlutoAbstractDingetjes.Bonds.initial_value(s::MySlider) = first(s.range)

# Add the following for the same functionality on Pluto versions TODO and below. Will be ignored in newer Pluto versions. See the compat info below.
Base.get(s::MySlider) = first(s.range)

```


!!! compat "Pluto TODO"
    This feature only works in Pluto version TODO: NOT RELEASED YET or above.
    
    Older versions of Pluto used a `Base.get` overload for this (to avoid the need for the `AbstractPlutoDingetjes` package, but we changed our minds 💕). To support all versions of Pluto, use both methods of declaring the initial value.

"""
initial_value(bond::Any) = missing




"""
Transform a value received from the browser before assigning it to the bound julia variable. In a notebook containing `@bind x my_widget`, Pluto will run `x = PlutoAbstractDingetjes.Bonds.transform_value(my_widget, \$value_from_javascript)`. Without this hook, widgets in JavaScript can only return simple types (numbers, dictionaries, vectors) into bound variables.

When not overloaded for your widget, it defaults to returning the value unchanged, i.e. `x = \$value_from_javascript`.

# Example
```julia
struct MyVectorSlider
    values::Vector{<:Any} # note! a vector of arbitrary objects, not just numbers
end

Base.show(io::IO, m::MIME"text/html", s::MyVectorSlider) = show(io, m, HTML("<input type=range min=1 max=\$(length(s.values))>"))

PlutoAbstractDingetjes.Bonds.transform_value(s::MySlider, value_from_javascript::Int) = s.values[value_from_javascript]
```

!!! compat "Pluto TODO"
    This feature only works in Pluto version TODO: NOT RELEASED YET or above. Values are not transformed in older versions.

"""
transform_value(bond::Any, value_from_javascript::Any) = value_from_javascript




""
struct NotGiven end
"Return `InfinitePossibilities()` from your overload of [`possible_values`](@ref) to signify that your bond has no finite set of possible values."
struct InfinitePossibilities end


"""
The possible values of a bond. This is used when generating precomputed PlutoSliderServer states, see [https://github.com/JuliaPluto/PlutoSliderServer.jl/pull/29](https://github.com/JuliaPluto/PlutoSliderServer.jl/pull/29). Not relevant outside of this use (for now...).

The returned value should be an iterable object that you can call `length` on (like a `Vector` or a `Generator` without filter) or return [`PlutoAbstractDingetjes.Bonds.InfinitePossibilities()`](@ref) if this set is inifinite.

# Examples
```julia
struct MySlider
    range::AbstractRange{<:Real}
end

Base.show(io::IO, m::MIME"text/html", s::MySlider) = show(io, m, HTML("<input type=range min=\$(first(s.values)) step=\$(step(s.values)) max=\$(last(s.values))>"))

PlutoAbstractDingetjes.Bonds.possible_values(s::MySlider) = s.range
```

```julia
struct MyTextBox end

Base.show(io::IO, m::MIME"text/html", s::MyTextBox) = show(io, m, HTML("<input type=text>"))

PlutoAbstractDingetjes.Bonds.possible_values(s::MySlider) = PlutoAbstractDingetjes.Bonds.InfinitePossibilities()
```


!!! compat "Pluto TODO"
    This feature only works in Pluto version TODO: NOT RELEASED YET or above.

"""
possible_values(bond::Any) = NotGiven()


"""
Validate a value received from the browser before "doing the pluto thing". In a notebook containing `@bind x my_widget`, Pluto will run `PlutoAbstractDingetjes.Bonds.validate_value(my_widget, \$value_from_javascript)`. If the result is `false`, then the value from JavaScript is considered "invalid" or "insecure", and no further code will be executed.

This is a protection measure when using your widget on a public PlutoSliderServer, where people could write fake requests that set bonds to arbitrary values.

The returned value should be a `Boolean`.

# Example
```julia
struct MySlider
    range::AbstractRange{<:Real}
end

Base.show(io::IO, m::MIME"text/html", s::MySlider) = show(io, m, HTML("<input type=range min=\$(first(s.values)) step=\$(step(s.values)) max=\$(last(s.values))>"))

PlutoAbstractDingetjes.Bonds.validate_value(s::MySlider, x::Any) = x isa Real && first(s.range) <= x <= last(s.range)
```


!!! warning
    Be sure to add a dispatch for `validate_value(s::MyWidget, x::Any)`, not just for `validate_value(s::MyWidget, x::ExpectedType)`, since this would return the fallback value `true` when `x` is not of the expected type.

!!! compat "Pluto TODO"
    This feature only works in Pluto version TODO: NOT RELEASED YET or above.
        
"""
validate_value(bond::Any, input::Any) = true


end

end
