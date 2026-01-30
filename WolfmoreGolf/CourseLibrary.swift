//
//  CourseLibrary.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 12/28/25.
//

import Foundation

// =======================================================
// MARK: - Built-in default: Biltmore CC (18 pars + 18 HCs)
// =======================================================

let WOLFMORE_PARS: [Int] = [
    4,4,4,4,3,5,3,4,4,
    4,4,3,4,4,5,3,4,5
]

let WOLFMORE_HCS: [Int] = [
    4,8,14,10,16,2,18,6,12,
    11,3,15,1,13,7,17,9,5
]

// ===============================================
// MARK: - Course model + tiny persistent library
// ===============================================

struct CourseProfile: Codable, Equatable {
    var id: UUID
    var name: String
    var pars: [Int]   // 18
    var hcs:  [Int]   // 18

    init(id: UUID = UUID(), name: String, pars: [Int], hcs: [Int]) {
        self.id = id
        self.name = name
        self.pars = Array(pars.prefix(18))
        self.hcs  = Array(hcs.prefix(18))
    }
}

final class CourseLibrary {
    static let shared = CourseLibrary()

    private let keyLibrary = "course.library.v1"
    private let keySeed    = "course.library.seeded.v1"

    private(set) var courses: [CourseProfile] = []

    private init() { load() }

    /// Seed Biltmore once on first launch
    func seedIfNeeded() {
        let u = UserDefaults.standard
        guard !u.bool(forKey: keySeed) else { return }

        if !courses.contains(where: {
            $0.name.caseInsensitiveCompare("WolfMore CC") == ComparisonResult.orderedSame
        }) {
            courses.append(CourseProfile(name: "WolfMore CC", pars: WOLFMORE_PARS, hcs: WOLFMORE_HCS))
            save()
        }

        u.set(true, forKey: keySeed)
    }

    func allSorted() -> [CourseProfile] {
        courses.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func upsert(_ c: CourseProfile) {
        if let i = courses.firstIndex(where: { $0.id == c.id }) {
            courses[i] = c
        } else if let j = courses.firstIndex(where: {
            $0.name.caseInsensitiveCompare(c.name) == ComparisonResult.orderedSame
        }) {
            // preserve existing ID if overwriting by same name
            courses[j] = CourseProfile(id: courses[j].id, name: c.name, pars: c.pars, hcs: c.hcs)
        } else {
            courses.append(c)
        }
        save()
    }

    func get(id: UUID) -> CourseProfile? { courses.first { $0.id == id } }

    func delete(id: UUID) {
        courses.removeAll { $0.id == id }
        save()
    }

    func WolfMore() -> CourseProfile? {
        courses.first { $0.name.caseInsensitiveCompare("WolMore CC") == ComparisonResult.orderedSame }
    }

    // MARK: - Persistence
    private func load() {
        let u = UserDefaults.standard
        guard let data = u.data(forKey: keyLibrary) else { return }
        courses = (try? JSONDecoder().decode([CourseProfile].self, from: data)) ?? []
    }

    private func save() {
        let u = UserDefaults.standard
        let data = (try? JSONEncoder().encode(courses)) ?? Data()
        u.set(data, forKey: keyLibrary)
    }
}
