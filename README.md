# AbstractPlutoDingetjes.jl

An abstract package to be implemented by packages/people who create widgets (or other [*dingetjes*](https://en.wiktionary.org/wiki/dingetjes#Dutch)) for Pluto. If you are just happy using Pluto to make cool stuff, you probably don't want to use this package directly. This package is not *necessary* to create widgets in Pluto, but it can add more advanced functionality to your widgets. See the Interactivity sample notebook inside Pluto's main menu to learn more!

![](https://media.giphy.com/media/l3vRfDn9ca5PVkHv2/giphy.gif)

## What is it

> **[FULL DOCUMENTATION HERE](https://docs.juliahub.com/AbstractPlutoDingetjes/UHbnu/)**

### `Bonds.initial_value`
The initial value of a bond. In a notebook containing `@bind x my_widget`, this will be used in two cases:
1. The value of `x` will be set to `x = AbstractPlutoDingetjes.Bonds.initial_value(my_widget)` during the `@bind` call. This initial value will be used in cells that use `x`, until the widget is rendered in the browser and the first value is received.
2. When running a notebook file without Pluto, e.g. `shell> julia my_notebook.jl`, this value will be used for `x`.

When not overloaded for your widget, it defaults to returning `missing`.

#### Example
```julia
struct MySlider
    range::AbstractRange{<:Real}
end

Base.show(io::IO, m::MIME"text/html", s::MySlider) = show(io, m, HTML("<input type=range min=$(first(s.values)) step=$(step(s.values)) max=$(last(s.values))>"))

AbstractPlutoDingetjes.Bonds.initial_value(s::MySlider) = first(s.range)

# Add the following for the same functionality on Pluto versions TODO and below. Will be ignored in newer Pluto versions. See the compat info below.
Base.get(s::MySlider) = first(s.range)

```

### `Bonds.transform_value`
Transform a value received from the browser before assigning it to the bound julia variable. In a notebook containing `@bind x my_widget`, Pluto will run `x = AbstractPlutoDingetjes.Bonds.transform_value(my_widget, \$value_from_javascript)`. Without this hook, widgets in JavaScript can only return simple types (numbers, dictionaries, vectors) into bound variables.

When not overloaded for your widget, it defaults to returning the value unchanged, i.e. `x = \$value_from_javascript`.

#### Example
```julia
struct MyVectorSlider
    values::Vector{<:Any} # note! a vector of arbitrary objects, not just numbers
end

Base.show(io::IO, m::MIME"text/html", s::MyVectorSlider) = show(io, m, HTML("<input type=range min=1 max=$(length(s.values))>"))

AbstractPlutoDingetjes.Bonds.transform_value(s::MySlider, value_from_javascript::Int) = s.values[value_from_javascript]
```

See https://github.com/JuliaPluto/PlutoUI.jl/issues/3#issuecomment-629724036


> ***For more features, see the [DOCUMENTATION](https://docs.juliahub.com/AbstractPlutoDingetjes/UHbnu/)***