//
//  UserProfile.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 11/6/25.
//

// UserProfile.swift
import Foundation

struct UserProfile: Codable {
    var myName: String
    var createdAt: Date = Date()
}

