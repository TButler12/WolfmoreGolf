//
//  RemoteMatch.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 4/13/26.
//
import Foundation

struct RemoteMatch: Identifiable {
    let id: UUID
    var createdAt: Date

    var myRound: SharedRound
    var opponentRound: SharedRound?

    var opponentName: String
    var stakePerBet: Int

    var inviteCode: String?
    var isAccepted: Bool

    var compareMode: RemoteCompareMode
    var roundApplied: Bool
    var sameCourse: Bool
}

extension RemoteMatch {

    var statusText: String {
        if !isAccepted   { return "Invite sent" }
        if !roundApplied { return "Accepted — apply your round" }
        return "Results ready"
    }

    var result: RemoteNassauResult? {
        guard roundApplied, let opponentRound else { return nil }
        return RemoteNassauScorer.score(playerA: myRound, playerB: opponentRound, stakePerBet: stakePerBet)
    }
}

extension RemoteMatch {
    init(
        myRound: SharedRound,
        opponentName: String,
        stakePerBet: Int,
        inviteCode: String? = nil,
        isAccepted: Bool = false,
        opponentRound: SharedRound? = nil,
        compareMode: RemoteCompareMode = .holeByHole,
        roundApplied: Bool = false
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.myRound = myRound
        self.opponentRound = opponentRound
        self.opponentName = opponentName
        self.stakePerBet = stakePerBet
        self.inviteCode = inviteCode
        self.isAccepted = isAccepted
        self.compareMode = compareMode
        self.roundApplied = roundApplied

        let localName  = myRound.courseName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let remoteName = (opponentRound?.courseName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.sameCourse = !localName.isEmpty && !remoteName.isEmpty && localName == remoteName
    }
}

// MARK: - Codable with backward-compat defaults

extension RemoteMatch: Codable {
    enum CodingKeys: String, CodingKey {
        case id, createdAt, myRound, opponentRound, opponentName
        case stakePerBet, inviteCode, isAccepted, compareMode, roundApplied, sameCourse
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id           = try c.decode(UUID.self,         forKey: .id)
        createdAt    = try c.decode(Date.self,         forKey: .createdAt)
        myRound      = try c.decode(SharedRound.self,  forKey: .myRound)
        opponentRound = try c.decodeIfPresent(SharedRound.self, forKey: .opponentRound)
        opponentName = try c.decode(String.self,       forKey: .opponentName)
        stakePerBet  = try c.decode(Int.self,          forKey: .stakePerBet)
        inviteCode   = try c.decodeIfPresent(String.self, forKey: .inviteCode)
        isAccepted   = try c.decode(Bool.self,         forKey: .isAccepted)
        compareMode  = try c.decodeIfPresent(RemoteCompareMode.self, forKey: .compareMode) ?? .holeByHole
        // Old matches that already had opponentRound set were fully applied
        roundApplied = try c.decodeIfPresent(Bool.self, forKey: .roundApplied) ?? (opponentRound != nil)
        // Recompute sameCourse on decode for backward compat; stored value used when present
        let storedSameCourse = try c.decodeIfPresent(Bool.self, forKey: .sameCourse)
        if let stored = storedSameCourse {
            sameCourse = stored
        } else {
            let localName  = myRound.courseName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let remoteName = (opponentRound?.courseName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            sameCourse = !localName.isEmpty && !remoteName.isEmpty && localName == remoteName
        }
    }
}
