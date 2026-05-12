using Test
using AbstractPlutoDingetjes
using AbstractPlutoDingetjes: Bonds, Display

@testset "AbstractPlutoDingetjes" begin
    @testset "top-level callables" begin
        @test is_inside_pluto() isa Bool
        io = IOBuffer()
        @test is_inside_pluto(io) === false
        @test is_supported_by_display(io, Display.published_to_js) === false
        @test is_supported_by_display(IOContext(io, :pluto_supported_integration_features => Any[Display.published_to_js]), Display.published_to_js) === true
    end

    @testset "Bonds fallbacks" begin
        struct _DummyBond end
        b = _DummyBond()
        @test Bonds.initial_value(b) === missing
        @test Bonds.transform_value(b, 42) === 42
        @test Bonds.possible_values(b) isa Bonds.NotGiven
        @test Bonds.validate_value(b, 42) === false
        # Marker types are constructable.
        @test Bonds.NotGiven() isa Bonds.NotGiven
        @test Bonds.InfinitePossibilities() isa Bonds.InfinitePossibilities
    end

    @testset "Display markers callable" begin
        # published_to_js returns a marker; rendering without the iocontext key errors.
        p = Display.published_to_js([1, 2, 3])
        @test_throws AssertionError sprint(show, MIME"text/javascript"(), p)

        # with_js_link returns a marker; same.
        l = Display.with_js_link(sqrt)
        l2 = Display.with_js_link(sqrt, () -> nothing)
        @test_throws AssertionError sprint(show, MIME"text/javascript"(), l)
        @test_throws AssertionError sprint(show, MIME"text/javascript"(), l2)

        # @auto_id falls back to a random string outside Pluto.
        id = sprint(io -> show(io, (@eval Display.@auto_id)))
        @test id isa String && !isempty(id)

        # @embed falls back to plain show of the wrapped value outside Pluto.
        embedded = @eval Display.@embed HTML("hello")
        @test sprint(show, MIME"text/html"(), embedded) isa String
    end

    @testset "ReactDOMElement sanity" begin
        @test Display.ReactDOMElement() isa Display.ReactDOMElement
        e = Display.ReactDOMElement(; tag="span", attributes=Dict("id" => "x"), children=Any[HTML("hi")])
        @test e.tag == "span"
        @test e.attributes["id"] == "x"
        @test length(e.children) == 1
    end
end
