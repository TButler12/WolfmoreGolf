//
//  TextGroup.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 3/25/26.
//
import Foundation

struct TextGroup: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var memberIDs: [UUID]

    init(id: UUID = UUID(), name: String, memberIDs: [UUID]) {
        self.id = id
        self.name = name
        self.memberIDs = memberIDs
    }
}
