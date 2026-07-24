//
//  DestinyMatrix.swift
//  SoulSign
//

import Foundation

struct DestinyMatrix {
    // 4 cardinal points
    let A, B, C, D: Int   // top (day), right (month), bottom (year), left (synthesis)
    let E: Int             // center / soul point

    // Edge midpoints on the outer diamond
    let AB, BC, CD, DA: Int

    // Inner midpoints between each corner and center
    let AE, BE, CE, DE: Int

    static func compute(from date: Date) -> DestinyMatrix {
        let cal = Calendar.current
        let day   = cal.component(.day,   from: date)
        let month = cal.component(.month, from: date)
        let year  = cal.component(.year,  from: date)
        let yearSum = String(year).compactMap { $0.wholeNumberValue }.reduce(0, +)

        let a = reduce(day)
        let b = reduce(month)
        let c = reduce(yearSum)
        let d = reduce(a + b + c)
        let e = reduce(a + b + c + d)

        return DestinyMatrix(
            A: a, B: b, C: c, D: d, E: e,
            AB: reduce(a + b), BC: reduce(b + c),
            CD: reduce(c + d), DA: reduce(d + a),
            AE: reduce(a + e), BE: reduce(b + e),
            CE: reduce(c + e), DE: reduce(d + e)
        )
    }

    // Reduces n to 1–22 by digit-summing repeatedly.
    private static func reduce(_ n: Int) -> Int {
        guard n > 22 else { return n }
        return reduce(String(n).compactMap { $0.wholeNumberValue }.reduce(0, +))
    }
}
