//
//  RemoteMatchInvite.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 4/13/26.
//
import Foundation

struct RemoteMatchInvite: Codable {
    let matchID: UUID
    let inviterName: String
    let stakePerBet: Int
    let inviterRound: SharedRound
}
