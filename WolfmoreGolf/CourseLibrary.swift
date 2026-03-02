//
//  CourseLibrary.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 12/28/25.
//  Refactor: central built-in registry + looped seeding + derived builtInIDs
//
import Foundation

// =======================================================
// MARK: - Models
// =======================================================

struct TeeInfo: Codable, Equatable {
    var teeName: String
    var yardage: Int?
    var rating: Double?
    var slope: Int?

    init(teeName: String, yardage: Int? = nil, rating: Double? = nil, slope: Int? = nil) {
        self.teeName = teeName
        self.yardage = yardage
        self.rating = rating
        self.slope = slope
    }
}

struct CourseProfile: Codable, Equatable {
    var id: UUID
    var name: String
    var pars: [Int]   // 18
    var hcs:  [Int]   // 18
    var tees: [TeeInfo]? = nil

    // ✅ NEW (optional so old saved data still decodes)
    var country: String? = nil         // "USA", "Ireland", etc.
    var state: String? = nil           // "WI", "FL" (only for USA typically)

    init(
        id: UUID = UUID(),
        name: String,
        pars: [Int],
        hcs: [Int],
        tees: [TeeInfo]? = nil,
        country: String? = nil,
        state: String? = nil
    ) {
        self.id = id
        self.name = name
        self.pars = Array(pars.prefix(18))
        self.hcs  = Array(hcs.prefix(18))
        self.tees = tees
        self.country = country
        self.state = state
    }
}



// =======================================================
// MARK: - Built-in raw data (pars / hcs / optional tees)
// =======================================================

// MARK: WolfMore (Default)
private let WOLFMORE_CC_ID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
let WOLFMORE_PARS: [Int] = [4,4,4,4,3,5,3,4,4, 4,4,3,4,4,5,3,4,5]
let WOLFMORE_HCS:  [Int] = [4,8,14,10,16,2,18,6,12, 11,3,15,1,13,7,17,9,5]

// MARK: Cedar Rapids CC (Championship)
private let CEDAR_RAPIDS_CC_ID = UUID(uuidString: "8A9C62C7-2D5E-4B6F-9B6D-4F1C2D7F0A11")!
let CEDAR_RAPIDS_PARS: [Int] = [4,4,4,4,3,5,4,3,5, 4,4,3,4,4,5,4,4,4]
let CEDAR_RAPIDS_HCS:  [Int] = [11,3,7,5,15,17,1,13,9, 12,4,14,10,18,6,16,2,8]

// MARK: Wynstone GC (Silver)
private let WYNSTONE_SILVER_ID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
let WYNSTONE_SILVER_PARS: [Int] = [4,4,5,3,4,4,3,4,5, 4,3,5,4,3,4,4,4,5]
let WYNSTONE_SILVER_HCS:  [Int] = [18,10,2,14,6,4,16,12,8, 1,17,7,15,13,3,11,5,9]

// MARK: Barrington Hills CC (White)
private let BARRINGTON_HILLS_WHITE_ID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
let BARRINGTON_HILLS_WHITE_PARS: [Int] = [5,4,4,4,4,4,4,3,4, 4,3,4,4,5,3,4,4,4]
let BARRINGTON_HILLS_WHITE_HCS:  [Int] = [9,17,7,5,11,1,13,15,3, 6,16,4,18,8,14,2,10,12]

// MARK: Crane's Landing GC (Blue)
private let CRANES_LANDING_BLUE_ID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
let CRANES_LANDING_BLUE_PARS: [Int] = [4,4,4,4,4,3,5,4,3, 4,4,3,4,4,4,3,5,4]
let CRANES_LANDING_BLUE_HCS:  [Int] = [13,11,5,16,12,18,6,4,15, 1,7,14,3,10,17,8,9,2]

// MARK: ChampionsGate CC (Blended Black)
private let CHAMPIONGATE_BLENDED_BLACK_ID = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
let CHAMPIONGATE_BLENDED_BLACK_PARS: [Int] = [4,3,4,5,4,3,4,4,5, 5,3,4,4,3,4,4,4,5]
let CHAMPIONGATE_BLENDED_BLACK_HCS:  [Int] = [7,15,3,1,11,17,13,9,5, 14,18,2,10,16,6,8,4,12]

// MARK: Butler CC (Blue)
// MARK: Butler National (Blue)  — Par 71 (from your Blue card: 6,970 yds)
private let BUTLER_CC_BLUE_ID = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!

let BUTLER_CC_BLUE_PARS: [Int] = [
    4,5,4,3,4,3,4,4,4,   // OUT = 35
    3,4,5,4,4,3,5,4,4    // IN  = 36  ✅ hole 16 is 5
]
let BUTLER_CC_BLUE_HCS:  [Int] = [
    3,9,5,17,11,15,7,13,1,
    12,14,6,4,8,16,18,2,10
]
// Optional tee metadata you *do* have
let BUTLER_CC_BLUE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue", yardage: 6970, rating: nil, slope: nil)
]
// MARK: Butler National (BUTLER / Championship) — Oak Brook, IL
// Par 71 | 7,550 yds | Rating 78.4 | Slope 155
private let BUTLER_NATIONAL_BUTLER_TEE_ID = UUID(uuidString: "A6E1C1F2-4E2B-4C4C-9B1A-2B3C4D5E6F70")!

let BUTLER_NATIONAL_BUTLER_TEE_PARS: [Int] = [
    4,5,4,4,3,4,5,3,4,
    4,3,4,3,4,5,4,4,4
]

let BUTLER_NATIONAL_BUTLER_TEE_HCS: [Int] = [
    13,7,15,9,17,5,1,11,3,
    2,18,12,16,10,6,14,8,4
]

let BUTLER_NATIONAL_BUTLER_TEE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "BUTLER", yardage: 7550, rating: 78.4, slope: 155)
]
// MARK: Stonewall Orchard (Silver)
private let STONEWALL_ORCHARD_SILVER_ID = UUID(uuidString: "77777777-7777-7777-7777-777777777777")!
let STONEWALL_ORCHARD_SILVER_PARS: [Int] = [4,4,5,4,3,4,4,5,3, 5,4,4,3,4,4,4,3,5]
let STONEWALL_ORCHARD_SILVER_HCS:  [Int] = [15,3,17,5,7,1,9,13,11, 10,6,16,12,8,4,14,18,2]

// MARK: Kemper Lakes (Green)
private let KEMPER_LAKES_GREEN_ID = UUID(uuidString: "88888888-8888-8888-8888-888888888888")!
let KEMPER_LAKES_GREEN_PARS: [Int] = [4,4,3,5,4,3,5,4,4, 4,5,4,3,4,5,4,3,4]
let KEMPER_LAKES_GREEN_HCS:  [Int] = [14,12,18,8,4,16,6,10,2, 3,9,11,17,13,5,1,15,7]

// MARK: Rich Harvest Farms (Silver)
private let RICH_HARVEST_SILVER_ID = UUID(uuidString: "99999999-9999-9999-9999-999999999999")!
let RICH_HARVEST_SILVER_PARS: [Int] = [4,5,3,4,3,4,5,4,4, 4,5,3,4,4,4,3,4,4]
let RICH_HARVEST_SILVER_HCS:  [Int] = [10,14,18,2,16,4,8,12,6, 9,5,15,17,13,3,11,1,7]

// MARK: Kohler — Whistling Straits (Straits)
private let WHISTLING_STRAITS_STRAITS_ID = UUID(uuidString: "C0B10E41-6A2E-4F3C-9B0B-3C6E0B2C5B01")!
let WHISTLING_STRAITS_STRAITS_PARS: [Int] = [4,5,3,4,5,4,3,4,4, 4,5,3,4,4,4,5,3,4]
let WHISTLING_STRAITS_STRAITS_HCS:  [Int] = [15,7,17,1,5,13,9,3,11, 12,6,18,14,16,4,10,8,2]
let WHISTLING_STRAITS_STRAITS_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7790, rating: 77.2, slope: 152),
    TeeInfo(teeName: "Blue",  yardage: 7142, rating: 74.4, slope: 146),
    TeeInfo(teeName: "Green", yardage: 6663, rating: 72.0, slope: 140),
    TeeInfo(teeName: "White", yardage: 6360, rating: 70.5, slope: 136),
    TeeInfo(teeName: "Red",   yardage: 5564, rating: 67.3, slope: 127)
]

// MARK: Whistling Straits (Irish)
private let WHISTLING_STRAITS_IRISH_ID = UUID(uuidString: "2A7C0D92-0F0D-4DA3-93B7-1E6B55DA6F02")!
let WHISTLING_STRAITS_IRISH_PARS: [Int] = [4,4,3,4,5,3,4,5,4, 4,3,4,3,5,4,4,4,5]
let WHISTLING_STRAITS_IRISH_HCS:  [Int] = [4,6,18,2,14,16,12,10,8, 5,15,13,17,11,1,3,7,9]

// MARK: Blackwolf Run (River)
private let BLACKWOLF_RUN_RIVER_ID = UUID(uuidString: "B4D7B9B5-01A8-4E58-8E1A-7C8D7E6C1F03")!
let BLACKWOLF_RUN_RIVER_PARS: [Int] = [5,4,4,3,4,4,4,5,4, 3,5,4,3,4,4,5,3,4]
let BLACKWOLF_RUN_RIVER_HCS:  [Int] = [5,13,1,15,3,17,7,9,11, 14,6,2,10,16,18,8,12,4]

// MARK: Blackwolf Run (Meadow Valleys)
private let BLACKWOLF_RUN_MEADOW_VALLEYS_ID = UUID(uuidString: "9D6D6A9B-9A1E-4C5A-A5F8-7F0A3D7B2E04")!
let BLACKWOLF_RUN_MEADOW_VALLEYS_PARS: [Int] = [4,4,3,5,4,4,5,3,4, 4,5,4,4,4,3,5,3,4]
let BLACKWOLF_RUN_MEADOW_VALLEYS_HCS:  [Int] = [7,5,15,9,11,1,17,13,3, 10,14,2,8,6,16,12,18,4]

// MARK: Sand Valley (Sand Valley)
private let SAND_VALLEY_ID = UUID(uuidString: "7A2E2D6D-2AE0-45E3-A9A6-9E7D8B2D1A05")!
let SAND_VALLEY_PARS: [Int] = [4,4,3,5,3,4,5,3,4, 5,4,5,4,3,4,4,3,5]
let SAND_VALLEY_HCS:  [Int] = [9,7,13,1,15,5,3,17,11, 2,12,6,8,18,14,10,16,4]

// MARK: Sand Valley (Mammoth Dunes)
private let MAMMOTH_DUNES_ID = UUID(uuidString: "F8B7E0B0-3C0B-4D9E-9A2B-7D2E5B6C3A06")!
let MAMMOTH_DUNES_PARS: [Int] = [4,4,5,3,4,4,5,3,4, 4,5,4,3,4,5,3,4,5]
let MAMMOTH_DUNES_HCS:  [Int] = [11,9,3,15,5,13,1,17,7, 12,4,8,18,14,6,16,10,2]

// MARK: Troon North (Monument)
private let TROON_NORTH_MONUMENT_ID = UUID(uuidString: "0B8D8A31-7E7A-4C5B-9B40-7B0E3B9E5101")!
let TROON_NORTH_MONUMENT_PARS: [Int] = [4,3,5,4,4,4,3,4,5, 4,5,4,3,5,4,3,4,3]
let TROON_NORTH_MONUMENT_HCS:  [Int] = [5,17,3,11,1,13,15,9,7, 10,6,12,16,2,14,18,4,8]

// MARK: TPC Sawgrass (Stadium)
private let TPC_SAWGRASS_STADIUM_ID = UUID(uuidString: "7D9F0A2B-6B7A-4D6E-8E0D-8A6A1E93C102")!
let TPC_SAWGRASS_STADIUM_PARS: [Int] = [4,5,3,4,4,4,4,3,5, 4,5,4,3,4,4,5,3,4]
let TPC_SAWGRASS_STADIUM_HCS:  [Int] = [11,15,17,9,3,13,1,7,5, 12,8,16,18,4,6,10,14,2]

// MARK: Bay Hill (Challenger/Champion)
private let BAY_HILL_CHALLENGER_CHAMPION_ID = UUID(uuidString: "2E6C1D5A-ACB6-4E47-9F09-2B7E0C52A203")!
let BAY_HILL_CHALLENGER_CHAMPION_PARS: [Int] = [4,3,4,5,4,5,3,4,4, 4,4,5,4,3,4,5,3,4]
let BAY_HILL_CHALLENGER_CHAMPION_HCS:  [Int] = [9,11,5,1,15,13,17,3,7, 12,4,10,14,18,6,2,16,8]
let BAY_HILL_CHALLENGER_CHAMPION_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Green", yardage: 7409, rating: 76.4, slope: 138)
]

// MARK: Medinah CC (Course #3) — Gold  ✅ RE-ADDED
private let MEDINAH_CC_3_ID = UUID(uuidString: "9A1C0F37-9B11-4E2C-8D49-7A5A6E6F2404")!
let MEDINAH_CC_3_PARS: [Int] = [4,3,4,4,5,4,5,4,4, 5,3,4,3,4,4,4,3,5]
let MEDINAH_CC_3_HCS:  [Int] = [13,15,11,3,5,7,1,17,9, 2,16,8,14,10,4,12,18,6]
let MEDINAH_CC_3_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Gold", yardage: 7564, rating: 76.8, slope: 143)
]

// MARK: Troon North (Pinnacle)
private let TROON_NORTH_PINNACLE_ID = UUID(uuidString: "0E3D4F5A-8B8E-4C2F-A8B7-6A1E0B2C8C11")!
let TROON_NORTH_PINNACLE_PARS: [Int] = [4,4,4,4,5,3,4,3,4, 4,5,4,3,5,4,3,4,4]
let TROON_NORTH_PINNACLE_HCS:  [Int] = [9,7,3,11,5,17,1,15,13, 10,8,12,16,2,14,18,4,6]

// MARK: Streamsong (Blue/Red/Black)
private let STREAMSONG_BLUE_ID = UUID(uuidString: "3B6D7A21-1F39-4E4A-8A4D-9B1E6C2A3D22")!
let STREAMSONG_BLUE_PARS: [Int] = [4,5,4,4,3,4,3,4,5, 3,4,4,4,5,4,3,5,4]
let STREAMSONG_BLUE_HCS:  [Int] = [14,10,8,4,16,18,12,2,6, 13,1,11,15,9,5,17,7,3]

private let STREAMSONG_RED_ID = UUID(uuidString: "8D2B1C70-5A3B-4BE6-9B9F-1C4F0A6E7D33")!
let STREAMSONG_RED_PARS: [Int] = [4,5,4,4,4,3,5,3,4, 4,4,4,5,3,4,3,4,5]
let STREAMSONG_RED_HCS:  [Int] = [4,2,14,16,6,18,12,10,8, 9,5,3,15,11,1,7,13,17]

private let STREAMSONG_BLACK_ID = UUID(uuidString: "C1A9E2D4-6F8A-4A64-9D1A-5D8B3E2A1F44")!
let STREAMSONG_BLACK_PARS: [Int] = [5,4,4,5,3,4,3,4,4, 5,4,5,4,4,3,4,3,5]
let STREAMSONG_BLACK_HCS:  [Int] = [12,16,4,2,6,18,14,8,10, 11,3,7,9,15,17,1,13,5]

// MARK: PGA Village (Wanamaker/Ryder/Dye)
private let PGA_VILLAGE_WANAMAKER_ID = UUID(uuidString: "A2F7E2D1-6D3C-4F2A-9D0C-2B5D8A8F1C10")!
private let PGA_VILLAGE_RYDER_ID     = UUID(uuidString: "B3C1A9F4-1E8B-4D77-8C2F-7A3F6D9B2E11")!
private let PGA_VILLAGE_DYE_ID       = UUID(uuidString: "C4D8B2A6-9A5E-4B6C-9E1A-1F7B3C5D4A12")!

let PGA_VILLAGE_WANAMAKER_PARS: [Int] = [5,4,4,3,4,3,5,4,4, 4,3,4,5,4,4,5,3,4]
let PGA_VILLAGE_WANAMAKER_HCS:  [Int] = [11,1,7,13,17,15,5,9,3, 6,18,10,8,2,14,16,12,4]

let PGA_VILLAGE_RYDER_PARS: [Int] = [4,4,4,5,3,5,3,4,4, 3,4,3,5,4,4,3,5,4]
let PGA_VILLAGE_RYDER_HCS:  [Int] = [3,7,5,15,17,11,9,13,1, 8,12,18,16,14,2,10,6,4]

let PGA_VILLAGE_DYE_PARS: [Int] = [4,4,3,4,5,3,5,4,4, 5,4,4,3,4,4,3,5,4]
let PGA_VILLAGE_DYE_HCS:  [Int] = [9,1,17,13,5,15,7,11,3, 2,10,16,18,6,4,14,12,8]

// MARK: Pebble / Spyglass
private let PEBBLE_BEACH_ID = UUID(uuidString: "A11D2B8E-9E53-4F68-9C31-1E2D7C6A0B91")!
let PEBBLE_BEACH_PARS: [Int] = [4,5,4,4,3,5,3,4,4, 4,4,3,4,5,4,4,3,5]
let PEBBLE_BEACH_HCS:  [Int] = [6,10,12,16,14,2,18,4,8, 3,9,17,7,1,13,11,15,5]

private let SPYGLASS_HILL_ID = UUID(uuidString: "B22C3D9F-5A2B-4B1A-8C4D-2A6F4E1D7C02")!
let SPYGLASS_HILL_PARS: [Int] = [5,4,3,4,3,4,5,4,4, 4,5,3,4,5,3,4,4,4]
let SPYGLASS_HILL_HCS:  [Int] = [3,13,17,9,15,7,11,1,5, 12,10,16,4,6,18,2,14,8]

// MARK: Bandon set
private let BANDON_DUNES_ID  = UUID(uuidString: "C33E4A10-7C9E-4D7A-9B10-3F2A1E6D8B73")!
private let PACIFIC_DUNES_ID = UUID(uuidString: "D44F5B21-9D0C-4C3E-8A77-4B2C6D1E9F14")!
private let BANDON_TRAILS_ID = UUID(uuidString: "E55A6C32-1B2D-4E5F-9C88-5C3D7E2F0A25")!
private let OLD_MACDONALD_ID = UUID(uuidString: "F66B7D43-2C3E-4F60-8D99-6D4E8F301B36")!
private let SHEEP_RANCH_ID   = UUID(uuidString: "0A7C8E54-3D4F-4A71-9EAA-7E5F9032C447")!

let BANDON_DUNES_PARS: [Int] = [4,3,5,4,4,3,4,4,5, 4,4,3,5,4,3,4,4,5]
let BANDON_DUNES_HCS:  [Int] = [13,15,3,5,1,17,7,11,9, 8,2,18,6,16,14,10,12,4]

let PACIFIC_DUNES_PARS: [Int] = [4,4,5,4,3,4,4,4,4, 3,3,5,4,3,5,4,3,5]
let PACIFIC_DUNES_HCS:  [Int] = [9,11,7,3,17,13,1,5,15, 14,18,6,2,16,10,12,8,4]

let BANDON_TRAILS_PARS: [Int] = [4,3,5,4,3,4,4,4,5, 4,4,3,4,4,4,5,3,4]
let BANDON_TRAILS_HCS:  [Int] = [13,17,3,5,15,9,7,11,1, 10,4,18,12,14,8,2,16,6]

let OLD_MACDONALD_PARS: [Int] = [4,3,4,4,3,5,4,3,4, 4,4,3,4,4,5,4,5,4]
let OLD_MACDONALD_HCS:  [Int] = [11,15,9,1,17,3,5,13,7, 6,4,16,18,14,12,2,10,8]

let SHEEP_RANCH_PARS: [Int] = [5,4,3,4,3,4,3,4,4, 4,5,4,5,4,4,3,4,5]
let SHEEP_RANCH_HCS:  [Int] = [5,13,17,3,11,1,15,7,9, 6,4,2,10,8,14,16,12,18]
// MARK: The Bear's Club (Champion) — Jupiter, FL
private let BEARS_CLUB_CHAMPION_ID = UUID(uuidString: "6E4C2E1B-8D3B-4A4D-9E6A-7F8B2C1D0A91")!

let BEARS_CLUB_CHAMPION_PARS: [Int] = [
    4,3,4,5,4,4,3,5,4,
    5,4,4,4,3,4,3,4,5
]
let BEARS_CLUB_CHAMPION_HCS: [Int] = [
    5,15,3,11,9,1,17,13,7,
    14,2,12,10,16,4,18,6,8
]
let BEARS_CLUB_CHAMPION_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Champion", yardage: 7212, rating: 76.2, slope: 151)
]
// MARK: The Bear's Club (Championship) — Jupiter, FL
private let BEARS_CLUB_CHAMPIONSHIP_ID = UUID(uuidString: "1C2A7B3E-4D5F-4A3B-9E10-8D6A2F7C9B55")!

let BEARS_CLUB_CHAMPIONSHIP_PARS: [Int] = [
    4,3,4,5,4,4,3,5,4,
    5,4,4,4,3,4,3,4,5
]
// From your 7,328-yard “Championship” table
let BEARS_CLUB_CHAMPIONSHIP_HCS: [Int] = [
    7,13,5,9,1,3,15,17,11,
    18,2,14,4,12,8,10,6,16
]
let BEARS_CLUB_CHAMPIONSHIP_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 7328, rating: nil, slope: nil)
]
// MARK: Adare Manor
private let ADARE_MANOR_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000001")!
let ADARE_MANOR_PARS: [Int] = [4,4,4,5,4,3, 5,4,4, 4,5,4, 3,4,4, 5,3,4]
let ADARE_MANOR_HCS:  [Int] = [9,3,13,1,11,15, 5,7,17, 12,8,16, 18,4,14, 2,6,10]

// MARK: Ballybunion (Old Course)
private let BALLYBUNION_OLD_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000002")!
let BALLYBUNION_OLD_PARS: [Int] = [4,4,4,5,3,4, 4,3,5, 4,4,3, 4,5,4, 4,3,5]
let BALLYBUNION_OLD_HCS:  [Int] = [9,15,1,5,17,7, 11,13,3, 8,10,2, 14,12,4, 18,16,6]


// MARK: Geneva National – Palmer
private let GENEVA_NATIONAL_PALMER_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000004")!
let GENEVA_NATIONAL_PALMER_PARS: [Int] = [4,4,3,5,4,4, 5,3,4, 4,4,4, 3,5,4, 3,5,4]
let GENEVA_NATIONAL_PALMER_HCS:  [Int] = [17,13,5,7,3,11, 1,9,15, 6,2,8, 18,10,14, 16,4,12]

// MARK: Geneva National – Trevino
private let GENEVA_NATIONAL_TREVINO_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000005")!
let GENEVA_NATIONAL_TREVINO_PARS: [Int] = [4,4,3,4,5,3, 4,5,4, 5,4,4, 3,4,4, 5,3,4]
let GENEVA_NATIONAL_TREVINO_HCS:  [Int] = [7,15,17,5,1,13, 11,3,9, 8,10,16, 12,4,6, 2,18,14]

// MARK: Grand Geneva – The Highlands
private let GRAND_GENEVA_HIGHLANDS_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000006")!
let GRAND_GENEVA_HIGHLANDS_PARS: [Int] = [4,5,4,3,4,5, 3,4,4, 4,5,3, 4,4,4, 4,3,4]
let GRAND_GENEVA_HIGHLANDS_HCS:  [Int] = [11,5,9,15,7,1, 17,13,3, 14,2,16, 10,6,12, 4,18,8]

// MARK: Harbour Town Golf Links
private let HARBOUR_TOWN_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000007")!
let HARBOUR_TOWN_PARS: [Int] = [4,3,4,4,3,5, 4,3,4, 4,5,3, 4,4,3, 4,4,4]
let HARBOUR_TOWN_HCS:  [Int] = [5,17,9,1,15,7, 11,13,3, 10,2,18, 12,6,16, 14,8,4]

// MARK: Long Cove Club (Gold)
private let LONG_COVE_GOLD_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000008")!
let LONG_COVE_GOLD_PARS: [Int] = [4,3,5,4,4,5, 4,3,4, 4,4,4, 3,4,5, 4,3,4]
let LONG_COVE_GOLD_HCS:  [Int] = [7,17,1,11,13,5, 3,15,9, 12,10,4, 18,2,8, 14,16,6]
// MARK: Pinehurst No. 2 (U.S. Open) — Pinehurst, NC
private let PINEHURST_NO2_USOPEN_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000021")!
let PINEHURST_NO2_USOPEN_PARS: [Int] = [
    4,4,4,4,3,5,4,3,4,
    4,3,4,4,5,3,4,3,4
]
let PINEHURST_NO2_USOPEN_HCS: [Int] = [
    7,3,11,15,17,1,5,13,9,
    2,16,10,6,4,14,12,18,8
]
// MARK: ç
private let MEDALIST_JT_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000009")!
let MEDALIST_JT_PARS: [Int] = [4,4,5,3,4,4,5,3,4,4,4,3,5,4,4,3,5,4]
let MEDALIST_JT_HCS:  [Int] = [13,1,5, 17,9,11,7,15,3,6,16,18,4,12,2,14,10,8]

// MARK: Brook Hollow Golf Club — Tillinghast — Dallas, TX
// Par 70 | 7,087 yds | Rating 75.2 | Slope 139
private let BROOK_HOLLOW_TILLINGHAST_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000003")!

let BROOK_HOLLOW_TILLINGHAST_PARS: [Int] = [
    4,4,4,3,5,4,4,3,4,   // OUT = 35
    3,4,4,4,4,5,3,4,4    // IN  = 35
]

let BROOK_HOLLOW_TILLINGHAST_HCS: [Int] = [
    5,15,7,17,1,9,3,13,11,
    18,6,4,16,8,2,14,10,12
]

let BROOK_HOLLOW_TILLINGHAST_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Tillinghast", yardage: 7087, rating: 75.2, slope: 139)
]
// MARK: Scottsdale National GC — X-Tee (Scottsdale, AZ)
// Par 72 | 7,347 yds | Rating 74.1 | Slope 140

private let SCOTTSDALE_NATIONAL_XTEE_ID =
    UUID(uuidString: "A6666666-6666-6666-6666-666666666666")!

let SCOTTSDALE_NATIONAL_XTEE_PARS: [Int] = [
    4,5,3,5,4,3,4,5,3,
    5,3,4,3,4,5,3,4,5
]

let SCOTTSDALE_NATIONAL_XTEE_HCS: [Int] = [
    11,3,15,9,7,13,5,1,17,
    6,18,14,16,8,2,12,10,4
]

let SCOTTSDALE_NATIONAL_XTEE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "X-Tee",
            yardage: 7347,
            rating: 74.1,
            slope: 140)
]
// =======================================================
// MARK: - Barrington / Cary, IL (BlueGolf)
// =======================================================

// MARK: Makray Memorial (Black) — Barrington, IL
// Par 71 • 6,878 yds • 74.2 / 138
private let MAKRAY_MEMORIAL_BLACK_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000022")!

let MAKRAY_MEMORIAL_BLACK_PARS: [Int] = [
    4,4,4,3,4,5,3,4,4,
    4,4,4,3,4,5,4,3,5
]
let MAKRAY_MEMORIAL_BLACK_HCS: [Int] = [
    13,3,11,7,5,9,15,17,1,
    4,2,14,16,12,6,8,18,10
]
let MAKRAY_MEMORIAL_BLACK_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6878, rating: 74.2, slope: 138)
]

// MARK: Lake Barrington Shores (Black) — Barrington, IL
// Par 71 • 6,673 yds • 72.1 / 137
private let LAKE_BARRINGTON_SHORES_BLACK_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000023")!

let LAKE_BARRINGTON_SHORES_BLACK_PARS: [Int] = [
    4,5,4,4,3,4,4,3,4,
    4,5,4,3,5,4,3,4,4
]
let LAKE_BARRINGTON_SHORES_BLACK_HCS: [Int] = [
    15,1,11,3,5,9,13,7,17,
    12,4,14,16,2,10,18,6,8
]
let LAKE_BARRINGTON_SHORES_BLACK_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6673, rating: 72.1, slope: 137)
]

// MARK: Foxford Hills (Black) — Cary, IL
// Par 72 • 7,047 yds • 74.6 / 142
private let FOXFORD_HILLS_BLACK_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000024")!

let FOXFORD_HILLS_BLACK_PARS: [Int] = [
    4,5,3,4,4,5,4,3,4,
    5,4,4,3,4,5,4,3,4
]
let FOXFORD_HILLS_BLACK_HCS: [Int] = [
    13,3,9,15,7,1,11,17,5,
    6,12,14,18,10,2,8,16,4
]
let FOXFORD_HILLS_BLACK_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7047, rating: 74.6, slope: 142)
]

// MARK: Cary CC (Blue) — Cary, IL
// Par 72 • 6,247 yds • 70.1 / 125
private let CARY_CC_BLUE_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000025")!

let CARY_CC_BLUE_PARS: [Int] = [
    5,4,4,3,4,3,5,4,5,
    4,4,3,5,3,4,4,4,4
]
let CARY_CC_BLUE_HCS: [Int] = [
    7,11,13,15,5,17,1,9,3,
    8,14,18,2,16,12,6,4,10
]
let CARY_CC_BLUE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue", yardage: 6247, rating: 70.1, slope: 125)
]

// MARK: Chalet Hills (Black) — Cary, IL
// Par 73 • 6,898 yds • 73.8 / 140
private let CHALET_HILLS_BLACK_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000026")!

let CHALET_HILLS_BLACK_PARS: [Int] = [
    4,4,5,3,4,3,5,4,4,
    4,5,4,3,4,5,4,3,5
]
let CHALET_HILLS_BLACK_HCS: [Int] = [
    9,11,5,15,1,17,3,13,7,
    12,4,10,16,6,2,14,18,8
]
let CHALET_HILLS_BLACK_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6898, rating: 73.8, slope: 140)
]
// MARK: Old Head Golf Links
private let OLD_HEAD_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000010")!
let OLD_HEAD_PARS: [Int] = [4,4,5,3,4,4, 5,4,4, 4,5,3, 4,5,3, 4,4,4]
let OLD_HEAD_HCS:  [Int] = [11,7,13,1,15,5, 3,17,9, 2,12,8, 14,4,10, 6,18,16]

// MARK: Royal County Down (Championship)
private let ROYAL_COUNTY_DOWN_CHAMP_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000011")!
let ROYAL_COUNTY_DOWN_CHAMP_PARS: [Int] = [4,5,3,4,4,3, 5,4,4, 4,4,4, 3,5,4, 4,4,5]
let ROYAL_COUNTY_DOWN_CHAMP_HCS:  [Int] = [9,1,17,5,3,15, 7,11,13, 14,2,10, 16,12,6, 8,18,4]

// MARK: Royal Oaks CC (Scheffler)
private let ROYAL_OAKS_SCHEFFLER_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000012")!
let ROYAL_OAKS_SCHEFFLER_PARS: [Int] = [4,4,4,3,5,4,4,3,4,4,4,3,4,5,4,3,4,5]
let ROYAL_OAKS_SCHEFFLER_HCS:  [Int] = [6,8,2,16,10,12,4,18,14,5,3,17, 1,11,13,15,9,7]

// MARK: Royal Portrush (Dunluce)
private let ROYAL_PORTRUSH_DUNLUCE_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000013")!
let ROYAL_PORTRUSH_DUNLUCE_PARS: [Int] = [4,5,3,4,4,3, 5,4,4, 4,4,4, 3,5,4, 4,4,5]
let ROYAL_PORTRUSH_DUNLUCE_HCS:  [Int] = [15,7,17,1,5,13, 9,3,11, 12,6,18, 14,16,4, 10,8,2]

// MARK: Summit Club (Morikawa)
private let SUMMIT_CLUB_MORIKAWA_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000014")!
let SUMMIT_CLUB_MORIKAWA_PARS: [Int] = [5,4,4,4,3,5,4,3,4, 4,4,3,5,4,5,3,4,4]
let SUMMIT_CLUB_MORIKAWA_HCS:  [Int] = [15,13,1,9,11,7,5,17,3,18,14,12,10,8,2,16,4,6]

// MARK: Waterville Golf Links
private let WATERVILLE_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000015")!
let WATERVILLE_PARS: [Int] = [4,4,3,5,4,4, 5,3,4, 4,5,4, 4,3,4, 4,4,5]
let WATERVILLE_HCS:  [Int] = [13,5,17,3,11,1, 15,7,9, 6,2,14, 16,10,8, 18,12,4]

// =======================================================
// MARK: - ADD THESE BUILT-INS (from your screenshots)
// =======================================================

// MARK: Esker Hills Golf Club
private let ESKER_HILLS_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000016")!
let ESKER_HILLS_PARS: [Int] = [
    5,4,4,4,3,5,
    4,4,3,
    4,4,4,
    3,4,3,
    5,4,4
]
let ESKER_HILLS_HCS: [Int] = [
    17,11,1,5,15,9,
    3,13,7,
    18,4,6,
    14,10,8,
    16,2,12
]

// MARK: Geneva National – Player
private let GENEVA_NATIONAL_PLAYER_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000017")!
let GENEVA_NATIONAL_PLAYER_PARS: [Int] = [
    4,5,4,3,4,3,
    4,5,4,
    5,4,4,
    3,5,3,
    5,3,4
]
let GENEVA_NATIONAL_PLAYER_HCS: [Int] = [
    15,1,7,17,13,11,
    9,3,5,
    2,8,4,
    10,18,12,
    14,16,6
]

// MARK: Grand Geneva – The Brute
private let GRAND_GENEVA_BRUTE_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000018")!
let GRAND_GENEVA_BRUTE_PARS: [Int] = [
    4,5,4,3,4,5,
    4,3,4,
    4,5,4,
    3,4,5,
    3,4,4
]
let GRAND_GENEVA_BRUTE_HCS: [Int] = [
    7,3,9,15,11,1,
    13,17,5,
    8,4,12,
    18,14,2,
    16,10,6
]

// MARK: Heron Point (Gold) — Sea Pines
private let HERON_POINT_GOLD_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000019")!
let HERON_POINT_GOLD_PARS: [Int] = [
    4,4,3,5,4,5,
    4,3,4,
    4,3,5,
    3,4,4,
    3,5,4
]
let HERON_POINT_GOLD_HCS: [Int] = [
    7,5,17,9,11,3,
    15,13,1,
    10,14,12,
    8,6,16,
    18,2,4
]

// MARK: Pine Valley
private let PINE_VALLEY_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000020")!
let PINE_VALLEY_PARS: [Int] = [
    4,4,3,4,4,3,
    5,4,3,
    4,4,5,
    3,4,5,
    4,3,4
]
let PINE_VALLEY_HCS: [Int] = [
    9,1,15,11,3,17,
    5,7,13,
    10,2,6,
    18,4,8,
    12,16,14]
// MARK: Panther National (JT) — Palm Beach Gardens, FL
// Par 72 | 7,864 yds | Rating 78.7 | Slope 147
private let PANTHER_NATIONAL_JT_ID = UUID(uuidString: "3F2B65E1-9E5F-4B8F-A15B-8B71B98A4D21")!

let PANTHER_NATIONAL_JT_PARS: [Int] = [
    4,3,5,4,4,4,5,3,4,
    4,5,4,3,4,3,4,5,4
]

let PANTHER_NATIONAL_JT_HCS: [Int] = [
    15,11,9,1,5,13,7,17,3,
    10,4,8,16,2,14,18,12,6
]

let PANTHER_NATIONAL_JT_TEES: [TeeInfo] = [
    TeeInfo(teeName: "JT", yardage: 7864, rating: 78.7, slope: 147)
]


// MARK: PGA National Resort & Spa – The Champion (BEAR) — Palm Beach Gardens, FL
// Par 72 | 7,081 yds | Rating 75.4 | Slope 144
private let PGA_NATIONAL_CHAMPION_BEAR_ID = UUID(uuidString: "A9C4D88D-AC64-4D8E-8C68-32C6E0B3D4F9")!

let PGA_NATIONAL_CHAMPION_BEAR_PARS: [Int] = [
    4,4,5,4,3,5,3,4,4,
    5,4,4,4,4,3,4,3,5
]

let PGA_NATIONAL_CHAMPION_BEAR_HCS: [Int] = [
    11,3,7,13,17,1,15,9,5,
    6,4,8,12,10,18,14,16,2
]

let PGA_NATIONAL_CHAMPION_BEAR_TEES: [TeeInfo] = [
    TeeInfo(teeName: "BEAR", yardage: 7081, rating: 75.4, slope: 144)
]
//

// MARK: Sea Island Retreat — Red (St Simons Island, GA)
// Par 72 | 7,110 yds | Rating 73.9 | Slope 133
private let SEA_ISLAND_RETREAT_RED_ID = UUID(uuidString: "A1111111-1111-1111-1111-111111111111")!

let SEA_ISLAND_RETREAT_RED_PARS: [Int] = [
    5,4,3,4,4,4,3,5,4,
    5,4,3,4,4,4,3,5,4
]
let SEA_ISLAND_RETREAT_RED_HCS: [Int] = [
    13,5,11,1,7,17,15,9,3,
    16,6,14,8,2,10,18,12,4
]
let SEA_ISLAND_RETREAT_RED_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Red", yardage: 7110, rating: 73.9, slope: 133)
]

// MARK: Dye Preserve — Championship (Jupiter, FL)
// Par 72 | 7,312 yds | Rating 75.9 | Slope 146
private let DYE_PRESERVE_CHAMPIONSHIP_ID = UUID(uuidString: "A2222222-2222-2222-2222-222222222222")!

let DYE_PRESERVE_CHAMPIONSHIP_PARS: [Int] = [
    5,4,3,4,4,5,3,4,4,
    5,4,4,3,4,5,4,3,4
]
let DYE_PRESERVE_CHAMPIONSHIP_HCS: [Int] = [
    7,13,11,1,15,5,17,9,3,
    8,2,10,12,16,6,18,14,4
]
let DYE_PRESERVE_CHAMPIONSHIP_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 7312, rating: 75.9, slope: 146)
]

// MARK: Whisper Rock — Upper Course — Rock (Scottsdale, AZ)
// Par 72 | 7,550 yds | Rating 75.9 | Slope 146
private let WHISPER_ROCK_UPPER_ROCK_ID = UUID(uuidString: "A3333333-3333-3333-3333-333333333333")!

let WHISPER_ROCK_UPPER_ROCK_PARS: [Int] = [
    4,4,3,4,5,4,4,3,5,
    4,3,5,4,3,4,5,4,4
]
let WHISPER_ROCK_UPPER_ROCK_HCS: [Int] = [
    6,4,18,14,10,2,12,16,8,
    3,13,7,17,15,1,9,11,5
]
let WHISPER_ROCK_UPPER_ROCK_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Rock", yardage: 7550, rating: 75.9, slope: 146)
]

// MARK: Silverleaf GC — Silver (Scottsdale, AZ)
// Par 72 | 7,392 yds | Rating 75.1 | Slope 149
private let SILVERLEAF_GC_SILVER_ID = UUID(uuidString: "A4444444-4444-4444-4444-444444444444")!

let SILVERLEAF_GC_SILVER_PARS: [Int] = [
    4,4,5,4,3,4,3,5,4,
    4,4,4,4,5,4,3,4,4
]
let SILVERLEAF_GC_SILVER_HCS: [Int] = [
    8,10,6,12,18,2,14,4,16,
    1,15,9,13,7,5,17,11,3
]
let SILVERLEAF_GC_SILVER_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Silver", yardage: 7392, rating: 75.1, slope: 149)
]

// MARK: Seminole — Gold (Juno Beach, FL)
// Par 72 | 7,259 yds | Rating 75.4 | Slope 144
private let SEMINOLE_GOLD_ID = UUID(uuidString: "A5555555-5555-5555-5555-555555555555")!

let SEMINOLE_GOLD_PARS: [Int] = [
    4,4,5,4,3,4,4,3,5,
    4,4,4,3,5,5,4,3,4
]
let SEMINOLE_GOLD_HCS: [Int] = [
    17,5,13,1,15,7,3,9,11,
    12,2,8,18,14,10,4,16,6
]
let SEMINOLE_GOLD_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Gold", yardage: 7259, rating: 75.4, slope: 144)
]
// =======================================================
// MARK: - Built-in Registry (ONE place that defines “built-in”)
// =======================================================
private struct BuiltInCourse {
    let id: UUID
    let name: String
    let pars: [Int]
    let hcs: [Int]
    let tees: [TeeInfo]?

    // ✅ NEW
    let country: String
    let state: String?
}
// =======================================================
// MARK: - Built-in Registry (ONE place that defines “built-in”)
// =======================================================


// MARK: - Built-in Registry (ONE place that defines “built-in”)
// =======================================================

// =======================================================
// MARK: - Built-in Registry (ONE place that defines “built-in”)
// =======================================================

private enum BuiltIns {

    // Keep this private so you never leak it outside this file
    private struct BuiltInCourse {
        let id: UUID
        let name: String
        let pars: [Int]
        let hcs: [Int]
        let tees: [TeeInfo]?
        let country: String?
        let state: String?
    }

    // ✅ Helper (defaults fix “Missing arguments for country/state” issues)
    private static func c(
        _ id: UUID,
        _ name: String,
        _ pars: [Int],
        _ hcs: [Int],
        _ tees: [TeeInfo]? = nil,
        country: String? = nil,
        state: String? = nil
    ) -> BuiltInCourse {
        .init(id: id, name: name, pars: pars, hcs: hcs, tees: tees, country: country, state: state)
    }

    // ✅ List stays private (so you can change internals later)
    private static let all: [BuiltInCourse] = [

        // -------------------------
        // Default
        // -------------------------
        c(WOLFMORE_CC_ID, "WolfMore", WOLFMORE_PARS, WOLFMORE_HCS,
          country: "USA", state: "IL"),

        // -------------------------
        // Illinois / Midwest
        // -------------------------
        c(CEDAR_RAPIDS_CC_ID, "Cedar Rapids CC", CEDAR_RAPIDS_PARS, CEDAR_RAPIDS_HCS,
          country: "USA", state: "IA"),
        c(WYNSTONE_SILVER_ID, "Wynstone", WYNSTONE_SILVER_PARS, WYNSTONE_SILVER_HCS,
          country: "USA", state: "IL"),
        c(BARRINGTON_HILLS_WHITE_ID, "Barrington Hills", BARRINGTON_HILLS_WHITE_PARS, BARRINGTON_HILLS_WHITE_HCS,
          country: "USA", state: "IL"),
        c(CRANES_LANDING_BLUE_ID, "Crane's Landing", CRANES_LANDING_BLUE_PARS, CRANES_LANDING_BLUE_HCS,
          country: "USA", state: "IL"),
        c(STONEWALL_ORCHARD_SILVER_ID, "Stonewall Orchard", STONEWALL_ORCHARD_SILVER_PARS, STONEWALL_ORCHARD_SILVER_HCS,
          country: "USA", state: "IL"),
        c(KEMPER_LAKES_GREEN_ID, "Kemper Lakes", KEMPER_LAKES_GREEN_PARS, KEMPER_LAKES_GREEN_HCS,
          country: "USA", state: "IL"),
        c(RICH_HARVEST_SILVER_ID, "Rich Harvest Farms", RICH_HARVEST_SILVER_PARS, RICH_HARVEST_SILVER_HCS,
          country: "USA", state: "IL"),

        c(BUTLER_CC_BLUE_ID, "Butler National 6970", BUTLER_CC_BLUE_PARS, BUTLER_CC_BLUE_HCS, BUTLER_CC_BLUE_TEES,
          country: "USA", state: "IL"),
        c(BUTLER_NATIONAL_BUTLER_TEE_ID, "Butler National (7,550-yard)", BUTLER_NATIONAL_BUTLER_TEE_PARS, BUTLER_NATIONAL_BUTLER_TEE_HCS, BUTLER_NATIONAL_BUTLER_TEE_TEES,
          country: "USA", state: "IL"),

        c(MEDINAH_CC_3_ID, "Medinah CC (Course #3)", MEDINAH_CC_3_PARS, MEDINAH_CC_3_HCS, MEDINAH_CC_3_TEES,
          country: "USA", state: "IL"),

        // -------------------------
        // Florida / Southeast
        // -------------------------
        c(CHAMPIONGATE_BLENDED_BLACK_ID, "Champions Gate", CHAMPIONGATE_BLENDED_BLACK_PARS, CHAMPIONGATE_BLENDED_BLACK_HCS,
          country: "USA", state: "FL"),
        c(TPC_SAWGRASS_STADIUM_ID, "TPC Sawgrass (Stadium)", TPC_SAWGRASS_STADIUM_PARS, TPC_SAWGRASS_STADIUM_HCS,
          country: "USA", state: "FL"),
        c(BAY_HILL_CHALLENGER_CHAMPION_ID, "Bay Hill (Challenger/Champion)", BAY_HILL_CHALLENGER_CHAMPION_PARS, BAY_HILL_CHALLENGER_CHAMPION_HCS, BAY_HILL_CHALLENGER_CHAMPION_TEES,
          country: "USA", state: "FL"),
        c(PGA_NATIONAL_CHAMPION_BEAR_ID, "PGA National (Champion – Bear)", PGA_NATIONAL_CHAMPION_BEAR_PARS, PGA_NATIONAL_CHAMPION_BEAR_HCS, PGA_NATIONAL_CHAMPION_BEAR_TEES,
          country: "USA", state: "FL"),
        c(PANTHER_NATIONAL_JT_ID, "Panther National (JT)", PANTHER_NATIONAL_JT_PARS, PANTHER_NATIONAL_JT_HCS, PANTHER_NATIONAL_JT_TEES,
          country: "USA", state: "FL"),

        c(BEARS_CLUB_CHAMPION_ID, "The Bear's Club (7212 yds)", BEARS_CLUB_CHAMPION_PARS, BEARS_CLUB_CHAMPION_HCS, BEARS_CLUB_CHAMPION_TEES,
          country: "USA", state: "FL"),
        c(BEARS_CLUB_CHAMPIONSHIP_ID, "The Bear's Club (7328 yds)", BEARS_CLUB_CHAMPIONSHIP_PARS, BEARS_CLUB_CHAMPIONSHIP_HCS, BEARS_CLUB_CHAMPIONSHIP_TEES,
          country: "USA", state: "FL"),

        // -------------------------
        // Wisconsin / Resort
        // -------------------------
        c(WHISTLING_STRAITS_STRAITS_ID, "Whistling Straits (Straits)", WHISTLING_STRAITS_STRAITS_PARS, WHISTLING_STRAITS_STRAITS_HCS, WHISTLING_STRAITS_STRAITS_TEES,
          country: "USA", state: "WI"),
        c(WHISTLING_STRAITS_IRISH_ID, "Whistling Straits (Irish)", WHISTLING_STRAITS_IRISH_PARS, WHISTLING_STRAITS_IRISH_HCS,
          country: "USA", state: "WI"),
        c(BLACKWOLF_RUN_RIVER_ID, "Blackwolf Run (River)", BLACKWOLF_RUN_RIVER_PARS, BLACKWOLF_RUN_RIVER_HCS,
          country: "USA", state: "WI"),
        c(BLACKWOLF_RUN_MEADOW_VALLEYS_ID, "Blackwolf Run (Meadow Valleys)", BLACKWOLF_RUN_MEADOW_VALLEYS_PARS, BLACKWOLF_RUN_MEADOW_VALLEYS_HCS,
          country: "USA", state: "WI"),
        c(SAND_VALLEY_ID, "Sand Valley", SAND_VALLEY_PARS, SAND_VALLEY_HCS,
          country: "USA", state: "WI"),
        c(MAMMOTH_DUNES_ID, "Mammoth Dunes", MAMMOTH_DUNES_PARS, MAMMOTH_DUNES_HCS,
          country: "USA", state: "WI"),

        c(GENEVA_NATIONAL_PALMER_ID, "Geneva National – Palmer", GENEVA_NATIONAL_PALMER_PARS, GENEVA_NATIONAL_PALMER_HCS,
          country: "USA", state: "WI"),
        c(GENEVA_NATIONAL_TREVINO_ID, "Geneva National – Trevino", GENEVA_NATIONAL_TREVINO_PARS, GENEVA_NATIONAL_TREVINO_HCS,
          country: "USA", state: "WI"),
        c(GENEVA_NATIONAL_PLAYER_ID, "Geneva National – Player", GENEVA_NATIONAL_PLAYER_PARS, GENEVA_NATIONAL_PLAYER_HCS,
          country: "USA", state: "WI"),

        c(GRAND_GENEVA_HIGHLANDS_ID, "Grand Geneva – The Highlands", GRAND_GENEVA_HIGHLANDS_PARS, GRAND_GENEVA_HIGHLANDS_HCS,
          country: "USA", state: "WI"),
        c(GRAND_GENEVA_BRUTE_ID, "Grand Geneva – The Brute", GRAND_GENEVA_BRUTE_PARS, GRAND_GENEVA_BRUTE_HCS,
          country: "USA", state: "WI"),
        c(ESKER_HILLS_ID, "Esker Hills Golf Club", ESKER_HILLS_PARS, ESKER_HILLS_HCS,
          country: "Ireland", state: "Offaly"),

        // -------------------------
        // Arizona / Southwest
        // -------------------------
        c(TROON_NORTH_MONUMENT_ID, "Troon North (Monument)", TROON_NORTH_MONUMENT_PARS, TROON_NORTH_MONUMENT_HCS,
          country: "USA", state: "AZ"),
        c(TROON_NORTH_PINNACLE_ID, "Troon North (Pinnacle)", TROON_NORTH_PINNACLE_PARS, TROON_NORTH_PINNACLE_HCS,
          country: "USA", state: "AZ"),

        // -------------------------
        // Oregon / Bandon set
        // -------------------------
        c(BANDON_DUNES_ID, "Bandon Dunes", BANDON_DUNES_PARS, BANDON_DUNES_HCS,
          country: "USA", state: "OR"),
        c(PACIFIC_DUNES_ID, "Pacific Dunes", PACIFIC_DUNES_PARS, PACIFIC_DUNES_HCS,
          country: "USA", state: "OR"),
        c(BANDON_TRAILS_ID, "Bandon Trails", BANDON_TRAILS_PARS, BANDON_TRAILS_HCS,
          country: "USA", state: "OR"),
        c(OLD_MACDONALD_ID, "Old Macdonald", OLD_MACDONALD_PARS, OLD_MACDONALD_HCS,
          country: "USA", state: "OR"),
        c(SHEEP_RANCH_ID, "Sheep Ranch", SHEEP_RANCH_PARS, SHEEP_RANCH_HCS,
          country: "USA", state: "OR"),

        // -------------------------
        // California classics
        // -------------------------
        c(PEBBLE_BEACH_ID, "Pebble Beach", PEBBLE_BEACH_PARS, PEBBLE_BEACH_HCS,
          country: "USA", state: "CA"),
        c(SPYGLASS_HILL_ID, "Spyglass Hill", SPYGLASS_HILL_PARS, SPYGLASS_HILL_HCS,
          country: "USA", state: "CA"),

        // -------------------------
        // Streamsong (FL)
        // -------------------------
        c(STREAMSONG_BLUE_ID, "Streamsong (Blue)", STREAMSONG_BLUE_PARS, STREAMSONG_BLUE_HCS,
          country: "USA", state: "FL"),
        c(STREAMSONG_RED_ID, "Streamsong (Red)", STREAMSONG_RED_PARS, STREAMSONG_RED_HCS,
          country: "USA", state: "FL"),
        c(STREAMSONG_BLACK_ID, "Streamsong (Black)", STREAMSONG_BLACK_PARS, STREAMSONG_BLACK_HCS,
          country: "USA", state: "FL"),

        // -------------------------
        // PGA Village (FL)
        // -------------------------
        c(PGA_VILLAGE_WANAMAKER_ID, "PGA Village (Wanamaker)", PGA_VILLAGE_WANAMAKER_PARS, PGA_VILLAGE_WANAMAKER_HCS,
          country: "USA", state: "FL"),
        c(PGA_VILLAGE_RYDER_ID, "PGA Village (Ryder)", PGA_VILLAGE_RYDER_PARS, PGA_VILLAGE_RYDER_HCS,
          country: "USA", state: "FL"),
        c(PGA_VILLAGE_DYE_ID, "PGA Village (Dye)", PGA_VILLAGE_DYE_PARS, PGA_VILLAGE_DYE_HCS,
          country: "USA", state: "FL"),

        // -------------------------
        // Hilton Head / Lowcountry
        // -------------------------
        c(HARBOUR_TOWN_ID, "Harbour Town Golf Links", HARBOUR_TOWN_PARS, HARBOUR_TOWN_HCS,
          country: "USA", state: "SC"),
        c(LONG_COVE_GOLD_ID, "Long Cove Club (Gold)", LONG_COVE_GOLD_PARS, LONG_COVE_GOLD_HCS,
          country: "USA", state: "SC"),
        c(HERON_POINT_GOLD_ID, "Heron Point (Gold) — Sea Pines", HERON_POINT_GOLD_PARS, HERON_POINT_GOLD_HCS,
          country: "USA", state: "SC"),

        // -------------------------
        // “Fantasy / Tracker” set
        // -------------------------
        c(MEDALIST_JT_ID, "Medalist GC (JT)", MEDALIST_JT_PARS, MEDALIST_JT_HCS,
          country: "USA", state: "FL"),

    
        c(ROYAL_OAKS_SCHEFFLER_ID, "Royal Oaks CC (Scheff)", ROYAL_OAKS_SCHEFFLER_PARS, ROYAL_OAKS_SCHEFFLER_HCS,
          country: "USA", state: "TX"),
        c(SUMMIT_CLUB_MORIKAWA_ID, "Summit Club (Colin)", SUMMIT_CLUB_MORIKAWA_PARS, SUMMIT_CLUB_MORIKAWA_HCS,
          country: "USA", state: "NV"),
        
        c(PINEHURST_NO2_USOPEN_ID, "Pinehurst No. 2 (U.S. Open)", PINEHURST_NO2_USOPEN_PARS, PINEHURST_NO2_USOPEN_HCS,
          country: "USA", state: "NC"),

     
        c(BROOK_HOLLOW_TILLINGHAST_ID, "Brook Hollow GC (Tillinghast)", BROOK_HOLLOW_TILLINGHAST_PARS, BROOK_HOLLOW_TILLINGHAST_HCS, BROOK_HOLLOW_TILLINGHAST_TEES,
          country: "USA", state: "TX"),
        
        // -------------------------
        // Georgia
        // -------------------------
        c(SEA_ISLAND_RETREAT_RED_ID, "Sea Island Retreat", SEA_ISLAND_RETREAT_RED_PARS, SEA_ISLAND_RETREAT_RED_HCS, SEA_ISLAND_RETREAT_RED_TEES,
          country: "USA", state: "GA"),

        // -------------------------
        // Florida
        // -------------------------
        c(DYE_PRESERVE_CHAMPIONSHIP_ID, "Dye Preserve (Championship)", DYE_PRESERVE_CHAMPIONSHIP_PARS, DYE_PRESERVE_CHAMPIONSHIP_HCS, DYE_PRESERVE_CHAMPIONSHIP_TEES,
          country: "USA", state: "FL"),
        c(SEMINOLE_GOLD_ID, "Seminole (Gold)", SEMINOLE_GOLD_PARS, SEMINOLE_GOLD_HCS, SEMINOLE_GOLD_TEES,
          country: "USA", state: "FL"),

        // -------------------------
        // Arizona
        // -------------------------
        c(WHISPER_ROCK_UPPER_ROCK_ID, "Whisper Rock Upper (Rock)", WHISPER_ROCK_UPPER_ROCK_PARS, WHISPER_ROCK_UPPER_ROCK_HCS, WHISPER_ROCK_UPPER_ROCK_TEES,
          country: "USA", state: "AZ"),
        c(SILVERLEAF_GC_SILVER_ID, "Silverleaf GC (Silver)", SILVERLEAF_GC_SILVER_PARS, SILVERLEAF_GC_SILVER_HCS, SILVERLEAF_GC_SILVER_TEES,
          country: "USA", state: "AZ"),
        c(SCOTTSDALE_NATIONAL_XTEE_ID, "Scottsdale National GC (X-Tee)", SCOTTSDALE_NATIONAL_XTEE_PARS, SCOTTSDALE_NATIONAL_XTEE_HCS, SCOTTSDALE_NATIONAL_XTEE_TEES,
          country: "USA", state: "AZ"),
        c(MAKRAY_MEMORIAL_BLACK_ID, "Makray Memorial (Black)",
          MAKRAY_MEMORIAL_BLACK_PARS, MAKRAY_MEMORIAL_BLACK_HCS, MAKRAY_MEMORIAL_BLACK_TEES,
          country: "USA", state: "IL"),

        c(LAKE_BARRINGTON_SHORES_BLACK_ID, "Lake Barrington Shores (Black)",
          LAKE_BARRINGTON_SHORES_BLACK_PARS, LAKE_BARRINGTON_SHORES_BLACK_HCS, LAKE_BARRINGTON_SHORES_BLACK_TEES,
          country: "USA", state: "IL"),

        c(FOXFORD_HILLS_BLACK_ID, "Foxford Hills (Black)",
          FOXFORD_HILLS_BLACK_PARS, FOXFORD_HILLS_BLACK_HCS, FOXFORD_HILLS_BLACK_TEES,
          country: "USA", state: "IL"),

        c(CARY_CC_BLUE_ID, "Cary CC (Blue)",
          CARY_CC_BLUE_PARS, CARY_CC_BLUE_HCS, CARY_CC_BLUE_TEES,
          country: "USA", state: "IL"),

        c(CHALET_HILLS_BLACK_ID, "Chalet Hills (Black)",
          CHALET_HILLS_BLACK_PARS, CHALET_HILLS_BLACK_HCS, CHALET_HILLS_BLACK_TEES,
          country: "USA", state: "IL"),
        
        // -------------------------
        // Ireland / UK / Travel set
        // -------------------------
        c(ADARE_MANOR_ID, "Adare Manor", ADARE_MANOR_PARS, ADARE_MANOR_HCS,
          country: "Ireland", state: nil),
        c(BALLYBUNION_OLD_ID, "Ballybunion (Old Course)", BALLYBUNION_OLD_PARS, BALLYBUNION_OLD_HCS,
          country: "Ireland", state: nil),
        c(OLD_HEAD_ID, "Old Head Golf Links", OLD_HEAD_PARS, OLD_HEAD_HCS,
          country: "Ireland", state: nil),
        c(ROYAL_COUNTY_DOWN_CHAMP_ID, "Royal County Down (Championship)", ROYAL_COUNTY_DOWN_CHAMP_PARS, ROYAL_COUNTY_DOWN_CHAMP_HCS,
          country: "Northern Ireland", state: nil),
        c(ROYAL_PORTRUSH_DUNLUCE_ID, "Royal Portrush (Dunluce)", ROYAL_PORTRUSH_DUNLUCE_PARS, ROYAL_PORTRUSH_DUNLUCE_HCS,
          country: "Northern Ireland", state: nil),
        c(WATERVILLE_ID, "Waterville Golf Links", WATERVILLE_PARS, WATERVILLE_HCS,
          country: "Ireland", state: nil),

        // -------------------------
        // Must-have classic
        // -------------------------
        c(PINE_VALLEY_ID, "Pine Valley", PINE_VALLEY_PARS, PINE_VALLEY_HCS,
          country: "USA", state: "NJ"),
    ]

    // ✅ expose UUIDs only (safe)
    static let ids: Set<UUID> = Set(all.map(\.id))

    // ✅ expose CourseProfile list (so CourseLibrary never touches BuiltInCourse)
    static var profiles: [CourseProfile] {
        all.map {
            CourseProfile(
                id: $0.id,
                name: $0.name,
                pars: $0.pars,
                hcs: $0.hcs,
                tees: $0.tees,
                country: $0.country,
                state: $0.state
            )
        }
    }
    
}

// =======================================================
// MARK: - CourseLibrary
// =======================================================

final class CourseLibrary {
    static let shared = CourseLibrary()

    private let keyLibrary  = "course.library.v1"
    private let keySelected = "course.selected.id.v1"

    private(set) var courses: [CourseProfile] = []

    private init() {
        load()
        seedBuiltIns()
    }

    // MARK: - Public helpers

    func wolfMore() -> CourseProfile? {
        if let c = get(id: WOLFMORE_CC_ID) { return c }
        return courses.first { $0.name.caseInsensitiveCompare("WolfMore") == .orderedSame }
    }

    func allSorted() -> [CourseProfile] {
        courses.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func get(id: UUID) -> CourseProfile? { courses.first { $0.id == id } }

    func isBuiltIn(id: UUID) -> Bool { BuiltIns.ids.contains(id) }

    // MARK: - Upsert / Delete

    func upsert(_ c: CourseProfile) {
        if let i = courses.firstIndex(where: { $0.id == c.id }) {
            courses[i] = mergeKeepUserBits(existing: courses[i], incoming: c)
        } else if let j = courses.firstIndex(where: { $0.name.caseInsensitiveCompare(c.name) == .orderedSame }) {
            let merged = CourseProfile(
                id: courses[j].id,
                name: c.name,
                pars: c.pars,
                hcs:  c.hcs,
                tees: c.tees ?? courses[j].tees,
                country: c.country ?? courses[j].country,
                state: c.state ?? courses[j].state
            )
            courses[j] = merged
        } else {
            courses.append(c)
        }
        save()
    }

    func delete(id: UUID) {
        if isBuiltIn(id: id) { return }   // hard safety
        courses.removeAll { $0.id == id }
        save()
    }

    // MARK: - Selected course

    var selectedCourseID: UUID? {
        get {
            guard let s = UserDefaults.standard.string(forKey: keySelected) else { return nil }
            return UUID(uuidString: s)
        }
        set { UserDefaults.standard.set(newValue?.uuidString, forKey: keySelected) }
    }

    var selectedCourseName: String? {
        guard let id = selectedCourseID else { return nil }
        return get(id: id)?.name
    }

    // MARK: - Seeding

    func seedIfNeeded() { seedBuiltIns() } // back-compat

    private func seedBuiltIns() {
        let builtIns = BuiltIns.profiles
        var changed = false

        for p in builtIns {
            changed = upsertBuiltIn(p) || changed
        }

        if changed { save() } // ✅ save once
    }

    @discardableResult
    private func upsertBuiltIn(_ c: CourseProfile) -> Bool {
        if let i = courses.firstIndex(where: { $0.id == c.id }) {
            let merged = mergeKeepUserBits(existing: courses[i], incoming: c)
            if courses[i] != merged {
                courses[i] = merged
                return true
            }
            return false
        }

        if let j = courses.firstIndex(where: { $0.name.caseInsensitiveCompare(c.name) == .orderedSame }) {
            let merged = CourseProfile(
                id: courses[j].id,                // keep existing ID
                name: c.name,
                pars: c.pars,
                hcs:  c.hcs,
                tees: c.tees ?? courses[j].tees,
                country: c.country ?? courses[j].country,
                state: c.state ?? courses[j].state
            )
            if courses[j] != merged {
                courses[j] = merged
                return true
            }
            return false
        }

        courses.append(c)
        return true
    }

    private func mergeKeepUserBits(existing: CourseProfile, incoming: CourseProfile) -> CourseProfile {
        CourseProfile(
            id: existing.id,
            name: incoming.name,
            pars: incoming.pars,
            hcs: incoming.hcs,
            tees: incoming.tees ?? existing.tees,
            country: incoming.country ?? existing.country,
            state: incoming.state ?? existing.state
        )
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: keyLibrary) else { return }
        courses = (try? JSONDecoder().decode([CourseProfile].self, from: data)) ?? []
    }

    private func save() {
        let data = (try? JSONEncoder().encode(courses)) ?? Data()
        UserDefaults.standard.set(data, forKey: keyLibrary)
    }
}
