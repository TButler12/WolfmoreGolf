//
//  CourseStore.swift
//  Wolfmore-5Man
//
//  Created by Tom BUTLER on 9/29/25.
// CourseStore.swift
import Foundation

enum CourseStore {
    private static let key = "persistedCourse.v1"
    static func load() -> CourseData {
        if let d = UserDefaults.standard.data(forKey: key),
           let c = try? JSONDecoder().decode(CourseData.self, from: d) { return c }
        return .default
    }
    static func save(_ c: CourseData) {
        if let d = try? JSONEncoder().encode(c) {
            UserDefaults.standard.set(d, forKey: key)
        }
    }
}
