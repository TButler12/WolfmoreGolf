//
//  RemoteMatch.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 4/13/26.
//
import Foundation

struct RemoteMatch: Codable, Identifiable {
    let id: UUID
    var createdAt: Date

    var myRound: SharedRound
    var opponentRound: SharedRound?

    var opponentName: String
    var stakePerBet: Int

    var inviteCode: String?
    var isAccepted: Bool
}

extension RemoteMatch {
    var hasOpponentRound: Bool {
        opponentRound != nil
    }

    var statusText: String {
        if !isAccepted { return "Invite sent" }
        if opponentRound == nil { return "Waiting for opponent" }
        return "Ready"
    }

    var result: RemoteNassauResult? {
        guard let opponentRound else { return nil }
        return RemoteNassauScorer.score(
            playerA: myRound,
            playerB: opponentRound,
            stakePerBet: stakePerBet
        )
    }
}
extension RemoteMatch {
    init(
        myRound: SharedRound,
        opponentName: String,
        stakePerBet: Int,
        inviteCode: String? = nil,
        isAccepted: Bool = false,
        opponentRound: SharedRound? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.myRound = myRound
        self.opponentRound = opponentRound
        self.opponentName = opponentName
        self.stakePerBet = stakePerBet
        self.inviteCode = inviteCode
        self.isAccepted = isAccepted
    }
}
