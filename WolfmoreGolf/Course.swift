//
//  Course.swift
//  Wolfmore-5Man
//
//  Created by Tom BUTLER on 9/29/25.
//

// Course.swift
import Foundation

struct Course: Codable {
    var pars: [Int]
    var holeHandicaps: [Int]

    static let `default` = Course(
        pars: Array(repeating: 4, count: 18),
        holeHandicaps: Array(1...18)
    )
}
