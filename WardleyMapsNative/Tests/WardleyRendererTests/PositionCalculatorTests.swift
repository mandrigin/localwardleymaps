import Testing
@testable import WardleyRenderer

@Suite("PositionCalculator")
struct PositionCalculatorTests {
    let calc = PositionCalculator(mapWidth: 500, mapHeight: 600, padding: 20)

    @Test("Maturity 0 maps to left padding")
    func testMaturityZero() {
        let x = calc.maturityToX(0)
        #expect(x == 20)
    }

    @Test("Maturity 1 maps to right edge")
    func testMaturityOne() {
        let x = calc.maturityToX(1)
        #expect(x == 480) // 500 - 20
    }

    @Test("Visibility 1 maps to top padding")
    func testVisibilityOne() {
        let y = calc.visibilityToY(1)
        #expect(y == 20)
    }

    @Test("Visibility 0 maps to bottom edge")
    func testVisibilityZero() {
        let y = calc.visibilityToY(0)
        #expect(y == 580) // 600 - 20
    }

    @Test("Round-trip maturity conversion")
    func testMaturityRoundTrip() {
        let original = 0.65
        let x = calc.maturityToX(original)
        let back = calc.xToMaturity(x)
        #expect(abs(back - original) < 0.001)
    }

    @Test("Round-trip visibility conversion")
    func testVisibilityRoundTrip() {
        let original = 0.42
        let y = calc.visibilityToY(original)
        let back = calc.yToVisibility(y)
        #expect(abs(back - original) < 0.001)
    }

    @Test("Point convenience method")
    func testPoint() {
        let pt = calc.point(visibility: 0.5, maturity: 0.5)
        #expect(pt.x == 250) // midpoint of 500
        #expect(pt.y == 300) // midpoint of 600
    }
}
