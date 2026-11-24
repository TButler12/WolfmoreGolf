import Foundation

struct EventPots {
    let teamNet:    Double
    let teamGross:  Double
    let grossSkins: Double
    let netSkins:   Double
}

enum PayoutCalculator {

    /// Compute all four pots.
    ///
    /// - Parameters:
    ///   - rules:       Event rules (payout mode, per-player amounts, fixed totals).
    ///   - players:     Full roster. Active = assigned to a group + not withdrawn.
    ///   - memberships: Team membership records. Used for team pool counts so a
    ///                  dual-team player is counted once per team. Pass `[]` to
    ///                  fall back to unique-player count for all pools.
    static func pots(
        rules:       ClubEventRules,
        players:     [ClubEventPlayer],
        memberships: [ClubEventTeamMembership] = []
    ) -> EventPots {

        if rules.payoutMode == "fixed_total" {
            return EventPots(
                teamNet:    rules.teamNetTotal,
                teamGross:  rules.teamGrossTotal,
                grossSkins: rules.grossSkinsEnabled ? rules.grossSkinsTotal : 0,
                netSkins:   rules.netSkinsEnabled   ? rules.netSkinsTotal   : 0
            )
        }

        // per_player: active = assigned to a group and not withdrawn
        let activePlayers = players.filter { $0.groupCode != nil && !$0.isWithdrawn }
        let activeIds     = Set(activePlayers.map(\.id))
        let skinsN        = Double(activePlayers.count)

        // Team pools: count active team memberships (dual-team player counted once per team)
        let teamN: Double
        if memberships.isEmpty {
            teamN = skinsN
        } else {
            teamN = Double(memberships.filter { activeIds.contains($0.tournamentPlayerId) }.count)
        }

        return EventPots(
            teamNet:    rules.teamNetPerPlayer   * teamN,
            teamGross:  rules.teamGrossPerPlayer * teamN,
            grossSkins: rules.grossSkinsEnabled ? rules.grossSkinsPerPlayer * skinsN : 0,
            netSkins:   rules.netSkinsEnabled   ? rules.netSkinsPerPlayer   * skinsN : 0
        )
    }
}
