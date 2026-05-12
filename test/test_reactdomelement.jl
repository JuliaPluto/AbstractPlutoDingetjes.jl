using Test
using OrderedCollections: OrderedDict
using AbstractPlutoDingetjes.Display: ReactDOMElement

render(e; ctx_pairs...) = sprint() do io
    show(IOContext(io, ctx_pairs...), MIME"text/html"(), e)
end

@testset "ReactDOMElement HTML fallback" begin
    @testset "defaults and empty" begin
        @test render(ReactDOMElement()) == "<div></div>"
        @test render(ReactDOMElement(; tag="span")) == "<span></span>"
        @test render(ReactDOMElement(; tag="svg", attributes=OrderedDict{String,Any}(), children=Any[])) == "<svg></svg>"
    end

    @testset "attributes" begin
        # Single attribute.
        @test render(ReactDOMElement(; attributes=OrderedDict("class" => "foo"))) ==
              "<div class=\"foo\"></div>"

        # Order is preserved with OrderedDict.
        @test render(ReactDOMElement(; attributes=OrderedDict("class" => "a", "id" => "b"))) ==
              "<div class=\"a\" id=\"b\"></div>"
        @test render(ReactDOMElement(; attributes=OrderedDict("id" => "b", "class" => "a"))) ==
              "<div id=\"b\" class=\"a\"></div>"

        # Non-string attribute values get stringified.
        @test render(ReactDOMElement(; attributes=OrderedDict{String,Any}("tabindex" => 3, "data-flag" => true))) ==
              "<div tabindex=\"3\" data-flag=\"true\"></div>"
    end

    @testset "key attribute is omitted" begin
        @test render(ReactDOMElement(; attributes=OrderedDict("key" => "k1", "id" => "x"))) ==
              "<div id=\"x\"></div>"
        @test render(ReactDOMElement(; attributes=OrderedDict("id" => "x", "key" => "k1"))) ==
              "<div id=\"x\"></div>"
        @test render(ReactDOMElement(; attributes=OrderedDict("key" => "only"))) == "<div></div>"
    end

    @testset "attribute value escaping" begin
        @test render(ReactDOMElement(; attributes=OrderedDict("data-x" => "a & b < c \"quoted\""))) ==
              "<div data-x=\"a &amp; b &lt; c &quot;quoted&quot;\"></div>"

        # `>` is intentionally not escaped in attribute values.
        @test render(ReactDOMElement(; attributes=OrderedDict("data-x" => "a>b"))) ==
              "<div data-x=\"a>b\"></div>"

        # The fallback uses naive sequential replace, so an existing entity
        # gets re-escaped: "&amp;" -> "&amp;amp;". Documenting this behavior.
        @test render(ReactDOMElement(; attributes=OrderedDict("data-x" => "&amp;"))) ==
              "<div data-x=\"&amp;amp;\"></div>"
    end

    @testset "children rendering" begin
        @test render(ReactDOMElement(; children=[HTML("<p>hi</p>")])) ==
              "<div><p>hi</p></div>"

        # Multiple children render in order.
        @test render(ReactDOMElement(; children=[HTML("<a>"), HTML("<b>"), HTML("<c>")])) ==
              "<div><a><b><c></div>"

        # Nested ReactDOMElement.
        inner = ReactDOMElement(; tag="span", attributes=OrderedDict("id" => "i"), children=[HTML("ok")])
        @test render(ReactDOMElement(; tag="section", children=[inner])) ==
              "<section><span id=\"i\">ok</span></section>"

        # Deeply nested — three levels.
        deep = ReactDOMElement(; children=[
            ReactDOMElement(; tag="a", children=[
                ReactDOMElement(; tag="b", children=[HTML("x")])
            ])
        ])
        @test render(deep) == "<div><a><b>x</b></a></div>"
    end

    @testset "tag is emitted verbatim (no validation)" begin
        @test render(ReactDOMElement(; tag="my-custom-element")) ==
              "<my-custom-element></my-custom-element>"
    end

    @testset "Pluto embed branch is taken when :pluto_embed_display is set" begin
        # If :pluto_embed_display is in the IOContext, the fallback should delegate
        # rather than emit raw HTML. We stub the embed callback to write a marker.
        called = Ref(0)
        function embed_stub(io, x, _auto_id_giver)
            called[] += 1
            HTML("STUB")
        end
        e = ReactDOMElement(; tag="div", attributes=OrderedDict("id" => "should-not-appear"))
        s = render(e; pluto_embed_display=embed_stub)
        @test called[] == 1
        @test s == "STUB"
    end
end
