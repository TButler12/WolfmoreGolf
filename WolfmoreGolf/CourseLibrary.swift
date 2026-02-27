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

    init(id: UUID = UUID(), name: String, pars: [Int], hcs: [Int], tees: [TeeInfo]? = nil) {
        self.id = id
        self.name = name
        self.pars = Array(pars.prefix(18))
        self.hcs  = Array(hcs.prefix(18))
        self.tees = tees
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

// MARK: Brook Hollow GC (Spieth)
private let BROOK_HOLLOW_SPIETH_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000003")!
let BROOK_HOLLOW_SPIETH_PARS: [Int] = [4,4,5,3,4,4, 3,5,4, 4,3,4, 5,4,4, 3,4,5]
let BROOK_HOLLOW_SPIETH_HCS:  [Int] = [1,3,5,7,9,11, 13,15,17, 2,4,6, 8,10,12, 14,16,18]

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

// MARK: Medalist GC (Justin Thomas)
private let MEDALIST_JT_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000009")!
let MEDALIST_JT_PARS: [Int] = [4,4,5,3,4,4, 3,5,4, 4,3,4, 5,4,4, 3,4,5]
let MEDALIST_JT_HCS:  [Int] = [1,3,5,7,9,11, 13,15,17, 2,4,6, 8,10,12, 14,16,18]

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
let ROYAL_OAKS_SCHEFFLER_PARS: [Int] = [4,4,4,5,3,4, 4,3,5, 4,4,3, 4,5,4, 3,4,4]
let ROYAL_OAKS_SCHEFFLER_HCS:  [Int] = [1,3,5,7,9,11, 13,15,17, 2,4,6, 8,10,12, 14,16,18]

// MARK: Royal Portrush (Dunluce)
private let ROYAL_PORTRUSH_DUNLUCE_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000013")!
let ROYAL_PORTRUSH_DUNLUCE_PARS: [Int] = [4,5,3,4,4,3, 5,4,4, 4,4,4, 3,5,4, 4,4,5]
let ROYAL_PORTRUSH_DUNLUCE_HCS:  [Int] = [15,7,17,1,5,13, 9,3,11, 12,6,18, 14,16,4, 10,8,2]

// MARK: Summit Club (Morikawa)
private let SUMMIT_CLUB_MORIKAWA_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000014")!
let SUMMIT_CLUB_MORIKAWA_PARS: [Int] = [4,5,3,4,4,5, 3,4,4, 4,3,5, 4,4,3, 4,5,4]
let SUMMIT_CLUB_MORIKAWA_HCS:  [Int] = [1,3,5,7,9,11, 13,15,17, 2,4,6, 8,10,12, 14,16,18]

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
    4,5,4,4,3,5,
    4,4,4,
    4,4,3,
    5,4,3,
    4,4,4
]
let ESKER_HILLS_HCS: [Int] = [
    11,17,1,5,15,9,
    3,13,7,
    10,4,14,
    2,8,16,
    12,18,6
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
// =======================================================
// MARK: - Built-in Registry (ONE place that defines “built-in”)
// =======================================================
private struct BuiltInCourse {
    let id: UUID
    let name: String
    let pars: [Int]
    let hcs: [Int]
    let tees: [TeeInfo]?
}
private enum BuiltIns {

    static let all: [BuiltInCourse] = [
        .init(id: WOLFMORE_CC_ID, name: "WolfMore", pars: WOLFMORE_PARS, hcs: WOLFMORE_HCS, tees: nil),

        .init(id: CEDAR_RAPIDS_CC_ID, name: "Cedar Rapids CC", pars: CEDAR_RAPIDS_PARS, hcs: CEDAR_RAPIDS_HCS, tees: nil),
        .init(id: WYNSTONE_SILVER_ID, name: "Wynstone", pars: WYNSTONE_SILVER_PARS, hcs: WYNSTONE_SILVER_HCS, tees: nil),
        .init(id: BARRINGTON_HILLS_WHITE_ID, name: "Barrington Hills", pars: BARRINGTON_HILLS_WHITE_PARS, hcs: BARRINGTON_HILLS_WHITE_HCS, tees: nil),
        .init(id: CRANES_LANDING_BLUE_ID, name: "Crane's Landing", pars: CRANES_LANDING_BLUE_PARS, hcs: CRANES_LANDING_BLUE_HCS, tees: nil),
        .init(id: CHAMPIONGATE_BLENDED_BLACK_ID, name: "Champions Gate", pars: CHAMPIONGATE_BLENDED_BLACK_PARS, hcs: CHAMPIONGATE_BLENDED_BLACK_HCS, tees: nil),
        .init(id: BUTLER_CC_BLUE_ID,
              name: "Butler National 6970",
              pars: BUTLER_CC_BLUE_PARS,
              hcs:  BUTLER_CC_BLUE_HCS,
              tees: BUTLER_CC_BLUE_TEES),
        .init(
            id: BUTLER_NATIONAL_BUTLER_TEE_ID,
            name: "Butler National (7,550-yard)",
            pars: BUTLER_NATIONAL_BUTLER_TEE_PARS,
            hcs: BUTLER_NATIONAL_BUTLER_TEE_HCS,
            tees: BUTLER_NATIONAL_BUTLER_TEE_TEES
        ),
        .init(id: STONEWALL_ORCHARD_SILVER_ID, name: "Stonewall Orchard", pars: STONEWALL_ORCHARD_SILVER_PARS, hcs: STONEWALL_ORCHARD_SILVER_HCS, tees: nil),
        .init(id: KEMPER_LAKES_GREEN_ID, name: "Kemper Lakes", pars: KEMPER_LAKES_GREEN_PARS, hcs: KEMPER_LAKES_GREEN_HCS, tees: nil),
        .init(id: RICH_HARVEST_SILVER_ID, name: "Rich Harvest Farms", pars: RICH_HARVEST_SILVER_PARS, hcs: RICH_HARVEST_SILVER_HCS, tees: nil),

        .init(id: WHISTLING_STRAITS_STRAITS_ID, name: "Whistling Straits (Straits)", pars: WHISTLING_STRAITS_STRAITS_PARS, hcs: WHISTLING_STRAITS_STRAITS_HCS, tees: WHISTLING_STRAITS_STRAITS_TEES),
        .init(id: WHISTLING_STRAITS_IRISH_ID, name: "Whistling Straits (Irish)", pars: WHISTLING_STRAITS_IRISH_PARS, hcs: WHISTLING_STRAITS_IRISH_HCS, tees: nil),

        .init(id: BLACKWOLF_RUN_RIVER_ID, name: "Blackwolf Run (River)", pars: BLACKWOLF_RUN_RIVER_PARS, hcs: BLACKWOLF_RUN_RIVER_HCS, tees: nil),
        .init(id: BLACKWOLF_RUN_MEADOW_VALLEYS_ID, name: "Blackwolf Run (Meadow Valleys)", pars: BLACKWOLF_RUN_MEADOW_VALLEYS_PARS, hcs: BLACKWOLF_RUN_MEADOW_VALLEYS_HCS, tees: nil),

        .init(id: SAND_VALLEY_ID, name: "Sand Valley", pars: SAND_VALLEY_PARS, hcs: SAND_VALLEY_HCS, tees: nil),
        .init(id: MAMMOTH_DUNES_ID, name: "Mammoth Dunes", pars: MAMMOTH_DUNES_PARS, hcs: MAMMOTH_DUNES_HCS, tees: nil),

        .init(id: TROON_NORTH_MONUMENT_ID, name: "Troon North (Monument)", pars: TROON_NORTH_MONUMENT_PARS, hcs: TROON_NORTH_MONUMENT_HCS, tees: nil),
        .init(id: TROON_NORTH_PINNACLE_ID, name: "Troon North (Pinnacle)", pars: TROON_NORTH_PINNACLE_PARS, hcs: TROON_NORTH_PINNACLE_HCS, tees: nil),

        .init(id: TPC_SAWGRASS_STADIUM_ID, name: "TPC Sawgrass (Stadium)", pars: TPC_SAWGRASS_STADIUM_PARS, hcs: TPC_SAWGRASS_STADIUM_HCS, tees: nil),
        .init(id: BAY_HILL_CHALLENGER_CHAMPION_ID, name: "Bay Hill (Challenger/Champion)", pars: BAY_HILL_CHALLENGER_CHAMPION_PARS, hcs: BAY_HILL_CHALLENGER_CHAMPION_HCS, tees: BAY_HILL_CHALLENGER_CHAMPION_TEES),

        // ✅ Medinah restored into built-ins
        .init(id: MEDINAH_CC_3_ID, name: "Medinah CC (Course #3)", pars: MEDINAH_CC_3_PARS, hcs: MEDINAH_CC_3_HCS, tees: MEDINAH_CC_3_TEES),

        .init(id: STREAMSONG_BLUE_ID, name: "Streamsong (Blue)", pars: STREAMSONG_BLUE_PARS, hcs: STREAMSONG_BLUE_HCS, tees: nil),
        .init(id: STREAMSONG_RED_ID, name: "Streamsong (Red)", pars: STREAMSONG_RED_PARS, hcs: STREAMSONG_RED_HCS, tees: nil),
        .init(id: STREAMSONG_BLACK_ID, name: "Streamsong (Black)", pars: STREAMSONG_BLACK_PARS, hcs: STREAMSONG_BLACK_HCS, tees: nil),

        .init(id: PGA_VILLAGE_WANAMAKER_ID, name: "PGA Village (Wanamaker)", pars: PGA_VILLAGE_WANAMAKER_PARS, hcs: PGA_VILLAGE_WANAMAKER_HCS, tees: nil),
        .init(id: PGA_VILLAGE_RYDER_ID, name: "PGA Village (Ryder)", pars: PGA_VILLAGE_RYDER_PARS, hcs: PGA_VILLAGE_RYDER_HCS, tees: nil),
        .init(id: PGA_VILLAGE_DYE_ID, name: "PGA Village (Dye)", pars: PGA_VILLAGE_DYE_PARS, hcs: PGA_VILLAGE_DYE_HCS, tees: nil),

        .init(id: PEBBLE_BEACH_ID, name: "Pebble Beach", pars: PEBBLE_BEACH_PARS, hcs: PEBBLE_BEACH_HCS, tees: nil),
        .init(id: SPYGLASS_HILL_ID, name: "Spyglass Hill", pars: SPYGLASS_HILL_PARS, hcs: SPYGLASS_HILL_HCS, tees: nil),

        .init(id: BANDON_DUNES_ID, name: "Bandon Dunes", pars: BANDON_DUNES_PARS, hcs: BANDON_DUNES_HCS, tees: nil),
        .init(id: PACIFIC_DUNES_ID, name: "Pacific Dunes", pars: PACIFIC_DUNES_PARS, hcs: PACIFIC_DUNES_HCS, tees: nil),
        .init(id: BANDON_TRAILS_ID, name: "Bandon Trails", pars: BANDON_TRAILS_PARS, hcs: BANDON_TRAILS_HCS, tees: nil),
        .init(id: OLD_MACDONALD_ID, name: "Old Macdonald", pars: OLD_MACDONALD_PARS, hcs: OLD_MACDONALD_HCS, tees: nil),
        .init(id: SHEEP_RANCH_ID, name: "Sheep Ranch", pars: SHEEP_RANCH_PARS, hcs: SHEEP_RANCH_HCS, tees: nil),
        // MARK: The Bear's Club (two tee options)
        .init(
            id: BEARS_CLUB_CHAMPION_ID,
            name: "The Bear's Club (7212 yrds)",
            pars: BEARS_CLUB_CHAMPION_PARS,
            hcs: BEARS_CLUB_CHAMPION_HCS,
            tees: BEARS_CLUB_CHAMPION_TEES
        ),
        .init(
            id: BEARS_CLUB_CHAMPIONSHIP_ID,
            name: "The Bear's Club (7328 yds)",
            pars: BEARS_CLUB_CHAMPIONSHIP_PARS,
            hcs: BEARS_CLUB_CHAMPIONSHIP_HCS,
            tees: BEARS_CLUB_CHAMPIONSHIP_TEES
        ),
        // --- Ireland / UK / Travel set ---
        .init(id: ADARE_MANOR_ID, name: "Adare Manor", pars: ADARE_MANOR_PARS, hcs: ADARE_MANOR_HCS, tees: nil),
        .init(id: BALLYBUNION_OLD_ID, name: "Ballybunion (Old Course)", pars: BALLYBUNION_OLD_PARS, hcs: BALLYBUNION_OLD_HCS, tees: nil),
        .init(id: OLD_HEAD_ID, name: "Old Head Golf Links", pars: OLD_HEAD_PARS, hcs: OLD_HEAD_HCS, tees: nil),
        .init(id: ROYAL_COUNTY_DOWN_CHAMP_ID, name: "Royal County Down (Championship)", pars: ROYAL_COUNTY_DOWN_CHAMP_PARS, hcs: ROYAL_COUNTY_DOWN_CHAMP_HCS, tees: nil),
        .init(id: ROYAL_PORTRUSH_DUNLUCE_ID, name: "Royal Portrush (Dunluce)", pars: ROYAL_PORTRUSH_DUNLUCE_PARS, hcs: ROYAL_PORTRUSH_DUNLUCE_HCS, tees: nil),
        .init(id: WATERVILLE_ID, name: "Waterville Golf Links", pars: WATERVILLE_PARS, hcs: WATERVILLE_HCS, tees: nil),

        // --- Wisconsin / Midwest / Resort set ---
        .init(id: BROOK_HOLLOW_SPIETH_ID, name: "Brook Hollow GC (Spieth)", pars: BROOK_HOLLOW_SPIETH_PARS, hcs: BROOK_HOLLOW_SPIETH_HCS, tees: nil),
        .init(id: GENEVA_NATIONAL_PALMER_ID, name: "Geneva National – Palmer", pars: GENEVA_NATIONAL_PALMER_PARS, hcs: GENEVA_NATIONAL_PALMER_HCS, tees: nil),
        .init(id: GENEVA_NATIONAL_TREVINO_ID, name: "Geneva National – Trevino", pars: GENEVA_NATIONAL_TREVINO_PARS, hcs: GENEVA_NATIONAL_TREVINO_HCS, tees: nil),
        .init(id: GRAND_GENEVA_HIGHLANDS_ID, name: "Grand Geneva – The Highlands", pars: GRAND_GENEVA_HIGHLANDS_PARS, hcs: GRAND_GENEVA_HIGHLANDS_HCS, tees: nil),

        // --- Hilton Head / Lowcountry set ---
        .init(id: HARBOUR_TOWN_ID, name: "Harbour Town Golf Links", pars: HARBOUR_TOWN_PARS, hcs: HARBOUR_TOWN_HCS, tees: nil),
        .init(id: LONG_COVE_GOLD_ID, name: "Long Cove Club (Gold)", pars: LONG_COVE_GOLD_PARS, hcs: LONG_COVE_GOLD_HCS, tees: nil),

        // --- “Fantasy”/Tracker set ---
        .init(id: MEDALIST_JT_ID, name: "Medalist GC (Justin Thomas)", pars: MEDALIST_JT_PARS, hcs: MEDALIST_JT_HCS, tees: nil),
        .init(id: ROYAL_OAKS_SCHEFFLER_ID, name: "Royal Oaks CC (Scheffler)", pars: ROYAL_OAKS_SCHEFFLER_PARS, hcs: ROYAL_OAKS_SCHEFFLER_HCS, tees: nil),
        .init(id: SUMMIT_CLUB_MORIKAWA_ID, name: "Summit Club (Morikawa)", pars: SUMMIT_CLUB_MORIKAWA_PARS, hcs: SUMMIT_CLUB_MORIKAWA_HCS, tees: nil),
        

                // --- Add from screenshots ---
                .init(id: ESKER_HILLS_ID, name: "Esker Hills Golf Club", pars: ESKER_HILLS_PARS, hcs: ESKER_HILLS_HCS, tees: nil),

                // Geneva National set
                .init(id: GENEVA_NATIONAL_PLAYER_ID, name: "Geneva National – Player", pars: GENEVA_NATIONAL_PLAYER_PARS, hcs: GENEVA_NATIONAL_PLAYER_HCS, tees: nil),

                // Grand Geneva set
                .init(id: GRAND_GENEVA_BRUTE_ID, name: "Grand Geneva – The Brute", pars: GRAND_GENEVA_BRUTE_PARS, hcs: GRAND_GENEVA_BRUTE_HCS, tees: nil),

                // Hilton Head / Sea Pines set
                .init(id: HERON_POINT_GOLD_ID, name: "Heron Point (Gold) — Sea Pines", pars: HERON_POINT_GOLD_PARS, hcs: HERON_POINT_GOLD_HCS, tees: nil),

                // Must-have classic
                .init(id: PINE_VALLEY_ID, name: "Pine Valley", pars: PINE_VALLEY_PARS, hcs: PINE_VALLEY_HCS, tees: nil),
    ]

    static let ids: Set<UUID> = Set(all.map(\.id))
}

// =======================================================
// MARK: - CourseLibrary
// =======================================================

final class CourseLibrary {
    static let shared = CourseLibrary()

    func wolfMore() -> CourseProfile? {
        // Prefer the fixed built-in ID (best)
        if let c = get(id: WOLFMORE_CC_ID) { return c }

        // Fallback: name match (helps if something odd happened to IDs)
        return courses.first { $0.name.caseInsensitiveCompare("WolfMore") == .orderedSame }
    }
    private let keyLibrary  = "course.library.v1"
    private let keySelected = "course.selected.id.v1"

    private(set) var courses: [CourseProfile] = []

    private init() {
        load()
        seedBuiltIns()
    }

   
    private func seedBuiltIns() {
        for b in BuiltIns.all {
            let profile = CourseProfile(id: b.id, name: b.name, pars: b.pars, hcs: b.hcs, tees: b.tees)
            upsertBuiltIn(profile)
        }
    }

    private func upsertBuiltIn(_ c: CourseProfile) {
        if let i = courses.firstIndex(where: { $0.id == c.id }) {
            courses[i] = c
            save()
            return
        }

        if let j = courses.firstIndex(where: { $0.name.caseInsensitiveCompare(c.name) == .orderedSame }) {
            // Keep existing ID to prevent duplicates
            courses[j] = CourseProfile(
                id: courses[j].id,
                name: c.name,
                pars: c.pars,
                hcs:  c.hcs,
                tees: c.tees ?? courses[j].tees
            )
            save()
            return
        }

        courses.append(c)
        save()
    }

    // MARK: - Public API

    func allSorted() -> [CourseProfile] {
        courses.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func get(id: UUID) -> CourseProfile? { courses.first { $0.id == id } }

    func upsert(_ c: CourseProfile) {
        if let i = courses.firstIndex(where: { $0.id == c.id }) {
            courses[i] = CourseProfile(
                id: courses[i].id,
                name: c.name,
                pars: c.pars,
                hcs:  c.hcs,
                tees: c.tees ?? courses[i].tees
            )
        } else if let j = courses.firstIndex(where: { $0.name.caseInsensitiveCompare(c.name) == .orderedSame }) {
            courses[j] = CourseProfile(
                id: courses[j].id,
                name: c.name,
                pars: c.pars,
                hcs:  c.hcs,
                tees: c.tees ?? courses[j].tees
            )
        } else {
            courses.append(c)
        }
        save()
    }

    // ✅ HARD SAFETY: built-ins cannot be deleted
    func delete(id: UUID) {
        if isBuiltIn(id: id) { return }   // ✅ hard safety
        courses.removeAll { $0.id == id }
        save()
    }

    func isBuiltIn(id: UUID) -> Bool { BuiltIns.ids.contains(id) }

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

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: keyLibrary) else { return }
        courses = (try? JSONDecoder().decode([CourseProfile].self, from: data)) ?? []
    }

    private func save() {
        let data = (try? JSONEncoder().encode(courses)) ?? Data()
        UserDefaults.standard.set(data, forKey: keyLibrary)
    }
    // Back-compat for older callers (CourseSetupVC, CoursePickerVC, etc.)
    func seedIfNeeded() {
        seedBuiltIns()
    }
}
