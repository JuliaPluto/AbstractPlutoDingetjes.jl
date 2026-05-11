

Base.show(io::IO, ::MIME"application/vnd.pluto.reactdomelement+object", e::MyType)
    # dont write to io!
    # NO:
    write(io, ...)
    
    return AbstractPlutoDingetjes.Display.ReactDOMElement(;
        tag = "div",
        attributes = Dict(
            "style" => "display: flex; width: 100px; height: 100px; background-color: red;",
            "class" => "awesome",
            "id" => "something",
            "data-xoxox" => "yeS",
        ),
        children = [
            AbstractPlutoDingetjes.Display.ReactDOMElement(;
                tag = "div",
                attributes = Dict("style" => "display: flex; width: 100px; height: 100px; background-color: blue;"),
                children = [
                    html"<p>asdf</p>"
                ]
            ),
        ],
    )
end



Base.show(io::IO, ::MIME"text/html", e::MyType) = write(io, "fallback content")