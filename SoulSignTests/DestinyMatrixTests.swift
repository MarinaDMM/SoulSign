//
//  DestinyMatrixTests.swift
//  SoulSignTests
//
import XCTest
@testable import SoulSign

final class DestinyMatrixTests: XCTestCase {

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d
        return Calendar.current.date(from: c)!
    }

    func testAllValuesReducedToAtMost22() {
        // Numerology positions must always reduce into the 1...22 arcana range.
        for (y, m, d) in [(1990, 6, 15), (2001, 12, 31), (1888, 1, 1), (2024, 9, 9)] {
            let mtx = DestinyMatrix.compute(from: date(y, m, d))
            for value in [mtx.A, mtx.B, mtx.C, mtx.D, mtx.E,
                          mtx.AB, mtx.BC, mtx.CD, mtx.DA,
                          mtx.AE, mtx.BE, mtx.CE, mtx.DE] {
                XCTAssertGreaterThanOrEqual(value, 1, "\(y)-\(m)-\(d)")
                XCTAssertLessThanOrEqual(value, 22, "value \(value) for \(y)-\(m)-\(d)")
            }
        }
    }

    func testDeterministicForSameDate() {
        let a = DestinyMatrix.compute(from: date(1990, 6, 15))
        let b = DestinyMatrix.compute(from: date(1990, 6, 15))
        XCTAssertEqual(a.A, b.A)
        XCTAssertEqual(a.E, b.E)
        XCTAssertEqual(a.DE, b.DE)
    }

    func testKnownNumerology_15June1990() {
        // reduce(n) only collapses values ABOVE 22, so numbers 1...22 pass
        // through untouched. day=15 -> 15 ; month=6 -> 6 ;
        // year 1990 digit-sum = 19 -> 19 (all <= 22, so kept as-is).
        let mtx = DestinyMatrix.compute(from: date(1990, 6, 15))
        XCTAssertEqual(mtx.A, 15, "day 15 is <= 22, not reduced")
        XCTAssertEqual(mtx.B, 6, "month 6")
        XCTAssertEqual(mtx.C, 19, "1990 digit-sum 19, <= 22")
        // D = reduce(15+6+19) = reduce(40) = 4+0 = 4
        XCTAssertEqual(mtx.D, 4)
        // E = reduce(15+6+19+4) = reduce(44) = 4+4 = 8  (matches the chart's centre)
        XCTAssertEqual(mtx.E, 8)
        // AB = reduce(15+6) = reduce(21) = 21 (<= 22, unchanged)
        XCTAssertEqual(mtx.AB, 21)
    }

    func testValuesUnder22PassThroughUnreduced() {
        // Confirms the ">22" threshold: 15, 19, 21 are all kept, not collapsed
        // to single digits.
        let mtx = DestinyMatrix.compute(from: date(1990, 6, 15))
        XCTAssertEqual(mtx.A, 15)
        XCTAssertEqual(mtx.C, 19)
        XCTAssertEqual(mtx.AB, 21)
    }
}
