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
    var lockedResult: RemoteNassauResult?
}

extension RemoteMatch {

    var statusText: String {
        if !isAccepted   { return "Invite sent" }
        if !roundApplied { return "Accepted — apply your round" }
        return "Results ready"
    }

    var result: RemoteNassauResult? {
        if let locked = lockedResult { return locked }
        guard roundApplied, let opponentRound else { return nil }
        return RemoteNassauScorer.score(playerA: myRound, playerB: opponentRound,
                                        stakePerBet: stakePerBet, sameCourse: sameCourse)
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
        self.lockedResult = nil

        let localId  = myRound.courseId ?? ""
        let remoteId = opponentRound?.courseId ?? ""
        if !localId.isEmpty && !remoteId.isEmpty {
            self.sameCourse = localId == remoteId
        } else {
            let localName  = myRound.courseName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let remoteName = (opponentRound?.courseName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            self.sameCourse = !localName.isEmpty && !remoteName.isEmpty && localName == remoteName
        }
    }
}

// MARK: - Codable with backward-compat defaults

extension RemoteMatch: Codable {
    enum CodingKeys: String, CodingKey {
        case id, createdAt, myRound, opponentRound, opponentName
        case stakePerBet, inviteCode, isAccepted, compareMode, roundApplied, sameCourse
        case lockedResult
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id            = try c.decode(UUID.self,         forKey: .id)
        createdAt     = try c.decode(Date.self,         forKey: .createdAt)
        myRound       = try c.decode(SharedRound.self,  forKey: .myRound)
        opponentRound = try c.decodeIfPresent(SharedRound.self, forKey: .opponentRound)
        opponentName  = try c.decode(String.self,       forKey: .opponentName)
        stakePerBet   = try c.decode(Int.self,          forKey: .stakePerBet)
        inviteCode    = try c.decodeIfPresent(String.self, forKey: .inviteCode)
        isAccepted    = try c.decode(Bool.self,         forKey: .isAccepted)
        compareMode   = try c.decodeIfPresent(RemoteCompareMode.self, forKey: .compareMode) ?? .holeByHole
        roundApplied  = try c.decodeIfPresent(Bool.self, forKey: .roundApplied) ?? (opponentRound != nil)
        lockedResult  = try c.decodeIfPresent(RemoteNassauResult.self, forKey: .lockedResult)

        // Prefer courseId comparison; fall back to name for old records without courseId
        let storedSameCourse = try c.decodeIfPresent(Bool.self, forKey: .sameCourse)
        let localId  = myRound.courseId ?? ""
        let remoteId = opponentRound?.courseId ?? ""
        if !localId.isEmpty && !remoteId.isEmpty {
            sameCourse = localId == remoteId
        } else if let stored = storedSameCourse {
            sameCourse = stored
        } else {
            let localName  = myRound.courseName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let remoteName = (opponentRound?.courseName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            sameCourse = !localName.isEmpty && !remoteName.isEmpty && localName == remoteName
        }
    }
}
