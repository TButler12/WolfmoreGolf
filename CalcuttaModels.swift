import Foundation

// MARK: - Models

struct CalcuttaEvent: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var createdAt: Date = Date()
    var teams: [CalcuttaTeam] = []
    var payoutRows: [CalcuttaPayoutRow] = []
    var day1Board: [CalcuttaLeaderboardEntry] = []
    var day2Board: [CalcuttaLeaderboardEntry] = []
    var bowWinner: String = ""

    var totalPot: Double { teams.reduce(0) { $0 + $1.bidAmount } }
}

struct CalcuttaTeam: Codable, Identifiable {
    var id: UUID = UUID()
    var teamName: String = ""
    var bidAmount: Double = 0
    var useCaptainOnly: Bool = true
    var captain: String = ""
    var players: [String] = ["", "", "", ""]
    var sortOrder: Int = 0
}

struct CalcuttaPayoutRow: Codable, Identifiable {
    var id: UUID = UUID()
    var label: String = ""
    var percentage: Double = 0
}

struct CalcuttaLeaderboardEntry: Codable {
    var teamName: String
    var points: Int?
}

// MARK: - Store

final class CalcuttaStore {
    static let shared = CalcuttaStore()
    private init() { load() }

    private(set) var events: [CalcuttaEvent] = []

    private static let udKey = "calcuttaEvents_v1"

    func save(_ event: CalcuttaEvent) {
        if let idx = events.firstIndex(where: { $0.id == event.id }) {
            events[idx] = event
        } else {
            events.insert(event, at: 0)
        }
        persist()
    }

    func delete(_ event: CalcuttaEvent) {
        events.removeAll { $0.id == event.id }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(data, forKey: Self.udKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.udKey),
              let decoded = try? JSONDecoder().decode([CalcuttaEvent].self, from: data)
        else { return }
        events = decoded
    }

    // MARK: - Tonight's event seed

    // Call once to pre-populate the 25-team roster. No-ops if an event with
    // this seed ID already exists (safe to call on every launch).
    func seedTonightsEventIfNeeded() {
        guard let seedID = UUID(uuidString: "4F7DA955-999D-4965-93CF-997D03075DB5") else { return }
        guard !events.contains(where: { $0.id == seedID }) else { return }

        let rosters: [(String, String, String, String)] = [
            ("Jeff Zanchelli",    "Nick Ruggio",       "Brad Skiba",        "Tim Schiewe"),
            ("Scott Blomquist",   "Josh Brown",         "Ed Spiegel",        "Joe Messer"),
            ("Brian Manczak",     "Kyle West",          "Balaji Rajan",      "Jon Cherry"),
            ("Pat Carroll",       "John Kainz",         "Michael Taege",     "Rob Sciddurlo"),
            ("Steve Muscarello",  "Dylan Yahn",         "Ed Fanslow",        "Don Pfingstler"),
            ("JP Talbot",         "Darren Dickson",     "Jim Roach",         "Kirk Hamilton"),
            ("Paul Guske",        "Dave Nolan",         "Sherman Shechtman", "Vito Quaranta"),
            ("Mark Childers",     "Cam Nisbet",         "Pat Buckstaff",     "Brian Hogan"),
            ("Kris Roy",          "Ross Hudson",        "Rick Sanders",      "Pat Gainer"),
            ("Doug Bauman",       "Jim Leitl",          "Mike Riley",        "Eric Speichinger"),
            ("Tim Nisbet",        "Andy Adler",         "Kevin McGee",       "John Kern"),
            ("Gavin Newman",      "Chris Karam",        "John Leider",       "Paul Holmes"),
            ("Jason Sfire",       "John Talbot",        "David Zorzy",       "Brian Murtha"),
            ("Pat Modig",         "Phil Fijal",         "Joe Holland",       "Nick Howard"),
            ("Tommy Nassif",      "Eric Lohmeyer",      "Ken Rojc",          "Greg Dowell"),
            ("Ryan Birch",        "John Valentine",     "Mike O'Toole",      "Alex Wodka"),
            ("Rick Herdrich",     "Jim Powell",         "Michael Daugherty", "Tom Butler"),
            ("Brian Blasius",     "Dan Hoeltgen",       "David Kenyon",      "Randy Marks"),
            ("Kris Jankowski",    "Brian Bulgarelli",   "Ed Soske",          "Rich Wulforst"),
            ("Brian Rosenburg",   "Jeff Boundy",        "Andrew Byrne",      "Steve Nuzzo"),
            ("Tim Chambers",      "Marv Husby",         "Tom Miller",        "Tim Rosenzweig"),
            ("John Lopez, Jr.",   "Vince Maestranzi",   "Ray Iardella",      "Don Minner"),
            ("Greg Tepas",        "Justin Pratt",       "Derek Cavaleri",    "Stan Pajerski"),
            ("Brian Paine",       "Tom Weyburn",        "Mike Seiffer",      "Jeff Murray"),
            ("Tom Uutala",        "Derek Hardy",        "Jason Lohmeyer",    "Chuck Dale"),
        ]

        var event = CalcuttaEvent(name: "Tonight's Calcutta")
        event.id = seedID
        event.teams = rosters.enumerated().map { (i, r) in
            CalcuttaTeam(
                teamName:      "Team \(i + 1)",
                bidAmount:     0,
                useCaptainOnly: false,
                captain:       "",
                players:       [r.0, r.1, r.2, r.3],
                sortOrder:     i
            )
        }
        save(event)
    }
}
