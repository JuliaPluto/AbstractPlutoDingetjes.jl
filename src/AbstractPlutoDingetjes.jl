
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

import Pkg
project_relative_path(xs...) = normpath(joinpath(dirname(dirname(pathof(@__MODULE__))), xs...))
p = Pkg.TOML.parsefile(project_relative_path("Project.toml"))

const MY_VERSION = VersionNumber(p["version"])


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


###########################



module Display
import ..AbstractPlutoDingetjes
export published_to_js


struct _PublishToJS
    x
end
function Base.show(io::IO, ::MIME"text/javascript", ptj::_PublishToJS)
    core_published_to_js = get(io, :pluto_published_to_js, nothing)
    @assert core_published_to_js !== nothing """
    `AbstractPlutoDingetjes.Display.published_to_js` is not supported by this `IO` display.

    If you are not using `published_to_js` (or you do not know what it is), or you are not using Pluto, then please report this error to the package that you are using.

    If you are trying to use `published_to_js` but it is not working, please make sure that:
    - Pluto is up to date.
    - The original IO context is used to render the widget.
    - If you want to support non-Pluto environments, you use `AbstractPlutoDingetjes.is_supported_by_display` for a fallback.
    
    See the documentation for `published_to_js` to learn more about these points.
    """

    core_published_to_js(io, ptj.x)
end
Base.show(io::IO, ::MIME"text/plain", ptj::_PublishToJS) = show(io, MIME"text/javascript"(), ptj)
Base.show(io::IO, ptj::_PublishToJS) = show(io, MIME"text/javascript"(), ptj)

"""
```julia
AbstractPlutoDingetjes.Display.published_to_js(x)
```

Make the object `x` available to the JS runtime of this cell, to be rendered
inside a `<script>` element. This system uses Pluto's optimized data transfer (probably with MsgPack and WebSocket),
which is much more efficient for large amounts of data, including lossless
transfer for `Vector{UInt8}` and `Vector{Float64}` (see the table below),
and a global cache to avoid transmitting the same object twice.

The function `published_to_js` returns a special object that behaves like a
piece of JavaScript code. We recommend using HypertextLiteral.jl to 
interpolate the result into a  `<script>` element.

# Example
```julia
import HypertextLiteral: @htl
import AbstractPlutoDingetjes.Display: published_to_js

let
    x = Dict(
        "data" => rand(Float64, 20),
        "name" => "juliette",
    )

    @htl("\""
    <script>
    // we interpolate into JavaScript:
    const x = \$(published_to_js(x))

    console.log(x.name, x.data)
    </script>
    "\"")
end
```

# Types

| Julia | JavaScript |
|:---------- |:---------- |
| `String`, `Symbol` | `string` |
| `Boolean` | `boolean` |
| `Int64`, `Int32`, `Int16`, `Int8`, `UInt64`, `UInt32`, `UInt16`, `UInt8`, `Float32`, `Float64` | `Number` |
| `Nothing`, `Missing` | `null` |
| `DateTime` | [`Date`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date) |
| `UUID`, `MIME` | `string` |
| --- | --- |
| `Dict` | `object` |
| `NamedTuple` | `object` |
| `Vector` | `Array` |
| `Tuple` | `Array` |
| `Vector{Int8}` | [`Int8Array`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Int8Array) |
| `Vector{UInt8}` | [`Uint8Array`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Uint8Array) |
| `Vector{Int16}` | [`Int16Array`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Int16Array) |
| `Vector{UInt16}` | [`Uint16Array`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Uint16Array) |
| `Vector{Int32}` | [`Int32Array`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Int32Array) |
| `Vector{UInt32}` | [`Uint32Array`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Uint32Array) |
| `Vector{Float32}` | [`Float32Array`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Float32Array) |
| `Vector{Float64}` | [`Float64Array`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Float64Array) |


# Note about IO context

The object that `published_to_js` returns needs to be rendered using the IO
context that Pluto uses to render cell output. If you are using
HypertextLiteral.jl, then this is easy to achieve. 

The example above is using `HypertextLiteral.@htl`, and the cell returns a
`HypertextLiteral` object, which will be rendered by Pluto. This means that
Pluto will render it using its magical IO context, and all is good!

## Custom show method

Below is a second example, to use when your are writing a **custom HTML show
method for your own type**:

```julia
struct MyType
    data
end

function Base.show(io::IO, m::MIME"text/html", x::MyType)

    # ✅ This works
    show(io, m, @htl("\""
    <script>
    let data = \$(published_to_js(x.data))
    console.log(data)
    </script>
    "\""))
end
```

Test it out with:

```julia
MyType([1,2,3])
```

The trick that makes it work is: `show(io, m, @htl(...))`. This will take your
`HypertextLiteral` object, and **render it using the `io` object that was passed
in**.

## Without HypertextLiteral.jl

The following would not work:

```julia
function Base.show(io::IO, m::MIME"text/html", x::MyType)

    # 🛑 This does not work
    println(io, "\""
    <script>
    let data = \$(published_to_js(x.data))
    console.log(data)
    </script>
    "\"")
end
```

This does not work, because the **string interpolation (i.e. `"\"" ...
\$(published_to_js(x.data)) ... "\""`) happens on its own**, without the `io`
context used to render it.

The solution is to use HypertextLiteral.jl, passing through the `io` in your
show method. If you can't use HypertextLiteral.jl, you could use `repr` to
manually render published object to a string, using `io` as the context:

```julia
function Base.show(io::IO, m::MIME"text/html", x::MyType)
    
    # 🟡 This works, but we recommend the HypertextLiteral.jl example instead.
    rendered = repr(published_to_js(x.data); context=io)

    println(io, "\""
    <script>
    let data = \$(rendered)
    console.log(data)
    </script>
    "\"")
end
```

# Note on published object caching

Whenever a Julia object is sent to Pluto using `published_to_js`, its value is
cached so that subsequent requests for the same object are served faster. This
means that Pluto already optimizes the performance of sending data from Julia to
Javascript and it is especially useful when the same object is rendered multiple
times within the notebook.

Also: If you use `published_to_js` twice on the same object within the
same cell, or in two different cells, the data is only transmitted once. The
second `published_to_js` just contains a reference to the same data.

It is important to note that mutating an object that has already been sent to
JavaScript with `published_to_js` will not change the value of this object on
the JavaScript side, even if the cells with the `published_to_js` calls are
re-run.


# Compatibility

## Old Pluto versions

!!! compat "Pluto 0.19.28"
    This feature only works in Pluto version 0.19.28 (July 2023) or above.

    Older versions of Pluto used `PlutoRunner.publish_to_js` for this (to avoid the need for the AbstractPlutoDingetjes package, but we changed our minds 💕).

    Use [`AbstractPlutoDingetjes.is_supported_by_display`](@ref) if you want to check support inside your widget:
    
    ```julia
    AbstractPlutoDingetjes.is_supported_by_display(io, published_to_js) ? 
        AbstractPlutoDingetjes.Display.published_to_js(x) : 
        PlutoRunner.publish_to_js(x)
    ```
    
    (You need a reference to `io` for this, so this is useful inside a custom `Base.show` method for your own struct type.)

## Outside of Pluto

This feature only works in Pluto-compatible environments (i.e. Pluto). Outside of Pluto, you might be happy with the default HypertextLiteral [script interpolation](https://juliapluto.github.io/HypertextLiteral.jl/stable/script/). This is less performant for large objects, and some Julia types are mapped to a different JavaScript type (e.g. `Vector{Int32}` is mapped to a simple `Array` instead of `Int32Array`), but it might be good enough for your use case.

In your interpolation, check for support, and otherwise, just interpolate the object directly:

```julia
AbstractPlutoDingetjes.is_supported_by_display(io, published_to_js) ? 
    AbstractPlutoDingetjes.Display.published_to_js(x) : 
    x
```

## Both

To support old versions of Pluto, and also support non-Pluto displays, you can combine the two:

```julia
AbstractPlutoDingetjes.is_supported_by_display(io, published_to_js) ? 
    # modern Pluto
    AbstractPlutoDingetjes.Display.published_to_js(x) : 
    isdefined(Main, :PlutoRunner) && isdefined(Main.PlutoRunner, :publish_to_js) ?
    # old Pluto
    PlutoRunner.publish_to_js(x) :
    # not Pluto
    x
```


"""
published_to_js(x) = _PublishToJS(x)






struct _JSLink
    callback
    on_cancellation
end
function Base.show(io::IO, ::MIME"text/javascript", wjl::_JSLink)
    core_with_js_link = get(io, :pluto_with_js_link, nothing)
    @assert core_with_js_link !== nothing """
    `AbstractPlutoDingetjes.Display.with_js_link` is not supported by this `IO` display.

    If you are not using `with_js_link` (or you do not know what it is), or you are not using Pluto, then please report this error to the package that you are using.

    If you are trying to use `with_js_link` but it is not working, please make sure that:
    - Pluto is up to date.
    - The original IO context is used to render the widget.
    - If you want to support non-Pluto environments, you use `AbstractPlutoDingetjes.is_supported_by_display` for a fallback.
    
    See the documentation for `with_js_link` to learn more about these points.
    """

    core_with_js_link(io, wjl.callback, wjl.on_cancellation)
end
Base.show(io::IO, ::MIME"text/plain", wjl::_JSLink) = show(io, MIME"text/javascript"(), wjl)
Base.show(io::IO, wjl::_JSLink) = show(io, MIME"text/javascript"(), wjl)

"""
```julia
with_js_link(f::Function[, on_cancellation::Function])
```

Make a Julia function available to the JS runtime of this cell, to be called from JavaScript. This API allows for more advanced use cases than `published_to_js`, but is also more difficult to use.

# Example
The easiest way to use this API is with HypertextLiteral. Here is a simple example:

```julia
@htl("\""
<script>
const sqrt_from_julia = \$(AbstractPlutoDingetjes.Display.with_js_link(sqrt))

// I can now call sqrt_from_julia like a JavaScript function. It returns a Promise:
const result = await sqrt_from_julia(9.0)
console.log(result)

</script>
"\"")
```

# API
The use is very similar to `Display.published_to_js`. `with_js_link` returns a "piece of JavaScript code" that you interpolate directly into a `<script>` tag. 

In JavaScript, the "piece of JavaScript code" returns a function. You can call this function with an argument (which will be passed to your Julia function), and it returns a [`Promise`](https://javascript.info/promise-basics) that resolves to the answer from your Julia function.

# Serialization and inner workings
The request and response use the same communication protocol as `published_to_js`, so in particular, `Vector{Float64}` or `Vector{UInt8}` are really fast. 

# When not to use it
This API is only meant to support **use cases that can not be covered with `Display.published_to_js`** (or `@bind`). If possible, the use of these APIs is preferred over `with_js_link`: they will work with the Static HTML export and PlutoSliderServer.

## `published_to_js` vs `with_js_link`
If the set of possible inputs is quite small, consider precomputing all possible outputs, and using `published_to_js` to publish everything at once. 

For example, in the `sqrt` example above, if you know that the input will be an integer between 1 and 1 million, then we recommend using `publish_to_js(sqrt.(1:1_000_000))` instead.

## `@bind` vs `with_js_link`
We recommend using `@bind` instead of `with_js_link` when your widget also makes sense split into two: an input widget (with `@bind`) and an output widget (possibly with `published_to_js`). This will be easier for you to develop, and easier for others to understand. If you are still considering how to design your widget, try to start with `@bind`. But if `with_js_link` is exactly what you are looking for, go for it!

For example, you are showing a map of the world, and you want to show a weather forecast for the location where the user clicks. With `with_js_link`, you could make an awesome GUI where the forecast is shown as an overlay on the map. But a simpler option would be to have one widget where you pick a location on the map, which gets bound to a Julia variable `location`. Then other cells in the notebook can compute the forecast, which you show in the cell directly above or below the map.

# Background task
JS link calculations are executed as a background task (not a thread). They can run in parallel with other computations in the notebook.


!!! warning "Don't make too many requests!"
	If you make too many requests from JS, then the notebook can become almost unusable. As a developer using this API, you need to take care to keep your users' notebooks responsive.

	The JS link request returns a `Promise` that resolves to the response. Consider keeping track of whether you are currently requesting something from Julia, and avoid making more requests in the meantime.

	It can also help to use [**throttling**](https://lodash.com/docs#throttle) or [**debouncing**](https://lodash.com/docs#debounce) to reduce the number of requests that you make.
    
    For example, starting requests at a regular interval can lead to big trouble. Instead, wait for the last request to finish, set a delay, and then make the next request.

# Advanced topics

## Multiple clients
Since this API is designed for one-off requests, this communication does not go through Pluto's state management (the request and response are not stored in the state). If multiple clients are connected in parallel, then the messages are not shared between clients. The client that made the request will receive the response.

## Cancellation
For advanced use cases, you can also provide a second argument to `with_js_link` – a function that will be called when the link is cancelled. This can be useful to clean up resources or to cancel a long-running process.

Cancellation happens **not** when the browser disconnects, but right before the cell or one of its dependency cells re-evaluates. This is done to prevent using data defined in the notebook that is no longer well-defined.

If your function is long-running, does async I/O work or runs threaded, then it is possible that your link gets cancelled during an execution. Use the `on_cancellation` callback wisely!

## Bidirectional communication
The primary purpose of this API is for JavaScript to ask a question to Julia, and receive an answer. So there is communication is both directions, but it needs to be initiated from JavaScript.

If you need to send *unrequested* updates from Julia to JavaScript, then you could use polling. [Long polling](https://javascript.info/long-polling) works well with this API, but you need to use the `on_cancellation` callback to clean up resources. Remember that Pluto notebooks can be viewed by multiple clients connected in parallel. [Here](https://github.com/fonsp/disorganised-mess/blob/main/APD%20with_js_link%20bidirectional%203.jl) is an example.

!!! compat "Pluto 0.19.41"
    This feature only works in Pluto version 0.19.41 or above.

    Use [`AbstractPlutoDingetjes.is_supported_by_display`](@ref) if you want to check support inside your widget.

"""
with_js_link(f::Function, on_cancellation=nothing) = _JSLink(f, on_cancellation)

# note: if we want to add a kwarg to this function later, we need a way for users to check support. The solution:

# const with_js_link_kwarg_blablabla_support = Ref(nothing)

# then PlutoRunner will "add support" for `with_js_link_kwarg_blablabla_support`, and users can then use it as a proxy to check support for the kwarg:

# APD.is_supported_by_display(io, with_js_link_kwarg_blablabla_support)



end

end
