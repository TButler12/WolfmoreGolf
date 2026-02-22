//
//  CourseLibrary.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 12/28/25.
//
import Foundation

// =======================================================
// MARK: - Built-in default: Biltmore CC (18 pars + 18 HCs)
// =======================================================

let WOLFMORE_PARS: [Int] = [
    4,4,4,4,3,5,3,4,4,
    4,4,3,4,4,5,3,4,5
]

let WOLFMORE_HCS: [Int] = [
    4,8,14,10,16,2,18,6,12,
    11,3,15,1,13,7,17,9,5
]

//=======================================================
// MARK: - Built-in default: Cedar Rapids CC (Championship)
// =======================================================

private let CEDAR_RAPIDS_CC_ID = UUID(uuidString: "8A9C62C7-2D5E-4B6F-9B6D-4F1C2D7F0A11")!
private let WOLFMORE_CC_ID     = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

let CEDAR_RAPIDS_PARS: [Int] = [
    4,4,4,4,3,5,4,3,5,
    4,4,3,4,4,5,4,4,4
]

let CEDAR_RAPIDS_HCS: [Int] = [
    11,3,7,5,15,17,1,13,9,
    12,4,14,10,18,6,16,2,8
]

//=======================================================
// MARK: - Built-in: Wynstone GC (Silver)
//=======================================================

private let WYNSTONE_SILVER_ID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

let WYNSTONE_SILVER_PARS: [Int] = [
    4,4,5,3,4,4,3,4,5,
    4,3,5,4,3,4,4,4,5
]

let WYNSTONE_SILVER_HCS: [Int] = [
    18,10,2,14,6,4,16,12,8,
    1,17,7,15,13,3,11,5,9
]

//=======================================================
// MARK: - Built-in: Barrington Hills CC (White)
//=======================================================

private let BARRINGTON_HILLS_WHITE_ID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!

let BARRINGTON_HILLS_WHITE_PARS: [Int] = [
    5,4,4,4,4,4,4,3,4,
    4,3,4,4,5,3,4,4,4
]

let BARRINGTON_HILLS_WHITE_HCS: [Int] = [
    9,17,7,5,11,1,13,15,3,
    6,16,4,18,8,14,2,10,12
]

//=======================================================
// MARK: - Built-in: Crane's Landing GC (Blue)
//=======================================================

private let CRANES_LANDING_BLUE_ID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!

let CRANES_LANDING_BLUE_PARS: [Int] = [
    4,4,4,4,4,3,5,4,3,
    4,4,3,4,4,4,3,5,4
]

let CRANES_LANDING_BLUE_HCS: [Int] = [
    13,11,5,16,12,18,6,4,15,
    1,7,14,3,10,17,8,9,2
]

//=======================================================
// MARK: - Built-in: ChampionGate CC (Blended Black)
//=======================================================

private let CHAMPIONGATE_BLENDED_BLACK_ID = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!

let CHAMPIONGATE_BLENDED_BLACK_PARS: [Int] = [
    4,3,4,5,4,3,4,4,5,
    5,3,4,4,3,4,4,4,5
]

let CHAMPIONGATE_BLENDED_BLACK_HCS: [Int] = [
    7,15,3,1,11,17,13,9,5,
    14,18,2,10,16,6,8,4,12
]

//=======================================================
// MARK: - Built-in: Butler Country Club (Blue)
//=======================================================

private let BUTLER_CC_BLUE_ID = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!

let BUTLER_CC_BLUE_PARS: [Int] = [
    4,5,4,3,4,3,4,4,4,
    3,4,5,4,4,3,4,4,4
]

let BUTLER_CC_BLUE_HCS: [Int] = [
    3,9,5,17,11,15,7,13,1,
    12,14,6,4,8,16,18,2,10
]

//=======================================================
// MARK: - Built-in: Stonewall Orchard GC (Silver)
//=======================================================

private let STONEWALL_ORCHARD_SILVER_ID = UUID(uuidString: "77777777-7777-7777-7777-777777777777")!

let STONEWALL_ORCHARD_SILVER_PARS: [Int] = [
    4,4,5,4,3,4,4,5,3,
    5,4,4,3,4,4,4,3,5
]

let STONEWALL_ORCHARD_SILVER_HCS: [Int] = [
    15,3,17,5,7,1,9,13,11,
    10,6,16,12,8,4,14,18,2
]

//=======================================================
// MARK: - Built-in: Kemper Lakes GC (Green)
//=======================================================

private let KEMPER_LAKES_GREEN_ID = UUID(uuidString: "88888888-8888-8888-8888-888888888888")!

let KEMPER_LAKES_GREEN_PARS: [Int] = [
    4,4,3,5,4,3,5,4,4,
    4,5,4,3,4,5,4,3,4
]

let KEMPER_LAKES_GREEN_HCS: [Int] = [
    14,12,18,8,4,16,6,10,2,
    3,9,11,17,13,5,1,15,7
]

//=======================================================
// MARK: - Built-in: Rich Harvest Farms (Silver)
//=======================================================

private let RICH_HARVEST_SILVER_ID = UUID(uuidString: "99999999-9999-9999-9999-999999999999")!

let RICH_HARVEST_SILVER_PARS: [Int] = [
    4,5,3,4,3,4,5,4,4,
    4,5,3,4,4,4,3,4,4
]

let RICH_HARVEST_SILVER_HCS: [Int] = [
    10,14,18,2,16,4,8,12,6,
    9,5,15,17,13,3,11,1,7
]

//=======================================================
// MARK: - Built-in: Kohler (Placeholder)
// NOTE: Kohler has multiple courses (Whistling Straits / Blackwolf Run / etc.).
// If you want them separately, create one ID + pars/hcs per specific course.
//=======================================================

private let WHISTLING_STRAITS_STRAITS_ID = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!

let WHISTLING_STRAITS_STRAITS_PARS: [Int] = [
    4,5,3,4,5,4,3,4,4,
    4,5,3,4,4,4,5,3,4
] // :contentReference[oaicite:0]{index=0}

let WHISTLING_STRAITS_STRAITS_HCS: [Int] = [
    15,7,17,1,5,13,9,3,11,
    12,6,18,14,16,4,10,8,2
] // :contentReference[oaicite:1]{index=1}


// =======================================================
// MARK: - Built-in: Whistling Straits (Irish)
// =======================================================

private let WHISTLING_STRAITS_IRISH_ID = UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!

let WHISTLING_STRAITS_IRISH_PARS: [Int] = [
    4,4,3,4,5,3,4,5,4,
    4,3,4,3,5,4,4,4,5
] // :contentReference[oaicite:2]{index=2}

let WHISTLING_STRAITS_IRISH_HCS: [Int] = [
    4,6,18,2,14,16,12,10,8,
    5,15,13,17,11,1,3,7,9
] // :contentReference[oaicite:3]{index=3}


// =======================================================
// MARK: - Built-in: Blackwolf Run (River)
// =======================================================

private let BLACKWOLF_RUN_RIVER_ID = UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!

let BLACKWOLF_RUN_RIVER_PARS: [Int] = [
    5,4,4,3,4,4,4,5,4,
    3,5,4,3,4,4,5,3,4
] // :contentReference[oaicite:4]{index=4}

let BLACKWOLF_RUN_RIVER_HCS: [Int] = [
    5,13,1,15,3,17,7,9,11,
    14,6,2,10,16,18,8,12,4
] // :contentReference[oaicite:5]{index=5}


// =======================================================
// MARK: - Built-in: Blackwolf Run (Meadow Valleys)
// =======================================================

private let BLACKWOLF_RUN_MEADOW_VALLEYS_ID = UUID(uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD")!

let BLACKWOLF_RUN_MEADOW_VALLEYS_PARS: [Int] = [
    4,4,3,5,4,4,5,3,4,
    4,5,4,4,4,3,5,3,4
] // :contentReference[oaicite:6]{index=6}

let BLACKWOLF_RUN_MEADOW_VALLEYS_HCS: [Int] = [
    7,5,15,9,11,1,17,13,3,
    10,14,2,8,6,16,12,18,4
] // :contentReference[oaicite:7]{index=7}


// =======================================================
// MARK: - Built-in: Sand Valley (Sand Valley)
// =======================================================

private let SAND_VALLEY_ID = UUID(uuidString: "EEEEEEEE-EEEE-EEEE-EEEE-EEEEEEEEEEEE")!

let SAND_VALLEY_PARS: [Int] = [
    4,4,3,5,3,4,5,3,4,
    5,4,5,4,3,4,4,3,5
] // :contentReference[oaicite:8]{index=8}

let SAND_VALLEY_HCS: [Int] = [
    9,7,13,1,15,5,3,17,11,
    2,12,6,8,18,14,10,16,4
] // :contentReference[oaicite:9]{index=9}


// =======================================================
// MARK: - Built-in: Sand Valley (Mammoth Dunes)
// =======================================================

private let MAMMOTH_DUNES_ID = UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF")!

let MAMMOTH_DUNES_PARS: [Int] = [
    4,4,5,3,4,4,5,3,4,
    4,5,4,3,4,5,3,4,5
] // :contentReference[oaicite:10]{index=10}

let MAMMOTH_DUNES_HCS: [Int] = [
    11,9,3,15,5,13,1,17,7,
    12,4,8,18,14,6,16,10,2
] // :contentReference[oaicite:11]{index=11}
// =======================================================
// MARK: - Built-in: Troon North (Monument) — Scottsdale
// Source: ArizonaGolfer scorecard
// =======================================================

private let TROON_NORTH_MONUMENT_ID = UUID(uuidString: "0B8D8A31-7E7A-4C5B-9B40-7B0E3B9E5101")!

let TROON_NORTH_MONUMENT_PARS: [Int] = [
    4,3,5,4,4,4,3,4,5,
    4,5,4,3,5,4,3,4,3
]

let TROON_NORTH_MONUMENT_HCS: [Int] = [
    5,17,3,11,1,13,15,9,7,
    10,6,12,16,2,14,18,4,8
]

// =======================================================
// MARK: - Built-in: TPC Sawgrass (THE PLAYERS Stadium)
// Source: Golfify scorecard (SI + Par)
// =======================================================

private let TPC_SAWGRASS_STADIUM_ID = UUID(uuidString: "7D9F0A2B-6B7A-4D6E-8E0D-8A6A1E93C102")!

let TPC_SAWGRASS_STADIUM_PARS: [Int] = [
    4,5,3,4,4,4,4,3,5,
    4,5,4,3,4,4,5,3,4
]

let TPC_SAWGRASS_STADIUM_HCS: [Int] = [
    11,15,17,9,3,13,1,7,5,
    12,8,16,18,4,6,10,14,2
]

// =======================================================
// MARK: - Built-in: Bay Hill (Challenger/Champion) — Orlando
// Source: Golfify scorecard (SI + Par)
// =======================================================

private let BAY_HILL_CHALLENGER_CHAMPION_ID = UUID(uuidString: "2E6C1D5A-ACB6-4E47-9F09-2B7E0C52A203")!

let BAY_HILL_CHALLENGER_CHAMPION_PARS: [Int] = [
    4,3,4,5,4,5,3,4,4,
    4,4,5,4,3,4,5,3,4
]

let BAY_HILL_CHALLENGER_CHAMPION_HCS: [Int] = [
    1,3,5,7,9,11,13,15,17,
    2,4,6,8,10,12,14,16,18
]

// =======================================================
// MARK: - Built-in: Medinah CC (Course #3) — Illinois
// Source: Golfify scorecard (SI + Par)
// =======================================================

private let MEDINAH_CC_3_ID = UUID(uuidString: "9A1C0F37-9B11-4E2C-8D49-7A5A6E6F2404")!

let MEDINAH_CC_3_PARS: [Int] = [
    4,3,4,4,5,4,5,3,4,
    5,4,4,3,5,4,4,3,4
]

let MEDINAH_CC_3_HCS: [Int] = [
    1,3,5,7,9,11,13,15,17,
    2,4,6,8,10,12,14,16,18
]
// =======================================================
// MARK: - Built-in: Troon North (Pinnacle) — 2023 Scorecard
// =======================================================

private let TROON_NORTH_PINNACLE_ID = UUID(uuidString: "0E3D4F5A-8B8E-4C2F-A8B7-6A1E0B2C8C11")!

let TROON_NORTH_PINNACLE_PARS: [Int] = [
    4,4,4,4,5,3,4,3,4,
    4,5,4,3,5,4,3,4,4
] // :contentReference[oaicite:0]{index=0}

let TROON_NORTH_PINNACLE_HCS: [Int] = [
    9,7,3,11,5,17,1,15,13,
    10,8,12,16,2,14,18,4,6
] // :contentReference[oaicite:1]{index=1}


// =======================================================
// MARK: - Built-in: Streamsong (Blue)
// =======================================================

private let STREAMSONG_BLUE_ID = UUID(uuidString: "3B6D7A21-1F39-4E4A-8A4D-9B1E6C2A3D22")!

let STREAMSONG_BLUE_PARS: [Int] = [
    4,5,4,4,3,4,3,4,9,
    3,4,4,4,5,4,3,5,4
] // :contentReference[oaicite:2]{index=2}

let STREAMSONG_BLUE_HCS: [Int] = [
    14,10,8,4,16,18,12,2,6,
    13,1,11,15,9,5,17,7,3
] // :contentReference[oaicite:3]{index=3}


// =======================================================
// MARK: - Built-in: Streamsong (Red)
// NOTE: using GolfGenius scorecard listing (Par + Stroke Index)
// =======================================================

private let STREAMSONG_RED_ID = UUID(uuidString: "8D2B1C70-5A3B-4BE6-9B9F-1C4F0A6E7D33")!

let STREAMSONG_RED_PARS: [Int] = [
    4,5,4,4,4,3,5,3,4,
    4,4,4,5,3,4,3,4,5
] // :contentReference[oaicite:4]{index=4}

let STREAMSONG_RED_HCS: [Int] = [
    4,2,14,16,6,18,12,10,8,
    9,5,3,15,11,1,7,13,17
] // :contentReference[oaicite:5]{index=5}


// =======================================================
// MARK: - Built-in: Streamsong (Black)
// NOTE: using GolfGenius scorecard listing (Par + Stroke Index)
// =======================================================

private let STREAMSONG_BLACK_ID = UUID(uuidString: "C1A9E2D4-6F8A-4A64-9D1A-5D8B3E2A1F44")!

let STREAMSONG_BLACK_PARS: [Int] = [
    5,4,4,5,3,4,3,4,4,
    5,4,5,4,4,3,4,3,5
] // :contentReference[oaicite:6]{index=6}

let STREAMSONG_BLACK_HCS: [Int] = [
    12,16,4,2,6,18,14,8,10,
    11,3,7,9,15,17,1,13,5
] // //=======================================================
// MARK: - Built-in: PGA Village / PGA Golf Club (Port St. Lucie)
//=======================================================

private let PGA_VILLAGE_WANAMAKER_ID = UUID(uuidString: "A2F7E2D1-6D3C-4F2A-9D0C-2B5D8A8F1C10")!
private let PGA_VILLAGE_RYDER_ID     = UUID(uuidString: "B3C1A9F4-1E8B-4D77-8C2F-7A3F6D9B2E11")!
private let PGA_VILLAGE_DYE_ID       = UUID(uuidString: "C4D8B2A6-9A5E-4B6C-9E1A-1F7B3C5D4A12")!

// Wanamaker — PAR + Men's Handicap
let PGA_VILLAGE_WANAMAKER_PARS: [Int] = [
    5,4,4,3,4,3,5,4,4,
    4,3,4,5,4,4,5,3,4
]
let PGA_VILLAGE_WANAMAKER_HCS: [Int] = [
    11,1,7,13,17,15,5,9,3,
    6,18,10,8,2,14,16,12,4
]

// Ryder — PAR + Men's Handicap
let PGA_VILLAGE_RYDER_PARS: [Int] = [
    4,4,4,5,3,5,3,4,4,
    3,4,3,5,4,4,3,5,4
]
let PGA_VILLAGE_RYDER_HCS: [Int] = [
    3,7,5,15,17,11,9,13,1,
    8,12,18,16,14,2,10,6,4
]

// Dye — PAR + Men's Handicap
let PGA_VILLAGE_DYE_PARS: [Int] = [
    4,4,3,4,5,3,5,4,4,
    5,4,4,3,4,4,3,5,4
]
let PGA_VILLAGE_DYE_HCS: [Int] = [
    9,1,17,13,5,15,7,11,3,
    2,10,16,18,6,4,14,12,8
]
// ===============================================
// MARK: - Course model + tiny persistent library
// ===============================================

struct CourseProfile: Codable, Equatable {
    var id: UUID
    var name: String
    var pars: [Int]   // 18
    var hcs:  [Int]   // 18

    init(id: UUID = UUID(), name: String, pars: [Int], hcs: [Int]) {
        self.id = id
        self.name = name
        self.pars = Array(pars.prefix(18))
        self.hcs  = Array(hcs.prefix(18))
    }
}

final class CourseLibrary {
    static let shared = CourseLibrary()

    private let keyLibrary = "course.library.v1"
    private let keySeed    = "course.library.seeded.v1"

    private(set) var courses: [CourseProfile] = []

    private init() { load() }

    /// Seed / ensure built-in courses exist.
    /// - Important: We upsert built-ins EVERY launch so you can add more later
    ///   and existing users will still receive them.
    func seedIfNeeded() {

        upsertBuiltIn(
            CourseProfile(id: WOLFMORE_CC_ID, name: "WolfMore", pars: WOLFMORE_PARS, hcs: WOLFMORE_HCS)
        )
        upsertBuiltIn(
            CourseProfile(id: CEDAR_RAPIDS_CC_ID, name: "Cedar Rapids CC", pars: CEDAR_RAPIDS_PARS, hcs: CEDAR_RAPIDS_HCS)
        )
        upsertBuiltIn(
            CourseProfile(id: WYNSTONE_SILVER_ID, name: "Wynstone", pars: WYNSTONE_SILVER_PARS, hcs: WYNSTONE_SILVER_HCS)
        )
        upsertBuiltIn(
            CourseProfile(id: BARRINGTON_HILLS_WHITE_ID, name: "Barrington Hills", pars: BARRINGTON_HILLS_WHITE_PARS, hcs: BARRINGTON_HILLS_WHITE_HCS)
        )
        upsertBuiltIn(
            CourseProfile(id: CRANES_LANDING_BLUE_ID, name: "Crane's Landing", pars: CRANES_LANDING_BLUE_PARS, hcs: CRANES_LANDING_BLUE_HCS)
        )
        upsertBuiltIn(
            CourseProfile(id: CHAMPIONGATE_BLENDED_BLACK_ID, name: "Champions Gate", pars: CHAMPIONGATE_BLENDED_BLACK_PARS, hcs: CHAMPIONGATE_BLENDED_BLACK_HCS)
        )
        upsertBuiltIn(
            CourseProfile(id: BUTLER_CC_BLUE_ID, name: "Butler National", pars: BUTLER_CC_BLUE_PARS, hcs: BUTLER_CC_BLUE_HCS)
        )
        upsertBuiltIn(
            CourseProfile(id: STONEWALL_ORCHARD_SILVER_ID, name: "Stonewall Orchard", pars: STONEWALL_ORCHARD_SILVER_PARS, hcs: STONEWALL_ORCHARD_SILVER_HCS)
        )
        upsertBuiltIn(
            CourseProfile(id: KEMPER_LAKES_GREEN_ID, name: "Kemper Lakes", pars: KEMPER_LAKES_GREEN_PARS, hcs: KEMPER_LAKES_GREEN_HCS)
        )
        upsertBuiltIn(
            CourseProfile(id: RICH_HARVEST_SILVER_ID, name: "Rich Harvest Farms", pars: RICH_HARVEST_SILVER_PARS, hcs: RICH_HARVEST_SILVER_HCS)
        )

        upsertBuiltIn(CourseProfile(
            id: WHISTLING_STRAITS_STRAITS_ID,
            name: "Whistling Straits (Straits)",
            pars: WHISTLING_STRAITS_STRAITS_PARS,
            hcs:  WHISTLING_STRAITS_STRAITS_HCS
        ))

        upsertBuiltIn(CourseProfile(
            id: WHISTLING_STRAITS_IRISH_ID,
            name: "Whistling Straits (Irish)",
            pars: WHISTLING_STRAITS_IRISH_PARS,
            hcs:  WHISTLING_STRAITS_IRISH_HCS
        ))

        upsertBuiltIn(CourseProfile(
            id: BLACKWOLF_RUN_RIVER_ID,
            name: "Blackwolf Run (River)",
            pars: BLACKWOLF_RUN_RIVER_PARS,
            hcs:  BLACKWOLF_RUN_RIVER_HCS
        ))

        upsertBuiltIn(CourseProfile(
            id: BLACKWOLF_RUN_MEADOW_VALLEYS_ID,
            name: "Blackwolf Run (Meadow Valleys)",
            pars: BLACKWOLF_RUN_MEADOW_VALLEYS_PARS,
            hcs:  BLACKWOLF_RUN_MEADOW_VALLEYS_HCS
        ))

        upsertBuiltIn(CourseProfile(
            id: SAND_VALLEY_ID,
            name: "Sand Valley",
            pars: SAND_VALLEY_PARS,
            hcs:  SAND_VALLEY_HCS
        ))

        upsertBuiltIn(CourseProfile(
            id: MAMMOTH_DUNES_ID,
            name: "Mammoth Dunes",
            pars: MAMMOTH_DUNES_PARS,
            hcs:  MAMMOTH_DUNES_HCS
        ))
        upsertBuiltIn(CourseProfile(
            id: TROON_NORTH_MONUMENT_ID,
            name: "Troon North (Monument)",
            pars: TROON_NORTH_MONUMENT_PARS,
            hcs:  TROON_NORTH_MONUMENT_HCS
        ))

        upsertBuiltIn(CourseProfile(
            id: TPC_SAWGRASS_STADIUM_ID,
            name: "TPC Sawgrass (Stadium)",
            pars: TPC_SAWGRASS_STADIUM_PARS,
            hcs:  TPC_SAWGRASS_STADIUM_HCS
        ))

        upsertBuiltIn(CourseProfile(
            id: BAY_HILL_CHALLENGER_CHAMPION_ID,
            name: "Bay Hill (Challenger/Champion)",
            pars: BAY_HILL_CHALLENGER_CHAMPION_PARS,
            hcs:  BAY_HILL_CHALLENGER_CHAMPION_HCS
        ))

        upsertBuiltIn(CourseProfile(
            id: MEDINAH_CC_3_ID,
            name: "Medinah CC (Course #3)",
            pars: MEDINAH_CC_3_PARS,
            hcs:  MEDINAH_CC_3_HCS
        ))

        let u = UserDefaults.standard
        if !u.bool(forKey: keySeed) {
            u.set(true, forKey: keySeed)
        }
        upsertBuiltIn(CourseProfile(
            id: TROON_NORTH_PINNACLE_ID,
            name: "Troon North (Pinnacle)",
            pars: TROON_NORTH_PINNACLE_PARS,
            hcs:  TROON_NORTH_PINNACLE_HCS
        ))

        upsertBuiltIn(CourseProfile(
            id: STREAMSONG_RED_ID,
            name: "Streamsong (Red)",
            pars: STREAMSONG_RED_PARS,
            hcs:  STREAMSONG_RED_HCS
        ))

        upsertBuiltIn(CourseProfile(
            id: STREAMSONG_BLUE_ID,
            name: "Streamsong (Blue)",
            pars: STREAMSONG_BLUE_PARS,
            hcs:  STREAMSONG_BLUE_HCS
        ))

        upsertBuiltIn(CourseProfile(
            id: STREAMSONG_BLACK_ID,
            name: "Streamsong (Black)",
            pars: STREAMSONG_BLACK_PARS,
            hcs:  STREAMSONG_BLACK_HCS
        ))
        upsertBuiltIn(CourseProfile(
            id: PGA_VILLAGE_WANAMAKER_ID,
            name: "PGA Village (Wanamaker)",
            pars: PGA_VILLAGE_WANAMAKER_PARS,
            hcs:  PGA_VILLAGE_WANAMAKER_HCS
        ))

        upsertBuiltIn(CourseProfile(
            id: PGA_VILLAGE_RYDER_ID,
            name: "PGA Village (Ryder)",
            pars: PGA_VILLAGE_RYDER_PARS,
            hcs:  PGA_VILLAGE_RYDER_HCS
        ))

        upsertBuiltIn(CourseProfile(
            id: PGA_VILLAGE_DYE_ID,
            name: "PGA Village (Dye)",
            pars: PGA_VILLAGE_DYE_PARS,
            hcs:  PGA_VILLAGE_DYE_HCS
        ))
    }

    /// Built-in upsert rules:
    /// - If ID exists: overwrite name/pars/hcs (lets you ship corrections)
    /// - If same name exists with different ID: keep the existing ID (avoid duplicates),
    ///   but overwrite the data.
    /// - Else: append as new.
    private func upsertBuiltIn(_ c: CourseProfile) {
        if let i = courses.firstIndex(where: { $0.id == c.id }) {
            courses[i] = c
            save()
            return
        }

        if let j = courses.firstIndex(where: { $0.name.caseInsensitiveCompare(c.name) == .orderedSame }) {
            courses[j] = CourseProfile(id: courses[j].id, name: c.name, pars: c.pars, hcs: c.hcs)
            save()
            return
        }

        courses.append(c)
        save()
    }

    func allSorted() -> [CourseProfile] {
        courses.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func upsert(_ c: CourseProfile) {
        if let i = courses.firstIndex(where: { $0.id == c.id }) {
            courses[i] = c
        } else if let j = courses.firstIndex(where: {
            $0.name.caseInsensitiveCompare(c.name) == .orderedSame
        }) {
            courses[j] = CourseProfile(id: courses[j].id, name: c.name, pars: c.pars, hcs: c.hcs)
        } else {
            courses.append(c)
        }
        save()
    }

    func get(id: UUID) -> CourseProfile? { courses.first { $0.id == id } }

    func delete(id: UUID) {
        courses.removeAll { $0.id == id }
        save()
    }

    func wolfMore() -> CourseProfile? {
        courses.first { $0.name.caseInsensitiveCompare("WolfMore") == .orderedSame }
    }

    // MARK: - Persistence
    private func load() {
        let u = UserDefaults.standard
        guard let data = u.data(forKey: keyLibrary) else { return }
        courses = (try? JSONDecoder().decode([CourseProfile].self, from: data)) ?? []
    }

    private func save() {
        let u = UserDefaults.standard
        let data = (try? JSONEncoder().encode(courses)) ?? Data()
        u.set(data, forKey: keyLibrary)
    }

    private let keySelected = "course.selected.id.v1"

    var selectedCourseID: UUID? {
        get {
            guard let s = UserDefaults.standard.string(forKey: keySelected) else { return nil }
            return UUID(uuidString: s)
        }
        set {
            UserDefaults.standard.set(newValue?.uuidString, forKey: keySelected)
        }
    }

    var selectedCourseName: String? {
        guard let id = selectedCourseID else { return nil }
        return get(id: id)?.name
    }
}

extension CourseLibrary {

    private var builtInIDs: Set<UUID> {
        return [
            UUID(uuidString: "11111111-1111-1111-1111-111111111111")!, // WolfMore
            UUID(uuidString: "8A9C62C7-2D5E-4B6F-9B6D-4F1C2D7F0A11")!, // Cedar Rapids
            UUID(uuidString: "22222222-2222-2222-2222-222222222222")!, // Wynstone Silver
            UUID(uuidString: "33333333-3333-3333-3333-333333333333")!, // Barrington Hills White
            UUID(uuidString: "44444444-4444-4444-4444-444444444444")!, // Crane's Landing Blue
            UUID(uuidString: "55555555-5555-5555-5555-555555555555")!, // ChampionGate Blended Black
            UUID(uuidString: "66666666-6666-6666-6666-666666666666")!, // Butler CC Blue
            UUID(uuidString: "77777777-7777-7777-7777-777777777777")!, // Stonewall Orchard Silver
            UUID(uuidString: "88888888-8888-8888-8888-888888888888")!, // Kemper Lakes Green
            UUID(uuidString: "99999999-9999-9999-9999-999999999999")!, // Rich Harvest Silver

            UUID(uuidString: "C0B10E41-6A2E-4F3C-9B0B-3C6E0B2C5B01")!, // Whistling Straits (Straits)
            UUID(uuidString: "2A7C0D92-0F0D-4DA3-93B7-1E6B55DA6F02")!, // Whistling Straits (Irish)
            UUID(uuidString: "B4D7B9B5-01A8-4E58-8E1A-7C8D7E6C1F03")!, // Blackwolf Run (River)
            UUID(uuidString: "9D6D6A9B-9A1E-4C5A-A5F8-7F0A3D7B2E04")!, // Blackwolf Run (Meadow Valleys)
            UUID(uuidString: "7A2E2D6D-2AE0-45E3-A9A6-9E7D8B2D1A05")!, // Sand Valley
            UUID(uuidString: "F8B7E0B0-3C0B-4D9E-9A2B-7D2E5B6C3A06")!, // Mammoth Dunes
            UUID(uuidString: "0B8D8A31-7E7A-4C5B-9B40-7B0E3B9E5101")!, // Troon North (Monument)
            UUID(uuidString: "7D9F0A2B-6B7A-4D6E-8E0D-8A6A1E93C102")!, // TPC Sawgrass (Stadium)
            UUID(uuidString: "2E6C1D5A-ACB6-4E47-9F09-2B7E0C52A203")!, // Bay Hill (Challenger/Champion)
            UUID(uuidString: "9A1C0F37-9B11-4E2C-8D49-7A5A6E6F2404")!, // Medinah CC (Course #3)
            UUID(uuidString: "0E3D4F5A-8B8E-4C2F-A8B7-6A1E0B2C8C11")!, // Troon North (Pinnacle)
            UUID(uuidString: "8D2B1C70-5A3B-4BE6-9B9F-1C4F0A6E7D33")!, // Streamsong (Red)
            UUID(uuidString: "3B6D7A21-1F39-4E4A-8A4D-9B1E6C2A3D22")!, // Streamsong (Blue)
            UUID(uuidString: "C1A9E2D4-6F8A-4A64-9D1A-5D8B3E2A1F44")!, // Streamsong (Black)
            UUID(uuidString: "A2F7E2D1-6D3C-4F2A-9D0C-2B5D8A8F1C10")!, // PGA Village (Wanamaker)
            UUID(uuidString: "B3C1A9F4-1E8B-4D77-8C2F-7A3F6D9B2E11")!, // PGA Village (Ryder)
            UUID(uuidString: "C4D8B2A6-9A5E-4B6C-9E1A-1F7B3C5D4A12")!, // PGA Village (Dye)
        ]
    }

    func isBuiltIn(id: UUID) -> Bool {
        builtInIDs.contains(id)
    }
}
