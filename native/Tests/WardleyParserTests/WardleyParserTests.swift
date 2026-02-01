import Testing
@testable import WardleyModel
@testable import WardleyParser

@Suite("WardleyParser")
struct WardleyParserTests {
    let parser = WardleyParser()

    // MARK: - Title

    @Test("Extracts title from DSL")
    func testTitle() {
        let map = parser.parse("title Tea Shop\ncomponent Cup [0.79, 0.61]")
        #expect(map.title == "Tea Shop")
    }

    @Test("Default title when none specified")
    func testDefaultTitle() {
        let map = parser.parse("component Cup [0.79, 0.61]")
        #expect(map.title == "Untitled Map")
    }

    @Test("Empty input gives untitled map")
    func testEmptyInput() {
        let map = parser.parse("")
        #expect(map.title == "Untitled Map")
    }

    // MARK: - Components

    @Test("Extracts components with coordinates")
    func testComponents() {
        let map = parser.parse("component Cup of Tea [0.79, 0.61]")
        #expect(map.elements.count == 1)
        #expect(map.elements[0].name == "Cup of Tea")
        #expect(map.elements[0].visibility == 0.79)
        #expect(map.elements[0].maturity == 0.61)
    }

    @Test("Extracts component with label")
    func testComponentLabel() {
        let map = parser.parse("component Cup of Tea [0.79, 0.61] label [-85.48, 3.78]")
        #expect(map.elements[0].label.x == -85.48)
        #expect(map.elements[0].label.y == 3.78)
    }

    @Test("Extracts component with inertia")
    func testComponentInertia() {
        let map = parser.parse("component Kettle [0.43, 0.35] inertia")
        #expect(map.elements[0].inertia == true)
    }

    @Test("Extracts component with decorator")
    func testComponentDecorators() {
        let map = parser.parse("component Platform [0.5, 0.6] (buy)")
        #expect(map.elements[0].decorators.buy == true)
        #expect(map.elements[0].decorators.build == false)
    }

    @Test("Extracts multiple components")
    func testMultipleComponents() {
        let input = """
        component Cup [0.73, 0.78]
        component Tea [0.63, 0.81]
        component Water [0.38, 0.82]
        """
        let map = parser.parse(input)
        #expect(map.elements.count == 3)
        #expect(map.elements[0].name == "Cup")
        #expect(map.elements[1].name == "Tea")
        #expect(map.elements[2].name == "Water")
    }

    // MARK: - Evolution Labels

    @Test("Extracts custom evolution labels")
    func testEvolutionLabels() {
        let map = parser.parse("evolution Uncharted->Emerging->Good->Best")
        #expect(map.evolution.count == 4)
        #expect(map.evolution[0].line1 == "Uncharted")
        #expect(map.evolution[3].line1 == "Best")
    }

    @Test("Default evolution labels")
    func testDefaultEvolution() {
        let map = parser.parse("component Cup [0.5, 0.5]")
        #expect(map.evolution.count == 4)
        #expect(map.evolution[0].line1 == "Genesis")
        #expect(map.evolution[2].line1 == "Product")
    }

    // MARK: - Links

    @Test("Extracts dependency links")
    func testLinks() {
        let input = """
        component A [0.5, 0.5]
        component B [0.3, 0.7]
        A->B
        """
        let map = parser.parse(input)
        #expect(map.links.count == 1)
        #expect(map.links[0].start == "A")
        #expect(map.links[0].end == "B")
        #expect(map.links[0].flow == false)
    }

    @Test("Extracts flow links")
    func testFlowLinks() {
        let input = "A+>B"
        let map = parser.parse(input)
        #expect(map.links.count == 1)
        #expect(map.links[0].flow == true)
    }

    @Test("Extracts link with context")
    func testLinkContext() {
        let input = "Hot Water->Kettle; limited by"
        let map = parser.parse(input)
        #expect(map.links.count == 1)
        #expect(map.links[0].context == "limited by")
        #expect(map.links[0].end == "Kettle")
    }

    @Test("Extracts future flow links")
    func testFutureFlowLinks() {
        let input = "A+<B"
        let map = parser.parse(input)
        #expect(map.links.count == 1)
        #expect(map.links[0].future == true)
    }

    // MARK: - Evolve

    @Test("Extracts evolve with maturity")
    func testEvolve() {
        let map = parser.parse("evolve Kettle 0.62")
        #expect(map.evolved.count == 1)
        #expect(map.evolved[0].name == "Kettle")
        #expect(map.evolved[0].maturity == 0.62)
    }

    @Test("Extracts evolve with rename")
    func testEvolveRename() {
        let map = parser.parse("evolve Kettle->Electric Kettle 0.62 label [16, 5]")
        #expect(map.evolved[0].name == "Kettle")
        #expect(map.evolved[0].override == "Electric Kettle")
        #expect(map.evolved[0].maturity == 0.62)
        #expect(map.evolved[0].label.x == 16)
    }

    // MARK: - Pipelines

    @Test("Extracts pipeline with maturity range")
    func testPipeline() {
        let map = parser.parse("pipeline Kettle [0.15, 0.65]")
        #expect(map.pipelines.count == 1)
        #expect(map.pipelines[0].name == "Kettle")
        #expect(map.pipelines[0].maturity1 == 0.15)
        #expect(map.pipelines[0].maturity2 == 0.65)
        #expect(map.pipelines[0].hidden == false)
    }

    @Test("Extracts hidden pipeline")
    func testHiddenPipeline() {
        let map = parser.parse("pipeline Kettle")
        #expect(map.pipelines[0].hidden == true)
    }

    // MARK: - Anchors

    @Test("Extracts anchors")
    func testAnchors() {
        let map = parser.parse("anchor Business [0.95, 0.63]")
        #expect(map.anchors.count == 1)
        #expect(map.anchors[0].name == "Business")
        #expect(map.anchors[0].visibility == 0.95)
    }

    // MARK: - Annotations

    @Test("Extracts annotations with occurrences")
    func testAnnotations() {
        let map = parser.parse("annotation 1 [[0.43,0.49],[0.08,0.79]] Some text here")
        #expect(map.annotations.count == 1)
        #expect(map.annotations[0].number == 1)
        #expect(map.annotations[0].occurances.count == 2)
        #expect(map.annotations[0].text == "Some text here")
    }

    @Test("Extracts single occurrence annotation")
    func testSingleAnnotation() {
        let map = parser.parse("annotation 2 [0.48, 0.85] Hot water is obvious")
        #expect(map.annotations.count == 1)
        #expect(map.annotations[0].occurances.count == 1)
    }

    // MARK: - Notes

    @Test("Extracts notes")
    func testNotes() {
        let map = parser.parse("note +a generic note appeared [0.23, 0.33]")
        #expect(map.notes.count == 1)
        #expect(map.notes[0].text == "+a generic note appeared")
        #expect(map.notes[0].visibility == 0.23)
    }

    // MARK: - Presentation

    @Test("Extracts style")
    func testStyle() {
        let map = parser.parse("style wardley")
        #expect(map.presentation.style == "wardley")
    }

    @Test("Extracts annotations position")
    func testAnnotationsPosition() {
        let map = parser.parse("annotations [0.72, 0.03]")
        #expect(map.presentation.annotations.visibility == 0.72)
        #expect(map.presentation.annotations.maturity == 0.03)
    }

    // MARK: - Attitudes

    @Test("Extracts attitudes")
    func testAttitudes() {
        let map = parser.parse("pioneers [0.9, 0.1, 0.5, 0.4]")
        #expect(map.attitudes.count == 1)
        #expect(map.attitudes[0].attitude == "pioneers")
    }

    // MARK: - Accelerators

    @Test("Extracts accelerator")
    func testAccelerator() {
        let map = parser.parse("accelerator MyAcc [0.5, 0.7]")
        #expect(map.accelerators.count == 1)
        #expect(map.accelerators[0].name == "MyAcc")
        #expect(map.accelerators[0].deaccelerator == false)
    }

    @Test("Extracts deaccelerator")
    func testDeaccelerator() {
        let map = parser.parse("deaccelerator MyDeacc [0.3, 0.4]")
        #expect(map.accelerators.count == 1)
        #expect(map.accelerators[0].deaccelerator == true)
    }

    // MARK: - URLs

    @Test("Extracts URLs")
    func testURLs() {
        let map = parser.parse("url MyUrl [https://example.com]")
        #expect(map.urls.count == 1)
        #expect(map.urls[0].name == "MyUrl")
        #expect(map.urls[0].url == "https://example.com")
    }

    // MARK: - Submaps

    @Test("Extracts submaps")
    func testSubmaps() {
        let map = parser.parse("submap MySubmap [0.6, 0.5] url(http://example.com)")
        #expect(map.submaps.count == 1)
        #expect(map.submaps[0].name == "MySubmap")
    }

    // MARK: - Methods

    @Test("Extracts methods")
    func testMethods() {
        let map = parser.parse("buy MyComponent")
        #expect(map.methods.count == 1)
        #expect(map.methods[0].name == "MyComponent")
        #expect(map.methods[0].decorators.buy == true)
    }

    // MARK: - Comments

    @Test("Strips single line comments")
    func testSingleLineComments() {
        let input = """
        title Test // this is a comment
        component Cup [0.5, 0.5]
        // this whole line is a comment
        component Tea [0.3, 0.7]
        """
        let map = parser.parse(input)
        #expect(map.title == "Test")
        #expect(map.elements.count == 2)
    }

    @Test("Strips block comments")
    func testBlockComments() {
        let input = """
        title Test
        /* this is
        a block comment */
        component Cup [0.5, 0.5]
        """
        let map = parser.parse(input)
        #expect(map.elements.count == 1)
    }

    @Test("URL lines preserve double slashes")
    func testURLPreservesSlashes() {
        let map = parser.parse("url MyUrl [https://example.com/path]")
        #expect(map.urls[0].url == "https://example.com/path")
    }

    // MARK: - Unpositioned Component Distribution

    @Test("Single unpositioned component keeps default position")
    func testSingleUnpositionedComponent() {
        let map = parser.parse("component Foo")
        #expect(map.elements.count == 1)
        #expect(map.elements[0].visibility == 0.9)
        #expect(map.elements[0].maturity == 0.1)
    }

    @Test("Multiple unpositioned components are distributed along maturity")
    func testUnpositionedComponentDistribution() {
        let input = """
        component Alpha
        component Beta
        component Gamma
        """
        let map = parser.parse(input)
        #expect(map.elements.count == 3)
        // All should share the default visibility
        for el in map.elements {
            #expect(el.visibility == 0.9)
        }
        // Each should have a distinct maturity
        #expect(map.elements[0].maturity != map.elements[1].maturity)
        #expect(map.elements[1].maturity != map.elements[2].maturity)
        // First at 0.1, last at 0.9, middle at 0.5
        #expect(map.elements[0].maturity == 0.1)
        #expect(map.elements[1].maturity == 0.5)
        #expect(map.elements[2].maturity == 0.9)
    }

    @Test("Positioned components are not affected by distribution")
    func testPositionedComponentsUnaffected() {
        let input = """
        component Positioned [0.5, 0.5]
        component Unpositioned1
        component Unpositioned2
        component AlsoPositioned [0.3, 0.7]
        """
        let map = parser.parse(input)
        #expect(map.elements.count == 4)
        // Positioned components keep their explicit coordinates
        let positioned = map.elements.first { $0.name == "Positioned" }!
        #expect(positioned.visibility == 0.5)
        #expect(positioned.maturity == 0.5)
        let alsoPositioned = map.elements.first { $0.name == "AlsoPositioned" }!
        #expect(alsoPositioned.visibility == 0.3)
        #expect(alsoPositioned.maturity == 0.7)
        // Unpositioned components are distributed
        let unpos1 = map.elements.first { $0.name == "Unpositioned1" }!
        let unpos2 = map.elements.first { $0.name == "Unpositioned2" }!
        #expect(unpos1.maturity != unpos2.maturity)
    }

    // MARK: - Full Map (Tea Shop Example)

    @Test("Parses complete Tea Shop map")
    func testTeaShopMap() {
        let input = """
        title Tea Shop
        anchor Business [0.95, 0.63]
        anchor Public [0.95, 0.78]
        component Cup of Tea [0.79, 0.61] label [-85.48, 3.78]
        component Cup [0.73, 0.78]
        component Tea [0.63, 0.81]
        component Hot Water [0.52, 0.80]
        component Water [0.38, 0.82]
        component Kettle [0.43, 0.35] label [-57, 4]
        evolve Kettle->Electric Kettle 0.62 label [16, 5]
        component Power [0.1, 0.7] label [-27, 20]
        evolve Power 0.89 label [-12, 21]
        Business->Cup of Tea
        Public->Cup of Tea
        Cup of Tea->Cup
        Cup of Tea->Tea
        Cup of Tea->Hot Water
        Hot Water->Water
        Hot Water->Kettle; limited by
        Kettle->Power
        annotation 1 [[0.43,0.49],[0.08,0.79]] Standardising power allows Kettles to evolve faster
        annotation 2 [0.48, 0.85] Hot water is obvious and well known
        annotations [0.72, 0.03]
        note +a generic note appeared [0.23, 0.33]
        style wardley
        """
        let map = parser.parse(input)

        #expect(map.title == "Tea Shop")
        #expect(map.elements.count == 7)
        #expect(map.anchors.count == 2)
        #expect(map.evolved.count == 2)
        #expect(map.links.count == 8)
        #expect(map.annotations.count == 2)
        #expect(map.notes.count == 1)
        #expect(map.presentation.style == "wardley")

        // Verify evolved components
        let kettleEvolve = map.evolved.first { $0.name == "Kettle" }
        #expect(kettleEvolve?.override == "Electric Kettle")
        #expect(kettleEvolve?.maturity == 0.62)

        // Verify link with context
        let contextLink = map.links.first { $0.context != nil }
        #expect(contextLink?.start == "Hot Water")
        #expect(contextLink?.end == "Kettle")
        #expect(contextLink?.context == "limited by")
    }
}
