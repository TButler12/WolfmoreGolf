import XCTest
@testable import WolfmoreGolf

final class PayoutCalculatorTests: XCTestCase {

    private let tid = UUID()

    private func makeRules(
        payoutMode: String = "per_player",
        teamNet: Double = 0, teamGross: Double = 0,
        grossSkins: Double = 0, netSkins: Double = 0,
        grossSkinsEnabled: Bool = true, netSkinsEnabled: Bool = true,
        teamNetTotal: Double = 0, teamGrossTotal: Double = 0,
        grossSkinsTotal: Double = 0, netSkinsTotal: Double = 0
    ) -> ClubEventRules {
        ClubEventRules(
            handicapAllowance: 1.0, grossLeaderboard: false,
            grossSkinsEnabled: grossSkinsEnabled, netSkinsEnabled: netSkinsEnabled,
            skinsCarryover: false,
            teamNetPerPlayer: teamNet, teamGrossPerPlayer: teamGross,
            grossSkinsPerPlayer: grossSkins, netSkinsPerPlayer: netSkins,
            teamPlacesPaid: 3, placePcts: [50, 30, 20], allowDualTeam: false,
            payoutMode: payoutMode,
            teamNetTotal: teamNetTotal, teamGrossTotal: teamGrossTotal,
            grossSkinsTotal: grossSkinsTotal, netSkinsTotal: netSkinsTotal
        )
    }

    private func player(groupCode: String?, withdrawn: Bool = false) -> ClubEventPlayer {
        ClubEventPlayer(id: UUID(), tournamentId: tid, playerName: "Test", handicap: 0,
                        groupCode: groupCode, status: withdrawn ? "withdrawn" : "active")
    }

    // MARK: - Per player mode

    func testPerPlayer_pot500_10Players() {
        // $50/player × 10 = $500
        let rules = makeRules(grossSkins: 50, netSkins: 50)
        let players = (0..<10).map { _ in player(groupCode: "A") }
        let pots = PayoutCalculator.pots(rules: rules, players: players)
        XCTAssertEqual(pots.grossSkins, 500)
        XCTAssertEqual(pots.netSkins, 500)
    }

    func testPerPlayer_5SkinsPaidPerSkin100() {
        // $500 total, 5 skins won → $100 each
        let rules = makeRules(grossSkins: 50)
        let players = (0..<10).map { _ in player(groupCode: "A") }
        let pots = PayoutCalculator.pots(rules: rules, players: players)
        XCTAssertEqual(pots.grossSkins / 5.0, 100.0)
    }

    func testPerPlayer_zeroPlayersNoDivisionByZero() {
        let rules = makeRules(grossSkins: 50, netSkins: 50)
        let pots = PayoutCalculator.pots(rules: rules, players: [])
        XCTAssertEqual(pots.grossSkins, 0)
        XCTAssertEqual(pots.netSkins, 0)
    }

    func testPerPlayer_withdrawnExcluded() {
        let rules = makeRules(grossSkins: 10)
        let players = [
            player(groupCode: "A"),
            player(groupCode: "A", withdrawn: true),
            player(groupCode: "B"),
        ]
        let pots = PayoutCalculator.pots(rules: rules, players: players)
        XCTAssertEqual(pots.grossSkins, 20)   // 2 active, not 3
    }

    func testPerPlayer_unassignedExcluded() {
        let rules = makeRules(teamNet: 20)
        let players = [
            player(groupCode: "A"),
            player(groupCode: nil),
            player(groupCode: "B"),
        ]
        let pots = PayoutCalculator.pots(rules: rules, players: players)
        XCTAssertEqual(pots.teamNet, 40)   // 2 assigned, not 3
    }

    func testPerPlayer_disabledPoolsAreZero() {
        let rules = makeRules(grossSkins: 50, netSkins: 50,
                              grossSkinsEnabled: false, netSkinsEnabled: true)
        let players = [player(groupCode: "A"), player(groupCode: "A")]
        let pots = PayoutCalculator.pots(rules: rules, players: players)
        XCTAssertEqual(pots.grossSkins, 0)
        XCTAssertEqual(pots.netSkins, 100)
    }

    // MARK: - Fixed total mode

    func testFixedTotal_usesTotalDirectly() {
        let rules = makeRules(payoutMode: "fixed_total",
                              grossSkinsTotal: 300, netSkinsTotal: 200)
        let players = (0..<5).map { _ in player(groupCode: "A") }
        let pots = PayoutCalculator.pots(rules: rules, players: players)
        XCTAssertEqual(pots.grossSkins, 300)
        XCTAssertEqual(pots.netSkins, 200)
    }

    func testFixedTotal_disabledPoolsAreZero() {
        let rules = makeRules(payoutMode: "fixed_total",
                              grossSkinsEnabled: false, netSkinsEnabled: true,
                              grossSkinsTotal: 300, netSkinsTotal: 200)
        let players = (0..<5).map { _ in player(groupCode: "A") }
        let pots = PayoutCalculator.pots(rules: rules, players: players)
        XCTAssertEqual(pots.grossSkins, 0)
        XCTAssertEqual(pots.netSkins, 200)
    }

    func testFixedTotal_withdrawnDontAffectPot() {
        let rules = makeRules(payoutMode: "fixed_total", grossSkinsTotal: 500)
        let players = [
            player(groupCode: "A"),
            player(groupCode: "A", withdrawn: true),
        ]
        let pots = PayoutCalculator.pots(rules: rules, players: players)
        XCTAssertEqual(pots.grossSkins, 500)
    }

    // MARK: - Dual-team player (counted once in skins, once per team for teams)

    func testPerPlayer_dualTeamPlayerCountsOnce() {
        // A player on two teams still counts as 1 active player in the per-player count
        let rules = makeRules(grossSkins: 20)
        let players = [player(groupCode: "A")]   // one player assigned
        let pots = PayoutCalculator.pots(rules: rules, players: players)
        XCTAssertEqual(pots.grossSkins, 20)
    }

    func testDualTeam_anneScenario() {
        // 7 players (all active), Fred is on 2 teams → 8 total team memberships
        // $10 team net/player → $80 team pot (8 slots)
        // $10 gross skins/player → $70 skins pot (7 players)
        let rules = makeRules(teamNet: 10, grossSkins: 10)
        var players: [ClubEventPlayer] = []
        var fredId: UUID!
        for i in 0..<7 {
            let p = player(groupCode: "A")
            players.append(p)
            if i == 0 { fredId = p.id }
        }

        let teamA = UUID(); let teamB = UUID()
        let teamC = UUID(); let teamD = UUID()
        // 4 teams; Fred (index 0) is on both A and B; others are one each
        var memberships: [ClubEventTeamMembership] = [
            ClubEventTeamMembership(teamId: teamA, tournamentPlayerId: fredId),
            ClubEventTeamMembership(teamId: teamB, tournamentPlayerId: fredId),
        ]
        for i in 1..<7 {
            let team = i <= 2 ? teamA : (i <= 4 ? teamC : teamD)
            memberships.append(ClubEventTeamMembership(teamId: team, tournamentPlayerId: players[i].id))
        }

        let pots = PayoutCalculator.pots(rules: rules, players: players, memberships: memberships)
        XCTAssertEqual(pots.teamNet,    80, "8 memberships × $10")
        XCTAssertEqual(pots.grossSkins, 70, "7 players × $10")
    }

    func testDualTeam_withdrawnExcludedFromBoth() {
        // Alice active, Bob withdrawn — both on same team
        // After filter: 1 active player (skins), 1 active membership (team)
        let rules = makeRules(teamNet: 10, grossSkins: 10)
        let alice = player(groupCode: "A")
        let bob   = player(groupCode: "A", withdrawn: true)
        let team  = UUID()
        let memberships = [
            ClubEventTeamMembership(teamId: team, tournamentPlayerId: alice.id),
            ClubEventTeamMembership(teamId: team, tournamentPlayerId: bob.id),
        ]
        let pots = PayoutCalculator.pots(rules: rules, players: [alice, bob], memberships: memberships)
        XCTAssertEqual(pots.teamNet,    10, "1 active membership × $10")
        XCTAssertEqual(pots.grossSkins, 10, "1 active player × $10")
    }

    func testFixedTotal_ignoresMemberships() {
        // fixed_total mode uses hardcoded totals regardless of membership counts
        let rules = makeRules(payoutMode: "fixed_total",
                              teamNetTotal: 300, grossSkinsTotal: 500)
        let playerList = (0..<3).map { _ in player(groupCode: "A") }
        let team = UUID()
        let memberships = playerList.flatMap { p in [
            ClubEventTeamMembership(teamId: team, tournamentPlayerId: p.id),
            ClubEventTeamMembership(teamId: UUID(), tournamentPlayerId: p.id),
        ]}
        let pots = PayoutCalculator.pots(rules: rules, players: playerList, memberships: memberships)
        XCTAssertEqual(pots.grossSkins, 500)
        XCTAssertEqual(pots.teamNet,    300)
    }
}
