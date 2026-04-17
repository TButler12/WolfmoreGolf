
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
enum CourseRouting: String, Codable {
    case eighteenStandard
    case loopAtoB
    case loopBtoC
    case loopAtoC
}
struct CourseProfile: Codable, Equatable {
    var id: UUID
    var name: String
    var pars: [Int]
    var hcs: [Int]
    var tees: [TeeInfo]? = nil
    var country: String?
    var state: String?
    var region: String?
    var architect: String?
    var type: String?
    var phone: String?
    var website: String?
    var address: String?
    var isWolfApproved: Bool? = nil
    var venueType: VenueType?
    var resortBrand: String?
    var promo: LocationPromo?
    var routing: CourseRouting = .eighteenStandard
    
    init(
        id: UUID = UUID(),
        name: String,
        pars: [Int],
        hcs: [Int],
        tees: [TeeInfo]? = nil,
        country: String? = nil,
        state: String? = nil,
        region: String? = nil,
        architect: String? = nil,
        type: String? = nil,
        phone: String? = nil,
        website: String? = nil,
        address: String? = nil,
        isWolfApproved: Bool? = nil,
        venueType: VenueType? = nil,
        resortBrand: String? = nil,
        promo: LocationPromo? = nil,
        routing: CourseRouting = .eighteenStandard
    ) {
        self.id = id
        self.name = name
        self.pars = pars
        self.hcs = hcs
        self.tees = tees
        self.country = country
        self.state = state
        self.region = region
        self.architect = architect
        self.type = type
        self.phone = phone
        self.website = website
        self.address = address
        self.isWolfApproved = isWolfApproved
        self.venueType = venueType
        self.resortBrand = resortBrand
        self.promo = promo
        self.routing = routing
    }
    
    
}
// =======================================================
// MARK: - Built-in raw data (pars / hcs / optional tees)
// =======================================================
private let WJ_ARBORETUM_ID = UUID(uuidString: "A1D4E7C2-8F61-4D4A-9B2C-1234567890A1")!
private let EMPTY_PARS = Array(repeating: 4, count: 18)
private let EMPTY_HCS = Array(1...18)
// MARK: WolfMore (Default)
private let WOLFMORE_CC_ID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
let WOLFMORE_PARS: [Int] = [4,4,4,4,3,5,3,4,4,4,4,3,4,4,5,3,4,5]
let WOLFMORE_HCS:  [Int] = [4,8,14,10,16,2,18,6,12,11,3,15,1,13,7,17,9,5]

// MARK: BuiltfMore (Default)
private let BILTMORE_CC_ID = UUID(uuidString: "11111111-1111-1111-1111-111111111126")!
let BILTMORE_CC_PARS: [Int] = [4,4,4,4,3,5,3,4,4, 4,4,3,4,4,5,3,4,5]
let BILTMORE_CC_HCS:  [Int] = [4,8,14,10,16,2,18,6,12, 11,3,15,1,13,7,17,9,5]
let BILTMORE_CC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6900, rating: 74.8, slope: 138),
    TeeInfo(teeName: "Blue",  yardage: 6700, rating: 73.3, slope: 134),
    TeeInfo(teeName: "White", yardage: 6300, rating: 71.2, slope: 129),
    TeeInfo(teeName: "Gold",  yardage: 5900, rating: 69.0, slope: 123),
    TeeInfo(teeName: "Red",   yardage: 5400, rating: 72.1, slope: 128)
]
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

// MARK: - TPC Sawgrass (Stadium)

private let TPC_SAWGRASS_STADIUM_ID = UUID(uuidString: "7D9F0A2B-6B7A-4D6E-8E0D-8A6A1E93C102")!

let TPC_SAWGRASS_STADIUM_PARS: [Int] = [
    4,5,3,4,4,4,4,3,5,
    4,5,4,3,4,4,5,3,4
]

let TPC_SAWGRASS_STADIUM_HCS: [Int] = [
    11,15,17,9,3,13,1,7,5,
    12,8,16,18,4,6,10,14,2
]
let TPC_SAWGRASS_STADIUM_TEES: [TeeInfo] = [

    TeeInfo(
        teeName: "THE PLAYERS",
        yardage: 7560,
        rating: 74.5,
        slope: 145
    ),

    TeeInfo(
        teeName: "Blue",
        yardage: 7300,
        rating: 73.8,
        slope: 148
    ),

    TeeInfo(
        teeName: "B&W Blended",
        yardage: 7075,
        rating: 72.6,
        slope: 144
    ),

    TeeInfo(
        teeName: "White",
        yardage: 6700,
        rating: 70.8,
        slope: 138
    ),

    TeeInfo(
        teeName: "W&G Blended",
        yardage: 6400,
        rating: 69.2,
        slope: 132
    ),

    TeeInfo(
        teeName: "Green",
        yardage: 6100,
        rating: 67.8,
        slope: 126
    )
]
// MARK: - TPC Sawgrass (Dye’s Valley)

private let TPC_SAWGRASS_DYES_VALLEY_ID = UUID(uuidString: "C1A9E3B4-8F21-4A7E-9B44-5F1C2D9A7301")!

let TPC_SAWGRASS_DYES_VALLEY_PARS: [Int] = [
    5,3,4,4,3,4,4,5,4,
    4,3,4,4,3,4,5,5,4
]

let TPC_SAWGRASS_DYES_VALLEY_HCS: [Int] = [
    7,11,17,5,15,1,13,9,3,
    4,6,14,8,12,16,10,18,2
]
let TPC_SAWGRASS_DYES_VALLEY_TEES: [TeeInfo] = [

    TeeInfo(
        teeName: "TPC",
        yardage: 6847,
        rating: 74.0,
        slope: 134
    ),

    TeeInfo(
        teeName: "Blue",
        yardage: 6502,
        rating: 72.1,
        slope: 131
    ),

    TeeInfo(
        teeName: "B&W Blended",
        yardage: 6272,
        rating: 71.0,
        slope: 128
    ),

    TeeInfo(
        teeName: "White",
        yardage: 6079,
        rating: 70.1,
        slope: 127
    ),

    TeeInfo(
        teeName: "W&G Blended",
        yardage: 5526,
        rating: 67.8,
        slope: 117
    ),

    TeeInfo(
        teeName: "Green",
        yardage: 5126,
        rating: 65.9,
        slope: 113
    )
]

// MARK: Bay Hill (Challenger/Champion)
private let BAY_HILL_CHALLENGER_CHAMPION_ID = UUID(uuidString: "2E6C1D5A-ACB6-4E47-9F09-2B7E0C52A203")!
let BAY_HILL_CHALLENGER_CHAMPION_PARS: [Int] = [4,3,4,5,4,5,3,4,4, 4,4,5,4,3,4,5,3,4]
let BAY_HILL_CHALLENGER_CHAMPION_HCS:  [Int] = [9,11,5,1,15,13,17,3,7, 12,4,10,14,18,6,2,16,8]
let BAY_HILL_CHALLENGER_CHAMPION_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Green", yardage: 7409, rating: 76.4, slope: 138)
]

// MARK: - Medinah Country Club (Course #3)

private let MEDINAH_CC_3_ID = UUID(uuidString: "9A1C0F37-9B11-4E2C-8D49-7A5A6E6F2404")!

let MEDINAH_CC_3_PARS: [Int] = [
    4,3,4,4,5,4,5,4,4,
    5,3,4,3,4,4,4,3,5
]

let MEDINAH_CC_3_HCS: [Int] = [
    13,15,11,3,5,7,1,17,9,
    2,16,8,14,10,4,12,18,6
]

let MEDINAH_CC_3_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Gold",
        yardage: 7564,
        rating: 76.8,
        slope: 143
    )
]

// MARK: - Medinah Country Club (Course #2)

private let MEDINAH_CC_2_ID = UUID(uuidString: "B7A10000-0000-0000-0000-000000000102")!

let MEDINAH_CC_2_PARS: [Int] = [
    4,4,4,5,4,3,5,3,4,
    4,4,3,4,4,3,5,4,5
]

let MEDINAH_CC_2_HCS: [Int] = [
    11,3,7,1,9,17,5,13,15,
    12,2,18,8,14,16,4,6,10
]

let MEDINAH_CC_2_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Gold",
        yardage: 6412,
        rating: 70.6,
        slope: 126
    )
]

// MARK: - Medinah Country Club (Course #1)

private let MEDINAH_CC_1_ID = UUID(uuidString: "B7A10000-0000-0000-0000-000000000101")!

let MEDINAH_CC_1_PARS: [Int] = [
    5,4,4,4,3,4,3,4,5,
    4,4,4,4,4,3,4,5,3
]

let MEDINAH_CC_1_HCS: [Int] = [
    9,13,17,3,11,1,15,5,7,
    12,8,6,18,10,16,2,4,14
]

let MEDINAH_CC_1_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Gold",
        yardage: 6895,
        rating: 73.5,
        slope: 138
    )
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

// MARK: - Lahinch Golf Club (Old Course)
private let LAHINCH_OLD_ID = UUID(uuidString: "B7A10000-0000-0000-0000-000000000001")!

let LAHINCH_OLD_PARS: [Int] = [
    4,3,4,5,4,3,4,5,4,
    4,4,5,3,4,4,4,4,4
]

let LAHINCH_OLD_HCS: [Int] = [
    8,14,4,18,16,2,12,10,6,
    13,5,9,17,15,1,7,3,11
]

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
// MARK: - St Andrews Links (Old Course)

private let ST_ANDREWS_OLD_ID = UUID(uuidString: "B7A10000-0000-0000-0000-000000000002")!

let ST_ANDREWS_OLD_PARS: [Int] = [
    4,4,4,4,5,4,4,3,4,
    4,3,4,4,5,4,4,4,4
]

let ST_ANDREWS_OLD_HCS: [Int] = [
    11,3,7,1,13,9,5,15,17,
    18,6,14,2,12,8,10,4,16
]

let ST_ANDREWS_OLD_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Championship",
        yardage: 7190,
        rating: 75.7,
        slope: 143
    )
]
// MARK: - Muirfield (The Honourable Company of Edinburgh Golfers)

private let MUIRFIELD_ID = UUID(uuidString: "B7A10000-0000-0000-0000-000000000003")!

let MUIRFIELD_PARS: [Int] = [
    4,4,4,3,4,4,3,5,4,
    4,4,5,3,4,4,3,4,5
]

let MUIRFIELD_HCS: [Int] = [
    9,5,13,11,15,1,7,17,3,
    10,4,16,2,14,6,18,8,12
]

let MUIRFIELD_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Championship",
        yardage: 7245,
        rating: 73.8,
        slope: 142
    )
]
private let TURNBERRY_AILSA_ID = UUID(uuidString: "B7A10000-0000-0000-0000-000000000004")!

let TURNBERRY_AILSA_PARS: [Int] = [
    4,4,4,3,5,3,5,4,3,
    5,3,4,4,5,3,4,4,4
]

let TURNBERRY_AILSA_HCS: [Int] = [
    6,10,4,16,8,18,12,2,14,
    9,15,3,13,11,17,1,5,7
]

let TURNBERRY_AILSA_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 7489,
        rating: 70.0,
        slope: 113
    )
]
private let TURNBERRY_KRTB_ID = UUID(uuidString: "B7A10000-0000-0000-0000-000000000005")!

let TURNBERRY_KRTB_PARS: [Int] = [
    5,3,4,4,4,3,4,5,4,
    3,5,3,4,5,4,3,4,5
]

let TURNBERRY_KRTB_HCS: [Int] = [
    8,16,18,6,4,14,10,12,2,
    17,5,13,7,9,3,15,1,11
]

let TURNBERRY_KRTB_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 7203,
        rating: 0.0,
        slope: 0
    )
]
private let SUNNINGDALE_OLD_ID = UUID(uuidString: "B7A10000-0000-0000-0000-000000000006")!

let SUNNINGDALE_OLD_PARS: [Int] = [
    5,4,4,3,4,4,4,3,4,
    4,4,4,3,5,3,4,4,4
]

let SUNNINGDALE_OLD_HCS: [Int] = [
    8,4,12,16,2,10,6,18,14,
    7,15,1,17,5,11,3,13,9
]
let SUNNINGDALE_OLD_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Championship",
        yardage: 6660,
        rating: 70.0,
        slope: 113
    ),
    TeeInfo(
        teeName: "Black",
        yardage: 6820,
        rating: 73.7,
        slope: 134
    )
]
private let ROYAL_DORNOCH_CHAMP_ID = UUID(uuidString: "B7A10000-0000-0000-0000-000000000007")!

let ROYAL_DORNOCH_CHAMP_PARS: [Int] = [
    4,3,4,4,4,3,4,4,5,
    3,4,5,3,4,4,4,4,4
]

let ROYAL_DORNOCH_CHAMP_HCS: [Int] = [
    12,6,14,4,18,8,2,16,10,
    11,3,7,15,1,17,5,13,9
]

let ROYAL_DORNOCH_CHAMP_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Blue",
        yardage: 6799,
        rating: 0.0,   // not shown → leave 0
        slope: 0
    )
]
private let ROYAL_ST_GEORGES_ID = UUID(uuidString: "B7A10000-0000-0000-0000-000000000008")!

let ROYAL_ST_GEORGES_PARS: [Int] = [
    4,4,3,4,4,3,5,4,4,
    4,3,4,4,5,4,3,4,4
]

let ROYAL_ST_GEORGES_HCS: [Int] = [
    10,8,16,2,6,18,14,4,12,
    9,7,15,3,13,1,17,5,11
]
let ROYAL_ST_GEORGES_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Championship",
        yardage: 7204,
        rating: 75.2,
        slope: 138
    )
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

// MARK: Sea Island — Seaside Course — Red — St Simons Island, GA
// Par 70 | 6,883 yds | Rating 73.8 | Slope 138
// Type: Resort | Architect: Davis Love III, Mark Love

private let SEA_ISLAND_SEASIDE_RED_ID = UUID(uuidString: "E1A00001-0000-0000-0000-000000000006")!

let SEA_ISLAND_SEASIDE_RED_PARS: [Int] = [
    4,4,3,4,4,3,5,4,4,
    4,4,3,4,4,5,4,3,4
]

let SEA_ISLAND_SEASIDE_RED_HCS: [Int] = [
    7,3,9,1,11,17,15,13,5,
    6,10,12,2,16,14,8,18,4
]

let SEA_ISLAND_SEASIDE_RED_TEES: [TeeInfo] = [
    TeeInfo(teeName: "RED", yardage: 6883, rating: 73.8, slope: 138)
]
// MARK: Sea Island — Retreat Course — Red — St Simons Island, GA
// Par 72 | 7,110 yds | Rating 73.9 | Slope 133
// Type: Resort | Architect: Davis Love III, Mark Love

private let SEA_ISLAND_RETREAT_RED_ID = UUID(uuidString: "E1A00001-0000-0000-0000-000000000012")!

let SEA_ISLAND_RETREAT_RED_PARS: [Int] = [
    5,4,3,4,4,4,3,5,4,
    5,4,3,4,4,4,3,5,4
]

let SEA_ISLAND_RETREAT_RED_HCS: [Int] = [
    13,5,11,1,7,17,15,9,3,
    16,6,14,8,2,10,18,12,4
]

let SEA_ISLAND_RETREAT_RED_TEES: [TeeInfo] = [
    TeeInfo(teeName: "RED", yardage: 7110, rating: 73.9, slope: 133)
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
// MARK: - Built-in: Erin Hills (Black)
// Erin, WI  •  Par 72  •  7715 yds  •  77.9 / 145
// =======================================================

private let ERIN_HILLS_ID = UUID(uuidString: "91FA20CB-83C8-4D06-8189-95D9DE5A86FC")!

let ERIN_HILLS_BLACK_PARS: [Int] = [
    5,4,4,4,4,3,5,4,3,
    4,4,4,3,5,4,3,4,5
]

let ERIN_HILLS_BLACK_HCS: [Int] = [
    3,13,7,11,9,15,1,5,17,
    4,14,10,18,2,12,16,8,6
]

let ERIN_HILLS_BLACK_YARDS: [Int] = [
    552,361,476,445,462,237,607,492,163,
    504,423,464,212,613,370,190,481,663
]

let ERIN_HILLS_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7715, rating: 77.9, slope: 145)
]

// =======================================================
// MARK: - Built-in: Calusa Pines (Gold)
// Naples, FL  •  Par 72  •  7119 yds  •  75.2 / 143
// =======================================================

private let CALUSA_PINES_ID = UUID(uuidString: "0F70F061-4A22-462F-BFF1-5A541D160774")!

let CALUSA_PINES_GOLD_PARS: [Int] = [
    4,5,3,4,4,5,3,4,4,
    4,3,4,5,4,4,3,4,5
]

let CALUSA_PINES_GOLD_HCS: [Int] = [
    9,7,15,5,1,11,13,17,3,
    8,18,2,6,12,4,16,10,14
]

let CALUSA_PINES_GOLD_YARDS: [Int] = [
    414,569,145,464,449,538,239,298,444,
    422,194,453,607,336,439,180,418,510
]

let CALUSA_PINES_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Gold", yardage: 7119, rating: 75.2, slope: 143)
]

// =======================================================
// MARK: - Built-in: Karoo (Black)
// Brooksville, FL  •  Par 72  •  7562 yds  •  75.2 / 140
// NOTE: Your screenshots did NOT show HCPs, so this is a TODO.
// =======================================================

private let KAROO_ID = UUID(uuidString: "0C6A3D27-1783-4AC1-9B41-0E2F70C7CDEE")!

let KAROO_BLACK_PARS: [Int] = [
    4,4,3,5,4,5,3,4,4,
    3,4,4,4,5,4,3,5,4
]

let KAROO_BLACK_YARDS: [Int] = [
    475,522,292,511,382,563,199,426,421,
    242,427,496,447,581,388,201,500,489
]


let KAROO_BLACK_HCS_TODO: [Int] = [
    9,7,1,17,5,15,13,11,3,8,14,4,2,12,16,10,18,6
]

let KAROO_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7562, rating: 75.2, slope: 140),
    TeeInfo(teeName: "Green", yardage: 6954, rating: 72.3, slope: 135),
    TeeInfo(teeName: "Tangerine", yardage: 6431, rating: 70.0, slope: 123),
    TeeInfo(teeName: "Hybrid", yardage: 6009, rating: 68.0, slope: 119),
    TeeInfo(teeName: "Silver", yardage: 5325, rating: 64.9, slope: 109)
]

// =======================================================
// MARK: - Built-in: Patriot GC (4 Star)
// Owasso, OK  •  Par 72  •  7094 yds  •  74.7 / 144
// =======================================================

private let PATRIOT_GC_ID = UUID(uuidString: "62BE8D82-63CC-42C0-9F89-055629241C25")!

let PATRIOT_GC_4STAR_PARS: [Int] = [
    5,4,4,5,4,3,4,4,3,
    5,3,4,3,4,5,5,3,4
]

let PATRIOT_GC_4STAR_HCS: [Int] = [
    7,9,1,5,11,15,17,3,13,
    2,14,10,18,6,8,12,16,4
]

let PATRIOT_GC_4STAR_YARDS: [Int] = [
    560,426,482,493,315,138,387,476,240,
    603,172,424,188,474,567,548,171,430
]

let PATRIOT_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "4 Star", yardage: 7094, rating: 74.7, slope: 144)
]

// =======================================================
// MARK: - Built-in: Augusta National (Masters)
// Augusta, GA  •  Par 72  •  7485 yds  •  76.2 / 148
// =======================================================

private let AUGUSTA_NATIONAL_ID = UUID(uuidString: "41BFA11C-487A-44AA-A126-5F9030347364")!

let AUGUSTA_NATIONAL_MASTERS_PARS: [Int] = [
    4,5,4,3,4,3,4,5,4,
    4,4,3,5,4,5,3,4,4
]

let AUGUSTA_NATIONAL_MASTERS_HCS: [Int] = [
    9,1,13,15,5,17,11,3,7,
    6,8,16,4,12,2,18,14,10
]

let AUGUSTA_NATIONAL_MASTERS_YARDS: [Int] = [
    455,575,350,240,495,180,450,570,460,
    495,505,155,510,440,530,170,440,465
]

let AUGUSTA_NATIONAL_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Masters", yardage: 7485, rating: 76.2, slope: 148)
]

// =======================================================
// MARK: - Built-in: Forest Highlands – Meadow (White tees)
// Flagstaff, AZ  •  Par 72  •  Total yardage (White): 6478
// NOTE: Rating/Slope not shown on your scorecard image.
// =======================================================

private let FOREST_HIGHLANDS_MEADOW_ID = UUID(uuidString: "E94A3D13-5CDE-41A6-88B2-3226D8A2A48C")!

let FOREST_HIGHLANDS_MEADOW_PARS: [Int] = [
    4,3,3,4,5,4,4,3,4,
    4,3,4,4,5,4,4,3,5
]

let FOREST_HIGHLANDS_MEADOW_MENS_HCS: [Int] = [
    11,17,5,9,3,15,7,13,1,
    12,18,16,8,2,10,4,14,6
]

let FOREST_HIGHLANDS_MEADOW_WHITE_YARDS: [Int] = [
    392,176,510,397,501,392,389,150,387,
    368,186,310,405,521,373,411,201,509
]

let FOREST_HIGHLANDS_MEADOW_TEES: [TeeInfo] = [
    TeeInfo(teeName: "White", yardage: 6478, rating: nil, slope: nil)
]



// MARK: The Harvester GC — Black (Harvester, IA)
// Par 72 | 7,463 yds | Rating 76.8 | Slope 148
private let HARVESTER_GC_BLACK_ID = UUID(uuidString: "E2D7C4B1-2A61-4F5E-9B4B-2F1B3A5D7C91")!

let HARVESTER_GC_BLACK_PARS: [Int] = [
    4,4,3,5,4,5,4,3,4,
    4,4,4,4,3,5,4,3,5
]
let HARVESTER_GC_BLACK_HCS: [Int] = [
    12,10,16,2,14,4,8,18,6,
    5,13,7,11,17,1,9,15,3
]
let HARVESTER_GC_BLACK_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7463, rating: 76.8, slope: 148)
]

// MARK: Davenport CC — Black (Pleasant Valley, IA)
// Par 70 | 6,790 yds | Rating 73.7 | Slope 140
private let DAVENPORT_CC_BLACK_ID = UUID(uuidString: "8C5F1D3A-3B19-4F2E-9A7D-1C6B7E2A0D44")!

let DAVENPORT_CC_BLACK_PARS: [Int] = [
    4,5,4,4,3,4,4,3,5,
    3,4,4,5,4,3,4,3,4
]
let DAVENPORT_CC_BLACK_HCS: [Int] = [
    11,5,9,3,13,15,1,17,7,
    10,6,16,12,4,18,2,14,8
]
let DAVENPORT_CC_BLACK_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6790, rating: 73.7, slope: 140)
]

// MARK: TPC Deere Run — TPC (Silvis, IL)
// Par 71 | 7,281 yds | Rating 75.5 | Slope 139
private let TPC_DEERE_RUN_TPC_ID = UUID(uuidString: "F7B3A2C1-1E9C-4C3A-8D2B-7A0E4B9C6F10")!

let TPC_DEERE_RUN_TPC_PARS: [Int] = [
    4,5,3,4,4,4,3,4,4,
    5,4,3,4,4,4,3,5,4
]
let TPC_DEERE_RUN_TPC_HCS: [Int] = [
    17,7,9,3,5,13,15,11,1,
    8,6,12,18,16,2,14,10,4
]
let TPC_DEERE_RUN_TPC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "TPC", yardage: 7281, rating: 75.5, slope: 139)
]
private let KIAWAH_OCEAN_CHAMP_ID =
UUID(uuidString: "A1111111-1111-1111-1111-111111111111")!
let KIAWAH_OCEAN_CHAMP_PARS: [Int] = [
    4,5,4,4,3,4,5,3,4,
    4,5,4,4,3,4,5,3,4
]
let KIAWAH_OCEAN_CHAMP_HCS: [Int] = [
    15,3,9,1,11,13,7,17,5,
    16,8,10,2,14,18,4,12,6
]
let KIAWAH_OCEAN_CHAMP_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Championship",
        yardage: 7772,
        rating: 79.1,
        slope: 155
    )
]
// MARK: - PGA WEST (Stadium Course)

private let PGA_WEST_STADIUM_ID = UUID(uuidString: "A1E41C91-6C52-4D1E-8D5D-2A3A9C3F7101")!

let PGA_WEST_STADIUM_PARS: [Int] = [
4,4,4,3,5,3,4,5,4,
4,5,4,3,4,4,5,3,4
]

let PGA_WEST_STADIUM_HCS: [Int] = [
9,15,1,17,5,7,11,13,3,
6,8,18,10,12,2,16,14,4
]

let PGA_WEST_STADIUM_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 7300,
        rating: 76.0,
        slope: 148
    )
]
// MARK: - Pelican Hill Golf Club (Ocean North)

private let PELICAN_HILL_OCEAN_NORTH_ID = UUID(uuidString: "B2F52D02-7A63-4E2F-9C6E-3B4BA4D87202")!

let PELICAN_HILL_OCEAN_NORTH_PARS: [Int] = [
5,3,4,4,4,3,4,5,4,
4,4,3,4,4,4,3,5,4
]

let PELICAN_HILL_OCEAN_NORTH_HCS: [Int] = [
13,15,11,3,7,17,1,9,5,
4,14,16,12,8,2,18,6,10
]

let PELICAN_HILL_OCEAN_NORTH_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 6924,
        rating: 73.5,
        slope: 137
    )
]
// MARK: - La Costa Resort & Spa (North Course)

private let LA_COSTA_NORTH_ID = UUID(uuidString: "C3A63E13-8B74-4F30-A71F-4C5CB5E98303")!

let LA_COSTA_NORTH_PARS: [Int] = [
4,5,3,4,4,5,4,3,4,
5,4,3,4,4,4,3,4,5
]

let LA_COSTA_NORTH_HCS: [Int] = [
11,9,15,7,17,1,3,13,5,
14,16,12,2,6,8,18,10,4
]

let LA_COSTA_NORTH_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "I",
        yardage: 7500,
        rating: 77.8,
        slope: 146
    )
    
]
// MARK: - Yocha Dehe Golf Club at Cache Creek

private let YOCHA_DEHE_ID = UUID(uuidString: "D4B74F24-9C85-4031-B82A-5D6DC6FA9404")!

let YOCHA_DEHE_PARS: [Int] = [
4,5,4,3,4,5,3,4,4,
5,4,4,3,4,4,3,5,4
]

let YOCHA_DEHE_HCS: [Int] = [
5,7,1,15,13,3,11,17,9,
6,14,16,10,8,12,18,4,2
]

let YOCHA_DEHE_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 7222,
        rating: 75.2,
        slope: 142
    )
]
// =======================================================
// MARK: - Built-in: La Estancia Golf Resort (Tournament)
// Dominican Republic  •  Par 72  •  7382 yds  •  78.2 / 137
// =======================================================

private let LA_ESTANCIA_ID = UUID(uuidString: "C29B2E0F-4D95-4DBE-B580-908D4C71B381")!

let LA_ESTANCIA_TOURNAMENT_PARS: [Int] = [
    4,5,3,4,3,4,5,4,4,
    4,3,5,4,4,3,5,4,4
]

let LA_ESTANCIA_TOURNAMENT_HCS: [Int] = [
    11,5,9,17,15,1,13,7,3,
    14,18,4,16,2,12,8,10,6
]

let LA_ESTANCIA_TOURNAMENT_YARDS: [Int] = [
    430,555,236,365,138,455,510,449,469,
    429,174,594,339,454,195,666,452,472
]

let LA_ESTANCIA_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Tournament", yardage: 7382, rating: 78.2, slope: 137)
]
//=======================================================
// MARK: - Built-in: Rock Creek Cattle Company (TEE I)
// Deer Lodge, MT • Private • Architect: Tom Doak
// 7486 yds • 75.9 rating • 153 slope • Par 71
//=======================================================

private let ROCK_CREEK_CATTLE_COMPANY_ID = UUID(uuidString: "B6A6C9D4-0E3A-4C2E-9F2A-7A6E2D0C1B55")!

let ROCK_CREEK_CATTLE_COMPANY_TEE_I_PARS: [Int] = [
    4,4,5,4,4,4,4,3,4,
    5,4,3,3,4,4,4,3,5
]

let ROCK_CREEK_CATTLE_COMPANY_TEE_I_HCS: [Int] = [
    9,3,13,1,17,7,5,15,11,
    12,4,16,10,2,18,6,14,8
]

let ROCK_CREEK_CATTLE_COMPANY_TEE_I_YARDS: [Int] = [
    435,471,577,457,354,443,486,193,403,
    632,439,175,265,548,352,467,191,598
]

let ROCK_CREEK_CATTLE_COMPANY_TEES: [TeeInfo] = [
    TeeInfo(teeName: "TEE I", yardage: 7486, rating: 75.9, slope: 153)
]
// MARK: Wade Hampton Club — Cashiers, NC (Tom Fazio)
private let WADE_HAMPTON_CLUB_ID = UUID(uuidString: "A0F2F5C3-9AC5-4D86-9A1F-0B6D77F6A101")!
let WADE_HAMPTON_CLUB_PARS_TODO: [Int] = [
    5,4,3,5,4,3,4,4,4,
    5,3,4,4,4,4,4,3,5
]
let WADE_HAMPTON_CLUB_HCS_TODO:  [Int] = [7,5,15,1,3,17,13,11,9,8,18,14,12,10,6,2,16,4]

// MARK: Estancia — Scottsdale, AZ (Tom Fazio)
private let ESTANCIA_ID = UUID(uuidString: "A0F2F5C3-9AC5-4D86-9A1F-0B6D77F6A102")!
let ESTANCIA_PARS_TODO: [Int] = [4,4,3,5,4,4,3,4,5,4,3,4,4,5,4,3,5,4]

let ESTANCIA_HCS_TODO:  [Int] = [9,7,17,5,1,13,15,3,11,14,18,8,10,2,4,16,12,6]
   
// MARK: Sand Valley (Lido) — Nekoosa, WI (Macdonald/Raynor/Doak/Schneider)
private let SAND_VALLEY_LIDO_ID = UUID(uuidString: "A0F2F5C3-9AC5-4D86-9A1F-0B6D77F6A103")!
let SAND_VALLEY_LIDO_PARS_TODO: [Int] = [4,4,3,5,4,5,5,3,4,4,4,4,4,3,4,3,5,4]

let SAND_VALLEY_LIDO_HCS_TODO:  [Int] = [11,7,15,1,13,3,5,9,17,6,8,2,16,18,10,12,4,14]

// MARK: Colorado Golf Club — Parker, CO (Bill Coore/Ben Crenshaw)
private let COLORADO_GOLF_CLUB_ID = UUID(uuidString: "A0F2F5C3-9AC5-4D86-9A1F-0B6D77F6A104")!
// MARK: Colorado Golf Club — Championship
// 7,571 yds | Par 72

let COLORADO_GOLF_CLUB_PARS: [Int] = [
    5,3,4,4,4,3,5,4,4,
    4,3,4,4,4,5,5,3,4
]
let COLORADO_GOLF_CLUB_HCS: [Int] = [
    13,11,7,3,1,17,9,15,5,
    8,14,2,12,18,6,10,16,4
]

// MARK: The Quarry at La Quinta — La Quinta, CA (Tom Fazio)
private let QUARRY_LA_QUINTA_ID = UUID(uuidString: "A0F2F5C3-9AC5-4D86-9A1F-0B6D77F6A105")!
let QUARRY_LA_QUINTA_PARS: [Int] = [
    4,4,3,4,4,5,4,3,5,
    4,4,3,5,4,4,3,4,5
]
let QUARRY_LA_QUINTA_HCS: [Int] = [
    9,5,17,7,1,13,3,15,11,
    10,6,18,2,8,4,16,14,12
]

// MARK: Martis Camp — Truckee, CA (Tom Fazio)
private let MARTIS_CAMP_ID = UUID(uuidString: "A0F2F5C3-9AC5-4D86-9A1F-0B6D77F6A106")!
let MARTIS_CAMP_MEDAL_PARS: [Int] = [
    4,4,3,5,4,4,5,3,4,
    5,4,4,4,3,5,4,3,4
]

let MARTIS_CAMP_MEDAL_HCS: [Int] = [
    11,5,15,13,1,7,9,17,3,
    8,4,10,2,18,12,14,16,6
]

// MARK: Shooting Star — Teton Village, WY (Tom Fazio)
private let SHOOTING_STAR_ID = UUID(uuidString: "A0F2F5C3-9AC5-4D86-9A1F-0B6D77F6A107")!
let SHOOTING_STAR_CHAMPIONSHIP_PARS: [Int] = [
    4,3,5,4,4,3,4,4,5,
    3,5,4,4,4,5,4,3,4
]

let SHOOTING_STAR_CHAMPIONSHIP_HCS: [Int] = [
    11,17,5,9,1,15,13,3,7,
    18,8,10,14,2,6,12,16,4
]
// MARK: Cornerstone — Montrose, CO (Greg Norman)
private let CORNERSTONE_ID = UUID(uuidString: "A0F2F5C3-9AC5-4D86-9A1F-0B6D77F6A108")!
let CORNERSTONE_PARS_TODO: [Int] = [4,5,3,4,3,5,3,4,5,4,3,4,5,4,4,5,3,4]
let CORNERSTONE_HCS_TODO:  [Int] = [15,7,11,5,3,1,17,3,9,12,10,2,4,14,18,6,16,8]

// MARK: Manele Golf Course — Nicklaus — Lanai City, HI
// Par 72 | 7,039 yds | Rating 74.0 | Slope 134 | Type: Resort | Architect: Jack Nicklaus

private let MANELE_GOLF_COURSE_NICKLAUS_ID = UUID(uuidString: "E1A00001-0000-0000-0000-000000000001")!

let MANELE_GOLF_COURSE_NICKLAUS_PARS: [Int] = [
    4,4,3,5,4,5,3,3,5,
    4,5,3,4,3,5,4,4,4
]

let MANELE_GOLF_COURSE_NICKLAUS_HCS: [Int] = [
    13,3,17,11,1,9,15,5,7,
    14,10,8,18,16,12,4,2,6
]

let MANELE_GOLF_COURSE_NICKLAUS_TEES: [TeeInfo] = [
    TeeInfo(teeName: "NICKLAUS", yardage: 7039, rating: 74.0, slope: 134)
]

// MARK: Pinehurst No. 10 — Blue Tees — Pinehurst, NC
// Par 70 | 7,020 yds | Rating 74.1 | Slope 142 | Type: Resort

private let PINEHURST_NO10_BLUE_ID = UUID(uuidString: "E1A00001-0000-0000-0000-000000000002")!

let PINEHURST_NO10_BLUE_PARS: [Int] = [
    4,3,5,4,4,4,3,4,4,
    5,3,5,4,3,4,4,3,4
]

let PINEHURST_NO10_BLUE_HCS: [Int] = [
    5,13,11,15,9,1,17,7,3,
    6,14,16,2,10,12,4,18,8
]

let PINEHURST_NO10_BLUE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue Tees", yardage: 7020, rating: 74.1, slope: 142)
]

// MARK: Gamble Sands — Medal — Brewster, WA
// Par 72 | 7,184 yds | Rating 73.7 | Slope 125 | Type: Daily-Fee | Architect: David McLay Kidd

private let GAMBLE_SANDS_ID = UUID(uuidString: "7C8E2C4D-0B3A-4F7F-8A11-100000000301")!

let GAMBLE_SANDS_PARS: [Int] = [
    4,4,5,3,4,3,5,4,4,
    3,4,4,5,4,4,3,4,5
]

let GAMBLE_SANDS_HCS: [Int] = [
    7,11,1,15,5,13,3,17,9,
    14,6,18,12,2,8,10,4,16
]

let GAMBLE_SANDS_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Medal",        yardage: 7151, rating: 73.4, slope: 120),
    TeeInfo(teeName: "Back",         yardage: 6664, rating: 70.7, slope: 114),
    TeeInfo(teeName: "Sands",        yardage: 6389, rating: 69.4, slope: 111),
    TeeInfo(teeName: "Regular",      yardage: 6113, rating: 68.6, slope: 109),
    TeeInfo(teeName: "Intermediate", yardage: 5623, rating: 66.0, slope: 103),
    TeeInfo(teeName: "Forward",      yardage: 4804, rating: 66.4, slope: 102)
]
// MARK: - Scarecrow

private let SCARECROW_ID = UUID(uuidString: "9B4A1A52-1C33-4D1B-8D11-100000000402")!

let SCARECROW_PARS: [Int] = [
    4,3,5,3,4,5,4,4,3,
    4,3,5,4,4,5,3,4,4
]

let SCARECROW_HCS: [Int] = [
    3,9,11,5,17,15,1,7,13,
    4,18,16,8,2,10,12,6,14
]

let SCARECROW_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Medal",        yardage: 6921, rating: 73.9, slope: 131),
    TeeInfo(teeName: "Back",         yardage: 6501, rating: 71.1, slope: 127),
    TeeInfo(teeName: "Sands",        yardage: 6261, rating: 70.0, slope: 122),
    TeeInfo(teeName: "Regular",      yardage: 6061, rating: 69.1, slope: 119),
    TeeInfo(teeName: "Intermediate", yardage: 5204, rating: 65.3, slope: 113),
    TeeInfo(teeName: "Forward",      yardage: 4656, rating: 66.9, slope: 110)
]

// MARK: Kapalua Resort – Plantation — Tournament — Lahaina, HI
// Par 73 | 7,596 yds | Rating 77.0 | Slope 144 | Type: Resort | Architect: Bill Coore & Ben Crenshaw

private let KAPALUA_PLANTATION_TOURNAMENT_ID = UUID(uuidString: "E1A00001-0000-0000-0000-000000000004")!

let KAPALUA_PLANTATION_TOURNAMENT_PARS: [Int] = [
    4,3,4,4,5,4,4,3,5,
    4,3,4,4,4,5,4,4,5
]

let KAPALUA_PLANTATION_TOURNAMENT_HCS: [Int] = [
    11,17,3,9,7,13,5,15,1,
    10,18,14,4,16,6,12,2,8
]

let KAPALUA_PLANTATION_TOURNAMENT_TEES: [TeeInfo] = [
    TeeInfo(teeName: "TOURNAMENT", yardage: 7596, rating: 77.0, slope: 144)
]



// MARK: McLemore — The Keep — Rising Fawn, GA
// Par 72 | 6,654 yds (Black) | Architect: Bill Bergen & Rees Jones | Type: Resort

private let MCLEMORE_KEEP_ID = UUID(uuidString: "E1A00001-0000-0000-0000-000000000005")!

let MCLEMORE_KEEP_PARS: [Int] = [
    4,5,3,4,4,4,5,3,4,
    5,3,4,4,3,5,4,4,4
]

let MCLEMORE_KEEP_HCS: [Int] = [
    1,7,11,5,15,17,13,9,3,
    6,10,18,2,8,14,4,16,12
]

let MCLEMORE_KEEP_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6654)
]
// MARK: Sand Valley Resort — Sedge Valley — Championship — Nekoosa, WI
// Par 68 | 6,198 yds | Rating 70.7 | Slope 133
// Type: Private (Resort) | Architect: Tom Doak   // (set to nil if you don’t want to assume)

private let SAND_VALLEY_SEDGE_VALLEY_CHAMPIONSHIP_ID = UUID(uuidString: "E1A00001-0000-0000-0000-000000000008")!

let SAND_VALLEY_SEDGE_VALLEY_CHAMPIONSHIP_PARS: [Int] = [
    4,4,4,4,3,4,3,3,4,
    4,5,4,3,4,3,4,4,4
]

let SAND_VALLEY_SEDGE_VALLEY_CHAMPIONSHIP_HCS: [Int] = [
    13,9,1,3,7,15,17,11,5,
    8,2,14,18,6,16,4,10,12
]

let SAND_VALLEY_SEDGE_VALLEY_CHAMPIONSHIP_TEES: [TeeInfo] = [
    TeeInfo(teeName: "CHAMPIONSHIP", yardage: 6198, rating: 70.7, slope: 133)
]

// MARK: Arcadia Bluffs — The Bluffs Course — Blue — Arcadia, MI
// Par 72 | 6,858 yds | Rating 74.2 | Slope 150
// Type: Daily-Fee | Architect: W. Henderson, R. Smith

private let ARCADIA_BLUFFS_BLUFFS_BLUE_ID = UUID(uuidString: "E1A00001-0000-0000-0000-000000000007")!

let ARCADIA_BLUFFS_BLUFFS_BLUE_PARS: [Int] = [
    5,3,5,4,5,3,4,4,3,
    4,5,4,3,4,5,4,3,4
]

let ARCADIA_BLUFFS_BLUFFS_BLUE_HCS: [Int] = [
    15,17,7,13,3,9,1,5,11,
    2,12,10,8,14,18,4,16,6
]

let ARCADIA_BLUFFS_BLUFFS_BLUE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "BLUE", yardage: 6858, rating: 74.2, slope: 150)
]
// MARK: The Old White — Greenbrier — White Sulphur Springs, WV
private let OLD_WHITE_GREENBRIER_ID = UUID(uuidString: "F2010001-0000-0000-0000-000000000001")!

let OLD_WHITE_GREENBRIER_PARS: [Int] = [
    4,4,3,4,4,4,4,3,4,
    4,4,5,4,4,3,4,5,3
]

let OLD_WHITE_GREENBRIER_HCS: [Int] = [
    3,5,17,13,11,1,7,15,9,
    14,12,2,6,10,16,8,4,18
]

let OLD_WHITE_GREENBRIER_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7246, rating: 76.0, slope: 145),
    TeeInfo(teeName: "Gold",  yardage: 6894, rating: 74.1, slope: 137),
    TeeInfo(teeName: "Blue",  yardage: 6426, rating: 71.7, slope: 130),
    TeeInfo(teeName: "White", yardage: 5853, rating: 69.1, slope: 127),
    TeeInfo(teeName: "Green", yardage: 5062, rating: 64.2, slope: 113)
]

// MARK: The Greenbrier Course — White Sulphur Springs, WV
private let GREENBRIER_COURSE_ID = UUID(uuidString: "F2010001-0000-0000-0000-000000000002")!

let GREENBRIER_COURSE_PARS: [Int] = [
    4,4,5,3,5,4,3,4,3,
    4,5,3,5,4,3,4,3,5
]

let GREENBRIER_COURSE_HCS: [Int] = [
    9,5,11,13,3,1,15,7,17,
    6,12,14,4,2,16,8,18,10
]

let GREENBRIER_COURSE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Gold",  yardage: 6655, rating: 72.5, slope: 132),
    TeeInfo(teeName: "Blue",  yardage: 6377, rating: 71.5, slope: 129),
    TeeInfo(teeName: "White", yardage: 6003, rating: 68.9, slope: 119),
    TeeInfo(teeName: "Green", yardage: 5057, rating: 65.5, slope: 115)
]

// MARK: Conway Farms GC — Lake Forest, IL
private let CONWAY_FARMS_ID = UUID(uuidString: "F2010001-0000-0000-0000-000000000003")!

let CONWAY_FARMS_PARS: [Int] = [
    4,3,4,4,4,3,4,5,4,
    4,3,4,4,5,4,4,3,5
]

let CONWAY_FARMS_HCS: [Int] = [
    11,17,9,3,1,13,15,5,7,
    10,18,12,2,6,14,4,16,8
]

let CONWAY_FARMS_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black",     yardage: 7233, rating: 76.3, slope: 152),
    TeeInfo(teeName: "Green",     yardage: 6803, rating: nil,  slope: nil),
    TeeInfo(teeName: "Blue Plus", yardage: 6609, rating: nil,  slope: nil),
    TeeInfo(teeName: "Blue",      yardage: 6294, rating: nil,  slope: nil),
    TeeInfo(teeName: "Classic",   yardage: 6147, rating: nil,  slope: nil),
    TeeInfo(teeName: "White",     yardage: 5939, rating: nil,  slope: nil),
    TeeInfo(teeName: "Gold Plus", yardage: 5469, rating: nil,  slope: nil),
    TeeInfo(teeName: "Gold",      yardage: 5146, rating: nil,  slope: nil)
]

// MARK: The Links at Spanish Bay — Pebble Beach, CA
private let SPANISH_BAY_ID = UUID(uuidString: "F2010001-0000-0000-0000-000000000004")!

let SPANISH_BAY_PARS: [Int] = [
    5,4,4,3,4,4,4,3,4,
    5,4,4,3,5,4,3,4,5
]

let SPANISH_BAY_HCS: [Int] = [
    9,13,5,15,1,11,3,17,7,
    8,14,6,18,2,12,16,4,10
]

let SPANISH_BAY_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue",  yardage: 6739, rating: 73.8, slope: 143),
    TeeInfo(teeName: "Gold",  yardage: 6428, rating: 72.4, slope: 135),
    TeeInfo(teeName: "White", yardage: 6037, rating: 71.7, slope: 133),
    TeeInfo(teeName: "Green", yardage: 5720, rating: 69.3, slope: 127),
    TeeInfo(teeName: "Red",   yardage: 5218, rating: 67.3, slope: 114)
]
// =======================================================
// MARK: - Built-in: French Lick Resort – Pete Dye
// French Lick, IN • Resort • Pete Dye
// Gold: Par 72 | 8,102 yds | 80.5 / 151
// =======================================================

private let FRENCH_LICK_PETE_DYE_ID = UUID(uuidString: "A1F10001-0000-0000-0000-000000000001")!

let FRENCH_LICK_PETE_DYE_PARS: [Int] = [
    4,4,5,3,4,4,5,3,4,
    4,4,4,3,5,4,3,4,5
]

let FRENCH_LICK_PETE_DYE_HCS: [Int] = [
    7,13,1,11,15,5,9,17,3,
    14,10,4,18,8,16,6,12,2
]

let FRENCH_LICK_PETE_DYE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Gold", yardage: 8102, rating: 80.5, slope: 151)
]

// =======================================================
// MARK: - Built-in: French Lick Resort – Donald Ross
// French Lick, IN • Resort • Donald Ross
// Gold Medal: Par 70 | 7,030 yds | 75.7 / 149
// =======================================================

private let FRENCH_LICK_DONALD_ROSS_ID = UUID(uuidString: "A1F10001-0000-0000-0000-000000000002")!

let FRENCH_LICK_DONALD_ROSS_PARS: [Int] = [
    4,4,4,3,4,3,5,4,4,
    4,4,4,3,4,5,3,4,4
]

let FRENCH_LICK_DONALD_ROSS_HCS: [Int] = [
    5,17,7,15,3,11,1,9,13,
    12,16,8,6,10,2,18,14,4
]

let FRENCH_LICK_DONALD_ROSS_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Gold Medal", yardage: 7030, rating: 75.7, slope: 149)
]

// =======================================================
// MARK: - Built-in: Silvies Valley Resort & Links – Craddock
// Seneca, OR • Resort
// Challenge: Par 72 | 7,170 yds | 73.8 / 132
// =======================================================

private let SILVIES_CRADDOCK_ID = UUID(uuidString: "A1F10001-0000-0000-0000-000000000003")!

let SILVIES_CRADDOCK_PARS: [Int] = [
    5,4,4,3,5,4,3,4,4,
    3,4,3,5,5,4,4,4,4
]

let SILVIES_CRADDOCK_HCS: [Int] = [
    13,5,17,15,11,1,3,9,7,
    8,4,10,14,6,16,2,18,12
]

let SILVIES_CRADDOCK_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Challenge", yardage: 7170, rating: 73.8, slope: 132)
]

// =======================================================
// MARK: - Built-in: ArborLinks
// Nebraska City, NE • Private • Arnold Palmer
// Black: Par 72 | 7,222 yds | 75.4 / 141
// =======================================================

private let ARBORLINKS_ID = UUID(uuidString: "A1F10001-0000-0000-0000-000000000004")!

let ARBORLINKS_PARS: [Int] = [
    5,4,3,5,4,3,4,4,4,
    5,3,4,4,3,4,5,4,4
]

let ARBORLINKS_HCS: [Int] = [
    12,14,18,2,8,16,10,4,6,
    11,15,7,13,17,1,5,3,9
]

let ARBORLINKS_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7222, rating: 75.4, slope: 141)
]
// =======================================================
// MARK: - Built-in: Mid Pines
// Southern Pines, NC • Resort • Donald Ross
// Medal: Par 72 | 6,710 yds | 73.5 / 142
// =======================================================

private let MID_PINES_ID = UUID(uuidString: "A1F10001-0000-0000-0000-000000000101")!

let MID_PINES_PARS: [Int] = [
    4,3,4,4,5,5,4,3,4,
    5,3,4,3,4,5,4,4,4
]

let MID_PINES_HCS: [Int] = [
    5,15,7,13,9,1,3,17,11,
    2,18,8,10,16,12,6,14,4
]

let MID_PINES_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Medal", yardage: 6710, rating: 73.5, slope: 142)
]

// =======================================================
// MARK: - Built-in: Makai Course
// Princeville, HI • Resort • Robert Trent Jones Jr.
// Black: Par 72 | 7,223 yds | 75.4 / 134
// =======================================================

private let MAKAI_COURSE_ID = UUID(uuidString: "A1F10001-0000-0000-0000-000000000102")!

let MAKAI_COURSE_PARS: [Int] = [
    4,5,3,4,5,4,3,4,4,
    4,5,4,3,4,4,3,4,5
]

let MAKAI_COURSE_HCS: [Int] = [
    13,9,15,1,11,3,7,17,5,
    6,14,2,4,18,10,12,8,16
]

let MAKAI_COURSE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7223, rating: 75.4, slope: 134)
]

// =======================================================
// MARK: - Built-in: Pine Needles
// Southern Pines, NC • Resort • Donald Ross
// Medal: Par 71 | 7,035 yds | 73.5 / 134
// =======================================================

private let PINE_NEEDLES_ID = UUID(uuidString: "A1F10001-0000-0000-0000-000000000103")!

let PINE_NEEDLES_PARS: [Int] = [
    5,4,3,4,3,4,4,4,4,
    5,4,4,3,4,5,3,4,4
]

let PINE_NEEDLES_HCS: [Int] = [
    11,5,17,9,7,1,3,15,13,
    4,12,14,16,2,6,18,8,10
]

let PINE_NEEDLES_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Medal", yardage: 7035, rating: 73.5, slope: 134)
]

// =======================================================
// MARK: - Built-in: Southern Pines Golf Club
// Southern Pines, NC • Resort • Donald Ross
// Medal routing: Par 71 | 6,695 yds | 73.8 / 139
// NOTE: Scorecard shows special dual-routing / Lost Hole layout.
// This setup uses the men's medal routing shown on the card.
// =======================================================

private let SOUTHERN_PINES_GC_ID = UUID(uuidString: "A1F10001-0000-0000-0000-000000000104")!

let SOUTHERN_PINES_GC_PARS: [Int] = [
    4,5,3,4,5,4,3,4,3,
    4,4,4,4,3,5,4,4,4
]

let SOUTHERN_PINES_GC_HCS: [Int] = [
    11,7,13,3,5,1,17,9,15,
    10,14,2,8,18,6,16,4,12
]

let SOUTHERN_PINES_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Medal", yardage: 6695, rating: 73.8, slope: 139)
]
// =======================================================
// MARK: - Built-in: Troon Country Club
// Scottsdale, AZ • Private • Jay Morrish / Tom Weiskopf
// Black: Par 72 | 6,707 yds | 73.0 / 136
// =======================================================

private let TROON_COUNTRY_CLUB_ID = UUID(uuidString: "A1F10001-0000-0000-0000-000000000105")!

let TROON_COUNTRY_CLUB_PARS: [Int] = [
    4,4,5,4,3,4,3,5,4,
    4,5,4,3,4,3,4,5,4
]

let TROON_COUNTRY_CLUB_HCS: [Int] = [
    7,3,15,17,9,1,11,13,5,
    4,14,8,16,2,18,12,6,10
]

let TROON_COUNTRY_CLUB_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6707, rating: 73.0, slope: 136)
]
// MARK: Top of the Rock

private let TOP_OF_THE_ROCK_ID = UUID(uuidString: "9E2B7F01-7C49-4D13-BD4E-9A1F88A6F101")!

let TOP_OF_THE_ROCK_PARS: [Int] = [
3,3,3,3,3,3,3,3,3
]

let TOP_OF_THE_ROCK_HCS: [Int] = [
8,9,1,3,2,5,7,4,6
]

let TOP_OF_THE_ROCK_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 1420, rating: 27.7, slope: nil),
    TeeInfo(teeName: "Red", yardage: 885, rating: 27.2, slope: nil)
]
// MARK: - Payne’s Valley (Big Cedar)
private let PAYNES_VALLEY_ID = UUID(uuidString: "B12A34CD-5678-4EF0-9ABC-1234567890AB")!

let PAYNES_VALLEY_PARS: [Int] = [
    4,3,4,5,3,4,4,5,4,
    3,4,4,5,4,4,3,4,5
]

let PAYNES_VALLEY_HCS: [Int] = [
    3,7,17,11,9,13,15,5,1,
    16,12,18,2,10,4,14,8,6
]

let PAYNES_VALLEY_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Tiger", yardage: 7370, rating: 75.6, slope: 132),
    TeeInfo(teeName: "Blue",  yardage: 6876, rating: 73.2, slope: 125),
    TeeInfo(teeName: "Combo", yardage: 6505, rating: 71.3, slope: 122),
    TeeInfo(teeName: "White", yardage: 6133, rating: 69.4, slope: 119),
    TeeInfo(teeName: "Red",   yardage: 4957, rating: 64.0, slope: 102)
]
// MARK: Cliffhangers

private let CLIFFHANGERS_ID = UUID(uuidString: "9E2B7F01-7C49-4D13-BD4E-9A1F88A6F103")!

let CLIFFHANGERS_PARS: [Int] = [
3,3,3,3,3,3,3,3,3,
3,3,3,3,3,3,3,3,3
]

let CLIFFHANGERS_HCS: [Int] = [
1,2,3,4,5,6,7,8,9,
10,11,12,13,14,15,16,17,18
]
// MARK: - Buffalo Ridge (Big Cedar)
private let BUFFALO_RIDGE_ID = UUID(uuidString: "C23B45DE-6789-4ABC-9DEF-1234567890AB")!

let BUFFALO_RIDGE_PARS: [Int] = [
    5,4,4,3,4,4,3,5,3,
    4,3,4,4,5,4,4,3,5
]

let BUFFALO_RIDGE_HCS: [Int] = [
    5,1,9,17,7,13,11,3,15,
    12,18,4,8,2,14,10,16,6
]

let BUFFALO_RIDGE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Buffalo", yardage: 7036, rating: 73.4, slope: 130),
    TeeInfo(teeName: "Blue",    yardage: 6616, rating: 71.4, slope: 127),
    TeeInfo(teeName: "Combo",   yardage: 6183, rating: 69.5, slope: 125),
    TeeInfo(teeName: "White",   yardage: 5881, rating: 67.5, slope: 123),
    TeeInfo(teeName: "W/R Combo", yardage: 5367, rating: 65.7, slope: 118),
    TeeInfo(teeName: "Red",     yardage: 5004, rating: 63.8, slope: 113)
]

// MARK: - The Prairie Club - Dunes Course

private let PRAIRIE_CLUB_DUNES_ID = UUID(uuidString: "A1F0C7D2-3C4A-4D69-9F12-100000000002")!

let PRAIRIE_CLUB_DUNES_PARS: [Int] = [
    4,4,5,3,4,5,3,4,4,
    5,4,5,4,3,5,3,4,4
]

let PRAIRIE_CLUB_DUNES_HCS: [Int] = [
    5,7,9,17,13,11,15,1,3,
    4,18,10,8,16,12,14,6,2
]
// MARK: - The Loop - Black Course

private let LOOP_BLACK_ID = UUID(uuidString: "A1F0C7D2-3C4A-4D69-9F12-100000000003")!

let LOOP_BLACK_PARS: [Int] = [
    4,3,4,4,3,5,4,3,4,
    5,4,4,3,4,3,4,5,4
]

let LOOP_BLACK_HCS: [Int] = [
    5,15,1,9,13,7,11,17,3,
    4,8,10,12,2,18,6,16,14
]
// MARK: - The Loop - Red Course

private let LOOP_RED_ID = UUID(uuidString: "A1F0C7D2-3C4A-4D69-9F12-100000000004")!

let LOOP_RED_PARS: [Int] = [
    4,5,4,3,4,3,4,4,5,
    4,3,4,5,3,4,4,3,4
]

let LOOP_RED_HCS: [Int] = [
    11,9,7,13,3,17,15,1,5,
    2,12,14,8,16,6,4,18,10
]
// MARK: - Forest Dunes

private let FOREST_DUNES_ID = UUID(uuidString: "A1F0C7D2-3C4A-4D69-9F12-100000000005")!

let FOREST_DUNES_PARS: [Int] = [
    4,4,3,4,5,4,5,4,3,
    4,3,4,4,4,5,3,4,5
]

let FOREST_DUNES_HCS: [Int] = [
    15,1,13,9,5,11,7,3,17,
    4,18,10,14,2,6,8,16,12
]
// MARK: - The Legend at Giants Ridge

private let THE_LEGEND_ID = UUID(uuidString: "A1F0C7D2-3C4A-4D69-9F12-100000000006")!

let THE_LEGEND_PARS: [Int] = [
    4, 4, 4, 4, 4, 4, 5, 4, 3,
    4, 3, 4, 4, 5, 4, 3, 4, 5
]

let THE_LEGEND_HCS: [Int] = [
    5, 1, 9, 17, 7, 13, 11, 3, 15,
    12, 18, 4, 8, 2, 14, 10, 16, 6
]

let THE_LEGEND_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7562, rating: 75.5, slope: 133),
    TeeInfo(teeName: "Blue", yardage: 6981, rating: 72.6, slope: 127),
    TeeInfo(teeName: "Blue/White", yardage: 6663, rating: 71.0, slope: 123)
]
// MARK: - The Quarry at Giants Ridge

private let THE_QUARRY_ID = UUID(uuidString: "A1F0C7D2-3C4A-4D69-9F12-100000000007")!

let THE_QUARRY_PARS: [Int] = [
    5, 4, 4, 4, 5, 4, 4, 3, 5,
    4, 3, 4, 4, 5, 4, 4, 3, 5
]

let THE_QUARRY_HCS: [Int] = [
    5, 1, 9, 17, 7, 13, 11, 3, 15,
    12, 18, 4, 8, 2, 14, 10, 16, 6
]

let THE_QUARRY_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Buffalo", yardage: 7036, rating: 73.4, slope: 130),
    TeeInfo(teeName: "Blue", yardage: 6616, rating: 71.4, slope: 127),
    TeeInfo(teeName: "Blue/White Combo", yardage: 6183, rating: 69.5, slope: 125),
    TeeInfo(teeName: "White", yardage: 5881, rating: 67.5, slope: 123),
    TeeInfo(teeName: "White/Red Combo", yardage: 5367, rating: 65.7, slope: 118),
    TeeInfo(teeName: "Red", yardage: 5004, rating: 63.8, slope: 113)
]
// MARK: - Richter Park Golf Course
private let RICHTER_PARK_GOLF_COURSE_ID = UUID(uuidString: "E3C2A8A1-7F5E-4B90-9B5D-0C6B1D2E3F41")!
let RICHTER_PARK_GOLF_COURSE_PARS: [Int] = [4,5,3,4,3,4,5,4,4, 3,4,5,3,4,4,5,3,4]
let RICHTER_PARK_GOLF_COURSE_HCS:  [Int] = [9,11,17,3,15,1,7,5,13, 14,10,6,16,8,12,4,18,2]

let RICHTER_PARK_GOLF_COURSE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue", yardage: 6547, rating: 71.3, slope: 130)
]

// MARK: - Lake of Isles
private let LAKE_OF_ISLES_ID = UUID(uuidString: "F4D3B9C2-8E6F-4A11-9C22-1D7E2F3A4B52")!

// North Course (Shell)
let LAKE_OF_ISLES_NORTH_PARS: [Int] = [5,3,4,4,5,4,3,4,4, 4,3,5,4,4,5,3,4,4]
let LAKE_OF_ISLES_NORTH_HCS:  [Int] = [6,14,8,18,12,4,16,10,2, 1,13,15,5,11,7,17,9,3]

let LAKE_OF_ISLES_NORTH_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7279, rating: 76.3, slope: 148),
    TeeInfo(teeName: "Gold", yardage: 6757, rating: 73.9, slope: 141),
    TeeInfo(teeName: "Gold/Silver", yardage: 6312, rating: 71.7, slope: 136),
    TeeInfo(teeName: "Silver", yardage: 6005, rating: 69.9, slope: 130),
    TeeInfo(teeName: "Copper", yardage: 5387, rating: 67.1, slope: 122),
    TeeInfo(teeName: "Jade", yardage: 4895, rating: 68.9, slope: 124)
]

// South Course (Turtle)
let LAKE_OF_ISLES_SOUTH_PARS: [Int] = [4,4,4,3,5,3,4,5,4, 4,3,4,4,5,4,3,5,4]
let LAKE_OF_ISLES_SOUTH_HCS:  [Int] = [9,1,15,11,17,13,7,5,3, 2,18,6,16,4,12,8,10,14]

let LAKE_OF_ISLES_SOUTH_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7346, rating: 76.2, slope: 141),
    TeeInfo(teeName: "Gold", yardage: 6845, rating: 74.0, slope: 136),
    TeeInfo(teeName: "Gold/Silver", yardage: 6524, rating: 72.1, slope: 133),
    TeeInfo(teeName: "Silver", yardage: 6278, rating: 71.4, slope: 130),
    TeeInfo(teeName: "Silver/Copper", yardage: 5535, rating: 67.3, slope: 125),
    TeeInfo(teeName: "Copper", yardage: 5231, rating: 65.6, slope: 122),
    TeeInfo(teeName: "Jade", yardage: 4858, rating: 68.3, slope: 123)
]

// MARK: - Brooklawn Country Club
private let BROOKLAWN_COUNTRY_CLUB_ID = UUID(uuidString: "A7B8C9D1-2E3F-4A5B-8C6D-7E8F9A0B1C62")!
let BROOKLAWN_COUNTRY_CLUB_PARS: [Int] = [4,3,4,4,3,4,5,5,4, 3,5,4,4,4,3,4,4,4]
let BROOKLAWN_COUNTRY_CLUB_HCS:  [Int] = [5,17,13,3,15,7,1,9,11, 18,2,14,4,6,16,12,8,10]

let BROOKLAWN_COUNTRY_CLUB_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6744, rating: 73.2, slope: 136)
]

// MARK: - Sterling Farms Golf Course
private let STERLING_FARMS_GC_ID = UUID(uuidString: "7C3F0C11-9C6B-4D4E-9F61-5C9E6F7E2A11")!

let STERLING_FARMS_GC_PARS: [Int] = [
4,5,4,4,3,5,4,3,4,
4,4,4,5,4,3,4,3,5
]
let STERLING_FARMS_GC_HCS: [Int] = [
11,15,17,1,7,13,9,3,5,
12,10,4,8,2,14,16,6,18
]
let STERLING_FARMS_GC_TEES: [TeeInfo] = [

TeeInfo(
teeName: "Black",
yardage: 6423,
rating: 71.5,
slope: 134
),

TeeInfo(
teeName: "Blue",
yardage: 6227,
rating: 70.4,
slope: 132
),

TeeInfo(
teeName: "White",
yardage: 5899,
rating: 69.3,
slope: 126
),

TeeInfo(
teeName: "Gold",
yardage: 5423,
rating: 66.4,
slope: 121
),

TeeInfo(
teeName: "Red",
yardage: 5402,
rating: 71.4,
slope: 122
)

]// MARK: - Grayhawk Golf Club (Talon)
private let GRAYHAWK_GC_TALON_ID = UUID(uuidString: "B4A5E1E3-8E12-4A47-8C12-9F87A0C54F01")!

let GRAYHAWK_GC_TALON_PARS: [Int] = [
4,4,5,4,3,4,4,3,5,
4,3,4,4,5,4,4,3,5
]

let GRAYHAWK_GC_TALON_HCS: [Int] = [
9,13,5,7,17,1,11,15,3,
4,16,2,14,10,8,12,18,6
]

let GRAYHAWK_GC_TALON_TEES: [TeeInfo] = [

    TeeInfo(
        teeName: "Talon",
        yardage: 6973,
        rating: 74.0,
        slope: 149
    ),

    TeeInfo(
        teeName: "Palo Verde",
        yardage: 6430,
        rating: 71.4,
        slope: 137
    ),

    TeeInfo(
        teeName: "Terra Cotta",
        yardage: 5867,
        rating: 68.8,
        slope: 124
    ),

    TeeInfo(
        teeName: "Heather",
        yardage: 5143,
        rating: 70.0,
        slope: 121
    )
    ]
    // MARK: - Grayhawk Golf Club (Raptor)
    private let GRAYHAWK_GC_RAPTOR_ID = UUID(uuidString: "9F5C2D44-8F3B-4C73-B8C6-2E4F0C7D9A22")!

    let GRAYHAWK_GC_RAPTOR_PARS: [Int] = [
    4,4,4,5,3,4,5,3,4,
    4,5,4,3,4,4,3,4,5
    ]

    let GRAYHAWK_GC_RAPTOR_HCS: [Int] = [
    10,16,4,2,14,12,8,18,6,
    9,1,5,7,13,11,17,15,3
    ]

    let GRAYHAWK_GC_RAPTOR_TEES: [TeeInfo] = [

    TeeInfo(
    teeName: "Raptor",
    yardage: 7221,
    rating: 74.7,
    slope: 142
    ),

    TeeInfo(
    teeName: "Palo Verde",
    yardage: 6526,
    rating: 71.7,
    slope: 137
    ),

    TeeInfo(
    teeName: "Terra Cotta",
    yardage: 6040,
    rating: 69.5,
    slope: 130
    ),

    TeeInfo(
    teeName: "L Terra Cotta",
    yardage: 5138,
    rating: 75.6,
    slope: 138
    ),

    TeeInfo(
    teeName: "Heather",
    yardage: 5175,
    rating: 70.6,
    slope: 122
    )

    ]
// MARK: - We-Ko-Pa Golf Club (Saguaro)

private let WEKOPA_SAGUARO_ID =
UUID(uuidString: "5A7D4C63-8D1B-4B42-9D6A-4B2F2E61A0C1")!
let WEKOPA_SAGUARO_PARS: [Int] = [
4,4,4,5,3,4,4,5,3,
4,3,4,4,5,3,4,4,4]

let WEKOPA_SAGUARO_HCS: [Int] = [
5,11,9,1,15,7,13,3,17,
14,18,6,8,2,16,12,10,4

]
let WEKOPA_SAGUARO_TEES: [TeeInfo] = [

TeeInfo(
teeName: "Cholla",
yardage: 7225,
rating: 74.6,
slope: 142
),

TeeInfo(
teeName: "Purple",
yardage: 6740,
rating: 72.5,
slope: 137
),

TeeInfo(
teeName: "Composite",
yardage: 6436,
rating: 71.0,
slope: 132
),

TeeInfo(
teeName: "White",
yardage: 6114,
rating: 69.3,
slope: 128
),

TeeInfo(
teeName: "Green",
yardage: 5289,
rating: 66.2,
slope: 118
)

]
// MARK: - We-Ko-Pa Golf Club (Cholla)

private let WEKOPA_CHOLLA_ID =
UUID(uuidString: "E5C82D52-9A51-4A9C-9E1C-74C9F9A1E7B2")!
let WEKOPA_CHOLLA_PARS: [Int] = [
4,5,3,4,3,4,4,5,4,
5,3,4,4,3,4,4,5,4
]
let WEKOPA_CHOLLA_HCS: [Int] = [
13,3,17,9,15,7,11,1,5,
4,16,10,12,18,14,6,2,8
]
let WEKOPA_CHOLLA_TEES: [TeeInfo] = [

TeeInfo(
teeName: "Cholla",
yardage: 7225,
rating: 74.5,
slope: 141
),

TeeInfo(
teeName: "Purple",
yardage: 6740,
rating: 72.2,
slope: 137
),

TeeInfo(
teeName: "Composite",
yardage: 6436,
rating: 71.0,
slope: 134
),

TeeInfo(
teeName: "White",
yardage: 6114,
rating: 69.2,
slope: 129
),

TeeInfo(
teeName: "Green",
yardage: 5289,
rating: 66.0,
slope: 117
)

]
// MARK: - PGA WEST (Nicklaus Tournament Course)

private let PGA_WEST_NICKLAUS_TOURNAMENT_ID = UUID(uuidString: "E6D8A9B1-3F44-4A78-8A2C-9C0D2B7E5101")!

let PGA_WEST_NICKLAUS_TOURNAMENT_PARS: [Int] = [
    4,4,3,5,4,4,5,3,4,
    4,5,3,4,4,5,4,3,4
]

let PGA_WEST_NICKLAUS_TOURNAMENT_HCS: [Int] = [
    5,11,15,13,1,7,17,9,3,
    14,18,10,8,16,2,6,12,4
]

let PGA_WEST_NICKLAUS_TOURNAMENT_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 7204,
        rating: 75.3,
        slope: 143
    )
]

// MARK: - Desert Willow Golf Resort (Firecliff Course)

private let DESERT_WILLOW_FIRECLIFF_ID = UUID(uuidString: "A4B2F910-6D1E-4E20-8B6D-2F4A9A4C6202")!

let DESERT_WILLOW_FIRECLIFF_PARS: [Int] = [
    5,4,3,4,4,4,5,3,4,
    4,4,4,5,3,4,4,3,5
]

let DESERT_WILLOW_FIRECLIFF_HCS: [Int] = [
    11,9,15,1,5,13,7,17,3,
    2,6,8,12,16,18,10,4,14
]

let DESERT_WILLOW_FIRECLIFF_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 7056,
        rating: 74.3,
        slope: 140
    )
]

// MARK: - Indian Wells Golf Resort (Celebrity Course)

private let INDIAN_WELLS_CELEBRITY_ID = UUID(uuidString: "B5C3D021-7E2F-4F31-9C7E-3B5D0B5D7303")!

let INDIAN_WELLS_CELEBRITY_PARS: [Int] = [
    4,4,4,5,4,3,4,4,4,
    4,4,4,4,5,4,3,4,4
]

let INDIAN_WELLS_CELEBRITY_HCS: [Int] = [
    15,7,11,13,1,9,5,17,3,
    6,16,18,12,8,2,14,4,10
]

let INDIAN_WELLS_CELEBRITY_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Cabernet",
        yardage: 6985,
        rating: 73.5,
        slope: 136
    )
]
// MARK: - Desert Willow Golf Resort (Mountain View Course)

private let DESERT_WILLOW_MOUNTAIN_VIEW_ID = UUID(uuidString: "7A5F3C21-8C44-4A0D-9C2B-1A3E5F7B9011")!

let DESERT_WILLOW_MOUNTAIN_VIEW_PARS: [Int] = [
    4,4,4,4,3,5,4,3,5,
    4,3,5,3,4,4,4,4,5
]

let DESERT_WILLOW_MOUNTAIN_VIEW_HCS: [Int] = [
    3,7,1,9,5,11,13,17,15,
    10,4,18,14,2,6,8,16,12
]

let DESERT_WILLOW_MOUNTAIN_VIEW_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 6913,
        rating: 73.0,
        slope: 132
    ),
    TeeInfo(
        teeName: "Purple",
        yardage: 6507,
        rating: 71.2,
        slope: 128
    ),
    TeeInfo(
        teeName: "Purple / White",
        yardage: 6316,
        rating: 70.3,
        slope: 126
    ),
    TeeInfo(
        teeName: "White",
        yardage: 6128,
        rating: 69.4,
        slope: 124
    ),
    TeeInfo(
        teeName: "White / Tan",
        yardage: 5866,
        rating: 68.1,
        slope: 121
    ),
    TeeInfo(
        teeName: "Tan",
        yardage: 5573,
        rating: 66.6,
        slope: 117
    ),
    TeeInfo(
        teeName: "Tan / Green",
        yardage: 5290,
        rating: 70.9,
        slope: 130
    ),
    TeeInfo(
        teeName: "Green",
        yardage: 5040,
        rating: 64.0,
        slope: 110
    )
]
// MARK: - Classic Club

private let CLASSIC_CLUB_ID = UUID(uuidString: "9C7B5E43-AE66-4C2F-B4D5-3C5A7B9D1233")!

let CLASSIC_CLUB_PARS: [Int] = [
    4,3,4,5,4,3,4,4,5,
    4,4,3,4,5,4,4,3,5
]

let CLASSIC_CLUB_HCS: [Int] = [
    15,17,7,5,9,13,3,11,1,
    4,6,16,12,8,14,10,18,2
]

let CLASSIC_CLUB_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 7322,
        rating: 75.8,
        slope: 144
    ),
    TeeInfo(
        teeName: "Blue",
        yardage: 6711,
        rating: 72.9,
        slope: 135
    ),
    TeeInfo(
        teeName: "White",
        yardage: 6229,
        rating: 71.0,
        slope: 129
    ),
    TeeInfo(
        teeName: "Gold",
        yardage: 5782,
        rating: 68.7,
        slope: 125
    ),
    TeeInfo(
        teeName: "White (Ladies)",
        yardage: 6229,
        rating: 77.0,
        slope: 142
    ),
    TeeInfo(
        teeName: "Gold (Ladies)",
        yardage: 5872,
        rating: 74.6,
        slope: 138
    ),
    TeeInfo(
        teeName: "Purple (Ladies)",
        yardage: 5279,
        rating: 71.9,
        slope: 132
    ),
    TeeInfo(
        teeName: "Orange (Ladies)",
        yardage: 4219,
        rating: 65.7,
        slope: 116
    )
]
// MARK: - Indian Wells Golf Resort (Players Course)

private let INDIAN_WELLS_PLAYERS_ID = UUID(uuidString: "8B6A4D32-9D55-4B1E-A3C4-2B4F6A8C0122")!

let INDIAN_WELLS_PLAYERS_PARS: [Int] = [
    5,4,4,3,4,4,3,5,3,
    4,4,3,5,4,4,4,3,5
]

let INDIAN_WELLS_PLAYERS_HCS: [Int] = [
    3,11,17,15,1,5,13,7,9,
    18,14,16,10,4,2,6,12,8
]

let INDIAN_WELLS_PLAYERS_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Cabernet",
        yardage: 7118,
        rating: 74.1,
        slope: 133
    ),
    TeeInfo(
        teeName: "Blue",
        yardage: 6601,
        rating: 71.7,
        slope: 127
    ),
    TeeInfo(
        teeName: "Yellow",
        yardage: 6121,
        rating: 69.5,
        slope: 122
    ),
    TeeInfo(
        teeName: "White",
        yardage: 5567,
        rating: 67.0,
        slope: 116
    ),
    TeeInfo(
        teeName: "Silver",
        yardage: 4944,
        rating: 64.2,
        slope: 109
    )
]
// MARK: - Tahquitz Creek Golf Resort (Resort Course)

private let TAHQUITZ_CREEK_RESORT_ID = UUID(uuidString: "AD8C6F54-BF77-4D30-C5E6-4D6B8CAE2344")!

let TAHQUITZ_CREEK_RESORT_PARS: [Int] = [
    4,4,3,5,4,5,4,3,4,
    4,4,4,3,5,4,4,3,5
]

let TAHQUITZ_CREEK_RESORT_HCS: [Int] = [
    17,13,15,9,3,11,1,5,7,
    2,12,18,16,6,8,4,14,10
]

let TAHQUITZ_CREEK_RESORT_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Green (Championship)",
        yardage: 6621,
        rating: 71.5,
        slope: 126
    )
]

// MARK: - SilverRock Resort

private let SILVERROCK_RESORT_ID = UUID(uuidString: "C6D4E132-8F30-4032-A08F-4C6E1C6E8404")!

let SILVERROCK_RESORT_PARS: [Int] = [
    4,5,3,4,4,4,5,3,4,
    4,3,5,3,5,4,3,5,4
]

let SILVERROCK_RESORT_HCS: [Int] = [
    7,9,17,13,11,1,3,15,5,
    14,12,4,18,8,6,10,2,16
]

let SILVERROCK_RESORT_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Silver",
        yardage: 7239,
        rating: 75.0,
        slope: 139
    )
]
// MARK: - Tahquitz Creek Golf Resort (Legend Course)

private let TAHQUITZ_LEGEND_ID = UUID(uuidString: "1F4D8A61-3E52-4A61-9D43-8D0B6F4C2101")!

let TAHQUITZ_LEGEND_PARS: [Int] = [
    4,4,5,4,4,5,3,4,3,
    4,4,3,5,4,3,4,4,4
]

let TAHQUITZ_LEGEND_HCS: [Int] = [
    5,9,13,3,17,7,11,1,15,
    10,18,14,16,6,12,8,4,2
]

let TAHQUITZ_LEGEND_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Green (Championship)",
        yardage: 6646,
        rating: 72.3,
        slope: 127
    )
]
// MARK: - Indian Canyons Golf Resort (South Course)

private let INDIAN_CANYONS_SOUTH_ID = UUID(uuidString: "2A5E9B72-4F63-4B72-AE54-9E1C7D5D3202")!

let INDIAN_CANYONS_SOUTH_PARS: [Int] = [
    4,3,5,3,4,4,3,4,5,
    5,4,3,4,5,3,4,4,5
]

let INDIAN_CANYONS_SOUTH_HCS: [Int] = [
    13,17,1,15,11,5,7,3,9,
    8,12,2,14,18,10,16,6,4
]

let INDIAN_CANYONS_SOUTH_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 6560,
        rating: 71.4,
        slope: 124
    ),
    TeeInfo(
        teeName: "Teal",
        yardage: 6281,
        rating: 69.7,
        slope: 120
    ),
    TeeInfo(
        teeName: "White",
        yardage: 5962,
        rating: 67.8,
        slope: 115
    ),
    TeeInfo(
        teeName: "Gold",
        yardage: 5499,
        rating: 65.7,
        slope: 110
    )
]
// MARK: - Indian Canyons Golf Resort (North Course)

private let INDIAN_CANYONS_NORTH_ID = UUID(uuidString: "3B6FAC83-5074-4C83-BF65-AF2D8E6E4303")!

let INDIAN_CANYONS_NORTH_PARS: [Int] = [
    4,4,4,3,4,5,3,4,4,
    5,4,4,5,3,4,3,4,5
]

let INDIAN_CANYONS_NORTH_HCS: [Int] = [
    9,5,3,17,1,11,15,7,13,
    12,4,2,6,14,16,18,10,8
]

let INDIAN_CANYONS_NORTH_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Blue",
        yardage: 6933,
        rating: 72.9,
        slope: 127
    ),
    TeeInfo(
        teeName: "White",
        yardage: 6532,
        rating: 71.1,
        slope: 123
    ),
    TeeInfo(
        teeName: "Gold",
        yardage: 6040,
        rating: 68.8,
        slope: 117
    )
]
// MARK: - Torrey Pines (South Course)

private let TORREY_PINES_SOUTH_ID = UUID(uuidString: "4C70BD94-6185-4D94-C076-B03E9F7F5404")!

let TORREY_PINES_SOUTH_PARS: [Int] = [
    4,4,3,4,4,5,4,3,5,
    4,4,4,5,4,3,4,4,5
]

let TORREY_PINES_SOUTH_HCS: [Int] = [
    5,15,13,3,11,9,1,17,7,
    16,14,2,6,8,12,18,4,10
]

let TORREY_PINES_SOUTH_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 7802,
        rating: 77.9,
        slope: 144
    ),
    TeeInfo(
        teeName: "Brown",
        yardage: 7015,
        rating: 75.0,
        slope: 139
    ),
    TeeInfo(
        teeName: "Green",
        yardage: 6635,
        rating: 72.4,
        slope: 132
    ),
    TeeInfo(
        teeName: "White",
        yardage: 6145,
        rating: 69.2,
        slope: 125
    ),
    TeeInfo(
        teeName: "Yellow",
        yardage: 5373,
        rating: 65.7,
        slope: 116
    )
]
// MARK: - Monarch Beach Golf Links

private let MONARCH_BEACH_ID = UUID(uuidString: "9CF5A2E9-B6DA-4CE9-852B-A58CE4C4A919")!

let MONARCH_BEACH_PARS: [Int] = [
    4,4,4,3,3,4,5,4,5,
    4,4,5,3,4,3,4,3,4
]

let MONARCH_BEACH_HCS: [Int] = [
    11,3,17,15,7,13,1,5,9,
    10,2,4,16,12,14,8,18,6
]
let MONARCH_BEACH_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 6645,
        rating: 71.9,
        slope: 130
    ),
    TeeInfo(
        teeName: "Orange",
        yardage: 6052,
        rating: 69.7,
        slope: 125
    ),
    TeeInfo(
        teeName: "Gold",
        yardage: 5612,
        rating: 67.4,
        slope: 120
    ),
    TeeInfo(
        teeName: "Platinum",
        yardage: 5050,
        rating: 64.6,
        slope: 113
    )
]
// MARK: - Torrey Pines (North Course)

private let TORREY_PINES_NORTH_ID = UUID(uuidString: "5D81CEA5-7296-4EA5-D187-C14FA0806505")!

let TORREY_PINES_NORTH_PARS: [Int] = [
    4,4,3,4,5,4,4,3,5,
    5,4,3,4,4,3,4,5,4
]

let TORREY_PINES_NORTH_HCS: [Int] = [
    5,1,13,3,11,7,17,15,9,
    12,18,14,4,6,16,8,10,2
]

let TORREY_PINES_NORTH_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 6781,
        rating: 73.0,
        slope: 137
    ),
    TeeInfo(
        teeName: "Green",
        yardage: 6346,
        rating: 70.8,
        slope: 132
    ),
    TeeInfo(
        teeName: "Gold",
        yardage: 5851,
        rating: 67.8,
        slope: 125
    ),
    TeeInfo(
        teeName: "Silver",
        yardage: 5197,
        rating: 64.4,
        slope: 117
    )
]
// MARK: - Half Moon Bay Golf Links (Old Course)

// MARK: - Half Moon Bay Golf Links (Old Course)

private let HALF_MOON_BAY_OLD_ID = UUID(uuidString: "7A93E0C7-94B8-4AC7-A309-E36AC2A28707")!

let HALF_MOON_BAY_OLD_PARS: [Int] = [
    5,4,3,4,5,4,3,4,4,
    5,4,4,3,4,5,4,3,4
]

let HALF_MOON_BAY_OLD_HCS: [Int] = [
    17,7,3,9,13,5,15,1,11,
    16,14,10,8,2,12,4,18,6
]

let HALF_MOON_BAY_OLD_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 6989,
        rating: 74.3,
        slope: 135
    )
]
// MARK: - Half Moon Bay Golf Links (Ocean Course)

// MARK: - Half Moon Bay Golf Links (Ocean Course)

private let HALF_MOON_BAY_OCEAN_ID = UUID(uuidString: "8BA4F1D8-A5C9-4BD8-B41A-F47BD3B39818")!

let HALF_MOON_BAY_OCEAN_PARS: [Int] = [
    4,3,4,5,4,4,3,5,3,
    5,4,3,4,5,4,4,3,5
]

let HALF_MOON_BAY_OCEAN_HCS: [Int] = [
    3,9,17,15,1,5,13,7,11,
    12,4,8,2,14,10,6,16,18
]

let HALF_MOON_BAY_OCEAN_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 6854,
        rating: 72.5,
        slope: 132
    ),
    TeeInfo(
        teeName: "Blue",
        yardage: 6470,
        rating: 70.8,
        slope: 127
    ),
    TeeInfo(
        teeName: "White",
        yardage: 6052,
        rating: 69.1,
        slope: 123
    ),
    TeeInfo(
        teeName: "Gold",
        yardage: 5461,
        rating: 66.1,
        slope: 117
    )
]
// =======================================================
// MARK: RTJ Trail — Alabama
// Cambrian Ridge (Greenville, AL)
// 27 holes: Canyon / Loblolly / Sherling
// =======================================================

// MARK: Cambrian Ridge — Canyon / Sherling
private let CAMBRIAN_RIDGE_CANYON_SHERLING_ID = UUID(uuidString: "7E8C11A1-4F1B-4C21-9E10-1A2B3C4D5E61")!

let CAMBRIAN_RIDGE_CANYON_SHERLING_PARS: [Int] = [
    // Canyon
    4,3,5,4,4,4,5,3,4,
    // Sherling
    5,3,4,3,4,4,4,5,4
]

// Provisional 18-hole SI conversion:
// Canyon ranks (1-9) -> odd SI values
// Sherling ranks (1-9) -> even SI values
let CAMBRIAN_RIDGE_CANYON_SHERLING_HCS: [Int] = [
    // Canyon M. HCP: 1,4,8,7,6,3,9,5,2
    1,7,15,13,11,5,17,9,3,
    // Sherling M. HCP: 8,9,5,7,1,3,6,4,2
    16,18,10,14,2,6,12,8,4
]

let CAMBRIAN_RIDGE_CANYON_SHERLING_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Purple", yardage: 7135, rating: nil, slope: nil),
    TeeInfo(teeName: "Orange", yardage: 6608, rating: nil, slope: nil),
    TeeInfo(teeName: "White",  yardage: 6076, rating: nil, slope: nil),
    TeeInfo(teeName: "Gold",   yardage: 5474, rating: nil, slope: nil),
    TeeInfo(teeName: "Teal",   yardage: 4732, rating: nil, slope: nil)
]

// MARK: Cambrian Ridge — Canyon / Loblolly
private let CAMBRIAN_RIDGE_CANYON_LOBLOLLY_ID = UUID(uuidString: "8F9D22B2-5A2C-4D32-AF21-2B3C4D5E6F72")!

let CAMBRIAN_RIDGE_CANYON_LOBLOLLY_PARS: [Int] = [
    // Canyon
    4,3,5,4,4,4,5,3,4,
    // Loblolly
    5,4,4,3,4,3,5,4,4
]

// Provisional 18-hole SI conversion:
// Canyon ranks (1-9) -> odd SI values
// Loblolly ranks (1-9) -> even SI values
let CAMBRIAN_RIDGE_CANYON_LOBLOLLY_HCS: [Int] = [
    // Canyon M. HCP: 1,4,8,7,6,3,9,5,2
    1,7,15,13,11,5,17,9,3,
    // Loblolly M. HCP: 8,1,4,9,7,6,2,3,5
    16,2,8,18,14,12,4,6,10
]

let CAMBRIAN_RIDGE_CANYON_LOBLOLLY_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Purple", yardage: 7088, rating: nil, slope: nil),
    TeeInfo(teeName: "Orange", yardage: 6619, rating: nil, slope: nil),
    TeeInfo(teeName: "White",  yardage: 6079, rating: nil, slope: nil),
    TeeInfo(teeName: "Gold",   yardage: 5464, rating: nil, slope: nil),
    TeeInfo(teeName: "Teal",   yardage: 4756, rating: nil, slope: nil)
]

// MARK: Cambrian Ridge — Sherling / Loblolly
private let CAMBRIAN_RIDGE_SHERLING_LOBLOLLY_ID = UUID(uuidString: "9A0E33C3-6B3D-4E43-B032-3C4D5E6F7083")!

let CAMBRIAN_RIDGE_SHERLING_LOBLOLLY_PARS: [Int] = [
    // Sherling
    5,3,4,3,4,4,4,5,4,
    // Loblolly
    5,4,4,3,4,3,5,4,4
]

private let RTJ_GRAND_NATIONAL_LAKE_ID = UUID(uuidString: "44444444-DDDD-4444-EEEE-000000000004")!

let RTJ_GRAND_NATIONAL_LAKE_PARS: [Int] = [
4,4,3,5,4,4,5,3,4,
4,4,5,4,5,3,4,3,4
]

let RTJ_GRAND_NATIONAL_LAKE_HCS: [Int] = [
11,1,15,9,5,13,3,17,7,
4,16,12,2,8,6,14,18,10
]

let RTJ_GRAND_NATIONAL_LAKE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Purple", yardage: 7314, rating: 76.2, slope: 139),
    TeeInfo(teeName: "Orange", yardage: 6648, rating: 73.2, slope: 133),
    TeeInfo(teeName: "White", yardage: 6018, rating: 70.2, slope: 131),
    TeeInfo(teeName: "Gold", yardage: 5432, rating: 67.3, slope: 123),
    TeeInfo(teeName: "Teal", yardage: 4873, rating: 64.3, slope: 117),
    TeeInfo(teeName: "Ladies Orange", yardage: 6648, rating: 78.9, slope: 142),
    TeeInfo(teeName: "Ladies White", yardage: 6018, rating: 75.3, slope: 135),
    TeeInfo(teeName: "Ladies Gold", yardage: 5432, rating: 71.8, slope: 126),
    TeeInfo(teeName: "Ladies Teal", yardage: 4873, rating: 68.9, slope: 121)
]
// Provisional 18-hole SI conversion:
// Sherling ranks (1-9) -> odd SI values
// Loblolly ranks (1-9) -> even SI values
let CAMBRIAN_RIDGE_SHERLING_LOBLOLLY_HCS: [Int] = [
    // Sherling M. HCP: 8,9,5,7,1,3,6,4,2
    15,17,9,13,1,5,11,7,3,
    // Loblolly M. HCP: 8,1,4,9,7,6,2,3,5
    16,2,8,18,14,12,4,6,10
]

let CAMBRIAN_RIDGE_SHERLING_LOBLOLLY_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Purple", yardage: 7095, rating: nil, slope: nil),
    TeeInfo(teeName: "Orange", yardage: 6565, rating: nil, slope: nil),
    TeeInfo(teeName: "White",  yardage: 6079, rating: nil, slope: nil),
    TeeInfo(teeName: "Gold",   yardage: 5528, rating: nil, slope: nil),
    TeeInfo(teeName: "Teal",   yardage: 4702, rating: nil, slope: nil)
]
private let RTJ_CAPITOL_HILL_JUDGE_ID = UUID(uuidString: "11111111-AAAA-4444-BBBB-000000000001")!

let RTJ_CAPITOL_HILL_JUDGE_PARS: [Int] = [
4,4,3,5,4,3,5,4,4,
5,4,3,4,4,5,3,4,4
]

let RTJ_CAPITOL_HILL_JUDGE_HCS: [Int] = [
11,5,17,3,7,15,1,9,13,
2,10,18,12,6,4,16,8,14
]

let RTJ_CAPITOL_HILL_JUDGE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7807, rating: 78.5, slope: 147),
    TeeInfo(teeName: "Purple", yardage: 7151, rating: 75.1, slope: 142),
    TeeInfo(teeName: "Orange", yardage: 6577, rating: 71.7, slope: 131),
    TeeInfo(teeName: "White", yardage: 6120, rating: 69.6, slope: 130),
    TeeInfo(teeName: "Gold", yardage: 5215, rating: 65.9, slope: 116),
    TeeInfo(teeName: "Teal", yardage: 4854, rating: 64.7, slope: 115),
    TeeInfo(teeName: "Ladies White", yardage: 6120, rating: 75.6, slope: 139),
    TeeInfo(teeName: "Ladies Gold", yardage: 5215, rating: 69.9, slope: 126),
    TeeInfo(teeName: "Ladies Teal", yardage: 4854, rating: 68.4, slope: 123)
]
private let RTJ_CAPITOL_HILL_LEGISLATOR_ID = UUID(uuidString: "22222222-BBBB-4444-CCCC-000000000002")!

let RTJ_CAPITOL_HILL_LEGISLATOR_PARS: [Int] = [
5,4,3,4,5,3,4,4,4,
4,3,4,5,4,4,3,5,4
]

let RTJ_CAPITOL_HILL_LEGISLATOR_HCS: [Int] = [
3,13,17,7,1,15,11,5,9,
10,16,12,4,6,14,18,2,8
]

let RTJ_CAPITOL_HILL_LEGISLATOR_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7454, rating: 76.0, slope: 143),
    TeeInfo(teeName: "Purple", yardage: 6997, rating: 73.9, slope: 139),
    TeeInfo(teeName: "Orange", yardage: 6468, rating: 71.6, slope: 133),
    TeeInfo(teeName: "White", yardage: 5964, rating: 69.1, slope: 128),
    TeeInfo(teeName: "Gold", yardage: 5410, rating: 66.4, slope: 116),
    TeeInfo(teeName: "Teal", yardage: 4453, rating: 62.2, slope: 108),
    TeeInfo(teeName: "Ladies White", yardage: 5964, rating: 74.9, slope: 137),
    TeeInfo(teeName: "Ladies Gold", yardage: 5410, rating: 71.8, slope: 130),
    TeeInfo(teeName: "Ladies Teal", yardage: 4453, rating: 66.6, slope: 117)
]
private let RTJ_CAPITOL_HILL_SENATOR_ID = UUID(uuidString: "33333333-CCCC-4444-DDDD-000000000003")!

let RTJ_CAPITOL_HILL_SENATOR_PARS: [Int] = [
4,3,4,4,5,4,3,5,4,
5,4,4,3,4,4,3,5,4
]

let RTJ_CAPITOL_HILL_SENATOR_HCS: [Int] = [
11,17,13,5,1,7,15,3,9,
4,14,6,18,12,8,16,2,10
]

let RTJ_CAPITOL_HILL_SENATOR_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7643, rating: 77.4, slope: 132),
    TeeInfo(teeName: "Purple", yardage: 7022, rating: 74.1, slope: 125),
    TeeInfo(teeName: "Orange", yardage: 6442, rating: 70.9, slope: 126),
    TeeInfo(teeName: "White", yardage: 5862, rating: 68.1, slope: 121),
    TeeInfo(teeName: "Gold", yardage: 5347, rating: 65.4, slope: 111),
    TeeInfo(teeName: "Teal", yardage: 5028, rating: 64.7, slope: 110),
    TeeInfo(teeName: "Ladies White", yardage: 5862, rating: 73.6, slope: 123),
    TeeInfo(teeName: "Ladies Gold", yardage: 5347, rating: 70.7, slope: 120),
    TeeInfo(teeName: "Ladies Teal", yardage: 5028, rating: 69.6, slope: 116)
]
private let RTJ_GRAND_NATIONAL_LINKS_ID = UUID(uuidString: "55555555-EEEE-4444-FFFF-000000000005")!

let RTJ_GRAND_NATIONAL_LINKS_PARS: [Int] = [
4,5,3,4,4,5,4,4,3,
4,3,5,4,4,5,3,4,4
]

let RTJ_GRAND_NATIONAL_LINKS_HCS: [Int] = [
7,5,15,9,11,3,1,13,17,
16,8,4,12,6,10,18,14,2
]

let RTJ_GRAND_NATIONAL_LINKS_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Purple", yardage: 7404, rating: 76.2, slope: 141),
    TeeInfo(teeName: "Orange", yardage: 6738, rating: 73.2, slope: 135),
    TeeInfo(teeName: "White", yardage: 6125, rating: 70.5, slope: 128),
    TeeInfo(teeName: "Gold", yardage: 5308, rating: 66.5, slope: 120),
    TeeInfo(teeName: "Teal", yardage: 4544, rating: 62.9, slope: 113),
    TeeInfo(teeName: "Ladies Orange", yardage: 6738, rating: 79.3, slope: 143),
    TeeInfo(teeName: "Ladies White", yardage: 6125, rating: 76.0, slope: 136),
    TeeInfo(teeName: "Ladies Gold", yardage: 5308, rating: 71.4, slope: 126),
    TeeInfo(teeName: "Ladies Teal", yardage: 4544, rating: 67.1, slope: 118)
]
private let RTJ_GRAND_NATIONAL_SHORT_ID = UUID(uuidString: "66666666-FFFF-4444-AAAA-000000000006")!

let RTJ_GRAND_NATIONAL_SHORT_PARS: [Int] = [
    3,3,3,3,3,3,3,3,3,
    3,3,3,3,3,3,3,3,3
]

let RTJ_GRAND_NATIONAL_SHORT_HCS: [Int] = [
    9,5,13,11,7,15,17,3,1,
    14,8,6,10,18,2,4,16,12
]

let RTJ_GRAND_NATIONAL_SHORT_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Purple", yardage: 3126, rating: 56.8, slope: 95),
    TeeInfo(teeName: "Orange", yardage: 2714, rating: 55.4, slope: 93),
    TeeInfo(teeName: "White", yardage: 2218, rating: 53.7, slope: 89),
    TeeInfo(teeName: "Teal", yardage: 1586, rating: 51.5, slope: 85),
    TeeInfo(teeName: "Ladies Purple", yardage: 3126, rating: 59.0, slope: 88),
    TeeInfo(teeName: "Ladies Orange", yardage: 2714, rating: 57.7, slope: 86),
    TeeInfo(teeName: "Ladies White", yardage: 2218, rating: 56.2, slope: 82),
    TeeInfo(teeName: "Ladies Teal", yardage: 1586, rating: 54.2, slope: 79)
]
// =======================================================
// MARK: RTJ Trail — Alabama
// Hampton Cove (Owens Crossroads, AL)
// =======================================================

// MARK: Hampton Cove (Highlands)
private let RTJ_HAMPTON_COVE_HIGHLANDS_ID = UUID(uuidString: "77777777-1111-4444-AAAA-000000000007")!

let RTJ_HAMPTON_COVE_HIGHLANDS_PARS: [Int] = [
    4,4,5,3,4,4,4,3,5,
    4,3,4,4,4,5,3,5,4
]

let RTJ_HAMPTON_COVE_HIGHLANDS_HCS: [Int] = [
    5,15,17,9,7,1,3,13,11,
    4,14,16,12,2,18,10,6,8
]

let RTJ_HAMPTON_COVE_HIGHLANDS_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Purple", yardage: 7428, rating: 76.2, slope: 143),
    TeeInfo(teeName: "Orange", yardage: 6806, rating: 73.4, slope: 138),
    TeeInfo(teeName: "White", yardage: 6070, rating: 70.9, slope: 130),
    TeeInfo(teeName: "Gold", yardage: 5535, rating: 67.8, slope: 126),
    TeeInfo(teeName: "Teal", yardage: 4982, rating: 65.0, slope: 120),
    TeeInfo(teeName: "Ladies White", yardage: 6070, rating: 76.9, slope: 136),
    TeeInfo(teeName: "Ladies Gold", yardage: 5535, rating: 73.7, slope: 129),
    TeeInfo(teeName: "Ladies Teal", yardage: 4982, rating: 70.2, slope: 120)
]
// MARK: Hampton Cove (River)
private let RTJ_HAMPTON_COVE_RIVER_ID = UUID(uuidString: "88888888-2222-4444-BBBB-000000000008")!

let RTJ_HAMPTON_COVE_RIVER_PARS: [Int] = [
    5,3,4,4,4,3,4,5,4,
    5,4,4,4,3,5,3,4,4
]

let RTJ_HAMPTON_COVE_RIVER_HCS: [Int] = [
    3,17,9,13,1,15,7,5,11,
    18,8,2,16,6,12,14,4,10
]

let RTJ_HAMPTON_COVE_RIVER_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Purple", yardage: 7668, rating: 77.5, slope: 140),
    TeeInfo(teeName: "Orange", yardage: 6764, rating: 73.1, slope: 136),
    TeeInfo(teeName: "White", yardage: 6111, rating: 70.2, slope: 130),
    TeeInfo(teeName: "Gold", yardage: 5602, rating: 67.9, slope: 119),
    TeeInfo(teeName: "Teal", yardage: 5200, rating: 66.2, slope: 110),
    TeeInfo(teeName: "Ladies White", yardage: 6111, rating: 76.1, slope: 140),
    TeeInfo(teeName: "Ladies Gold", yardage: 5602, rating: 73.4, slope: 129),
    TeeInfo(teeName: "Ladies Teal", yardage: 5200, rating: 70.8, slope: 126)
]
// MARK: Hampton Cove (Short Course)
private let RTJ_HAMPTON_COVE_SHORT_ID = UUID(uuidString: "99999999-3333-4444-CCCC-000000000009")!

let RTJ_HAMPTON_COVE_SHORT_PARS: [Int] = [
    3,3,3,3,3,3,3,3,3,
    3,3,3,3,3,3,3,3,3
]

let RTJ_HAMPTON_COVE_SHORT_HCS: [Int] = [
    11,13,3,17,15,5,9,1,7,
    10,16,14,6,8,4,18,2,12
]

let RTJ_HAMPTON_COVE_SHORT_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Purple", yardage: 3635, rating: nil, slope: nil),
    TeeInfo(teeName: "Orange", yardage: 3007, rating: nil, slope: nil),
    TeeInfo(teeName: "White", yardage: 2480, rating: nil, slope: nil),
    TeeInfo(teeName: "Teal", yardage: 1861, rating: nil, slope: nil)
]
private let RTJ_HIGHLAND_OAKS_HIGHLANDS_MAGNOLIA_ID = UUID(uuidString: "A1000001-0000-4444-AAAA-000000000001")!

let RTJ_HIGHLAND_OAKS_HIGHLANDS_MAGNOLIA_PARS: [Int] = [
    4,4,4,3,4,3,5,4,5,
    4,3,5,5,4,4,3,4,4
]

let RTJ_HIGHLAND_OAKS_HIGHLANDS_MAGNOLIA_HCS: [Int] = [
    // Highlands (odd)
    5,15,1,9,3,17,13,11,7,
    // Magnolia (even)
    14,16,8,10,12,2,18,6,4
]

let RTJ_HIGHLAND_OAKS_HIGHLANDS_MAGNOLIA_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7593, rating: 75.0, slope: 144),
    TeeInfo(teeName: "Purple", yardage: 6995, rating: 73.0, slope: 138),
    TeeInfo(teeName: "Orange", yardage: 6426, rating: 71.0, slope: 133),
    TeeInfo(teeName: "White", yardage: 5828, rating: 68.5, slope: 122),
    TeeInfo(teeName: "Teal", yardage: 5025, rating: 65.0, slope: 115),
    TeeInfo(teeName: "Ladies White", yardage: 5828, rating: 72.5, slope: 128),
    TeeInfo(teeName: "Ladies Teal", yardage: 5025, rating: 69.2, slope: 119)
]
private let RTJ_HIGHLAND_OAKS_HIGHLANDS_MARSHWOOD_ID = UUID(uuidString: "A1000002-0000-4444-BBBB-000000000002")!

let RTJ_HIGHLAND_OAKS_HIGHLANDS_MARSHWOOD_PARS: [Int] = [
    4,4,4,3,4,3,5,4,5,
    4,5,4,3,4,5,4,3,4
]

let RTJ_HIGHLAND_OAKS_HIGHLANDS_MARSHWOOD_HCS: [Int] = [
    // Highlands (odd)
    5,15,1,9,3,17,13,11,7,
    // Marshwood (even)
    10,12,14,16,4,2,8,18,6
]

let RTJ_HIGHLAND_OAKS_HIGHLANDS_MARSHWOOD_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7704, rating: 75.5, slope: 146),
    TeeInfo(teeName: "Purple", yardage: 7082, rating: 73.5, slope: 140),
    TeeInfo(teeName: "Orange", yardage: 6489, rating: 71.2, slope: 134),
    TeeInfo(teeName: "White", yardage: 5815, rating: 68.7, slope: 124),
    TeeInfo(teeName: "Teal", yardage: 5085, rating: 65.3, slope: 117),
    TeeInfo(teeName: "Ladies White", yardage: 5815, rating: 72.8, slope: 129),
    TeeInfo(teeName: "Ladies Teal", yardage: 5085, rating: 69.0, slope: 118)
]
private let RTJ_HIGHLAND_OAKS_MAGNOLIA_MARSHWOOD_ID = UUID(uuidString: "A1000003-0000-4444-CCCC-000000000003")!

let RTJ_HIGHLAND_OAKS_MAGNOLIA_MARSHWOOD_PARS: [Int] = [
    4,3,5,5,4,4,3,4,4,
    4,5,4,3,4,5,4,3,4
]

let RTJ_HIGHLAND_OAKS_MAGNOLIA_MARSHWOOD_HCS: [Int] = [
    // Magnolia (odd)
    13,15,7,9,11,1,17,5,3,
    // Marshwood (even)
    10,12,14,16,4,2,8,18,6
]

let RTJ_HIGHLAND_OAKS_MAGNOLIA_MARSHWOOD_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7513, rating: 74.5, slope: 143),
    TeeInfo(teeName: "Purple", yardage: 6917, rating: 72.6, slope: 137),
    TeeInfo(teeName: "Orange", yardage: 6345, rating: 70.8, slope: 132),
    TeeInfo(teeName: "White", yardage: 5711, rating: 68.3, slope: 120),
    TeeInfo(teeName: "Teal", yardage: 5002, rating: 64.8, slope: 113),
    TeeInfo(teeName: "Ladies White", yardage: 5711, rating: 72.0, slope: 125),
    TeeInfo(teeName: "Ladies Teal", yardage: 5002, rating: 68.5, slope: 117)
]
private let RTJ_LAKEWOOD_AZALEA_ID = UUID(uuidString: "B2000001-0000-4444-AAAA-000000000001")!

let RTJ_LAKEWOOD_AZALEA_PARS: [Int] = [
    5,4,4,3,4,5,3,4,4,
    4,5,4,3,5,3,4,4,4
]

let RTJ_LAKEWOOD_AZALEA_HCS: [Int] = [
    5,3,7,9,13,17,15,1,11,
    4,14,2,18,12,16,10,8,6
]

let RTJ_LAKEWOOD_AZALEA_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Purple", yardage: 7202, rating: 74.4, slope: 131),
    TeeInfo(teeName: "Orange", yardage: 6573, rating: 71.8, slope: 127),
    TeeInfo(teeName: "White", yardage: 6066, rating: 69.4, slope: 123),
    TeeInfo(teeName: "Teal", yardage: 5272, rating: 65.7, slope: 110),
    TeeInfo(teeName: "Red", yardage: 4539, rating: 65.5, slope: 109),
    TeeInfo(teeName: "Ladies Teal", yardage: 5272, rating: 70.3, slope: 118)
]
private let RTJ_LAKEWOOD_DOGWOOD_ID = UUID(uuidString: "B2000002-0000-4444-BBBB-000000000002")!

let RTJ_LAKEWOOD_DOGWOOD_PARS: [Int] = [
    5,4,3,4,5,4,4,3,4,
    4,4,5,3,4,4,5,3,4
]

let RTJ_LAKEWOOD_DOGWOOD_HCS: [Int] = [
    13,3,9,1,15,5,17,7,11,
    14,2,12,16,4,8,18,6,10
]

let RTJ_LAKEWOOD_DOGWOOD_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Purple", yardage: 7104, rating: 73.7, slope: 136),
    TeeInfo(teeName: "Orange", yardage: 6511, rating: 71.2, slope: 130),
    TeeInfo(teeName: "White", yardage: 5949, rating: 68.5, slope: 126),
    TeeInfo(teeName: "Teal", yardage: 5179, rating: 64.5, slope: 112),
    TeeInfo(teeName: "Red", yardage: 4436, rating: 61.6, slope: 105),
    TeeInfo(teeName: "Ladies Orange", yardage: 6511, rating: 77.8, slope: 132),
    TeeInfo(teeName: "Ladies White", yardage: 5949, rating: 74.8, slope: 125),
    TeeInfo(teeName: "Ladies Teal", yardage: 5179, rating: 70.2, slope: 115),
    TeeInfo(teeName: "Ladies Red", yardage: 4436, rating: 66.2, slope: 107)
]
private let RTJ_MAGNOLIA_GROVE_CROSSINGS_ID = UUID(uuidString: "C3000001-0000-4444-AAAA-000000000001")!

let RTJ_MAGNOLIA_GROVE_CROSSINGS_PARS: [Int] = [
4,3,4,5,4,5,4,3,4,
4,4,4,5,3,4,5,3,4
]

let RTJ_MAGNOLIA_GROVE_CROSSINGS_HCS: [Int] = [
14,18,10,6,2,12,16,8,4,
7,11,17,5,15,3,9,13,1
]

let RTJ_MAGNOLIA_GROVE_CROSSINGS_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Purple", yardage: 7212, rating: 73.7, slope: 139),
    TeeInfo(teeName: "Orange", yardage: 6652, rating: 71.2, slope: 135),
    TeeInfo(teeName: "White", yardage: 6157, rating: 69.6, slope: 130),
    TeeInfo(teeName: "Gold", yardage: 5660, rating: 67.1, slope: 122),
    TeeInfo(teeName: "Teal", yardage: 5261, rating: nil, slope: nil),
    TeeInfo(teeName: "Ladies White", yardage: 6157, rating: 74.9, slope: 136),
    TeeInfo(teeName: "Ladies Gold", yardage: 5660, rating: 72.1, slope: 130),
    TeeInfo(teeName: "Ladies Teal", yardage: 5261, rating: 68.1, slope: 121)
]
private let RTJ_MAGNOLIA_GROVE_FALLS_ID = UUID(uuidString: "C3000002-0000-4444-BBBB-000000000002")!

let RTJ_MAGNOLIA_GROVE_FALLS_PARS: [Int] = [
4,3,4,4,5,3,4,4,4,
5,3,4,3,4,4,4,4,5
]

let RTJ_MAGNOLIA_GROVE_FALLS_HCS: [Int] = [
6,16,4,14,10,18,12,2,8,
3,15,11,17,7,1,9,13,5
]

let RTJ_MAGNOLIA_GROVE_FALLS_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Purple", yardage: 7158, rating: 74.6, slope: 130),
    TeeInfo(teeName: "Orange", yardage: 6674, rating: 71.6, slope: 125),
    TeeInfo(teeName: "White", yardage: 6119, rating: 69.2, slope: 125),
    TeeInfo(teeName: "Gold", yardage: 5478, rating: 66.1, slope: 119),
    TeeInfo(teeName: "Teal", yardage: 5049, rating: 64.9, slope: 110),
    TeeInfo(teeName: "Ladies White", yardage: 6119, rating: 74.8, slope: 129),
    TeeInfo(teeName: "Ladies Gold", yardage: 5478, rating: 71.2, slope: 121),
    TeeInfo(teeName: "Ladies Teal", yardage: 5049, rating: 70.2, slope: 120)
]
// Ridge
private let RTJ_OXMOOR_RIDGE_ID = UUID(uuidString: "D4000001-0000-4444-AAAA-000000000001")!

let RTJ_OXMOOR_RIDGE_PARS: [Int] = [
4,5,5,4,3,4,4,3,4,
4,4,5,3,4,4,3,4,5
]

let RTJ_OXMOOR_RIDGE_HCS: [Int] = [
8,4,2,12,16,6,14,18,10,
9,7,3,17,13,11,15,5,1
]
// Valley
private let RTJ_OXMOOR_VALLEY_ID = UUID(uuidString: "D4000002-0000-4444-BBBB-000000000002")!

let RTJ_OXMOOR_VALLEY_PARS: [Int] = [
4,3,4,3,4,4,5,4,5,
4,4,5,3,5,4,3,4,4
]

let RTJ_OXMOOR_VALLEY_HCS: [Int] = [
5,15,9,17,7,13,3,11,1,
6,14,4,18,2,10,16,12,8
]
private let RTJ_ROSS_BRIDGE_ID = UUID(uuidString: "E5000001-0000-4444-AAAA-000000000001")!

let RTJ_ROSS_BRIDGE_PARS: [Int] = [
5,4,4,3,4,3,5,4,4,
4,3,4,5,3,4,5,4,4
]

let RTJ_ROSS_BRIDGE_HCS: [Int] = [
3,13,1,15,7,11,5,17,9,
2,16,18,6,14,12,8,10,4
]
private let RTJ_SILVER_LAKES_BACK_HEART_ID = UUID(uuidString: "F6000001-0000-4444-AAAA-000000000001")!

let RTJ_SILVER_LAKES_BACK_HEART_PARS: [Int] = [
4,3,4,4,3,4,5,4,5,
5,4,4,4,3,4,5,3,4
]

let RTJ_SILVER_LAKES_BACK_HEART_HCS: [Int] = [
    // Backbreaker odd
    7,15,3,5,13,11,9,1,17,
    // Heartbreaker even
    16,8,6,12,14,10,4,18,2
]
private let RTJ_SHOALS_FIGHTING_JOE_ID = UUID(uuidString: "G7000001-0000-4444-AAAA-000000000001")!

let RTJ_SHOALS_FIGHTING_JOE_PARS: [Int] = [
5,4,4,4,3,4,5,4,3,
4,4,5,3,4,4,4,5,3
]

let RTJ_SHOALS_FIGHTING_JOE_HCS: [Int] = [
3,9,7,13,15,5,1,11,17,
6,14,2,16,10,12,8,4,18
]
private let RTJ_SHOALS_SCHOOLMASTER_ID = UUID(uuidString: "G7000002-0000-4444-BBBB-000000000002")!

let RTJ_SHOALS_SCHOOLMASTER_PARS: [Int] = [
4,3,4,5,4,3,4,4,5,
3,5,5,4,4,4,3,4,4
]

let RTJ_SHOALS_SCHOOLMASTER_HCS: [Int] = [
13,17,7,3,9,15,11,5,1,
16,4,2,6,12,8,18,10,14

]
// MARK: Steelwood Country Club (Gold)
private let STEELWOOD_CC_GOLD_ID = UUID(uuidString: "C8D7F4A1-2E33-4A8A-9D11-7B5C2F6A9012")!

let STEELWOOD_CC_GOLD_PARS: [Int] = [
    4,3,4,5,4,3,4,4,5,
    5,4,3,4,4,4,4,3,5
]

let STEELWOOD_CC_GOLD_HCS: [Int] = [
    5,11,13,3,15,9,1,7,17,
    16,2,18,8,10,4,12,6,14
]

let STEELWOOD_CC_GOLD_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Gold", yardage: 7032, rating: 75.2, slope: 137)
]
// MARK: - Omni PGA Frisco (Fields Ranch East)

private let PGA_FRISCO_EAST_ID = UUID(uuidString: "A1F0E3C2-1234-4F8B-9A11-ABCDEF123456")!

let PGA_FRISCO_EAST_PARS: [Int] = [
5,4,5,3,4,4,4,3,4,
4,4,4,3,5,4,4,3,5
]

let PGA_FRISCO_EAST_HCS: [Int] = [
9,5,17,11,7,1,13,15,3,
8,12,4,10,2,14,6,18,16
]

let PGA_FRISCO_EAST_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Championship",
        yardage: 7860,
        rating: 78.9,
        slope: 152
    ),
    TeeInfo(
        teeName: "Tournament",
        yardage: 7467,
        rating: 76.5,
        slope: 148
    )
]
// MARK: - Omni Barton Creek (Fazio Canyons)
// MARK: - Omni Barton Creek (Fazio Canyons)

private let BARTON_CREEK_CANYONS_ID = UUID(uuidString: "B2F1A9D4-2234-4A8B-8C11-ABCDEF223456")!

let BARTON_CREEK_CANYONS_PARS: [Int] = [
4,4,3,4,5,4,5,3,4,
4,3,4,4,5,4,4,3,5
]

let BARTON_CREEK_CANYONS_HCS: [Int] = [
13,9,17,15,5,3,7,11,1,
2,18,16,14,10,4,6,8,12
]

let BARTON_CREEK_CANYONS_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7153, rating: 75.0, slope: 140),
    TeeInfo(teeName: "Gold",  yardage: 6745, rating: 72.8, slope: 138),
    TeeInfo(teeName: "Blue",  yardage: 6405, rating: 71.0, slope: 134),
    TeeInfo(teeName: "White", yardage: 6002, rating: 69.2, slope: 130),
    TeeInfo(teeName: "Red",   yardage: 5098, rating: 66.5, slope: 120)
]

// MARK: - Omni Barton Creek (Crenshaw Cliffside)

private let BARTON_CREEK_CRENSHAW_ID = UUID(uuidString: "C3F2B9D4-3234-4A8B-8C11-ABCDEF323456")!

let BARTON_CREEK_CRENSHAW_PARS: [Int] = [
4,5,4,4,3,4,4,3,4,
4,3,5,3,4,5,5,3,4
]

let BARTON_CREEK_CRENSHAW_HCS: [Int] = [
17,13,7,1,9,5,11,15,3,
4,8,10,12,16,6,14,18,2
]

let BARTON_CREEK_CRENSHAW_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Gold",      yardage: 6630, rating: 72.2, slope: 130),
    TeeInfo(teeName: "Crenshaw",  yardage: 6347, rating: 70.8, slope: 129),
    TeeInfo(teeName: "Blue",      yardage: 6152, rating: 70.0, slope: 127),
    TeeInfo(teeName: "White (M)", yardage: 5660, rating: 67.7, slope: 124),
    TeeInfo(teeName: "White (W)", yardage: 5660, rating: 73.3, slope: 129),
    TeeInfo(teeName: "Red",       yardage: 4778, rating: 67.5, slope: 112)
]
// MARK: - Omni Barton Creek (Palmer Lakeside)

private let BARTON_CREEK_PALMER_ID = UUID(uuidString: "D4F3C9D4-4234-4A8B-8C11-ABCDEF423456")!

let BARTON_CREEK_PALMER_PARS: [Int] = [
4,5,3,4,4,5,4,3,4,
4,3,5,4,3,5,4,3,4
]

let BARTON_CREEK_PALMER_HCS: [Int] = [
15,7,17,11,3,5,1,13,9,
6,16,12,2,14,10,4,18,8
]

let BARTON_CREEK_PALMER_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6407, rating: 72.3, slope: 136),
    TeeInfo(teeName: "Gold",  yardage: 6221, rating: 71.5, slope: 134),
    TeeInfo(teeName: "Blue",  yardage: 5861, rating: 69.6, slope: 130),
    TeeInfo(teeName: "Green", yardage: 5596, rating: 68.5, slope: 127),
    TeeInfo(teeName: "White", yardage: 5389, rating: 67.6, slope: 124),
    TeeInfo(teeName: "Red",   yardage: 4726, rating: 68.3, slope: 123)
]
// MARK: - Omni Homestead (Cascades)

private let HOMESTEAD_CASCADES_ID = UUID(uuidString: "E5F4D9D4-5234-4A8B-8C11-ABCDEF523456")!

let HOMESTEAD_CASCADES_PARS: [Int] = [
4,4,4,3,5,4,4,3,4,
4,3,5,4,4,3,5,5,3
]

let HOMESTEAD_CASCADES_HCS: [Int] = [
9,3,13,15,1,11,7,17,5,
12,16,4,10,8,14,2,6,18
]

let HOMESTEAD_CASCADES_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue",  yardage: 6729, rating: 73.0, slope: 137),
    TeeInfo(teeName: "White", yardage: 6294, rating: 70.9, slope: 132),
    TeeInfo(teeName: "Gold",  yardage: 5536, rating: 67.5, slope: 122),
    TeeInfo(teeName: "Red",   yardage: 4917, rating: 64.9, slope: 114)
]
// MARK: - Omni Bedford Springs (Old Course)


private let BEDFORD_SPRINGS_OLD_ID = UUID(uuidString: "F6A5E9D4-6234-4A8B-8C11-ABCDEF623456")!

let BEDFORD_SPRINGS_OLD_PARS: [Int] = [
    4,3,5,3,5,4,4,4,5,
    3,4,4,5,3,4,5,3,4
]

let BEDFORD_SPRINGS_OLD_HCS: [Int] = [
    17,11,7,1,5,9,3,13,15,
    18,2,10,4,16,14,8,6,12
]

let BEDFORD_SPRINGS_OLD_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Medal",       yardage: 6785, rating: nil, slope: nil),
    TeeInfo(teeName: "Ross",        yardage: 6446, rating: nil, slope: nil),
    TeeInfo(teeName: "Tillinghast", yardage: 6023, rating: nil, slope: nil),
    TeeInfo(teeName: "Oldham",      yardage: 5106, rating: nil, slope: nil)
]
// MARK: - Omni Homestead (Old Course)


private let HOMESTEAD_OLD_ID = UUID(uuidString: "A7B6E9D4-7234-4A8B-8C11-ABCDEF723456")!

let HOMESTEAD_OLD_PARS: [Int] = [
5,3,5,5,3,4,4,4,3,
4,3,5,5,4,5,3,4,3
]

let HOMESTEAD_OLD_HCS: [Int] = [
3,11,17,13,9,1,7,15,5,
4,8,12,16,2,14,10,18,6
]

let HOMESTEAD_OLD_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue",  yardage: 6036, rating: 69.4, slope: 132),
    TeeInfo(teeName: "White", yardage: 5677, rating: 67.8, slope: 125),
    TeeInfo(teeName: "Gold",  yardage: 5096, rating: 65.3, slope: 113),
    TeeInfo(teeName: "Red",   yardage: 4678, rating: 63.5, slope: 109)
]
// MARK: - Ozarks National (Big Cedar)
private let OZARKS_NATIONAL_ID = UUID(uuidString: "A91B2C3D-4E5F-6789-ABCD-1234567890AB")!

let OZARKS_NATIONAL_PARS: [Int] = [
    5,3,4,4,4,3,5,3,5,
    4,5,3,4,4,4,4,3,4
]

let OZARKS_NATIONAL_HCS: [Int] = [
    8,18,14,2,10,12,6,16,4,
    13,9,11,3,5,15,1,17,7
]

let OZARKS_NATIONAL_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Ozarks", yardage: 7036, rating: 73.9, slope: 131),
    TeeInfo(teeName: "Blue",   yardage: 6510, rating: 71.3, slope: 126),
    TeeInfo(teeName: "Combo",  yardage: 6264, rating: 70.0, slope: 122),
    TeeInfo(teeName: "White",  yardage: 5903, rating: 68.6, slope: 118),
    TeeInfo(teeName: "Red",    yardage: 5025, rating: 64.6, slope: 112)
]
// MARK: - Bear Dance Golf Club
private let BEAR_DANCE_ID = UUID(uuidString: "D4A12B34-5678-4ABC-9DEF-1234567890AB")!

let BEAR_DANCE_PARS: [Int] = [
    4,3,4,4,5,4,3,5,4,
    4,4,3,5,4,4,4,3,5
]

let BEAR_DANCE_HCS: [Int] = [
    3,17,13,11,7,15,9,5,1,
    14,6,16,8,12,4,10,18,2
]

let BEAR_DANCE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Professional", yardage: 7726, rating: 74.8, slope: 141),
    TeeInfo(teeName: "Black",        yardage: 7344, rating: 73.8, slope: 138),
    TeeInfo(teeName: "Blue",         yardage: 6879, rating: 72.2, slope: 136),
    TeeInfo(teeName: "White",        yardage: 6293, rating: 68.6, slope: 124),
    TeeInfo(teeName: "Gold",         yardage: 5240, rating: 64.1, slope: 111)
]
// MARK: - The Ridge at Castle Pines
private let RIDGE_CASTLE_PINES_ID = UUID(uuidString: "E5B23C45-6789-4DEF-9ABC-1234567890AB")!

let RIDGE_CASTLE_PINES_PARS: [Int] = [
    4,5,4,3,5,4,3,4,4,
    4,5,3,5,3,4,4,3,4
]

let RIDGE_CASTLE_PINES_HCS: [Int] = [
    3,9,1,17,7,15,13,11,5,
    2,6,16,4,18,14,10,12,8
]

let RIDGE_CASTLE_PINES_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7013, rating: 72.8, slope: 137),
    TeeInfo(teeName: "Gold",  yardage: 6490, rating: 70.1, slope: 133),
    TeeInfo(teeName: "Silver",yardage: 6002, rating: 67.9, slope: 122),
    TeeInfo(teeName: "Jade",  yardage: 5011, rating: 68.5, slope: 124)
]
// MARK: - Fossil Trace Golf Club
private let FOSSIL_TRACE_ID = UUID(uuidString: "F6C34D56-789A-4BCD-9EFA-1234567890AB")!

let FOSSIL_TRACE_PARS: [Int] = [
    5,4,3,4,3,4,4,4,5,
    4,3,5,4,3,5,3,4,5
]

let FOSSIL_TRACE_HCS: [Int] = [
    3,13,15,5,17,9,11,7,1,
    10,16,4,8,14,2,18,12,6
]

let FOSSIL_TRACE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6798, rating: 72.0, slope: 141),
    TeeInfo(teeName: "Blue",  yardage: 6241, rating: 70.9, slope: 136),
    TeeInfo(teeName: "White", yardage: 5559, rating: 66.2, slope: 114),
    TeeInfo(teeName: "Gold",  yardage: 4681, rating: 67.0, slope: 115)
]
// MARK: - Arrowhead Golf Club (Black Bear)
private let ARROWHEAD_BLACK_BEAR_ID = UUID(uuidString: "F7D45E67-89AB-4CDE-9FAB-1234567890AB")!

let ARROWHEAD_BLACK_BEAR_PARS: [Int] = [
    4,5,3,4,4,4,4,4,3,
    4,3,4,3,4,4,5,3,5
]

let ARROWHEAD_BLACK_BEAR_HCS: [Int] = [
    8,2,10,6,14,4,16,12,18,
    3,17,1,9,13,5,11,7,15
]

let ARROWHEAD_BLACK_BEAR_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black Bear", yardage: 6636, rating: 72.0, slope: 139)
]
// MARK: - Arrowhead Golf Club (South / West)
private let ARROWHEAD_SOUTH_WEST_ID = UUID(uuidString: "B9F67A89-01BC-4DEF-9ABC-1234567890AB")!

let ARROWHEAD_SOUTH_WEST_PARS: [Int] = [
    4,5,4,3,4,3,5,4,4,
    4,4,4,4,3,5,3,5,4
]

let ARROWHEAD_SOUTH_WEST_HCS: [Int] = [
    9,3,6,8,1,5,7,2,4,
    2,6,5,7,9,1,8,3,4
]

let ARROWHEAD_SOUTH_WEST_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue",  yardage: 7219, rating: 72.9, slope: 134),
    TeeInfo(teeName: "White", yardage: 7011, rating: 70.1, slope: 127),
    TeeInfo(teeName: "Combo", yardage: 6711, rating: 67.7, slope: 121),
    TeeInfo(teeName: "Red",   yardage: 6194, rating: 69.4, slope: 123)
]

// MARK: - Arrowhead Golf Club (West / East)
private let ARROWHEAD_WEST_EAST_ID = UUID(uuidString: "C0A78B9A-12CD-4EF0-9BCD-1234567890AB")!

let ARROWHEAD_WEST_EAST_PARS: [Int] = [
    4,4,4,4,3,5,3,5,4,
    5,4,3,5,4,4,4,3,4
]

let ARROWHEAD_WEST_EAST_HCS: [Int] = [
    2,6,5,7,9,1,8,3,4,
    1,7,9,3,6,2,8,5,4
]

let ARROWHEAD_WEST_EAST_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue",  yardage: 7267, rating: 72.6, slope: 133),
    TeeInfo(teeName: "White", yardage: 7011, rating: 70.6, slope: 128),
    TeeInfo(teeName: "Combo", yardage: 6711, rating: 67.4, slope: 121),
    TeeInfo(teeName: "Red",   yardage: 6119, rating: 68.7, slope: 119)
]
// MARK: - Pinehurst No. 2
private let PINEHURST_NO2_ID = UUID(uuidString: "D1E89F01-2345-4ABC-9DEF-1234567890AB")!

let PINEHURST_NO2_PARS: [Int] = [
    4,4,4,4,5,3,4,5,3,
    5,4,4,4,4,3,5,3,4
]

let PINEHURST_NO2_HCS: [Int] = [
    11,3,9,1,15,5,7,17,13,
    18,8,10,6,2,12,16,14,4
]

let PINEHURST_NO2_TEES: [TeeInfo] = [
    TeeInfo(teeName: "U.S. Open", yardage: 7588, rating: 77.8, slope: 149),
    TeeInfo(teeName: "Blue",      yardage: 6961, rating: 75.2, slope: 144),
    TeeInfo(teeName: "White",     yardage: 6307, rating: 72.0, slope: 139),
    TeeInfo(teeName: "Green",     yardage: 5771, rating: 69.1, slope: 134),
    TeeInfo(teeName: "Red",       yardage: 5302, rating: 66.8, slope: 128)
]
// MARK: - Pinehurst No. 4
private let PINEHURST_NO4_ID = UUID(uuidString: "E2F3A4B5-6789-4CDE-AB12-1234567890CD")!

let PINEHURST_NO4_PARS: [Int] = [
    4,5,4,3,4,3,4,4,5,
    4,4,3,5,3,4,4,5,4
]

let PINEHURST_NO4_HCS: [Int] = [
    7,13,11,17,1,9,3,15,5,
    4,18,10,8,12,16,14,6,2
]

let PINEHURST_NO4_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Orange", yardage: 7227, rating: 74.2, slope: 136),
    TeeInfo(teeName: "Blue",   yardage: 6961, rating: 71.7, slope: 129),
    TeeInfo(teeName: "White",  yardage: 6428, rating: 69.5, slope: 126),
    TeeInfo(teeName: "Green",  yardage: 5864, rating: 67.2, slope: 115),
    TeeInfo(teeName: "Red",    yardage: 5260, rating: 64.7, slope: 109)
]
// MARK: - Tobacco Road Golf Club
private let TOBACCO_ROAD_ID = UUID(uuidString: "F4A7C2D9-8B12-4E6F-ABCD-9876543210EF")!

let TOBACCO_ROAD_PARS: [Int] = [
    5,4,3,5,4,3,4,3,4,
    4,5,4,5,3,4,4,3,4
]

let TOBACCO_ROAD_HCS: [Int] = [
    3,11,17,9,15,13,7,5,1,
    6,10,14,2,8,12,16,18,4
]

let TOBACCO_ROAD_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Ripper",     yardage: 6532, rating: 71.7, slope: 144),
    TeeInfo(teeName: "Disc",       yardage: 6297, rating: 70.3, slope: 135),
    TeeInfo(teeName: "Plow",       yardage: 5886, rating: 68.6, slope: 140),
    TeeInfo(teeName: "Cultivator", yardage: 4946, rating: 69.8, slope: 126)
]
// MARK: - Black Desert Resort (Tournament)

private let BLACK_DESERT_RESORT_ID = UUID(uuidString: "C4D9B822-7A91-4E77-92D1-300000000001")!

let BLACK_DESERT_RESORT_PARS: [Int] = [
    4,4,3,4,4,4,5,3,5,
    4,4,4,5,4,3,4,3,5
]

let BLACK_DESERT_RESORT_HCS: [Int] = [
    9,11,15,1,13,5,3,17,7,
    14,2,6,10,16,12,4,18,8
]

let BLACK_DESERT_RESORT_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Tournament",
        yardage: 7393,
        rating: 75.4,
        slope: 139
    )
]
// MARK: - Shadow Creek
private let SHADOW_CREEK_ID = UUID(uuidString: "C7E9F2A1-5B34-4D89-ABCD-2468135790AB")!

let SHADOW_CREEK_PARS: [Int] = [
    4,4,4,5,3,4,5,3,4,
    4,4,4,3,4,4,5,3,5
]

let SHADOW_CREEK_HCS: [Int] = [
    13,9,1,7,15,3,11,17,5,
    12,18,14,8,4,2,6,16,10
]

let SHADOW_CREEK_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 7560, rating: 74.5, slope: 145)
]
// MARK: - Primland Resort (Highland Course)

private let PRIMLAND_HIGHLAND_ID = UUID(uuidString: "A9F2C6E1-5B3A-4C1F-9A11-200000000001")!

let PRIMLAND_HIGHLAND_PARS: [Int] = [
    4,4,4,5,3,4,5,3,4,
    4,4,4,3,4,4,5,3,5
]

let PRIMLAND_HIGHLAND_HCS: [Int] = [
    6,16,8,12,4,2,10,14,18,
    1,9,17,7,15,13,3,11,5
]

let PRIMLAND_HIGHLAND_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 7053,
        rating: 74.7,
        slope: 140
    ),
    TeeInfo(
        teeName: "Blue",
        yardage: 6771,
        rating: 73.0,
        slope: 136
    ),
    TeeInfo(
        teeName: "Gold",
        yardage: 6450,
        rating: 71.5,
        slope: 132
    ),
    TeeInfo(
        teeName: "Silver",
        yardage: 6013,
        rating: 69.8,
        slope: 128
    )
]
// MARK: - Ironwood Country Club (South Course)

private let IRONWOOD_CC_SOUTH_ID = UUID(uuidString: "D7A3F2B1-8C44-4E11-9B22-400000000001")!

let IRONWOOD_CC_SOUTH_PARS: [Int] = [
    4,5,4,3,5,3,4,4,4,
    5,4,4,4,3,5,4,3,4
]

let IRONWOOD_CC_SOUTH_HCS: [Int] = [
    9,17,7,11,3,15,1,13,5,
    12,6,14,4,18,10,2,16,8
]

let IRONWOOD_CC_SOUTH_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 7274,
        rating: 75.3,
        slope: 136
    )
]

// MARK: - Ironwood Country Club (North Course)

private let IRONWOOD_CC_NORTH_ID = UUID(uuidString: "D7A3F2B1-8C44-4E11-9B22-400000000002")!

let IRONWOOD_CC_NORTH_PARS: [Int] = [
    4,4,4,3,5,4,3,4,5,
    5,3,3,4,4,3,4,4,5
]

let IRONWOOD_CC_NORTH_HCS: [Int] = [
    7,5,9,13,17,1,11,3,15,
    16,18,12,14,2,10,4,8,6
]

let IRONWOOD_CC_NORTH_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Blue",
        yardage: 6212,
        rating: 69.1,
        slope: 121
    )
]
// MARK: - Wynn Golf Club

private let WYNN_GOLF_CLUB_ID = UUID(uuidString: "E8C4A9D1-6F22-4D11-9A33-500000000001")!

let WYNN_GOLF_CLUB_PARS: [Int] = [
    4,3,5,4,3,4,3,5,4,
    3,5,3,5,4,4,4,4,3
]

let WYNN_GOLF_CLUB_HCS: [Int] = [
    13,11,1,5,17,9,15,7,3,
    10,2,16,12,6,18,4,14,8
]

let WYNN_GOLF_CLUB_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 6722,
        rating: 71.1,
        slope: 119
    )
]
// MARK: - Cascata

private let CASCATA_BLACK_ID = UUID(uuidString: "E8C4A9D1-6F22-4D11-9A33-500000000008")!

let CASCATA_BLACK_PARS: [Int] = [
    4,4,5,3,5,4,3,4,4,
    4,4,3,4,4,3,5,4,5
]

let CASCATA_BLACK_HCS: [Int] = [
    11,1,15,9,13,5,17,3,7,
    6,12,18,4,8,10,14,2,16
]

let CASCATA_BLACK_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 6980,
        rating: 73.4,
        slope: 141
    )
]
// MARK: - Las Vegas Paiute Golf Resort (The Wolf)

private let PAIUTE_WOLF_ID = UUID(uuidString: "F1A7C3D2-9E44-4B11-8A21-600000000002")!

let PAIUTE_WOLF_PARS: [Int] = [
    4,4,5,3,4,5,4,3,4,
    5,4,3,5,4,3,4,4,4
]

let PAIUTE_WOLF_HCS: [Int] = [
    7,17,3,11,9,15,1,13,5,
    6,18,10,12,2,16,14,4,8
]

let PAIUTE_WOLF_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Tournament",
        yardage: 7604,
        rating: 76.3,
        slope: 149
    ),
    TeeInfo(
        teeName: "Black",
        yardage: 7009,
        rating: 73.5,
        slope: 134
    ),
    TeeInfo(
        teeName: "Yellow",
        yardage: 6483,
        rating: 71.4,
        slope: 130
    )
]
private let BALI_HAI_GC_ID = UUID(uuidString: "E8C4A9D1-6F22-4D11-9A33-500000000002")!

let BALI_HAI_GC_PARS: [Int] = [
    4,5,4,4,4,3,5,4,3,
    5,3,4,4,3,5,3,4,4
]

let BALI_HAI_GC_HCS: [Int] = [
    17,7,3,13,11,15,5,1,9,
    14,18,10,4,12,8,16,6,2
]

let BALI_HAI_GC_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 6858,
        rating: 74.1,
        slope: 137
    )
]
private let BEARS_BEST_LV_ID = UUID(uuidString: "E8C4A9D1-6F22-4D11-9A33-500000000003")!

let BEARS_BEST_LV_PARS: [Int] = [
    4,5,4,3,4,4,3,5,4,
    4,4,5,3,4,3,4,5,4
]

let BEARS_BEST_LV_HCS: [Int] = [
    11,5,3,9,1,15,13,17,7,
    6,18,10,16,4,8,14,12,2
]

let BEARS_BEST_LV_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Gold",
        yardage: 7194,
        rating: 74.5,
        slope: 140
    )
]
private let REFLECTION_BAY_GC_ID = UUID(uuidString: "E8C4A9D1-6F22-4D11-9A33-500000000004")!

let REFLECTION_BAY_GC_PARS: [Int] = [
    4,4,3,4,4,5,4,3,5,
    4,4,5,3,5,4,4,3,4
]

let REFLECTION_BAY_GC_HCS: [Int] = [
    8,18,16,12,2,6,10,14,4,
    13,7,9,17,15,1,3,11,5
]

let REFLECTION_BAY_GC_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Gold",
        yardage: 7261,
        rating: 75.6,
        slope: 150
    )
]

private let REVERE_LEXINGTON_ID = UUID(uuidString: "E8C4A9D1-6F22-4D11-9A33-500000000005")!

let REVERE_LEXINGTON_PARS: [Int] = [
    4,5,4,3,4,4,5,3,4,
    4,5,4,3,4,4,5,3,4
]

let REVERE_LEXINGTON_HCS: [Int] = [
    18,16,2,14,10,6,8,12,4,
    3,5,13,17,1,11,9,15,7
]

let REVERE_LEXINGTON_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 7123,
        rating: 74.7,
        slope: 145
    ),
    TeeInfo(
        teeName: "Gold",
        yardage: 6590,
        rating: 71.4,
        slope: 135
    ),
    TeeInfo(
        teeName: "Silver",
        yardage: 5941,
        rating: 68.7,
        slope: 123
    ),
    TeeInfo(
        teeName: "Bronze",
        yardage: 5216,
        rating: 65.9,
        slope: 120
    )
]
private let CASCATA_SERKET_ID = UUID(uuidString: "E8C4A9D1-6F22-4D11-9A33-500000000007")!

let CASCATA_SERKET_PARS: [Int] = [
    4,4,3,4,4,3,4,5,5,
    4,4,3,4,5,4,3,5,4
]

let CASCATA_SERKET_HCS: [Int] = [
    13,3,11,17,1,7,9,15,5,
    8,2,18,14,12,6,10,16,4
]

let CASCATA_SERKET_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Tournament",
        yardage: 7215,
        rating: 74.7,
        slope: 140
    )
]
private let REVERE_CONCORD_ID = UUID(uuidString: "E8C4A9D1-6F22-4D11-9A33-500000000006")!

let REVERE_CONCORD_PARS: [Int] = [
    4,5,4,4,3,4,4,3,5,
    4,5,3,4,4,4,3,4,5
]

let REVERE_CONCORD_HCS: [Int] = [
    12,18,2,8,16,14,6,10,4,
    11,17,9,15,3,13,5,1,7
]

let REVERE_CONCORD_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 7069,
        rating: 73.5,
        slope: 140
    ),
    TeeInfo(
        teeName: "Gold",
        yardage: 6545,
        rating: 71.0,
        slope: 130
    ),
    TeeInfo(
        teeName: "Silver",
        yardage: 6094,
        rating: 67.9,
        slope: 126
    ),
    TeeInfo(
        teeName: "Bronze",
        yardage: 5171,
        rating: 64.5,
        slope: 111
    )
]
// MARK: - TPC Las Vegas

private let TPC_LAS_VEGAS_ID = UUID(uuidString: "D9F3B8C1-9E77-4C2F-9A11-900000000001")!

let TPC_LAS_VEGAS_PARS: [Int] = [
    4,3,4,5,4,3,4,3,4,
    4,4,3,4,4,3,4,3,5
]

let TPC_LAS_VEGAS_HCS: [Int] = [
    17,5,11,15,9,7,13,3,1,
    12,4,18,2,16,6,14,8,10
]

// TPC / Tournament Tees (~7016 yards)
let TPC_LAS_VEGAS_TEES: [TeeInfo] = [

    TeeInfo(
        teeName: "TPC",
        yardage: 7016,
        rating: 73.4,
        slope: 136
    )

]

// Yardages (TPC / Tournament)
let TPC_LAS_VEGAS_YARDS: [Int] = [
    365,193,458,541,367,595,203,454,346,
    418,444,173,437,347,440,346,445,350
]
private let TPC_SUMMERLIN_ID = UUID(uuidString: "A1B2C3D4-1111-4444-8888-000000000001")!

let TPC_SUMMERLIN_PARS: [Int] = [
4,4,5,4,3,4,4,3,5,
4,4,4,5,3,4,5,3,4
]

let TPC_SUMMERLIN_HCS: [Int] = [
7,5,15,3,13,1,11,9,17,
8,2,4,12,18,16,6,14,10
]

let TPC_SUMMERLIN_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Shriners",
        yardage: 7198,
        rating: 74.7,
        slope: 143
    )
]
private let TRUMP_DORAL_BLUE_ID = UUID(uuidString: "C8D20000-0000-0000-0000-000000000101")!

let TRUMP_DORAL_BLUE_PARS: [Int] = [
    5,4,4,3,4,4,4,5,3,
    5,4,5,3,4,3,4,4,4
]

let TRUMP_DORAL_BLUE_HCS: [Int] = [
    5,17,3,13,15,7,1,9,11,
    4,16,8,10,6,18,14,12,2
]

let TRUMP_DORAL_BLUE_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 7545,
        rating: 77.4,
        slope: 146
    )
]
// MARK: - Trump International Golf Club - Championship

private let TRUMP_INTL_WEST_PALM_CHAMPIONSHIP_ID = UUID(uuidString: "C8D20000-0000-0000-0000-100000000201")!

let TRUMP_INTL_WEST_PALM_CHAMPIONSHIP_PARS: [Int] = [
    4,4,5,4,3,4,3,4,5,
    4,3,5,4,4,5,4,3,4
]

let TRUMP_INTL_WEST_PALM_CHAMPIONSHIP_HCS: [Int] = [
    3,13,5,17,9,15,11,1,7,
    16,18,6,4,12,14,10,8,2
]

let TRUMP_INTL_WEST_PALM_CHAMPIONSHIP_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 7210,
        rating: 76.3,
        slope: 155
    )
]


// MARK: - Trump National Golf Club Jupiter

private let TRUMP_NATIONAL_JUPITER_ID = UUID(uuidString: "C8D20000-0000-0000-0000-000000000202")!

let TRUMP_NATIONAL_JUPITER_PARS: [Int] = [
    4,5,4,3,4,5,3,4,4,
    4,3,4,5,3,4,4,5,4
]

let TRUMP_NATIONAL_JUPITER_HCS: [Int] = [
    15,7,1,17,5,11,13,3,9,
    8,16,2,14,18,6,12,10,4
]

let TRUMP_NATIONAL_JUPITER_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 7404,
        rating: 76.5,
        slope: 150
    )
]


// MARK: - Trump National Golf Club Bedminster (Old Course)

private let TRUMP_BEDMINSTER_OLD_ID = UUID(uuidString: "C8D20000-0000-0000-0000-000000000203")!

let TRUMP_BEDMINSTER_OLD_PARS: [Int] = [
    4,4,4,3,4,4,3,5,4,
    4,4,4,4,3,4,3,4,5
]

let TRUMP_BEDMINSTER_OLD_HCS: [Int] = [
    13,11,3,17,1,7,15,9,5,
    12,4,8,2,18,14,16,6,10
]

let TRUMP_BEDMINSTER_OLD_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 7781,
        rating: 77.6,
        slope: 153
    )
]
private let TRUMP_BEDMINSTER_NEW_ID = UUID(uuidString: "C8D20000-0000-0000-0000-000000000204")!

let TRUMP_BEDMINSTER_NEW_PARS: [Int] = [
    4,3,4,5,4,3,4,5,4,
    3,5,4,4,3,5,4,4,4
]

let TRUMP_BEDMINSTER_NEW_HCS: [Int] = [
    3,15,11,13,1,17,7,9,5,
    18,4,14,10,16,2,12,6,8
]

let TRUMP_BEDMINSTER_NEW_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 7564,
        rating: 76.7,
        slope: 150
    )
]



// MARK: - Trump National Golf Club Colts Neck

private let TRUMP_COLTS_NECK_ID = UUID(uuidString: "C8D20000-0000-0000-0000-200000000204")!

let TRUMP_COLTS_NECK_PARS: [Int] = [
    4,5,3,4,4,4,5,3,4,
    4,3,4,5,4,3,4,4,5
]

let TRUMP_COLTS_NECK_HCS: [Int] = [
    3,15,11,17,1,7,13,9,5,
    4,18,8,16,2,10,12,6,14
]

let TRUMP_COLTS_NECK_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Gold",
        yardage: 7579,
        rating: 77.2,
        slope: 149
    )
]


// MARK: - Trump National GC - Philly

private let TRUMP_NATIONAL_PHILLY_ID = UUID(uuidString: "C8D20000-0000-0000-0000-000000000205")!

let TRUMP_NATIONAL_PHILLY_PARS: [Int] = [
    5,3,4,4,3,4,5,3,5,
    4,4,4,3,5,4,3,4,4
]

let TRUMP_NATIONAL_PHILLY_HCS: [Int] = [
    17,15,3,1,9,7,5,11,13,
    4,10,8,18,16,2,14,6,12
]

let TRUMP_NATIONAL_PHILLY_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Trump",
        yardage: 7191,
        rating: 75.4,
        slope: 147
    )
]

private let TRUMP_NATIONAL_WESTCHESTER_ID = UUID(uuidString: "C8D20000-0000-0000-0000-200000000201")!

let TRUMP_NATIONAL_WESTCHESTER_PARS: [Int] = [
    4,5,4,4,5,3,4,3,4,
    4,4,5,3,4,3,5,4,4
]

let TRUMP_NATIONAL_WESTCHESTER_HCS: [Int] = [
    13,11,1,9,5,17,15,7,3,
    8,6,2,12,16,18,4,14,10
]

let TRUMP_NATIONAL_WESTCHESTER_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 7361,
        rating: 77.8,
        slope: 153
    )
]
private let TRUMP_NATIONAL_HUDSON_VALLEY_ID = UUID(uuidString: "C8D20000-0000-0000-0000-000000000206")!

let TRUMP_NATIONAL_HUDSON_VALLEY_PARS: [Int] = [
    4,5,3,5,4,4,3,4,4,
    4,4,3,4,5,5,4,3,4
]

let TRUMP_NATIONAL_HUDSON_VALLEY_HCS: [Int] = [
    5,1,17,9,7,3,13,15,11,
    6,18,14,4,12,2,16,10,8
]

let TRUMP_NATIONAL_HUDSON_VALLEY_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Gold",
        yardage: 7693,
        rating: 77.3,
        slope: 147
    )
]

private let TRUMP_NATIONAL_LOS_ANGELES_ID = UUID(uuidString: "C8D20000-0000-0000-0000-000000000207")!

let TRUMP_NATIONAL_LOS_ANGELES_PARS: [Int] = [
    4,5,4,3,4,4,5,3,4,
    4,3,5,4,5,3,4,3,4
]

let TRUMP_NATIONAL_LOS_ANGELES_HCS: [Int] = [
    11,15,13,17,3,5,9,7,1,
    10,8,12,4,6,16,18,14,2
]

let TRUMP_NATIONAL_LOS_ANGELES_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 6871,
        rating: 75.0,
        slope: 144
    )
]

private let TRUMP_NATIONAL_CHARLOTTE_ID = UUID(uuidString: "C8D20000-0000-0000-0000-000000000208")!

let TRUMP_NATIONAL_CHARLOTTE_PARS: [Int] = [
    4,5,3,4,4,4,3,5,4,
    4,4,5,3,4,3,5,4,4
]

let TRUMP_NATIONAL_CHARLOTTE_HCS: [Int] = [
    8,6,14,12,4,2,16,18,10,
    1,7,15,9,5,17,11,13,3
]

let TRUMP_NATIONAL_CHARLOTTE_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black Tees",
        yardage: 7296,
        rating: 75.7,
        slope: 146
    )
]

private let TRUMP_NATIONAL_WASHINGTON_DC_CHAMPIONSHIP_ID = UUID(uuidString: "C8D20000-0000-0000-0000-000000000209")!

let TRUMP_NATIONAL_WASHINGTON_DC_CHAMPIONSHIP_PARS: [Int] = [
    4,5,3,4,4,5,4,4,3,
    4,4,5,4,3,4,3,5,4
]

let TRUMP_NATIONAL_WASHINGTON_DC_CHAMPIONSHIP_HCS: [Int] = [
    13,9,15,1,5,7,3,17,11,
    14,2,10,6,18,4,16,8,12
]

let TRUMP_NATIONAL_WASHINGTON_DC_CHAMPIONSHIP_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Gold",
        yardage: 7793,
        rating: 78.0,
        slope: 142
    )
]

private let BALLYS_FERRY_POINT_ID = UUID(uuidString: "C8D20000-0000-0000-0000-000000000210")!

let BALLYS_FERRY_POINT_PARS: [Int] = [
    4,4,3,5,4,4,4,3,4,
    4,4,3,4,4,5,4,3,5
]

let BALLYS_FERRY_POINT_HCS: [Int] = [
    9,1,15,3,7,5,13,17,11,
    6,14,18,8,10,2,4,16,12
]

let BALLYS_FERRY_POINT_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 7407,
        rating: 76.1,
        slope: 141
    )
]
private let OLD_MEMORIAL_ID = UUID(uuidString: "B7A10000-0000-0000-0000-000000000122")!

let OLD_MEMORIAL_PARS: [Int] = [
    4,4,5,3,4,4,3,4,5,
    4,3,5,4,4,4,3,4,4
]

let OLD_MEMORIAL_HCS: [Int] = [
    9,5,3,13,1,11,17,7,15,
    8,18,2,12,6,4,16,10,14
]

let OLD_MEMORIAL_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 7401,
        rating: 75.9,
        slope: 144
    )
]
private let CONCESSION_GC_ID = UUID(uuidString: "B7A10000-0000-0000-0000-000000000103")!

let CONCESSION_GC_PARS: [Int] = [
    4,4,5,3,4,3,5,4,4,
    4,3,4,5,4,4,5,3,4
]

let CONCESSION_GC_HCS: [Int] = [
    13,7,5,17,3,15,1,11,9,
    10,18,6,2,8,4,12,16,14
]

let CONCESSION_GC_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 7492,
        rating: 78.1,
        slope: 155
    )
]
private let INNISBROOK_COPPERHEAD_ID = UUID(uuidString: "B7A10000-0000-0000-0000-000000000104")!

let INNISBROOK_COPPERHEAD_PARS: [Int] = [
    5,4,4,3,5,4,4,3,4,
    4,5,4,3,5,3,4,3,4
]

let INNISBROOK_COPPERHEAD_HCS: [Int] = [
    5,11,7,17,1,3,13,15,9,
    8,6,12,18,2,14,4,16,10
]

let INNISBROOK_COPPERHEAD_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 7209,
        rating: 75.6,
        slope: 144
    ),
    TeeInfo(
        teeName: "Green",
        yardage: 6624,
        rating: 73.0,
        slope: 138
    ),
    TeeInfo(
        teeName: "White",
        yardage: 6243,
        rating: 71.2,
        slope: 134
    ),
    TeeInfo(
        teeName: "Gold",
        yardage: 5676,
        rating: 69.0,
        slope: 131
    )
]
private let FLORIDIAN_NATIONAL_ID = UUID(uuidString: "B7A10000-0000-0000-0000-000000000105")!

let FLORIDIAN_NATIONAL_PARS: [Int] = [
    4,3,4,3,5,4,5,3,4,
    4,4,3,5,4,5,3,4,4
]

let FLORIDIAN_NATIONAL_HCS: [Int] = [
    9,13,7,11,1,17,5,15,3,
    12,8,18,6,10,4,16,14,2
]

let FLORIDIAN_NATIONAL_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 6958,
        rating: 74.7,
        slope: 145
    )
]
private let INVERNESS_GC_ID = UUID(uuidString: "B7A10000-0000-0000-0000-000000000106")!

let INVERNESS_GC_PARS: [Int] = [
    4,4,4,4,4,4,3,5,3,
    4,4,4,4,4,4,4,4,4
]

let INVERNESS_GC_HCS: [Int] = [
    12,4,10,2,6,16,14,8,18,
    11,3,7,15,1,17,5,13,9
]

let INVERNESS_GC_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Championship",
        yardage: 6600,   // estimate from front/back totals (~3241 + ~3350 range)
        rating: 73.3,
        slope: 139
    ),
    TeeInfo(
        teeName: "Member",
        yardage: 6200,
        rating: 71.8,
        slope: 136
    ),
    TeeInfo(
        teeName: "Intermediate",
        yardage: 5900,
        rating: 70.9,
        slope: 134
    )
    
]
// MARK: - Wynstone Golf Club

private let WYNSTONE_GC_ID = UUID(uuidString: "D4A1F8E2-9C3A-4D91-B8A1-100000000111")!

let WYNSTONE_GC_PARS: [Int] = [
    4,4,5,3,4,4,3,4,5,
    4,3,5,4,3,4,4,4,5
]

let WYNSTONE_GC_HCS: [Int] = [
    18,10,2,14,6,4,16,12,8,
    1,17,7,15,13,3,11,5,9
]

let WYNSTONE_GC_TEES: [TeeInfo] = [

    TeeInfo(
        teeName: "Black",
        yardage: 7162,
        rating: 75.4,
        slope: 147
    ),

    TeeInfo(
        teeName: "Gold",
        yardage: 6864,
        rating: 74.0,
        slope: 143
    ),

    TeeInfo(
        teeName: "Silver",
        yardage: 6384,
        rating: 71.8,
        slope: 138
    ),

    TeeInfo(
        teeName: "Blue",
        yardage: 5946,
        rating: 69.8,
        slope: 133
    ),

    TeeInfo(
        teeName: "Red",
        yardage: 5201,
        rating: 71.3,
        slope: 134
    )
]
// MARK: - Shingle Creek Golf Club

private let SHINGLE_CREEK_GC_ID = UUID(uuidString: "D4A1C2B3-9876-4F21-ABCD-1234567890AB")!

let SHINGLE_CREEK_GC_PARS: [Int] = [
    4,5,4,4,3,4,4,3,5,
    4,4,3,4,5,4,3,4,5
]

let SHINGLE_CREEK_GC_HCS: [Int] = [
    9,5,11,1,15,7,13,17,3,
    10,6,16,2,8,12,18,14,4
]

let SHINGLE_CREEK_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black",  yardage: 7213, rating: 74.0, slope: 140),
    TeeInfo(teeName: "Gold",   yardage: 6749, rating: 71.7, slope: 134),
    TeeInfo(teeName: "Blue",   yardage: 6320, rating: 69.9, slope: 130),
    TeeInfo(teeName: "White",  yardage: 5810, rating: 67.5, slope: 125),
    TeeInfo(teeName: "Silver", yardage: 5290, rating: 65.2, slope: 120)
]
// MARK: - TPC Scottsdale (Stadium Course)

private let TPC_SCOTTSDALE_STADIUM_ID = UUID(uuidString: "A5D1F0C2-3101-4D22-8A11-100000000202")!

let TPC_SCOTTSDALE_STADIUM_PARS: [Int] = [
    4,4,5,3,4,4,3,4,4,
    4,4,3,5,4,5,3,4,4
]

let TPC_SCOTTSDALE_STADIUM_HCS: [Int] = [
    14,8,4,18,6,12,16,2,10,
    11,1,15,5,7,9,17,13,3
]

let TPC_SCOTTSDALE_STADIUM_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Championship",
        yardage: 7261,
        rating: 74.7,
        slope: 142
    )
]
// MARK: - TPC Scottsdale (Champions Course)

private let TPC_SCOTTSDALE_CHAMPIONS_ID = UUID(uuidString: "A5D1F0C2-3101-4D22-8A11-100000000201")!

let TPC_SCOTTSDALE_CHAMPIONS_PARS: [Int] = [
    4,4,3,5,4,3,4,3,5,
    5,4,4,3,4,4,3,5,4
]

let TPC_SCOTTSDALE_CHAMPIONS_HCS: [Int] = [
    16,8,18,6,2,12,14,10,4,
    11,7,5,17,13,15,9,3,1
]

let TPC_SCOTTSDALE_CHAMPIONS_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 7091,
        rating: 73.2,
        slope: 135
    )
]
// MARK: - Talking Stick Golf Club (Piipaash Course)

private let TALKING_STICK_PIIPAASH_ID = UUID(uuidString: "A5D1F0C2-3101-4D22-8A11-100000000203")!

let TALKING_STICK_PIIPAASH_PARS: [Int] = [
    4,4,3,4,4,4,5,4,3,
    4,4,4,3,5,4,5,3,4
]

let TALKING_STICK_PIIPAASH_HCS: [Int] = [
    13,3,7,17,1,15,9,5,11,
    10,8,2,16,6,4,14,18,12
]

let TALKING_STICK_PIIPAASH_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 6833,
        rating: 72.0,
        slope: 126
    ),

    TeeInfo(
        teeName: "Gold",
        yardage: 6430,
        rating: 69.6,
        slope: 120
    ),

    TeeInfo(
        teeName: "Gold/Jade",
        yardage: 6040,
        rating: 67.4,
        slope: 112
    ),

    TeeInfo(
        teeName: "Jade",
        yardage: 5331,
        rating: 64.9,
        slope: 108
    )
]
// MARK: - Talking Stick Golf Club (O’odham Course)

private let TALKING_STICK_ODHAM_ID = UUID(uuidString: "E4A1C9B2-7F3D-4D11-9C22-6B8A2E1F5501")!

let TALKING_STICK_ODHAM_PARS: [Int] = [
    4,5,4,4,4,3,4,3,4,
    4,3,4,4,4,4,3,5,4
]

let TALKING_STICK_ODHAM_HCS: [Int] = [
    15,13,3,1,11,5,9,17,7,
    12,6,2,16,8,14,18,4,10
]
let TALKING_STICK_ODHAM_TEES: [TeeInfo] = [

    TeeInfo(
        teeName: "Black",
        yardage: 7133,
        rating: 72.2,
        slope: 125
    ),

    TeeInfo(
        teeName: "Gold",
        yardage: 6510,
        rating: 69.7,
        slope: 120
    ),

    TeeInfo(
        teeName: "Gold/Jade",
        yardage: 5945,
        rating: 66.4,
        slope: 115
    ),

    TeeInfo(
        teeName: "Jade",
        yardage: 5532,
        rating: 64.6,
        slope: 113
    )
]

// MARK: - Kierland Golf Club (Acacia / Mesquite)

private let KIERLAND_ACACIA_MESQUITE_ID = UUID(uuidString: "A5D1F0C2-3101-4D22-8A11-100000000204")!

let KIERLAND_ACACIA_MESQUITE_PARS: [Int] = [
    5,4,4,3,5,3,4,3,5,
    4,4,4,3,5,4,5,3,4
]

let KIERLAND_ACACIA_MESQUITE_HCS: [Int] = [
    16,8,4,18,2,12,10,14,6,
    11,9,17,15,5,3,7,13,1
]

let KIERLAND_ACACIA_MESQUITE_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Cinder",
        yardage: 6914,
        rating: 72.5,
        slope: 127
    )
]

// MARK: - Kierland Golf Club (Ironwood / Mesquite)

private let KIERLAND_IRONWOOD_MESQUITE_ID = UUID(uuidString: "A5D1F0C2-3101-4D22-8A11-100000000206")!

let KIERLAND_IRONWOOD_MESQUITE_PARS: [Int] = [
    4,4,3,4,3,4,5,4,5,   // Ironwood
    4,4,4,3,5,4,5,3,4    // Mesquite
]

let KIERLAND_IRONWOOD_MESQUITE_HCS: [Int] = [
    1,5,17,7,13,11,15,9,3,
    12,10,18,16,6,4,8,14,2
]
let KIERLAND_IRONWOOD_MESQUITE_TEES: [TeeInfo] = [

    TeeInfo(
        teeName: "Black",
        yardage: 7017,
        rating: 72.8,
        slope: 128
    ),

    TeeInfo(
        teeName: "Copper",
        yardage: 6340,
        rating: 70.5,
        slope: 124
    ),

    TeeInfo(
        teeName: "Indigo",
        yardage: 5851,
        rating: 68.4,
        slope: 120
    ),

    TeeInfo(
        teeName: "Turquoise",
        yardage: 5432,
        rating: 66.5,
        slope: 116
    ),

    TeeInfo(
        teeName: "Lava",
        yardage: 5017,
        rating: 64.0,
        slope: 110
    )
]
// MARK: - Kierland Golf Club (Ironwood / Acacia)

private let KIERLAND_IRONWOOD_ACACIA_ID = UUID(uuidString: "A5D1F0C2-3101-4D22-8A11-100000000205")!

let KIERLAND_IRONWOOD_ACACIA_PARS: [Int] = [
    4,4,3,4,3,4,5,4,5,
    5,4,4,3,5,3,4,3,5
]

let KIERLAND_IRONWOOD_ACACIA_HCS: [Int] = [
    1,5,17,7,13,11,15,9,3,
    16,8,4,18,2,12,10,14,6
]

let KIERLAND_IRONWOOD_ACACIA_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Cinder",
        yardage: 6976,
        rating: 72.8,
        slope: 128
    )
]
// MARK: - Camelback Golf Club (Ambiente)

private let CAMELBACK_AMBIENTE_ID = UUID(uuidString: "A5D1F0C2-3101-4D22-8A11-100000000301")!

let CAMELBACK_AMBIENTE_PARS: [Int] = [
    4,3,5,4,4,4,5,3,4,
    4,3,4,4,5,3,5,4,4
]

let CAMELBACK_AMBIENTE_HCS: [Int] = [
    5,11,17,13,15,1,7,9,3,
    18,12,2,14,6,8,16,4,10
]

let CAMELBACK_AMBIENTE_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 7225,
        rating: 74.2,
        slope: 138
    )
]
// MARK: - Camelback Golf Club (Padre)

private let CAMELBACK_PADRE_ID = UUID(uuidString: "A5D1F0C2-3101-4D22-8A11-100000000302")!

let CAMELBACK_PADRE_PARS: [Int] = [
    4,4,3,4,5,4,4,3,5,
    4,3,4,5,4,4,3,5,4
]

let CAMELBACK_PADRE_HCS: [Int] = [
    7,13,17,9,1,3,15,11,5,
    2,18,16,10,14,6,12,8,4
]

let CAMELBACK_PADRE_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 6868,
        rating: 72.2,
        slope: 130
    )
]

// MARK: - The Boulders (North Course)

private let BOULDERS_NORTH_ID = UUID(uuidString: "A5D1F0C2-3101-4D22-8A11-100000000303")!

let BOULDERS_NORTH_PARS: [Int] = [
    5,3,5,4,4,3,4,4,4,
    4,4,5,4,3,4,4,3,4
]

let BOULDERS_NORTH_HCS: [Int] = [
    6,18,4,10,2,16,12,8,14,
    1,5,3,11,7,13,9,17,15
]

let BOULDERS_NORTH_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 6849,
        rating: 73.3,
        slope: 138
    )
]
// MARK: - The Boulders (South Course)

private let BOULDERS_SOUTH_ID = UUID(uuidString: "A5D1F0C2-3101-4D22-8A11-100000000304")!

let BOULDERS_SOUTH_PARS: [Int] = [
    4,3,4,5,4,3,4,5,4,
    4,5,4,4,3,4,3,4,5
]

let BOULDERS_SOUTH_HCS: [Int] = [
    9,13,7,1,3,15,11,5,17,
    2,6,12,10,8,14,18,4,16
]

let BOULDERS_SOUTH_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 6917,
        rating: 72.9,
        slope: 142
    )
]
// MARK: - Ak-Chin Southern Dunes Golf Club

private let AK_CHIN_SOUTHERN_DUNES_ID = UUID(uuidString: "B7C2D1E4-5F63-4A91-9A12-3E8B7F2C4401")!

let AK_CHIN_SOUTHERN_DUNES_PARS: [Int] = [
    4,4,5,3,4,3,5,4,4,
    4,3,4,5,4,4,5,3,4
]

let AK_CHIN_SOUTHERN_DUNES_HCS: [Int] = [
    9,15,1,17,7,13,3,5,11,
    14,18,8,2,12,6,4,16,10
]
let AK_CHIN_SOUTHERN_DUNES_TEES: [TeeInfo] = [

    TeeInfo(
        teeName: "Tips",
        yardage: 7546,
        rating: 76.5,
        slope: 142
    ),

    TeeInfo(
        teeName: "Black",
        yardage: 7330,
        rating: 75.2,
        slope: 138
    ),

    TeeInfo(
        teeName: "Gold",
        yardage: 6902,
        rating: 72.7,
        slope: 132
    ),

    TeeInfo(
        teeName: "Blue",
        yardage: 6493,
        rating: 71.2,
        slope: 129
    ),

    TeeInfo(
        teeName: "White",
        yardage: 5981,
        rating: 68.7,
        slope: 124
    ),

    TeeInfo(
        teeName: "Red",
        yardage: 5055,
        rating: 64.3,
        slope: 105
    )
]
// MARK: - Quintero Golf Club

private let QUINTERO_GC_ID = UUID(uuidString: "9E7C3A21-4B2F-4C6D-8A11-5D9F7B3E2201")!

let QUINTERO_GC_PARS: [Int] = [
    4,5,4,4,4,3,4,5,3,
    5,4,4,3,5,4,3,4,4
]

let QUINTERO_GC_HCS: [Int] = [
    13,7,5,3,11,17,9,1,15,
    10,8,4,18,2,14,16,12,6
]
let QUINTERO_GC_TEES: [TeeInfo] = [

    TeeInfo(
        teeName: "Black",
        yardage: 7153,
        rating: 74.9,
        slope: 146
    ),

    TeeInfo(
        teeName: "Gold",
        yardage: 6800,
        rating: 73.2,
        slope: 140
    ),

    TeeInfo(
        teeName: "Blue",
        yardage: 6450,
        rating: 71.5,
        slope: 136
    ),

    TeeInfo(
        teeName: "White",
        yardage: 6100,
        rating: 69.8,
        slope: 130
    ),

    TeeInfo(
        teeName: "Red",
        yardage: 5400,
        rating: 66.5,
        slope: 120
    )
]
// MARK: - American Dunes Golf Club

private let AMERICAN_DUNES_ID = UUID(uuidString: "C12A6D8E-1F44-4B7D-9E31-2A8C7F5D1001")!

let AMERICAN_DUNES_PARS: [Int] = [
    4,5,4,3,4,5,3,4,4,
    4,4,3,5,4,3,4,4,5
]

let AMERICAN_DUNES_HCS: [Int] = [
    10,18,6,14,2,12,16,4,8,
    3,13,15,11,7,9,1,5,17
]

let AMERICAN_DUNES_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Jet",
        yardage: 7213,
        rating: 75.4,
        slope: 148
    ),
    TeeInfo(
        teeName: "Valor",
        yardage: 6701,
        rating: 73.0,
        slope: 142
    ),
    TeeInfo(
        teeName: "Freedom",
        yardage: 6131,
        rating: 70.3,
        slope: 133
    ),
    TeeInfo(
        teeName: "Honor",
        yardage: 5573,
        rating: 67.8,
        slope: 126
    ),
    TeeInfo(
        teeName: "Bear",
        yardage: 4772,
        rating: 63.9,
        slope: 116
    )
]
private let GOLDEN_HORSESHOE_GOLD_ID = UUID(uuidString: "D34B7E90-2C51-4C98-8B42-3D9E8A6F2002")!

let GOLDEN_HORSESHOE_GOLD_PARS: [Int] = [
    4,5,3,4,4,5,3,4,4,
    4,4,3,4,4,5,3,4,4
]

let GOLDEN_HORSESHOE_GOLD_HCS: [Int] = [
    11,3,9,1,15,5,7,17,13,
    8,14,12,18,2,10,16,4,6
]

let GOLDEN_HORSESHOE_GOLD_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Gold",
        yardage: 6817,
        rating: 73.4,
        slope: 140
    ),
    TeeInfo(
        teeName: "Blue",
        yardage: 6522,
        rating: 72.1,
        slope: 136
    ),
    TeeInfo(
        teeName: "White",
        yardage: 6248,
        rating: 70.8,
        slope: 134
    ),
    TeeInfo(
        teeName: "Silver",
        yardage: 5504,
        rating: 67.4,
        slope: 128
    ),
    TeeInfo(
        teeName: "Red",
        yardage: 4599,
        rating: 63.0,
        slope: 114
    )
]
private let POLO_FIELDS_ANN_ARBOR_ID = UUID(uuidString: "E56C8FA1-3D62-4DA9-9C53-4E0F9B7A3003")!

let POLO_FIELDS_ANN_ARBOR_PARS: [Int] = [
    5,4,3,4,4,4,4,5,3,
    4,5,3,4,3,4,5,4,4
]

let POLO_FIELDS_ANN_ARBOR_HCS: [Int] = [
    13,1,9,11,5,3,7,15,17,
    18,8,16,4,12,2,10,6,14
]

let POLO_FIELDS_ANN_ARBOR_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Black",
        yardage: 6705,
        rating: 73.3,
        slope: 146
    )
]
private let LAWSONIA_LINKS_ID = UUID(uuidString: "F71D9A22-4E83-4F9A-8D21-5C1E9A8B4004")!

let LAWSONIA_LINKS_PARS: [Int] = [
    4,4,4,3,5,4,3,4,5,
    3,5,3,5,3,4,4,4,5
]

let LAWSONIA_LINKS_HCS: [Int] = [
    8,14,10,18,6,4,16,12,2,
    15,7,13,1,17,9,5,11,3
]

let LAWSONIA_LINKS_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Blue",
        yardage: 6853,
        rating: 73.0,
        slope: 130
    ),
    TeeInfo(
        teeName: "White",
        yardage: 6494,
        rating: 71.5,
        slope: 128
    ),
    TeeInfo(
        teeName: "Gold",
        yardage: 5889,
        rating: 68.8,
        slope: 124
    ),
    TeeInfo(
        teeName: "Red",
        yardage: 5078,
        rating: 65.2,
        slope: 115
    )
]
private let PAAKO_RIDGE_1_18_ID = UUID(uuidString: "A82E1B33-5F94-4B2C-9F32-6D2F0B9C5005")!
private let PAAKO_RIDGE_10_27_ID = UUID(uuidString: "A82E1B33-5F94-4B2C-9F32-6D2F0B9C5006")!
private let PAAKO_RIDGE_1_9_19_27_ID = UUID(uuidString: "A82E1B33-5F94-4B2C-9F32-6D2F0B9C5007")!

let PAAKO_RIDGE_1_18_PARS: [Int] = [
    4,4,5,3,5,4,4,3,4,
    4,4,5,4,3,5,3,4,4
]

let PAAKO_RIDGE_1_18_HCS: [Int] = [
    13,11,5,17,7,15,1,9,3,
    10,2,14,16,8,4,18,12,6
]
let PAAKO_RIDGE_10_27_PARS: [Int] = [
    4,4,5,4,3,5,3,4,4,
    5,4,4,3,5,3,5,3,4
]

let PAAKO_RIDGE_10_27_HCS: [Int] = [
    10,2,14,16,8,4,18,12,6,
    5,7,2,8,1,9,3,6,4
]
private let PAAKO_RIDGE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7562, rating: 75.7, slope: 150),
    TeeInfo(teeName: "Blue", yardage: 7218, rating: 74.0, slope: 145),
    TeeInfo(teeName: "Green", yardage: 6727, rating: 71.8, slope: 139),
    TeeInfo(teeName: "Brown", yardage: 6265, rating: 69.6, slope: 134),
    TeeInfo(teeName: "Gray", yardage: 5755, rating: 67.0, slope: 126),
    TeeInfo(teeName: "Turquoise", yardage: 4776, rating: 64.7, slope: 115)

]
// MARK: - Trinity Forest GC (Plates)

private let TRINITY_FOREST_ID = UUID(uuidString: "C3E8A6F1-9D55-4B77-8A33-100000000503")!

let TRINITY_FOREST_PARS: [Int] = [
    4,5,3,4,5,4,4,3,4,   // Front 9 = 36
    5,3,4,4,4,5,3,4,4    // Back 9 = 36
]

let TRINITY_FOREST_HCS: [Int] = [
    11,7,17,1,3,9,13,15,5,
    10,14,12,4,16,8,6,18,2
]

let TRINITY_FOREST_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Plates", yardage: 7617, rating: 76.0, slope: 134),
    TeeInfo(teeName: "Blue",   yardage: 7109, rating: 74.8, slope: 132),
    TeeInfo(teeName: "White",  yardage: 6576, rating: 71.8, slope: 129),
    TeeInfo(teeName: "Red",    yardage: 5902, rating: 75.3, slope: 133) // women's rating
]
private let AUSTIN_CC_ID = UUID(uuidString: "C3A7F1D2-7B22-4E11-8C11-100000000303")!

let AUSTIN_CC_PARS: [Int] = [
    4,3,5,4,4,4,5,3,4,
    4,4,4,3,4,5,3,5,4
]

let AUSTIN_CC_HCS: [Int] = [
    9,11,5,13,1,7,3,17,15,
    12,2,8,18,16,4,14,10,6
]
let AUSTIN_CC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Harvey", yardage: 7062, rating: 74.7, slope: 150)
    ]
// MARK: - Colonial Country Club

private let COLONIAL_CC_ID = UUID(uuidString: "B2D7C5E3-8F42-4A99-9B22-100000000502")!

let COLONIAL_CC_PARS: [Int] = [
    5,4,4,3,4,4,4,3,4,
    4,5,4,3,4,4,3,4,4
]

let COLONIAL_CC_HCS: [Int] = [
    9,17,5,15,1,13,3,11,7,
    16,8,4,14,10,2,18,6,12
]

let COLONIAL_CC_TEES: [TeeInfo] = [
    TeeInfo(
        teeName: "Championship",
        yardage: 7289,
        rating: 76.5,
        slope: 137
    )
]
private let DALLAS_NATIONAL_ID = UUID(uuidString: "B2E4D7A1-6C31-4F22-8C11-100000000302")!

let DALLAS_NATIONAL_PARS: [Int] = [
    4,5,3,5,3,4,4,4,4,
    5,4,4,3,4,4,4,3,5
]

let DALLAS_NATIONAL_HCS: [Int] = [
    16,4,18,2,10,6,14,8,12,
    3,11,9,17,15,5,1,13,7
]

let DALLAS_NATIONAL_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Texas", yardage: 7372, rating: 75.9, slope: 145),
    TeeInfo(teeName: "I",     yardage: 6862, rating: 73.5, slope: 140),
    TeeInfo(teeName: "II",    yardage: 6514, rating: 71.6, slope: 133),
    TeeInfo(teeName: "III",   yardage: 6045, rating: 69.3, slope: 129)
]
private let WHISPERING_PINES_ID = UUID(uuidString: "D4B8E2F3-8A11-4C22-8C11-100000000304")!

let WHISPERING_PINES_PARS: [Int] = [
    4,5,3,4,5,4,4,3,4,
    4,4,5,4,4,3,3,5,4
]

let WHISPERING_PINES_HCS: [Int] = [
    17,5,15,3,7,9,1,13,11,
    14,6,18,4,16,10,12,8,2
]

let WHISPERING_PINES_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Spirit", yardage: 7468, rating: 77.0, slope: 150),
    TeeInfo(teeName: "I",      yardage: 6842, rating: 74.1, slope: 145),
    TeeInfo(teeName: "II",     yardage: 6420, rating: 71.7, slope: 139),
    TeeInfo(teeName: "III",    yardage: 5876, rating: 69.5, slope: 134),
    TeeInfo(teeName: "IV",     yardage: 4996, rating: 65.5, slope: 126)
]
private let BLUEJACK_NATIONAL_ID = UUID(uuidString: "E5C9F3A4-9D11-4D22-8C11-100000000305")!

let BLUEJACK_NATIONAL_PARS: [Int] = [
    4,5,3,4,5,4,3,4,4,
    4,5,3,5,4,3,4,4,4
]

let BLUEJACK_NATIONAL_HCS: [Int] = [
    9,11,15,5,7,3,17,13,1,
    10,6,16,8,12,18,4,14,2
]

let BLUEJACK_NATIONAL_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Tiger", yardage: 7552, rating: 75.8, slope: 135)
]

// MARK: - Valhalla Golf Club (Gold / Championship)

private let VALHALLA_GOLD_ID = UUID(uuidString: "9E7C1F42-8A6D-4F91-B2A1-6D9C3E5F7201")!

let VALHALLA_GOLD_PARS: [Int] = [
    4,5,3,4,4,4,5,3,4,
    5,3,4,4,3,4,4,4,5
]

let VALHALLA_GOLD_HCS: [Int] = [
    13,9,11,15,3,1,5,17,7,
    6,16,2,14,18,10,4,8,12
]

let VALHALLA_GOLD_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Gold", yardage: 7575, rating: 78.5, slope: 155)
]
// MARK: - Audubon Country Club (Cardinal)

private let AUDUBON_CARDINAL_ID = UUID(uuidString: "C1A9D2E4-5F6B-4A91-8C3D-9E7B2F4D6102")!

let AUDUBON_CARDINAL_PARS: [Int] = [
    4,4,3,5,3,4,5,4,4,
    4,4,5,3,4,5,4,3,4
]

let AUDUBON_CARDINAL_HCS: [Int] = [
    5,11,15,1,17,13,3,7,9,
    10,12,2,18,8,4,6,16,14
]

let AUDUBON_CARDINAL_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Cardinal", yardage: 6843, rating: 74.1, slope: 134)
]
// MARK: - Dothan Country Club

private let DOTHAN_COUNTRY_CLUB_ID = UUID(uuidString: "D8B3C1A4-5E72-4F69-9C10-2A7E4D5F8301")!

let DOTHAN_COUNTRY_CLUB_PARS: [Int] = [
    4,4,3,5,3,4,4,4,4,
    5,3,4,3,4,4,4,4,4
]

let DOTHAN_COUNTRY_CLUB_HCS: [Int] = [
    15,7,13,1,17,5,3,9,11,
    2,18,10,14,4,12,6,16,8
]

let DOTHAN_COUNTRY_CLUB_TEES: [TeeInfo] = [
    TeeInfo(teeName: "1", yardage: 6479, rating: 71.4, slope: 130)
]
// =======================================================
// MARK: - Built-in Registry
// =======================================================

private enum BuiltIns {

    private struct BuiltInCourse {
        let id: UUID
        let name: String
        let pars: [Int]
        let hcs: [Int]
        let tees: [TeeInfo]?
        let country: String?
        let state: String?
        let region: String?          // ✅ ADD
        let architect: String?
        let type: String?
        let phone: String?
        let website: String?
        let address: String?
        let isWolfApproved: Bool?
        let venueType: VenueType?    // ✅ ADD (not String)
        let resortBrand: String?
        let promo: LocationPromo?    // ✅ ADD (not String)
        let routing: CourseRouting
        
    }

    private static func c(
        _ id: UUID,
        _ name: String,
        _ pars: [Int],
        _ hcs: [Int],
        _ tees: [TeeInfo]? = nil,
        country: String? = nil,
        state: String? = nil,
        region: String? = nil,
        architect: String? = nil,
        type: String? = nil,
        phone: String? = nil,
        website: String? = nil,
        address: String? = nil,
        isWolfApproved: Bool? = nil,
        venueType: VenueType? = nil,
        resortBrand: String? = nil,
        promo: LocationPromo? = nil,
        routing: CourseRouting = .eighteenStandard   // 👈 ADD
    ) -> BuiltInCourse {
        .init(
            id: id,
            name: name,
            pars: pars,
            hcs: hcs,
            tees: tees,
            country: country,
            state: state,
            region: region,
            architect: architect,
            type: type,
            phone: phone,
            website: website,
            address: address,
            isWolfApproved: isWolfApproved,
            venueType: venueType,
            resortBrand: resortBrand,
            promo: promo,
            routing: routing   // 👈 ADD
        )
    }
    private static func profile(from b: BuiltInCourse) -> CourseProfile {
        return CourseProfile(
            id: b.id,
            name: b.name,
            pars: b.pars,
            hcs: b.hcs,
            tees: b.tees,
            country: b.country,
            state: b.state,
            region: b.region,
            architect: b.architect,
            type: b.type,
            phone: b.phone,
            website: b.website,
            address: b.address,
            isWolfApproved: b.isWolfApproved,
            venueType: b.venueType,
            resortBrand: b.resortBrand,
            promo: b.promo,
            routing: b.routing   // 👈 ADD THIS
        )
    }
    private static let all: [BuiltInCourse] = [

        // -------------------------
        // Default
        // -------------------------
        c(WOLFMORE_CC_ID, "WolfMore", WOLFMORE_PARS, WOLFMORE_HCS,
          country: "USA", state: "IL"),

        // -------------------------
        // Illinois / Midwest
        // -------------------------
        
        c(
            WJ_ARBORETUM_ID,
            "WJ Golf at Arboretum Golf Club",
            EMPTY_PARS,
            EMPTY_HCS,
            nil,
            country: "USA",
            state: "IL",
            region: "Indoor",
            type: "Indoor Golf",
            phone: "(224) 676-0692",
            website: "https://www.wj.golf/location",
            address: "401 W Half Day Rd, Buffalo Grove, IL",
            isWolfApproved: true,
            venueType: .indoorGolf,
            resortBrand: "WJ Golf",
            promo: LocationPromo(
                type: .deal,
                title: "Weekday Special",
                subtitle: "Mon–Thur before 5PM",
                isActive: false
            )
        ),
        c(
            BILTMORE_CC_ID,
            "Biltmore Country Club",
            BILTMORE_CC_PARS,
            BILTMORE_CC_HCS,
            BILTMORE_CC_TEES,
            country: "USA",
            state: "IL",
            type: "Private",
            phone: "(847) 381-1960",
            website: "https://www.biltmore-cc.com",
            address: "160 Biltmore Drive, North Barrington, IL 60010",
            isWolfApproved: true
        ),
        c(
            CEDAR_RAPIDS_CC_ID,
            "Cedar Rapids Country Club",
            CEDAR_RAPIDS_PARS,
            CEDAR_RAPIDS_HCS,
            country: "USA",
            state: "IA",
            architect: "Donald Ross",
            type: "Private",
            phone: "(319) 363-9673",
            website: "https://www.cedarrapidscc.com",
            address: "550 27th St Dr SE, Cedar Rapids, IA 52403",
            isWolfApproved: false
        ),

        c(WYNSTONE_SILVER_ID, "Wynstone", WYNSTONE_SILVER_PARS, WYNSTONE_SILVER_HCS,
          country: "USA",
          state: "IL",
          type: "Private",
          phone: "(847) 304-2800",
          website: "https://www.wynstone.org",
          address: "1 South Wynstone Drive, North Barrington, IL 60010"),

        c(BARRINGTON_HILLS_WHITE_ID, "Barrington Hills", BARRINGTON_HILLS_WHITE_PARS, BARRINGTON_HILLS_WHITE_HCS,
          country: "USA",
          state: "IL",
          type: "Private",
          phone: "(847) 381-4200",
          website: "https://www.barringtonhillscc.com",
          address: "300 W. County Line Road, Barrington Hills, IL 60010"),

        c(CRANES_LANDING_BLUE_ID, "Crane's Landing", CRANES_LANDING_BLUE_PARS, CRANES_LANDING_BLUE_HCS,
          country: "USA",
          state: "IL",
          type: "Resort",
          phone: "(847) 634-5935",
          website: "https://www.craneslandinggolf.com",
          address: "10 Marriott Drive, Lincolnshire, IL 60069"),

        c(STONEWALL_ORCHARD_SILVER_ID, "Stonewall Orchard", STONEWALL_ORCHARD_SILVER_PARS, STONEWALL_ORCHARD_SILVER_HCS,
          country: "USA",
          state: "IL",
          architect: "Arthur Hills",
          type: "Daily-Fee",
          phone: "(847) 740-4890",
          website: "https://www.stonewallorchard.com",
          address: "25675 W IL Highway 60, Grayslake, IL 60030"),

        c(KEMPER_LAKES_GREEN_ID, "Kemper Lakes", KEMPER_LAKES_GREEN_PARS, KEMPER_LAKES_GREEN_HCS,
          country: "USA",
          state: "IL",
          type: "Private",
          phone: "(847) 320-3450",
          website: "https://www.kemperlakesgolf.com",
          address: "24000 N. Old McHenry Road, Kildeer, IL 60047"),

        c(RICH_HARVEST_SILVER_ID, "Rich Harvest Farms", RICH_HARVEST_SILVER_PARS, RICH_HARVEST_SILVER_HCS,
          country: "USA",
          state: "IL",
          type: "Private",
          phone: "(630) 466-7610",
          website: "https://www.richharvestfarms.com",
          address: "7S771 Dugan Road, Sugar Grove, IL 60554"),


        c(BUTLER_NATIONAL_BUTLER_TEE_ID, "Butler National (7,550-yard)", BUTLER_NATIONAL_BUTLER_TEE_PARS, BUTLER_NATIONAL_BUTLER_TEE_HCS, BUTLER_NATIONAL_BUTLER_TEE_TEES,
          country: "USA",
          state: "IL",
          type: "Private",
          phone: "(630) 990-3333",
          website: "https://www.butlernational.org",
          address: "2616 S York Road, Oak Brook, IL 60523"),

        c(
            MEDINAH_CC_3_ID,
            "Medinah CC (Course #3)",
            MEDINAH_CC_3_PARS,
            MEDINAH_CC_3_HCS,
            MEDINAH_CC_3_TEES,
            country: "USA",
            state: "IL",
            region: nil,
            architect: nil,
            type: "Private",
            phone: "(630) 773-1700",
            website: "https://www.medinahcc.org",
            address: "6N001 Medinah Road, Medinah, IL 60157",
            isWolfApproved: true,
            resortBrand: nil,
            promo: nil
        ),

        c(
            MEDINAH_CC_2_ID,
            "Medinah CC (Course #2)",
            MEDINAH_CC_2_PARS,
            MEDINAH_CC_2_HCS,
            MEDINAH_CC_2_TEES,
            country: "USA",
            state: "IL",
            region: nil,
            architect: nil,
            type: "Private",
            phone: "(630) 773-1700",
            website: "https://www.medinahcc.org",
            address: "6N001 Medinah Road, Medinah, IL 60157",
            isWolfApproved: true,
            resortBrand: nil,
            promo: nil
        ),

        c(
            MEDINAH_CC_1_ID,
            "Medinah CC (Course #1)",
            MEDINAH_CC_1_PARS,
            MEDINAH_CC_1_HCS,
            MEDINAH_CC_1_TEES,
            country: "USA",
            state: "IL",
            region: nil,
            architect: "Tom Bendelow",
            type: "Private",
            phone: "(630) 773-1700",
            website: "https://www.medinahcc.org",
            address: "6N001 Medinah Road, Medinah, IL 60157",
            isWolfApproved: true,
            resortBrand: nil,
            promo: nil
        ),
        
        c(MAKRAY_MEMORIAL_BLACK_ID, "Makray Memorial (Black)", MAKRAY_MEMORIAL_BLACK_PARS, MAKRAY_MEMORIAL_BLACK_HCS, MAKRAY_MEMORIAL_BLACK_TEES,
          country: "USA",
          state: "IL",
          type: "Daily-Fee",
          phone: "(847) 381-6500",
          website: "https://www.makraygolf.com",
          address: "1010 S. Northwest Highway, Barrington, IL 60010"),

        c(LAKE_BARRINGTON_SHORES_BLACK_ID, "Lake Barrington Shores (Black)", LAKE_BARRINGTON_SHORES_BLACK_PARS, LAKE_BARRINGTON_SHORES_BLACK_HCS, LAKE_BARRINGTON_SHORES_BLACK_TEES,
          country: "USA",
          state: "IL",
          type: "Private",
          phone: "(847) 382-4240",
          website: "https://www.golflakebarrington.com",
          address: "40 Shoreline Road, Lake Barrington, IL 60010"),

        c(FOXFORD_HILLS_BLACK_ID, "Foxford Hills (Black)", FOXFORD_HILLS_BLACK_PARS, FOXFORD_HILLS_BLACK_HCS, FOXFORD_HILLS_BLACK_TEES,
          country: "USA",
          state: "IL",
          type: "Daily-Fee",
          phone: "(847) 639-0400",
          website: "https://www.foxfordhillsgolfclub.com",
          address: "6800 S. Rawson Bridge Road, Cary, IL 60013"),

        c(CARY_CC_BLUE_ID, "Cary CC (Blue)", CARY_CC_BLUE_PARS, CARY_CC_BLUE_HCS, CARY_CC_BLUE_TEES,
          country: "USA",
          state: "IL",
          type: "Private",
          phone: "(847) 639-3161",
          website: "https://www.carycountryclub.com",
          address: "2400 Grove Lane, Cary, IL 60013"),

        c(CHALET_HILLS_BLACK_ID, "Chalet Hills (Black)", CHALET_HILLS_BLACK_PARS, CHALET_HILLS_BLACK_HCS, CHALET_HILLS_BLACK_TEES,
          country: "USA",
          state: "IL",
          type: "Daily-Fee",
          phone: "(847) 639-0666",
          website: "https://www.chalethillsgolfclub.com",
          address: "943 Rawson Bridge Road, Cary, IL 60013"),

        c(TPC_DEERE_RUN_TPC_ID, "TPC Deere Run (TPC)", TPC_DEERE_RUN_TPC_PARS, TPC_DEERE_RUN_TPC_HCS, TPC_DEERE_RUN_TPC_TEES,
          country: "USA",
          state: "IL",
          type: "Daily-Fee",
          phone: "(309) 796-6000",
          website: "https://tpc.com/deererun/",
          address: "3100 Heather Knoll, Silvis, IL 61282"),
        // -------------------------
        // Iowa
        // -------------------------
        c(HARVESTER_GC_BLACK_ID, "The Harvester GC (Black)", HARVESTER_GC_BLACK_PARS, HARVESTER_GC_BLACK_HCS, HARVESTER_GC_BLACK_TEES,
          country: "USA",
          state: "IA",
          architect: "Keith Foster",
          type: "Private",
          phone: "(515) 986-4653",
          website: "https://www.theharvestergolfclub.com",
          address: "833 Foster Drive, Rhodes, IA 50234"),
        c(DAVENPORT_CC_BLACK_ID, "Davenport CC (Black)", DAVENPORT_CC_BLACK_PARS, DAVENPORT_CC_BLACK_HCS, DAVENPORT_CC_BLACK_TEES,
          country: "USA",
          state: "IA",
          architect: "H.S. Colt / Donald Ross influence",
          type: "Private",
          phone: "(563) 322-3000",
          website: "https://www.davenportcc.com",
          address: "25500 Valley Drive, Pleasant Valley, IA 52767"),

        // -------------------------
        // Florida
        // -------------------------
        c(CHAMPIONGATE_BLENDED_BLACK_ID, "Champions Gate", CHAMPIONGATE_BLENDED_BLACK_PARS, CHAMPIONGATE_BLENDED_BLACK_HCS,
          country: "USA",
          state: "FL",
          architect: "Greg Norman",
          type: "Resort",
          phone: "(407) 787-4653",
          website: "https://www.championsgategolf.com",
          address: "8575 White Shark Blvd, ChampionsGate, FL 33896"),
        
        c(
            TPC_SAWGRASS_STADIUM_ID,
            "TPC Sawgrass (Stadium)",
            TPC_SAWGRASS_STADIUM_PARS,
            TPC_SAWGRASS_STADIUM_HCS,
            TPC_SAWGRASS_STADIUM_TEES,
            country: "USA",
            state: "FL",
            architect: "Pete Dye",
            type: "Daily-Fee",
            phone: "(904) 273-3235",
            website: "https://tpc.com/sawgrass/",
            address: "110 Championship Way, Ponte Vedra Beach, FL 32082",
            isWolfApproved: true,
            resortBrand: "TPC",
            promo: nil
        ),
 
        c(
            TPC_SAWGRASS_DYES_VALLEY_ID,
            "TPC Sawgrass (Dye’s Valley)",
            TPC_SAWGRASS_DYES_VALLEY_PARS,
            TPC_SAWGRASS_DYES_VALLEY_HCS,
            TPC_SAWGRASS_DYES_VALLEY_TEES,
            country: "USA",
            state: "FL",
            architect: "Pete Dye & Bobby Weed",
            type: "Daily-Fee",
            phone: "(904) 273-3235",
            website: "https://tpc.com/sawgrass/",
            address: "110 Championship Way, Ponte Vedra Beach, FL 32082",
            isWolfApproved: true,
            resortBrand: "TPC",
            promo: nil
        ),
        c(BAY_HILL_CHALLENGER_CHAMPION_ID, "Bay Hill (Challenger/Champion)", BAY_HILL_CHALLENGER_CHAMPION_PARS, BAY_HILL_CHALLENGER_CHAMPION_HCS, BAY_HILL_CHALLENGER_CHAMPION_TEES,
          country: "USA",
          state: "FL",
          architect: "Dick Wilson / Arnold Palmer redesign",
          type: "Private",
          phone: "(407) 876-2429",
          website: "https://www.bayhill.com",
          address: "9000 Bay Hill Blvd, Orlando, FL 32819"),
        c(PGA_NATIONAL_CHAMPION_BEAR_ID, "PGA National (Champion – Bear)", PGA_NATIONAL_CHAMPION_BEAR_PARS, PGA_NATIONAL_CHAMPION_BEAR_HCS, PGA_NATIONAL_CHAMPION_BEAR_TEES,
          country: "USA",
          state: "FL",
          architect: "Tom Fazio / Jack Nicklaus redesign",
          type: "Resort",
          phone: "(561) 627-1800",
          website: "https://www.pgaresort.com",
          address: "400 Avenue of the Champions, Palm Beach Gardens, FL 33418"),
        c(PANTHER_NATIONAL_JT_ID, "Panther National (JT)", PANTHER_NATIONAL_JT_PARS, PANTHER_NATIONAL_JT_HCS, PANTHER_NATIONAL_JT_TEES,
          country: "USA",
          state: "FL",
          architect: "Jack Nicklaus / Justin Thomas",
          type: "Private",
          phone: "(561) 440-1000",
          website: "https://panthernational.com",
          address: "11880 Panther Parkway, Palm Beach Gardens, FL 33412"),
        c(BEARS_CLUB_CHAMPION_ID, "The Bear's Club (7212 yds)", BEARS_CLUB_CHAMPION_PARS, BEARS_CLUB_CHAMPION_HCS, BEARS_CLUB_CHAMPION_TEES,
          country: "USA",
          state: "FL",
          architect: "Jack Nicklaus",
          type: "Private",
          phone: "(561) 626-2327",
          website: "https://www.thebearsclub.com",
          address: "250 Bears Club Drive, Jupiter, FL 33477"),
        c(STREAMSONG_BLUE_ID, "Streamsong (Blue)", STREAMSONG_BLUE_PARS, STREAMSONG_BLUE_HCS,
          country: "USA",
          state: "FL",
          architect: "Tom Doak",
          type: "Resort",
          phone: "(863) 428-1000",
          website: "https://www.streamsongresort.com",
          address: "1000 Streamsong Drive, Bowling Green, FL 33834"),
        c(STREAMSONG_RED_ID, "Streamsong (Red)", STREAMSONG_RED_PARS, STREAMSONG_RED_HCS,
          country: "USA",
          state: "FL",
          architect: "Tom Doak",
          type: "Resort",
          phone: "(863) 428-1000",
          website: "https://www.streamsongresort.com",
          address: "1000 Streamsong Drive, Bowling Green, FL 33834"),
        c(STREAMSONG_BLACK_ID, "Streamsong (Black)", STREAMSONG_BLACK_PARS, STREAMSONG_BLACK_HCS,
          country: "USA",
          state: "FL",
          architect: "Tom Doak",
          type: "Resort",
          phone: "(863) 428-1000",
          website: "https://www.streamsongresort.com",
          address: "1000 Streamsong Drive, Bowling Green, FL 33834"),
        c(PGA_VILLAGE_WANAMAKER_ID, "PGA Village (Wanamaker)", PGA_VILLAGE_WANAMAKER_PARS, PGA_VILLAGE_WANAMAKER_HCS,
          country: "USA",
          state: "FL",
          architect: "Tom Fazio",
          type: "Resort",
          phone: "(772) 467-1300",
          website: "https://www.pgavillage.com",
          address: "1916 Perfect Drive, Port St. Lucie, FL 34986"),
        c(PGA_VILLAGE_RYDER_ID, "PGA Village (Ryder)", PGA_VILLAGE_RYDER_PARS, PGA_VILLAGE_RYDER_HCS,
          country: "USA",
          state: "FL",
          architect: "Tom Fazio",
          type: "Resort",
          phone: "(772) 467-1300",
          website: "https://www.pgavillage.com",
          address: "1916 Perfect Drive, Port St. Lucie, FL 34986"),
      
        c(PGA_VILLAGE_DYE_ID, "PGA Village (Dye)",
          PGA_VILLAGE_DYE_PARS, PGA_VILLAGE_DYE_HCS,
          country: "USA",
          state: "FL",
          architect: "Pete Dye",
          type: "Resort",
          phone: "(772) 467-1300",
          website: "https://www.pgavillage.com",
          address: "1916 Perfect Drive, Port St. Lucie, FL 34986"),
       
        c(MEDALIST_JT_ID, "Medalist GC ",
          MEDALIST_JT_PARS, MEDALIST_JT_HCS,
          country: "USA",
          state: "FL",
          architect: "Pete Dye and Greg Norman",
          type: "Private",
          phone: "((772) 545-9600",
          website: "https://www.medalistgolfclub.org",
          address: "9908 SE Cottage Lane, Hobe Sound, FL 33455"),
        
        c(DYE_PRESERVE_CHAMPIONSHIP_ID, "Dye Preserve (Championship)", DYE_PRESERVE_CHAMPIONSHIP_PARS, DYE_PRESERVE_CHAMPIONSHIP_HCS, DYE_PRESERVE_CHAMPIONSHIP_TEES,
          country: "USA",
          state: "FL",
          architect: "Pete Dye",
          type: "Private",
          phone: "(561) 575-7011",
          website: "https://www.dyepreserve.com",
          address: "1800 SE Bridge Road, Jupiter, FL 33469"),
        
        c(SEMINOLE_GOLD_ID, "Seminole (Gold)", SEMINOLE_GOLD_PARS, SEMINOLE_GOLD_HCS, SEMINOLE_GOLD_TEES,
          country: "USA",
          state: "FL",
          architect: "Donald Ross,Ren:Gil Hanse/Jim Wagner.",
          type: "Private",
          phone: "(561) 626-0280",
          website: "https://www.seminolegolfclub.com",
          address: "901 Seminole Boulevard, Juno Beach, FL 33408"),
        
        c(CALUSA_PINES_ID, "Calusa Pines (Gold)", CALUSA_PINES_GOLD_PARS, CALUSA_PINES_GOLD_HCS,
          country: "USA", state: "FL",
          phone: "(239) 352-2200",
          website: "https://www.calusapinesgolfclub.com",
          address: "2000 Calusa Pines Drive, Naples, FL 34120"),
      
        c(KAROO_ID, "Karoo (Black)", KAROO_BLACK_PARS, KAROO_BLACK_HCS_TODO,
          country: "USA", state: "FL",
          phone: "(239) 352-2200",
          website: "https://www.calusapinesgolfclub.com",
          address: "2000 Calusa Pines Drive, Naples, FL 34120"),

        // -------------------------
        // Wisconsin
        // -------------------------
        c(WHISTLING_STRAITS_STRAITS_ID, "Whistling Straits (Straits)", WHISTLING_STRAITS_STRAITS_PARS, WHISTLING_STRAITS_STRAITS_HCS, WHISTLING_STRAITS_STRAITS_TEES,
          country: "USA",
          state: "WI",
          architect: "Pete Dye",
          type: "Resort",
          phone: "(920) 565-6000",
          website: "https://www.americanclubresort.com/golf/whistling-straits",
          address: "N8501 Lakeshore Rd, Sheboygan, WI 53083"),
        
        c(WHISTLING_STRAITS_IRISH_ID, "Whistling Straits (Irish)", WHISTLING_STRAITS_IRISH_PARS, WHISTLING_STRAITS_IRISH_HCS,
          country: "USA",
          state: "WI",
          architect: "Pete Dye",
          type: "Resort",
          phone: "(920) 565-6000",
          website: "https://www.americanclubresort.com/golf/whistling-straits",
          address: "N8501 Lakeshore Rd, Sheboygan, WI 53083"),
        
        c(BLACKWOLF_RUN_RIVER_ID, "Blackwolf Run (River)", BLACKWOLF_RUN_RIVER_PARS, BLACKWOLF_RUN_RIVER_HCS,
          country: "USA",
          state: "WI",
          architect: "Pete Dye",
          type: "Resort",
          phone: "(920) 457-4441",
          website: "https://www.americanclubresort.com/golf/blackwolf-run",
          address: "1111 W Riverside Dr, Kohler, WI 53044"),
        
        c(BLACKWOLF_RUN_MEADOW_VALLEYS_ID, "Blackwolf Run (Meadow Valleys)", BLACKWOLF_RUN_MEADOW_VALLEYS_PARS, BLACKWOLF_RUN_MEADOW_VALLEYS_HCS,
          country: "USA",
          state: "WI",
          architect: "Pete Dye",
          type: "Resort",
          phone: "(920) 457-4441",
          website: "https://www.americanclubresort.com/golf/blackwolf-run",
          address: "1111 W Riverside Dr, Kohler, WI 53044"),
        
        c(SAND_VALLEY_ID, "Sand Valley", SAND_VALLEY_PARS, SAND_VALLEY_HCS,
          country: "USA",
          state: "WI",
          architect: "Coore & Crenshaw",
          type: "Resort",
          phone: "(888) 651-5539",
          website: "https://www.sandvalley.com",
          address: "1697 Leopold Way, Nekoosa, WI 54457"),
        
        c(MAMMOTH_DUNES_ID, "Mammoth Dunes", MAMMOTH_DUNES_PARS, MAMMOTH_DUNES_HCS,
          country: "USA",
          state: "WI",
          architect: "David McLay Kidd",
          type: "Resort",
          phone: "(888) 651-5539",
          website: "https://www.sandvalley.com",
          address: "1697 Leopold Way, Nekoosa, WI 54457"),
        
        c(GENEVA_NATIONAL_PALMER_ID, "Geneva National – Palmer", GENEVA_NATIONAL_PALMER_PARS, GENEVA_NATIONAL_PALMER_HCS,
          country: "USA",
          state: "WI",
          architect: "Arnold Palmer",
          type: "Resort",
          phone: "(262) 245-7000",
          website: "https://www.genevanationalresort.com",
          address: "1221 Geneva National Ave S, Lake Geneva, WI 53147"),
        c(GENEVA_NATIONAL_TREVINO_ID, "Geneva National – Trevino", GENEVA_NATIONAL_TREVINO_PARS, GENEVA_NATIONAL_TREVINO_HCS,
          country: "USA",
          state: "WI",
          architect: "Lee Trevino",
          type: "Resort",
          phone: "(262) 245-7000",
          website: "https://www.genevanationalresort.com",
          address: "1221 Geneva National Ave S, Lake Geneva, WI 53147"),
        c(GENEVA_NATIONAL_PLAYER_ID, "Geneva National – Player", GENEVA_NATIONAL_PLAYER_PARS, GENEVA_NATIONAL_PLAYER_HCS,
          country: "USA",
          state: "WI",
          architect: "Gary Player",
          type: "Resort",
          phone: "(262) 245-7000",
          website: "https://www.genevanationalresort.com",
          address: "1221 Geneva National Ave S, Lake Geneva, WI 53147"),
        c(GRAND_GENEVA_HIGHLANDS_ID, "Grand Geneva – The Highlands", GRAND_GENEVA_HIGHLANDS_PARS, GRAND_GENEVA_HIGHLANDS_HCS,
          country: "USA",
          state: "WI",
          architect: "Pete Dye",
          type: "Resort",
          phone: "(262) 248-8811",
          website: "https://www.grandgeneva.com",
          address: "7036 Grand Geneva Way, Lake Geneva, WI 53147"),
        c(GRAND_GENEVA_BRUTE_ID, "Grand Geneva – The Brute", GRAND_GENEVA_BRUTE_PARS, GRAND_GENEVA_BRUTE_HCS,
          country: "USA",
          state: "WI",
          architect: "Robert Bruce Harris",
          type: "Resort",
          phone: "(262) 248-8811",
          website: "https://www.grandgeneva.com",
          address: "7036 Grand Geneva Way, Lake Geneva, WI 53147"),
        c(ERIN_HILLS_ID, "Erin Hills (Black)", ERIN_HILLS_BLACK_PARS, ERIN_HILLS_BLACK_HCS,
          country: "USA",
          state: "WI",
          architect: "Dr. Michael Hurdzan / Dana Fry / Ron Whitten",
          type: "Daily-Fee",
          phone: "(866) 772-4769",
          website: "https://www.erinhills.com",
          address: "7169 County Road O, Erin, WI 53027"),
        c(SAND_VALLEY_LIDO_ID, "Sand Valley (Lido)", SAND_VALLEY_LIDO_PARS_TODO, SAND_VALLEY_LIDO_HCS_TODO,
          country: "USA",
          state: "WI",
          architect: "C.B. Macdonald / Seth Raynor / Tom Doak / Brian Schneider",
          type: "Resort",
          phone: "(888) 651-5539",
          website: "https://www.sandvalley.com",
          address: "1697 Leopold Way, Nekoosa, WI 54457"),
        
        c(SAND_VALLEY_SEDGE_VALLEY_CHAMPIONSHIP_ID, "Sand Valley (Sedge Valley — Championship)", SAND_VALLEY_SEDGE_VALLEY_CHAMPIONSHIP_PARS, SAND_VALLEY_SEDGE_VALLEY_CHAMPIONSHIP_HCS, SAND_VALLEY_SEDGE_VALLEY_CHAMPIONSHIP_TEES,
          country: "USA",
          state: "WI",
          architect: "Tom Doak",
          type: "Resort",
          phone: "(888) 651-5539",
          website: "https://www.sandvalley.com",
          address: "1697 Leopold Way, Nekoosa, WI 54457"),
        
        // -------------------------
        // Arizona
        // -------------------------
        c(
            TROON_NORTH_MONUMENT_ID,
            "Troon North (Monument)",
            TROON_NORTH_MONUMENT_PARS,
            TROON_NORTH_MONUMENT_HCS,
            country: "USA",
            state: "AZ",
            type: "Daily-Fee",
            phone: "(480) 585-7700",
            address: "10320 E Dynamite Blvd, Scottsdale, AZ 85262"
        ),
        c(
            TROON_NORTH_PINNACLE_ID,
            "Troon North (Pinnacle)",
            TROON_NORTH_PINNACLE_PARS,
            TROON_NORTH_PINNACLE_HCS,
            country: "USA",
            state: "AZ",
            type: "Daily-Fee",
            phone: "(480) 585-7700",
            address: "10320 E Dynamite Blvd, Scottsdale, AZ 85262"
        ),
        c(
            WHISPER_ROCK_UPPER_ROCK_ID,
            "Whisper Rock Upper (Rock)",
            WHISPER_ROCK_UPPER_ROCK_PARS,
            WHISPER_ROCK_UPPER_ROCK_HCS,
            WHISPER_ROCK_UPPER_ROCK_TEES,
            country: "USA",
            state: "AZ",
            type: "Private",
            phone: "(480) 575-8700",
            address: "32000 N Old Bridge Rd, Scottsdale, AZ 85266"
        ),
        c(
            SILVERLEAF_GC_SILVER_ID,
            "Silverleaf GC (Silver)",
            SILVERLEAF_GC_SILVER_PARS,
            SILVERLEAF_GC_SILVER_HCS,
            SILVERLEAF_GC_SILVER_TEES,
            country: "USA",
            state: "AZ",
            type: "Private",
            phone: "(480) 515-3200",
            address: "18701 N Silverleaf Dr, Scottsdale, AZ 85255"
        ),
        c(
            SCOTTSDALE_NATIONAL_XTEE_ID,
            "Scottsdale National GC (X-Tee)",
            SCOTTSDALE_NATIONAL_XTEE_PARS,
            SCOTTSDALE_NATIONAL_XTEE_HCS,
            SCOTTSDALE_NATIONAL_XTEE_TEES,
            country: "USA",
            state: "AZ",
            type: "Private",
            phone: "(480) 443-8868",
            address: "28265 N Scottsdale National Dr, Scottsdale, AZ 85262"
        ),
        c(
            ESTANCIA_ID,
            "Estancia",
            ESTANCIA_PARS_TODO,
            ESTANCIA_HCS_TODO,
            country: "USA",
            state: "AZ",
            architect: "Tom Fazio",
            type: "Private",
            phone: "(480) 473-4400",
            address: "27998 N 99th Pl, Scottsdale, AZ 85262"
        ),
        c(
            FOREST_HIGHLANDS_MEADOW_ID,
            "Forest Highlands - Meadow (White)",
            FOREST_HIGHLANDS_MEADOW_PARS,
            FOREST_HIGHLANDS_MEADOW_MENS_HCS,
            country: "USA",
            state: "AZ",
            type: "Private",
            phone: "(928) 525-5200",
            address: "2425 William Palmer, Flagstaff, AZ 86005"
        ),
        // -------------------------
        // Oregon
        // -------------------------
        // -------------------------
        // Oregon
        // -------------------------
        c(
            BANDON_DUNES_ID,
            "Bandon Dunes",
            BANDON_DUNES_PARS,
            BANDON_DUNES_HCS,
            country: "USA",
            state: "OR",
            type: "Resort",
            phone: "(541) 347-5888",
            website: "https://www.bandondunesgolf.com/golf/golf-courses/bandon-dunes",
            address: "57744 Round Lake Road, Bandon, OR 97411"
        ),
        c(
            PACIFIC_DUNES_ID,
            "Pacific Dunes",
            PACIFIC_DUNES_PARS,
            PACIFIC_DUNES_HCS,
            country: "USA",
            state: "OR",
            type: "Resort",
            phone: "(541) 347-5831",
            website: "https://www.bandondunesgolf.com/golf/golf-courses/pacific-dunes",
            address: "57744 Round Lake Road, Bandon, OR 97411"
        ),
        c(
            BANDON_TRAILS_ID,
            "Bandon Trails",
            BANDON_TRAILS_PARS,
            BANDON_TRAILS_HCS,
            country: "USA",
            state: "OR",
            type: "Resort",
            phone: "(541) 347-5958",
            website: "https://www.bandondunesgolf.com/golf/golf-courses/bandon-trails",
            address: "57744 Round Lake Road, Bandon, OR 97411"
        ),
        c(
            OLD_MACDONALD_ID,
            "Old Macdonald",
            OLD_MACDONALD_PARS,
            OLD_MACDONALD_HCS,
            country: "USA",
            state: "OR",
            type: "Resort",
            phone: "(541) 347-5935",
            website: "https://www.bandondunesgolf.com/golf/golf-courses/old-macdonald",
            address: "57744 Round Lake Road, Bandon, OR 97411"
        ),
        c(
            SHEEP_RANCH_ID,
            "Sheep Ranch",
            SHEEP_RANCH_PARS,
            SHEEP_RANCH_HCS,
            country: "USA",
            state: "OR",
            type: "Resort",
            phone: "(541) 347-5985",
            website: "https://www.bandondunesgolf.com/golf/golf-courses/sheep-ranch",
            address: "57744 Round Lake Road, Bandon, OR 97411"
        ),
        // -------------------------
        // California
        // -------------------------
        c(
            PEBBLE_BEACH_ID,
            "Pebble Beach",
            PEBBLE_BEACH_PARS,
            PEBBLE_BEACH_HCS,
            country: "USA",
            state: "CA",
            region: "NorCal",
            type: "Resort",
            phone: "(800) 877-0597",
            website: "https://www.pebblebeach.com/golf/pebble-beach-golf-links/",
            address: "1700 17-Mile Drive, Pebble Beach, CA 93953"
        ),
        c(
            SPYGLASS_HILL_ID,
            "Spyglass Hill",
            SPYGLASS_HILL_PARS,
            SPYGLASS_HILL_HCS,
            country: "USA",
            state: "CA",
            region: "NorCal",
            type: "Resort",
            phone: "(831) 625-8563",
            website: "https://www.pebblebeach.com/golf/spyglass-hill-golf-course/",
            address: "Stevenson Drive, Pebble Beach, CA 93953"
        ),
        c(
            QUARRY_LA_QUINTA_ID,
            "The Quarry at La Quinta",
            QUARRY_LA_QUINTA_PARS,
            QUARRY_LA_QUINTA_HCS,
            country: "USA",
            state: "CA",
            region: "NorCal",
            architect: "Tom Fazio",
            type: "Private",
            phone: "(760) 777-1100",
            website: "https://www.thequarrygc.com/",
            address: "1 Quarry Lane, La Quinta, CA 92253"
        ),
        c(
            MARTIS_CAMP_ID,
            "Martis Camp",
            MARTIS_CAMP_MEDAL_PARS,
            MARTIS_CAMP_MEDAL_HCS,
            country: "USA",
            state: "CA",
            region: "NorCal",
            architect: "Tom Fazio",
            type: "Private",
            phone: "(530) 550-6000",
            website: "https://www.martiscamp.com/",
            address: "7951 Fleur du Lac Drive, Truckee, CA 96161"
        ),
        // -------------------------
        // South Carolina
        // -------------------------
        c(
            HARBOUR_TOWN_ID,
            "Harbour Town Golf Links",
            HARBOUR_TOWN_PARS,
            HARBOUR_TOWN_HCS,
            country: "USA",
            state: "SC",
            architect: "Pete Dye / Jack Nicklaus",
            type: "Resort",
            phone: "(843) 785-3333",
            website: "https://www.seapines.com/golf/courses/harbour-town-golf-links",
            address: "32 Greenwood Dr, Hilton Head Island, SC 29928"
        ),
        c(
            LONG_COVE_GOLD_ID,
            "Long Cove Club (Gold)",
            LONG_COVE_GOLD_PARS,
            LONG_COVE_GOLD_HCS,
            country: "USA",
            state: "SC",
            architect: "Pete Dye",
            type: "Private",
            phone: "(843) 686-1020",
            website: "https://longcoveclub.com/",
            address: "44 Long Cove Drive, Hilton Head Island, SC 29928"
        ),
        c(
            HERON_POINT_GOLD_ID,
            "Heron Point (Gold) — Sea Pines",
            HERON_POINT_GOLD_PARS,
            HERON_POINT_GOLD_HCS,
            country: "USA",
            state: "SC",
            architect: "Pete Dye",
            type: "Resort",
            phone: "(843) 785-3333",
            website: "https://www.seapines.com/golf/courses/heron-point-by-pete-dye",
            address: "32 Greenwood Dr, Hilton Head Island, SC 29928"
        ),
        c(
            KIAWAH_OCEAN_CHAMP_ID,
            "Kiawah Island - Ocean Course (Championship)",
            KIAWAH_OCEAN_CHAMP_PARS,
            KIAWAH_OCEAN_CHAMP_HCS,
            KIAWAH_OCEAN_CHAMP_TEES,
            country: "USA",
            state: "SC",
            architect: "Pete Dye",
            type: "Resort",
            phone: "(800) 654-2924",
            website: "https://kiawahresort.com/golf/the-ocean-course/",
            address: "1 Sanctuary Beach Drive, Kiawah Island, SC 29455"
        ),
        // -------------------------
        // Texas / Nevada / Oklahoma / Colorado / Wyoming / Montana
        // -------------------------
        c(
            ROYAL_OAKS_SCHEFFLER_ID,
            "Royal Oaks CC (Scheff)",
            ROYAL_OAKS_SCHEFFLER_PARS,
            ROYAL_OAKS_SCHEFFLER_HCS,
            country: "USA",
            state: "TX",
            type: "Private",
            phone: "(214) 691-6091",
            website: "https://www.roccdallas.com/",
            address: "7915 Greenville Avenue, Dallas, TX 75231"
        ),
        c(
            BROOK_HOLLOW_TILLINGHAST_ID,
            "Brook Hollow GC (Tillinghast)",
            BROOK_HOLLOW_TILLINGHAST_PARS,
            BROOK_HOLLOW_TILLINGHAST_HCS,
            BROOK_HOLLOW_TILLINGHAST_TEES,
            country: "USA",
            state: "TX",
            type: "Private",
            phone: "(214) 637-1900",
            website: "https://www.brookhollowgc.org/",
            address: "8301 Harry Hines Blvd., Dallas, TX 75235"
        ),
        c(
            SUMMIT_CLUB_MORIKAWA_ID,
            "Summit Club (Colin)",
            SUMMIT_CLUB_MORIKAWA_PARS,
            SUMMIT_CLUB_MORIKAWA_HCS,
            country: "USA",
            state: "NV",
            type: "Private",
            phone: "(702) 970-2207",
            website: "https://summitclubnv.com/",
            address: "11660 Summit Club Drive, Las Vegas, NV 89135"
        ),
        c(
            PATRIOT_GC_ID,
            "Patriot GC (4 Star)",
            PATRIOT_GC_4STAR_PARS,
            PATRIOT_GC_4STAR_HCS,
            country: "USA",
            state: "OK",
            type: "Private",
            phone: "(918) 272-1260",
            website: "https://www.patriotgolfclub.com/",
            address: "5790 N. Patriot Dr., Owasso, OK 74055"
        ),
        c(
            COLORADO_GOLF_CLUB_ID,
            "Colorado Golf Club",
            COLORADO_GOLF_CLUB_PARS,
            COLORADO_GOLF_CLUB_HCS,
            country: "USA",
            state: "CO",
            architect: "Bill Coore / Ben Crenshaw",
            type: "Private",
            phone: "(303) 840-5400",
            website: "https://www.coloradogolfclub.com/",
            address: "8000 Preservation Trail, Parker, CO 80134"
        ),
        c(
            CORNERSTONE_ID,
            "Cornerstone",
            CORNERSTONE_PARS_TODO,
            CORNERSTONE_HCS_TODO,
            country: "USA",
            state: "CO",
            architect: "Greg Norman",
            type: "Private",
            phone: "(970) 249-1922",
            website: "https://www.cornerstonemontrose.com/",
            address: "1 Club Terrace, Montrose, CO 81403"
        ),
        c(
            SHOOTING_STAR_ID,
            "Shooting Star",
            SHOOTING_STAR_CHAMPIONSHIP_PARS,
            SHOOTING_STAR_CHAMPIONSHIP_HCS,
            country: "USA",
            state: "WY",
            architect: "Tom Fazio",
            type: "Private",
            phone: "(307) 734-9773",
            website: "https://www.shootingstarjh.com/",
            address: "18 Shooting Star Drive, Teton Village, WY 83025"
        ),
        c(
            ROCK_CREEK_CATTLE_COMPANY_ID,
            "Rock Creek Cattle Company",
            ROCK_CREEK_CATTLE_COMPANY_TEE_I_PARS,
            ROCK_CREEK_CATTLE_COMPANY_TEE_I_HCS,
            ROCK_CREEK_CATTLE_COMPANY_TEES,
            country: "USA",
            state: "MT",
            type: "Private",
            phone: "(406) 846-4020",
            website: "https://www.rockcreekcattlecompany.com/",
            address: "6848 S. Rock Creek Road, Deer Lodge, MT 59722"
        ),
        // -------------------------
        // Georgia
        // -------------------------
        c(
            SEA_ISLAND_SEASIDE_RED_ID,
            "Sea Island (Seaside — Red)",
            SEA_ISLAND_SEASIDE_RED_PARS,
            SEA_ISLAND_SEASIDE_RED_HCS,
            SEA_ISLAND_SEASIDE_RED_TEES,
            country: "USA",
            state: "GA",
            architect: "Davis Love III, Mark Love",
            type: "Resort",
            phone: "(800) 732-4752",
            website: "https://www.seaisland.com/golf/courses/seaside/",
            address: "100 Retreat Avenue, St. Simons Island, GA 31522"
        ),
        c(
            SEA_ISLAND_RETREAT_RED_ID,
            "Sea Island (Retreat — Red)",
            SEA_ISLAND_RETREAT_RED_PARS,
            SEA_ISLAND_RETREAT_RED_HCS,
            SEA_ISLAND_RETREAT_RED_TEES,
            country: "USA",
            state: "GA",
            architect: "Davis Love III, Mark Love",
            type: "Resort",
            phone: "(800) 732-4752",
            website: "https://www.seaisland.com/golf/",
            address: "100 Retreat Avenue, St. Simons Island, GA 31522"
        ),
        c(
            AUGUSTA_NATIONAL_ID,
            "Augusta National (Masters)",
            AUGUSTA_NATIONAL_MASTERS_PARS,
            AUGUSTA_NATIONAL_MASTERS_HCS,
            country: "USA",
            state: "GA",
            architect: "Bobby Jones / Alister MacKenzie",
            type: "Private",
            phone: "(706) 667-6000",
            website: "https://www.masters.com",
            address: "PO Box 2068, Augusta, GA 30903-2068"
        ),
        c(
            MCLEMORE_KEEP_ID,
            "McLemore (The Keep)",
            MCLEMORE_KEEP_PARS,
            MCLEMORE_KEEP_HCS,
            MCLEMORE_KEEP_TEES,
            country: "USA",
            state: "GA",
            architect: "Bill Bergen, Rees Jones",
            type: "Resort",
            phone: "(800) 329-8154",
            website: "https://www.themclemore.com/golf/the-keep-at-mclemore",
            address: "32 Clubhouse Lane, Rising Fawn, GA 30738"
        ),
        // -------------------------
        // North Carolina / Hawaii / Washington / Michigan
        // -------------------------
        c(
            PINEHURST_NO2_USOPEN_ID,
            "Pinehurst No. 2 (U.S. Open)",
            PINEHURST_NO2_USOPEN_PARS,
            PINEHURST_NO2_USOPEN_HCS,
            country: "USA",
            state: "NC",
            architect: "Donald Ross",
            type: "Resort",
            phone: "(855) 235-8507",
            website: "https://www.pinehurst.com/golf/courses/no-2/",
            address: "80 Carolina Vista Dr, Pinehurst, NC 28374"
        ),
        c(
            WADE_HAMPTON_CLUB_ID,
            "Wade Hampton Club",
            WADE_HAMPTON_CLUB_PARS_TODO,
            WADE_HAMPTON_CLUB_HCS_TODO,
            country: "USA",
            state: "NC",
            architect: "Tom Fazio",
            type: "Private",
            phone: "(828) 743-2244",
            website: "https://www.wadehampton.com",
            address: "68 Hampton Dr, Cashiers, NC 28717"
        ),
        c(
            PINEHURST_NO10_BLUE_ID,
            "Pinehurst No. 10 (Blue)",
            PINEHURST_NO10_BLUE_PARS,
            PINEHURST_NO10_BLUE_HCS,
            PINEHURST_NO10_BLUE_TEES,
            country: "USA",
            state: "NC",
            architect: "Tom Doak, Angela Moser",
            type: "Resort",
            phone: "(855) 235-8507",
            website: "https://www.pinehurst.com/golf/courses/no-10/",
            address: "80 Carolina Vista Dr, Pinehurst, NC 28374"
        ),

        c(
            MANELE_GOLF_COURSE_NICKLAUS_ID,
            "Four Seasons Lanai Manele",
            MANELE_GOLF_COURSE_NICKLAUS_PARS,
            MANELE_GOLF_COURSE_NICKLAUS_HCS,
            MANELE_GOLF_COURSE_NICKLAUS_TEES,
            country: "USA",
            state: "HI",
            architect: "Jack Nicklaus",
            type: "Resort",
            phone: "(808) 565-2222",
            website: "https://www.fourseasons.com/lanai/golf/",
            address: "1 Manele Bay Rd, Lanai City, HI 96763"
        ),
        c(
            KAPALUA_PLANTATION_TOURNAMENT_ID,
            "Kapalua (Plantation – Tournament)",
            KAPALUA_PLANTATION_TOURNAMENT_PARS,
            KAPALUA_PLANTATION_TOURNAMENT_HCS,
            KAPALUA_PLANTATION_TOURNAMENT_TEES,
            country: "USA",
            state: "HI",
            architect: "Bill Coore, Ben Crenshaw",
            type: "Resort",
            phone: "(808) 669-8044",
            website: "https://www.golfatkapalua.com",
            address: "2000 Plantation Club Dr, Lahaina, HI 96761"
        ),

        c(
            GAMBLE_SANDS_ID,
            "Gamble Sands",
            GAMBLE_SANDS_PARS,
            GAMBLE_SANDS_HCS,
            GAMBLE_SANDS_TEES,
            country: "USA",
            state: "WA",
            architect: "David McLay Kidd",
            type: "Resort",
            phone: nil,
            website: "https://www.gamblesands.com/gamble-sands/",
            address: "200 Sands Trail Rd, Brewster, WA 98812",
            isWolfApproved: true,
            resortBrand: nil,
            promo: nil
        ),
        c(
            SCARECROW_ID,
            "Gamble Sands - Scarecrow",
            SCARECROW_PARS,
            SCARECROW_HCS,
            SCARECROW_TEES,
            country: "USA",
            state: "WA",
            architect: "David McLay Kidd / Nick Schaan",
            type: "Resort",
            phone: nil,
            website: "https://www.gamblesands.com/scarecrow/",
            address: "200 Sands Trail Rd, Brewster, WA 98812",
            isWolfApproved: true,
            resortBrand: nil,
            promo: nil
        ),
        c(
            ARCADIA_BLUFFS_BLUFFS_BLUE_ID,
            "Arcadia Bluffs (Bluffs — Blue)",
            ARCADIA_BLUFFS_BLUFFS_BLUE_PARS,
            ARCADIA_BLUFFS_BLUFFS_BLUE_HCS,
            ARCADIA_BLUFFS_BLUFFS_BLUE_TEES,
            country: "USA",
            state: "MI",
            architect: "Warren Henderson, Rick Smith",
            type: "Daily-Fee",
            phone: "(231) 889-3001",
            website: "https://www.arcadiabluffs.com",
            address: "14710 Northwood Hwy, Arcadia, MI 49613"
        ),

        // -------------------------
        // International
        // -------------------------

        c(
            ESKER_HILLS_ID,
            "Esker Hills Golf Club",
            ESKER_HILLS_PARS,
            ESKER_HILLS_HCS,
            country: "Ireland",
            state: nil,
            architect: "Christy O’Connor Jr.",
            type: "Public",
            phone: "+353 90 648 3219",
            website: "https://www.eskerhillsgolf.com",
            address: "Rahan, Tullamore, Co. Offaly, Ireland"
        ),
        c(
            ADARE_MANOR_ID,
            "Adare Manor",
            ADARE_MANOR_PARS,
            ADARE_MANOR_HCS,
            country: "Ireland",
            state: nil,
            architect: "Tom Fazio",
            type: "Resort",
            phone: "+353 61 605200",
            website: "https://www.adaremanor.com",
            address: "Adare Manor, Adare, Co. Limerick, Ireland"
        ),
        c(
            BALLYBUNION_OLD_ID,
            "Ballybunion (Old Course)",
            BALLYBUNION_OLD_PARS,
            BALLYBUNION_OLD_HCS,
            country: "Ireland",
            state: nil,
            architect: "Old Tom Morris (original)",
            type: "Public",
            phone: "+353 68 27146",
            website: "https://www.ballybuniongolfclub.com",
            address: "Sandhill Rd, Ballybunion, Co. Kerry, Ireland"
        ),
        c(
            OLD_HEAD_ID,
            "Old Head Golf Links",
            OLD_HEAD_PARS,
            OLD_HEAD_HCS,
            country: "Ireland",
            state: nil,
            architect: "Ron Kirby / Eddie Hackett",
            type: "Private",
            phone: "+353 21 477 8444",
            website: "https://www.oldhead.com",
            address: "Old Head, Kinsale, Co. Cork, Ireland"
        ),
        c(
            WATERVILLE_ID,
            "Waterville Golf Links",
            WATERVILLE_PARS,
            WATERVILLE_HCS,
            country: "Ireland",
            state: nil,
            architect: "Eddie Hackett / Tom Fazio redesign",
            type: "Public",
            phone: "+353 66 947 4102",
            website: "https://www.watervillegolflinks.ie",
            address: "Waterville, Co. Kerry, Ireland"
        ),
        c(
            LAHINCH_OLD_ID,
            "Lahinch Golf Club (Old Course)",
            LAHINCH_OLD_PARS,
            LAHINCH_OLD_HCS,
            country: "Ireland",
            state: nil,
            architect: "Old Tom Morris / Alister MacKenzie",
            type: "Public",
            phone: "+353 65 708 1003",
            website: "https://www.lahinchgolf.com",
            address: "Lahinch, Co. Clare, V95 HD00, Ireland",
            isWolfApproved: false
        ),
        c(
            ROYAL_COUNTY_DOWN_CHAMP_ID,
            "Royal County Down (Championship)",
            ROYAL_COUNTY_DOWN_CHAMP_PARS,
            ROYAL_COUNTY_DOWN_CHAMP_HCS,
            country: "Northern Ireland",
            state: nil,
            architect: "Old Tom Morris / Harry Colt",
            type: "Private",
            phone: "+44 28 4372 3314",
            website: "https://www.royalcountydown.org",
            address: "36 Golf Links Rd, Newcastle BT33 0AN, Northern Ireland"
        ),
        c(
            ROYAL_PORTRUSH_DUNLUCE_ID,
            "Royal Portrush (Dunluce)",
            ROYAL_PORTRUSH_DUNLUCE_PARS,
            ROYAL_PORTRUSH_DUNLUCE_HCS,
            country: "Northern Ireland",
            state: nil,
            architect: "Harry Colt / Martin Ebert redesign",
            type: "Public",
            phone: "+44 28 7082 2311",
            website: "https://www.royalportrushgolfclub.com",
            address: "Dunluce Rd, Portrush BT56 8JQ, Northern Ireland"
        ),
        c(
            ST_ANDREWS_OLD_ID,
            "St Andrews Links (Old Course)",
            ST_ANDREWS_OLD_PARS,
            ST_ANDREWS_OLD_HCS,
            ST_ANDREWS_OLD_TEES,
            country: "Scotland",
            state: nil,
            architect: "Old Tom Morris / Alister MacKenzie",
            type: "Public",
            phone: "+44 1334 466666",
            website: "https://standrews.com/golf/courses/old-course",
            address: "St Andrews, Fife KY16 9SF, Scotland, United Kingdom",
            isWolfApproved: true
        ),
        c(
            MUIRFIELD_ID,
            "Muirfield",
            MUIRFIELD_PARS,
            MUIRFIELD_HCS,
            MUIRFIELD_TEES,
            country: "Scotland",
            state: nil,
            architect: "Tom Morris (Old Tom Morris)",
            type: "Private",
            phone: "+44 1620 842123",
            website: "https://www.muirfield.org.uk",
            address: "Duncur Rd, Gullane EH31 2EG, Scotland, United Kingdom",
            isWolfApproved: true
        ),
        
        c(
            TURNBERRY_AILSA_ID,
            "Trump Turnberry Resort (Ailsa)",
            TURNBERRY_AILSA_PARS,
            TURNBERRY_AILSA_HCS,
            TURNBERRY_AILSA_TEES,
            country: "Scotland",
            state: nil,
            architect: "Willie Fernie / Mackenzie Ross / Martin Ebert",
            type: "Resort",
            website: "https://www.trumphotels.com/turnberry",
            address: "Turnberry, Ayrshire KA26 9LT, Scotland, United Kingdom",
            isWolfApproved: true
        ),

        c(
            TURNBERRY_KRTB_ID,
            "Trump Turnberry Resort (King Robert the Bruce)",
            TURNBERRY_KRTB_PARS,
            TURNBERRY_KRTB_HCS,
            TURNBERRY_KRTB_TEES,
            country: "Scotland",
            state: nil,
            architect: "Mackenzie Ross / Donald Steel",
            type: "Resort",
            website: "https://www.trumphotels.com/turnberry",
            address: "Turnberry, Ayrshire KA26 9LT, Scotland, United Kingdom",
            isWolfApproved: true
        ),
        c(
            LA_ESTANCIA_ID,
            "La Estancia Golf Resort (Tournament)",
            LA_ESTANCIA_TOURNAMENT_PARS,
            LA_ESTANCIA_TOURNAMENT_HCS,
            country: "Dominican Republic",
            state: nil,
            architect: "P.B. Dye",
            type: "Resort",
            phone: "+1 809-412-0000",
            website: "https://laestanciagolf.com",
            address: "Carretera La Romana – Higuey, La Romana, Dominican Republic"
        ),
        c(
            SUNNINGDALE_OLD_ID,
            "Sunningdale Golf Club (Old Course)",
            SUNNINGDALE_OLD_PARS,
            SUNNINGDALE_OLD_HCS,
            SUNNINGDALE_OLD_TEES,
            country: "England",
            state: nil,
            architect: "Willie Park Jr.",
            type: "Private",
            website: "https://www.sunningdalegolfclub.co.uk",
            address: "Ridgemount Rd, Sunningdale, Ascot SL5 9RR, England, United Kingdom",
            isWolfApproved: true
        ),
        c(
            ROYAL_DORNOCH_CHAMP_ID,
            "Royal Dornoch Golf Club (Championship Course)",
            ROYAL_DORNOCH_CHAMP_PARS,
            ROYAL_DORNOCH_CHAMP_HCS,
            ROYAL_DORNOCH_CHAMP_TEES,
            country: "Scotland",
            state: nil,
            architect: "Old Tom Morris",
            type: "Public",
            website: "https://royaldornoch.com",
            address: "Golf Rd, Dornoch IV25 3LW, Scotland, United Kingdom",
            isWolfApproved: true
        ),
        c(
            ROYAL_ST_GEORGES_ID,
            "Royal St George's Golf Club",
            ROYAL_ST_GEORGES_PARS,
            ROYAL_ST_GEORGES_HCS,
            ROYAL_ST_GEORGES_TEES,
            country: "England",
            state: nil,
            architect: "William Laidlaw Purves",
            type: "Private",
            website: "https://www.royalstgeorges.com",
            address: "Golf Rd, Sandwich CT13 9PB, England, United Kingdom",
            isWolfApproved: true
        ),

    
        c(
            PINE_VALLEY_ID,
            "Pine Valley",
            PINE_VALLEY_PARS,
            PINE_VALLEY_HCS,
            country: "USA",
            state: "NJ",
            architect: "George Crump / Harry Colt",
            type: "Private",
            phone: "(856) 783-3000",
            website: "https://www.pinevalleygolfclub.com",
            address: "1 East Atlantic Ave, Pine Valley, NJ 08021"
        ),
        c(OLD_WHITE_GREENBRIER_ID, "The Old White", OLD_WHITE_GREENBRIER_PARS, OLD_WHITE_GREENBRIER_HCS, OLD_WHITE_GREENBRIER_TEES,
          country: "USA", state: "WV", architect: "Charles Blair Macdonald", type: "Resort",
          phone: "800-624-6070",
          website: "https://www.greenbrier.com",
          address: "101 Main St W, White Sulphur Springs, WV 24986"),

        c(GREENBRIER_COURSE_ID, "The Greenbrier Course", GREENBRIER_COURSE_PARS, GREENBRIER_COURSE_HCS, GREENBRIER_COURSE_TEES,
          country: "USA", state: "WV", architect: "Seth Raynor / Jack Nicklaus", type: "Resort",
          phone: "800-624-6070",
          website: "https://www.greenbrier.com",
          address: "101 Main St W, White Sulphur Springs, WV 24986"),

        c(CONWAY_FARMS_ID, "Conway Farms", CONWAY_FARMS_PARS, CONWAY_FARMS_HCS, CONWAY_FARMS_TEES,
          country: "USA",
          state: "IL",
          type: "Private",
          phone: "847-234-7160",
          website: "https://www.conwayfarmsgolfclub.org",
          address: "425 S. Conway Farms Drive, Lake Forest, IL 60045"),

        c(SPANISH_BAY_ID, "The Links at Spanish Bay", SPANISH_BAY_PARS, SPANISH_BAY_HCS, SPANISH_BAY_TEES,
          country: "USA",
          state: "CA",
          region: "NorCal",
          type: "Resort",
          phone: "800-654-9300",
          website: "https://www.pebblebeach.com",
          address: "2700 17-Mile Drive, Pebble Beach, California 93953"),
        
        c(
            FRENCH_LICK_PETE_DYE_ID,
            "French Lick Resort – Pete Dye",
            FRENCH_LICK_PETE_DYE_PARS,
            FRENCH_LICK_PETE_DYE_HCS,
            FRENCH_LICK_PETE_DYE_TEES,
            country: "USA",
            state: "IN",
            region: " ",
            architect: "Pete Dye",
            type: "Resort",
            phone: "(888) 936-9360",
            website: "https://www.frenchlick.com/golf.htm",
            address: "8670 West State Road 56, French Lick, IN 47432"
        ),
        c(
            FRENCH_LICK_DONALD_ROSS_ID,
            "French Lick Resort – Donald Ross",
            FRENCH_LICK_DONALD_ROSS_PARS,
            FRENCH_LICK_DONALD_ROSS_HCS,
            FRENCH_LICK_DONALD_ROSS_TEES,
            country: "USA",
            state: "IN",
            architect: "Donald Ross",
            type: "Resort",
            phone: "(888) 936-9360",
            website: "https://www.frenchlick.com/golf.htm",
            address: "8670 West State Road 56, French Lick, IN 47432"
        ),
        c(
            SILVIES_CRADDOCK_ID,
            "Silvies Valley Resort & Links – Craddock",
            SILVIES_CRADDOCK_PARS,
            SILVIES_CRADDOCK_HCS,
            SILVIES_CRADDOCK_TEES,
            country: "USA",
            state: "OR",
            architect: "Dan Hixson",
            type: "Resort",
            phone: "(541) 573-5150",
            website: "https://silvies.us/golf-at-silvies-valley-ranch/",
            address: "10000 Rendezvous Lane, Seneca, OR 97873"
        ),
        c(
            ARBORLINKS_ID,
            "ArborLinks",
            ARBORLINKS_PARS,
            ARBORLINKS_HCS,
            ARBORLINKS_TEES,
            country: "USA",
            state: "NE",
            architect: "Arnold Palmer",
            type: "Private",
            phone: "(402) 873-4334",
            website: "https://arborlinks.com/",
            address: "6038 H Road, Nebraska City, NE 68410-6198"
        ),
        c(
            MID_PINES_ID,
            "Mid Pines",
            MID_PINES_PARS,
            MID_PINES_HCS,
            MID_PINES_TEES,
            country: "USA",
            state: "NC",
            architect: "Donald Ross",
            type: "Resort",
            phone: "(800) 323-2114",
            website: "https://www.midpinesinn.com/",
            address: "1010 Midland Road, Southern Pines, NC 28387"
        ),
        c(
            MAKAI_COURSE_ID,
            "Makai Course",
            MAKAI_COURSE_PARS,
            MAKAI_COURSE_HCS,
            MAKAI_COURSE_TEES,
            country: "USA",
            state: "HI",
            architect: "Robert Trent Jones Jr.",
            type: "Resort",
            phone: "(808) 826-1912",
            website: "https://www.makaigolf.com/",
            address: "4080 Lei O Papa Rd, Princeville, HI 96722"
        ),
        c(
            PINE_NEEDLES_ID,
            "Pine Needles",
            PINE_NEEDLES_PARS,
            PINE_NEEDLES_HCS,
            PINE_NEEDLES_TEES,
            country: "USA",
            state: "NC",
            architect: "Donald Ross",
            type: "Resort",
            phone: "(800) 747-7272",
            website: "https://www.pineneedleslodge.com/",
            address: "1005 Midland Road, Southern Pines, NC 28387"
        ),
        c(
            SOUTHERN_PINES_GC_ID,
            "Southern Pines Golf Club",
            SOUTHERN_PINES_GC_PARS,
            SOUTHERN_PINES_GC_HCS,
            SOUTHERN_PINES_GC_TEES,
            country: "USA",
            state: "NC",
            architect: "Donald Ross",
            type: "Resort",
            phone: "(910) 692-6551",
            website: "https://www.southernpinesgolfclub.com/",
            address: "290 Country Club Circle, Southern Pines, NC 28387"
        ),
        c(
            TROON_COUNTRY_CLUB_ID,
            "Troon Country Club",
            TROON_COUNTRY_CLUB_PARS,
            TROON_COUNTRY_CLUB_HCS,
            TROON_COUNTRY_CLUB_TEES,
            country: "USA",
            state: "AZ",
            architect: "Jay Morrish / Tom Weiskopf",
            type: "Private",
            phone: "(480) 585-4310",
            website: "https://www.trooncc.com/",
            address: "25000 N. Windy Walk Drive, Scottsdale, AZ 85255"
        ),
        c(
            TOP_OF_THE_ROCK_ID,
            "Top of the Rock",
            TOP_OF_THE_ROCK_PARS,
            TOP_OF_THE_ROCK_HCS,
            TOP_OF_THE_ROCK_TEES,
            country: "USA",
            state: "MO",
            architect: "Jack Nicklaus",
            type: "Resort",
            phone: "417-339-5343",
            website: "https://www.bigcedar.com",
            address: "150 Top of the Rock Rd, Ridgedale, MO 65739",
            isWolfApproved: true
        ),
        c(
            PAYNES_VALLEY_ID,
            "Payne’s Valley (Big Cedar)",
            PAYNES_VALLEY_PARS,
            PAYNES_VALLEY_HCS,
            PAYNES_VALLEY_TEES,
            country: "USA",
            state: "MO",
            architect: "Tiger Woods / TGR Design",
            type: "Resort",
            phone: "(800) 225-6343",
            website: "https://bigcedar.com/golf/paynes-valley/",
            address: "1250 Buffalo Ridge Blvd, Hollister, MO 65672",
            isWolfApproved: true,
            resortBrand: "Big Cedar"
        ),
        c(
            CLIFFHANGERS_ID,
            "Cliffhangers",
            CLIFFHANGERS_PARS,
            CLIFFHANGERS_HCS,
            nil,
            country: "USA",
            state: "MO",
            architect: "Big Cedar Lodge",
            type: "Resort",
            phone: "417-339-5343",
            website: "https://www.bigcedar.com/golf/cliffhangers/",
            address: "1250 Buffalo Ridge Blvd, Hollister, MO 65672",
            isWolfApproved: true
        ),
        c(
            BUFFALO_RIDGE_ID,
            "Buffalo Ridge (Big Cedar)",
            BUFFALO_RIDGE_PARS,
            BUFFALO_RIDGE_HCS,
            BUFFALO_RIDGE_TEES,
            country: "USA",
            state: "MO",
            architect: "Tom Fazio",
            type: "Resort",
            phone: "(800) 225-6343",
            website: "https://bigcedar.com/golf/buffalo-ridge/",
            address: "1001 Buffalo Ridge Blvd, Hollister, MO 65672",
            isWolfApproved: true,
            resortBrand: "Big Cedar"
        ),
       
        c(
            PRAIRIE_CLUB_DUNES_ID,
            "The Prairie Club - Dunes Course",
            PRAIRIE_CLUB_DUNES_PARS,
            PRAIRIE_CLUB_DUNES_HCS,
            nil,
            country: "USA",
            state: "NE",
            architect: "Tom Lehman / Chris Brands",
            type: "Resort",
            phone: "(888) 402-1101",
            website: "https://theprairieclub.com/golf/dunes-course/",
            address: "88897 State Hwy. 97, Valentine, NE 69201",
            isWolfApproved: true
        ),
        c(
            LOOP_BLACK_ID,
            "The Loop - Black Course",
            LOOP_BLACK_PARS,
            LOOP_BLACK_HCS,
            nil,
            country: "USA",
            state: "MI",
            architect: "Tom Doak",
            type: "Resort",
            phone: "(989) 275-0700",
            website: "https://forestdunesgolf.com/play-the-loop",
            address: "6376 Forest Dunes Drive, Roscommon, MI 48653",
            isWolfApproved: true
        ),
        c(
            LOOP_RED_ID,
            "The Loop - Red Course",
            LOOP_RED_PARS,
            LOOP_RED_HCS,
            nil,
            country: "USA",
            state: "MI",
            architect: "Tom Doak",
            type: "Resort",
            phone: "(989) 275-0700",
            website: "https://forestdunesgolf.com/play-the-loop",
            address: "6376 Forest Dunes Drive, Roscommon, MI 48653",
            isWolfApproved: true
        ),
        c(
            FOREST_DUNES_ID,
            "Forest Dunes",
            FOREST_DUNES_PARS,
            FOREST_DUNES_HCS,
            nil,
            country: "USA",
            state: "MI",
            architect: "Tom Weiskopf",
            type: "Resort",
            phone: "(989) 275-0700",
            website: "https://forestdunesgolf.com/play-forest-dunes",
            address: "6376 Forest Dunes Drive, Roscommon, MI 48653",
            isWolfApproved: true
        ),
        c(
            THE_LEGEND_ID,
            "The Legend at Giants Ridge",
            THE_LEGEND_PARS,
            THE_LEGEND_HCS,
            THE_LEGEND_TEES,
            country: "USA",
            state: "MN",
            architect: "Jeffrey Brauer",
            type: "Resort",
            phone: "(218) 865-8030",
            website: "https://www.giantsridge.com/the-legend/",
            address: "6329 Wynne Creek Drive, Biwabik, MN 55708",
            isWolfApproved: true
        ),
        c(
            THE_QUARRY_ID,
            "The Quarry at Giants Ridge",
            THE_QUARRY_PARS,
            THE_QUARRY_HCS,
            THE_QUARRY_TEES,
            country: "USA",
            state: "MN",
            architect: "Jeffrey Brauer",
            type: "Resort",
            phone: "(800) 688-7669",
            website: "https://www.giantsridge.com/the-quarry/",
            address: "6329 Wynne Creek Drive, Biwabik, MN 55708",
            isWolfApproved: true
        ),
        c(
            RICHTER_PARK_GOLF_COURSE_ID,
            "Richter Park Golf Course",
            RICHTER_PARK_GOLF_COURSE_PARS,
            RICHTER_PARK_GOLF_COURSE_HCS,
            RICHTER_PARK_GOLF_COURSE_TEES,
            country: "USA",
            state: "CT",
            type: "Daily-Fee",
            phone: "(203) 792-2550",
            website: "https://www.richterpark.com",
            address: "100 Aunt Hack Rd, Danbury, CT 06811",
            isWolfApproved: true
        ),

        c(
            LAKE_OF_ISLES_ID,
            "Lake of Isles (North Course)",
            LAKE_OF_ISLES_NORTH_PARS,
            LAKE_OF_ISLES_NORTH_HCS,
            LAKE_OF_ISLES_NORTH_TEES,
            country: "USA",
            state: "CT",
            architect: "Rees Jones, Inc.",
            type: "Resort",
            phone: "(860) 312-3636",
            website: "https://www.lakeofisles.com",
            address: "1 Clubhouse Drive, North Stonington, CT 06359",
            isWolfApproved: true
        ),

        c(
            UUID(uuidString: "B8C9D0E2-3F4A-5B6C-9D7E-8F0A1B2C3D73")!,
            "Lake of Isles (South Course)",
            LAKE_OF_ISLES_SOUTH_PARS,
            LAKE_OF_ISLES_SOUTH_HCS,
            LAKE_OF_ISLES_SOUTH_TEES,
            country: "USA",
            state: "CT",
            architect: "Rees Jones, Inc.",
            type: "Resort",
            phone: "(860) 312-3636",
            website: "https://www.lakeofisles.com",
            address: "1 Clubhouse Drive, North Stonington, CT 06359",
            isWolfApproved: true
        ),

        c(
            BROOKLAWN_COUNTRY_CLUB_ID,
            "Brooklawn Country Club",
            BROOKLAWN_COUNTRY_CLUB_PARS,
            BROOKLAWN_COUNTRY_CLUB_HCS,
            BROOKLAWN_COUNTRY_CLUB_TEES,
            country: "USA",
            state: "CT",
            architect: "A. W. Tillinghast",
            type: "Private",
            phone: "(203) 334-5116",
            website: "https://brooklawncc.com",
            address: "500 Algonquin Road, Fairfield, CT 06825",
            isWolfApproved: true
        ),
        c(
            STERLING_FARMS_GC_ID,
            "Sterling Farms Golf Course",
            STERLING_FARMS_GC_PARS,
            STERLING_FARMS_GC_HCS,
            STERLING_FARMS_GC_TEES,
            country: "USA",
            state: "CT",
            architect: "Geoffrey Cornish",
            type: "Municipal",
            phone: "(203) 461-9090",
            website: "https://www.sterlingfarmsgc.com",
            address: "1349 Newfield Avenue, Stamford, CT 06905",
            isWolfApproved: true
        ),
        c(
            GRAYHAWK_GC_TALON_ID,
            "Grayhawk GC (Talon)",
            GRAYHAWK_GC_TALON_PARS,
            GRAYHAWK_GC_TALON_HCS,
            GRAYHAWK_GC_TALON_TEES,
            country: "USA",
            state: "AZ",
            architect: "David Graham / Gary Panks",
            type: "Daily-Fee",
            phone: "(480) 502-1800",
            website: "https://www.grayhawkgolf.com",
            address: "8620 E Thompson Peak Pkwy, Scottsdale, AZ 85255",
            isWolfApproved: false
        ),
        c(
            GRAYHAWK_GC_RAPTOR_ID,
            "Grayhawk GC (Raptor)",
            GRAYHAWK_GC_RAPTOR_PARS,
            GRAYHAWK_GC_RAPTOR_HCS,
            GRAYHAWK_GC_RAPTOR_TEES,
            country: "USA",
            state: "AZ",
            architect: "Tom Fazio",
            type: "Daily-Fee",
            phone: "(480) 502-1800",
            website: "https://www.grayhawkgolf.com",
            address: "8620 E Thompson Peak Pkwy, Scottsdale, AZ 85255",
            isWolfApproved: false
        ),
        c(
            WEKOPA_SAGUARO_ID,
            "We-Ko-Pa Golf Club (Saguaro)",
            WEKOPA_SAGUARO_PARS,
            WEKOPA_SAGUARO_HCS,
            WEKOPA_SAGUARO_TEES,
            country: "USA",
            state: "AZ",
            architect: "Bill Coore & Ben Crenshaw",
            type: "Resort",
            phone: "(480) 836-9000",
            website: "https://wekopa.com",
            address: "18200 E Wekopa Way, Fort McDowell, AZ 85264",
            isWolfApproved: false
        ),
        c(
            WEKOPA_CHOLLA_ID,
            "We-Ko-Pa Golf Club (Cholla)",
            WEKOPA_CHOLLA_PARS,
            WEKOPA_CHOLLA_HCS,
            WEKOPA_CHOLLA_TEES,
            country: "USA",
            state: "AZ",
            architect: "Scott Miller",
            type: "Resort",
            phone: "(480) 836-9000",
            website: "https://wekopa.com",
            address: "18200 E Wekopa Way, Fort McDowell, AZ 85264",
            isWolfApproved: true
        ),
        c(
            PGA_WEST_STADIUM_ID,
            "PGA WEST (Stadium Course)",
            PGA_WEST_STADIUM_PARS,
            PGA_WEST_STADIUM_HCS,
            PGA_WEST_STADIUM_TEES,
            country: "USA",
            state: "CA",
            region: "Palm Springs",
            architect: "Pete Dye",
            type: "Resort",
            phone: "(760) 564-7101",
            website: "https://www.pgawest.com",
            address: "56150 PGA Blvd, La Quinta, CA 92253",
            isWolfApproved: true
        ),

        c(
            PELICAN_HILL_OCEAN_NORTH_ID,
            "Pelican Hill Golf Club (Ocean North)",
            PELICAN_HILL_OCEAN_NORTH_PARS,
            PELICAN_HILL_OCEAN_NORTH_HCS,
            PELICAN_HILL_OCEAN_NORTH_TEES,
            country: "USA",
            state: "CA",
            region: "SoCal",
            architect: "Tom Fazio",
            type: "Private",
            phone: "(855) 315-8214",
            website: "https://www.pelicanhill.com/golf",
            address: "22701 Pelican Hill Rd S, Newport Coast, CA 92657",
            isWolfApproved: true
        ),

        c(
            LA_COSTA_NORTH_ID,
            "La Costa Resort & Spa (North Course)",
            LA_COSTA_NORTH_PARS,
            LA_COSTA_NORTH_HCS,
            LA_COSTA_NORTH_TEES,
            country: "USA",
            state: "CA",
            region: "SoCal",
            type: "Resort",
            phone: "(760) 438-9111",
            website: "https://www.omnihotels.com/hotels/san-diego-la-costa/golf",
            address: "2100 Costa Del Mar Rd, Carlsbad, CA 92009",
            isWolfApproved: true
        ),

        c(
            YOCHA_DEHE_ID,
            "Yocha Dehe Golf Club at Cache Creek",
            YOCHA_DEHE_PARS,
            YOCHA_DEHE_HCS,
            YOCHA_DEHE_TEES,
            country: "USA",
            state: "CA",
            region: "NorCal",
            architect: "Brad Bell",
            type: "Resort",
            phone: "(530) 796-4653",
            website: "https://www.yochadehegolfclub.com",
            address: "14455 CA-16, Brooks, CA 95606",
            isWolfApproved: true
        ),

        c(
            PGA_WEST_NICKLAUS_TOURNAMENT_ID,
            "PGA WEST (Nicklaus Tournament Course)",
            PGA_WEST_NICKLAUS_TOURNAMENT_PARS,
            PGA_WEST_NICKLAUS_TOURNAMENT_HCS,
            PGA_WEST_NICKLAUS_TOURNAMENT_TEES,
            country: "USA",
            state: "CA",
            region: "Palm Springs",
            architect: "Arnold Palmer",
            type: "Resort",
            phone: "(760) 564-7101",
            website: "https://www.pgawest.com/course-restorations/jack-nicklaus-tournament-course",
            address: "56-150 PGA Blvd, La Quinta, CA 92253",
            isWolfApproved: true
        ),

        c(
            DESERT_WILLOW_FIRECLIFF_ID,
            "Desert Willow Golf Resort (Firecliff Course)",
            DESERT_WILLOW_FIRECLIFF_PARS,
            DESERT_WILLOW_FIRECLIFF_HCS,
            DESERT_WILLOW_FIRECLIFF_TEES,
            country: "USA",
            state: "CA",
            region: "Palm Springs",
            type: "Resort",
            phone: "(760) 346-7060",
            website: "https://www.desertwillow.com/firecliffcourse/",
            address: "38-995 Desert Willow Dr, Palm Desert, CA 92260",
            isWolfApproved: true
        ),

        c(
            INDIAN_WELLS_CELEBRITY_ID,
            "Indian Wells Golf Resort (Celebrity Course)",
            INDIAN_WELLS_CELEBRITY_PARS,
            INDIAN_WELLS_CELEBRITY_HCS,
            INDIAN_WELLS_CELEBRITY_TEES,
            country: "USA",
            state: "CA",
            region: "Palm Springs",
            type: "Resort",
            phone: "(760) 346-4653",
            website: "https://www.indianwellsgolfresort.com/celebrity-course/",
            address: "44-500 Indian Wells Ln, Indian Wells, CA 92210",
            isWolfApproved: true
        ),

        c(
            SILVERROCK_RESORT_ID,
            "SilverRock Resort",
            SILVERROCK_RESORT_PARS,
            SILVERROCK_RESORT_HCS,
            SILVERROCK_RESORT_TEES,
            country: "USA",
            state: "CA",
            region: "Palm Springs",
            architect: "Arnold Palmer",
            type: "Resort",
            phone: "(760) 777-8884",
            website: "https://www.silverrock.org/",
            address: "79179 Ahmanson Ln, La Quinta, CA 92253",
            isWolfApproved: true
        ),

        c(
            DESERT_WILLOW_MOUNTAIN_VIEW_ID,
            "Desert Willow Golf Resort (Mountain View Course)",
            DESERT_WILLOW_MOUNTAIN_VIEW_PARS,
            DESERT_WILLOW_MOUNTAIN_VIEW_HCS,
            DESERT_WILLOW_MOUNTAIN_VIEW_TEES,
            country: "USA",
            state: "CA",
            region: "Palm Springs",
            architect: "Hurdzan/Fry",
            type: "Resort",
            phone: "(760) 346-7060",
            website: "https://www.desertwillow.com/mountainviewcourse/",
            address: "38995 Desert Willow Dr, Palm Desert, CA 92260",
            isWolfApproved: true
        ),

        c(
            INDIAN_WELLS_PLAYERS_ID,
            "Indian Wells Golf Resort (Players Course)",
            INDIAN_WELLS_PLAYERS_PARS,
            INDIAN_WELLS_PLAYERS_HCS,
            INDIAN_WELLS_PLAYERS_TEES,
            country: "USA",
            state: "CA",
            region: "Palm Springs",
            architect: "John Fought",
            type: "Resort",
            phone: "(760) 346-4653",
            website: "https://www.indianwellsgolfresort.com/players-course/",
            address: "44-500 Indian Wells Ln, Indian Wells, CA 92210",
            isWolfApproved: true
        ),

        c(
            CLASSIC_CLUB_ID,
            "Classic Club",
            CLASSIC_CLUB_PARS,
            CLASSIC_CLUB_HCS,
            CLASSIC_CLUB_TEES,
            country: "USA",
            state: "CA",
            region: "Palm Springs",
            architect: "Arnold Palmer",
            type: "Resort",
            phone: "(760) 601-3600",
            website: "https://www.classicclubgolf.com/course-information/",
            address: "75-200 Classic Club Blvd, Palm Desert, CA 92211",
            isWolfApproved: true
        ),

        c(
            TAHQUITZ_CREEK_RESORT_ID,
            "Tahquitz Creek Golf Resort (Resort Course)",
            TAHQUITZ_CREEK_RESORT_PARS,
            TAHQUITZ_CREEK_RESORT_HCS,
            TAHQUITZ_CREEK_RESORT_TEES,
            country: "USA",
            state: "CA",
            region: "Palm Springs",
            architect: "Ted Robinson",
            type: "Resort",
            phone: "(760) 328-1005",
            website: "https://www.tahquitzgolfresort.com/",
            address: "1885 Golf Club Dr, Palm Springs, CA 92264",
            isWolfApproved: true
        ),

        c(
            TAHQUITZ_LEGEND_ID,
            "Tahquitz Creek Golf Resort (Legend Course)",
            TAHQUITZ_LEGEND_PARS,
            TAHQUITZ_LEGEND_HCS,
            TAHQUITZ_LEGEND_TEES,
            country: "USA",
            state: "CA",
            region: "Palm Springs",
            architect: "William F. Bell",
            type: "Resort",
            phone: "760-328-1005",
            website: "https://www.tahquitzgolfresort.com",
            address: "1885 Golf Club Dr, Palm Springs, CA 92264",
            isWolfApproved: true
        ),

        c(
            INDIAN_CANYONS_SOUTH_ID,
            "Indian Canyons Golf Resort (South Course)",
            INDIAN_CANYONS_SOUTH_PARS,
            INDIAN_CANYONS_SOUTH_HCS,
            INDIAN_CANYONS_SOUTH_TEES,
            country: "USA",
            state: "CA",
            region: "Palm Springs",
            architect: "Casey O'Callaghan / Amy Alcott (renovation)",
            type: "Resort",
            phone: "760-833-8700",
            website: "https://www.indiancanyonsgolf.com",
            address: "1097 E Murray Canyon Dr, Palm Springs, CA 92264",
            isWolfApproved: true
        ),

        c(
            INDIAN_CANYONS_NORTH_ID,
            "Indian Canyons Golf Resort (North Course)",
            INDIAN_CANYONS_NORTH_PARS,
            INDIAN_CANYONS_NORTH_HCS,
            INDIAN_CANYONS_NORTH_TEES,
            country: "USA",
            state: "CA",
            region: "Palm Springs",
            architect: "William F. Bell",
            type: "Resort",
            phone: "760-833-8700",
            website: "https://www.indiancanyonsgolf.com",
            address: "1097 E Murray Canyon Dr, Palm Springs, CA 92264",
            isWolfApproved: true
        ),

        c(
            MONARCH_BEACH_ID,
            "Monarch Beach Golf Links",
            MONARCH_BEACH_PARS,
            MONARCH_BEACH_HCS,
            MONARCH_BEACH_TEES,
            country: "USA",
            state: "CA",
            region: "SoCal",
            architect: "Robert Trent Jones Jr.",
            type: "Resort",
            phone: "949-248-3002",
            website: "https://www.monarchbeachgolf.com",
            address: "50 Monarch Beach Resort N, Dana Point, CA 92629",
            isWolfApproved: true
        ),

        c(
            TORREY_PINES_SOUTH_ID,
            "Torrey Pines (South Course)",
            TORREY_PINES_SOUTH_PARS,
            TORREY_PINES_SOUTH_HCS,
            TORREY_PINES_SOUTH_TEES,
            country: "USA",
            state: "CA",
            region: "SoCal",
            architect: "William F. Bell / Rees Jones (renovation)",
            type: "Public",
            phone: "858-452-3226",
            website: "https://www.torreypines.com",
            address: "11480 N Torrey Pines Rd, La Jolla, CA 92037",
            isWolfApproved: true
        ),

        c(
            TORREY_PINES_NORTH_ID,
            "Torrey Pines (North Course)",
            TORREY_PINES_NORTH_PARS,
            TORREY_PINES_NORTH_HCS,
            TORREY_PINES_NORTH_TEES,
            country: "USA",
            state: "CA",
            region: "SoCal",
            architect: "William F. Bell / Tom Weiskopf (renovation)",
            type: "Public",
            phone: "858-452-3226",
            website: "https://www.torreypines.com",
            address: "11480 N Torrey Pines Rd, La Jolla, CA 92037",
            isWolfApproved: true
        ),

        c(
            HALF_MOON_BAY_OLD_ID,
            "Half Moon Bay Golf Links (Old Course)",
            HALF_MOON_BAY_OLD_PARS,
            HALF_MOON_BAY_OLD_HCS,
            HALF_MOON_BAY_OLD_TEES,
            country: "USA",
            state: "CA",
            region: "NorCal",
            architect: "Arnold Palmer / Francis Duane",
            type: "Resort",
            phone: "650-726-1800",
            website: "https://www.halfmoonbaygolf.com",
            address: "2 Miramontes Point Rd, Half Moon Bay, CA 94019",
            isWolfApproved: true
        ),

        c(
            HALF_MOON_BAY_OCEAN_ID,
            "Half Moon Bay Golf Links (Ocean Course)",
            HALF_MOON_BAY_OCEAN_PARS,
            HALF_MOON_BAY_OCEAN_HCS,
            HALF_MOON_BAY_OCEAN_TEES,
            country: "USA",
            state: "CA",
            region: "NorCal",
            architect: "Arthur Hills",
            type: "Resort",
            phone: "650-726-1800",
            website: "https://www.halfmoonbaygolf.com",
            address: "2 Miramontes Point Rd, Half Moon Bay, CA 94019",
            isWolfApproved: false
        ),
        c(
            CAMBRIAN_RIDGE_CANYON_SHERLING_ID,
            "Cambrian Ridge (Canyon / Sherling)",
            CAMBRIAN_RIDGE_CANYON_SHERLING_PARS,
            CAMBRIAN_RIDGE_CANYON_SHERLING_HCS,
            CAMBRIAN_RIDGE_CANYON_SHERLING_TEES,
            country: "USA",
            state: "AL",
            architect: "Robert Trent Jones, Sr.",
            type: "RTJ Trail",
            phone: "(334) 382-9787",
            website: "https://www.rtjgolf.com/cambrianridge/",
            address: "101 SunBelt Parkway, Greenville, AL 36037"
        ),

        c(
            CAMBRIAN_RIDGE_CANYON_LOBLOLLY_ID,
            "Cambrian Ridge (Canyon / Loblolly)",
            CAMBRIAN_RIDGE_CANYON_LOBLOLLY_PARS,
            CAMBRIAN_RIDGE_CANYON_LOBLOLLY_HCS,
            CAMBRIAN_RIDGE_CANYON_LOBLOLLY_TEES,
            country: "USA",
            state: "AL",
            architect: "Robert Trent Jones, Sr.",
            type: "RTJ Trail",
            phone: "(334) 382-9787",
            website: "https://www.rtjgolf.com/cambrianridge/",
            address: "101 SunBelt Parkway, Greenville, AL 36037"
        ),

        c(
            CAMBRIAN_RIDGE_SHERLING_LOBLOLLY_ID,
            "Cambrian Ridge (Sherling / Loblolly)",
            CAMBRIAN_RIDGE_SHERLING_LOBLOLLY_PARS,
            CAMBRIAN_RIDGE_SHERLING_LOBLOLLY_HCS,
            CAMBRIAN_RIDGE_SHERLING_LOBLOLLY_TEES,
            country: "USA",
            state: "AL",
            architect: "Robert Trent Jones, Sr.",
            type: "RTJ Trail",
            phone: "(334) 382-9787",
            website: "https://www.rtjgolf.com/cambrianridge/",
            address: "101 SunBelt Parkway, Greenville, AL 36037"
        ),
        c(RTJ_GRAND_NATIONAL_LAKE_ID,
          "Grand National (Lake)",
          RTJ_GRAND_NATIONAL_LAKE_PARS,
          RTJ_GRAND_NATIONAL_LAKE_HCS,
          RTJ_GRAND_NATIONAL_LAKE_TEES,
          country: "USA",
          state: "AL",
          architect: "Robert Trent Jones, Sr.",
          type: "RTJ Trail",
          phone: "(334) 749-9042",
          website: "https://www.rtjgolf.com/grandnational/",
          address: "3000 Robert Trent Jones Trail, Opelika, AL 36801"
        ),

        c(RTJ_GRAND_NATIONAL_LINKS_ID,
          "Grand National (Links)",
          RTJ_GRAND_NATIONAL_LINKS_PARS,
          RTJ_GRAND_NATIONAL_LINKS_HCS,
          RTJ_GRAND_NATIONAL_LINKS_TEES,
          country: "USA",
          state: "AL",
          architect: "Robert Trent Jones, Sr.",
          type: "RTJ Trail",
          phone: "(334) 749-9042",
          website: "https://www.rtjgolf.com/grandnational/",
          address: "3000 Robert Trent Jones Trail, Opelika, AL 36801"
        ),
        c(
            RTJ_GRAND_NATIONAL_SHORT_ID,
            "Grand National (Short Course)",
            RTJ_GRAND_NATIONAL_SHORT_PARS,
            RTJ_GRAND_NATIONAL_SHORT_HCS,
            RTJ_GRAND_NATIONAL_SHORT_TEES,
            country: "USA",
            state: "AL",
            architect: "Robert Trent Jones, Sr.",
            type: "RTJ Trail",
            phone: "(334) 749-9042",
            website: "https://www.rtjgolf.com/grandnational/",
            address: "3000 Robert Trent Jones Trail, Opelika, AL 36801"
        ),
        c(
            RTJ_HAMPTON_COVE_HIGHLANDS_ID,
            "Hampton Cove (Highlands)",
            RTJ_HAMPTON_COVE_HIGHLANDS_PARS,
            RTJ_HAMPTON_COVE_HIGHLANDS_HCS,
            RTJ_HAMPTON_COVE_HIGHLANDS_TEES,
            country: "USA",
            state: "AL",
            architect: "Robert Trent Jones, Sr.",
            type: "RTJ Trail",
            phone: "(256) 551-1818",
            website: "https://www.rtjgolf.com/hamptoncove/",
            address: "450 Old Highway 431, Owens Crossroads, AL 35763"
        ),

        c(
            RTJ_HAMPTON_COVE_RIVER_ID,
            "Hampton Cove (River)",
            RTJ_HAMPTON_COVE_RIVER_PARS,
            RTJ_HAMPTON_COVE_RIVER_HCS,
            RTJ_HAMPTON_COVE_RIVER_TEES,
            country: "USA",
            state: "AL",
            architect: "Robert Trent Jones, Sr.",
            type: "RTJ Trail",
            phone: "(256) 551-1818",
            website: "https://www.rtjgolf.com/hamptoncove/",
            address: "450 Old Highway 431, Owens Crossroads, AL 35763"
        ),

        c(
            RTJ_HAMPTON_COVE_SHORT_ID,
            "Hampton Cove (Short Course)",
            RTJ_HAMPTON_COVE_SHORT_PARS,
            RTJ_HAMPTON_COVE_SHORT_HCS,
            RTJ_HAMPTON_COVE_SHORT_TEES,
            country: "USA",
            state: "AL",
            architect: "Robert Trent Jones, Sr.",
            type: "RTJ Trail",
            phone: "(256) 551-1818",
            website: "https://www.rtjgolf.com/hamptoncove/",
            address: "450 Old Highway 431, Owens Crossroads, AL 35763"
        ),
        c(RTJ_HIGHLAND_OAKS_HIGHLANDS_MAGNOLIA_ID,
          "Highland Oaks (Highlands / Magnolia)",
          RTJ_HIGHLAND_OAKS_HIGHLANDS_MAGNOLIA_PARS,
          RTJ_HIGHLAND_OAKS_HIGHLANDS_MAGNOLIA_HCS,
          RTJ_HIGHLAND_OAKS_HIGHLANDS_MAGNOLIA_TEES,
          country: "USA",
          state: "AL",
          architect: "Robert Trent Jones, Sr.",
          type: "RTJ Trail",
          phone: "(334) 712-2820",
          website: "https://www.rtjgolf.com/highlandoaks/",
          address: "904 Royal Pkwy, Dothan, AL 36305"
        ),
        c(RTJ_HIGHLAND_OAKS_HIGHLANDS_MARSHWOOD_ID,
          "Highland Oaks (Highlands / Marshwood)",
          RTJ_HIGHLAND_OAKS_HIGHLANDS_MARSHWOOD_PARS,
          RTJ_HIGHLAND_OAKS_HIGHLANDS_MARSHWOOD_HCS,
          RTJ_HIGHLAND_OAKS_HIGHLANDS_MARSHWOOD_TEES,
          country: "USA",
          state: "AL",
          architect: "Robert Trent Jones, Sr.",
          type: "RTJ Trail",
          phone: "(334) 712-2820",
          website: "https://www.rtjgolf.com/highlandoaks/",
          address: "904 Royal Pkwy, Dothan, AL 36305"
        ),

        c(RTJ_HIGHLAND_OAKS_MAGNOLIA_MARSHWOOD_ID,
          "Highland Oaks (Magnolia / Marshwood)",
          RTJ_HIGHLAND_OAKS_MAGNOLIA_MARSHWOOD_PARS,
          RTJ_HIGHLAND_OAKS_MAGNOLIA_MARSHWOOD_HCS,
          RTJ_HIGHLAND_OAKS_MAGNOLIA_MARSHWOOD_TEES,
          country: "USA",
          state: "AL",
          architect: "Robert Trent Jones, Sr.",
          type: "RTJ Trail",
          phone: "(334) 712-2820",
          website: "https://www.rtjgolf.com/highlandoaks/",
          address: "904 Royal Pkwy, Dothan, AL 36305"
        ),
        
        c(RTJ_LAKEWOOD_AZALEA_ID,
          "Lakewood Club (Azalea)",
          RTJ_LAKEWOOD_AZALEA_PARS,
          RTJ_LAKEWOOD_AZALEA_HCS,
          RTJ_LAKEWOOD_AZALEA_TEES,
          country: "USA",
          state: "AL",
          architect: "Robert Trent Jones, Sr.",
          type: "RTJ Trail",
          phone: "(251) 990-6312",
          website: "https://www.rtjgolf.com/lakewood/",
          address: "5910 Lakewood Dr, Point Clear, AL 36564"
        ),

        c(RTJ_LAKEWOOD_DOGWOOD_ID,
          "Lakewood Club (Dogwood)",
          RTJ_LAKEWOOD_DOGWOOD_PARS,
          RTJ_LAKEWOOD_DOGWOOD_HCS,
          RTJ_LAKEWOOD_DOGWOOD_TEES,
          country: "USA",
          state: "AL",
          architect: "Robert Trent Jones, Sr.",
          type: "RTJ Trail",
          phone: "(251) 990-6312",
          website: "https://www.rtjgolf.com/lakewood/",
          address: "5910 Lakewood Dr, Point Clear, AL 36564"
        ),
        c(RTJ_MAGNOLIA_GROVE_CROSSINGS_ID,
          "Magnolia Grove (Crossings)",
          RTJ_MAGNOLIA_GROVE_CROSSINGS_PARS,
          RTJ_MAGNOLIA_GROVE_CROSSINGS_HCS,
          RTJ_MAGNOLIA_GROVE_CROSSINGS_TEES,
          country: "USA",
          state: "AL",
          architect: "Robert Trent Jones, Sr.",
          type: "RTJ Trail",
          phone: "(251) 645-0075",
          website: "https://www.rtjgolf.com/magnoliagrove/",
          address: "7001 Magnolia Grove Pkwy, Mobile, AL 36618"
        ),

        c(RTJ_MAGNOLIA_GROVE_FALLS_ID,
          "Magnolia Grove (Falls)",
          RTJ_MAGNOLIA_GROVE_FALLS_PARS,
          RTJ_MAGNOLIA_GROVE_FALLS_HCS,
          RTJ_MAGNOLIA_GROVE_FALLS_TEES,
          country: "USA",
          state: "AL",
          architect: "Robert Trent Jones, Sr.",
          type: "RTJ Trail",
          phone: "(251) 645-0075",
          website: "https://www.rtjgolf.com/magnoliagrove/",
          address: "7001 Magnolia Grove Pkwy, Mobile, AL 36618"
        ),
        c(
            STEELWOOD_CC_GOLD_ID,
            "Steelwood Country Club",
            STEELWOOD_CC_GOLD_PARS,
            STEELWOOD_CC_GOLD_HCS,
            STEELWOOD_CC_GOLD_TEES,
            country: "USA",
            state: "AL",
            architect: "Jerry Pate",
            type: "Private",
            phone: "251.964.2005",
            website: "https://www.steelwoodcountryclub.com/",
            address: "17230 Dogwood Grove, Loxley, AL 36551"
        ),
        c(
            UUID(uuidString: "A1F0E3C2-1234-4F8B-9A11-ABCDEF123456")!,
            "Omni PGA Frisco (Fields Ranch East)",
            PGA_FRISCO_EAST_PARS,
            PGA_FRISCO_EAST_HCS,
            PGA_FRISCO_EAST_TEES,
            country: "USA",
            state: "TX",
            region: nil,
            architect: "Gil Hanse",
            type: "Resort",
            phone: "(800) 843-6664",
            website: "https://pgafrisco.com/",
            address: "3255 PGA Parkway, Frisco, TX",
            isWolfApproved: true,
            resortBrand: "Omni",
            promo: nil
        ),
        c(
            BARTON_CREEK_CANYONS_ID,
            "Omni Barton Creek (Fazio Canyons)",
            BARTON_CREEK_CANYONS_PARS,
            BARTON_CREEK_CANYONS_HCS,
            BARTON_CREEK_CANYONS_TEES,
            country: "USA",
            state: "TX",
            architect: "Tom Fazio",
            type: "Resort",
            phone: "(512) 329-4000",
            website: "https://www.omnihotels.com/hotels/austin-barton-creek/golf",
            address: "8212 Barton Club Dr, Austin, TX",
            isWolfApproved: true,
            resortBrand: "Omni",
            promo: nil
        ),
        
        c(
            BARTON_CREEK_CRENSHAW_ID,
            "Omni Barton Creek (Crenshaw Course)",
            BARTON_CREEK_CRENSHAW_PARS,
            BARTON_CREEK_CRENSHAW_HCS,
            BARTON_CREEK_CRENSHAW_TEES,
            country: "USA",
            state: "TX",
            architect: "Ben Crenshaw & Bill Coore",
            type: "Resort",
            phone: "(512) 329-4000",
            website: "https://www.omnihotels.com/hotels/austin-barton-creek/golf/crenshaw-course",
            address: "8212 Barton Club Dr, Austin, TX 78735",
            isWolfApproved: true,
            resortBrand: "Omni",
        ),
        c(
            BARTON_CREEK_PALMER_ID,
            "Omni Barton Creek (Palmer Lakeside)",
            BARTON_CREEK_PALMER_PARS,
            BARTON_CREEK_PALMER_HCS,
            BARTON_CREEK_PALMER_TEES,
            country: "USA",
            state: "TX",
            architect: "Arnold Palmer",
            type: "Resort",
            phone: "(512) 329-4000",
            website: "https://www.omnihotels.com/hotels/austin-barton-creek/golf",
            address: "1900 Clubhouse Hill Dr, Spicewood, TX",
            isWolfApproved: true,
            resortBrand: "Omni",
            promo: nil
        ),
        c(
            HOMESTEAD_CASCADES_ID,
            "Omni Homestead (Cascades)",
            HOMESTEAD_CASCADES_PARS,
            HOMESTEAD_CASCADES_HCS,
            HOMESTEAD_CASCADES_TEES,
            country: "USA",
            state: "VA",
            architect: "William S. Flynn",
            type: "Resort",
            phone: "(540) 839-1766",
            website: "https://www.omnihotels.com/hotels/homestead-virginia/golf/cascades-course",
            address: "1766 Homestead Dr, Hot Springs, VA 24445",
            isWolfApproved: true,
            resortBrand: "Omni",
            promo: nil
        ),
        c(
            BEDFORD_SPRINGS_OLD_ID,
            "Omni Bedford Springs (Old Course)",
            BEDFORD_SPRINGS_OLD_PARS,
            BEDFORD_SPRINGS_OLD_HCS,
            BEDFORD_SPRINGS_OLD_TEES,
            country: "USA",
            state: "PA",
            architect: "A.W. Tillinghast / Donald Ross",
            type: "Resort",
            phone: "(814) 623-8100",
            website: "https://www.omnihotels.com/hotels/bedford-springs/golf",
            address: "2138 Business Route 220, Bedford, PA 15522",
            isWolfApproved: true,
            resortBrand: "Omni",
            promo: nil
        ),
        c(
            HOMESTEAD_OLD_ID,
            "Omni Homestead (Old Course)",
            HOMESTEAD_OLD_PARS,
            HOMESTEAD_OLD_HCS,
            HOMESTEAD_OLD_TEES,
            country: "USA",
            state: "VA",
            architect: "William S. Flynn",
            type: "Resort",
            phone: "(540) 839-1766",
            website: "https://www.omnihotels.com/hotels/homestead-virginia/golf",
            address: "1766 Homestead Dr, Hot Springs, VA",
            isWolfApproved: true,
            resortBrand: "Omni",
            promo: nil
        ),
        c(
            OZARKS_NATIONAL_ID,
            "Ozarks National (Big Cedar)",
            OZARKS_NATIONAL_PARS,
            OZARKS_NATIONAL_HCS,
            OZARKS_NATIONAL_TEES,
            country: "USA",
            state: "MO",
            architect: "Bill Coore & Ben Crenshaw",
            type: "Resort",
            phone: "(800) 225-6343",
            website: "https://bigcedar.com/golf/ozarks-national/",
            address: "1250 Buffalo Ridge Blvd, Hollister, MO 65672",
            isWolfApproved: true,
            resortBrand: "Big Cedar",
            promo: nil
        ),
        c(
            BEAR_DANCE_ID,
            "Bear Dance Golf Club",
            BEAR_DANCE_PARS,
            BEAR_DANCE_HCS,
            BEAR_DANCE_TEES,
            country: "USA",
            state: "CO",
            architect: "Bear Dance (original design team)",
            type: "Public",
            phone: "(303) 681-4653",
            website: "https://beardancegolf.com",
            address: "6630 Bear Dance Dr, Larkspur, CO 80118",
            isWolfApproved: true,
            resortBrand: nil,
            promo: nil
        ),
        c(
            RIDGE_CASTLE_PINES_ID,
            "The Ridge at Castle Pines",
            RIDGE_CASTLE_PINES_PARS,
            RIDGE_CASTLE_PINES_HCS,
            RIDGE_CASTLE_PINES_TEES,
            country: "USA",
            state: "CO",
            architect: "Tom Weiskopf",
            type: "Public",
            phone: "(303) 688-0100",
            website: "https://playtheridge.com",
            address: "1414 Castle Pines Pkwy, Castle Pines, CO 80108",
            isWolfApproved: true,
            resortBrand: "Troon Golf",
            promo: nil
        ),
        c(
            FOSSIL_TRACE_ID,
            "Fossil Trace Golf Club",
            FOSSIL_TRACE_PARS,
            FOSSIL_TRACE_HCS,
            FOSSIL_TRACE_TEES,
            country: "USA",
            state: "CO",
            architect: "Jim Engh",
            type: "Public",
            phone: "(303) 277-8750",
            website: "https://fossiltrace.com",
            address: "3050 Illinois St, Golden, CO 80401",
            isWolfApproved: true,
            resortBrand: nil,
            promo: nil
        ),
        c(
            ARROWHEAD_BLACK_BEAR_ID,
            "Arrowhead Golf Club (Black Bear)",
            ARROWHEAD_BLACK_BEAR_PARS,
            ARROWHEAD_BLACK_BEAR_HCS,
            ARROWHEAD_BLACK_BEAR_TEES,
            country: "USA",
            state: "CO",
            architect: "Robert Trent Jones Jr.",
            type: "Public",
            phone: "(303) 973-9614",
            website: "https://arrowheadgolfclub.org",
            address: "10850 Sundown Trail, Littleton, CO 80125",
            isWolfApproved: true,
            resortBrand: nil,
            promo: nil
        ),
        c(
            ARROWHEAD_SOUTH_WEST_ID,
            "Arrowhead Golf Club (South / West)",
            ARROWHEAD_SOUTH_WEST_PARS,
            ARROWHEAD_SOUTH_WEST_HCS,
            ARROWHEAD_SOUTH_WEST_TEES,
            country: "USA",
            state: "IL",
            architect: "Not listed",
            type: "Public",
            phone: "(630) 653-5800",
            website: "https://arrowheadgolfclub.org",
            address: "26W151 Butterfield Rd, Wheaton, IL 60189",
            isWolfApproved: true,
            resortBrand: nil,
            promo: nil
        ),
        c(
            ARROWHEAD_WEST_EAST_ID,
            "Arrowhead Golf Club (West / East)",
            ARROWHEAD_WEST_EAST_PARS,
            ARROWHEAD_WEST_EAST_HCS,
            ARROWHEAD_WEST_EAST_TEES,
            country: "USA",
            state: "IL",
            architect: "Not listed",
            type: "Public",
            phone: "(630) 653-5800",
            website: "https://arrowheadgolfclub.org",
            address: "26W151 Butterfield Rd, Wheaton, IL 60189",
            isWolfApproved: true,
            resortBrand: nil,
            promo: nil
        ),
        c(
            PINEHURST_NO2_ID,
            "Pinehurst No. 2",
            PINEHURST_NO2_PARS,
            PINEHURST_NO2_HCS,
            PINEHURST_NO2_TEES,
            country: "USA",
            state: "NC",
            architect: "Donald Ross",
            type: "Resort",
            phone: "(855) 235-8507",
            website: "https://www.pinehurst.com/golf/courses/no-2/",
            address: "80 Carolina Vista Dr, Pinehurst, NC 28374",
            isWolfApproved: true,
            resortBrand: "Pinehurst Resort",
            promo: nil
        ),
        c(
            PINEHURST_NO4_ID,
            "Pinehurst No. 4",
            PINEHURST_NO4_PARS,
            PINEHURST_NO4_HCS,
            PINEHURST_NO4_TEES,
            country: "USA",
            state: "NC",
            architect: "Gil Hanse",
            type: "Resort",
            phone: "(855) 235-8507",
            website: "https://www.pinehurst.com/golf/courses/no-4/",
            address: "80 Carolina Vista Dr, Pinehurst, NC 28374",
            isWolfApproved: false,
            resortBrand: "Pinehurst Resort",
            promo: nil
        ),
        c(
            TOBACCO_ROAD_ID,
            "Tobacco Road Golf Club",
            TOBACCO_ROAD_PARS,
            TOBACCO_ROAD_HCS,
            TOBACCO_ROAD_TEES,
            country: "USA",
            state: "NC",
            architect: "Mike Strantz",
            type: "Public",
            phone: "(877) 284-3762",
            website: "https://tobaccoroadgolf.com",
            address: "442 Tobacco Rd, Sanford, NC 27332",
            isWolfApproved: false,
            resortBrand: nil,
            promo: nil
        ),
        c(
            SHADOW_CREEK_ID,
            "Shadow Creek",
            SHADOW_CREEK_PARS,
            SHADOW_CREEK_HCS,
            SHADOW_CREEK_TEES,
            country: "USA",
            state: "NV",
            architect: "Tom Fazio",
            type: "Resort",
            phone: "(702) 399-7111",
            website: "https://www.mgmresorts.com/en/things-to-do/shadow-creek-golf-course.html",
            address: "3 Shadow Creek Dr, North Las Vegas, NV 89081",
            isWolfApproved: false,
            resortBrand: "MGM Resorts",
            promo: nil
        ),
        c(
            PRIMLAND_HIGHLAND_ID,
            "Primland Resort – Highland Course",
            PRIMLAND_HIGHLAND_PARS,
            PRIMLAND_HIGHLAND_HCS,
            PRIMLAND_HIGHLAND_TEES,
            country: "USA",
            state: "VA",
            architect: "Donald Steel",
            type: "Resort",
            phone: "(866) 960-7746",
            website: "https://www.primland.com",
            address: "2000 Busted Rock Rd, Meadows of Dan, VA 24120",
            isWolfApproved: false
        ),
        c(
            BLACK_DESERT_RESORT_ID,
            "Black Desert Resort",
            BLACK_DESERT_RESORT_PARS,
            BLACK_DESERT_RESORT_HCS,
            BLACK_DESERT_RESORT_TEES,
            country: "USA",
            state: "UT",
            architect: "Tom Weiskopf",
            type: "Resort",
            phone: "(844) 237-8824",
            website: "https://www.blackdesertresort.com/golf",
            address: "1500 E Black Desert Dr, Ivins, UT 84738",
            isWolfApproved: false
        ),
        c(
            IRONWOOD_CC_SOUTH_ID,
            "Ironwood Country Club – South Course",
            IRONWOOD_CC_SOUTH_PARS,
            IRONWOOD_CC_SOUTH_HCS,
            IRONWOOD_CC_SOUTH_TEES,
            country: "USA",
            state: "CA",
            region: "Palm Springs",
            architect: "Desmond Muirhead",
            type: "Private",
            phone: "(760) 346-0551",
            website: "https://www.ironwoodcountryclub.com",
            address: "73735 Irontree Dr, Palm Desert, CA 92260",
            isWolfApproved: false
        ),
        c(
            IRONWOOD_CC_NORTH_ID,
            "Ironwood Country Club – North Course",
            IRONWOOD_CC_NORTH_PARS,
            IRONWOOD_CC_NORTH_HCS,
            IRONWOOD_CC_NORTH_TEES,
            country: "USA",
            state: "CA",
            region: "Palm Springs",
            architect: "Desmond Muirhead",
            type: "Private",
            phone: "(760) 346-0551",
            website: "https://www.ironwoodcountryclub.com",
            address: "73735 Irontree Dr, Palm Desert, CA 92260",
            isWolfApproved: false
        ),
        c(
            WYNN_GOLF_CLUB_ID,
            "Wynn Golf Club",
            WYNN_GOLF_CLUB_PARS,
            WYNN_GOLF_CLUB_HCS,
            WYNN_GOLF_CLUB_TEES,
            country: "USA",
            state: "NV",
            architect: "Tom Fazio",
            type: "Resort",
            phone: "(702) 770-7000",
            website: "https://www.wynnlasvegas.com",
            address: "3131 Las Vegas Blvd S, Las Vegas, NV 89109",
            isWolfApproved: false
        ),
        c(
            CASCATA_BLACK_ID,
            "Cascata",
            CASCATA_BLACK_PARS,
            CASCATA_BLACK_HCS,
            CASCATA_BLACK_TEES,
            country: "USA",
            state: "NV",
            architect: "Rees Jones",
            type: "Resort",
            phone: "(702) 294-2005",
            website: "https://golfcascata.com",
            address: "1 Cascata Drive, Boulder City, NV 89005",
            isWolfApproved: false
    
        ),
        c(
            PAIUTE_WOLF_ID,
            "Las Vegas Paiute Golf Resort – The Wolf",
            PAIUTE_WOLF_PARS,
            PAIUTE_WOLF_HCS,
            PAIUTE_WOLF_TEES,
            country: "USA",
            state: "NV",
            architect: "Pete Dye",
            type: "Resort",
            phone: "(800) 711-2833",
            website: "https://www.lvpaiutegolf.com",
            address: "10325 Nu-Wav Kaiv Blvd, Las Vegas, NV 89124",
            isWolfApproved: false
        ),
        // MARK: - Bali Hai Golf Club

        c(
            BALI_HAI_GC_ID,
            "Bali Hai Golf Club",
            BALI_HAI_GC_PARS,
            BALI_HAI_GC_HCS,
            BALI_HAI_GC_TEES,
            country: "USA",
            state: "NV",
            architect: "Schmidt & Curley",
            type: "Resort",
            phone: "(702) 597-2400",
            website: "https://www.balihaigolfclub.com",
            address: "5160 Las Vegas Blvd S, Las Vegas, NV 89119",
            isWolfApproved: true
        ),

        // MARK: - Bear's Best Las Vegas

        c(
            BEARS_BEST_LV_ID,
            "Bear's Best Las Vegas",
            BEARS_BEST_LV_PARS,
            BEARS_BEST_LV_HCS,
            BEARS_BEST_LV_TEES,
            country: "USA",
            state: "NV",
            architect: "Jack Nicklaus",
            type: "Resort",
            phone: "(702) 804-8500",
            website: "https://nicklausdesign.com/course/bearsbestlasvegas/",
            address: "11111 W Flamingo Rd, Las Vegas, NV 89135",
            isWolfApproved: true
        ),

        // MARK: - Reflection Bay Golf Club

        c(
            REFLECTION_BAY_GC_ID,
            "Reflection Bay Golf Club",
            REFLECTION_BAY_GC_PARS,
            REFLECTION_BAY_GC_HCS,
            REFLECTION_BAY_GC_TEES,
            country: "USA",
            state: "NV",
            architect: "Jack Nicklaus",
            type: "Resort",
            phone: "(702) 740-4653",
            website: "https://reflectionbaygolf.com",
            address: "75 Montelago Blvd, Henderson, NV 89011",
            isWolfApproved: true
        ),
        // MARK: - Revere Golf Club - Lexington

        c(
            REVERE_LEXINGTON_ID,
            "Revere Golf Club - Lexington",
            REVERE_LEXINGTON_PARS,
            REVERE_LEXINGTON_HCS,
            REVERE_LEXINGTON_TEES,
            country: "USA",
            state: "NV",
            type: "Daily-Fee",
            phone: "(877) 273-8373",
            website: "https://reveregolf.com",
            address: "2600 Hampton Rd, Henderson, NV 89052",
            isWolfApproved: true
        ),

        // MARK: - Revere Golf Club - Concord

        c(
            REVERE_CONCORD_ID,
            "Revere Golf Club - Concord",
            REVERE_CONCORD_PARS,
            REVERE_CONCORD_HCS,
            REVERE_CONCORD_TEES,
            country: "USA",
            state: "NV",
            type: "Daily-Fee",
            phone: "(877) 273-8373",
            website: "https://reveregolf.com",
            address: "2600 Hampton Rd, Henderson, NV 89052",
            isWolfApproved: true
        ),

        // MARK: - Cascata - Serket

        c(
            CASCATA_SERKET_ID,
            "Cascata - Serket",
            CASCATA_SERKET_PARS,
            CASCATA_SERKET_HCS,
            CASCATA_SERKET_TEES,
            country: "USA",
            state: "NV",
            architect: "Rees Jones",
            type: "Resort",
            website: "https://cascata.com",
            isWolfApproved: true
        ),
        c(
            TPC_SUMMERLIN_ID,
            "TPC Summerlin",
            TPC_SUMMERLIN_PARS,
            TPC_SUMMERLIN_HCS,
            TPC_SUMMERLIN_TEES,
            country: "USA",
            state: "NV",
            architect: "Bobby Weed",
            type: "Private",
            phone: "(702) 256-0111",
            website: "https://tpc.com/summerlin",
            address: "1700 Village Center Cir, Las Vegas, NV 89134",
            isWolfApproved: true
        ),
        c(
            TPC_LAS_VEGAS_ID,
            "TPC Las Vegas",
            TPC_LAS_VEGAS_PARS,
            TPC_LAS_VEGAS_HCS,
            TPC_LAS_VEGAS_TEES,
            country: "USA",
            state: "NV",
            architect: "Bobby Weed / Raymond Floyd",
            type: "Resort",
            phone: "(702) 256-2000",
            website: "https://tpc.com/lasvegas",
            address: "9851 Canyon Run Dr, Las Vegas, NV 89144",
            isWolfApproved: false
        ),
        c(
            TRUMP_DORAL_BLUE_ID,
            "Trump National Doral (Blue Monster)",
            TRUMP_DORAL_BLUE_PARS,
            TRUMP_DORAL_BLUE_HCS,
            TRUMP_DORAL_BLUE_TEES,
            country: "USA",
            state: "FL",
            architect: "Dick Wilson / Gil Hanse redesign",
            type: "Resort",
            phone: "(305) 592-2000",
            website: "https://www.trumphotels.com/miami/golf",
            address: "4400 NW 87th Ave, Miami, FL 33178",
            isWolfApproved: false
        ),
        c(
            TRUMP_INTL_WEST_PALM_CHAMPIONSHIP_ID,
            "Trump International Golf Club - Championship",
            TRUMP_INTL_WEST_PALM_CHAMPIONSHIP_PARS,
            TRUMP_INTL_WEST_PALM_CHAMPIONSHIP_HCS,
            TRUMP_INTL_WEST_PALM_CHAMPIONSHIP_TEES,
            country: "USA",
            state: "FL",
            architect: "Jim Fazio",
            type: "Private",
            phone: "(561) 973-1550",
            website: "https://www.trump.com",
            address: "3505 Summit Blvd, West Palm Beach, FL 33406",
            isWolfApproved: false
        ),

        c(
            TRUMP_NATIONAL_JUPITER_ID,
            "Trump National Golf Club Jupiter",
            TRUMP_NATIONAL_JUPITER_PARS,
            TRUMP_NATIONAL_JUPITER_HCS,
            TRUMP_NATIONAL_JUPITER_TEES,
            country: "USA",
            state: "FL",
            architect: "Jack Nicklaus",
            type: "Private",
            phone: "(561) 691-8700", // standard club line (not in image but correct)
            website: "https://www.trump.com",
            address: "115 Eagle Tree Terrace, Jupiter, FL 33477",
            isWolfApproved: false
        ),

       

        c(
            TRUMP_COLTS_NECK_ID,
            "Trump National Golf Club - Colts Neck",
            TRUMP_COLTS_NECK_PARS,
            TRUMP_COLTS_NECK_HCS,
            TRUMP_COLTS_NECK_TEES,
            country: "USA",
            state: "NJ",
            architect: "Jerry Pate",
            type: "Private",
            phone: "(732) 305-9250",
            website: "https://www.trump.com",
            address: "1 Trump National Blvd, Colts Neck, NJ 07722",
            isWolfApproved: false
        ),

        c(
            TRUMP_NATIONAL_PHILLY_ID,
            "Trump National GC - Philadelphia",
            TRUMP_NATIONAL_PHILLY_PARS,
            TRUMP_NATIONAL_PHILLY_HCS,
            TRUMP_NATIONAL_PHILLY_TEES,
            country: "USA",
            state: "NJ",
            architect: "Tom Fazio",
            type: "Private",
            phone: "(856) 754-2160",
            website: "https://www.trump.com",
            address: "500 W Branch Ave, Pine Hill, NJ 08021",
            isWolfApproved: false
        ),
        c(
            TRUMP_NATIONAL_WESTCHESTER_ID,
            "Trump National Golf Club (Westchester)",
            TRUMP_NATIONAL_WESTCHESTER_PARS,
            TRUMP_NATIONAL_WESTCHESTER_HCS,
            TRUMP_NATIONAL_WESTCHESTER_TEES,
            country: "USA",
            state: "NY",
            architect: "Jim Fazio",
            type: "Private",
            phone: "(914) 944-0900",
            website: "https://www.trump.com",
            address: "100 Shadow Tree Ln, Briarcliff Manor, NY 10510",
            isWolfApproved: false,
            resortBrand: "Trump",
            promo: nil
        ),
        c(
            TRUMP_BEDMINSTER_OLD_ID,
            "Trump National Golf Club (Bedminster - Old Course)",
            TRUMP_BEDMINSTER_OLD_PARS,
            TRUMP_BEDMINSTER_OLD_HCS,
            TRUMP_BEDMINSTER_OLD_TEES,
            country: "USA",
            state: "NJ",
            architect: "Tom Fazio",
            type: "Private",
            phone: "(908) 470-4400",
            website: "https://www.trump.com",
            address: "900 Lamington Rd, Bedminster, NJ 07921",
            isWolfApproved: false
        ),
        c(
            TRUMP_BEDMINSTER_NEW_ID,
            "Trump National Golf Club (Bedminster - New Course)",
            TRUMP_BEDMINSTER_NEW_PARS,
            TRUMP_BEDMINSTER_NEW_HCS,
            TRUMP_BEDMINSTER_NEW_TEES,
            country: "USA",
            state: "NJ",
            architect: "Tom Fazio",
            type: "Private",
            phone: "(908) 470-4400",
            website: "https://www.trump.com",
            address: "900 Lamington Rd, Bedminster, NJ 07921",
            isWolfApproved: false,
            resortBrand: "Trump",
            promo: nil
        ),
        c(
            TRUMP_NATIONAL_HUDSON_VALLEY_ID,
            "Trump National Golf Club (Hudson Valley)",
            TRUMP_NATIONAL_HUDSON_VALLEY_PARS,
            TRUMP_NATIONAL_HUDSON_VALLEY_HCS,
            TRUMP_NATIONAL_HUDSON_VALLEY_TEES,
            country: "USA",
            state: "NY",
            architect: nil,
            type: "Private",
            phone: "(703) 444-4801",
            website: "https://www.trump.com",
            address: "178 Stormville Rd, Hopewell Junction, NY 12533",
            isWolfApproved: false,
            resortBrand: "Trump",
            promo: nil
        ),

        c(
            TRUMP_NATIONAL_LOS_ANGELES_ID,
            "Trump National Golf Club (Los Angeles)",
            TRUMP_NATIONAL_LOS_ANGELES_PARS,
            TRUMP_NATIONAL_LOS_ANGELES_HCS,
            TRUMP_NATIONAL_LOS_ANGELES_TEES,
            country: "USA",
            state: "CA",
            region: "SoCal",
            architect: "Pete Dye",
            type: "Semi-Private",
            phone: "(310) 870-9560",
            website: "https://www.trumpnationallosangeles.com",
            address: "One Trump National Dr, Rancho Palos Verdes, CA 90275",
            isWolfApproved: false,
            resortBrand: "Trump",
            promo: nil
        ),
        c(
            TRUMP_NATIONAL_CHARLOTTE_ID,
            "Trump National Golf Club (Charlotte)",
            TRUMP_NATIONAL_CHARLOTTE_PARS,
            TRUMP_NATIONAL_CHARLOTTE_HCS,
            TRUMP_NATIONAL_CHARLOTTE_TEES,
            country: "USA",
            state: "NC",
            architect: "Greg Norman",
            type: "Private",
            phone: "(980) 514-1860",
            website: "https://www.trumpnationalcharlotte.com",
            address: "120 Trump Sq, Mooresville, NC 28117",
            isWolfApproved: false,
            resortBrand: "Trump",
            promo: nil
        ),

        c(
            TRUMP_NATIONAL_WASHINGTON_DC_CHAMPIONSHIP_ID,
            "Trump National Golf Club (Washington D.C. - Championship)",
            TRUMP_NATIONAL_WASHINGTON_DC_CHAMPIONSHIP_PARS,
            TRUMP_NATIONAL_WASHINGTON_DC_CHAMPIONSHIP_HCS,
            TRUMP_NATIONAL_WASHINGTON_DC_CHAMPIONSHIP_TEES,
            country: "USA",
            state: "VA",
            architect: "Tom Fazio",
            type: "Private",
            phone: "(703) 444-4801",
            website: "https://www.trumpnationaldc.com",
            address: "20391 Lowes Island Blvd, Sterling, VA 20165",
            isWolfApproved: false,
            resortBrand: "Trump",
            promo: nil
        ),

        c(
            BALLYS_FERRY_POINT_ID,
            "Bally's Golf Links at Ferry Point",
            BALLYS_FERRY_POINT_PARS,
            BALLYS_FERRY_POINT_HCS,
            BALLYS_FERRY_POINT_TEES,
            country: "USA",
            state: "NY",
            architect: "Jack Nicklaus",
            type: "Daily-Fee",
            phone: "(718) 414-1555",
            website: "https://casinos.ballys.com/golf-links-ferry-point",
            address: "500 Hutchinson River Pkwy, Bronx, NY 10465",
            isWolfApproved: false,
            resortBrand: "Bally's",
            promo: nil
        ),
        c(
            OLD_MEMORIAL_ID,
            "Old Memorial Golf Club",
            OLD_MEMORIAL_PARS,
            OLD_MEMORIAL_HCS,
            OLD_MEMORIAL_TEES,
            country: "USA",
            state: "FL",
            architect: "Steve Smyers",
            type: "Private",
            phone: nil,
            website: "https://www.oldmemorialgolfclub.com",
            address: "13600 Hixon Rd, Tampa, FL 33626",
            isWolfApproved: false
        ),
        c(
            CONCESSION_GC_ID,
            "The Concession Golf Club",
            CONCESSION_GC_PARS,
            CONCESSION_GC_HCS,
            CONCESSION_GC_TEES,
            country: "USA",
            state: "FL",
            architect: "Jack Nicklaus / Tony Jacklin",
            type: "Private",
            phone: "(941) 322-1461",
            website: "https://www.theconcession.com",
            address: "7700 Lindrick Ln, Bradenton, FL 34202",
            isWolfApproved: false
        ),
        c(
            INNISBROOK_COPPERHEAD_ID,
            "Innisbrook Resort (Copperhead)",
            INNISBROOK_COPPERHEAD_PARS,
            INNISBROOK_COPPERHEAD_HCS,
            INNISBROOK_COPPERHEAD_TEES,
            country: "USA",
            state: "FL",
            architect: "Larry Packard",
            type: "Resort",
            phone: "(800) 492-6899",
            website: "https://www.innisbrookgolfresort.com",
            address: "36750 US Highway 19 N, Palm Harbor, FL 34684",
            isWolfApproved: true
        ),
        c(
            FLORIDIAN_NATIONAL_ID,
            "Floridian National Golf Club",
            FLORIDIAN_NATIONAL_PARS,
            FLORIDIAN_NATIONAL_HCS,
            FLORIDIAN_NATIONAL_TEES,
            country: "USA",
            state: "FL",
            architect: "Tom Fazio",
            type: "Private",
            phone: "(772) 781-1000",
            website: "https://floridian.cc",
            address: "14020 NW Gilson Rd, Palm City, FL 34990",
            isWolfApproved: true
        ),
        c(
            INVERNESS_GC_ID,
            "Inverness Golf Club",
            INVERNESS_GC_PARS,
            INVERNESS_GC_HCS,
            INVERNESS_GC_TEES,
            country: "USA",
            state: "IL",
            architect: "Donald Ross",
            type: "Private",
            phone: "(847) 358-2340",
            website: "https://invernessgolfclub.org",
            address: "102 N Roselle Rd, Inverness, IL 60067",
            isWolfApproved: true,
            resortBrand: nil,
            promo: nil
        ),
       
        c(
            WYNSTONE_GC_ID,
            "Wynstone Golf Club",
            WYNSTONE_GC_PARS,
            WYNSTONE_GC_HCS,
            WYNSTONE_GC_TEES,
            country: "USA",
            state: "IL",
            region: nil,
            architect: "Jack Nicklaus",
            type: "Private",
            phone: "(847) 304-2800",
            website: "https://www.wynstone.org",
            address: "1 South Wynstone Drive, North Barrington, IL 60010",
            isWolfApproved: true,
            resortBrand: nil,
            promo: nil
        ),
        c(
            SHINGLE_CREEK_GC_ID,
            "Shingle Creek Golf Club",
            SHINGLE_CREEK_GC_PARS,
            SHINGLE_CREEK_GC_HCS,
            SHINGLE_CREEK_GC_TEES,
            country: "USA",
            state: "FL",
            architect: "Arnold Palmer Design Company",
            type: "Resort",
            phone: "(407) 996-1559",
            website: "https://www.shinglecreekgolf.com",
            address: "9939 Universal Blvd, Orlando, FL 32819",
            isWolfApproved: true,
            resortBrand: "Omni",
        ),
        c(
            TPC_SCOTTSDALE_CHAMPIONS_ID,
            "TPC Scottsdale (Champions Course)",
            TPC_SCOTTSDALE_CHAMPIONS_PARS,
            TPC_SCOTTSDALE_CHAMPIONS_HCS,
            TPC_SCOTTSDALE_CHAMPIONS_TEES,
            country: "USA",
            state: "AZ",
            region: "Scottsdale",
            architect: "Randy Heckenkemper",
            type: "Public",
            isWolfApproved: true
        ),
        c(
            TPC_SCOTTSDALE_STADIUM_ID,
            "TPC Scottsdale (Stadium Course)",
            TPC_SCOTTSDALE_STADIUM_PARS,
            TPC_SCOTTSDALE_STADIUM_HCS,
            TPC_SCOTTSDALE_STADIUM_TEES,
            country: "USA",
            state: "AZ",
            region: "Scottsdale",
            architect: "Jay Morrish and Tom Weiskopf",
            type: "Public",
            isWolfApproved: true
        ),
        c(
            TALKING_STICK_PIIPAASH_ID,
            "Talking Stick Golf Club (Piipaash Course)",
            TALKING_STICK_PIIPAASH_PARS,
            TALKING_STICK_PIIPAASH_HCS,
            TALKING_STICK_PIIPAASH_TEES,
            country: "USA",
            state: "AZ",
            region: "Scottsdale",
            architect: "Bill Coore and Ben Crenshaw",
            type: "Resort",
            phone: "(480) 860-2221",
            website: "https://www.talkingstickgolfclub.com/",
            address: "9998 E Talking Stick Way, Scottsdale, AZ 85256",
            isWolfApproved: true
        ),
        c(
            TALKING_STICK_ODHAM_ID,
            "Talking Stick Golf Club (O’odham Course)",
            TALKING_STICK_ODHAM_PARS,
            TALKING_STICK_ODHAM_HCS,
            TALKING_STICK_ODHAM_TEES,
            country: "USA",
            state: "AZ",
            architect: "Bill Coore & Ben Crenshaw",
            type: "Resort",
            phone: "(480) 860-2221",
            website: "https://talkingstickgolfclub.com/",
            address: "9998 E Talking Stick Way, Scottsdale, AZ 85256",
            isWolfApproved: true,
            resortBrand: "Talking Stick",
            promo: nil
        ),
        c(
            KIERLAND_ACACIA_MESQUITE_ID,
            "Kierland Golf Club (Acacia / Mesquite)",
            KIERLAND_ACACIA_MESQUITE_PARS,
            KIERLAND_ACACIA_MESQUITE_HCS,
            KIERLAND_ACACIA_MESQUITE_TEES,
            country: "USA",
            state: "AZ",
            region: "Scottsdale",
            architect: "Scott Miller",
            type: "Resort",
            phone: "(480) 922-9283",
            website: "https://www.kierlandgolf.com/",
            address: "15636 N Clubgate Dr, Scottsdale, AZ 85254",
            isWolfApproved: true
        ),
        c(
            KIERLAND_IRONWOOD_ACACIA_ID,
            "Kierland Golf Club (Ironwood / Acacia)",
            KIERLAND_IRONWOOD_ACACIA_PARS,
            KIERLAND_IRONWOOD_ACACIA_HCS,
            KIERLAND_IRONWOOD_ACACIA_TEES,
            country: "USA",
            state: "AZ",
            region: "Scottsdale",
            architect: "Scott Miller",
            type: "Resort",
            phone: "(480) 922-9283",
            website: "https://www.kierlandgolf.com/",
            address: "15636 N Clubgate Dr, Scottsdale, AZ 85254",
            isWolfApproved: true
        ),
        c(
            KIERLAND_IRONWOOD_MESQUITE_ID,
            "Kierland Golf Club (Ironwood / Mesquite)",
            KIERLAND_IRONWOOD_MESQUITE_PARS,
            KIERLAND_IRONWOOD_MESQUITE_HCS,
            KIERLAND_IRONWOOD_MESQUITE_TEES,
            country: "USA",
            state: "AZ",
            region: "Scottsdale",
            architect: "Scott Miller",
            type: "Resort",
            phone: "(480) 922-9283",
            website: "https://www.kierlandgolf.com/",
            address: "15636 N Clubgate Dr, Scottsdale, AZ 85254",
            isWolfApproved: true
        ),
        c(
            CAMELBACK_AMBIENTE_ID,
            "Camelback Golf Club (Ambiente)",
            CAMELBACK_AMBIENTE_PARS,
            CAMELBACK_AMBIENTE_HCS,
            CAMELBACK_AMBIENTE_TEES,
            country: "USA",
            state: "AZ",
            region: "Scottsdale",
            architect: "Jason Straka",
            type: "Resort",
            phone: "(480) 905-7902",
            website: "https://www.camelbackgolf.com/",
            address: "7847 N Mockingbird Ln, Scottsdale, AZ 85253",
            isWolfApproved: true
        ),

        c(
            CAMELBACK_PADRE_ID,
            "Camelback Golf Club (Padre)",
            CAMELBACK_PADRE_PARS,
            CAMELBACK_PADRE_HCS,
            CAMELBACK_PADRE_TEES,
            country: "USA",
            state: "AZ",
            region: "Scottsdale",
            architect: "Arthur Hills",
            type: "Resort",
            phone: "(480) 905-7902",
            website: "https://www.camelbackgolf.com/",
            address: "7847 N Mockingbird Ln, Scottsdale, AZ 85253",
            isWolfApproved: true
        ),
        c(
            BOULDERS_NORTH_ID,
            "The Boulders (North Course)",
            BOULDERS_NORTH_PARS,
            BOULDERS_NORTH_HCS,
            BOULDERS_NORTH_TEES,
            country: "USA",
            state: "AZ",
            region: "Scottsdale",
            architect: "Jay Morrish",
            type: "Resort",
            phone: "(480) 488-9028",
            website: "https://www.theboulders.com/",
            address: "34631 N Tom Darlington Dr, Carefree, AZ 85377",
            isWolfApproved: true
        ),

        c(
            BOULDERS_SOUTH_ID,
            "The Boulders (South Course)",
            BOULDERS_SOUTH_PARS,
            BOULDERS_SOUTH_HCS,
            BOULDERS_SOUTH_TEES,
            country: "USA",
            state: "AZ",
            region: "Scottsdale",
            architect: "Jay Morrish",
            type: "Resort",
            phone: "(480) 488-9028",
            website: "https://www.theboulders.com/",
            address: "34631 N Tom Darlington Dr, Carefree, AZ 85377",
            isWolfApproved: true
        ),
        c(
            AK_CHIN_SOUTHERN_DUNES_ID,
            "Ak-Chin Southern Dunes Golf Club",
            AK_CHIN_SOUTHERN_DUNES_PARS,
            AK_CHIN_SOUTHERN_DUNES_HCS,
            AK_CHIN_SOUTHERN_DUNES_TEES,
            country: "USA",
            state: "AZ",
            architect: "Fred Couples / Schmidt-Curley",
            type: "Daily-Fee",
            phone: "(480) 367-8949",
            website: "https://akchinsoutherndunes.com/",
            address: "48456 AZ-238, Maricopa, AZ 85139",
            isWolfApproved: true,
            resortBrand: "Troon",
            promo: nil
        ),
        c(
            QUINTERO_GC_ID,
            "Quintero Golf Club",
            QUINTERO_GC_PARS,
            QUINTERO_GC_HCS,
            QUINTERO_GC_TEES,
            country: "USA",
            state: "AZ",
            architect: "Rees Jones",
            type: "Daily-Fee",
            phone: "(928) 501-1500",
            website: "https://quinterogolf.com/",
            address: "16752 W State Route 74, Peoria, AZ 85383",
            isWolfApproved: true,
            resortBrand: nil,
            promo: nil
        ),
        c(
            AMERICAN_DUNES_ID,
            "American Dunes Golf Club",
            AMERICAN_DUNES_PARS,
            AMERICAN_DUNES_HCS,
            AMERICAN_DUNES_TEES,
            country: "USA",
            state: "MI",
            architect: "Jack Nicklaus",
            type: "Daily-Fee",
            phone: "(616) 842-4040",
            website: "https://americandunesgolfclub.com/",
            address: "17000 Lincoln Street, Grand Haven, MI 49417",
            isWolfApproved: true,
            resortBrand: nil,
            promo: nil
        ),
        c(
            GOLDEN_HORSESHOE_GOLD_ID,
            "Golden Horseshoe Golf Club (Gold Course)",
            GOLDEN_HORSESHOE_GOLD_PARS,
            GOLDEN_HORSESHOE_GOLD_HCS,
            GOLDEN_HORSESHOE_GOLD_TEES,
            country: "USA",
            state: "VA",
            architect: "Robert Trent Jones, Sr.",
            type: "Resort",
            phone: "(757) 565-8470",
            website: "https://www.colonialwilliamsburg.org/stay-play/recreation-wellness/golden-horseshoe-golf-club/gold-course/",
            address: "401 S England St, Williamsburg, VA 23185",
            isWolfApproved: true,
            resortBrand: nil,
            promo: nil
        ),
        c(
            POLO_FIELDS_ANN_ARBOR_ID,
            "Polo Fields Golf & Country Club",
            POLO_FIELDS_ANN_ARBOR_PARS,
            POLO_FIELDS_ANN_ARBOR_HCS,
            POLO_FIELDS_ANN_ARBOR_TEES,
            country: "USA",
            state: "MI",
            architect: "William Newcomb",
            type: "Private",
            phone: "(734) 998-1555",
            website: "https://polofieldsccmi.com/",
            address: "5200 Polo Fields Drive, Ann Arbor, MI 48103",
            isWolfApproved: true,
            resortBrand: nil,
            promo: nil
        ),
        c(
            LAWSONIA_LINKS_ID,
            "Lawsonia Links",
            LAWSONIA_LINKS_PARS,
            LAWSONIA_LINKS_HCS,
            LAWSONIA_LINKS_TEES,
            country: "USA",
            state: "WI",
            architect: "William Langford / Theodore Moreau",
            type: "Public",
            phone: "(920) 294-3320",
            website: "https://www.lawsonia.com/",
            address: "W2615 S Valley View Dr, Green Lake, WI 54941",
            isWolfApproved: true,
            resortBrand: nil,
            promo: nil
        ),
        c(
            PAAKO_RIDGE_1_18_ID,
            "Paako Ridge Golf Club (1–18)",
            PAAKO_RIDGE_1_18_PARS,
            PAAKO_RIDGE_1_18_HCS,
            PAAKO_RIDGE_TEES,
            country: "USA",
            state: "NM",
            architect: "Ken Dye",
            type: "Public",
            phone: "(505) 281-6000",
            website: "https://paakogolf.com/",
            address: "1 Club House Dr, Sandia Park, NM 87047",
            isWolfApproved: true,
            promo: nil
        ),
        c(
            PAAKO_RIDGE_10_27_ID,
            "Paako Ridge Golf Club (10–27)",
            PAAKO_RIDGE_10_27_PARS,
            PAAKO_RIDGE_10_27_HCS,
            PAAKO_RIDGE_TEES,
            country: "USA",
            state: "NM",
            architect: "Ken Dye",
            type: "Public",
            phone: "(505) 281-6000",
            website: "https://paakogolf.com/",
            address: "1 Club House Dr, Sandia Park, NM 87047",
            isWolfApproved: true,
            promo: nil
        ),
        c(
            TRINITY_FOREST_ID,
            "Trinity Forest Golf Club",
            TRINITY_FOREST_PARS,
            TRINITY_FOREST_HCS,
            TRINITY_FOREST_TEES,
            country: "USA",
            state: "TX",
            architect: "Bill Coore & Ben Crenshaw",
            type: "Private",
            phone: "(214) 646-3570",
            website: "https://trinityforestgc.com/",
            address: "5000 Great Trinity Forest Way, Dallas, TX 75217",
            isWolfApproved: true
        ),

        c(
            COLONIAL_CC_ID,
            "Colonial Country Club",
            COLONIAL_CC_PARS,
            COLONIAL_CC_HCS,
            COLONIAL_CC_TEES,
            country: "USA",
            state: "TX",
            architect: "John Bredemus / Perry Maxwell",
            type: "Private",
            phone: "(817) 927-4200",
            website: "https://colonialfw.com/",
            address: "3735 Country Club Circle, Fort Worth, TX 76109",
            isWolfApproved: false,
            resortBrand: nil,
            promo: nil
        ),
        c(
            DALLAS_NATIONAL_ID,
            "Dallas National Golf Club",
            DALLAS_NATIONAL_PARS,
            DALLAS_NATIONAL_HCS,
            DALLAS_NATIONAL_TEES,
            country: "USA",
            state: "TX",
            architect: "Tom Fazio",
            type: "Private",
            phone: "(214) 331-4195",
            website: "https://www.dallasnationalgolfclub.com/",
            address: "1515 Knoxville St, Dallas, TX 75211",
            isWolfApproved: false
        ),
        c(
            AUSTIN_CC_ID,
            "Austin Country Club",
            AUSTIN_CC_PARS,
            AUSTIN_CC_HCS,
            AUSTIN_CC_TEES,
            country: "USA",
            state: "TX",
            architect: "Pete Dye",
            type: "Private",
            phone: "(512) 328-0090",
            website: "https://austincountryclub.com/",
            address: "4408 Long Champ Dr, Austin, TX 78746",
            isWolfApproved: true
        ),
        c(
            WHISPERING_PINES_ID,
            "Whispering Pines Golf Club",
            WHISPERING_PINES_PARS,
            WHISPERING_PINES_HCS,
            WHISPERING_PINES_TEES,
            country: "USA",
            state: "TX",
            architect: "Chet Williams (Nicklaus Design)",
            type: "Private",
            phone: "(936) 594-4980",
            website: "https://whisperingpinesgolfclub.com/",
            address: "1532 Whispering Pines Dr, Trinity, TX 75862",
            isWolfApproved: true
        ),
        c(
            BLUEJACK_NATIONAL_ID,
            "Bluejack National",
            BLUEJACK_NATIONAL_PARS,
            BLUEJACK_NATIONAL_HCS,
            BLUEJACK_NATIONAL_TEES,
            country: "USA",
            state: "TX",
            architect: "Tiger Woods",
            type: "Private",
            phone: "(281) 475-2165",
            website: "https://bluejacknational.com/",
            address: "4430 S FM 1486, Montgomery, TX 77316",
            isWolfApproved: true
        ),
        c(
            VALHALLA_GOLD_ID,
            "Valhalla Golf Club",
            VALHALLA_GOLD_PARS,
            VALHALLA_GOLD_HCS,
            VALHALLA_GOLD_TEES,
            country: "USA",
            state: "KY",
            architect: "Jack Nicklaus",
            type: "Private",
            phone: "(502) 245-4475",
            website: "https://www.valhallagolfclub.com/",
            address: "15503 Shelbyville Rd, Louisville, KY 40245",
            isWolfApproved: true,
            resortBrand: nil,
            promo: nil
        ),
        c(
            AUDUBON_CARDINAL_ID,
            "Audubon Country Club",
            AUDUBON_CARDINAL_PARS,
            AUDUBON_CARDINAL_HCS,
            AUDUBON_CARDINAL_TEES,
            country: "USA",
            state: "KY",
            architect: "Tom Bendelow",
            type: "Private",
            phone: "(502) 636-1331",
            website: "https://www.auduboncc.org/",
            address: "3265 Robin Rd, Louisville, KY 40213",
            isWolfApproved: true,
            resortBrand: nil,
            promo: nil
        ),
        c(
            DOTHAN_COUNTRY_CLUB_ID,
            "Dothan Country Club",
            DOTHAN_COUNTRY_CLUB_PARS,
            DOTHAN_COUNTRY_CLUB_HCS,
            DOTHAN_COUNTRY_CLUB_TEES,
            country: "USA",
            state: "AL",
            architect: nil,
            type: "Private",
            phone: "(334) 792-6650",
            website: "https://www.dothancountryclub.com/",
            address: "200 South Cherokee Avenue, Dothan, AL 36301",
            isWolfApproved: true,
            resortBrand: nil,
            promo: nil
        ),
        ]
    
#if DEBUG
    private static func assertNoDuplicateIDs() {
        let ids = all.map(\.id)
        let counts = Dictionary(grouping: ids, by: { $0 })
        let dupes = counts
            .filter { $0.value.count > 1 }
            .map { "\($0.key.uuidString) x\($0.value.count)" }
            .sorted()

        precondition(dupes.isEmpty, "Duplicate BuiltInCourse IDs found:\n" + dupes.joined(separator: "\n"))
    }

    private static let _validated: Bool = {
        assertNoDuplicateIDs()
        return true
    }()
#endif

    static let ids: Set<UUID> = {
#if DEBUG
        _ = _validated
#endif
        return Set(all.map(\.id))
    }()

    @MainActor
    static var profiles: [CourseProfile] {
        all.map(profile(from:))
    }
}

// =======================================================
// MARK: - CourseLibrary
// =======================================================

final class CourseLibrary {
    static let shared = CourseLibrary()

    private let keyLibrary = "course.library.v1"
    private let keySelected = "course.selected.id.v1"

    private(set) var courses: [CourseProfile] = []

    private init() {
        load()
        seedBuiltIns()
    }

    func wolfMore() -> CourseProfile? {
        if let c = get(id: WOLFMORE_CC_ID) { return c }
        return courses.first { $0.name.caseInsensitiveCompare("WolfMore") == .orderedSame }
    }

    func allSorted() -> [CourseProfile] {
        courses.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func get(id: UUID) -> CourseProfile? {
        courses.first { $0.id == id }
    }

    func isBuiltIn(id: UUID) -> Bool {
        BuiltIns.ids.contains(id)
    }

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

    func seedIfNeeded() {
        seedBuiltIns()
    }

    func upsert(_ c: CourseProfile) {
        if let i = courses.firstIndex(where: { $0.id == c.id }) {
            courses[i] = mergedCourse(base: courses[i], incoming: c)
        } else if let j = courses.firstIndex(where: { $0.name.caseInsensitiveCompare(c.name) == .orderedSame }) {
            courses[j] = mergedCourse(base: courses[j], incoming: c)
        } else {
            courses.append(c)
        }
        save()
    }

    @discardableResult
    func delete(id: UUID) -> Bool {
        if isBuiltIn(id: id) { return false }

        if ProfileStore.homeCourseID == id.uuidString {
            ProfileStore.homeCourseID = ""
        }

        if selectedCourseID == id {
            selectedCourseID = wolfMore()?.id
        }

        let before = courses.count
        courses.removeAll { $0.id == id }
        let didDelete = courses.count != before

        if didDelete { save() }
        return didDelete
    }

    private func seedBuiltIns() {
        let builtIns = BuiltIns.profiles
        var changed = false

        for p in builtIns {
            changed = upsertBuiltIn(p) || changed
        }

        if changed { save() }
    }

    @discardableResult
    private func upsertBuiltIn(_ c: CourseProfile) -> Bool {
        if let i = courses.firstIndex(where: { $0.id == c.id }) {
            let merged = mergedCourse(base: courses[i], incoming: c)
            if courses[i] != merged {
                courses[i] = merged
                return true
            }
            return false
        }

        if let j = courses.firstIndex(where: { $0.name.caseInsensitiveCompare(c.name) == .orderedSame }) {
            let merged = mergedCourse(base: courses[j], incoming: c)
            if courses[j] != merged {
                courses[j] = merged
                return true
            }
            return false
        }

        courses.append(c)
        return true
    }

    private func mergedCourse(base: CourseProfile?, incoming: CourseProfile) -> CourseProfile {
        CourseProfile(
            id: base?.id ?? incoming.id,
            name: incoming.name,
            pars: incoming.pars,
            hcs: incoming.hcs,
            tees: incoming.tees ?? base?.tees,
            country: incoming.country ?? base?.country,
            state: incoming.state ?? base?.state,
            region: incoming.region ?? base?.region,
            architect: incoming.architect ?? base?.architect,
            type: incoming.type ?? base?.type,
            phone: incoming.phone ?? base?.phone,
            website: incoming.website ?? base?.website,
            address: incoming.address ?? base?.address,
            isWolfApproved: incoming.isWolfApproved ?? base?.isWolfApproved,
            venueType: incoming.venueType ?? base?.venueType,
            resortBrand: incoming.resortBrand ?? base?.resortBrand,
            promo: incoming.promo ?? base?.promo
        )
    }
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: keyLibrary) else { return }
        courses = (try? JSONDecoder().decode([CourseProfile].self, from: data)) ?? []
    }

    private func save() {
        let data = (try? JSONEncoder().encode(courses)) ?? Data()
        UserDefaults.standard.set(data, forKey: keyLibrary)
    }
    
}

// =======================================================
// MARK: - Grouping helpers
// =======================================================

extension CourseLibrary {

    struct LocationSection: Hashable {
        let isUSAState: Bool
        let title: String
        let sortKey: String
    }

    func coursesGroupedStateThenInternational() -> [(section: LocationSection, courses: [CourseProfile])] {
        let pairs: [(LocationSection, CourseProfile)] = courses.map { c in
            let country = (c.country ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let state = (c.state ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let isUSA = country.caseInsensitiveCompare("USA") == .orderedSame

            if isUSA, !state.isEmpty {
                let sec = LocationSection(
                    isUSAState: true,
                    title: state.uppercased(),
                    sortKey: state.uppercased()
                )
                return (sec, c)
            } else {
                let label = country.isEmpty ? "International" : country
                let sec = LocationSection(
                    isUSAState: false,
                    title: label,
                    sortKey: label.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                )
                return (sec, c)
            }
        }

        let grouped = Dictionary(grouping: pairs, by: { $0.0 })

        let sortedSections = grouped.keys.sorted {
            if $0.isUSAState != $1.isUSAState {
                return $0.isUSAState && !$1.isUSAState
            }
            return $0.sortKey.localizedCaseInsensitiveCompare($1.sortKey) == .orderedAscending
        }

        return sortedSections.map { sec in
            let list = (grouped[sec] ?? [])
                .map { $0.1 }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            return (sec, list)
        }
    }

    func stateThenInternationalTitles() -> [String] {
        coursesGroupedStateThenInternational().map { $0.section.title }
    }
}
extension CourseRouting {
    var displayName: String {
        switch self {
        case .eighteenStandard: return "Standard 18"
        case .loopAtoB: return "A → B"
        case .loopBtoC: return "B → C"
        case .loopAtoC: return "A → C"
        }
    }
}
