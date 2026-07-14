
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
    case nineStandard
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
private let EMPTY_PARS = [4,4,4,4,3,5,3,4,4,4,4,3,4,4,5,3,4,5]
private let EMPTY_HCS  = [4,8,14,10,16,2,18,6,12,11,3,15,1,13,7,17,9,5]
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
// MARK: Wilmette Golf Club
private let WILMETTE_GC_ID = UUID(uuidString: "77777701-0001-0001-0001-000000000001")!
let WILMETTE_GC_PARS: [Int] = [4,3,4,4,4,5,3,4,4, 4,4,3,4,4,4,3,5,4]   // par 70
let WILMETTE_GC_HCS:  [Int] = [9,17,1,5,15,3,13,11,7, 10,2,18,12,6,14,16,4,8]
let WILMETTE_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black",  yardage: 6363, rating: 70.8, slope: 128),
    TeeInfo(teeName: "Gold",   yardage: 6032, rating: 69.2, slope: 124),
    TeeInfo(teeName: "Orange", yardage: 5686, rating: 67.7, slope: 120),
    TeeInfo(teeName: "Green",  yardage: 4899, rating: 64.0, slope: 112),
    TeeInfo(teeName: "White",  yardage: 4668, rating: 63.0, slope: 109),
]

// MARK: Elgin Country Club (Blue)
private let ELGIN_CC_ID = UUID(uuidString: "e16100cc-0001-0001-0001-000000000001")!
let ELGIN_CC_PARS: [Int] = [5,4,4,3,4,3,4,5,3, 5,4,4,4,5,4,3,4,4]   // par 72
let ELGIN_CC_HCS:  [Int] = [12,14,10,8,2,16,4,6,18, 11,17,9,1,5,3,13,15,7]
let ELGIN_CC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue",  yardage: 6450, rating: 72.2, slope: 135),
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

// MARK: Twin Orchard CC — Long Grove, IL
private let TWIN_ORCHARD_RED_ID   = UUID(uuidString: "ACC00001-0001-0001-0001-000000000001")!
private let TWIN_ORCHARD_WHITE_ID = UUID(uuidString: "ACC00002-0002-0002-0002-000000000002")!

// Red Course — Par 72 | Member 72.0/136
let TWIN_ORCHARD_RED_PARS: [Int]  = [5,4,4,3,5,3,4,5,4, 4,3,5,3,4,4,4,4,4]
let TWIN_ORCHARD_RED_HCS:  [Int]  = [5,7,13,15,3,17,9,1,11, 10,18,4,16,14,6,2,12,8]
let TWIN_ORCHARD_RED_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Tips",          yardage: 6811, rating: 73.5, slope: 140),
    TeeInfo(teeName: "Championship",  yardage: 6716, rating: 73.1, slope: 139),
    TeeInfo(teeName: "Member",        yardage: 6460, rating: 72.0, slope: 136),
]

// White Course — Par 70 | Member 69.7/126
let TWIN_ORCHARD_WHITE_PARS: [Int] = [4,3,5,4,3,4,5,3,4, 4,5,4,4,3,3,5,3,4]
let TWIN_ORCHARD_WHITE_HCS:  [Int] = [9,13,3,1,17,15,5,11,7, 2,10,12,6,14,16,8,18,4]
let TWIN_ORCHARD_WHITE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship",  yardage: 5698, rating: 72.8, slope: 133),
    TeeInfo(teeName: "Member",        yardage: 6018, rating: 69.7, slope: 126),
    TeeInfo(teeName: "Forward",       yardage: 5086, rating: 65.4, slope: 116),
]

// MARK: ChampionsGate CC (Blended Black)
private let CHAMPIONGATE_BLENDED_BLACK_ID = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
let CHAMPIONGATE_BLENDED_BLACK_PARS: [Int] = [4,3,4,5,4,3,4,4,5, 5,3,4,4,3,4,4,4,5]
let CHAMPIONGATE_BLENDED_BLACK_HCS:  [Int] = [7,15,3,1,11,17,13,9,5, 14,18,2,10,16,6,8,4,12]


// MARK: Chicago Golf Club — Wheaton, IL

private let CHICAGO_GC_ID = UUID(uuidString: "B7A10000-0000-0000-0000-000000000126")!

let CHICAGO_GC_PARS: [Int] = [
    4,4,3,5,4,4,3,4,4,
    3,4,4,3,4,4,5,4,4
]

let CHICAGO_GC_HCS: [Int] = [
    5,3,17,1,13,9,15,7,11,
    16,6,4,18,14,10,2,12,8
]

let CHICAGO_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6950, rating: 74.4, slope: 141)
]

// MARK: Camargo Club — Cincinnati, OH (Indian Hill)
private let CAMARGO_CLUB_ID = UUID(uuidString: "B7A10000-0000-0000-0000-000000000127")!

let CAMARGO_CLUB_PARS: [Int] = [
    4,5,4,4,3,4,4,3,4,
    4,3,4,4,4,3,4,5,4
]

let CAMARGO_CLUB_HCS: [Int] = [
    17,5,13,1,15,7,3,11,9,
    2,18,4,16,10,14,8,12,6
]

let CAMARGO_CLUB_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Gold", yardage: 6655, rating: 71.6, slope: 130)
]

// MARK: - Tashua Knolls Golf Course
private let TASHUA_KNOLLS_CHAMPIONSHIP_ID = UUID(uuidString: "B7A10000-0000-0000-0000-000000000128")!
private let TASHUA_KNOLLS_BACK_ID         = UUID(uuidString: "B7A10000-0000-0000-0000-000000000130")!
private let TASHUA_KNOLLS_MIDDLE_ID       = UUID(uuidString: "B7A10000-0000-0000-0000-000000000131")!
private let TASHUA_KNOLLS_FORWARD_ID      = UUID(uuidString: "B7A10000-0000-0000-0000-000000000132")!

let TASHUA_KNOLLS_PARS: [Int] = [
    5, 4, 3, 4, 4, 3, 5, 4, 4,   // Front 9 (Out)
    4, 4, 3, 4, 5, 4, 5, 3, 4    // Back 9 (In)
]

let TASHUA_KNOLLS_HCS_CHAMPIONSHIP: [Int] = [
    5, 7, 17, 3, 11, 15, 1, 13, 9,
    12, 10, 16, 14, 6, 2, 4, 18, 8
]

let TASHUA_KNOLLS_HCS_BACK: [Int] = [
    3, 9, 15, 5, 11, 17, 1, 13, 7,
    8, 12, 18, 14, 6, 2, 4, 16, 10
]

let TASHUA_KNOLLS_HCS_MIDDLE: [Int] = [
    3, 7, 13, 5, 15, 17, 1, 9, 11,
    10, 12, 18, 14, 4, 6, 2, 16, 8
]

let TASHUA_KNOLLS_HCS_FORWARD: [Int] = [
    3, 15, 13, 5, 7, 17, 1, 9, 11,
    10, 12, 18, 14, 4, 6, 2, 16, 8
]

let TASHUA_KNOLLS_YARDS_CHAMPIONSHIP: [Int] = [
    561, 375, 167, 391, 370, 211, 501, 366, 378,
    373, 385, 163, 303, 506, 394, 527, 162, 407
]

let TASHUA_KNOLLS_YARDS_BACK: [Int] = [
    532, 317, 151, 342, 353, 192, 480, 354, 356,
    349, 367, 154, 262, 495, 373, 506, 145, 391
]

let TASHUA_KNOLLS_YARDS_MIDDLE: [Int] = [
    495, 302, 146, 325, 330, 155, 445, 324, 307,
    333, 327, 146, 250, 487, 330, 469, 140, 345
]

let TASHUA_KNOLLS_YARDS_FORWARD: [Int] = [
    420, 270, 115, 280, 316, 120, 395, 308, 307,
    286, 304, 142, 243, 404, 280, 415, 110, 335
]

// MARK: Tashua Glen Golf Course (9-hole) — Trumbull, CT
private let TASHUA_GLEN_ID = UUID(uuidString: "B7A10000-0000-0000-0000-000000000129")!

let TASHUA_GLEN_PARS: [Int] = [4,3,4,3,3,4,4,3,5]   // par 33
let TASHUA_GLEN_HCS:  [Int] = [1,2,3,4,5,6,7,8,9]

let TASHUA_GLEN_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 2184),
    TeeInfo(teeName: "Back",         yardage: 2036),
    TeeInfo(teeName: "Middle",       yardage: 1851),
    TeeInfo(teeName: "Forward",      yardage: 1664)
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
// MARK: Glen Oak Country Club — Glen Ellyn, IL
private let GLEN_OAK_CC_ID = UUID(uuidString: "B3C5D7E9-1F2A-4B3C-8D4E-5F6A7B8C9D0E")!

let GLEN_OAK_CC_PARS: [Int] = [
    4,4,3,4,5,3,5,4,4,
    5,3,4,4,4,4,3,5,4
]
let GLEN_OAK_CC_HCS: [Int] = [
    7,9,15,5,3,17,1,13,11,
    2,18,6,14,4,12,16,10,8
]
let GLEN_OAK_CC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 6841, rating: 73.2, slope: 139)
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

// MARK: Portmarnock Golf Club (Championship)
// Original 18 holes laid out 1894 by William C. Pickeman & George Coburn
private let PORTMARNOCK_CHAMPIONSHIP_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000027")!

let PORTMARNOCK_CHAMPIONSHIP_PARS: [Int] = [
    4,4,4,4,4,5,3,4,4,
    4,4,3,5,4,3,5,4,4
]

let PORTMARNOCK_CHAMPIONSHIP_HCS: [Int] = [
    11,15,13,1,5,9,17,7,3,
    8,6,16,14,2,12,18,4,10
]

let PORTMARNOCK_CHAMPIONSHIP_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue", yardage: 7466, rating: 70.0, slope: 110)
]

// MARK: Portmarnock Golf Club (Yellow Nine)
// 9-hole addition designed by Fred Hawtree (1971)
private let PORTMARNOCK_YELLOW_NINE_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000028")!

let PORTMARNOCK_YELLOW_NINE_PARS: [Int] = [4,4,3,3,5,4,5,3,5]

let PORTMARNOCK_YELLOW_NINE_HCS: [Int] = [3,5,17,11,15,1,7,9,13]

let PORTMARNOCK_YELLOW_NINE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue",  yardage: 3461, rating: 37.0),
    TeeInfo(teeName: "White", yardage: 3357, rating: 36.0),
    TeeInfo(teeName: "Green", yardage: 3240, rating: 35.5)
]

// MARK: Rosapenna – St. Patrick's Links (Tom Doak)
private let ROSAPENNA_ST_PATRICKS_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000029")!

let ROSAPENNA_ST_PATRICKS_PARS: [Int] = [
    4,4,3,5,3,5,4,4,4,
    4,4,5,4,4,3,4,3,4
]

let ROSAPENNA_ST_PATRICKS_HCS: [Int] = [
    9,11,17,5,13,7,3,15,1,
    8,6,4,12,10,18,2,14,16
]

let ROSAPENNA_ST_PATRICKS_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Sandstone", yardage: 6930, rating: 73.2, slope: 128),
    TeeInfo(teeName: "Slate",     yardage: 6490, rating: 71.0, slope: 125),
    TeeInfo(teeName: "Granite",   yardage: 5919)
]

// MARK: Rosapenna – Sandy Hills Links (Pat Ruddy)
private let ROSAPENNA_SANDY_HILLS_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000030")!

let ROSAPENNA_SANDY_HILLS_PARS: [Int] = [
    5,4,3,4,4,4,3,5,4,
    4,3,4,5,4,4,3,5,4
]

let ROSAPENNA_SANDY_HILLS_HCS: [Int] = [
    13,3,17,11,5,1,15,9,7,
    6,12,10,8,18,2,14,16,4
]

let ROSAPENNA_SANDY_HILLS_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6767, rating: 73.2, slope: 127),
    TeeInfo(teeName: "Blue",  yardage: 6312, rating: 71.0, slope: 121),
    TeeInfo(teeName: "White", yardage: 5890, rating: 68.9, slope: 117),
    TeeInfo(teeName: "Red",   yardage: 4828)
]

// MARK: Rosapenna – Old Tom Morris Links (1891)
private let ROSAPENNA_OLD_TOM_MORRIS_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000031")!

let ROSAPENNA_OLD_TOM_MORRIS_PARS: [Int] = [
    4,3,4,4,4,4,3,5,4,
    4,4,4,4,3,4,5,3,5
]

let ROSAPENNA_OLD_TOM_MORRIS_HCS: [Int] = [
    6,18,4,12,8,2,16,14,10,
    5,1,7,15,13,3,17,11,9
]

let ROSAPENNA_OLD_TOM_MORRIS_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6867, rating: 73.0, slope: 119),
    TeeInfo(teeName: "Blue",  yardage: 6495, rating: 71.0, slope: 116),
    TeeInfo(teeName: "White", yardage: 6064, rating: 69.0, slope: 113),
    TeeInfo(teeName: "Red",   yardage: 5150, rating: 71.0, slope: 117)
]

// MARK: The European Club — Brittas Bay, Co. Wicklow, Ireland (Pat Ruddy)
private let EUROPEAN_CLUB_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000037")!

let EUROPEAN_CLUB_PARS: [Int] = [
    4,3,5,4,4,3,4,4,4,
    4,4,4,5,3,4,4,4,4
]

let EUROPEAN_CLUB_HCS: [Int] = [
    8,18,16,3,5,14,1,10,12,
    2,9,6,15,17,13,11,4,7
]

let EUROPEAN_CLUB_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue", yardage: 7377, rating: 75.9, slope: 135)
]

// MARK: Ballinlough Castle Golf Club — Clonmellon, Co. Westmeath, Ireland (Pat Ruddy)
private let BALLINLOUGH_CASTLE_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000038")!

let BALLINLOUGH_CASTLE_PARS: [Int] = [
    4,4,3,4,3,5,4,4,4,
    4,4,4,4,4,4,3,4,3
]

let BALLINLOUGH_CASTLE_HCS: [Int] = [
    9,1,7,3,15,13,11,17,6,
    12,5,2,4,10,14,16,8,18
]

let BALLINLOUGH_CASTLE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "White", yardage: 5786)
]

// MARK: Ballyliffin Golf Club (Glashedy Links) — Inishowen, Co. Donegal, Ireland (Pat Ruddy)
private let BALLYLIFFIN_GLASHEDY_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000039")!

let BALLYLIFFIN_GLASHEDY_PARS: [Int] = [
    4,4,4,5,3,4,3,4,4,
    4,4,4,5,3,4,4,5,4
]

let BALLYLIFFIN_GLASHEDY_HCS: [Int] = [
    10,2,8,18,16,14,12,6,4,
    17,7,3,11,15,1,5,9,13
]

let BALLYLIFFIN_GLASHEDY_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7542),
    TeeInfo(teeName: "Gold",  yardage: 6847),
    TeeInfo(teeName: "White", yardage: 6363),
    TeeInfo(teeName: "Red",   yardage: 5610)
]

// MARK: Castlegregory Golf & Fishing Club — Co. Kerry, Ireland (Arthur Spring, 1989; 9-hole played twice)
private let CASTLEGREGORY_ID = UUID(uuidString: "D101A001-0000-0000-0000-00000000003A")!

let CASTLEGREGORY_PARS: [Int] = [
    5,3,4,4,3,4,4,4,3
]

let CASTLEGREGORY_HCS: [Int] = [
    11,7,17,3,9,15,1,5,13
]

let CASTLEGREGORY_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue",  yardage: 2877, rating: 34.0),
    TeeInfo(teeName: "White", yardage: 2766, rating: 33.5),
    TeeInfo(teeName: "Green", yardage: 2623, rating: 33.0),
    TeeInfo(teeName: "Red",   yardage: 2330, rating: 34.0)
]

// MARK: Castlecomer Golf Club — Castlecomer, Co. Kilkenny, Ireland (Pat Ruddy)
private let CASTLECOMER_ID = UUID(uuidString: "D101A001-0000-0000-0000-00000000003B")!

let CASTLECOMER_PARS: [Int] = [
    5,4,3,4,4,5,4,4,3,
    4,4,5,4,4,3,4,3,5
]

let CASTLECOMER_HCS: [Int] = [
    13,7,9,1,3,5,11,15,17,
    12,2,8,16,4,18,6,10,14
]

let CASTLECOMER_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue",  yardage: 6758, rating: 74.0),
    TeeInfo(teeName: "White", yardage: 6474, rating: 73.0),
    TeeInfo(teeName: "Green", yardage: 6160, rating: 72.0),
    TeeInfo(teeName: "Red",   yardage: 5487, rating: 74.0)
]

// MARK: Co. Tipperary Golf & Country Club (Dundrum House) — Dundrum, Co. Tipperary (Philip Walton & Ken Kearney)
private let CO_TIPPERARY_GCC_ID = UUID(uuidString: "D101A001-0000-0000-0000-00000000003C")!

let CO_TIPPERARY_GCC_PARS: [Int] = [
    4,4,3,4,4,3,5,4,4,
    4,5,3,5,4,4,4,4,4
]

let CO_TIPPERARY_GCC_HCS: [Int] = [
    16,8,10,18,14,6,4,12,2,
    3,9,17,7,11,15,13,5,1
]

let CO_TIPPERARY_GCC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "White", yardage: 7164, rating: 70.0, slope: 113)
]

// MARK: County Sligo Golf Club (Rosses Point) — H.S. Harry Colt (1927)
private let COUNTY_SLIGO_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000032")!

let COUNTY_SLIGO_PARS: [Int] = [
    4,4,5,3,5,4,4,4,3,
    4,4,5,3,4,4,3,4,4
]

let COUNTY_SLIGO_HCS: [Int] = [
    9,15,8,11,18,6,1,4,13,
    16,3,14,17,5,7,12,2,10
]

let COUNTY_SLIGO_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7157, rating: 74.3),
    TeeInfo(teeName: "White", yardage: 6574, rating: 71.9),
    TeeInfo(teeName: "Gold",  yardage: 6375, rating: 70.7),
    TeeInfo(teeName: "Green", yardage: 5918, rating: 74.7)
]

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
// MARK: Sunningdale Golf Club — New Course

private let SUNNINGDALE_NEW_ID = UUID(uuidString: "B7A10000-0000-0000-0000-000000000125")!

let SUNNINGDALE_NEW_PARS: [Int] = [
    4,3,4,4,3,5,4,4,4,
    3,4,4,5,3,4,4,3,5
]

let SUNNINGDALE_NEW_HCS: [Int] = [
    8,16,4,10,12,2,18,14,6,
    9,1,15,5,11,3,13,17,7
]

let SUNNINGDALE_NEW_TEES: [TeeInfo] = [
    TeeInfo(teeName: "White", yardage: 6444, rating: 70.0, slope: 113)
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
// MARK: Alwoodley Golf Club — Leeds, England

private let ALWOODLEY_GC_ID = UUID(uuidString: "B7A10000-0000-0000-0000-000000000123")!

let ALWOODLEY_GC_PARS: [Int] = [
    4,4,5,5,4,4,3,5,3,
    5,3,4,4,3,4,4,4,4
]

let ALWOODLEY_GC_HCS: [Int] = [
    14,6,10,3,16,8,18,1,12,
    5,17,2,11,9,15,4,13,7
]

let ALWOODLEY_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "White", yardage: 6673, rating: 70.0, slope: 113)
]

// MARK: Moortown Golf Club — Leeds, England

private let MOORTOWN_GC_ID = UUID(uuidString: "B7A10000-0000-0000-0000-000000000124")!

let MOORTOWN_GC_PARS: [Int] = [
    5,4,4,3,4,4,5,3,4,
    3,4,5,4,4,4,4,3,4
]

let MOORTOWN_GC_HCS: [Int] = [
    1,2,3,4,5,6,7,8,9,
    10,11,12,13,14,15,16,17,18
]

let MOORTOWN_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue", yardage: 7301, rating: 70.0, slope: 113)
]

// MARK: Carnoustie Golf Links — Carnoustie, Scotland

private let CARNOUSTIE_CHAMP_ID = UUID(uuidString: "1E2F3A4B-5C6D-4E7F-8A9B-0C1D2E3F4A5C")!

let CARNOUSTIE_CHAMP_PARS: [Int] = [
    4,4,4,4,4,5,4,3,4,
    4,4,5,4,3,5,4,3,4
]

let CARNOUSTIE_CHAMP_HCS: [Int] = [
    10,4,14,16,12,2,8,18,6,
    3,15,9,17,1,7,13,5,11
]

let CARNOUSTIE_CHAMP_TEES: [TeeInfo] = [
    TeeInfo(teeName: "White",  yardage: 6945, rating: 75.2, slope: 139),
    TeeInfo(teeName: "Yellow", yardage: 6589, rating: 73.6, slope: 135),
    TeeInfo(teeName: "Green",  yardage: 6139, rating: 71.5, slope: 130),
    TeeInfo(teeName: "Black",  yardage: 5610, rating: 69.1, slope: 126)
]

private let CARNOUSTIE_BURNSIDE_ID = UUID(uuidString: "2F3A4B5C-6D7E-4F8A-9B0C-1D2E3F4A5B6D")!

let CARNOUSTIE_BURNSIDE_PARS: [Int] = [
    4,4,3,4,3,4,4,4,3,
    4,4,4,4,3,5,3,4,4
]

let CARNOUSTIE_BURNSIDE_HCS: [Int] = [
    18,4,16,2,10,14,12,6,8,
    15,7,13,5,1,11,9,3,17
]

let CARNOUSTIE_BURNSIDE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "White",  yardage: 5943, rating: 69.5, slope: 125),
    TeeInfo(teeName: "Yellow", yardage: 5731, rating: 68.3, slope: 122),
    TeeInfo(teeName: "Green",  yardage: 5400, rating: 66.5, slope: 122),
    TeeInfo(teeName: "Black",  yardage: 4070, rating: 61.6, slope: 110)
]

private let CARNOUSTIE_BUDDON_ID = UUID(uuidString: "3A4B5C6D-7E8F-4A9B-0C1D-2E3F4A5B6C7E")!

let CARNOUSTIE_BUDDON_PARS: [Int] = [
    4,3,4,3,4,4,3,5,4,
    4,4,4,3,4,3,5,3,4
]

let CARNOUSTIE_BUDDON_HCS: [Int] = [
    6,16,8,18,14,4,12,2,10,
    1,7,9,13,3,17,11,15,5
]

let CARNOUSTIE_BUDDON_TEES: [TeeInfo] = [
    TeeInfo(teeName: "White",  yardage: 5921, rating: 69.0, slope: 120),
    TeeInfo(teeName: "Yellow", yardage: 5652, rating: 67.7, slope: 117),
    TeeInfo(teeName: "Green",  yardage: 5041, rating: 64.9, slope: 112),
    TeeInfo(teeName: "Black",  yardage: 4070, rating: 62.0, slope: 106)
]

// MARK: Kingsbarns Golf Links — St Andrews, Scotland

private let KINGSBARNS_ID = UUID(uuidString: "4B5C6D7E-8F9A-4B0C-1D2E-3F4A5B6C7D8F")!

let KINGSBARNS_PARS: [Int] = [
    4,3,5,4,4,4,4,3,5,
    4,4,5,3,4,3,5,4,4
]

let KINGSBARNS_HCS: [Int] = [
    13,9,15,3,7,11,1,17,5,
    14,10,2,12,18,6,16,8,4
]

let KINGSBARNS_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7226, rating: 0.0, slope: 0),
    TeeInfo(teeName: "White", yardage: 6853, rating: 0.0, slope: 0),
    TeeInfo(teeName: "Green", yardage: 6408, rating: 0.0, slope: 0),
    TeeInfo(teeName: "Blue",  yardage: 6057, rating: 0.0, slope: 0),
    TeeInfo(teeName: "Red",   yardage: 5231, rating: 0.0, slope: 0)
]

// MARK: Castle Stuart Golf Links — Inverness, Scotland

private let CASTLE_STUART_ID = UUID(uuidString: "5C6E7F8A-9B0C-4D1E-2F3A-4B5C6D7E8F9A")!

let CASTLE_STUART_PARS: [Int] = [
    4,5,4,3,4,5,4,3,4,
    4,3,5,4,4,4,4,3,5
]

let CASTLE_STUART_HCS: [Int] = [
    9,5,13,17,7,3,1,15,11,
    14,16,2,4,10,8,18,6,12
]

let CASTLE_STUART_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7009, rating: 74.1, slope: 141)
]

// MARK: Cruden Bay Golf Club — Cruden Bay, Scotland

private let CRUDEN_BAY_ID = UUID(uuidString: "6D7F8A9B-0C1D-4E2F-3A4B-5C6D7E8F9A0B")!

let CRUDEN_BAY_PARS: [Int] = [
    4,4,4,3,5,5,4,4,5,
    4,3,4,5,4,3,3,4,5
]

let CRUDEN_BAY_HCS: [Int] = [
    9,13,17,5,11,7,1,15,3,
    6,12,16,8,2,18,14,4,10
]

let CRUDEN_BAY_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6634, rating: 73.4, slope: 137),
    TeeInfo(teeName: "Gold",  yardage: 6250, rating: 71.7, slope: 130),
    TeeInfo(teeName: "White", yardage: 5868, rating: 69.8, slope: 124),
    TeeInfo(teeName: "Blue",  yardage: 5441, rating: 67.8, slope: 119),
    TeeInfo(teeName: "Green", yardage: 5002, rating: 65.8, slope: 115)
]

// MARK: Kings Links Golf Centre — Aberdeen, Scotland

private let KINGS_LINKS_ID = UUID(uuidString: "7E8F0A1B-2C3D-4E5F-6A7B-8C9D0E1F2A3B")!

let KINGS_LINKS_PARS: [Int] = [
    4,4,3,5,4,4,5,3,5,
    3,4,4,4,4,5,3,4,3
]

let KINGS_LINKS_HCS: [Int] = [
    11,3,17,9,13,2,7,15,5,
    12,6,18,8,1,10,16,4,14
]

let KINGS_LINKS_TEES: [TeeInfo] = [
    TeeInfo(teeName: "White", yardage: 6442, rating: 69.9, slope: 116)
]

private let PRESTWICK_GC_ID = UUID(uuidString: "CC3D4E5F-6A7B-4C3D-4E5F-6A7B8C9D0E1F")!

let PRESTWICK_GC_PARS: [Int] = [
    4,3,5,4,3,4,4,4,4,
    4,3,5,4,4,4,4,4,4
]

let PRESTWICK_GC_HCS: [Int] = [
    11,17,3,13,5,15,1,9,7,
    4,16,8,2,14,10,18,6,12
]

let PRESTWICK_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 6908, rating: 74.4, slope: 139)
]

private let WESTERN_GAILES_ID = UUID(uuidString: "DD4E5F6A-7B8C-4D4E-5F6A-7B8C9D0E1F2A")!

let WESTERN_GAILES_PARS: [Int] = [
    4,4,4,4,4,5,3,4,4,
    4,4,4,3,5,3,4,4,4
]

let WESTERN_GAILES_HCS: [Int] = [
    13,3,11,9,1,5,15,7,17,
    14,2,8,18,6,16,10,4,12
]

let WESTERN_GAILES_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 7014, rating: 75.3, slope: 144)
]

private let MACHRIHANISH_GC_ID = UUID(uuidString: "EE5F6A7B-8C9D-4E5F-6A7B-8C9D0E1F2A3B")!

let MACHRIHANISH_GC_PARS: [Int] = [
    4,4,4,3,4,4,4,4,4,
    5,3,5,4,4,3,3,4,4
]

let MACHRIHANISH_GC_HCS: [Int] = [
    3,7,11,18,5,13,2,9,15,
    10,8,6,12,1,16,4,14,17
]

let MACHRIHANISH_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 6226, rating: 71.0, slope: 130),
    TeeInfo(teeName: "Yellow", yardage: 5956, rating: 70.0, slope: 126)
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

// MARK: Royal Birkdale Golf Club — Southport, England

private let ROYAL_BIRKDALE_ID = UUID(uuidString: "C12A6D8E-1F44-4B7D-9E31-2A8C7F5D1008")!

let ROYAL_BIRKDALE_PARS: [Int] = [
    4,4,4,3,4,4,3,4,4,
    4,4,3,4,3,5,4,5,4
]

let ROYAL_BIRKDALE_HCS: [Int] = [
    11,3,7,15,13,1,17,9,5,
    14,8,16,4,18,2,12,6,10
]

let ROYAL_BIRKDALE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue",   yardage: 7170, rating: 70.0, slope: 110),
    TeeInfo(teeName: "White",  yardage: 6817),
    TeeInfo(teeName: "Yellow", yardage: 6381),
    TeeInfo(teeName: "Red",    yardage: 5793)
]

// MARK: The Renaissance Club — North Berwick, Scotland

private let RENAISSANCE_CLUB_ID = UUID(uuidString: "D23B7E9F-2055-4C8E-AF42-3B9D8A6E2110")!

let RENAISSANCE_CLUB_PARS: [Int] = [
    4,4,5,4,3,4,5,4,3,
    4,4,5,4,4,3,5,3,4
]

let RENAISSANCE_CLUB_HCS: [Int] = [
    7,3,5,13,15,17,9,1,11,
    10,18,6,14,2,8,16,12,4
]

let RENAISSANCE_CLUB_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Scottish Open", yardage: 7303, rating: 70.0, slope: 113)
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
// MARK: - Built-in: Southern Hills Country Club
// Tulsa, OK • Private • Perry Maxwell • 1936
// Blue: Par 71 | 7,196 yds | 76.0 / 144  (pre-2022 renovation)
// =======================================================

private let SOUTHERN_HILLS_CC_ID = UUID(uuidString: "507EB111-0001-4B5E-A2F0-000000000003")!

let SOUTHERN_HILLS_CC_PARS: [Int] = [
    4,4,4,5,5,3,4,3,4,
    4,3,4,5,3,4,5,3,4
]

let SOUTHERN_HILLS_CC_HCS: [Int] = [
    3,1,7,13,5,17,15,11,9,
    12,16,4,10,14,2,18,6,8
]

let SOUTHERN_HILLS_CC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue",  yardage: 7196, rating: 76.0, slope: 144),
    TeeInfo(teeName: "White", yardage: 6850, rating: 74.7, slope: 144),
    TeeInfo(teeName: "Gold",  yardage: 6179, rating: 73.0, slope: 138),
]

// =======================================================
// MARK: - Built-in: Oak Tree National
// Edmond, OK • Private • Pete Dye • 1976
// Black: Par 71 | 7,412 yds | 79.3 / 155
// Host: 1988 PGA Championship, 2027 US Senior Open
// =======================================================

private let OAK_TREE_NATIONAL_ID = UUID(uuidString: "0A5B00DE-0001-4B5E-A2F0-000000000005")!

let OAK_TREE_NATIONAL_PARS: [Int] = [
    4,4,5,3,5,4,4,3,4,
    4,4,4,3,4,4,5,3,4
]

let OAK_TREE_NATIONAL_HCS: [Int] = [
    3,13,1,11,7,17,5,15,9,
    12,2,6,18,8,4,16,14,10
]

let OAK_TREE_NATIONAL_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7412, rating: 79.3, slope: 155),
]

// =======================================================
// MARK: - Built-in: Shangri-La Resort — Heritage + Legends
// Monkey Island, OK • Resort • Tom Clark (renovation)
// 27-hole complex; Heritage, Legends, Champions nines
// #1: Par 72 | 7,210 yds | 76.0 / 146
// =======================================================

private let SHANGRI_LA_HL_ID = UUID(uuidString: "5A6EE011-0001-4B5E-A2F0-000000000009")!

let SHANGRI_LA_HL_PARS: [Int] = [
    4,4,4,5,3,4,4,3,5,
    5,3,4,3,4,4,5,3,5
]

let SHANGRI_LA_HL_HCS: [Int] = [
    11,15,5,7,17,3,9,13,1,
    10,8,4,18,16,6,14,12,2
]

let SHANGRI_LA_HL_TEES: [TeeInfo] = [
    TeeInfo(teeName: "#1", yardage: 7210, rating: 76.0, slope: 146),
]

// =======================================================
// MARK: - Built-in: Shangri-La Resort — Legends + Champions
// Monkey Island, OK • Resort • Tom Clark (renovation)
// #1: Par 72 | 6,905 yds | 73.8 / 134
// =======================================================

private let SHANGRI_LA_LC_ID = UUID(uuidString: "5A6EE012-0002-4B5E-A2F0-00000000000A")!

let SHANGRI_LA_LC_PARS: [Int] = [
    5,3,4,3,4,4,5,3,5,
    5,3,4,4,4,3,5,4,4
]

let SHANGRI_LA_LC_HCS: [Int] = [
    10,8,4,18,16,6,14,12,2,
    9,17,13,5,11,15,3,1,7
]

let SHANGRI_LA_LC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "#1", yardage: 6905, rating: 73.8, slope: 134),
]

// =======================================================
// MARK: - Built-in: Shangri-La Resort — Champions + Heritage
// Monkey Island, OK • Resort • Tom Clark (renovation)
// #1: Par 72 | 7,074 yds | 74.5 / 140
// NOTE: Both nines share odd HCPs 1–17 (27-hole facility)
// =======================================================

private let SHANGRI_LA_CH_ID = UUID(uuidString: "5A6EE013-0003-4B5E-A2F0-00000000000B")!

let SHANGRI_LA_CH_PARS: [Int] = [
    5,3,4,4,4,3,5,4,4,
    4,4,4,5,3,4,4,3,5
]

let SHANGRI_LA_CH_HCS: [Int] = [
    9,17,13,5,11,15,3,1,7,
    11,15,5,7,17,3,9,13,1
]

let SHANGRI_LA_CH_TEES: [TeeInfo] = [
    TeeInfo(teeName: "#1", yardage: 7074, rating: 74.5, slope: 140),
]

// =======================================================
// MARK: - Built-in: Dornick Hills Golf & Country Club
// Ardmore, OK • Private • Perry Maxwell
// Black: Par 70 | 6,621 yds | 73.7 / 131
// =======================================================

private let DORNICK_HILLS_ID = UUID(uuidString: "D0EE1C11-0001-4B5E-A2F0-000000000008")!

let DORNICK_HILLS_PARS: [Int] = [
    4,3,4,3,4,5,4,3,4,
    4,4,4,4,4,4,5,3,4
]

let DORNICK_HILLS_HCS: [Int] = [
    15,13,7,5,17,11,9,3,1,
    10,8,16,2,18,4,6,14,12
]

let DORNICK_HILLS_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6621, rating: 73.7, slope: 131),
]

// =======================================================
// MARK: - Built-in: Oak Tree Country Club — East
// Edmond, OK • Private • Pete & Alice Dye
// Gold: Par 70 | 7,116 yds | 76.3 / 137
// =======================================================

private let OAK_TREE_CC_EAST_ID = UUID(uuidString: "0A57EE01-0001-4B5E-A2F0-000000000006")!

let OAK_TREE_CC_EAST_PARS: [Int] = [
    4,4,4,5,4,3,4,3,4,
    4,4,5,4,3,4,4,3,4
]

let OAK_TREE_CC_EAST_HCS: [Int] = [
    5,1,15,7,9,13,11,17,3,
    18,10,16,8,2,12,4,14,6
]

let OAK_TREE_CC_EAST_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Gold", yardage: 7116, rating: 76.3, slope: 137),
]

// =======================================================
// MARK: - Built-in: Oak Tree Country Club — West
// Edmond, OK • Private • Pete & Alice Dye
// Gold: Par 70 | 6,752 yds | 74.6 / 140
// =======================================================

private let OAK_TREE_CC_WEST_ID = UUID(uuidString: "0A57EE02-0002-4B5E-A2F0-000000000007")!

let OAK_TREE_CC_WEST_PARS: [Int] = [
    4,3,4,4,4,3,5,4,4,
    3,4,4,4,3,4,5,4,4
]

let OAK_TREE_CC_WEST_HCS: [Int] = [
    11,3,1,17,9,13,7,5,15,
    16,4,8,12,6,2,14,18,10
]

let OAK_TREE_CC_WEST_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Gold", yardage: 6752, rating: 74.6, slope: 140),
]

// =======================================================
// MARK: - Built-in: Karsten Creek Golf Club
// Stillwater, OK • Private • Tom Fazio / Dennis Wise • 1994
// Orange: Par 72 | 7,407 yds | 77.2 / 152
// Home course of Oklahoma State University golf teams
// =======================================================

private let KARSTEN_CREEK_ID = UUID(uuidString: "CA5E0001-0001-4B5E-A2F0-000000000004")!

let KARSTEN_CREEK_PARS: [Int] = [
    5,4,3,4,4,4,3,4,5,
    4,3,4,4,5,3,4,4,5
]

let KARSTEN_CREEK_HCS: [Int] = [
    15,1,7,11,5,9,13,3,17,
    6,10,18,4,12,16,8,2,14
]

let KARSTEN_CREEK_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Orange", yardage: 7407, rating: 77.2, slope: 152),
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

// MARK: Wakonda Club — Des Moines, IA
private let WAKONDA_CLUB_ID = UUID(uuidString: "A3C5F2B1-7D9E-4A4B-8C6E-1F3D5B7A9C2E")!

let WAKONDA_CLUB_PARS: [Int] = [
    4,3,4,4,5,4,4,5,3,
    4,4,4,5,3,5,4,3,4
]
let WAKONDA_CLUB_HCS: [Int] = [
    5,15,11,7,1,9,13,3,17,
    6,12,8,2,16,4,14,18,10
]
let WAKONDA_CLUB_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6910)
]

// MARK: Blue Top Ridge — Riverside, IA
private let BLUE_TOP_RIDGE_ID = UUID(uuidString: "B8E4D3A2-5C6F-4B1E-9D7A-2E4F6C8A0B3D")!

let BLUE_TOP_RIDGE_PARS: [Int] = [
    4,4,4,5,4,3,5,3,4,
    4,3,5,4,3,4,5,4,4
]
let BLUE_TOP_RIDGE_HCS: [Int] = [
    11,7,17,5,3,15,1,13,9,
    6,12,4,10,18,14,2,16,8
]
let BLUE_TOP_RIDGE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 7481, rating: 77.2, slope: 143),
    TeeInfo(teeName: "Gold",         yardage: 7019, rating: 74.9, slope: 139),
    TeeInfo(teeName: "Blue",         yardage: 6454, rating: 71.6, slope: 136),
    TeeInfo(teeName: "White",        yardage: 5789, rating: 68.3, slope: 131),
    TeeInfo(teeName: "Red",          yardage: 5208, rating: 66.1, slope: 122)
]

// MARK: Glen Oaks Country Club — West Des Moines, IA
private let GLEN_OAKS_CC_IA_ID = UUID(uuidString: "C4D6E8F0-2A3B-4C5D-9E7F-6A8B0C2D4E6F")!

let GLEN_OAKS_CC_IA_PARS: [Int] = [
    4,3,4,4,3,4,4,4,5,
    4,5,4,4,3,5,3,4,4
]
let GLEN_OAKS_CC_IA_HCS: [Int] = [
    12,10,4,18,8,2,6,14,16,
    3,15,11,5,9,13,17,1,7
]
let GLEN_OAKS_CC_IA_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6950, rating: 74.9, slope: 145)
]

// MARK: Des Moines Golf and Country Club — North (West Des Moines, IA)
private let DMGCC_NORTH_ID = UUID(uuidString: "F1A3B5C7-2D4E-4F6A-8B0C-3E5D7A9B1C4F")!

let DMGCC_NORTH_PARS: [Int] = [
    4,5,3,4,3,4,4,4,5,
    4,4,3,5,4,4,4,3,5
]
let DMGCC_NORTH_HCS: [Int] = [
    5,9,13,7,15,1,3,11,17,
    18,6,16,10,2,8,14,12,4
]
let DMGCC_NORTH_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7294, rating: 75.2, slope: 136)
]

// MARK: Des Moines Golf and Country Club — South (West Des Moines, IA)
private let DMGCC_SOUTH_ID = UUID(uuidString: "A2B4C6D8-3E5F-4A7B-9C1D-4F6E8A0B2C5D")!

let DMGCC_SOUTH_PARS: [Int] = [
    4,5,4,4,3,5,4,3,4,
    4,4,4,5,4,3,5,3,4
]
let DMGCC_SOUTH_HCS: [Int] = [
    7,9,3,1,17,13,11,15,5,
    8,10,4,18,2,12,14,16,6
]
let DMGCC_SOUTH_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7347, rating: 75.0, slope: 140)
]

// MARK: Tournament Club of Iowa — Polk City, IA
private let TOURNAMENT_CLUB_IOWA_ID = UUID(uuidString: "D4E6F3A1-8B2C-4D5E-9A3F-5C1B8D4E7A2F")!

let TOURNAMENT_CLUB_IOWA_PARS: [Int] = [
    4,4,3,5,3,4,5,4,3,
    4,4,4,5,4,3,3,5,4
]
let TOURNAMENT_CLUB_IOWA_HCS: [Int] = [
    17,7,15,3,13,1,5,9,11,
    16,8,2,12,18,14,10,6,4
]
let TOURNAMENT_CLUB_IOWA_TEES: [TeeInfo] = [
    TeeInfo(teeName: "King",   yardage: 7013, rating: 73.5, slope: 140),
    TeeInfo(teeName: "Palmer", yardage: 6551, rating: 71.5, slope: 140),
    TeeInfo(teeName: "Deacon", yardage: 6153, rating: 69.0, slope: 132)
]

// MARK: Amana Colonies Golf Club — Amana, IA
private let AMANA_COLONIES_GC_ID = UUID(uuidString: "E5F7A2B3-9C4D-4E6F-8B1A-6D2C9E5F0B4A")!

let AMANA_COLONIES_GC_PARS: [Int] = [
    4,5,4,3,4,5,4,3,4,
    4,5,4,3,4,5,4,3,4
]
let AMANA_COLONIES_GC_HCS: [Int] = [
    7,1,3,17,9,5,11,15,13,
    6,12,2,18,14,8,4,10,16
]
let AMANA_COLONIES_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6824, rating: 73.6, slope: 146),
    TeeInfo(teeName: "Gold",  yardage: 6540, rating: 72.2, slope: 144),
    TeeInfo(teeName: "Blue",  yardage: 6194, rating: 70.6, slope: 142),
    TeeInfo(teeName: "White", yardage: 5804, rating: 69.5, slope: 129)
]

// MARK: Spirit Hollow Golf Course — Burlington, IA
private let SPIRIT_HOLLOW_ID = UUID(uuidString: "C7D2A4B5-3E8F-4C2A-9B5D-4F1E3A6C8D0B")!

let SPIRIT_HOLLOW_PARS: [Int] = [
    4,5,3,5,4,4,3,4,4,
    5,4,3,4,4,3,4,4,5
]
let SPIRIT_HOLLOW_HCS: [Int] = [
    3,11,9,13,15,1,17,5,7,
    8,12,14,2,4,18,16,10,6
]
let SPIRIT_HOLLOW_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Gold", yardage: 7301, rating: 75.9, slope: 135)
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

// MARK: Pasatiempo Golf Club — Santa Cruz, CA (Alister MacKenzie, 1929)
private let PASATIEMPO_CHAMPIONSHIP_ID = UUID(uuidString: "B1C2D3E4-F5A6-4B1C-2D3E-4F5A6B7C8D9E")!
let PASATIEMPO_CHAMPIONSHIP_PARS: [Int] = [
    4,4,3,4,3,5,4,3,5,
    4,4,4,5,4,3,4,4,3
]
let PASATIEMPO_CHAMPIONSHIP_HCS: [Int] = [
    4,8,2,16,6,10,12,14,18,
    5,1,13,15,7,17,3,9,11
]
let PASATIEMPO_CHAMPIONSHIP_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 6495),
    TeeInfo(teeName: "Middle",       yardage: 6093),
]

private let PASATIEMPO_MIDDLE_ID = UUID(uuidString: "C2D3E4F5-A6B7-4C2D-3E4F-5A6B7C8D9E0F")!
let PASATIEMPO_MIDDLE_PARS: [Int] = [
    4,4,3,4,3,5,4,3,5,
    4,4,4,5,4,3,4,4,3
]
let PASATIEMPO_MIDDLE_HCS: [Int] = [
    4,8,2,16,6,10,12,14,18,
    5,1,13,15,7,17,3,9,11
]

// MARK: Los Angeles Country Club — Los Angeles, CA (George Thomas / Gil Hanse)
private let LACC_NORTH_BLUE_ID = UUID(uuidString: "D3E4F5A6-B7C8-4D3E-4F5A-6B7C8D9E0F1A")!
let LACC_NORTH_BLUE_PARS: [Int] = [
    5,4,4,3,4,4,3,5,3,
    4,3,4,4,5,3,4,4,4
]
let LACC_NORTH_BLUE_HCS: [Int] = [
    11,3,7,15,1,5,17,9,13,
    12,14,8,4,2,18,16,6,10
]
let LACC_NORTH_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7010, rating: 74.6, slope: 139),
    TeeInfo(teeName: "Blue",  yardage: 6466, rating: 72.4, slope: 135),
    TeeInfo(teeName: "White", yardage: 6089, rating: 70.2, slope: 131),
    TeeInfo(teeName: "Green", yardage: 5610, rating: 67.7, slope: 122),
]

private let LACC_SOUTH_CHAMPIONSHIP_ID = UUID(uuidString: "E4F5A6B7-C8D9-4E4F-5A6B-7C8D9E0F1A2B")!
let LACC_SOUTH_CHAMPIONSHIP_PARS: [Int] = [
    4,4,5,3,4,4,3,5,3,
    5,3,4,4,3,4,5,3,4
]
let LACC_SOUTH_CHAMPIONSHIP_HCS: [Int] = [
    13,7,5,11,1,3,15,9,17,
    4,8,14,12,16,2,6,18,10
]
let LACC_SOUTH_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 6407, rating: 71.1, slope: 129),
]

// MARK: Cypress Point Country Club — Virginia Beach, VA
private let CYPRESS_POINT_VA_BLUE_ID = UUID(uuidString: "F5A6B7C8-D9E0-4F5A-6B7C-8D9E0F1A2B3C")!
let CYPRESS_POINT_VA_BLUE_PARS: [Int] = [
    4,5,3,5,3,4,4,5,3,
    4,3,4,4,5,4,4,3,5
]
let CYPRESS_POINT_VA_BLUE_HCS: [Int] = [
    11,7,17,5,13,3,1,9,15,
    2,16,8,18,4,10,6,14,12
]
let CYPRESS_POINT_VA_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue",    yardage: 6541, rating: 70.6, slope: 121),
    TeeInfo(teeName: "White",   yardage: 6210, rating: 69.0, slope: 118),
    TeeInfo(teeName: "Yellow",  yardage: 5581, rating: 66.2, slope: 111),
    TeeInfo(teeName: "Forward", yardage: 5237, rating: 69.6, slope: 117),
]

// MARK: Dunes Golf & Beach Club — Myrtle Beach, SC (Robert Trent Jones, 1948)
private let DUNES_GOLF_BEACH_GOLD_ID = UUID(uuidString: "A6B7C8D9-E0F1-4A6B-7C8D-9E0F1A2B3C4D")!
let DUNES_GOLF_BEACH_GOLD_PARS: [Int] = [
    4,4,4,5,3,4,4,5,3,
    4,4,3,5,4,5,4,3,4
]
let DUNES_GOLF_BEACH_GOLD_HCS: [Int] = [
    6,12,2,16,14,8,4,10,18,
    9,5,13,1,7,11,15,17,3
]
let DUNES_GOLF_BEACH_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Gold",  yardage: 7362, rating: 76.3, slope: 145),
    TeeInfo(teeName: "Blue",  yardage: 6569),
    TeeInfo(teeName: "White", yardage: 6175),
]

// MARK: Riviera Country Club — Pacific Palisades, CA (George C. Thomas)
private let RIVIERA_CC_BLACK_ID = UUID(uuidString: "B8C9D0E1-F2A3-4B8C-9D0E-1F2A3B4C5D6E")!
let RIVIERA_CC_BLACK_PARS: [Int] = [
    5,4,4,3,4,3,4,4,4,
    4,5,4,4,3,4,3,5,4
]
let RIVIERA_CC_BLACK_HCS: [Int] = [
    17,1,7,9,5,15,11,13,3,
    16,10,8,6,18,2,14,12,4
]
let RIVIERA_CC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7400, rating: 76.3, slope: 144),
]

// MARK: Baltusrol Golf Club — Springfield, NJ (A.W. Tillinghast)
private let BALTUSROL_LOWER_ID = UUID(uuidString: "C9D0E1F2-A3B4-4C9D-0E1F-2A3B4C5D6E7F")!
let BALTUSROL_LOWER_PARS: [Int] = [
    5,4,4,3,4,4,5,4,3,
    4,4,3,4,4,4,3,5,5
]
let BALTUSROL_LOWER_HCS: [Int] = [
    17,11,3,13,7,1,9,5,15,
    4,8,18,2,12,10,16,6,14
]
let BALTUSROL_LOWER_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Tee V",   yardage: 7135),
    TeeInfo(teeName: "Tee IV",  yardage: 6665),
    TeeInfo(teeName: "Tee III", yardage: 6225),
    TeeInfo(teeName: "Tee II",  yardage: 5430),
    TeeInfo(teeName: "Tee I",   yardage: 5000),
]

private let BALTUSROL_UPPER_ID = UUID(uuidString: "D0E1F2A3-B4C5-4D0E-1F2A-3B4C5D6E7F8A")!
let BALTUSROL_UPPER_PARS: [Int] = [
    5,4,3,4,4,4,3,5,4,
    3,5,4,4,4,3,4,5,4
]
let BALTUSROL_UPPER_HCS: [Int] = [
    9,3,13,7,11,1,15,5,17,
    16,6,12,10,2,18,8,14,4
]
let BALTUSROL_UPPER_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Tee V",   yardage: 7000),
    TeeInfo(teeName: "Tee IV",  yardage: 6510),
    TeeInfo(teeName: "Tee III", yardage: 6060),
    TeeInfo(teeName: "Tee II",  yardage: 5575),
    TeeInfo(teeName: "Tee I",   yardage: 5005),
]

// MARK: Plainfield Country Club — Edison, NJ (Donald Ross / Gil Hanse renovation)
private let PLAINFIELD_CC_CHAMPIONSHIP_ID = UUID(uuidString: "E1F2A3B4-C5D6-4E1F-2A3B-4C5D6E7F8A9B")!
let PLAINFIELD_CC_CHAMPIONSHIP_PARS: [Int] = [
    4,4,3,4,5,3,4,5,4,
    4,3,5,4,3,4,5,4,4
]
let PLAINFIELD_CC_CHAMPIONSHIP_HCS: [Int] = [
    9,3,15,13,5,17,1,7,11,
    16,18,6,2,12,14,8,4,10
]
let PLAINFIELD_CC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 7110, rating: 74.7, slope: 138),
    TeeInfo(teeName: "Plainfield",   yardage: 6616, rating: 72.6, slope: 136),
    TeeInfo(teeName: "Ross",         yardage: 6356, rating: 71.3, slope: 131),
    TeeInfo(teeName: "Hillside",     yardage: 6069, rating: 70.2, slope: 127),
    TeeInfo(teeName: "Calkins",      yardage: 5452, rating: 67.5, slope: 121),
    TeeInfo(teeName: "Club",         yardage: 4719, rating: 64.4, slope: 114),
]

// MARK: Liberty National Golf Club — Jersey City, NJ (Tom Kite / Bob Cupp, 2003)
private let LIBERTY_NATIONAL_GC_ID = UUID(uuidString: "1A2B3C4D-E5F6-4A1B-2C3D-4E5F6A1B2C3D")!
let LIBERTY_NATIONAL_GC_PARS: [Int] = [
    4,3,4,3,4,5,4,5,4,
    5,3,4,5,3,4,4,4,4
]
let LIBERTY_NATIONAL_GC_HCS: [Int] = [
    15,17,11,13,5,9,3,1,7,
    12,8,14,10,18,4,16,6,2
]
let LIBERTY_NATIONAL_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Tournament", yardage: 7387, rating: 77.7, slope: 155),
    TeeInfo(teeName: "Medal",      yardage: 6762, rating: 74.2, slope: 142),
    TeeInfo(teeName: "Liberty",    yardage: 6500, rating: 72.9, slope: 141),
    TeeInfo(teeName: "Member",     yardage: 6264, rating: 72.2, slope: 134),
    TeeInfo(teeName: "Regular",    yardage: 5748, rating: 69.6, slope: 120),
]

// MARK: Ridgewood Country Club — Paramus, NJ (A.W. Tillinghast, 1929)
private let RIDGEWOOD_CC_ID = UUID(uuidString: "F2A3B4C5-D6E7-4F2A-3B4C-5D6E7F8A9B0C")!
let RIDGEWOOD_CC_PARS: [Int] = [
    4,3,5,4,4,3,4,4,4,
    4,3,4,5,4,3,4,5,4
]
let RIDGEWOOD_CC_HCS: [Int] = [
    11,17,1,9,13,3,7,15,5,
    16,10,6,2,12,18,14,4,8
]
let RIDGEWOOD_CC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 7576, rating: 77.0, slope: 146),
]

// MARK: Poipu Bay Golf Course — Koloa, Kauai, HI (Robert Trent Jones Jr., 1991)
private let POIPU_BAY_GC_ID = UUID(uuidString: "3C4D5E6F-A7B8-4C3D-4E5F-6A7B8C9D0E1F")!
let POIPU_BAY_GC_PARS: [Int] = [
    4,5,3,4,4,5,3,4,4,
    4,3,4,4,5,4,4,3,5
]
let POIPU_BAY_GC_HCS: [Int] = [
    15,5,7,3,11,13,17,9,1,
    6,10,4,16,8,18,2,12,14
]
let POIPU_BAY_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Gold",   yardage: 7123, rating: 74.7, slope: 131),
]

// MARK: Princeville Makai Golf Club — Princeville, Kauai, HI (Robert Trent Jones Jr., 1971)
private let PRINCEVILLE_MAKAI_GC_ID = UUID(uuidString: "4D5E6F7A-B8C9-4D4E-5F6A-7B8C9D0E1F2A")!
let PRINCEVILLE_MAKAI_GC_PARS: [Int] = [
    4,5,3,4,5,4,3,4,4,
    4,5,4,3,4,4,3,4,5
]
let PRINCEVILLE_MAKAI_GC_HCS: [Int] = [
    13,9,15,1,11,3,7,17,5,
    6,14,2,4,18,10,12,8,16
]
let PRINCEVILLE_MAKAI_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7223, rating: 75.4, slope: 134),
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

// MARK: Chambers Bay — University Place, WA
// Par 72 | 7,158 yds (Black) 74.4/138 | Architect: Robert Trent Jones Jr. | Type: Public
// 2015 U.S. Open host

private let CHAMBERS_BAY_ID = UUID(uuidString: "FF6A7B8C-9D0E-4F6A-7B8C-9D0E1F2A3B4C")!

let CHAMBERS_BAY_PARS: [Int] = [
    4,4,3,5,4,4,4,5,3,
    4,4,4,5,4,3,4,4,5
]

let CHAMBERS_BAY_HCS: [Int] = [
    3,9,15,13,5,7,1,17,11,
    4,8,18,14,2,16,10,6,12
]

let CHAMBERS_BAY_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black",     yardage: 7158, rating: 74.4, slope: 138),
    TeeInfo(teeName: "Blue",      yardage: 6748, rating: 72.4, slope: 134),
    TeeInfo(teeName: "Sand",      yardage: 6345, rating: 70.6, slope: 130),
    TeeInfo(teeName: "White",     yardage: 5822, rating: 68.0, slope: 122),
    TeeInfo(teeName: "Teal",      yardage: 4708, rating: 63.0, slope: 109)
]

// MARK: Sahalee Country Club — Sammamish, WA (3 × 9-hole courses = 3 combinations)
// Type: Private | Phone: (425) 868-8800 | sahalee.com
// HC computed by pairing equal 9-hole ranks; longer yardage gets the harder 18-hole HC

private let SAHALEE_EAST_NORTH_ID = UUID(uuidString: "01A2B3C4-D5E6-4F01-A2B3-C4D5E6F01A2B")!

let SAHALEE_EAST_NORTH_PARS: [Int] = [
    5,4,4,3,5,4,4,3,4,   // East Course (holes 1–9)
    4,5,4,3,4,4,4,3,5    // North Course (holes 10–18)
]

let SAHALEE_EAST_NORTH_HCS: [Int] = [
    2,15,11,14,3,9,8,17,6,
    10,1,4,18,12,7,13,16,5
]

let SAHALEE_EAST_NORTH_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 6966),
    TeeInfo(teeName: "Blue",         yardage: 6769),
    TeeInfo(teeName: "White",        yardage: 6325),
    TeeInfo(teeName: "Gold",         yardage: 5762),
    TeeInfo(teeName: "Green",        yardage: 5412)
]

private let SAHALEE_EAST_SOUTH_ID = UUID(uuidString: "02B3C4D5-E6F0-4102-B3C4-D5E6F01A2B3C")!

let SAHALEE_EAST_SOUTH_PARS: [Int] = [
    5,4,4,3,5,4,4,3,4,   // East Course (holes 1–9)
    4,5,4,4,3,5,4,4,3    // South Course (holes 10–18)
]

let SAHALEE_EAST_SOUTH_HCS: [Int] = [
    1,15,11,14,3,9,8,18,6,
    10,2,7,12,17,5,13,4,16
]

let SAHALEE_EAST_SOUTH_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 6965),
    TeeInfo(teeName: "Blue",         yardage: 6769),
    TeeInfo(teeName: "White",        yardage: 6322),
    TeeInfo(teeName: "Gold",         yardage: 5700),
    TeeInfo(teeName: "Green",        yardage: 5413)
]

private let SAHALEE_NORTH_SOUTH_ID = UUID(uuidString: "03C4D5E6-F012-4203-C4D5-E6F01A2B3C4D")!

let SAHALEE_NORTH_SOUTH_PARS: [Int] = [
    4,5,4,3,4,4,4,3,5,   // North Course (holes 1–9)
    4,5,4,4,3,5,4,4,3    // South Course (holes 10–18)
]

let SAHALEE_NORTH_SOUTH_HCS: [Int] = [
    10,1,3,18,12,7,14,15,5,
    9,2,8,11,17,6,13,4,16
]

let SAHALEE_NORTH_SOUTH_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 7003),
    TeeInfo(teeName: "Blue",         yardage: 6754),
    TeeInfo(teeName: "White",        yardage: 6321),
    TeeInfo(teeName: "Gold",         yardage: 5742),
    TeeInfo(teeName: "Green",        yardage: 5411)
]

// MARK: Aldarra Golf Club — Sammamish, WA
// Par 71 | 6,926 yds | Rating 74.9 | Slope 151 | Type: Private | Architect: Tom Fazio

private let ALDARRA_GC_ID = UUID(uuidString: "04D5E6F0-1234-4405-D6E7-F01A2B3C4D5E")!

let ALDARRA_GC_PARS: [Int] = [
    4,3,5,4,4,3,5,4,3,
    4,5,5,3,4,3,4,4,4
]

let ALDARRA_GC_HCS: [Int] = [
    5,9,1,7,11,15,13,3,17,
    14,2,18,12,16,4,8,10,6
]

let ALDARRA_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Aldarra", yardage: 6926, rating: 74.9, slope: 151)
]

// MARK: Wine Valley Golf Club — Walla Walla, WA
// Par 72 | 7,600 yds (Gold) | Type: Daily-Fee | Architect: Dan Hixon

private let WINE_VALLEY_GC_ID = UUID(uuidString: "05E6F012-3456-4506-E7F0-12A3B4C5D6E7")!

let WINE_VALLEY_GC_PARS: [Int] = [
    4,4,5,4,4,3,5,3,4,
    4,4,4,4,3,5,3,4,5
]

let WINE_VALLEY_GC_HCS: [Int] = [
    7,11,3,15,1,17,9,13,5,
    6,16,4,2,18,12,14,8,10
]

let WINE_VALLEY_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Gold",     yardage: 7600, rating: 76.4, slope: 133),
    TeeInfo(teeName: "Cabernet", yardage: 7195, rating: 74.4, slope: 130),
    TeeInfo(teeName: "Black",    yardage: 6760, rating: 72.6, slope: 127),
    TeeInfo(teeName: "Merlot",   yardage: 6510, rating: 71.3, slope: 127),
    TeeInfo(teeName: "Blue",     yardage: 6333, rating: 70.3, slope: 126),
    TeeInfo(teeName: "Syrah",    yardage: 6090, rating: 69.1, slope: 125),
    TeeInfo(teeName: "White",    yardage: 5845, rating: 68.4, slope: 114)
]

// MARK: Palouse Ridge Golf Course — Pullman, WA
// Par 72 | 7,302 yds (Crimson) | Rating 75.5 | Slope 144 | Type: Daily-Fee | Architect: John Harbottle III

private let PALOUSE_RIDGE_GC_ID = UUID(uuidString: "06F7A012-3456-4607-F7A0-12B3C4D5E6F7")!

let PALOUSE_RIDGE_GC_PARS: [Int] = [
    4,4,4,3,5,3,4,4,5,
    5,3,4,3,4,4,3,5,5
]

let PALOUSE_RIDGE_GC_HCS: [Int] = [
    3,17,5,9,1,7,15,11,13,
    8,10,4,2,14,18,16,12,6
]

let PALOUSE_RIDGE_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Crimson", yardage: 7302, rating: 75.5, slope: 144)
]

// MARK: The Home Course — DuPont, WA
// Par 72 | 7,420 yds (Dynamite) | Rating 74.9 | Slope 138 | Type: Daily-Fee

private let HOME_COURSE_ID = UUID(uuidString: "07A8B123-4567-4708-A8B1-23C4D5E6F7A8")!

let HOME_COURSE_PARS: [Int] = [
    4,4,4,3,5,3,4,5,4,
    5,4,3,4,3,4,5,4,4
]

let HOME_COURSE_HCS: [Int] = [
    11,13,1,15,17,5,7,9,3,
    14,16,6,2,10,8,18,12,4
]

let HOME_COURSE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Dynamite", yardage: 7420, rating: 74.9, slope: 138),
    TeeInfo(teeName: "Black",    yardage: 7031, rating: 73.3, slope: 135),
    TeeInfo(teeName: "Blue",     yardage: 6584, rating: 71.2, slope: 131),
    TeeInfo(teeName: "White",    yardage: 6094, rating: 69.0, slope: 125)
]

// MARK: Gold Mountain Golf Club — Olympic Course — Bremerton, WA
// Par 72 | 7,168 yds (Pro) | Rating 74.8 | Slope 139 | Type: Daily-Fee

private let GOLD_MTN_OLYMPIC_ID = UUID(uuidString: "08B9C234-5678-4809-B9C2-34D5E6F7A8B9")!

let GOLD_MTN_OLYMPIC_PARS: [Int] = [
    4,4,4,4,3,5,4,3,5,
    4,4,4,4,3,5,4,3,5
]

let GOLD_MTN_OLYMPIC_HCS: [Int] = [
    3,13,9,11,17,7,1,15,5,
    2,8,14,12,10,4,16,18,6
]

let GOLD_MTN_OLYMPIC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Pro",     yardage: 7168, rating: 74.8, slope: 139),
    TeeInfo(teeName: "Tourney", yardage: 6505, rating: 71.9, slope: 135),
    TeeInfo(teeName: "Player",  yardage: 6034, rating: 70.0, slope: 126),
    TeeInfo(teeName: "Scoring", yardage: 5607, rating: 68.3, slope: 121),
    TeeInfo(teeName: "Forward", yardage: 5220, rating: 66.2, slope: 117)
]

// MARK: Gold Mountain Golf Club — Cascade Course — Bremerton, WA
// Par 72 | 6,775 yds (Pro) | Rating 73.0 | Slope 125 | Type: Daily-Fee

private let GOLD_MTN_CASCADE_ID = UUID(uuidString: "09CAD345-6789-490A-CAD3-45E6F7A8B9CA")!

let GOLD_MTN_CASCADE_PARS: [Int] = [
    5,4,3,4,5,4,3,4,4,
    4,4,4,4,3,5,4,3,5
]

let GOLD_MTN_CASCADE_HCS: [Int] = [
    9,11,15,13,1,3,17,7,5,
    2,8,14,12,10,4,16,18,6
]

let GOLD_MTN_CASCADE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Pro",     yardage: 6775, rating: 73.0, slope: 125),
    TeeInfo(teeName: "Tourney", yardage: 6386, rating: 71.2, slope: 122),
    TeeInfo(teeName: "Player",  yardage: 6081, rating: 69.4, slope: 119),
    TeeInfo(teeName: "Scoring", yardage: 5711, rating: 67.5, slope: 117),
    TeeInfo(teeName: "Forward", yardage: 5333, rating: 65.4, slope: 112)
]

// MARK: Suncadia Resort – Prospector — Roslyn, WA
// Par 72 | 7,112 yds | Rating 74.5 | Slope 139 | Type: Resort | Architect: Arnold Palmer Design

private let SUNCADIA_PROSPECTOR_ID = UUID(uuidString: "0CDEF678-9ABC-4C0D-F678-9ABCDEF012CD")!

let SUNCADIA_PROSPECTOR_PARS: [Int] = [
    4,4,3,5,4,3,4,5,4,
    4,5,3,4,4,3,4,4,5
]

let SUNCADIA_PROSPECTOR_HCS: [Int] = [
    13,9,17,11,15,5,1,7,3,
    10,4,18,14,8,12,16,2,6
]

let SUNCADIA_PROSPECTOR_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 7112, rating: 74.5, slope: 139),
    TeeInfo(teeName: "Back",         yardage: 6641, rating: 72.4, slope: 134),
    TeeInfo(teeName: "Middle",       yardage: 6159, rating: 68.8, slope: 132),
    TeeInfo(teeName: "Forward",      yardage: 5362, rating: 71.3, slope: 132)
]

// MARK: Suncadia Resort – Rope Rider — Roslyn, WA
// Par 72 | 7,226 yds | Rating 73.5 | Slope 132 | Type: Resort | Architect: Jacobsen Hardy GC Design

private let SUNCADIA_ROPE_RIDER_ID = UUID(uuidString: "0DEF0789-ABCD-4D0E-0789-ABCDEF0123DE")!

let SUNCADIA_ROPE_RIDER_PARS: [Int] = [
    4,5,3,4,4,4,3,5,4,
    5,3,4,4,5,4,4,3,4
]

let SUNCADIA_ROPE_RIDER_HCS: [Int] = [
    7,3,13,9,11,15,17,1,5,
    6,18,16,12,2,8,4,14,10
]

let SUNCADIA_ROPE_RIDER_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Jake 2025", yardage: 7226, rating: 73.5, slope: 132)
]

// MARK: Salish Cliffs Golf Club — Shelton, WA
// Par 72 | 7,206 yds | Rating 75.1 | Slope 142 | Type: Daily-Fee | Architect: Gene Bates

private let SALISH_CLIFFS_GC_ID = UUID(uuidString: "0ADBE456-789A-4A0B-DBE4-56789ABCDEF0")!

let SALISH_CLIFFS_GC_PARS: [Int] = [
    5,4,3,4,4,3,4,5,4,
    5,4,4,3,4,4,4,3,5
]

let SALISH_CLIFFS_GC_HCS: [Int] = [
    3,15,13,9,11,17,5,1,7,
    8,4,12,16,2,14,10,18,6
]

let SALISH_CLIFFS_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 7206, rating: 75.1, slope: 142)
]

// MARK: Indian Canyon Golf Course — Spokane, WA
// Par 71 | 6,255 yds | Rating 69.6 | Slope 123 | Type: Municipal

private let INDIAN_CANYON_GC_ID = UUID(uuidString: "0BCEF567-89AB-4B0C-EF56-789ABCDEF01B")!

let INDIAN_CANYON_GC_PARS: [Int] = [
    4,5,4,3,4,4,4,3,4,
    4,3,5,3,4,4,4,4,5
]

let INDIAN_CANYON_GC_HCS: [Int] = [
    10,8,16,18,2,14,12,4,6,
    9,17,3,15,1,11,7,13,5
]

let INDIAN_CANYON_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue", yardage: 6255, rating: 69.6, slope: 123)
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

// MARK: - River Forest Country Club — Elmhurst, IL
// Par 72 | Est. 1926 | Architect: Frank P. McDonald / A.W. Tillinghast (1935)
// Type: Private

private let RIVER_FOREST_CC_ID = UUID(uuidString: "C12A6D8E-1F44-4B7D-9E31-2A8C7F5D1004")!

let RIVER_FOREST_CC_PARS: [Int] = [
    4,4,3,5,4,4,3,5,4,
    4,3,4,5,4,4,3,5,4
]

let RIVER_FOREST_CC_HCS: [Int] = [
    13,7,17,3,5,9,15,1,11,
    10,18,4,2,6,12,16,8,14
]

let RIVER_FOREST_CC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue",      yardage: 6831, rating: 74.0, slope: 139),
    TeeInfo(teeName: "Member",    yardage: 6657, rating: 73.2, slope: 137),
    TeeInfo(teeName: "Gold",      yardage: 6481, rating: 72.4, slope: 135),
    TeeInfo(teeName: "Member II", yardage: 6245, rating: 71.2, slope: 133),
    TeeInfo(teeName: "White",     yardage: 6082, rating: 70.5, slope: 131),
    TeeInfo(teeName: "Red",       yardage: 5692, rating: 74.0, slope: 133)
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

// MARK: - Victoria National Golf Club — Newburgh, IN
private let VICTORIA_NATIONAL_ID = UUID(uuidString: "F4A3B2C1-D5E6-4F7A-B8C9-D0E1F2A3B4C5")!
let VICTORIA_NATIONAL_PARS: [Int] = [4,4,5,4,3,4,3,4,5, 5,3,4,4,4,5,3,4,4]
let VICTORIA_NATIONAL_HCS: [Int]  = [13,7,3,9,15,1,17,11,5, 12,14,16,18,2,8,10,4,6]
let VICTORIA_NATIONAL_TEES: [TeeInfo] = [TeeInfo(teeName: "Black", yardage: 7242, rating: 77.7, slope: 152)]

// MARK: - Brickyard Crossing Golf Course — Indianapolis, IN
private let BRICKYARD_CROSSING_ID = UUID(uuidString: "E3B2A1C0-D4E5-4E6F-A7B8-C9D0E1F2A3B4")!
let BRICKYARD_CROSSING_PARS: [Int] = [4,5,4,3,4,5,3,4,4, 4,4,5,3,4,5,4,3,4]
let BRICKYARD_CROSSING_HCS: [Int]  = [17,5,13,9,3,15,7,1,11, 16,6,10,14,18,4,8,12,2]
let BRICKYARD_CROSSING_TEES: [TeeInfo] = [TeeInfo(teeName: "Gold", yardage: 7180, rating: 74.6, slope: 141)]

// MARK: - Pfau Course at Indiana University — Bloomington, IN
private let PFAU_COURSE_IU_ID = UUID(uuidString: "D2A1B0C9-E3F4-4D5E-B6C7-D8E9F0A1B2C3")!
let PFAU_COURSE_IU_PARS: [Int] = [5,4,3,4,4,4,3,4,5, 4,4,4,5,4,3,4,3,4]
let PFAU_COURSE_IU_HCS: [Int]  = [5,1,17,11,15,9,13,7,3, 16,12,2,6,10,14,8,18,4]
let PFAU_COURSE_IU_TEES: [TeeInfo] = [TeeInfo(teeName: "Championship", yardage: 7241, rating: 76.0, slope: 143)]

// MARK: - Warren Golf Course at Notre Dame — Notre Dame, IN
private let WARREN_GC_ND_ID = UUID(uuidString: "C1B0A9E8-F2D3-4C4B-A5D6-E7F8A9B0C1D2")!
let WARREN_GC_ND_PARS: [Int] = [4,4,4,3,5,4,4,4,3, 5,3,4,4,3,4,4,5,4]
let WARREN_GC_ND_HCS: [Int]  = [11,3,9,17,1,5,13,7,15, 4,14,6,10,18,16,12,2,8]
let WARREN_GC_ND_TEES: [TeeInfo] = [TeeInfo(teeName: "Championship", yardage: 7020, rating: 74.6, slope: 135)]

// MARK: - Harrison Lake Country Club — Columbus, IN
// Par 71 | Architect: Gary Kern | Private
// Official rating/slope not published on club website

private let HARRISON_LAKE_CC_ID = UUID(uuidString: "C12A6D8E-1F44-4B7D-9E31-2A8C7F5D1003")!

let HARRISON_LAKE_CC_PARS: [Int] = [
    5,3,4,4,4,3,5,3,4,
    4,5,4,3,4,4,4,3,5
]

let HARRISON_LAKE_CC_HCS: [Int] = [
    9,3,1,5,7,15,13,13,17,
    2,6,4,16,10,18,14,12,8
]

let HARRISON_LAKE_CC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Harrison",   yardage: 6503, rating: nil, slope: nil),
    TeeInfo(teeName: "Grandview",  yardage: 6117, rating: nil, slope: nil),
    TeeInfo(teeName: "Sweetwater", yardage: 5627, rating: nil, slope: nil),
    TeeInfo(teeName: "Tipton",     yardage: 4753, rating: nil, slope: nil)
]

// =======================================================
// MARK: Briar Ridge Country Club — Schererville, IN
// Par 72 | Opened: 1980 | Private
// Blue nine: Dick Nugent | Red nine: Gary Roger Baird | White nine: Larry Packard & Gary Roger Baird
// Three 9-hole nines: Red, Blue, White — three 18-hole combos below.

// Course 2 — Red nine (front) + White nine (back)
private let BRIAR_RIDGE_CC_ID = UUID(uuidString: "B8E4F2A1-3C7D-4E9F-B5A2-6D1E8C4F7B3A")!

let BRIAR_RIDGE_CC_PARS: [Int] = [
    4,5,3,4,4,5,4,3,4,   // Red nine
    4,3,5,4,4,3,4,4,5    // White nine
]

let BRIAR_RIDGE_CC_HCS: [Int] = [
    13,11,15,5,9,7,3,17,1,
    2,18,10,4,16,14,8,6,12
]

let BRIAR_RIDGE_CC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue",   yardage: 6772),
    TeeInfo(teeName: "Powers", yardage: 6580),
    TeeInfo(teeName: "White",  yardage: 6341),
    TeeInfo(teeName: "Gold",   yardage: 6006),
    TeeInfo(teeName: "Red",    yardage: 5316),
]

// Course 1 — Blue nine (front) + White nine (back)
private let BRIAR_RIDGE_BW_ID = UUID(uuidString: "B8E4F2A2-3C7D-4E9F-B5A2-6D1E8C4F7B3A")!

let BRIAR_RIDGE_BW_PARS: [Int] = [
    4,4,5,3,4,5,3,4,4,   // Blue nine
    4,3,5,4,4,3,4,4,5    // White nine
]

let BRIAR_RIDGE_BW_HCS: [Int] = [
    3,13,11,9,15,7,17,5,1,
    2,18,10,4,16,14,8,6,12
]

let BRIAR_RIDGE_BW_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue",   yardage: 6815),
    TeeInfo(teeName: "Powers", yardage: 6621),
    TeeInfo(teeName: "White",  yardage: 6409),
    TeeInfo(teeName: "Gold",   yardage: 6058),
    TeeInfo(teeName: "Red",    yardage: 5309),
]

// Course 3 — Red nine (front) + Blue nine (back)
private let BRIAR_RIDGE_RB_ID = UUID(uuidString: "B8E4F2A3-3C7D-4E9F-B5A2-6D1E8C4F7B3A")!

let BRIAR_RIDGE_RB_PARS: [Int] = [
    4,5,3,4,4,5,4,3,4,   // Red nine
    4,4,5,3,4,5,3,4,4    // Blue nine
]

let BRIAR_RIDGE_RB_HCS: [Int] = [
    13,11,15,5,9,7,3,17,1,
    4,14,12,10,16,8,18,6,2
]

let BRIAR_RIDGE_RB_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue",   yardage: 6815),
    TeeInfo(teeName: "Powers", yardage: 6627),
    TeeInfo(teeName: "White",  yardage: 6460),
    TeeInfo(teeName: "Gold",   yardage: 6122),
    TeeInfo(teeName: "Red",    yardage: 5475),
]

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
// MARK: - Built-in: Dismal River Club — Red Course
// Mullen, NE • Private • Tom Doak / Renaissance Golf Design
// Blue: Par 71 | 6,994 yds
// =======================================================

private let DISMAL_RIVER_RED_ID = UUID(uuidString: "D15A1001-0001-4B5E-A2F0-8E1C9D7B4036")!

let DISMAL_RIVER_RED_PARS: [Int] = [
    5,4,3,4,3,4,4,5,4,
    5,3,4,4,4,4,3,4,4
]

// Front HCs are all even (2,4,6,8,10,12,14,16,18); back are all odd (1,3,5,7,9,11,13,15,17)
let DISMAL_RIVER_RED_HCS: [Int] = [
    14,2,8,10,6,16,4,18,12,
    9,11,13,1,7,17,15,5,3
]

let DISMAL_RIVER_RED_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue",  yardage: 6994),
    TeeInfo(teeName: "White", yardage: 6252),
    TeeInfo(teeName: "Red",   yardage: 4838),
]

// =======================================================
// MARK: - Built-in: Dismal River Club — White Course
// Mullen, NE • Private • Jack Nicklaus
// Back: Par 72 | 7,398 yds
// =======================================================

private let DISMAL_RIVER_WHITE_ID = UUID(uuidString: "D15A1002-0002-4B5E-A2F0-8E1C9D7B4037")!

let DISMAL_RIVER_WHITE_PARS: [Int] = [
    4,4,3,5,3,4,4,4,5,
    3,4,5,4,4,3,4,4,5
]

let DISMAL_RIVER_WHITE_HCS: [Int] = [
    7,1,17,9,11,13,3,15,5,
    14,8,4,12,2,18,16,10,6
]

let DISMAL_RIVER_WHITE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Back",    yardage: 7398),
    TeeInfo(teeName: "Middle",  yardage: 6530),
    TeeInfo(teeName: "Forward", yardage: 5058),
]

// =======================================================
// MARK: - Built-in: CapRock Ranch
// Valentine, NE • Private • Gil Hanse / Jim Wagner
// Tee I: Par 71 | 6,998 yds
// =======================================================

private let CAPROCK_RANCH_ID = UUID(uuidString: "F7A3C912-6D84-4B5E-A2F0-8E1C9D7B4036")!

let CAPROCK_RANCH_PARS: [Int] = [
    4,5,3,5,4,3,4,4,3,
    5,4,5,4,4,4,3,4,3
]

let CAPROCK_RANCH_HCS: [Int] = [
    5,7,13,9,11,17,3,1,15,
    14,8,12,6,10,2,18,16,4
]

let CAPROCK_RANCH_TEES: [TeeInfo] = [
    TeeInfo(teeName: "I",   yardage: 6998),
    TeeInfo(teeName: "II",  yardage: 6676),
    TeeInfo(teeName: "III", yardage: 6289),
    TeeInfo(teeName: "IV",  yardage: 5642),
    TeeInfo(teeName: "V",   yardage: 4876),
]

// =======================================================
// MARK: - Built-in: Landmand Golf Club
// Homer, NE • Private • King-Collins Golf Course Design
// Red (longest): Par 73 | 7,200 yds | 74.7 / 135
// =======================================================

private let LANDMAND_GC_ID = UUID(uuidString: "C4D7F231-8A59-4E6B-B1F3-5A9C2E8D7041")!

let LANDMAND_GC_PARS: [Int] = [
    5,4,4,4,3,5,4,3,4,
    4,5,3,4,3,5,4,4,5
]

let LANDMAND_GC_HCS: [Int] = [
    17,15,7,3,13,1,11,9,5,
    18,2,14,4,10,12,8,16,6
]

let LANDMAND_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Red",    yardage: 7200, rating: 74.7, slope: 135),
    TeeInfo(teeName: "White",  yardage: 6775, rating: 72.8, slope: 132),
    TeeInfo(teeName: "Green",  yardage: 6440, rating: 71.3, slope: 130),
    TeeInfo(teeName: "Yellow", yardage: 6000, rating: 68.4, slope: 126),
    TeeInfo(teeName: "Black",  yardage: 5420, rating: 68.8, slope: 113),
]

// =======================================================
// MARK: - Built-in: Sand Hills Golf Club
// Mullen, NE • Private • Coore & Crenshaw • 1995
// Back: Par 71 | 7,089 yds | 76.0 / 130
// =======================================================

private let SAND_HILLS_GC_ID = UUID(uuidString: "E9C3F847-2B16-4D8A-95F0-7C4B1E6D3A28")!

let SAND_HILLS_GC_PARS: [Int] = [
    5,4,3,4,4,3,4,4,4,
    4,4,4,3,5,4,5,3,4
]

let SAND_HILLS_GC_HCS: [Int] = [
    7,3,11,1,9,17,15,5,13,
    4,14,10,16,2,6,8,18,12
]

let SAND_HILLS_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Back",   yardage: 7089, rating: 76.0, slope: 130),
    TeeInfo(teeName: "Middle", yardage: 6432, rating: 73.0, slope: 126),
    TeeInfo(teeName: "Front",  yardage: 5040, rating: 67.5, slope: 117),
]

// =======================================================
// MARK: - Built-in: Wild Horse Golf Club
// Gothenburg, NE • Daily-Fee • Dave Axland & Dan Proctor
// Tips: Par 72 | 7,030 yds | 73.9 / 140
// =======================================================

private let WILD_HORSE_GC_ID = UUID(uuidString: "B31DC0DE-0001-4B5E-A2F0-000000000001")!

let WILD_HORSE_GC_PARS: [Int] = [
    4,4,5,3,4,5,4,4,3,
    4,3,4,3,5,4,4,5,4
]

let WILD_HORSE_GC_HCS: [Int] = [
    11,3,15,9,13,5,7,1,17,
    10,18,4,6,16,12,2,14,8
]

let WILD_HORSE_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Tips",         yardage: 7030, rating: 73.9, slope: 140),
    TeeInfo(teeName: "Gold",         yardage: 6848, rating: 73.1, slope: 138),
    TeeInfo(teeName: "Black",        yardage: 6353, rating: 70.7, slope: 133),
    TeeInfo(teeName: "Black/Silver", yardage: 5874, rating: 68.3, slope: 125),
    TeeInfo(teeName: "Silver",       yardage: 5456, rating: 66.4, slope: 113),
    TeeInfo(teeName: "Green",        yardage: 4688, rating: 63.0, slope: 106),
]

// =======================================================
// MARK: - Built-in: GrayBull
// Nebraska Sandhills • Private (Dormie Network) • David McLay Kidd • 2024
// Bulls: Par 72 | 7,181 yds | 74.2 / 128
// =======================================================

private let GRAYBULL_ID = UUID(uuidString: "6BA4B011-0001-4B5E-A2F0-000000000002")!

let GRAYBULL_PARS: [Int] = [
    4,5,4,3,4,4,3,5,4,
    4,5,3,4,5,4,4,3,4
]

let GRAYBULL_HCS: [Int] = [
    5,9,11,7,13,1,17,15,3,
    2,10,8,14,18,4,16,12,6
]

let GRAYBULL_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Bulls", yardage: 7181, rating: 74.2, slope: 128),
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

let PRAIRIE_CLUB_DUNES_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black",      yardage: 7562, rating: 75.5, slope: 133),
    TeeInfo(teeName: "Blue",       yardage: 6981, rating: 72.6, slope: 127),
    TeeInfo(teeName: "Blue/White", yardage: 6663, rating: 71.0, slope: 123),
    TeeInfo(teeName: "White",      yardage: 6184, rating: 68.9, slope: 116),
    TeeInfo(teeName: "White/Green",yardage: 5905, rating: 67.7, slope: 113),
    TeeInfo(teeName: "Green",      yardage: 5260, rating: 69.3, slope: 116)
]

// MARK: - The Prairie Club - Pines Course — Valentine, NE
// Par 73 | Architect: Graham Marsh | Resort

private let PRAIRIE_CLUB_PINES_ID = UUID(uuidString: "C12A6D8E-1F44-4B7D-9E31-2A8C7F5D1006")!

let PRAIRIE_CLUB_PINES_PARS: [Int] = [
    4,5,3,4,4,3,5,4,4,
    3,5,4,4,4,5,4,3,5
]

let PRAIRIE_CLUB_PINES_HCS: [Int] = [
    3,7,17,5,11,13,9,1,15,
    16,6,2,10,18,12,4,14,8
]

let PRAIRIE_CLUB_PINES_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black",      yardage: 7385, rating: 74.6, slope: 129),
    TeeInfo(teeName: "Blue",       yardage: 6792, rating: 71.9, slope: 123),
    TeeInfo(teeName: "Blue/White", yardage: 6386, rating: 69.8, slope: 115),
    TeeInfo(teeName: "White",      yardage: 6032, rating: 68.4, slope: 111),
    TeeInfo(teeName: "White/Green",yardage: 5588, rating: 66.1, slope: 106),
    TeeInfo(teeName: "Green",      yardage: 5293, rating: 69.7, slope: 116)
]

// MARK: - Rustic Canyon Golf Course — Moorpark, CA
// Par 71 | Daily-Fee | Architects: Gil Hanse, Geoff Shackelford & Jim Wagner (2002)
// Note: par/HCP derived from yardages; scorecard did not display those rows

private let RUSTIC_CANYON_ID = UUID(uuidString: "C12A6D8E-1F44-4B7D-9E31-2A8C7F5D1007")!

let RUSTIC_CANYON_PARS: [Int] = [
    5,4,4,3,5,3,4,3,4,
    5,4,4,5,4,3,4,3,4
]

let RUSTIC_CANYON_HCS: [Int] = [
    5,8,13,16,3,14,11,18,4,
    2,10,12,1,6,17,7,15,9
]

let RUSTIC_CANYON_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7044, rating: 73.9, slope: 135),
    TeeInfo(teeName: "Blue",  yardage: 6634, rating: 72.0, slope: 130),
    TeeInfo(teeName: "Hanse", yardage: 6441, rating: 71.1, slope: 128),
    TeeInfo(teeName: "White", yardage: 6049, rating: 69.3, slope: 124),
    TeeInfo(teeName: "Red",   yardage: 5275, rating: 70.5, slope: 120)
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
private let LAKE_OF_ISLES_SOUTH_ID = UUID(uuidString: "B8C9D0E2-3F4A-5B6C-9D7E-8F0A1B2C3D73")!
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
// MARK: - Red Hawk Ridge Golf Course — Castle Rock, CO
private let RED_HAWK_RIDGE_ID = UUID(uuidString: "A2C91D43-7E85-4F6B-BC34-2E8A5D7F1C09")!

let RED_HAWK_RIDGE_PARS: [Int] = [
    5,4,3,4,4,3,5,4,4,
    4,3,4,5,3,4,5,3,5
]

let RED_HAWK_RIDGE_HCS: [Int] = [
    17,11,5,1,15,9,3,7,13,
    4,14,10,12,8,2,6,16,18
]

// MARK: - CommonGround Golf Course — Aurora, CO
private let COMMONGROUND_GC_ID = UUID(uuidString: "B3D02E54-8F96-4A7C-CD45-3F9B6E8A2D10")!

let COMMONGROUND_GC_PARS: [Int] = [
    4,3,5,4,4,3,5,4,4,
    4,5,3,4,3,4,4,3,5
]

let COMMONGROUND_GC_HCS: [Int] = [
    7,17,1,9,5,13,3,15,11,
    12,10,18,4,16,2,6,14,8
]

// MARK: - Green Valley Ranch Golf Club — Denver, CO
private let GREEN_VALLEY_RANCH_GC_ID = UUID(uuidString: "C4E13F65-9A07-4B8D-DE56-4A0C7F9B3E21")!

let GREEN_VALLEY_RANCH_GC_PARS: [Int] = [
    4,5,4,4,3,4,4,3,5,
    4,4,5,3,4,4,4,3,5
]

let GREEN_VALLEY_RANCH_GC_HCS: [Int] = [
    9,3,7,17,13,1,15,11,5,
    10,4,8,16,18,2,14,12,6
]

// MARK: - TPC Colorado — Berthoud, CO
private let TPC_COLORADO_ID = UUID(uuidString: "D5F24A76-0B18-4C9E-EF67-5B1D8A0C4F32")!

let TPC_COLORADO_PARS: [Int] = [
    5,3,4,4,5,4,4,3,4,
    4,4,4,5,3,5,3,4,4
]

let TPC_COLORADO_HCS: [Int] = [
    4,6,14,2,16,18,12,10,8,
    17,13,9,1,5,11,15,7,3
]

// MARK: - Pole Creek Golf Club — Tabernash, CO (27-hole)
// Meadow + Ranch
private let POLE_CREEK_MEADOW_RANCH_ID = UUID(uuidString: "E6A35B87-1C29-4DAF-F078-6C2E9B1D5A43")!

let POLE_CREEK_MEADOW_RANCH_PARS: [Int] = [
    4,5,4,3,4,3,5,4,4,
    5,3,4,4,4,4,3,4,5
]

let POLE_CREEK_MEADOW_RANCH_HCS: [Int] = [
    17,9,7,15,5,13,3,1,11,
    2,18,4,6,12,8,10,16,14
]

// Meadow + Ridge
private let POLE_CREEK_MEADOW_RIDGE_ID = UUID(uuidString: "F7B46C98-2D3A-4EB0-A189-7D3FAC2E6B54")!

let POLE_CREEK_MEADOW_RIDGE_PARS: [Int] = [
    4,5,4,3,4,3,5,4,4,
    4,3,4,4,4,3,5,4,4
]

let POLE_CREEK_MEADOW_RIDGE_HCS: [Int] = [
    17,9,7,15,5,13,3,1,11,
    2,18,14,4,16,6,12,8,10
]

// Ranch + Ridge
private let POLE_CREEK_RANCH_RIDGE_ID = UUID(uuidString: "A8C57DA9-3E4B-4FC1-B29A-8E4ABD3F7C65")!

let POLE_CREEK_RANCH_RIDGE_PARS: [Int] = [
    5,3,4,4,4,4,3,4,5,
    4,3,4,4,4,3,5,4,4
]

let POLE_CREEK_RANCH_RIDGE_HCS: [Int] = [
    1,17,3,5,11,7,9,15,13,
    2,18,14,4,16,6,12,8,10
]

// MARK: - Riverdale Golf Club — Brighton, CO
// Dunes Course
private let RIVERDALE_DUNES_ID = UUID(uuidString: "B9D68EBA-4F5C-4AD2-C3AB-9F5BCE4A8D76")!

let RIVERDALE_DUNES_PARS: [Int] = [
    4,4,5,3,4,4,4,3,5,
    4,5,3,4,4,4,5,3,4
]

let RIVERDALE_DUNES_HCS: [Int] = [
    11,15,9,7,1,3,5,13,17,
    10,4,14,2,12,6,18,8,16
]

// Knolls Course
private let RIVERDALE_KNOLLS_ID = UUID(uuidString: "CAE79FCB-5A6D-4BE3-D4BC-AF6CDF5B9E87")!

let RIVERDALE_KNOLLS_PARS: [Int] = [
    4,5,4,4,3,4,5,3,4,
    4,5,5,3,4,4,3,4,4
]

let RIVERDALE_KNOLLS_HCS: [Int] = [
    3,5,13,1,11,7,17,9,15,
    16,2,10,4,12,8,14,18,6
]

// MARK: - Golf Club at Fox Acres — Red Feather Lakes, CO
private let FOX_ACRES_GC_ID = UUID(uuidString: "DBF8A0DC-6B7E-4CF4-E5CD-BA7DE06CAF98")!

let FOX_ACRES_GC_PARS: [Int] = [
    4,3,4,4,4,3,5,4,3,
    4,4,4,5,4,4,4,5,3
]

let FOX_ACRES_GC_HCS: [Int] = [
    10,4,14,2,6,16,8,12,18,
    11,15,3,9,1,17,7,13,5
]

// MARK: - Cherry Hills Country Club — Cherry Hills Village, CO
private let CHERRY_HILLS_CC_ID = UUID(uuidString: "EC897B1D-7C8F-4D05-A6DE-CB8EF17DB0A9")!

let CHERRY_HILLS_CC_PARS: [Int] = [
    4,4,4,4,5,3,4,3,4,
    4,5,3,4,4,3,4,5,5
]

let CHERRY_HILLS_CC_HCS: [Int] = [
    12,6,14,8,2,18,10,16,4,
    7,13,15,9,1,17,5,3,11
]

// MARK: - Sanctuary Golf Course — Sedalia, CO
private let SANCTUARY_GC_ID = UUID(uuidString: "FD9A8C2E-8D90-4E16-B7EF-DC9FA28EC1BA")!

let SANCTUARY_GC_PARS: [Int] = [
    5,4,4,5,3,3,4,4,4,
    3,5,4,4,3,5,4,4,4
]

let SANCTUARY_GC_HCS: [Int] = [
    1,5,9,3,13,17,15,7,11,
    14,4,6,10,12,8,16,18,2
]

// MARK: - The Broadmoor East Course — Colorado Springs, CO
private let BROADMOOR_EAST_ID = UUID(uuidString: "AE0B9D3F-9EA1-4F27-C8FA-ED0AB39FD2CB")!

let BROADMOOR_EAST_PARS: [Int] = [
    4,4,4,3,5,4,3,4,4,
    4,5,4,3,4,4,5,3,4
]

let BROADMOOR_EAST_HCS: [Int] = [
    9,5,13,17,1,7,15,11,3,
    10,2,8,18,12,6,4,16,14
]

// MARK: - The Broadmoor West Course — Colorado Springs, CO
private let BROADMOOR_WEST_ID = UUID(uuidString: "BF3CE1A4-AB4C-4D49-E0DC-AB3EF1B2CD4F")!

let BROADMOOR_WEST_PARS: [Int] = [
    4,4,4,4,3,4,4,5,3,
    5,3,4,4,4,4,3,4,5
]

let BROADMOOR_WEST_HCS: [Int] = [
    11,5,7,15,17,1,9,3,13,
    2,16,6,10,4,14,18,12,8
]

// MARK: - RainDance National Golf Course — Windsor, CO
private let RAINDANCE_NATIONAL_ID = UUID(uuidString: "EC1ADF84-FA2B-4E7C-C0DF-BC2EF1A3BE5F")!

let RAINDANCE_NATIONAL_PARS: [Int] = [
    4,5,4,4,4,3,5,3,4,
    4,4,3,5,3,4,5,3,5
]

let RAINDANCE_NATIONAL_HCS: [Int] = [
    13,11,15,3,1,17,5,9,7,
    6,12,10,4,18,8,14,16,2
]

let RAINDANCE_NATIONAL_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black/Tour", yardage: 8463, rating: 79.9, slope: 155)
]

// MARK: - Breckenridge Golf Club — Breckenridge, CO
private let BRECKENRIDGE_GC_ID = UUID(uuidString: "FD2BE095-AB3C-4F8D-D1E0-CD3FA2B4CF60")!

let BRECKENRIDGE_GC_PARS: [Int] = [
    4,5,3,4,4,4,4,5,3,
    4,5,4,3,4,4,5,4,4
]

let BRECKENRIDGE_GC_HCS: [Int] = [
    4,6,9,5,3,8,2,1,7,
    9,3,8,5,7,6,1,2,4
]

let BRECKENRIDGE_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Beaver/Bear", yardage: 7339, rating: 73.9, slope: 151)
]

// MARK: - Keystone Ranch Golf Course — Keystone, CO
private let KEYSTONE_RANCH_ID = UUID(uuidString: "AE3CF1A6-BC4D-4A9E-E2F1-DE4AB3C5DA71")!

let KEYSTONE_RANCH_PARS: [Int] = [
    5,4,4,4,3,5,3,4,4,
    4,4,3,5,3,4,4,4,5
]

let KEYSTONE_RANCH_HCS: [Int] = [
    16,8,4,12,2,10,14,6,18,
    1,11,17,13,15,7,5,3,9
]

let KEYSTONE_RANCH_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Gold", yardage: 6317, rating: 72.2, slope: 142)
]

// MARK: - River Course at Keystone — Keystone, CO
private let KEYSTONE_RIVER_ID = UUID(uuidString: "BF4DA2B7-CD5E-4BAF-F3A2-EF5BC4D6EB82")!

let KEYSTONE_RIVER_PARS: [Int] = [
    5,4,3,4,5,4,3,4,3,
    4,4,3,5,4,3,4,4,5
]

let KEYSTONE_RIVER_HCS: [Int] = [
    15,17,1,11,3,5,9,7,13,
    8,6,12,14,4,10,2,16,18
]

let KEYSTONE_RIVER_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6886, rating: 71.1, slope: 137)
]

// MARK: - Murphy Creek Golf Course — Aurora, CO
private let MURPHY_CREEK_GC_ID = UUID(uuidString: "CA5EB3C8-DE6F-4CB0-A4B3-FA6CD5E7FC93")!

let MURPHY_CREEK_GC_PARS: [Int] = [
    4,4,5,4,3,5,4,3,4,
    4,3,4,5,4,5,4,3,4
]

let MURPHY_CREEK_GC_HCS: [Int] = [
    17,1,7,3,13,9,5,11,15,
    16,14,2,18,10,12,4,8,6
]

let MURPHY_CREEK_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue", yardage: 6909, rating: 72.0, slope: 132)
]

// MARK: - Walnut Creek Golf Preserve — Westminster, CO
private let WALNUT_CREEK_GC_ID = UUID(uuidString: "DB6FC4D9-EF70-4DC1-B5C4-AB7DE6F8AD04")!

let WALNUT_CREEK_GC_PARS: [Int] = [
    4,4,5,3,4,5,3,4,4,
    4,4,4,5,3,4,4,3,5
]

let WALNUT_CREEK_GC_HCS: [Int] = [
    11,7,1,5,3,9,17,13,15,
    12,16,8,2,18,6,10,14,4
]

let WALNUT_CREEK_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 7563, rating: 75.2, slope: 137)
]

// MARK: - The Club at Hokuli'a — Kealakekua, HI
private let HOKUL_IA_CLUB_ID = UUID(uuidString: "EC2BE095-AB4C-4F9E-D2F1-BC3EF2A4CF71")!

let HOKUL_IA_CLUB_PARS: [Int] = [
    4,4,3,4,5,4,4,3,5,
    4,3,4,3,5,4,5,4,4
]

let HOKUL_IA_CLUB_HCS: [Int] = [
    7,3,17,11,5,1,13,15,9,
    4,16,18,10,8,6,2,12,14
]

let HOKUL_IA_CLUB_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Green", yardage: 7335, rating: 76.1, slope: 147)
]

// MARK: - Shorehaven Golf Club — East Norwalk, CT
private let SHOREHAVEN_GC_ID = UUID(uuidString: "FD3CF1A6-BC5D-4AAF-E3A2-CD4FA3B5DA82")!

let SHOREHAVEN_GC_PARS: [Int] = [
    5,3,4,4,3,4,4,4,4,
    4,5,5,3,4,3,5,3,4
]

let SHOREHAVEN_GC_HCS: [Int] = [
    11,15,7,3,13,17,5,1,9,
    4,6,12,14,10,18,2,16,8
]

let SHOREHAVEN_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6548, rating: 72.5, slope: 136)
]

// MARK: - Cordillera Valley Course — Edwards, CO
private let CORDILLERA_VALLEY_ID = UUID(uuidString: "AE4DA2B7-CD6E-4BB0-F4B3-DE5AB4C6EB93")!

let CORDILLERA_VALLEY_PARS: [Int] = [
    5,4,5,3,4,4,4,3,4,
    3,4,4,5,3,4,4,4,4
]

let CORDILLERA_VALLEY_HCS: [Int] = [
    15,5,13,9,1,3,11,7,17,
    18,10,2,8,6,14,16,4,12
]

let CORDILLERA_VALLEY_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7046, rating: 72.8, slope: 144)
]

// MARK: - Cordillera Mountain Course — Edwards, CO
private let CORDILLERA_MOUNTAIN_ID = UUID(uuidString: "BF5EB3C8-DE7F-4CC1-A5C4-EF6BC5D7FC04")!

let CORDILLERA_MOUNTAIN_PARS: [Int] = [
    4,3,4,5,3,4,4,5,4,
    4,4,5,4,4,3,5,3,4
]

let CORDILLERA_MOUNTAIN_HCS: [Int] = [
    9,15,3,11,13,1,17,5,7,
    2,6,12,8,14,10,18,16,4
]

let CORDILLERA_MOUNTAIN_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7450, rating: 74.6, slope: 148)
]

// MARK: - Cordillera Summit Course — Edwards, CO
private let CORDILLERA_SUMMIT_ID = UUID(uuidString: "CA6FC4D9-EF80-4DD2-B6D5-FA7CD6E8AD15")!

let CORDILLERA_SUMMIT_PARS: [Int] = [
    4,4,3,4,5,4,3,5,4,
    4,3,4,5,4,4,3,5,4
]

let CORDILLERA_SUMMIT_HCS: [Int] = [
    9,3,17,1,15,7,13,11,5,
    12,6,4,2,10,16,14,18,8
]

let CORDILLERA_SUMMIT_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7518, rating: 74.7, slope: 149)
]

// MARK: - Frost Creek — Eagle, CO
private let FROST_CREEK_GC_ID = UUID(uuidString: "DB7AD5EA-FA91-4EE3-C7E6-AB8DE7F9BE26")!

let FROST_CREEK_GC_PARS: [Int] = [
    4,4,5,4,3,4,4,3,5,
    4,4,3,4,5,4,3,5,4
]

let FROST_CREEK_GC_HCS: [Int] = [
    5,13,3,17,9,1,15,7,11,
    6,12,8,18,16,2,10,14,4
]

let FROST_CREEK_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Copper", yardage: 7142, rating: 73.7, slope: 140)
]

// MARK: - Raven Golf Club at Three Peaks — Silverthorne, CO
private let RAVEN_THREE_PEAKS_ID = UUID(uuidString: "EC8BE6FB-AB02-4FF4-D8F7-BC9EF8A0CF37")!

let RAVEN_THREE_PEAKS_PARS: [Int] = [
    4,5,4,3,4,5,4,3,4,
    4,5,3,4,3,4,5,4,4
]

let RAVEN_THREE_PEAKS_HCS: [Int] = [
    11,3,5,17,13,7,9,15,1,
    14,2,6,12,10,18,8,4,16
]

let RAVEN_THREE_PEAKS_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Raven", yardage: 7273, rating: 74.3, slope: 144)
]

// MARK: - Roaring Fork Club — Basalt, CO
private let ROARING_FORK_CLUB_ID = UUID(uuidString: "FD9CF7AC-BC13-4A05-E9A8-CD0FA9B1DA48")!

let ROARING_FORK_CLUB_PARS: [Int] = [
    4,5,4,3,4,4,4,3,5,
    4,4,3,4,5,5,3,4,4
]

let ROARING_FORK_CLUB_HCS: [Int] = [
    7,11,17,5,3,13,1,15,9,
    14,6,12,18,16,2,10,4,8
]

let ROARING_FORK_CLUB_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6991, rating: 72.8, slope: 141)
]

// MARK: - Nevada Courses

// MARK: - Rio Secco Golf Club — Henderson, NV
private let RIO_SECCO_GC_ID = UUID(uuidString: "AE5EB4C9-EF91-4DE3-D8F7-BC0EF9A1CF48")!

let RIO_SECCO_GC_PARS: [Int] = [
    4,4,3,4,4,3,4,5,5,
    4,4,3,4,5,4,3,5,4
]

let RIO_SECCO_GC_HCS: [Int] = [
    15,1,13,17,11,5,7,9,3,
    16,2,14,10,4,12,6,18,8
]

let RIO_SECCO_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue", yardage: 6921, rating: 75.0, slope: 153)
]

// MARK: - Las Vegas Paiute Golf Resort - Snow Mountain — Las Vegas, NV
private let PAIUTE_SNOW_MOUNTAIN_ID = UUID(uuidString: "BF6FC5DA-FA02-4EF4-E9A8-CD1FA0B2DA59")!

let PAIUTE_SNOW_MOUNTAIN_PARS: [Int] = [
    4,4,5,3,4,5,4,3,4,
    4,5,4,4,3,4,3,5,4
]

let PAIUTE_SNOW_MOUNTAIN_HCS: [Int] = [
    11,9,3,13,1,5,15,17,7,
    8,4,12,16,18,6,14,10,2
]

let PAIUTE_SNOW_MOUNTAIN_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7068, rating: 73.1, slope: 130)
]

// MARK: - Las Vegas Paiute Golf Resort - Sun Mountain — Las Vegas, NV
private let PAIUTE_SUN_MOUNTAIN_ID = UUID(uuidString: "CA7AD6EB-AB13-4FA5-FAB9-DE2AB1C3EB6A")!

let PAIUTE_SUN_MOUNTAIN_PARS: [Int] = [
    4,4,5,3,4,4,5,3,4,
    4,5,4,4,3,4,5,3,4
]

let PAIUTE_SUN_MOUNTAIN_HCS: [Int] = [
    5,15,7,11,13,1,9,17,3,
    14,8,4,2,16,12,10,18,6
]

let PAIUTE_SUN_MOUNTAIN_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6967, rating: 73.0, slope: 135)
]

// MARK: - Chimera Golf Club — Henderson, NV
private let CHIMERA_GC_ID = UUID(uuidString: "DB8BE7FC-BC24-4AB6-ABD0-EF3BC2D4FC7B")!

let CHIMERA_GC_PARS: [Int] = [
    4,5,4,3,4,3,4,5,4,
    4,5,3,4,4,5,4,3,4
]

let CHIMERA_GC_HCS: [Int] = [
    5,15,7,13,3,11,17,9,1,
    10,8,16,6,14,12,2,18,4
]

let CHIMERA_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Pegasus Red", yardage: 6697, rating: 72.3, slope: 128)
]

// MARK: - Arroyo Golf Club — Las Vegas, NV
private let ARROYO_RED_ROCK_ID = UUID(uuidString: "AE6FC5DA-FA13-4FF5-E0B9-CD2FA1C4EB7A")!

let ARROYO_RED_ROCK_PARS: [Int] = [
    5,4,3,4,5,4,3,4,4,
    4,5,3,4,3,4,5,4,4
]

let ARROYO_RED_ROCK_HCS: [Int] = [
    7,3,15,1,11,5,17,9,13,
    8,12,6,10,18,16,2,14,4
]

let ARROYO_RED_ROCK_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6879, rating: 72.6, slope: 134)
]

// MARK: - Boulder Creek Golf Club — Boulder City, NV
private let BOULDER_CREEK_GC_ID = UUID(uuidString: "BF7AD6EB-AB24-4AA6-F1CA-DE3AB2D5FC8B")!

let BOULDER_CREEK_GC_PARS: [Int] = [
    4,5,4,3,5,4,4,3,4,
    4,4,3,5,4,4,5,3,4
]

let BOULDER_CREEK_GC_HCS: [Int] = [
    5,9,15,11,13,7,1,17,3,
    12,8,14,10,6,16,2,18,4
]

let BOULDER_CREEK_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7472, rating: 75.3, slope: 136)
]

// MARK: - Angel Park Golf Club (Mountain) — Las Vegas, NV
private let ANGEL_PARK_MOUNTAIN_ID = UUID(uuidString: "CA8BE7FC-BC35-4BB7-A2DB-EF4BC3E6AD9C")!

let ANGEL_PARK_MOUNTAIN_PARS: [Int] = [
    4,5,4,3,4,3,4,4,4,
    4,3,4,5,4,3,4,5,4
]

let ANGEL_PARK_MOUNTAIN_HCS: [Int] = [
    5,1,13,17,9,15,11,3,7,
    4,18,12,6,10,16,14,2,8
]

let ANGEL_PARK_MOUNTAIN_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Professional", yardage: 6596, rating: 71.4, slope: 134)
]

// MARK: - SouthShore Country Club — Henderson, NV
private let SOUTHSHORE_CC_ID = UUID(uuidString: "A1B2C3D4-E5F6-4A1B-B2C3-D4E5F6A1B2C3")!
let SOUTHSHORE_CC_PARS: [Int] = [5,4,4,3,4,5,4,3,4, 3,5,4,5,3,4,3,4,4]
let SOUTHSHORE_CC_HCS: [Int]  = [15,7,3,17,1,11,9,13,5, 12,18,4,8,16,2,14,10,6]
let SOUTHSHORE_CC_TEES: [TeeInfo] = [TeeInfo(teeName: "Black", yardage: 6887, rating: 74.7, slope: 150)]

// MARK: - Desert Springs Golf Course (Palms) — Palm Desert, CA
private let DESERT_SPRINGS_PALMS_ID = UUID(uuidString: "B2C3D4E5-F6A1-4B2C-C3D4-E5F6A1B2C3D4")!
let DESERT_SPRINGS_PALMS_PARS: [Int] = [5,4,3,4,4,4,5,3,4, 5,4,3,5,4,4,4,3,4]
let DESERT_SPRINGS_PALMS_HCS: [Int]  = [13,7,15,17,1,9,3,5,11, 8,16,6,10,18,12,4,14,2]
let DESERT_SPRINGS_PALMS_TEES: [TeeInfo] = [TeeInfo(teeName: "Black", yardage: 6761, rating: 72.7, slope: 132)]

// MARK: - Rhodes Ranch Golf Club — Las Vegas, NV
private let RHODES_RANCH_GC_ID = UUID(uuidString: "C3D4E5F6-A1B2-4C3D-D4E5-F6A1B2C3D4E5")!
let RHODES_RANCH_GC_PARS: [Int] = [4,4,3,4,4,4,3,4,5, 4,4,5,4,3,5,3,4,4]
let RHODES_RANCH_GC_HCS: [Int]  = [11,3,9,13,5,17,1,15,7, 8,18,2,14,6,16,12,10,4]
let RHODES_RANCH_GC_TEES: [TeeInfo] = [TeeInfo(teeName: "Black", yardage: 6582, rating: 70.6, slope: 128)]

// MARK: - Desert Pines Golf Club — Las Vegas, NV
private let DESERT_PINES_GC_ID = UUID(uuidString: "D4E5F6A1-B2C3-4D4E-E5F6-A1B2C3D4E5F6")!
let DESERT_PINES_GC_PARS: [Int] = [4,4,3,5,4,4,3,5,4, 4,4,3,5,4,4,3,5,3]
let DESERT_PINES_GC_HCS: [Int]  = [9,5,15,1,11,7,17,3,13, 10,6,16,2,12,8,18,4,14]
let DESERT_PINES_GC_TEES: [TeeInfo] = [TeeInfo(teeName: "Championship", yardage: 6222, rating: 70.5, slope: 129)]

// MARK: - Coyote Springs Golf Club — Coyote Springs, NV
private let COYOTE_SPRINGS_GC_ID = UUID(uuidString: "E5F6A1B2-C3D4-4E5F-F6A1-B2C3D4E5F6A1")!
let COYOTE_SPRINGS_GC_PARS: [Int] = [4,5,3,4,5,4,4,3,4, 4,5,3,4,4,4,5,3,4]
let COYOTE_SPRINGS_GC_HCS: [Int]  = [9,13,7,1,11,17,3,15,5, 12,6,14,8,2,10,4,18,16]
let COYOTE_SPRINGS_GC_TEES: [TeeInfo] = [TeeInfo(teeName: "Black", yardage: 7471, rating: 76.8, slope: 149)]

// MARK: - Wolf Creek Golf Club — Mesquite, NV
private let WOLF_CREEK_GC_ID = UUID(uuidString: "F6A1B2C3-D4E5-4F6A-A1B2-C3D4E5F6A1B2")!
let WOLF_CREEK_GC_PARS: [Int] = [5,4,3,4,5,4,4,3,4, 4,3,5,4,4,3,4,5,4]
let WOLF_CREEK_GC_HCS: [Int]  = [9,1,7,15,3,11,13,5,17, 2,16,8,14,4,18,10,6,12]
let WOLF_CREEK_GC_TEES: [TeeInfo] = [TeeInfo(teeName: "Challenger Black", yardage: 6785, rating: 74.4, slope: 147)]

// MARK: - Sand Hollow Resort (Championship) — Hurricane, UT
private let SAND_HOLLOW_CHAMPIONSHIP_ID = UUID(uuidString: "A2B3C4D5-E6F1-4A2B-B3C4-D5E6F1A2B3C4")!
let SAND_HOLLOW_CHAMPIONSHIP_PARS: [Int] = [4,5,3,4,4,4,5,3,4, 5,3,4,4,4,3,4,5,4]
let SAND_HOLLOW_CHAMPIONSHIP_HCS: [Int]  = [15,7,17,5,13,1,3,11,9, 10,16,2,14,4,8,18,12,6]
let SAND_HOLLOW_CHAMPIONSHIP_TEES: [TeeInfo] = [TeeInfo(teeName: "Tournament", yardage: 7315, rating: 74.0, slope: 137)]

// MARK: - Conestoga Golf Club — Mesquite, NV
private let CONESTOGA_GC_ID = UUID(uuidString: "B3C4D5E6-F1A2-4B3C-C4D5-E6F1A2B3C4D5")!
let CONESTOGA_GC_PARS: [Int] = [4,3,4,4,3,5,4,4,5, 3,4,5,4,3,4,5,4,4]
let CONESTOGA_GC_HCS: [Int]  = [5,15,9,1,13,3,17,7,11, 14,2,16,10,18,8,12,6,4]
let CONESTOGA_GC_TEES: [TeeInfo] = [TeeInfo(teeName: "Black", yardage: 7232, rating: 74.9, slope: 137)]

// MARK: - Falcon Ridge Golf Course — Mesquite, NV
private let FALCON_RIDGE_GC_ID = UUID(uuidString: "C4D5E6F1-A2B3-4C4D-D5E6-F1A2B3C4D5E6")!
let FALCON_RIDGE_GC_PARS: [Int] = [5,3,4,4,3,4,5,3,4, 5,4,5,4,3,4,5,3,4]
let FALCON_RIDGE_GC_HCS: [Int]  = [16,6,12,8,14,2,18,4,10, 15,5,13,1,11,9,17,7,3]
let FALCON_RIDGE_GC_TEES: [TeeInfo] = [TeeInfo(teeName: "Black", yardage: 6569, rating: 70.9, slope: 135)]

// MARK: - Summit Club — Las Vegas, NV
private let SUMMIT_CLUB_ID = UUID(uuidString: "D5E6F1A2-B3C4-4D5E-E6F1-A2B3C4D5E6F1")!
let SUMMIT_CLUB_PARS: [Int] = [4,3,5,4,4,5,3,4,4, 4,3,4,4,5,4,3,4,5]
let SUMMIT_CLUB_HCS: [Int]  = [15,13,5,1,11,9,17,3,7, 4,10,18,2,14,8,16,6,12]
let SUMMIT_CLUB_TEES: [TeeInfo] = [TeeInfo(teeName: "Crown", yardage: 7519, rating: 76.9, slope: 147)]

// MARK: - Reynolds Lake Oconee — Greensboro, GA
private let REYNOLDS_PRESERVE_ID = UUID(uuidString: "A3B4C5D6-E1F2-4A3B-C4D5-E6F1A2B3C4D5")!
let REYNOLDS_PRESERVE_PARS: [Int] = [4,4,3,4,5,4,5,3,5, 4,3,4,4,4,3,5,3,5]
let REYNOLDS_PRESERVE_HCS: [Int]  = [1,9,17,3,11,5,13,15,7, 4,8,6,16,2,10,18,12,14]
let REYNOLDS_PRESERVE_TEES: [TeeInfo] = [TeeInfo(teeName: "One", yardage: 6674, rating: 72.2, slope: 133)]

private let REYNOLDS_GREAT_WATERS_ID = UUID(uuidString: "B4C5D6E1-F2A3-4B4C-D5E6-F1A2B3C4D5E6")!
let REYNOLDS_GREAT_WATERS_PARS: [Int] = [4,5,4,3,4,5,4,3,4, 4,4,5,4,3,4,4,3,5]
let REYNOLDS_GREAT_WATERS_HCS: [Int]  = [11,17,3,13,1,9,7,15,5, 4,16,10,6,18,8,2,14,12]
let REYNOLDS_GREAT_WATERS_TEES: [TeeInfo] = [TeeInfo(teeName: "Bear", yardage: 7358, rating: 76.1, slope: 147)]

private let REYNOLDS_NATIONAL_ID = UUID(uuidString: "C5D6E1F2-A3B4-4C5D-E6F1-A2B3C4D5E6F1")!
let REYNOLDS_NATIONAL_PARS: [Int] = [4,4,3,4,3,5,4,5,4, 4,4,5,3,4,5,3,4,4]
let REYNOLDS_NATIONAL_HCS: [Int]  = [9,13,17,3,7,5,11,15,1, 16,6,14,18,12,10,8,2,4]
let REYNOLDS_NATIONAL_TEES: [TeeInfo] = [TeeInfo(teeName: "One", yardage: 6955, rating: 74.2, slope: 143)]

private let REYNOLDS_OCONEE_ID = UUID(uuidString: "D6E1F2A3-B4C5-4D6E-F1A2-B3C4D5E6F1A2")!
let REYNOLDS_OCONEE_PARS: [Int] = [5,4,4,4,3,4,5,3,4, 5,4,4,3,4,3,4,5,4]
let REYNOLDS_OCONEE_HCS: [Int]  = [9,11,1,17,15,7,5,13,3, 14,8,10,12,6,18,2,16,4]
let REYNOLDS_OCONEE_TEES: [TeeInfo] = [TeeInfo(teeName: "Zero", yardage: 7393, rating: 75.2, slope: 141)]

private let REYNOLDS_CREEK_CLUB_ID = UUID(uuidString: "E1F2A3B4-C5D6-4E1F-A2B3-C4D5E6F1A2B3")!
let REYNOLDS_CREEK_CLUB_PARS: [Int] = [5,4,4,3,4,4,3,5,4, 4,3,5,3,5,4,4,3,5]
let REYNOLDS_CREEK_CLUB_HCS: [Int]  = [11,17,3,5,1,13,7,15,9, 2,6,4,16,8,18,10,14,12]
let REYNOLDS_CREEK_CLUB_TEES: [TeeInfo] = [TeeInfo(teeName: "One", yardage: 6951, rating: 72.3, slope: 132)]

private let REYNOLDS_LANDING_ID = UUID(uuidString: "F2A3B4C5-D6E1-4F2A-B3C4-D5E6F1A2B3C4")!
let REYNOLDS_LANDING_PARS: [Int] = [4,5,3,4,4,5,3,4,4, 4,3,4,4,5,4,5,3,4]
let REYNOLDS_LANDING_HCS: [Int]  = [3,13,15,1,11,9,17,5,7, 6,8,2,10,12,4,14,18,16]
let REYNOLDS_LANDING_TEES: [TeeInfo] = [TeeInfo(teeName: "One", yardage: 6991, rating: 74.5, slope: 138)]

// MARK: - Stone Mountain Golf Club — Stone Mountain, GA
private let STONE_MOUNTAIN_STONEMONT_ID = UUID(uuidString: "A4B5C6D7-E2F3-4A4B-C5D6-E7F2A3B4C5D6")!
let STONE_MOUNTAIN_STONEMONT_PARS: [Int] = [4,4,5,4,4,3,4,3,4, 3,4,4,4,4,4,3,4,5]
let STONE_MOUNTAIN_STONEMONT_HCS: [Int]  = [1,17,11,3,9,13,5,15,7, 18,2,16,6,10,8,14,4,12]
let STONE_MOUNTAIN_STONEMONT_TEES: [TeeInfo] = [TeeInfo(teeName: "Black", yardage: 6870, rating: 73.3, slope: 131)]

private let STONE_MOUNTAIN_LAKEMONT_ID = UUID(uuidString: "B5C6D7E2-F3A4-4B5C-D6E7-F2A3B4C5D6E7")!
let STONE_MOUNTAIN_LAKEMONT_PARS: [Int] = [5,3,4,4,4,3,4,3,5, 4,4,5,3,4,4,3,4,5]
let STONE_MOUNTAIN_LAKEMONT_HCS: [Int]  = [1,11,7,13,15,5,9,17,3, 14,6,2,10,8,12,16,18,4]
let STONE_MOUNTAIN_LAKEMONT_TEES: [TeeInfo] = [TeeInfo(teeName: "Black", yardage: 6403, rating: 71.9, slope: 134)]

// MARK: - The Frog Golf Club — Villa Rica, GA
private let THE_FROG_GC_ID = UUID(uuidString: "C6D7E2F3-A4B5-4C6D-E7F2-A3B4C5D6E7F2")!
let THE_FROG_GC_PARS: [Int] = [4,5,4,3,4,5,4,3,4, 4,4,5,4,3,4,4,3,5]
let THE_FROG_GC_HCS: [Int]  = [9,17,5,15,1,13,3,11,7, 4,16,10,6,18,14,2,12,8]
let THE_FROG_GC_TEES: [TeeInfo] = [TeeInfo(teeName: "Black", yardage: 7073, rating: 72.3, slope: 132)]

// MARK: - Brasstown Valley Resort — Young Harris, GA
private let BRASSTOWN_VALLEY_ID = UUID(uuidString: "D7E2F3A4-B5C6-4D7E-F2A3-B4C5D6E7F2A3")!
let BRASSTOWN_VALLEY_PARS: [Int] = [4,4,4,5,3,4,4,4,5, 3,5,4,4,3,5,4,3,4]
let BRASSTOWN_VALLEY_HCS: [Int]  = [11,3,15,1,13,5,9,17,7, 18,6,8,16,14,12,4,10,2]
let BRASSTOWN_VALLEY_TEES: [TeeInfo] = [TeeInfo(teeName: "Gold", yardage: 6993, rating: 74.7, slope: 140)]

// MARK: - Currahee Club — Toccoa, GA
private let CURRAHEE_CLUB_ID = UUID(uuidString: "E2F3A4B5-C6D7-4E2F-A3B4-C5D6E7F2A3B4")!
let CURRAHEE_CLUB_PARS: [Int] = [5,3,4,3,5,4,4,4,4, 5,4,3,4,4,4,5,3,4]
let CURRAHEE_CLUB_HCS: [Int]  = [3,13,15,17,7,9,1,5,11, 4,2,18,6,12,14,10,16,8]
let CURRAHEE_CLUB_TEES: [TeeInfo] = [TeeInfo(teeName: "5's", yardage: 7408, rating: 76.2, slope: 151)]

// MARK: - Castle Pines Golf Club — Castle Rock, CO
private let CASTLE_PINES_GC_ID = UUID(uuidString: "BF1CAE40-AB2B-4A38-D9CB-FE1BC4A0EB1C")!

let CASTLE_PINES_GC_PARS: [Int] = [
    5,4,4,3,4,4,3,5,4,
    4,3,4,4,5,4,3,5,4
]

let CASTLE_PINES_GC_HCS: [Int] = [
    16,10,8,12,14,2,18,6,4,
    1,15,3,7,13,9,11,17,5
]

// MARK: - Lakota Canyon Ranch Golf Club — New Castle, CO
private let LAKOTA_CANYON_GC_ID = UUID(uuidString: "CA2DBF51-BC3C-4B49-EADC-AF2CD5B1FC2D")!

let LAKOTA_CANYON_GC_PARS: [Int] = [
    5,4,3,5,5,4,3,4,3,
    4,5,4,4,4,3,4,3,5
]

let LAKOTA_CANYON_GC_HCS: [Int] = [
    6,10,18,2,4,14,16,8,12,
    11,5,7,9,13,15,3,17,1
]

// MARK: - Redlands Mesa Golf Club — Grand Junction, CO
private let REDLANDS_MESA_GC_ID = UUID(uuidString: "DB3EC062-CD4D-4C5A-FBED-BA3DE6C2AD3E")!

let REDLANDS_MESA_GC_PARS: [Int] = [
    4,4,3,4,5,4,4,3,4,
    5,4,3,5,4,5,4,3,4
]

let REDLANDS_MESA_GC_HCS: [Int] = [
    5,11,15,17,3,9,1,13,7,
    10,2,18,16,12,6,4,14,8
]

// MARK: - Ballyneal Golf Club — Holyoke, CO
private let BALLYNEAL_GC_ID = UUID(uuidString: "EC0FDB73-DE5E-4D6B-A0CE-CB0CF5B1AD4F")!

let BALLYNEAL_GC_PARS: [Int] = [
    4,4,3,5,3,4,4,5,4,
    4,3,4,4,4,3,5,4,4
]

let BALLYNEAL_GC_HCS: [Int] = [
    9,3,17,5,13,1,15,7,11,
    2,18,12,4,16,14,6,8,10
]

// MARK: - Red Sky Golf Club – Fazio Course — Wolcott, CO
private let RED_SKY_FAZIO_ID = UUID(uuidString: "FD1AEC84-EF6F-4E7C-B1DF-DC1DA6C2BE50")!

let RED_SKY_FAZIO_PARS: [Int] = [
    4,5,4,4,5,4,3,4,3,
    3,4,4,4,4,5,4,3,5
]

let RED_SKY_FAZIO_HCS: [Int] = [
    11,9,15,3,1,13,7,5,17,
    4,2,16,10,8,14,6,18,12
]

// MARK: - Red Sky Golf Club – Norman Course — Wolcott, CO
private let RED_SKY_NORMAN_ID = UUID(uuidString: "AE2BFD95-F070-4F8D-C2E0-ED2EB7D3CF61")!

let RED_SKY_NORMAN_PARS: [Int] = [
    4,3,4,5,3,4,4,5,4,
    3,4,5,4,4,4,3,4,5
]

let RED_SKY_NORMAN_HCS: [Int] = [
    7,15,1,13,11,17,9,5,3,
    18,12,4,14,6,16,10,2,8
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

// MARK: - Wildhorse Golf Course — Davis, CA
// Par 72 | Daily-Fee | Architect: Jeffrey Brauer

private let WILDHORSE_GC_DAVIS_ID = UUID(uuidString: "C12A6D8E-1F44-4B7D-9E31-2A8C7F5D1005")!

let WILDHORSE_GC_DAVIS_PARS: [Int] = [
    4,4,4,3,5,3,5,4,4,
    4,4,3,5,3,4,4,5,4
]

let WILDHORSE_GC_DAVIS_HCS: [Int] = [
    9,15,1,7,3,17,11,5,13,
    18,16,10,8,14,4,12,6,2
]

let WILDHORSE_GC_DAVIS_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Red", yardage: 6793, rating: 72.8, slope: 134)
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

// MARK: Fishers Island Club — Fishers Island, NY
private let FISHERS_ISLAND_CLUB_ID = UUID(uuidString: "C9D0E1F2-A3B4-4C5D-6E7F-8A9B0C1D2E3F")!

let FISHERS_ISLAND_CLUB_PARS: [Int] = [
    4,3,4,4,3,5,4,4,4,
    4,3,4,4,4,5,3,4,4
]

let FISHERS_ISLAND_CLUB_HCS: [Int] = [
    7,13,9,1,5,11,3,17,15,
    4,12,6,8,2,14,18,10,16
]

let FISHERS_ISLAND_CLUB_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6597, rating: 72.8, slope: 144)
]

// MARK: Friar's Head — Baiting Hollow, NY
private let FRIARS_HEAD_ID = UUID(uuidString: "D0E1F2A3-B4C5-4D6E-7F8A-9B0C1D2E3F4A")!

let FRIARS_HEAD_PARS: [Int] = [
    4,5,4,3,4,4,5,3,4,
    3,5,3,4,5,4,4,3,4
]

let FRIARS_HEAD_HCS: [Int] = [
    9,7,1,13,15,3,5,17,11,
    16,12,14,2,10,8,6,18,4
]

let FRIARS_HEAD_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Back",      yardage: 7041, rating: 74.4, slope: 140),
    TeeInfo(teeName: "Composite", yardage: 6700, rating: 73.4, slope: 136),
    TeeInfo(teeName: "Member",    yardage: 6300, rating: 71.8, slope: 133),
    TeeInfo(teeName: "Short",     yardage: 5800, rating: 70.2, slope: 128)
]

// MARK: Winged Foot Golf Club — East — Mamaroneck, NY
private let WINGED_FOOT_EAST_ID = UUID(uuidString: "0A1B2C3D-E4F5-4A6B-7C8D-9E0F1A2B3C4E")!

let WINGED_FOOT_EAST_PARS: [Int] = [
    4,5,3,5,4,3,4,5,4,
    4,4,5,3,4,4,4,3,4
]

let WINGED_FOOT_EAST_HCS: [Int] = [
    13,5,17,1,9,11,3,15,7,
    12,8,2,18,6,10,4,16,14
]

let WINGED_FOOT_EAST_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue", yardage: 6737, rating: 73.6, slope: 140)
]

// MARK: Winged Foot Golf Club — West — Mamaroneck, NY
private let WINGED_FOOT_WEST_ID = UUID(uuidString: "0B1C2D3E-F4A5-4B6C-7D8E-9F0A1B2C3D4F")!

let WINGED_FOOT_WEST_PARS: [Int] = [
    4,4,3,4,5,4,3,4,5,
    3,4,5,3,4,4,4,5,4
]

let WINGED_FOOT_WEST_HCS: [Int] = [
    3,9,11,7,5,13,17,1,15,
    14,12,6,16,10,4,18,2,8
]

let WINGED_FOOT_WEST_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue", yardage: 7426, rating: 76.4, slope: 140)
]

// MARK: Shinnecock Hills Golf Club — Southampton, NY
private let SHINNECOCK_HILLS_ID = UUID(uuidString: "0C1D2E3F-A4B5-4C6D-7E8F-9A0B1C2D3E4A")!

let SHINNECOCK_HILLS_PARS: [Int] = [
    4,3,4,4,5,4,3,4,4,
    4,3,4,4,4,4,5,3,4
]

let SHINNECOCK_HILLS_HCS: [Int] = [
    11,17,3,7,9,1,15,13,5,
    4,16,2,12,6,14,8,18,10
]

let SHINNECOCK_HILLS_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Red",   yardage: 6940, rating: 74.7, slope: 145),
    TeeInfo(teeName: "Green", yardage: 6530, rating: 72.5, slope: 140),
    TeeInfo(teeName: "Blue",  yardage: 6141, rating: 70.8, slope: 135),
    TeeInfo(teeName: "White", yardage: 5396, rating: 72.8, slope: 135)
]

// MARK: National Golf Links of America — Southampton, NY
private let NGLA_ID = UUID(uuidString: "0D1E2F3A-B4C5-4D6E-7F8A-9B0C1D2E3F4B")!

let NGLA_PARS: [Int] = [
    4,4,4,3,4,3,5,4,5,
    4,4,4,3,4,4,4,4,5
]

let NGLA_HCS: [Int] = [
    11,15,1,13,3,17,9,5,7,
    4,10,2,18,12,6,14,16,8
]

let NGLA_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 6935, rating: 74.3, slope: 139),
    TeeInfo(teeName: "Regular",      yardage: 6505, rating: 72.3, slope: 133),
    TeeInfo(teeName: "Short",        yardage: 5771, rating: 68.8, slope: 127)
]

// MARK: Oak Hill Country Club — Rochester, NY

private let OAK_HILL_EAST_ID = UUID(uuidString: "0E1F2A3B-C4D5-4E6F-7A8B-9C0D1E2F3A4C")!

let OAK_HILL_EAST_PARS: [Int] = [
    4,4,3,5,3,4,4,4,4,
    4,3,4,5,4,3,4,5,4
]

let OAK_HILL_EAST_HCS: [Int] = [
    5,11,15,13,17,1,3,9,7,
    8,16,10,2,12,18,6,14,4
]

let OAK_HILL_EAST_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 7390, rating: 77.3, slope: 153),
    TeeInfo(teeName: "Black",        yardage: 6995, rating: 75.5, slope: 146),
    TeeInfo(teeName: "Blue",         yardage: 6655, rating: 74.0, slope: 141),
    TeeInfo(teeName: "White",        yardage: 6195, rating: 71.6, slope: 138),
    TeeInfo(teeName: "Gold",         yardage: 5595, rating: 69.0, slope: 130),
    TeeInfo(teeName: "Green",        yardage: 5265, rating: 67.2, slope: 127)
]

// MARK: Garden City Golf Club — Garden City, NY

private let GARDEN_CITY_GC_ID = UUID(uuidString: "5C6D7E8F-9A0B-4C1D-2E3F-4A5B6C7D8E9F")!

let GARDEN_CITY_GC_PARS: [Int] = [
    4,3,4,5,4,4,5,4,4,
    4,4,3,5,4,4,4,5,3
]

let GARDEN_CITY_GC_HCS: [Int] = [
    15,17,9,5,11,3,7,1,13,
    6,4,16,8,14,2,10,12,18
]

let GARDEN_CITY_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Back", yardage: 6926, rating: 74.0, slope: 141)
]

// MARK: Sleepy Hollow Country Club (Upper Course) — Briarcliff Manor, NY

private let SLEEPY_HOLLOW_UPPER_ID = UUID(uuidString: "6D7E8F9A-0B1C-4D2E-3F4A-5B6C7D8E9F0A")!

let SLEEPY_HOLLOW_UPPER_PARS: [Int] = [
    4,4,3,4,4,5,3,4,4,
    3,4,5,4,4,4,3,4,4
]

let SLEEPY_HOLLOW_UPPER_HCS: [Int] = [
    7,11,15,5,9,3,17,1,13,
    16,10,2,4,12,8,18,14,6
]

let SLEEPY_HOLLOW_UPPER_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6902, rating: 74.0, slope: 140)
]

// MARK: Sleepy Hollow CC — Lower Course (9-hole played twice)
private let SLEEPY_HOLLOW_LOWER_ID = UUID(uuidString: "B7A10000-0000-0000-0000-000000000133")!

let SLEEPY_HOLLOW_LOWER_PARS: [Int] = [
    4,3,3,4,3,4,3,4,3,   // Front (holes 1–9)
    4,3,3,4,3,4,3,4,3    // Back (same 9 repeated)
]

// Official HCPs not published; odd front / even back is standard convention for a repeated 9
let SLEEPY_HOLLOW_LOWER_HCS: [Int] = [
    1,3,5,7,9,11,13,15,17,
    2,4,6,8,10,12,14,16,18
]

let SLEEPY_HOLLOW_LOWER_TEES: [TeeInfo] = [
    TeeInfo(teeName: "White", yardage: 4216, slope: 110)   // 30.5 is the 9-hole rating
]

// MARK: The Creek Club — Locust Valley, NY

private let THE_CREEK_CLUB_ID = UUID(uuidString: "7E8F9A0B-1C2D-4E3F-4A5B-6C7D8E9F0A1B")!

let THE_CREEK_CLUB_PARS: [Int] = [
    4,4,4,3,4,4,5,3,4,
    4,3,4,4,4,4,4,3,5
]

let THE_CREEK_CLUB_HCS: [Int] = [
    9,7,11,17,13,1,5,15,3,
    10,16,14,4,2,8,6,18,12
]

let THE_CREEK_CLUB_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Silver", yardage: 6583, rating: 73.0, slope: 142)
]

// MARK: Sebonack Golf Club — Southampton, NY

private let SEBONACK_GC_ID = UUID(uuidString: "8F9A0B1C-2D3E-4F5A-6B7C-8D9E0F1A2B3C")!

let SEBONACK_GC_PARS: [Int] = [
    4,4,4,3,4,4,4,3,5,
    4,4,3,5,4,5,4,3,5
]

let SEBONACK_GC_HCS: [Int] = [
    15,1,5,13,17,7,3,11,9,
    12,2,18,4,8,6,14,16,10
]

let SEBONACK_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7220, rating: 0.0, slope: 0),
    TeeInfo(teeName: "Blue",  yardage: 6717, rating: 0.0, slope: 0),
    TeeInfo(teeName: "White", yardage: 6164, rating: 0.0, slope: 0)
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

// MARK: KAROO at Streamsong — Brooksville, FL
private let KAROO_STREAMSONG_ID = UUID(uuidString: "E1F2A3B4-C5D6-4E7F-8A9B-0C1D2E3F4A5B")!

let KAROO_STREAMSONG_PARS: [Int] = [
    4,4,3,5,4,5,3,4,4,
    3,4,4,4,5,4,3,5,4
]

let KAROO_STREAMSONG_HCS: [Int] = [
    9,7,1,17,5,15,13,11,3,
    8,14,4,2,12,16,10,18,6
]

let KAROO_STREAMSONG_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7562, rating: 75.2, slope: 140)
]

// MARK: - Tiburón Golf Club (Black Course)

private let TIBURON_BLACK_ID = UUID(uuidString: "F10A0000-0000-0000-0000-000000000001")!

let TIBURON_BLACK_PARS: [Int] = [
    4,4,4,3,4,5,3,4,5,
    3,4,4,3,4,5,4,4,5
]

let TIBURON_BLACK_HCS: [Int] = [
    5,1,9,15,7,17,11,3,13,
    16,14,8,18,6,12,2,4,10
]

let TIBURON_BLACK_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Gold", yardage: 6649),
    TeeInfo(teeName: "Black", yardage: 6465),
    TeeInfo(teeName: "White", yardage: 6197),
    TeeInfo(teeName: "Blue", yardage: 5590),
    TeeInfo(teeName: "Lavender", yardage: 4878),
    TeeInfo(teeName: "Family", yardage: 3975)
]

// MARK: - Tiburón Golf Club (Gold Course)

private let TIBURON_GOLD_ID = UUID(uuidString: "F10A0000-0000-0000-0000-000000000002")!

let TIBURON_GOLD_PARS: [Int] = [
    5,4,4,4,3,5,4,3,4,
    4,4,3,4,5,4,3,4,5
]

let TIBURON_GOLD_HCS: [Int] = [
    11,9,7,5,13,1,15,17,3,
    18,8,12,16,6,2,14,10,4
]

let TIBURON_GOLD_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Gold", yardage: 7382),
    TeeInfo(teeName: "Black", yardage: 6790),
    TeeInfo(teeName: "White", yardage: 6127),
    TeeInfo(teeName: "Blue", yardage: 5692),
    TeeInfo(teeName: "Lavender", yardage: 5112)
]

// MARK: - Naples Beach Club (Four Seasons)

private let NAPLES_BEACH_CLUB_ID = UUID(uuidString: "F10A0000-0000-0000-0000-000000000003")!

let NAPLES_BEACH_CLUB_PARS: [Int] = [
    4,4,5,3,4,4,4,3,4,
    4,5,3,4,5,4,3,4,4
]

let NAPLES_BEACH_CLUB_HCS: [Int] = [
    11,13,1,17,7,5,9,15,3,
    12,10,18,14,2,4,16,8,6
]

let NAPLES_BEACH_CLUB_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Tournament", yardage: 6884, rating: 73.1, slope: 135)
]

// MARK: - Lely Resort (Mustang Course)

private let LELY_MUSTANG_ID = UUID(uuidString: "F10A0000-0000-0000-0000-000000000004")!

let LELY_MUSTANG_PARS: [Int] = [
    5,4,4,4,3,4,5,3,4,
    5,4,3,4,5,4,3,4,4
]

let LELY_MUSTANG_HCS: [Int] = [
    11,9,7,1,17,5,13,15,3,
    10,4,14,6,8,2,16,12,18
]

let LELY_MUSTANG_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 7230, rating: 75.1, slope: 134),
    TeeInfo(teeName: "Back", yardage: 6627, rating: 72.4, slope: 128),
    TeeInfo(teeName: "Mustang", yardage: 6242, rating: 70.6, slope: 123),
    TeeInfo(teeName: "Middle", yardage: 6018),
    TeeInfo(teeName: "White/Aqua", yardage: 5567, rating: 68.0, slope: 119),
    TeeInfo(teeName: "Forward", yardage: 5249),
    TeeInfo(teeName: "Family", yardage: 4491)
]

// MARK: - Lely Resort (Flamingo Island Course)

private let LELY_FLAMINGO_ID = UUID(uuidString: "F10A0000-0000-0000-0000-000000000005")!

let LELY_FLAMINGO_PARS: [Int] = [
    4,5,3,4,3,4,4,5,4,
    4,3,5,4,4,3,5,4,4
]

let LELY_FLAMINGO_HCS: [Int] = [
    9,7,17,1,11,15,13,3,5,
    16,14,2,12,10,18,6,4,8
]

let LELY_FLAMINGO_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 7095, rating: 75.3, slope: 140),
    TeeInfo(teeName: "Back", yardage: 6454, rating: 71.9, slope: 137),
    TeeInfo(teeName: "Flamingo", yardage: 6180, rating: 70.3, slope: 131),
    TeeInfo(teeName: "Middle", yardage: 5996),
    TeeInfo(teeName: "White/Aqua", yardage: 5515, rating: 68.5, slope: 125),
    TeeInfo(teeName: "Forward", yardage: 5313),
    TeeInfo(teeName: "Family", yardage: 4477)
]

// MARK: - Lely Resort (Classics Course)

private let LELY_CLASSICS_ID = UUID(uuidString: "F10A0000-0000-0000-0000-000000000006")!

let LELY_CLASSICS_PARS: [Int] = [
    4,4,5,3,4,3,5,4,4,
    4,5,3,4,4,4,3,5,4
]

let LELY_CLASSICS_HCS: [Int] = [
    13,9,1,11,7,17,5,15,3,
    6,8,16,18,4,12,14,10,2
]

let LELY_CLASSICS_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6714, rating: 72.7, slope: 134),
    TeeInfo(teeName: "Green", yardage: 6239, rating: 70.0, slope: 128),
    TeeInfo(teeName: "Green/White", yardage: 5896, rating: 69.0, slope: 124),
    TeeInfo(teeName: "White", yardage: 5750, rating: 68.0, slope: 122),
    TeeInfo(teeName: "Red", yardage: 5209, rating: 66.2, slope: 114)
]

// MARK: - King & Bear (World Golf Village)

private let KING_BEAR_WGV_ID = UUID(uuidString: "F10A0000-0000-0000-0000-000000000007")!

let KING_BEAR_WGV_PARS: [Int] = [
    4,3,4,5,3,4,4,4,5,
    4,4,3,4,5,3,5,4,4
]

let KING_BEAR_WGV_HCS: [Int] = [
    3,11,5,9,17,7,1,15,13,
    6,14,12,8,18,16,4,10,2
]

let KING_BEAR_WGV_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Stone", yardage: 7279, rating: 74.6, slope: 141),
    TeeInfo(teeName: "Black", yardage: 6855, rating: 72.5, slope: 138),
    TeeInfo(teeName: "Blue", yardage: 6506, rating: 70.6, slope: 133),
    TeeInfo(teeName: "White", yardage: 5987),
    TeeInfo(teeName: "Green", yardage: 5119)
]

// MARK: - Slammer & Squire (World Golf Village)

private let SLAMMER_SQUIRE_WGV_ID = UUID(uuidString: "F10A0000-0000-0000-0000-000000000008")!

let SLAMMER_SQUIRE_WGV_PARS: [Int] = [
    4,3,4,5,4,4,3,5,4,
    4,5,4,3,4,3,5,4,4
]

let SLAMMER_SQUIRE_WGV_HCS: [Int] = [
    9,15,13,3,1,5,17,11,7,
    14,12,2,16,18,10,6,4,8
]

let SLAMMER_SQUIRE_WGV_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Stone", yardage: 6939, rating: 72.8, slope: 132),
    TeeInfo(teeName: "Black", yardage: 6660, rating: 71.2, slope: 129),
    TeeInfo(teeName: "Blue", yardage: 6132, rating: 68.9, slope: 124),
    TeeInfo(teeName: "White", yardage: 5711),
    TeeInfo(teeName: "Green", yardage: 4996)
]

// MARK: - Crandon Golf at Key Biscayne

private let CRANDON_KEY_BISCAYNE_ID = UUID(uuidString: "F10A0000-0000-0000-0000-000000000009")!

let CRANDON_KEY_BISCAYNE_PARS: [Int] = [
    5,4,3,5,4,3,4,3,4,
    5,4,3,4,5,4,4,3,5
]

let CRANDON_KEY_BISCAYNE_HCS: [Int] = [
    8,6,12,4,10,16,2,18,14,
    5,1,9,7,11,3,17,15,13
]

let CRANDON_KEY_BISCAYNE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 7182, rating: 75.1, slope: 146),
    TeeInfo(teeName: "Blue", yardage: 6866, rating: 73.7, slope: 142),
    TeeInfo(teeName: "White", yardage: 6424, rating: 71.8, slope: 135),
    TeeInfo(teeName: "Green", yardage: 5788, rating: 69.0, slope: 126),
    TeeInfo(teeName: "Yellow", yardage: 5342),
    TeeInfo(teeName: "Junior", yardage: 3786)
]

// MARK: - Trump National Doral (Red Tiger Course)

private let TRUMP_DORAL_RED_TIGER_ID = UUID(uuidString: "C8D20000-0000-0000-0000-000000000102")!

let TRUMP_DORAL_RED_TIGER_PARS: [Int] = [
    5,3,5,4,5,3,4,3,4,
    5,3,5,4,3,4,3,4,5
]

let TRUMP_DORAL_RED_TIGER_HCS: [Int] = [
    3,13,9,5,1,17,7,15,11,
    4,16,2,12,18,8,10,14,6
]

let TRUMP_DORAL_RED_TIGER_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6395, rating: 71.8, slope: 136),
    TeeInfo(teeName: "Gold", yardage: 5918, rating: 69.6, slope: 132),
    TeeInfo(teeName: "Blue", yardage: 5660, rating: 68.6, slope: 127),
    TeeInfo(teeName: "White", yardage: 5229, rating: 66.2, slope: 120),
    TeeInfo(teeName: "Red", yardage: 4525)
]

// MARK: - Trump National Doral (Silver Fox Course)

private let TRUMP_DORAL_SILVER_FOX_ID = UUID(uuidString: "C8D20000-0000-0000-0000-000000000103")!

let TRUMP_DORAL_SILVER_FOX_PARS: [Int] = [
    4,4,5,3,4,4,3,4,4,
    4,5,4,4,4,3,5,3,4
]

let TRUMP_DORAL_SILVER_FOX_HCS: [Int] = [
    10,12,14,8,18,2,4,6,16,
    5,3,1,15,11,13,17,7,9
]

let TRUMP_DORAL_SILVER_FOX_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7006, rating: 74.9, slope: 148),
    TeeInfo(teeName: "Gold", yardage: 6398, rating: 72.6, slope: 143),
    TeeInfo(teeName: "Blue", yardage: 5861, rating: 69.8, slope: 135),
    TeeInfo(teeName: "White", yardage: 5462, rating: 67.6, slope: 128),
    TeeInfo(teeName: "Red", yardage: 4478)
]

// MARK: - Trump National Doral (Golden Palm Course)

private let TRUMP_DORAL_GOLDEN_PALM_ID = UUID(uuidString: "C8D20000-0000-0000-0000-000000000104")!

let TRUMP_DORAL_GOLDEN_PALM_PARS: [Int] = [
    4,5,4,5,4,4,3,4,3,
    4,5,3,4,4,3,5,3,4
]

let TRUMP_DORAL_GOLDEN_PALM_HCS: [Int] = [
    11,7,9,1,3,13,15,5,17,
    10,2,18,12,4,16,6,14,8
]

let TRUMP_DORAL_GOLDEN_PALM_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7012, rating: 74.2, slope: 139),
    TeeInfo(teeName: "Gold", yardage: 6324, rating: 72.0, slope: 134),
    TeeInfo(teeName: "Blue", yardage: 6002, rating: 69.9, slope: 133),
    TeeInfo(teeName: "White", yardage: 5653, rating: 68.6, slope: 128),
    TeeInfo(teeName: "Red", yardage: 4858)
]

// MARK: - Ritz-Carlton Golf Club Orlando (Grande Lakes)

private let RITZ_CARLTON_ORLANDO_ID = UUID(uuidString: "F10A0000-0000-0000-0000-000000000010")!

let RITZ_CARLTON_ORLANDO_PARS: [Int] = [
    4,4,5,3,5,4,4,3,4,
    4,4,3,4,5,4,4,3,5
]

let RITZ_CARLTON_ORLANDO_HCS: [Int] = [
    10,6,8,18,4,12,14,16,2,
    11,13,17,15,3,1,7,9,5
]

let RITZ_CARLTON_ORLANDO_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7066, rating: 73.7, slope: 134)
]

// MARK: - Disney's Magnolia Golf Course

private let DISNEY_MAGNOLIA_ID = UUID(uuidString: "F10A0000-0000-0000-0000-000000000011")!

let DISNEY_MAGNOLIA_PARS: [Int] = [
    4,4,3,5,4,3,4,5,4,
    5,4,3,4,4,5,4,3,4
]

let DISNEY_MAGNOLIA_HCS: [Int] = [
    3,13,15,17,1,11,7,9,5,
    6,14,18,16,2,12,4,10,8
]

let DISNEY_MAGNOLIA_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Classic", yardage: 7505, rating: 76.6, slope: 142),
    TeeInfo(teeName: "Green", yardage: 6965, rating: 74.1, slope: 137),
    TeeInfo(teeName: "White", yardage: 6574, rating: 72.3, slope: 133),
    TeeInfo(teeName: "Yellow", yardage: 6146, rating: 70.2, slope: 129),
    TeeInfo(teeName: "Red", yardage: 5200)
]

// MARK: - Disney's Palm Golf Course

private let DISNEY_PALM_ID = UUID(uuidString: "F10A0000-0000-0000-0000-000000000012")!

let DISNEY_PALM_PARS: [Int] = [
    5,4,3,4,4,4,5,3,4,
    4,5,3,4,5,4,3,4,4
]

let DISNEY_PALM_HCS: [Int] = [
    11,3,13,17,7,1,5,9,15,
    4,10,18,6,8,12,16,14,2
]

let DISNEY_PALM_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Classic", yardage: 6925, rating: 73.7, slope: 137)
]

// MARK: - Disney's Osprey Ridge Golf Course

private let DISNEY_OSPREY_RIDGE_ID = UUID(uuidString: "F10A0000-0000-0000-0000-000000000013")!

let DISNEY_OSPREY_RIDGE_PARS: [Int] = [
    4,4,4,3,4,3,4,5,4,
    5,4,4,5,3,4,4,5,3
]

let DISNEY_OSPREY_RIDGE_HCS: [Int] = [
    15,11,9,17,3,13,7,1,5,
    6,12,14,8,18,2,16,4,10
]

let DISNEY_OSPREY_RIDGE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Talon", yardage: 6968, rating: 73.5, slope: 126)
]

// MARK: - Waldorf Astoria Golf Club Orlando

private let WALDORF_ASTORIA_ORLANDO_ID = UUID(uuidString: "F10A0000-0000-0000-0000-000000000014")!

let WALDORF_ASTORIA_ORLANDO_PARS: [Int] = [
    4,3,4,5,4,4,3,5,4,
    4,3,5,4,4,4,3,5,4
]

let WALDORF_ASTORIA_ORLANDO_HCS: [Int] = [
    17,15,3,11,7,1,13,9,5,
    12,8,4,18,2,10,16,14,6
]

let WALDORF_ASTORIA_ORLANDO_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7104, rating: 74.5, slope: 145),
    TeeInfo(teeName: "Blue", yardage: 6638, rating: 72.4, slope: 140),
    TeeInfo(teeName: "White", yardage: 6257, rating: 70.7, slope: 135),
    TeeInfo(teeName: "Green", yardage: 5761, rating: 68.3, slope: 128),
    TeeInfo(teeName: "Silver", yardage: 4986, rating: 69.0, slope: 127)
]

// MARK: - TPC San Antonio (AT&T Canyons Course)

private let TPC_SAN_ANTONIO_CANYONS_ID = UUID(uuidString: "F10A0000-0000-0000-0000-000000000015")!

let TPC_SAN_ANTONIO_CANYONS_PARS: [Int] = [
    4,5,4,3,4,5,4,3,4,
    4,4,5,3,4,5,3,4,4
]

let TPC_SAN_ANTONIO_CANYONS_HCS: [Int] = [
    15,5,17,11,1,7,9,13,3,
    14,4,10,12,2,18,8,16,6
]

let TPC_SAN_ANTONIO_CANYONS_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Cibolo", yardage: 7106, rating: 73.6, slope: 129),
    TeeInfo(teeName: "Tournament", yardage: 6622),
    TeeInfo(teeName: "Players", yardage: 6142, rating: 69.6, slope: 127),
    TeeInfo(teeName: "Club", yardage: 5609, rating: 67.5, slope: 120),
    TeeInfo(teeName: "Forward", yardage: 4968)
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
// MARK: - Lost Dunes Golf Club — Bridgman, MI
// Par 71 | 6928 yds | Rating 73.9 | Slope 140
// Type: Private | Architect: Tom Doak

private let LOST_DUNES_ID = UUID(uuidString: "C12A6D8E-1F44-4B7D-9E31-2A8C7F5D1002")!

let LOST_DUNES_PARS: [Int] = [
    4,4,3,5,3,4,4,5,3,
    5,4,4,3,4,5,3,4,4
]

let LOST_DUNES_HCS: [Int] = [
    13,5,17,9,11,3,7,1,15,
    10,4,12,18,14,6,16,2,8
]

let LOST_DUNES_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6928, rating: 73.9, slope: 140)
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

// MARK: - Bay Harbor Golf Club — Bay Harbor, MI
private let BAY_HARBOR_LQ_ID = UUID(uuidString: "FA1B2C3D-4E5F-4A6B-7C8D-9E0F1A2B3C4D")!
let BAY_HARBOR_LQ_PARS: [Int] = [4,4,4,3,4,4,5,3,5, 4,3,5,4,5,4,4,3,4]
let BAY_HARBOR_LQ_HCS: [Int]  = [6,10,8,18,12,2,14,16,4, 13,17,5,9,1,11,3,15,7]
let BAY_HARBOR_LQ_TEES: [TeeInfo] = [TeeInfo(teeName: "Black", yardage: 6845)]

private let BAY_HARBOR_LP_ID = UUID(uuidString: "EA1B2C3D-4E5F-4A6B-7C8D-9E0F1A2B3C4E")!
let BAY_HARBOR_LP_PARS: [Int] = [4,3,4,4,3,5,4,3,5, 4,3,4,5,4,3,4,5,4]
let BAY_HARBOR_LP_HCS: [Int]  = [7,11,3,1,13,9,5,15,17, 8,14,2,6,12,16,10,18,4]
let BAY_HARBOR_LP_TEES: [TeeInfo] = [TeeInfo(teeName: "Black", yardage: 6217)]

private let BAY_HARBOR_QP_ID = UUID(uuidString: "8A1B2C3D-4E5F-4A6B-7C8D-9E0F1A2B3C44")!
let BAY_HARBOR_QP_PARS: [Int] = [4,4,4,4,4,3,4,5,4, 4,3,4,5,4,3,4,5,4]
let BAY_HARBOR_QP_HCS: [Int]  = [11,17,15,1,13,9,5,7,3, 8,14,2,6,12,16,10,18,4]
let BAY_HARBOR_QP_TEES: [TeeInfo] = [TeeInfo(teeName: "Black", yardage: 5954)]

// MARK: - Boyne Highlands — Harbor Springs, MI
private let THE_HEATHER_ID = UUID(uuidString: "DA1B2C3D-4E5F-4A6B-7C8D-9E0F1A2B3C4F")!
let THE_HEATHER_PARS: [Int] = [4,4,4,3,5,3,4,4,5, 4,5,3,4,4,5,3,4,4]
let THE_HEATHER_HCS: [Int]  = [15,5,13,11,1,17,7,3,9, 6,18,16,8,10,2,14,12,4]
let THE_HEATHER_TEES: [TeeInfo] = [TeeInfo(teeName: "Black", yardage: 7123)]

private let ARTHUR_HILLS_BH_ID = UUID(uuidString: "CA1B2C3D-4E5F-4A6B-7C8D-9E0F1A2B3C40")!
let ARTHUR_HILLS_BH_PARS: [Int] = [4,4,5,4,4,5,3,4,3, 4,5,4,5,3,4,3,4,5]
let ARTHUR_HILLS_BH_HCS: [Int]  = [9,17,5,7,1,13,15,3,11, 18,4,8,14,12,2,16,6,10]
let ARTHUR_HILLS_BH_TEES: [TeeInfo] = [TeeInfo(teeName: "Black", yardage: 7312)]

private let THE_MOOR_ID = UUID(uuidString: "7A1B2C3D-4E5F-4A6B-7C8D-9E0F1A2B3C45")!
let THE_MOOR_PARS: [Int] = [4,4,5,3,4,3,4,5,4, 4,3,4,4,5,4,3,5,4]
let THE_MOOR_HCS: [Int]  = [5,15,17,9,1,7,11,13,3, 4,14,10,8,18,2,6,16,12]
let THE_MOOR_TEES: [TeeInfo] = [TeeInfo(teeName: "Black", yardage: 6787)]

private let CROOKED_TREE_GC_ID = UUID(uuidString: "6A1B2C3D-4E5F-4A6B-7C8D-9E0F1A2B3C46")!
let CROOKED_TREE_GC_PARS: [Int] = [4,4,4,5,3,5,4,4,3, 4,4,4,3,4,4,5,3,5]
let CROOKED_TREE_GC_HCS: [Int]  = [12,14,4,8,10,2,16,18,6, 5,9,7,17,11,1,13,15,3]
let CROOKED_TREE_GC_TEES: [TeeInfo] = [TeeInfo(teeName: "Black", yardage: 6640, rating: 73.2, slope: 137)]

// MARK: - Crooked Tree Golf Course — Browns Summit, NC
private let NC_CROOKED_TREE_ID = UUID(uuidString: "5A1B2C3D-4E5F-4A6B-7C8D-9E0F1A2B3C47")!
let NC_CROOKED_TREE_PARS: [Int] = [4,4,4,4,4,4,3,4,5, 4,3,4,3,5,4,4,5,4]
let NC_CROOKED_TREE_HCS: [Int]  = [9,1,7,3,11,13,5,17,15, 10,8,6,14,18,4,2,12,16]
let NC_CROOKED_TREE_TEES: [TeeInfo] = [TeeInfo(teeName: "Black", yardage: 6468, rating: 71.5, slope: 133)]

// MARK: - True North Golf Club — Harbor Springs, MI
private let TRUE_NORTH_GC_ID = UUID(uuidString: "BA1B2C3D-4E5F-4A6B-7C8D-9E0F1A2B3C41")!
let TRUE_NORTH_GC_PARS: [Int] = [5,4,3,4,3,4,5,5,4, 3,4,5,3,4,4,3,4,5]
let TRUE_NORTH_GC_HCS: [Int]  = [7,3,13,9,17,11,15,1,5, 14,10,8,18,2,12,16,4,6]
let TRUE_NORTH_GC_TEES: [TeeInfo] = [TeeInfo(teeName: "Black", yardage: 7009)]

// MARK: - Tullymore Golf Club — Stanwood, MI
private let TULLYMORE_GC_ID = UUID(uuidString: "AA1B2C3D-4E5F-4A6B-7C8D-9E0F1A2B3C42")!
let TULLYMORE_GC_PARS: [Int] = [5,4,4,3,3,4,3,5,4, 4,4,3,5,4,3,5,4,5]
let TULLYMORE_GC_HCS: [Int]  = [5,1,9,13,17,11,15,3,7, 4,14,16,8,6,18,2,12,10]
let TULLYMORE_GC_TEES: [TeeInfo] = [TeeInfo(teeName: "Black", yardage: 6550)]

// MARK: - Pilgrim's Run Golf Club — Pierson, MI
private let PILGRIMS_RUN_GC_ID = UUID(uuidString: "9A1B2C3D-4E5F-4A6B-7C8D-9E0F1A2B3C43")!
let PILGRIMS_RUN_GC_PARS: [Int] = [5,4,4,3,4,5,3,4,4, 4,5,4,5,4,3,4,4,4]
let PILGRIMS_RUN_GC_HCS: [Int]  = [1,9,13,17,11,15,3,7,5, 4,14,8,6,18,2,10,12,16]
let PILGRIMS_RUN_GC_TEES: [TeeInfo] = [TeeInfo(teeName: "Black", yardage: 7093)]

// MARK: - Eagle Eye Golf Club — Bath Township, MI
private let EAGLE_EYE_GC_ID = UUID(uuidString: "4A1B2C3D-4E5F-4A6B-7C8D-9E0F1A2B3C48")!
let EAGLE_EYE_GC_PARS: [Int] = [4,3,4,5,3,4,4,4,5, 4,4,3,4,5,4,4,3,5]
let EAGLE_EYE_GC_HCS: [Int]  = [3,17,11,1,5,15,13,7,9, 16,12,8,2,18,14,4,10,6]
let EAGLE_EYE_GC_TEES: [TeeInfo] = [TeeInfo(teeName: "Gold", yardage: 6412, rating: 71.4, slope: 136)]

// MARK: - Greywalls Golf Course — Marquette, MI
private let GREYWALLS_GC_ID = UUID(uuidString: "3A1B2C3D-4E5F-4A6B-7C8D-9E0F1A2B3C49")!
let GREYWALLS_GC_PARS: [Int] = [5,4,3,4,4,3,4,4,4, 4,4,4,5,4,3,4,3,5]
let GREYWALLS_GC_HCS: [Int]  = [7,3,17,6,13,10,2,14,9, 16,11,1,5,4,8,12,18,15]
let GREYWALLS_GC_TEES: [TeeInfo] = [TeeInfo(teeName: "Black", yardage: 6828, rating: 73.0, slope: 144)]

// MARK: - Harbor Shores Resort — Benton Harbor, MI
private let HARBOR_SHORES_GC_ID = UUID(uuidString: "2A1B2C3D-4E5F-4A6B-7C8D-9E0F1A2B3C4A")!
let HARBOR_SHORES_GC_PARS: [Int] = [4,3,4,3,5,4,4,4,5, 5,3,4,3,4,5,4,3,4]
let HARBOR_SHORES_GC_HCS: [Int]  = [11,17,15,5,7,1,3,9,13, 12,18,10,16,2,8,4,14,6]
let HARBOR_SHORES_GC_TEES: [TeeInfo] = [TeeInfo(teeName: "Black", yardage: 6734, rating: 73.6, slope: 146)]

// MARK: - Stoatin Brae Golf Club — Augusta, MI
private let STOATIN_BRAE_GC_ID = UUID(uuidString: "1A1B2C3D-4E5F-4A6B-7C8D-9E0F1A2B3C4B")!
let STOATIN_BRAE_GC_PARS: [Int] = [4,3,4,4,4,5,3,4,5, 4,3,4,4,3,4,5,3,5]
let STOATIN_BRAE_GC_HCS: [Int]  = [17,11,3,1,7,13,9,15,5, 12,10,4,2,16,8,14,18,6]
let STOATIN_BRAE_GC_TEES: [TeeInfo] = [TeeInfo(teeName: "Gold", yardage: 6722, rating: 71.7, slope: 123)]

// MARK: - Gull Lake View East — Augusta, MI
private let GULL_LAKE_VIEW_EAST_ID = UUID(uuidString: "0A1B2C3D-4E5F-4A6B-7C8D-9E0F1A2B3C4C")!
let GULL_LAKE_VIEW_EAST_PARS: [Int] = [4,3,4,4,4,3,4,4,5, 5,3,4,4,4,3,4,4,4]
let GULL_LAKE_VIEW_EAST_HCS: [Int]  = [13,9,5,1,15,11,3,7,17, 14,12,6,8,10,16,18,4,2]
let GULL_LAKE_VIEW_EAST_TEES: [TeeInfo] = [TeeInfo(teeName: "Green", yardage: 6032)]

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

// MARK: SentryWorld — Stevens Point, WI
private let SENTRYWORLD_ID = UUID(uuidString: "F2A3B4C5-D6E7-4F8A-9B0C-1D2E3F4A5B6C")!

let SENTRYWORLD_PARS: [Int] = [
    4,4,3,4,5,4,3,4,5,
    5,4,3,4,5,4,3,4,4
]

let SENTRYWORLD_HCS: [Int] = [
    7,5,17,13,1,9,15,11,3,
    4,14,18,12,2,10,16,8,6
]

let SENTRYWORLD_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 7320, rating: 76.6, slope: 151),
    TeeInfo(teeName: "Black",        yardage: 7102, rating: 75.7, slope: 145),
    TeeInfo(teeName: "Blue",         yardage: 6543, rating: 72.9, slope: 137),
    TeeInfo(teeName: "White",        yardage: 5961, rating: 69.9, slope: 129),
    TeeInfo(teeName: "Gold",         yardage: 5452, rating: 67.5, slope: 120),
    TeeInfo(teeName: "Green",        yardage: 4652, rating: 68.2, slope: 116)
]

// MARK: Blue Mound Golf & Country Club — Wauwatosa, WI
private let BLUE_MOUND_GCC_ID = UUID(uuidString: "B7A10000-0000-0000-0000-000000000134")!

let BLUE_MOUND_GCC_PARS: [Int] = [
    4,4,3,4,5,4,3,4,4,
    4,4,4,3,4,4,4,3,5
]

let BLUE_MOUND_GCC_HCS: [Int] = [
    9,7,1,5,17,13,15,3,11,
    8,10,4,14,12,2,18,16,6
]

let BLUE_MOUND_GCC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6854, rating: 72.9, slope: 133)
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
private let KNOLLWOOD_CLUB_ID = UUID(uuidString: "A1B2C3D4-1111-4AAA-8C11-100000000402")!

let KNOLLWOOD_CLUB_PARS: [Int] = [
    5,4,4,3,4,5,3,5,4,
    5,4,3,4,4,4,5,3,5
]

let KNOLLWOOD_CLUB_HCS: [Int] = [
    7,5,9,15,1,11,17,3,13,
    2,8,16,10,4,6,14,18,12
]

let KNOLLWOOD_CLUB_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Back", yardage: 7202, rating: 75.0, slope: 140),
    TeeInfo(teeName: "Member", yardage: 6682, rating: 72.5, slope: 136)
]
private let BOB_OLINK_ID = UUID(uuidString: "A1B2C3D4-1111-4AAA-8C11-100000000403")!

let BOB_OLINK_PARS: [Int] = [
    4,4,4,3,5,5,4,3,4,
    5,4,3,4,4,4,3,4,4
]

let BOB_OLINK_HCS: [Int] = [
    5,11,3,17,1,9,13,15,7,
    2,12,14,4,6,8,18,16,10
]

let BOB_OLINK_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Green", yardage: 7247, rating: 75.6, slope: 140)
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

// MARK: Sweetens Cove Golf Club — South Pittsburg, TN
private let SWEETENS_COVE_GC_ID = UUID(uuidString: "E5F6A7B8-C9D0-4E1F-2A3B-4C5D6E7F8A9B")!

let SWEETENS_COVE_GC_PARS: [Int] = [
    5,4,5,3,4,4,4,4,3,
    5,4,5,3,4,4,4,4,3
]

let SWEETENS_COVE_GC_HCS: [Int] = [
    3,9,5,13,15,1,11,7,17,
    4,10,6,14,16,2,12,8,18
]

let SWEETENS_COVE_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6602, rating: 70.0, slope: 120)
]

// MARK: The Honors Course — Ooltewah, TN
private let HONORS_COURSE_ID = UUID(uuidString: "F6A7B8C9-D0E1-4F2A-3B4C-5D6E7F8A9B0C")!

let HONORS_COURSE_PARS: [Int] = [
    4,5,3,4,4,5,4,3,4,
    4,5,4,4,3,4,3,5,4
]

let HONORS_COURSE_HCS: [Int] = [
    9,17,13,5,3,11,1,15,7,
    4,12,8,14,16,2,10,18,6
]

let HONORS_COURSE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Silver", yardage: 7694, rating: 78.3, slope: 155)
]

// MARK: Hermitage Golf Course (President's Reserve) — Old Hickory, TN
private let HERMITAGE_PR_ID = UUID(uuidString: "B8C9D0E1-F2A3-4B4C-5D6E-7F8A9B0C1D2E")!

let HERMITAGE_PR_PARS: [Int] = [
    4,5,3,4,4,4,3,5,4,
    4,4,3,4,5,3,4,4,5
]

let HERMITAGE_PR_HCS: [Int] = [
    18,2,14,16,6,12,10,4,8,
    15,3,13,1,5,11,9,17,7
]

let HERMITAGE_PR_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7157, rating: 74.8, slope: 134),
    TeeInfo(teeName: "Gold",  yardage: 6792, rating: 73.0, slope: 130),
    TeeInfo(teeName: "Blue",  yardage: 6443, rating: 71.2, slope: 126),
    TeeInfo(teeName: "White", yardage: 6056, rating: 69.0, slope: 121),
    TeeInfo(teeName: "Green", yardage: 5669, rating: 66.8, slope: 115)
]

// MARK: Gaylord Springs Golf Links — Nashville, TN
private let GAYLORD_SPRINGS_ID = UUID(uuidString: "E7F8A9B0-C1D2-4E3F-4A5B-6C7D8E9F0A1B")!

let GAYLORD_SPRINGS_PARS: [Int] = [
    5,4,3,4,4,5,4,3,4,
    5,4,5,3,4,4,4,3,4
]

let GAYLORD_SPRINGS_HCS: [Int] = [
    9,3,15,11,1,7,5,17,13,
    10,4,8,18,12,6,14,16,2
]

let GAYLORD_SPRINGS_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6981, rating: 73.1, slope: 133)
]

// MARK: Tennessee National — Loudon, TN
private let TENNESSEE_NATIONAL_ID = UUID(uuidString: "D6E7F8A9-B0C1-4D2E-3F4A-5B6C7D8E9F0A")!

let TENNESSEE_NATIONAL_PARS: [Int] = [
    4,5,3,5,4,4,3,4,4,
    4,5,3,4,5,4,4,3,4
]

let TENNESSEE_NATIONAL_HCS: [Int] = [
    11,5,13,1,9,7,17,15,3,
    4,2,16,12,10,14,6,18,8
]

let TENNESSEE_NATIONAL_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7393, rating: 75.8, slope: 140)
]

// MARK: Black Creek Golf Club — Ellabell, GA
private let BLACK_CREEK_GC_GA_ID = UUID(uuidString: "A7B8C9D0-E1F2-4A3B-4C5D-6E7F8A9B0C1D")!

let BLACK_CREEK_GC_GA_PARS: [Int] = [
    4,3,4,5,4,3,4,5,4,
    5,3,4,4,4,3,5,4,4
]

let BLACK_CREEK_GC_GA_HCS: [Int] = [
    15,9,1,13,11,5,3,17,7,
    14,18,4,12,6,10,16,8,2
]

let BLACK_CREEK_GC_GA_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue", yardage: 6335, rating: 70.2, slope: 128)
]

// MARK: Lookout Mountain Golf Club — Lookout Mountain, GA
private let LOOKOUT_MOUNTAIN_GC_ID = UUID(uuidString: "F8A9B0C1-D2E3-4F4A-5B6C-7D8E9F0A1B2C")!

let LOOKOUT_MOUNTAIN_GC_PARS: [Int] = [
    4,4,4,3,4,3,4,4,4,
    5,4,4,3,5,4,3,4,4
]

let LOOKOUT_MOUNTAIN_GC_HCS: [Int] = [
    7,3,9,5,11,17,1,15,13,
    4,16,18,14,6,2,8,10,12
]

let LOOKOUT_MOUNTAIN_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue", yardage: 6613, rating: 72.0, slope: 128)
]

// MARK: Blessings Golf Club — Fayetteville, AR
private let BLESSINGS_GC_ID = UUID(uuidString: "A9B0C1D2-E3F4-4A5B-6C7D-8E9F0A1B2C3D")!

let BLESSINGS_GC_PARS: [Int] = [
    4,5,3,4,5,4,4,3,4,
    5,4,4,3,4,5,4,3,4
]

let BLESSINGS_GC_HCS: [Int] = [
    5,15,9,11,1,7,3,17,13,
    6,14,8,12,2,16,10,18,4
]

let BLESSINGS_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 8015, rating: 81.0, slope: 155)
]

// MARK: The Alotian Club — Roland, AR
private let ALOTIAN_CLUB_ID = UUID(uuidString: "B0C1D2E3-F4A5-4B6C-7D8E-9F0A1B2C3D4E")!

let ALOTIAN_CLUB_PARS: [Int] = [
    5,4,4,3,4,3,4,5,4,
    4,3,4,4,5,4,3,5,4
]

let ALOTIAN_CLUB_HCS: [Int] = [
    15,9,13,7,5,11,1,17,3,
    14,18,4,16,12,6,10,8,2
]

let ALOTIAN_CLUB_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 7272, rating: 75.6, slope: 137)
]

private let SHOREACRES_ID = UUID(uuidString: "A1B2C3D4-1111-4AAA-8C11-100000000404")!

let SHOREACRES_PARS: [Int] = [
    5,4,4,4,4,3,4,3,4,
    4,4,3,4,3,5,4,4,5
]

let SHOREACRES_HCS: [Int] = [
    15,9,17,5,1,11,3,13,7,
    2,8,18,6,10,16,4,14,12
]

let SHOREACRES_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6725, rating: 73.2, slope: 142)
]
private let EXMOOR_CC_ID = UUID(uuidString: "A1B2C3D4-1111-4AAA-8C11-100000000405")!

let EXMOOR_CC_PARS: [Int] = [
    5,4,4,4,3,5,4,3,4,
    4,5,3,4,3,5,4,4,4
]

let EXMOOR_CC_HCS: [Int] = [
    17,3,5,1,11,15,7,13,9,
    4,10,18,16,14,12,2,6,8
]

let EXMOOR_CC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7180, rating: 75.0, slope: 140)
]
private let BOWES_CREEK_ID = UUID(uuidString: "A7A10006-0000-0000-0000-000000000006")!

let BOWES_CREEK_PARS: [Int] = [
    4,4,3,4,3,5,4,5,4,
    5,4,4,4,3,4,3,4,4
]

let BOWES_CREEK_HCS: [Int] = [
    9,7,17,11,15,3,5,1,13,
    2,10,8,14,18,4,16,12,6
]

let BOWES_CREEK_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6794, rating: 73.6, slope: 143)
]
private let THUNDERHAWK_ID = UUID(uuidString: "A7A10005-0000-0000-0000-000000000005")!

let THUNDERHAWK_PARS: [Int] = [
    4,5,3,4,4,3,5,4,4,
    4,5,4,3,4,3,5,3,5
]

let THUNDERHAWK_HCS: [Int] = [
    17,5,9,3,7,11,15,13,1,
    14,16,4,8,12,18,2,10,6
]

let THUNDERHAWK_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7031, rating: 74.2, slope: 141),
    TeeInfo(teeName: "Brass", yardage: 6761, rating: 72.4, slope: 137),
    TeeInfo(teeName: "Bronze", yardage: 6361, rating: 71.2, slope: 134),
    TeeInfo(teeName: "Silver", yardage: 6124, rating: 70.1, slope: 131)
]
private let GLEN_CLUB_ID = UUID(uuidString: "A7A10004-0000-0000-0000-000000000004")!

let GLEN_CLUB_PARS: [Int] = [
    5,4,4,3,5,4,4,4,3,
    4,3,4,4,5,4,4,3,5
]

let GLEN_CLUB_HCS: [Int] = [
    7,15,3,17,9,5,1,11,13,
    18,6,8,10,14,12,2,16,4
]

let GLEN_CLUB_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Gold",       yardage: 7133, rating: 74.9, slope: 141),
    TeeInfo(teeName: "Blue/Gold",  yardage: 6846, rating: 73.5, slope: 137),
    TeeInfo(teeName: "Blue",       yardage: 6575, rating: 72.2, slope: 133),
    TeeInfo(teeName: "Silver/Blue",yardage: 6300, rating: 71.0, slope: 129),
    TeeInfo(teeName: "Silver/White", yardage: 5900, rating: 70.0, slope: 126),
    TeeInfo(teeName: "White",      yardage: 5300, rating: 69.5, slope: 122)
]
private let CANTIGNY_WOODSIDE_LAKESIDE_ID = UUID(uuidString: "A7A10001-0000-0000-0000-000000000001")!
private let CANTIGNY_WOODSIDE_HILLSIDE_ID = UUID(uuidString: "A7A10002-0000-0000-0000-000000000002")!
private let CANTIGNY_LAKESIDE_HILLSIDE_ID = UUID(uuidString: "A7A10003-0000-0000-0000-000000000003")!

let CANTIGNY_WOODSIDE_LAKESIDE_PARS: [Int] = [
    4,5,3,4,4,4,5,3,4,
    4,5,4,3,5,4,4,3,4
]

let CANTIGNY_WOODSIDE_LAKESIDE_HCS: [Int] = [
    11,1,15,17,9,3,5,13,7,
    10,2,12,14,6,18,8,16,4
]

let CANTIGNY_WOODSIDE_LAKESIDE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Champ", yardage: 7055, rating: 74.3, slope: 143)
]

let CANTIGNY_WOODSIDE_HILLSIDE_PARS: [Int] = [
    4,5,3,4,4,4,5,3,4,
    4,5,4,4,3,4,5,3,4
]

let CANTIGNY_WOODSIDE_HILLSIDE_HCS: [Int] = [
    11,1,15,17,9,3,5,13,7,
    10,4,16,12,18,2,6,14,8
]

let CANTIGNY_WOODSIDE_HILLSIDE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Champ", yardage: 7012, rating: 74.1, slope: 142)
]

let CANTIGNY_LAKESIDE_HILLSIDE_PARS: [Int] = [
    4,5,4,3,5,4,4,3,4,
    4,5,4,4,3,4,5,3,4
]

let CANTIGNY_LAKESIDE_HILLSIDE_HCS: [Int] = [
    9,1,11,13,5,17,7,15,3,
    10,4,16,12,18,2,6,14,8
]

let CANTIGNY_LAKESIDE_HILLSIDE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Champ", yardage: 6831, rating: 73.0, slope: 139)
]
private let WHITE_DEER_RUN_ID = UUID(uuidString: "A7A10005-0000-0000-0000-000000000015")!

let WHITE_DEER_RUN_PARS: [Int] = [
    4,4,5,3,4,5,4,3,4,
    4,4,3,4,5,3,4,5,4
]

let WHITE_DEER_RUN_HCS: [Int] = [
    7,9,3,15,5,1,11,13,17,
    2,6,18,14,10,16,8,4,12
]

let WHITE_DEER_RUN_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7149, rating: 73.6, slope: 143),
    TeeInfo(teeName: "Gold",  yardage: 6816, rating: 72.0, slope: 140),
    TeeInfo(teeName: "Blue",  yardage: 6464, rating: 70.5, slope: 137),
    TeeInfo(teeName: "White", yardage: 6023, rating: 69.0, slope: 133),
    TeeInfo(teeName: "Red",   yardage: 5012, rating: 66.5, slope: 125)
]
private let BETHPAGE_BLACK_ID = UUID(uuidString: "A4E7A4A1-3A8F-4F4F-9B2F-6E9C1A0B4001")!

private let BETHPAGE_BLACK_PARS: [Int] = [
    4, 4, 3, 5, 4, 4, 5, 3, 4,
    4, 4, 4, 5, 3, 4, 4, 3, 4
]

private let BETHPAGE_BLACK_HCS: [Int] = [
    8, 16, 18, 2, 4, 10, 6, 14, 12,
    9, 11, 7, 3, 17, 1, 5, 13, 15
]

private let BETHPAGE_BLACK_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue",  yardage: 7468, rating: 78.1, slope: 152),
    TeeInfo(teeName: "White", yardage: 6684, rating: 74.0, slope: 145),
    TeeInfo(teeName: "Red",   yardage: 6223, rating: 71.2, slope: 137),
    TeeInfo(teeName: "Red (L)", yardage: 6223, rating: 77.8, slope: 150)
]
private let BETHPAGE_RED_ID = UUID(uuidString: "A4E7A4A1-3A8F-4F4F-9B2F-6E9C1A0B4002")!

let BETHPAGE_RED_PARS: [Int] = [
    4,4,4,3,5,4,3,4,4,
    4,4,3,4,4,4,5,3,4
]

let BETHPAGE_RED_HCS: [Int] = [
    3,7,11,15,5,9,17,13,1,
    14,12,16,6,4,2,8,18,10
]

let BETHPAGE_RED_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue", yardage: 6921, rating: 73.7, slope: 128)
]

// MARK: Harbor Links Golf Course — Port Washington, NY

private let HARBOR_LINKS_ID = UUID(uuidString: "8F0A1B2C-3D4E-4F5A-6B7C-8D9E0F1A2B3C")!

let HARBOR_LINKS_PARS: [Int] = [
    5,4,3,4,4,5,4,3,4,
    4,4,3,5,4,4,5,3,4
]

let HARBOR_LINKS_HCS: [Int] = [
    7,5,17,13,11,1,9,15,3,
    2,18,16,12,8,10,6,14,4
]

let HARBOR_LINKS_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6886, rating: 73.3, slope: 137)
]

// MARK: - South Carolina Private Courses

private let OLD_BARNWELL_ID = UUID(uuidString: "A7A20001-0000-0000-0000-000000000001")!
private let YEAMANS_HALL_ID = UUID(uuidString: "A7A20001-0000-0000-0000-000000000002")!
private let TREE_FARM_ID = UUID(uuidString: "A7A20001-0000-0000-0000-000000000003")!
private let CONGAREE_ID = UUID(uuidString: "A7A20001-0000-0000-0000-000000000004")!
private let PALMETTO_ID = UUID(uuidString: "A7A20001-0000-0000-0000-000000000005")!
private let SAGE_VALLEY_ID = UUID(uuidString: "A7A20001-0000-0000-0000-000000000006")!
private let QUIXOTE_ID = UUID(uuidString: "A7A20001-0000-0000-0000-000000000007")!

let OLD_BARNWELL_PARS = [
    5,4,4,3,4,4,4,4,4,
    4,3,5,4,4,5,5,3,4
]

let OLD_BARNWELL_HCS = [
    13,17,5,11,7,1,3,9,15,
    4,8,14,2,16,10,12,18,6
]

let OLD_BARNWELL_TEES = [
    TeeInfo(teeName: "Red", yardage: 7091, rating: 74.9, slope: 136)
]


let YEAMANS_HALL_PARS = [
    4,4,3,4,4,3,4,4,5,
    4,4,4,3,4,4,3,4,5
]

let YEAMANS_HALL_HCS = [
    5,15,17,3,7,13,1,11,9,
    12,6,16,18,4,2,10,8,14
]

let YEAMANS_HALL_TEES = [
    TeeInfo(teeName: "Rust", yardage: 6778, rating: 72.6, slope: 137)
]


let TREE_FARM_PARS = [
    3,4,4,3,4,4,4,4,5,
    4,4,4,5,4,3,5,3,4
]

let TREE_FARM_HCS = [
    13,15,3,5,17,7,11,1,9,
    12,6,4,2,10,14,8,16,18
]

let TREE_FARM_TEES = [
    TeeInfo(teeName: "Tree Monster", yardage: 7293, rating: 75.1, slope: 138)
]


let CONGAREE_PARS = [
    4,5,4,5,3,4,3,5,4,
    3,4,5,4,3,4,4,4,4
]

let CONGAREE_HCS = [
    9,11,15,5,17,3,13,7,1,
    18,6,16,4,14,8,10,2,12
]

let CONGAREE_TEES = [
    TeeInfo(teeName: "Championship", yardage: 7790, rating: 79.4, slope: 155)
]


let PALMETTO_PARS = [
    4,4,4,4,4,5,3,4,3,
    5,3,4,4,5,4,3,4,4
]

let PALMETTO_HCS = [
    15,11,1,9,3,17,13,5,7,
    10,16,4,2,12,18,8,6,14
]

let PALMETTO_TEES = [
    TeeInfo(teeName: "Tournament", yardage: 6631, rating: 73.8, slope: 145)
]


let SAGE_VALLEY_PARS = [
    4,3,4,5,4,4,3,5,4,
    5,4,3,4,4,5,3,4,4
]

let SAGE_VALLEY_HCS = [
    11,15,1,9,7,17,13,5,3,
    10,4,18,16,8,14,12,2,6
]

let SAGE_VALLEY_TEES = [
    TeeInfo(teeName: "Black", yardage: 7325, rating: nil, slope: nil)
]


let QUIXOTE_PARS = [
    4,4,4,3,4,4,5,3,4,
    4,4,3,5,4,4,4,3,4
]

let QUIXOTE_HCS = [
    3,7,15,13,11,5,9,17,1,
    12,4,18,14,6,10,16,8,2
]

let QUIXOTE_TEES = [
    TeeInfo(teeName: "Back", yardage: 6772, rating: 73.3, slope: 138)
]
private let MAY_RIVER_ID = UUID(uuidString: "F3A9D1C2-7E44-4B9A-AE8C-2D6F9B8A1C01")!
private let SECESSION_ID = UUID(uuidString: "8B7E2F90-3C1D-4A6E-BF55-91C2D7E4A2B3")!
private let BULLS_BAY_ID = UUID(uuidString: "C1D4A8E7-5B92-4F3C-9A6D-0E7F2B3C9D44")!
let MAY_RIVER_PARS: [Int] = [
    4,3,4,5,4,3,4,5,4,
    5,3,4,4,3,5,4,3,5
]

let MAY_RIVER_HCS: [Int] = [
    13,15,9,7,3,17,11,5,1,
    2,18,10,8,16,12,6,14,4
]

let MAY_RIVER_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Oak", yardage: 7171, rating: 75.6, slope: 141),
    TeeInfo(teeName: "Cedar", yardage: 6513, rating: 72.8, slope: 137),
    TeeInfo(teeName: "Hickory", yardage: 6065, rating: 70.7, slope: 133),
    TeeInfo(teeName: "Magnolia", yardage: 5168, rating: 70.3, slope: 124)
]

// MARK: - Secession Golf Club

let SECESSION_PARS: [Int] = [
    4,3,4,4,5,4,4,3,5,
    5,4,3,5,3,4,4,3,4
]

let SECESSION_HCS: [Int] = [
    13,17,1,11,9,15,3,7,5,
    12,8,6,2,10,16,18,14,4
]

let SECESSION_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Devlin", yardage: 7016, rating: 74.1, slope: 145)
]

// MARK: - Bulls Bay Golf Club

let BULLS_BAY_PARS: [Int] = [
    4,5,3,5,4,5,3,4,4,
    5,4,3,5,3,4,4,3,4
]

let BULLS_BAY_HCS: [Int] = [
    5,1,15,3,7,11,9,17,13,
    4,16,12,2,14,6,10,18,8
]

let BULLS_BAY_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Maverick", yardage: 7220, rating: 75.2, slope: 138),
    TeeInfo(teeName: "Skull", yardage: 6692, rating: 72.6, slope: 136),
    TeeInfo(teeName: "Club", yardage: 6345, rating: 71.0, slope: 132),
    TeeInfo(teeName: "Bull", yardage: 6104, rating: 69.7, slope: 130),
    TeeInfo(teeName: "Bay", yardage: 5335, rating: 72.2, slope: 123)
]
private let WARREN_GC_ID = UUID(uuidString: "7F2A9C14-3B6E-4D91-8E2F-5A1C7D9B4E22")!

let WARREN_GC_PARS: [Int] = [
    4,5,4,3,4,4,3,5,4,
    4,3,4,5,3,5,3,4,4
]

let WARREN_GC_HCS: [Int] = [
    5,7,1,11,15,17,9,13,3,
    16,14,8,2,12,6,18,10,4
]

let WARREN_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: nil, rating: nil, slope: nil)
]
// MARK: - Singapore Courses

private let LAGUNA_NATIONAL_ID = UUID(uuidString: "3C9E5A71-6B28-4F4D-9E2A-8B7D1C3F9026")!
private let SENTOSA_TANJONG_ID = UUID(uuidString: "D8F2A6B4-91C7-4E3A-A52F-6C8B0E9D7413")!

// MARK: - Laguna National Golf Resort Club

let LAGUNA_NATIONAL_PARS: [Int] = [
    4,5,3,4,4,5,4,3,4,
    4,5,4,4,3,4,5,3,4
]

let LAGUNA_NATIONAL_HCS: [Int] = [
    16,2,18,12,10,8,4,14,6,
    15,1,9,13,17,3,5,11,7
]

let LAGUNA_NATIONAL_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Masters", yardage: 7118, rating: nil, slope: nil),
    TeeInfo(teeName: "Blue", yardage: 6624, rating: nil, slope: nil),
    TeeInfo(teeName: "White", yardage: 6101, rating: nil, slope: nil)
]

// MARK: - Sentosa Golf Club - The Tanjong

let SENTOSA_TANJONG_PARS: [Int] = [
    4,3,4,5,4,4,5,3,4,
    4,4,5,4,3,4,4,3,5
]

let SENTOSA_TANJONG_HCS: [Int] = [
    9,17,1,3,5,13,11,15,7,
    16,12,18,2,8,4,6,14,10
]

let SENTOSA_TANJONG_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6675, rating: 75.2, slope: 137),
    TeeInfo(teeName: "Blue", yardage: 6227, rating: 73.6, slope: 133),
    TeeInfo(teeName: "White", yardage: 5845, rating: 71.7, slope: 133),
    TeeInfo(teeName: "Ladies", yardage: 5286, rating: 74.3, slope: 132)
]
private let TANAH_MERAH_TAMPINES_ID = UUID(uuidString: "A91C4F2D-5E7B-4C88-9F12-3D6A8B9E0F21")!

let TANAH_MERAH_TAMPINES_PARS: [Int] = [
    4,4,4,3,5,3,4,5,4,
    5,4,4,4,3,4,3,4,5
]

let TANAH_MERAH_TAMPINES_HCS: [Int] = [
    13,3,7,11,1,15,5,9,17,
    4,12,14,8,16,2,18,10,6
]

let TANAH_MERAH_TAMPINES_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6687, rating: 76.6, slope: 141),
    TeeInfo(teeName: "Blue", yardage: 6423, rating: 74.0, slope: 136),
    TeeInfo(teeName: "White", yardage: 6008, rating: 72.0, slope: 133),
    TeeInfo(teeName: "Gold", yardage: 5353, rating: 68.8, slope: 123),
    TeeInfo(teeName: "Red", yardage: 5353, rating: 68.8, slope: 122)
]
private let SENTOSA_NEW_TANJONG_ID = UUID(uuidString: "E4B72D93-6C18-4D6A-9A35-80F3B2174C9F")!

let SENTOSA_NEW_TANJONG_PARS: [Int] = [
    4,3,5,4,3,5,4,4,4,
    5,4,5,3,4,4,3,4,4
]

let SENTOSA_NEW_TANJONG_HCS: [Int] = [
    7,15,13,5,17,9,3,11,1,
    8,2,4,18,10,12,16,14,6
]

let SENTOSA_NEW_TANJONG_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue", yardage: 6218, rating: 72.2, slope: 138)
]
// MARK: - Keppel Club

private let KEPPEL_CLUB_ID = UUID(uuidString: "6F2B9C1D-4A73-4F88-B6E1-9C7D3A5E2B14")!

let KEPPEL_CLUB_PARS: [Int] = [
    4,5,3,4,4,4,3,4,5,
    4,3,4,3,5,4,5,4,4
]

let KEPPEL_CLUB_HCS: [Int] = [
    1,9,15,11,5,17,13,7,3,
    10,12,8,18,2,14,4,6,16
]

let KEPPEL_CLUB_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6488, rating: 72.5, slope: 143)
]
// MARK: - River Oaks Country Club

private let RIVER_OAKS_CC_ID = UUID(uuidString: "B84F2A9C-6D13-4E8B-9F41-2C7A5E90D331")!

let RIVER_OAKS_CC_PARS: [Int] = [
    4,4,3,5,4,3,4,5,4,
    5,4,4,4,3,5,4,3,4
]

let RIVER_OAKS_CC_HCS: [Int] = [
    13,3,7,11,1,15,5,17,9,
    12,4,10,18,16,6,2,14,8
]

let RIVER_OAKS_CC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Tips", yardage: 7125, rating: 74.9, slope: 137)
]

// MARK: - Champions Golf Club

private let CHAMPIONS_GC_ID = UUID(uuidString: "D7C9A1E4-42B8-4F61-9C3E-8A5B2D7E1044")!

let CHAMPIONS_GC_PARS: [Int] = [
    4,3,4,4,3,4,5,4,4,
    3,4,4,4,4,5,4,3,4
]

let CHAMPIONS_GC_HCS: [Int] = [
    11,15,5,9,17,1,13,7,3,
    12,2,18,4,10,16,14,6,8
]

let CHAMPIONS_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6536, rating: 71.6, slope: 128)
]

// MARK: - Memorial Park Golf Course

private let MEMORIAL_PARK_GC_ID = UUID(uuidString: "9F3B6C2D-1A84-4C9E-B5F2-7D6A8E41C205")!

let MEMORIAL_PARK_GC_PARS: [Int] = [
    5,3,5,4,4,4,3,5,3,
    4,3,4,4,5,3,5,4,4
]

let MEMORIAL_PARK_GC_HCS: [Int] = [
    15,13,5,1,11,9,7,3,17,
    8,10,2,14,18,16,4,12,6
]

let MEMORIAL_PARK_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue", yardage: 7292, rating: 74.2, slope: 128)
]

// MARK: - Sharpstown Park Golf Course

private let SHARPSTOWN_PARK_GC_ID = UUID(uuidString: "4A6E9D31-8B72-4F5C-A0E3-6C1D92B7F884")!

let SHARPSTOWN_PARK_GC_PARS: [Int] = [
    5,3,4,4,3,4,3,4,5,
    4,4,4,4,3,4,3,4,5
]

let SHARPSTOWN_PARK_GC_HCS: [Int] = [
    3,13,1,9,11,7,17,5,15,
    4,12,2,8,6,10,16,14,18
]

let SHARPSTOWN_PARK_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue", yardage: 6602, rating: 71.4, slope: 119)
]

// MARK: - Cypresswood Golf Club - Cypress Course

private let CYPRESSWOOD_CYPRESS_ID = UUID(uuidString: "C1A9F2D4-6E5B-4C9A-9A73-2D4E8F6B1A21")!

let CYPRESSWOOD_CYPRESS_PARS: [Int] = [
    5,4,4,4,3,4,3,5,4,
    4,4,4,4,3,5,3,5,4
]

let CYPRESSWOOD_CYPRESS_HCS: [Int] = [
    3,13,11,7,15,9,17,1,5,
    6,10,12,14,18,2,16,4,8
]

let CYPRESSWOOD_CYPRESS_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue",   yardage: 6906, rating: 72.8, slope: 127),
    TeeInfo(teeName: "Forest", yardage: 6168, rating: 70.3, slope: 120),
    TeeInfo(teeName: "Silver", yardage: 5624, rating: 68.1, slope: 116),
    TeeInfo(teeName: "Copper", yardage: 4744, rating: 67.3, slope: 114)
]

// MARK: - Gus Wortham Park Golf Course

private let GUS_WORTHAM_PARK_GC_ID = UUID(uuidString: "7C8A2F91-4D33-48E9-B62A-19F5D3A70C44")!

let GUS_WORTHAM_PARK_GC_PARS: [Int] = [
    4,5,5,4,3,4,4,3,4,
    3,4,4,4,4,4,3,5,4
]

let GUS_WORTHAM_PARK_GC_HCS: [Int] = [
    15,3,1,7,13,5,9,17,11,
    18,4,16,12,6,10,14,2,8
]

let GUS_WORTHAM_PARK_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Back", yardage: 6388, rating: 71.2, slope: 126)
]

// MARK: - Golf Club of Houston - Tournament Course

private let GOLF_CLUB_OF_HOUSTON_TOURNAMENT_ID = UUID(uuidString: "E9A41D6B-2C75-4F80-91B2-7D3F64C8A205")!

let GOLF_CLUB_OF_HOUSTON_TOURNAMENT_PARS: [Int] = [
    4,4,4,5,4,4,3,5,3,
    4,4,4,5,3,5,3,4,4
]

let GOLF_CLUB_OF_HOUSTON_TOURNAMENT_HCS: [Int] = [
    17,11,9,7,1,3,15,5,13,
    16,10,18,8,14,6,12,2,4
]

let GOLF_CLUB_OF_HOUSTON_TOURNAMENT_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Tournament", yardage: 7425, rating: 76.4, slope: 148)
]

// MARK: - Wildcat Golf Club - Highlands Course

private let WILDCAT_HIGHLANDS_ID = UUID(uuidString: "3A7F61D9-58B4-4C2E-8E94-B1F5A0D72E33")!

let WILDCAT_HIGHLANDS_PARS: [Int] = [
    4,5,3,4,4,4,4,3,5,
    3,4,5,4,4,5,3,4,4
]

let WILDCAT_HIGHLANDS_HCS: [Int] = [
    15,5,7,11,17,13,1,9,3,
    18,12,4,8,10,2,16,6,14
]

let WILDCAT_HIGHLANDS_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6954, rating: 73.3, slope: 134)
]

// MARK: - Wildcat Golf Club - Lakes Course

private let WILDCAT_LAKES_ID = UUID(uuidString: "B2E8C3F4-9A61-4F58-BD27-6F4A1E92C735")!

let WILDCAT_LAKES_PARS: [Int] = [
    4,4,5,3,4,4,4,3,5,
    4,5,4,3,4,4,5,3,4
]

let WILDCAT_LAKES_HCS: [Int] = [
    6,4,2,18,10,14,12,16,8,
    9,3,11,17,7,13,1,15,5
]

let WILDCAT_LAKES_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7016, rating: 73.2, slope: 135),
    TeeInfo(teeName: "Gold",  yardage: 6535, rating: 71.2, slope: 131),
    TeeInfo(teeName: "Blue",  yardage: 6045, rating: 68.9, slope: 114),
    TeeInfo(teeName: "White", yardage: 5482, rating: 66.3, slope: 103),
    TeeInfo(teeName: "Green", yardage: 4906, rating: 63.2, slope: 98)
]

// MARK: - Golfcrest Country Club — Pearland, TX

private let GOLFCREST_OLD_ID = UUID(uuidString: "4F3A7C21-9E56-4B8D-A102-8D6F3E51C947")!
private let GOLFCREST_NEW_ID = UUID(uuidString: "5C4B8D32-AF67-4C9E-B213-9E7A4F62D058")!

let GOLFCREST_CC_PARS: [Int] = [
    5,4,5,4,3,4,4,3,4,
    5,4,3,4,5,4,3,4,4
]

let GOLFCREST_OLD_HCS: [Int] = [
    13,1,7,11,17,3,5,15,9,
    12,8,18,4,10,2,16,14,6
]

let GOLFCREST_NEW_HCS: [Int] = [
    17,3,9,7,15,1,5,11,13,
    14,4,18,2,16,8,12,6,10
]

let GOLFCREST_CC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7254, rating: 74.6, slope: 140),
    TeeInfo(teeName: "Blue",  yardage: 6765, rating: 73.1, slope: 133),
    TeeInfo(teeName: "White", yardage: 6215, rating: 70.9, slope: 128),
    TeeInfo(teeName: "Gold",  yardage: 5720, rating: 68.8, slope: 123),
    TeeInfo(teeName: "Red",   yardage: 5138, rating: 71.8, slope: 124)
]

// MARK: - BlackHorse Golf Club - South Course

private let BLACKHORSE_SOUTH_ID = UUID(uuidString: "91D6A8E5-43B7-4C1A-8F2D-0E5B9C73F416")!

let BLACKHORSE_SOUTH_PARS: [Int] = [
    4,4,4,3,5,3,4,4,5,
    4,4,4,3,4,5,4,3,5
]

let BLACKHORSE_SOUTH_HCS: [Int] = [
    9,5,3,11,7,17,15,1,13,
    18,14,6,10,4,2,16,8,12
]

let BLACKHORSE_SOUTH_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Big Jake", yardage: 7191, rating: 75.7, slope: 138)
]

// MARK: - BlackHorse Golf Club - North Course

private let BLACKHORSE_NORTH_ID = UUID(uuidString: "5C0F92A7-6B38-4E1D-96A5-3E7D84B1F209")!

let BLACKHORSE_NORTH_PARS: [Int] = [
    4,3,5,4,4,3,4,5,4,
    4,5,4,4,3,4,3,4,5
]

let BLACKHORSE_NORTH_HCS: [Int] = [
    9,13,15,1,3,11,7,17,5,
    4,6,8,16,18,2,12,10,14
]

let BLACKHORSE_NORTH_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Big Jake", yardage: 7301, rating: 75.0, slope: 135),
    TeeInfo(teeName: "Black",    yardage: 7057, rating: 74.0, slope: 131),
    TeeInfo(teeName: "White",    yardage: 6199, rating: 69.8, slope: 121)
]

// MARK: - Ohio Course Batch

private let FOWLERS_MILL_ID       = UUID(uuidString: "81AE6238-D377-424E-BB47-C65AD7709C7F")!
private let STONELICK_HILLS_ID    = UUID(uuidString: "3783A331-0B72-4C47-8FC6-0973CD882FD9")!
private let MANAKIKI_ID           = UUID(uuidString: "C9B76CD9-A891-44CA-A14E-1E6725CCCD4B")!
private let BOULDER_CREEK_ID      = UUID(uuidString: "48E13F5D-03C9-4ADD-97F4-137C3432A651")!
private let QUARRY_GC_ID          = UUID(uuidString: "E79AF837-4B81-4618-B4F2-0B3242094D12")!
private let DEER_RIDGE_ID         = UUID(uuidString: "98A887F0-70B3-4F86-95C3-26DE2514969F")!
private let VALLEY_EAGLES_ID      = UUID(uuidString: "5DFE99D6-56AC-4C17-919A-5ED3E2D634E6")!

let FOWLERS_MILL_PARS: [Int] = [
    4,4,3,4,5,4,3,5,4,
    4,4,3,5,4,4,3,5,4
]
let FOWLERS_MILL_HCS: [Int] = [
    5,15,7,1,13,3,17,9,11,
    8,12,10,14,6,4,18,16,2
]

let STONELICK_HILLS_PARS: [Int] = [
    4,4,3,5,4,3,4,4,5,
    5,4,3,5,3,4,4,3,5
]
let STONELICK_HILLS_HCS: [Int] = [
    17,3,7,15,1,11,13,5,9,
    6,8,14,16,12,2,18,4,10
]

let MANAKIKI_PARS: [Int] = [
    4,4,5,4,3,5,3,4,4,
    4,3,5,5,4,3,4,4,4
]
let MANAKIKI_HCS: [Int] = [
    5,7,9,13,17,3,15,1,11,
    2,12,18,16,10,8,14,4,6
]

let BOULDER_CREEK_PARS: [Int] = [
    5,4,4,3,4,5,3,4,4,
    5,4,3,4,4,4,4,3,5
]
let BOULDER_CREEK_HCS: [Int] = [
    5,13,3,17,7,9,15,11,1,
    8,14,18,2,10,6,12,16,4
]

let QUARRY_GC_PARS: [Int] = [
    5,4,4,4,4,3,5,4,3,
    4,5,3,4,4,5,4,3,4
]
let QUARRY_GC_HCS: [Int] = [
    9,7,5,13,1,15,11,3,17,
    10,4,18,2,12,16,6,14,8
]

let DEER_RIDGE_PARS: [Int] = [
    4,4,3,5,4,5,3,4,4,
    4,3,5,4,4,4,5,3,4
]
let DEER_RIDGE_HCS: [Int] = [
    1,17,15,7,5,11,3,9,13,
    12,16,8,2,14,4,6,18,10
]

let VALLEY_EAGLES_PARS: [Int] = [
    4,5,4,5,3,4,3,4,4,
    3,5,4,4,4,3,4,5,4
]
let VALLEY_EAGLES_HCS: [Int] = [
    4,18,14,12,10,2,8,16,6,
    17,13,15,9,5,3,11,7,1
]

// MARK: - Pennsylvania Courses

private let HERSHEY_EAST_ID          = UUID(uuidString: "896F511F-49D8-4F1A-96F6-09D50101F57B")!
private let HERSHEY_WEST_ID          = UUID(uuidString: "BA216331-F3BD-48C4-BC18-EF4B598E6ADF")!
private let BEDFORD_SPRINGS_ID       = UUID(uuidString: "93AE33DB-DDDD-498A-9120-BDF78CA262A8")!
private let NEMACOLIN_MYSTIC_ROCK_ID = UUID(uuidString: "C3A468EE-6528-4995-B1EC-7421BF0D11ED")!
private let OLDE_STONEWALL_ID        = UUID(uuidString: "88039DFB-82BA-4F66-A5D9-530FBA568217")!
private let GLEN_MILLS_ID            = UUID(uuidString: "8F00DFC5-FC6D-473E-8962-F6949D3DF818")!
private let FOX_CHAPEL_ID            = UUID(uuidString: "2D8FAEDF-641C-4C45-80A8-40BAC985517E")!

let HERSHEY_EAST_PARS: [Int] = [
    5,3,4,4,4,5,4,3,4,
    4,4,4,3,5,4,3,4,4
]
let HERSHEY_EAST_HCS: [Int] = [
    13,17,1,9,15,11,5,7,3,
    12,6,10,18,8,2,14,16,4
]
let HERSHEY_EAST_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7130, rating: 74.3, slope: 132)
]

let HERSHEY_WEST_PARS: [Int] = [
    4,5,4,4,3,4,5,3,4,
    4,4,3,5,4,5,3,4,4
]
let HERSHEY_WEST_HCS: [Int] = [
    1,5,13,15,17,11,7,9,3,
    6,12,16,2,14,8,10,18,4
]
let HERSHEY_WEST_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue", yardage: 6830, rating: 72.7, slope: 139)
]

let BEDFORD_SPRINGS_PARS: [Int] = [
    4,3,5,3,5,4,4,4,5,
    3,4,4,5,3,4,5,3,4
]
let BEDFORD_SPRINGS_HCS: [Int] = [
    17,11,7,1,5,9,3,13,15,
    18,2,10,4,16,14,8,6,12
]
let BEDFORD_SPRINGS_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Medal", yardage: 6785, rating: 73.7, slope: 140)
]

let NEMACOLIN_MYSTIC_ROCK_PARS: [Int] = [
    4,4,3,4,5,4,3,5,4,
    4,5,3,4,4,5,3,4,4
]
let NEMACOLIN_MYSTIC_ROCK_HCS: [Int] = [
    13,3,15,9,5,11,17,7,1,
    10,4,8,18,12,14,6,16,2
]
let NEMACOLIN_MYSTIC_ROCK_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 7526, rating: 76.8, slope: 146)
]

let OLDE_STONEWALL_PARS: [Int] = [
    5,4,4,4,3,4,3,4,5,
    4,4,4,4,3,3,4,4,4
]
let OLDE_STONEWALL_HCS: [Int] = [
    10,14,6,4,16,2,18,8,12,
    1,3,9,15,13,11,5,17,7
]
let OLDE_STONEWALL_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Grey", yardage: 7103, rating: 74.2, slope: 149)
]

let GLEN_MILLS_PARS: [Int] = [
    4,4,4,5,3,5,3,4,4,
    3,4,4,4,3,5,3,5,4
]
let GLEN_MILLS_HCS: [Int] = [
    14,2,16,4,18,6,8,12,10,
    9,1,13,3,15,5,17,11,7
]
let GLEN_MILLS_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Scratch / Black",    yardage: 6646, rating: 71.1, slope: 140),
    TeeInfo(teeName: "Director / Blue",    yardage: 6314, rating: 69.1, slope: 135),
    TeeInfo(teeName: "Middle / White",     yardage: 6011, rating: 66.2, slope: 125),
    TeeInfo(teeName: "Preferred / Green",  yardage: 5430, rating: 63.7, slope: 126),
    TeeInfo(teeName: "Forward / Red",      yardage: 4703, rating: 66.1, slope: 120)
]

let FOX_CHAPEL_PARS: [Int] = [
    4,5,4,4,3,4,5,3,4,
    4,4,3,5,4,5,5,3,4
]
let FOX_CHAPEL_HCS: [Int] = [
    1,5,13,15,17,11,7,9,3,
    6,12,16,2,14,8,10,18,4
]
let FOX_CHAPEL_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Back",            yardage: 6860, rating: 72.9, slope: 135),
    TeeInfo(teeName: "Back / Middle",   yardage: 6632, rating: 72.0, slope: 135),
    TeeInfo(teeName: "Middle",          yardage: 6480, rating: 71.4, slope: 133),
    TeeInfo(teeName: "Middle / Forward",yardage: 5503, rating: 66.9, slope: 119),
    TeeInfo(teeName: "Forward",         yardage: 5276, rating: 70.4, slope: 120)
]

// MARK: - Firestone Country Club - South Course

private let FIRESTONE_SOUTH_ID = UUID(uuidString: "A8C93F41-6D72-4B5E-9F31-2C8A7D6E1045")!

let FIRESTONE_SOUTH_PARS: [Int] = [
    4,5,4,4,3,4,3,4,4,
    4,4,3,4,4,3,5,4,4
]

let FIRESTONE_SOUTH_HCS: [Int] = [
    9,13,15,7,11,1,17,5,3,
    6,16,10,2,14,18,12,8,4
]

let FIRESTONE_SOUTH_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue", yardage: 7400, rating: 77.0, slope: 148)
]

// MARK: - Firestone Country Club - North Course

private let FIRESTONE_NORTH_ID = UUID(uuidString: "D1E47A92-5C83-4A6F-9B20-7E3C1F8A6621")!

let FIRESTONE_NORTH_PARS: [Int] = [
    4,4,4,4,5,3,5,3,4,
    4,3,4,4,4,4,5,3,5
]

let FIRESTONE_NORTH_HCS: [Int] = [
    5,11,3,7,13,9,17,15,1,
    16,10,2,6,4,18,8,12,14
]

let FIRESTONE_NORTH_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Gold", yardage: 7125, rating: 74.2, slope: 139)
]

// MARK: - Firestone Country Club - Fazio Course

private let FIRESTONE_FAZIO_ID = UUID(uuidString: "F4B9C6E2-8A17-42D3-B9F6-3D1A7E8C9042")!

let FIRESTONE_FAZIO_PARS: [Int] = [
    4,4,3,4,4,4,3,4,5,
    4,4,3,5,3,4,3,5,4
]

let FIRESTONE_FAZIO_HCS: [Int] = [
    5,9,13,15,11,1,17,3,7,
    4,8,16,10,18,6,14,12,2
]

let FIRESTONE_FAZIO_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Gold", yardage: 6904, rating: 73.1, slope: 132)
]

// MARK: - The Virtues Golf Club

private let VIRTUES_GOLF_CLUB_ID = UUID(uuidString: "9C72A5E1-3F84-4D9B-A621-8E7F1C4B203D")!

let VIRTUES_GOLF_CLUB_PARS: [Int] = [
    4,4,4,5,3,4,5,4,3,
    5,4,3,4,3,4,5,4,4
]

let VIRTUES_GOLF_CLUB_HCS: [Int] = [
    9,7,13,1,15,11,5,3,17,
    8,14,16,2,18,10,6,12,4
]

let VIRTUES_GOLF_CLUB_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7243, rating: 74.8, slope: 142),
    TeeInfo(teeName: "Blue",  yardage: 6856, rating: 73.0, slope: 138)
]

// MARK: - Sleepy Hollow Golf Course

private let SLEEPY_HOLLOW_GC_ID = UUID(uuidString: "E6F31B8A-52D4-47C9-AF13-9B2E7D604581")!

let SLEEPY_HOLLOW_GC_PARS: [Int] = [
    5,3,4,5,4,3,4,3,4,
    4,4,3,4,5,4,4,4,4
]

let SLEEPY_HOLLOW_GC_HCS: [Int] = [
    17,3,1,7,5,15,9,13,11,
    2,4,16,12,8,14,6,18,10
]

let SLEEPY_HOLLOW_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6648, rating: 73.4, slope: 145)
]

// MARK: Oakmont Country Club — Oakmont, PA
private let OAKMONT_CC_ID = UUID(uuidString: "F9B0C526-7A81-4E3D-A417-0D5F9B8C2E35")!

let OAKMONT_CC_PARS: [Int] = [
    4,4,4,5,4,3,4,3,4,
    4,4,5,3,4,4,3,4,4
]

let OAKMONT_CC_HCS: [Int] = [
    5,9,1,13,7,15,3,11,17,
    6,14,8,18,12,2,16,10,4
]

let OAKMONT_CC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 7427, rating: 77.6, slope: 143)
]

// MARK: Aronimink Golf Club — Newtown Square, PA
private let ARONIMINK_GC_ID = UUID(uuidString: "D4E5F6A7-B8C9-4D0E-1F2A-3B4C5D6E7F8A")!

let ARONIMINK_GC_PARS: [Int] = [
    4,4,4,4,3,4,4,3,5,
    4,4,4,4,3,4,5,3,4
]

let ARONIMINK_GC_HCS: [Int] = [
    3,11,7,1,17,9,5,13,15,
    8,4,6,14,12,2,16,18,10
]

let ARONIMINK_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7313, rating: 75.5, slope: 144)
]

// MARK: Bulle Rock Golf Club — Havre de Grace, MD
private let BULLE_ROCK_GC_ID = UUID(uuidString: "C1D2E3F4-A5B6-4C7D-8E9F-0A1B2C3D4E5F")!

let BULLE_ROCK_GC_PARS: [Int] = [
    4,5,3,4,4,3,5,4,4,
    4,5,3,4,4,5,4,3,4
]

let BULLE_ROCK_GC_HCS: [Int] = [
    13,3,17,5,1,9,15,11,7,
    12,6,10,2,14,8,18,16,4
]

let BULLE_ROCK_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7375, rating: 75.6, slope: 146),
    TeeInfo(teeName: "Gold",  yardage: 6925, rating: 73.1, slope: 141),
    TeeInfo(teeName: "Blue",  yardage: 6410, rating: 71.0, slope: 137),
    TeeInfo(teeName: "White", yardage: 6055, rating: 69.2, slope: 133),
    TeeInfo(teeName: "Green", yardage: 5507, rating: 66.0, slope: 127)
]

// MARK: Worthington Manor Golf Club — Dickerson, MD
private let WORTHINGTON_MANOR_GC_ID = UUID(uuidString: "D2E3F4A5-B6C7-4D8E-9F0A-1B2C3D4E5F6A")!

let WORTHINGTON_MANOR_GC_PARS: [Int] = [
    4,4,4,4,5,3,4,3,5,
    4,4,4,5,4,3,4,3,5
]

let WORTHINGTON_MANOR_GC_HCS: [Int] = [
    5,7,1,9,15,13,17,11,3,
    14,12,2,8,16,18,4,6,10
]

let WORTHINGTON_MANOR_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 7165, rating: 75.0, slope: 144),
    TeeInfo(teeName: "Black",        yardage: 7034, rating: 74.4, slope: 143),
    TeeInfo(teeName: "Blue",         yardage: 6525, rating: 72.1, slope: 138),
    TeeInfo(teeName: "White",        yardage: 6002, rating: 69.7, slope: 133),
    TeeInfo(teeName: "Gold",         yardage: 5403, rating: 66.8, slope: 128),
    TeeInfo(teeName: "Silver",       yardage: 5086, rating: 69.7, slope: 128)
]

// MARK: Philadelphia Cricket Club — Wissahickon — Flourtown, PA
private let PCC_WISSAHICKON_ID = UUID(uuidString: "C3D4E5F6-A7B8-4C9D-0E1F-2A3B4C5D6E7F")!

let PCC_WISSAHICKON_PARS: [Int] = [
    4,4,3,4,3,4,5,4,4,
    3,4,5,4,4,3,4,4,4
]

let PCC_WISSAHICKON_HCS: [Int] = [
    3,9,17,7,13,1,15,5,11,
    18,6,16,2,12,14,10,8,4
]

let PCC_WISSAHICKON_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 7131, rating: 74.7, slope: 138)
]

// MARK: Merion Golf Club — East Course — Ardmore, PA
private let MERION_EAST_ID = UUID(uuidString: "A1B2C3D4-E5F6-4A7B-8C9D-0E1F2A3B4C5D")!

let MERION_EAST_PARS: [Int] = [
    4,5,3,5,4,4,4,4,3,
    4,4,4,3,4,4,3,4,4
]

let MERION_EAST_HCS: [Int] = [
    15,3,13,9,1,5,11,17,7,
    16,10,14,18,2,6,8,12,4
]

let MERION_EAST_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 6946, rating: 75.1, slope: 151)
]

// MARK: Merion Golf Club — West Course — Ardmore, PA
private let MERION_WEST_ID = UUID(uuidString: "B2C3D4E5-F6A7-4B8C-9D0E-1F2A3B4C5D6E")!

let MERION_WEST_PARS: [Int] = [
    4,4,5,3,4,3,4,4,4,
    4,4,4,4,4,3,5,3,4
]

let MERION_WEST_HCS: [Int] = [
    17,5,7,13,1,11,9,15,3,
    10,2,14,12,4,18,8,16,6
]

let MERION_WEST_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Back", yardage: 6019, rating: 69.9, slope: 129)
]

// MARK: Keswick Club — Keswick, VA
private let KESWICK_CLUB_ID = UUID(uuidString: "D7F8A304-5E69-4C1B-E295-8B3D7F6A0C13")!

let KESWICK_CLUB_PARS: [Int] = [
    4,5,4,3,4,4,3,5,4,
    4,3,5,4,4,4,3,5,4
]

let KESWICK_CLUB_HCS: [Int] = [
    11,3,9,17,1,7,13,5,15,
    10,18,6,16,12,2,14,4,8
]

let KESWICK_CLUB_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Tournament", yardage: 7134, rating: 74.1, slope: 138)
]

// MARK: Spring Creek Golf Club — Gordonsville, VA
private let SPRING_CREEK_GC_VA_ID = UUID(uuidString: "E8A9B415-6F70-4D2C-F306-9C4E8A7B1D24")!

let SPRING_CREEK_GC_VA_PARS: [Int] = [
    4,5,4,4,3,4,4,3,5,
    4,4,5,3,4,4,4,3,5
]

let SPRING_CREEK_GC_VA_HCS: [Int] = [
    3,9,7,13,11,1,5,15,17,
    4,8,14,18,2,10,12,16,6
]

let SPRING_CREEK_GC_VA_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 7348, rating: 76.4, slope: 151),
    TeeInfo(teeName: "★★★★",         yardage: 6838, rating: 74.1, slope: 146),
    TeeInfo(teeName: "★★★",          yardage: 6209, rating: 71.2, slope: 141),
    TeeInfo(teeName: "★★",           yardage: 5494, rating: 67.9, slope: 132),
    TeeInfo(teeName: "★",            yardage: 4677, rating: 64.4, slope: 125)
]

// MARK: Kinloch Golf Club — Manakin-Sabot, VA
private let KINLOCH_GC_ID = UUID(uuidString: "B5D6E182-3C47-4A9F-C073-6F1B5D4E8A91")!

let KINLOCH_GC_PARS: [Int] = [
    4,4,5,4,3,4,3,4,5,
    4,5,4,5,3,4,4,3,4
]

let KINLOCH_GC_HCS: [Int] = [
    9,11,7,15,17,1,13,3,5,
    6,12,4,10,18,16,2,14,8
]

let KINLOCH_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7373, rating: 76.1, slope: 146)
]

// MARK: Ballyhack Golf Club — Roanoke, VA (Dormie Network)
private let BALLYHACK_GC_ID = UUID(uuidString: "C6E7F293-4D58-4B0A-D184-7A2C6E5F9B02")!

let BALLYHACK_GC_PARS: [Int] = [
    4,5,3,4,4,4,3,4,5,
    5,4,4,3,4,5,4,3,4
]

let BALLYHACK_GC_HCS: [Int] = [
    3,11,15,1,5,13,17,9,7,
    12,14,4,16,6,10,2,18,8
]

let BALLYHACK_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Ballyhack", yardage: 7294, rating: 76.1, slope: 155)
]

// MARK: Deacon's Lodge — Breezy Point, MN
private let DEACONS_LODGE_ID = UUID(uuidString: "E1A3C857-6F24-4D8B-B940-3C7E2A1F5D68")!

let DEACONS_LODGE_PARS: [Int] = [
    4,5,3,4,4,3,4,4,5,
    4,3,4,4,5,4,4,3,5
]

let DEACONS_LODGE_HCS: [Int] = [
    3,5,13,9,7,17,1,15,11,
    14,12,18,4,8,2,16,6,10
]

let DEACONS_LODGE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Palmer", yardage: 6943),
    TeeInfo(teeName: "King",   yardage: 6586),
    TeeInfo(teeName: "Combo",  yardage: 6414),
    TeeInfo(teeName: "Deacon", yardage: 6091),
    TeeInfo(teeName: "Lodge",  yardage: 5364),
    TeeInfo(teeName: "Winnie", yardage: 4766)
]

// MARK: Whitebirch Golf Course — Breezy Point, MN
private let WHITEBIRCH_GC_ID = UUID(uuidString: "F2B4D968-7A35-4E9C-C051-4D8F3B2A6E79")!

let WHITEBIRCH_GC_PARS: [Int] = [
    4,4,4,5,3,4,5,4,3,
    4,4,3,4,4,5,4,3,5
]

let WHITEBIRCH_GC_HCS: [Int] = [
    13,17,3,7,15,5,1,11,9,
    4,2,18,14,10,6,12,16,8
]

let WHITEBIRCH_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6680, rating: 72.2, slope: 137),
    TeeInfo(teeName: "Blue",  yardage: 6292, rating: 70.5, slope: 131),
    TeeInfo(teeName: "White", yardage: 5816, rating: 68.2, slope: 123),
    TeeInfo(teeName: "Gold",  yardage: 4718, rating: 63.2, slope: 112)
]

// MARK: StoneRidge Golf Club — Stillwater, MN
private let STONERIDGE_GC_MN_ID = UUID(uuidString: "A3C5E079-8B46-4F1D-D162-5E9A4C3B7F80")!

let STONERIDGE_GC_MN_PARS: [Int] = [
    4,5,4,5,4,4,3,4,3,
    4,5,4,4,3,4,3,5,4
]

let STONERIDGE_GC_MN_HCS: [Int] = [
    18,12,10,4,2,8,16,6,14,
    5,11,1,17,15,7,13,9,3
]

let STONERIDGE_GC_MN_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7013, rating: 74.1, slope: 143)
]

// MARK: The Wilderness at Fortune Bay — Tower, MN
private let WILDERNESS_FORTUNE_BAY_ID = UUID(uuidString: "D2E75A38-4C96-4F1B-B823-6A0F1D5C8E47")!

let WILDERNESS_FORTUNE_BAY_PARS: [Int] = [
    5,4,3,4,4,4,3,5,4,
    4,4,3,4,4,5,5,3,4
]

let WILDERNESS_FORTUNE_BAY_HCS: [Int] = [
    3,5,15,7,13,1,17,9,11,
    10,8,16,14,12,6,2,18,4
]

let WILDERNESS_FORTUNE_BAY_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Gold",        yardage: 7207, rating: 75.3, slope: 142),
    TeeInfo(teeName: "Blue",        yardage: 6772, rating: 73.2, slope: 137),
    TeeInfo(teeName: "Blue/White",  yardage: 6460, rating: 71.8, slope: 134),
    TeeInfo(teeName: "White",       yardage: 6147, rating: 70.4, slope: 131),
    TeeInfo(teeName: "White/Green", yardage: 5562, rating: 68.1, slope: 127),
    TeeInfo(teeName: "Green",       yardage: 5324, rating: 71.7, slope: 129)
]

// MARK: Hazeltine National Golf Club — Chaska, MN
private let HAZELTINE_NATIONAL_ID = UUID(uuidString: "C6F3A847-2D19-4B7E-A508-9E1C4D7B3F82")!

let HAZELTINE_NATIONAL_PARS: [Int] = [
    4,4,5,3,4,4,5,3,4,
    4,5,4,3,4,5,4,3,4
]

let HAZELTINE_NATIONAL_HCS: [Int] = [
    5,9,11,15,1,3,13,17,7,
    8,12,2,16,18,6,10,14,4
]

let HAZELTINE_NATIONAL_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Tournament", yardage: 7674, rating: 77.8, slope: 145)
]

// MARK: The Club at Porto Cima — Lake of the Ozarks, MO
private let PORTO_CIMA_ID = UUID(uuidString: "A9C4D71E-3B5F-48A2-B60E-1D7F3E8C5A29")!

let PORTO_CIMA_PARS: [Int] = [
    4,4,3,5,4,3,4,5,4,
    4,4,4,5,3,5,3,4,4
]

let PORTO_CIMA_HCS: [Int] = [
    5,3,11,7,1,15,17,13,9,
    18,12,4,10,8,16,14,6,2
]

let PORTO_CIMA_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7060, rating: 74.2, slope: 141),
    TeeInfo(teeName: "Gold",  yardage: 6699, rating: 72.7, slope: 138),
    TeeInfo(teeName: "Blue",  yardage: 6303, rating: 70.9, slope: 134),
    TeeInfo(teeName: "White", yardage: 5810, rating: 68.7, slope: 130),
    TeeInfo(teeName: "Red",   yardage: 4740, rating: 68.0, slope: 117)
]

// MARK: Branson Hills Golf Club — Branson, MO
private let BRANSON_HILLS_GC_ID = UUID(uuidString: "B4E82F19-7D3A-4C5E-9061-2F8B7A1D4C36")!

let BRANSON_HILLS_GC_PARS: [Int] = [
    4,3,4,5,4,4,3,5,4,
    4,5,3,4,5,3,4,4,4
]

let BRANSON_HILLS_GC_HCS: [Int] = [
    5,7,15,11,3,9,17,13,1,
    4,6,14,18,16,12,10,8,2
]

let BRANSON_HILLS_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Gold",   yardage: 7324, rating: 75.1, slope: 135),
    TeeInfo(teeName: "Green",  yardage: 7046, rating: 73.9, slope: 132),
    TeeInfo(teeName: "Blue",   yardage: 6741, rating: 72.6, slope: 132),
    TeeInfo(teeName: "Silver", yardage: 6299, rating: 70.2, slope: 130),
    TeeInfo(teeName: "Orange", yardage: 5323, rating: 71.8, slope: 126)
]

// MARK: Old Kinderhook Golf Club — Camdenton, MO
private let OLD_KINDERHOOK_GC_ID = UUID(uuidString: "7C3D9E51-2A84-4F6B-B1C8-5E0D2A9F3B74")!

let OLD_KINDERHOOK_GC_PARS: [Int] = [
    4,4,3,4,4,4,3,4,5,
    4,3,4,4,5,4,3,4,5
]

let OLD_KINDERHOOK_GC_HCS: [Int] = [
    3,11,13,5,1,17,15,7,9,
    6,14,12,4,2,10,16,18,8
]

let OLD_KINDERHOOK_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Silver", yardage: 6726, rating: 72.3, slope: 133)
]

// MARK: Bellerive Country Club — St. Louis, MO
private let BELLERIVE_CC_ID = UUID(uuidString: "3A7F2B84-1C56-4E9D-B037-8D4A1F6C2E53")!

let BELLERIVE_CC_PARS: [Int] = [
    4,4,3,5,4,3,4,5,4,
    4,4,4,3,4,4,3,5,4
]

let BELLERIVE_CC_HCS: [Int] = [
    9,13,11,17,1,5,15,7,3,
    4,12,6,18,16,2,14,8,10
]

let BELLERIVE_CC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 7547),
    TeeInfo(teeName: "Gold",  yardage: 7393),
    TeeInfo(teeName: "Silver", yardage: 5673)
]

// MARK: TPC Toronto at Osprey Valley — North Course — Caledon, ON
private let TPC_TORONTO_NORTH_ID = UUID(uuidString: "A7B3C5D8-E2F1-4A9C-B6D4-1E2F3A4B5C6D")!

let TPC_TORONTO_NORTH_PARS: [Int] = [
    5,4,4,3,4,4,3,4,4,
    4,3,4,5,3,4,4,4,4
]

let TPC_TORONTO_NORTH_HCS: [Int] = [
    5,3,11,17,1,15,13,2,7,
    14,18,10,4,16,8,6,12,9
]

let TPC_TORONTO_NORTH_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 7445),
    TeeInfo(teeName: "Osprey",       yardage: 6324),
]

// MARK: TPC Toronto at Osprey Valley — Hoot Course — Caledon, ON
private let TPC_TORONTO_HOOT_ID = UUID(uuidString: "B8C4D6E9-F3A2-4B0D-C7E5-2F3A4B5C6D7E")!

let TPC_TORONTO_HOOT_PARS: [Int] = [
    5,4,4,3,4,5,4,3,4,
    3,5,4,5,4,3,4,4,4
]

let TPC_TORONTO_HOOT_HCS: [Int] = [
    7,9,5,17,1,11,13,15,3,
    16,2,14,4,6,18,8,12,10
]

let TPC_TORONTO_HOOT_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Gold",   yardage: 7021),
    TeeInfo(teeName: "Osprey", yardage: 6064),
    TeeInfo(teeName: "White",  yardage: 5841),
]

// MARK: TPC Toronto at Osprey Valley — Heathlands Course — Caledon, ON
private let TPC_TORONTO_HEATHLANDS_ID = UUID(uuidString: "C9D5E7F0-A4B3-4C1E-D8F6-3A4B5C6D7E8F")!

let TPC_TORONTO_HEATHLANDS_PARS: [Int] = [
    5,4,4,4,3,4,4,3,5,
    5,4,3,4,4,3,5,3,4
]

let TPC_TORONTO_HEATHLANDS_HCS: [Int] = [
    11,9,5,13,15,3,7,17,1,
    6,10,18,2,12,14,4,16,8
]

let TPC_TORONTO_HEATHLANDS_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Championship", yardage: 6983),
    TeeInfo(teeName: "Osprey",       yardage: 6137),
    TeeInfo(teeName: "White",        yardage: 5960),
]

// MARK: Nara Kokusai GC — Nara, Japan
private let NARA_KOKUSAI_GC_ID = UUID(uuidString: "2F8A1C47-9D3E-4B6F-A521-7C0E3D8B9F42")!

let NARA_KOKUSAI_GC_PARS: [Int] = [
    5,4,3,4,4,5,4,3,4,
    5,4,4,3,4,4,3,4,5
]

let NARA_KOKUSAI_GC_HCS: [Int] = [
    9,3,17,15,1,7,5,11,13,
    8,4,14,18,10,2,16,6,12
]

let NARA_KOKUSAI_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue", yardage: 7055, rating: 77.1, slope: 133)
]

// MARK: Hirono Golf Club — Miki-shi, Hyogo, Japan
private let HIRONO_GC_ID = UUID(uuidString: "A3B4C5D6-E7F8-4A9B-0C1D-2E3F4A5B6C7D")!

let HIRONO_GC_PARS: [Int] = [
    5,4,4,4,3,4,3,4,5,
    4,4,5,3,4,5,4,3,4
]

let HIRONO_GC_HCS: [Int] = [
    9,5,2,11,18,4,16,13,7,
    14,8,1,17,10,3,12,15,6
]

let HIRONO_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Champion", yardage: 7169, rating: 77.6, slope: 134)
]

// MARK: Kawana Hotel GC (Fuji Course) — Ito, Shizuoka, Japan
private let KAWANA_FUJI_ID = UUID(uuidString: "B4C5D6E7-F8A9-4B0C-1D2E-3F4A5B6C7D8E")!

let KAWANA_FUJI_PARS: [Int] = [
    4,4,5,5,3,4,4,3,4,
    3,5,4,4,4,5,3,4,4
]

let KAWANA_FUJI_HCS: [Int] = [
    3,5,17,9,15,1,7,13,11,
    18,6,8,14,4,16,12,2,10
]

let KAWANA_FUJI_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Blue", yardage: 6701, rating: 75.5, slope: 130)
]

// MARK: Naruo GC — Hyogo, Japan
private let NARUO_GC_ID = UUID(uuidString: "C5D6E7F8-A9B0-4C1D-2E3F-4A5B6C7D8E9F")!

let NARUO_GC_PARS: [Int] = [
    4,3,4,3,4,4,5,4,4,
    4,4,3,4,5,3,4,4,4
]

let NARUO_GC_HCS: [Int] = [
    5,17,11,15,3,9,1,7,13,
    4,12,18,16,6,14,2,10,8
]

let NARUO_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Back", yardage: 6612, rating: 75.1, slope: 129)
]

// MARK: Kasumigaseki CC — East Course — Kawagoe, Saitama, Japan
// C.H. Alison redesign (1930); hosted 1957 Canada Cup
private let KASUMIGASEKI_EAST_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000033")!

let KASUMIGASEKI_EAST_PARS: [Int] = [
    4,4,4,3,5,4,3,5,4,
    3,4,4,4,5,4,3,4,4
]

let KASUMIGASEKI_EAST_HCS: [Int] = [
    9,15,3,13,1,7,11,5,17,
    16,10,4,14,2,8,12,6,18
]

let KASUMIGASEKI_EAST_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Tournament", yardage: 7466, rating: 74.9, slope: 131)
]

// MARK: Kasumigaseki CC — West Course — Kawagoe, Saitama, Japan
// C.H. Alison (1932); Japan's first 36-hole club
private let KASUMIGASEKI_WEST_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000034")!

let KASUMIGASEKI_WEST_PARS: [Int] = [
    4,4,5,3,4,5,3,4,4,
    5,3,4,5,4,5,3,4,4
]

let KASUMIGASEKI_WEST_HCS: [Int] = [
    9,15,3,13,7,1,11,5,17,
    10,16,4,8,14,2,12,6,18
]

let KASUMIGASEKI_WEST_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Champion", yardage: 6887, rating: 76.3, slope: 131)
]

// MARK: Tokyo Golf Club — Sayama, Saitama, Japan
// Design: Komei Otani (1939); Redesign: Gil Hanse. Dual-green (ASAKA / CHICHIBU).
private let TOKYO_GC_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000035")!

let TOKYO_GC_PARS: [Int] = [
    4,4,5,3,3,4,4,3,4,
    4,4,3,5,4,5,4,3,4
]

let TOKYO_GC_HCS: [Int] = [
    7,9,3,11,5,1,17,13,15,
    4,12,18,8,14,10,2,16,6
]

let TOKYO_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "ASAKA",    yardage: 7215, rating: 74.3),
    TeeInfo(teeName: "CHICHIBU", yardage: 6959, rating: 73.3)
]

// MARK: Yokohama Country Club (West Course) — Hodogaya-ku, Yokohama, Japan
// Design: Takeo Aiyama / Hideo Takemura (1960); Redesign: Coore & Crenshaw (2015-2016)
// Hosted 2018 Japan Open
private let YOKOHAMA_CC_WEST_ID = UUID(uuidString: "D101A001-0000-0000-0000-000000000036")!

let YOKOHAMA_CC_WEST_PARS: [Int] = [
    4,3,4,4,5,4,4,4,3,
    4,4,3,5,4,5,3,4,4
]

let YOKOHAMA_CC_WEST_HCS: [Int] = [
    9,13,7,3,5,17,1,15,11,
    4,10,18,2,8,14,16,6,12
]

let YOKOHAMA_CC_WEST_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Pro",          yardage: 6938),
    TeeInfo(teeName: "Championship", yardage: 6621),
    TeeInfo(teeName: "Mens",         yardage: 6311),
    TeeInfo(teeName: "Womens",       yardage: 5707)
]

// MARK: Bro Hof Slott Golf Club — Stadium Course — Bro, Sweden
private let BRO_HOF_STADIUM_ID = UUID(uuidString: "1A2B3C4D-5E6F-4A1B-8C2D-3E4F5A6B7C8D")!

let BRO_HOF_STADIUM_PARS: [Int] = [
    5,4,4,3,4,4,3,4,5,
    4,3,5,5,4,5,3,3,4
]

let BRO_HOF_STADIUM_HCS: [Int] = [
    8,4,18,16,2,14,12,10,6,
    3,15,7,9,17,1,11,5,13
]

let BRO_HOF_STADIUM_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 8056, rating: 79.9, slope: 148)
]

// MARK: Bro Hof Slott Golf Club — Castle Course — Bro, Sweden
private let BRO_HOF_CASTLE_ID = UUID(uuidString: "2B3C4D5E-6F7A-4B2C-9D3E-4F5A6B7C8D9E")!

let BRO_HOF_CASTLE_PARS: [Int] = [
    5,3,4,3,5,4,3,4,5,
    5,3,3,5,4,5,4,3,4
]

let BRO_HOF_CASTLE_HCS: [Int] = [
    5,13,11,9,7,1,17,15,3,
    4,16,18,6,14,2,12,10,8
]

let BRO_HOF_CASTLE_TEES: [TeeInfo] = [
    TeeInfo(teeName: "Black", yardage: 6712, rating: 75.2, slope: 138)
]

// MARK: Visby Golf Club — Gotland, Sweden
private let VISBY_GC_ID = UUID(uuidString: "3C4D5E6F-7A8B-4C3D-AE4F-5A6B7C8D9E0F")!

let VISBY_GC_PARS: [Int] = [
    3,4,4,5,3,5,3,4,4,
    5,4,4,4,3,4,5,3,5
]

let VISBY_GC_HCS: [Int] = [
    17,7,5,1,13,11,9,3,15,
    10,6,14,16,18,8,2,12,4
]

// MARK: Falsterbo Golf Club — Falsterbo, Sweden
private let FALSTERBO_GC_ID = UUID(uuidString: "4D5E6F7A-8B9C-4D4E-BF5A-6B7C8D9E0F1A")!

let FALSTERBO_GC_PARS: [Int] = [
    4,3,5,4,4,3,4,3,4,
    4,3,4,5,3,5,4,4,5
]

let FALSTERBO_GC_HCS: [Int] = [
    7,17,11,1,5,15,9,13,3,
    8,18,2,6,10,14,4,12,16
]

let FALSTERBO_GC_TEES: [TeeInfo] = [
    TeeInfo(teeName: "White", yardage: 6650, rating: 72.1, slope: 121)
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
            architect: "Dick Nugent",
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
            architect: "William Langford & Theodore Moreau",
            type: "Private",
            phone: "(847) 381-1960",
            website: "https://www.biltmore-cc.com",
            address: "160 Biltmore Drive, North Barrington, IL 60010",
            isWolfApproved: true
        ),
        c(
            ELGIN_CC_ID,
            "Elgin Country Club",
            ELGIN_CC_PARS,
            ELGIN_CC_HCS,
            ELGIN_CC_TEES,
            country: "USA",
            state: "IL",
            architect: "Tom Bendelow",
            type: "Private",
            phone: "(847) 741-1716",
            website: "https://www.elgincc.com",
            address: "2575 Weld Road, Elgin, IL 60124",
            isWolfApproved: true
        ),
        c(
            WILMETTE_GC_ID,
            "Wilmette Golf Club",
            WILMETTE_GC_PARS,
            WILMETTE_GC_HCS,
            WILMETTE_GC_TEES,
            country: "USA",
            state: "IL",
            architect: "Dick Nugent",
            type: "Public",
            phone: "(847) 256-9777",
            website: "https://www.golfwilmette.com",
            address: "Lake Ave. & Harms Rd., Wilmette, IL",
            isWolfApproved: true
        ),
        c(
            CEDAR_RAPIDS_CC_ID,
            "Cedar Rapids Country Club",
            CEDAR_RAPIDS_PARS,
            CEDAR_RAPIDS_HCS,
            country: "USA",
            state: "IA",
            architect: "Donald Ross & Tom Bendelow",
            type: "Private",
            phone: "(319) 363-9673",
            website: "https://www.cedarrapidscc.com",
            address: "550 27th St Dr SE, Cedar Rapids, IA 52403",
            isWolfApproved: false
        ),

        c(WYNSTONE_SILVER_ID, "Wynstone", WYNSTONE_SILVER_PARS, WYNSTONE_SILVER_HCS,
          country: "USA",
          state: "IL",
          architect: "Jack Nicklaus",
          type: "Private",
          phone: "(847) 304-2800",
          website: "https://www.wynstone.org",
          address: "1 South Wynstone Drive, North Barrington, IL 60010"),

        c(BARRINGTON_HILLS_WHITE_ID, "Barrington Hills", BARRINGTON_HILLS_WHITE_PARS, BARRINGTON_HILLS_WHITE_HCS,
          country: "USA",
          state: "IL",
          architect: "George O'Neil",
          type: "Private",
          phone: "(847) 381-4200",
          website: "https://www.barringtonhillscc.com",
          address: "300 W. County Line Road, Barrington Hills, IL 60010"),

        c(CRANES_LANDING_BLUE_ID, "Crane's Landing", CRANES_LANDING_BLUE_PARS, CRANES_LANDING_BLUE_HCS,
          country: "USA",
          state: "IL",
          architect: "George Fazio",
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
          architect: "Ken Killian & Dick Nugent",
          type: "Private",
          phone: "(847) 320-3450",
          website: "https://www.kemperlakesgolf.com",
          address: "24000 N. Old McHenry Road, Kildeer, IL 60047"),

        c(TWIN_ORCHARD_RED_ID, "Twin Orchard CC (Red)",
          TWIN_ORCHARD_RED_PARS, TWIN_ORCHARD_RED_HCS,
          TWIN_ORCHARD_RED_TEES,
          country: "USA",
          state: "IL",
          architect: "C.D. Wagstaff",
          type: "Private",
          phone: "(847) 634-3800",
          website: "https://www.twinorchardcc.org",
          address: "22353 Old McHenry Road, Long Grove, IL 60047",
          isWolfApproved: true),

        c(TWIN_ORCHARD_WHITE_ID, "Twin Orchard CC (White)",
          TWIN_ORCHARD_WHITE_PARS, TWIN_ORCHARD_WHITE_HCS,
          TWIN_ORCHARD_WHITE_TEES,
          country: "USA",
          state: "IL",
          architect: "C.D. Wagstaff",
          type: "Private",
          phone: "(847) 634-3800",
          website: "https://www.twinorchardcc.org",
          address: "22353 Old McHenry Road, Long Grove, IL 60047",
          isWolfApproved: true),

        c(RICH_HARVEST_SILVER_ID, "Rich Harvest Farms", RICH_HARVEST_SILVER_PARS, RICH_HARVEST_SILVER_HCS,
          country: "USA",
          state: "IL",
          architect: "Jerry Rich / Greg Martin",
          type: "Private",
          phone: "(630) 466-7610",
          website: "https://www.richharvestfarms.com",
          address: "7S771 Dugan Road, Sugar Grove, IL 60554"),


        c(BUTLER_NATIONAL_BUTLER_TEE_ID, "Butler National (7,550-yard)", BUTLER_NATIONAL_BUTLER_TEE_PARS, BUTLER_NATIONAL_BUTLER_TEE_HCS, BUTLER_NATIONAL_BUTLER_TEE_TEES,
          country: "USA",
          state: "IL",
          architect: "George Fazio & Tom Fazio",
          type: "Private",
          phone: "(630) 990-3333",
          website: "https://www.butlernational.org",
          address: "2616 S York Road, Oak Brook, IL 60523"),

        c(
            RIVER_FOREST_CC_ID,
            "River Forest Country Club",
            RIVER_FOREST_CC_PARS,
            RIVER_FOREST_CC_HCS,
            RIVER_FOREST_CC_TEES,
            country: "USA",
            state: "IL",
            region: "Elmhurst",
            architect: "Frank P. McDonald / A.W. Tillinghast",
            type: "Private",
            phone: "(630) 279-5444",
            website: "https://www.riverforestcc.org",
            address: "15 W 468 Grand Avenue, Elmhurst, IL 60126"
        ),

        c(
            MEDINAH_CC_3_ID,
            "Medinah CC (Course #3)",
            MEDINAH_CC_3_PARS,
            MEDINAH_CC_3_HCS,
            MEDINAH_CC_3_TEES,
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

        c(
            MEDINAH_CC_2_ID,
            "Medinah CC (Course #2)",
            MEDINAH_CC_2_PARS,
            MEDINAH_CC_2_HCS,
            MEDINAH_CC_2_TEES,
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
          architect: "Harry Vignocchi",
          type: "Daily-Fee",
          phone: "(847) 381-6500",
          website: "https://www.makraygolf.com",
          address: "1010 S. Northwest Highway, Barrington, IL 60010"),

        c(LAKE_BARRINGTON_SHORES_BLACK_ID, "Lake Barrington Shores (Black)", LAKE_BARRINGTON_SHORES_BLACK_PARS, LAKE_BARRINGTON_SHORES_BLACK_HCS, LAKE_BARRINGTON_SHORES_BLACK_TEES,
          country: "USA",
          state: "IL",
          architect: "Larry Packard",
          type: "Private",
          phone: "(847) 382-4240",
          website: "https://www.golflakebarrington.com",
          address: "40 Shoreline Road, Lake Barrington, IL 60010"),

        c(FOXFORD_HILLS_BLACK_ID, "Foxford Hills (Black)", FOXFORD_HILLS_BLACK_PARS, FOXFORD_HILLS_BLACK_HCS, FOXFORD_HILLS_BLACK_TEES,
          country: "USA",
          state: "IL",
          architect: "Dick Nugent",
          type: "Daily-Fee",
          phone: "(847) 639-0400",
          website: "https://www.foxfordhillsgolfclub.com",
          address: "6800 S. Rawson Bridge Road, Cary, IL 60013"),

        c(CARY_CC_BLUE_ID, "Cary CC (Blue)", CARY_CC_BLUE_PARS, CARY_CC_BLUE_HCS, CARY_CC_BLUE_TEES,
          country: "USA",
          state: "IL",
          architect: "H. H. King",
          type: "Private",
          phone: "(847) 639-3161",
          website: "https://www.carycountryclub.com",
          address: "2400 Grove Lane, Cary, IL 60013"),

        c(CHALET_HILLS_BLACK_ID, "Chalet Hills (Black)", CHALET_HILLS_BLACK_PARS, CHALET_HILLS_BLACK_HCS, CHALET_HILLS_BLACK_TEES,
          country: "USA",
          state: "IL",
          architect: "Ken Killian",
          type: "Daily-Fee",
          phone: "(847) 639-0666",
          website: "https://www.chalethillsgolfclub.com",
          address: "943 Rawson Bridge Road, Cary, IL 60013"),

        c(TPC_DEERE_RUN_TPC_ID, "TPC Deere Run (TPC)", TPC_DEERE_RUN_TPC_PARS, TPC_DEERE_RUN_TPC_HCS, TPC_DEERE_RUN_TPC_TEES,
          country: "USA",
          state: "IL",
          architect: "D.A. Weibring & Chris Gray",
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
        c(GLEN_OAKS_CC_IA_ID, "Glen Oaks Country Club", GLEN_OAKS_CC_IA_PARS, GLEN_OAKS_CC_IA_HCS, GLEN_OAKS_CC_IA_TEES,
          country: "USA",
          state: "IA",
          region: "Des Moines",
          architect: "Tom Fazio",
          type: "Private",
          phone: "(515) 221-9000",
          website: "https://www.glenoakscc.com",
          address: "1401 Glen Oaks Drive, West Des Moines, IA 50266"),
        c(DMGCC_NORTH_ID, "Des Moines G&CC (North)", DMGCC_NORTH_PARS, DMGCC_NORTH_HCS, DMGCC_NORTH_TEES,
          country: "USA",
          state: "IA",
          region: "Des Moines",
          architect: "Pete Dye",
          type: "Private",
          phone: "(515) 440-7500",
          website: "https://www.dmgcc.org",
          address: "1600 Jordan Creek Parkway, West Des Moines, IA 50266"),
        c(DMGCC_SOUTH_ID, "Des Moines G&CC (South)", DMGCC_SOUTH_PARS, DMGCC_SOUTH_HCS, DMGCC_SOUTH_TEES,
          country: "USA",
          state: "IA",
          region: "Des Moines",
          architect: "Pete Dye",
          type: "Private",
          phone: "(515) 440-7500",
          website: "https://www.dmgcc.org",
          address: "1600 Jordan Creek Parkway, West Des Moines, IA 50266"),
        c(WAKONDA_CLUB_ID, "Wakonda Club", WAKONDA_CLUB_PARS, WAKONDA_CLUB_HCS, WAKONDA_CLUB_TEES,
          country: "USA",
          state: "IA",
          region: "Des Moines",
          architect: "William Langford",
          type: "Private",
          address: "3915 Fleur Drive, Des Moines, IA 50321"),
        c(BLUE_TOP_RIDGE_ID, "Blue Top Ridge", BLUE_TOP_RIDGE_PARS, BLUE_TOP_RIDGE_HCS, BLUE_TOP_RIDGE_TEES,
          country: "USA",
          state: "IA",
          region: "Iowa City",
          architect: "Rees Jones",
          type: "Resort",
          address: "3184 Highway 22, Riverside, IA 52327"),
        c(SPIRIT_HOLLOW_ID, "Spirit Hollow Golf Course", SPIRIT_HOLLOW_PARS, SPIRIT_HOLLOW_HCS, SPIRIT_HOLLOW_TEES,
          country: "USA",
          state: "IA",
          region: "Southeast Iowa",
          architect: "Rick Jacobson",
          type: "Semi-Private",
          phone: "(319) 752-0004",
          website: "https://www.spirithollow.com",
          address: "5592 Clubhouse Dr, Burlington, IA 52601"),
        c(TOURNAMENT_CLUB_IOWA_ID, "Tournament Club of Iowa", TOURNAMENT_CLUB_IOWA_PARS, TOURNAMENT_CLUB_IOWA_HCS, TOURNAMENT_CLUB_IOWA_TEES,
          country: "USA",
          state: "IA",
          region: "Des Moines",
          architect: "Arnold Palmer",
          type: "Daily-Fee",
          phone: "(515) 984-6668",
          address: "1000 Tournament Club Drive, Polk City, IA 50226"),
        c(AMANA_COLONIES_GC_ID, "Amana Colonies Golf Club", AMANA_COLONIES_GC_PARS, AMANA_COLONIES_GC_HCS, AMANA_COLONIES_GC_TEES,
          country: "USA",
          state: "IA",
          region: "Iowa City",
          architect: "William J. Spear",
          type: "Semi-Private",
          phone: "(319) 622-6222",
          website: "https://www.amanagolf.com",
          address: "451 27th Avenue, Amana, IA 52203"),

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
          architect: "Tom Fazio",
          type: "Resort",
          phone: "(863) 428-1000",
          website: "https://www.streamsongresort.com",
          address: "1000 Streamsong Drive, Bowling Green, FL 33834"),
        c(STREAMSONG_RED_ID, "Streamsong (Red)", STREAMSONG_RED_PARS, STREAMSONG_RED_HCS,
          country: "USA",
          state: "FL",
          architect: "Tom Fazio",
          type: "Resort",
          phone: "(863) 428-1000",
          website: "https://www.streamsongresort.com",
          address: "1000 Streamsong Drive, Bowling Green, FL 33834"),
        c(STREAMSONG_BLACK_ID, "Streamsong (Black)", STREAMSONG_BLACK_PARS, STREAMSONG_BLACK_HCS,
          country: "USA",
          state: "FL",
          architect: "Tom Fazio",
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
          architect: "Pete Dye & Greg Norman",
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
          architect: "Donald Ross / Gil Hanse & Jim Wagner",
          type: "Private",
          phone: "(561) 626-0280",
          website: "https://www.seminolegolfclub.com",
          address: "901 Seminole Boulevard, Juno Beach, FL 33408"),
        
        c(CALUSA_PINES_ID, "Calusa Pines (Gold)", CALUSA_PINES_GOLD_PARS, CALUSA_PINES_GOLD_HCS,
          country: "USA", state: "FL",
          architect: "Ron Garl",
          phone: "(239) 352-2200",
          website: "https://www.calusapinesgolfclub.com",
          address: "2000 Calusa Pines Drive, Naples, FL 34120"),
      
        c(KAROO_ID, "Karoo (Black)", KAROO_BLACK_PARS, KAROO_BLACK_HCS_TODO,
          country: "USA", state: "FL",
          architect: "Bill Coore & Ben Crenshaw",
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
          architect: "Bill Coore & Ben Crenshaw",
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
          architect: "Michael Hurdzan & Dana Fry & Ron Whitten",
          type: "Daily-Fee",
          phone: "(866) 772-4769",
          website: "https://www.erinhills.com",
          address: "7169 County Road O, Erin, WI 53027"),
        c(SAND_VALLEY_LIDO_ID, "Sand Valley (Lido)", SAND_VALLEY_LIDO_PARS_TODO, SAND_VALLEY_LIDO_HCS_TODO,
          country: "USA",
          state: "WI",
          architect: "Charles Blair Macdonald / Seth Raynor / Tom Doak / Brian Schneider",
          type: "Resort",
          phone: "(888) 651-5539",
          website: "https://www.sandvalley.com",
          address: "1697 Leopold Way, Nekoosa, WI 54457"),
        
        c(SAND_VALLEY_SEDGE_VALLEY_CHAMPIONSHIP_ID, "Sand Valley (Sedge Valley — Championship)", SAND_VALLEY_SEDGE_VALLEY_CHAMPIONSHIP_PARS, SAND_VALLEY_SEDGE_VALLEY_CHAMPIONSHIP_HCS, SAND_VALLEY_SEDGE_VALLEY_CHAMPIONSHIP_TEES,
          country: "USA",
          state: "WI",
          architect: "Tom Fazio",
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
            architect: "Tom Weiskopf & Jay Morrish",
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
            architect: "Tom Weiskopf & Jay Morrish",
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
            architect: "Tom Fazio",
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
            architect: "Tom Weiskopf",
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
            architect: "Tim Jackson & David Kahn",
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
            architect: "Tom Weiskopf & Jay Morrish",
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
            architect: "David McLay Kidd",
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
            architect: "Tom Doak",
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
            architect: "Bill Coore & Ben Crenshaw",
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
            architect: "Tom Doak & Jim Urbina",
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
            architect: "Bill Coore & Ben Crenshaw",
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
            architect: "Jack Neville & Douglas Grant",
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
            architect: "Robert Trent Jones, Sr.",
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
        c(
            PASATIEMPO_CHAMPIONSHIP_ID,
            "Pasatiempo (Championship)",
            PASATIEMPO_CHAMPIONSHIP_PARS,
            PASATIEMPO_CHAMPIONSHIP_HCS,
            PASATIEMPO_CHAMPIONSHIP_TEES,
            country: "USA",
            state: "CA",
            region: "NorCal",
            architect: "Alister MacKenzie",
            type: "Daily-Fee",
            address: "20 Clubhouse Road, Santa Cruz, CA 95060"
        ),
        c(
            PASATIEMPO_MIDDLE_ID,
            "Pasatiempo (Middle)",
            PASATIEMPO_MIDDLE_PARS,
            PASATIEMPO_MIDDLE_HCS,
            country: "USA",
            state: "CA",
            region: "NorCal",
            architect: "Alister MacKenzie",
            type: "Daily-Fee",
            address: "20 Clubhouse Road, Santa Cruz, CA 95060"
        ),
        c(
            LACC_NORTH_BLUE_ID,
            "LACC (North – Blue)",
            LACC_NORTH_BLUE_PARS,
            LACC_NORTH_BLUE_HCS,
            LACC_NORTH_TEES,
            country: "USA",
            state: "CA",
            region: "SoCal",
            architect: "George C. Thomas",
            type: "Private",
            address: "10101 Wilshire Blvd, Los Angeles, CA 90024"
        ),
        c(
            LACC_SOUTH_CHAMPIONSHIP_ID,
            "LACC (South – Championship)",
            LACC_SOUTH_CHAMPIONSHIP_PARS,
            LACC_SOUTH_CHAMPIONSHIP_HCS,
            LACC_SOUTH_TEES,
            country: "USA",
            state: "CA",
            region: "SoCal",
            architect: "George C. Thomas / Gil Hanse",
            type: "Private",
            address: "10101 Wilshire Blvd, Los Angeles, CA 90024"
        ),
        c(
            RIVIERA_CC_BLACK_ID,
            "Riviera CC (Black)",
            RIVIERA_CC_BLACK_PARS,
            RIVIERA_CC_BLACK_HCS,
            RIVIERA_CC_TEES,
            country: "USA",
            state: "CA",
            region: "SoCal",
            architect: "George C. Thomas",
            type: "Private",
            address: "1250 Capri Drive, Pacific Palisades, CA 90272"
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
            architect: "Robert Trent Jones, Sr.",
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
            architect: "A.W. Tillinghast",
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
            architect: "Tom Fazio",
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
            architect: "Randy Heckenkemper",
            type: "Private",
            phone: "(918) 272-1260",
            website: "https://www.patriotgolfclub.com/",
            address: "5790 N. Patriot Dr., Owasso, OK 74055"
        ),
        c(
            SHANGRI_LA_HL_ID,
            "Shangri-La (Heritage+Legends)",
            SHANGRI_LA_HL_PARS,
            SHANGRI_LA_HL_HCS,
            SHANGRI_LA_HL_TEES,
            country: "USA",
            state: "OK",
            architect: "Tom Clark (renovation)",
            type: "Resort",
            phone: "(918) 257-4204",
            website: "https://www.shangrilaok.com/",
            address: "57301 E. Highway 125, Monkey Island, OK 74331",
            isWolfApproved: true
        ),
        c(
            SHANGRI_LA_LC_ID,
            "Shangri-La (Legends+Champions)",
            SHANGRI_LA_LC_PARS,
            SHANGRI_LA_LC_HCS,
            SHANGRI_LA_LC_TEES,
            country: "USA",
            state: "OK",
            architect: "Tom Clark (renovation)",
            type: "Resort",
            phone: "(918) 257-4204",
            website: "https://www.shangrilaok.com/",
            address: "57301 E. Highway 125, Monkey Island, OK 74331",
            isWolfApproved: true
        ),
        c(
            SHANGRI_LA_CH_ID,
            "Shangri-La (Champions+Heritage)",
            SHANGRI_LA_CH_PARS,
            SHANGRI_LA_CH_HCS,
            SHANGRI_LA_CH_TEES,
            country: "USA",
            state: "OK",
            architect: "Tom Clark (renovation)",
            type: "Resort",
            phone: "(918) 257-4204",
            website: "https://www.shangrilaok.com/",
            address: "57301 E. Highway 125, Monkey Island, OK 74331",
            isWolfApproved: true
        ),
        c(
            DORNICK_HILLS_ID,
            "Dornick Hills CC",
            DORNICK_HILLS_PARS,
            DORNICK_HILLS_HCS,
            DORNICK_HILLS_TEES,
            country: "USA",
            state: "OK",
            architect: "Perry Maxwell",
            type: "Private",
            phone: "(580) 223-4071",
            website: "https://www.dornickhills.com/",
            address: "519 Country Club Rd, Ardmore, OK 73401",
            isWolfApproved: true
        ),
        c(
            OAK_TREE_CC_EAST_ID,
            "Oak Tree CC (East)",
            OAK_TREE_CC_EAST_PARS,
            OAK_TREE_CC_EAST_HCS,
            OAK_TREE_CC_EAST_TEES,
            country: "USA",
            state: "OK",
            architect: "Pete Dye",
            type: "Private",
            phone: "(405) 340-1010",
            website: "https://www.oaktreecountryclub.com/",
            address: "700 Country Club Dr, Edmond, OK 73025",
            isWolfApproved: true
        ),
        c(
            OAK_TREE_CC_WEST_ID,
            "Oak Tree CC (West)",
            OAK_TREE_CC_WEST_PARS,
            OAK_TREE_CC_WEST_HCS,
            OAK_TREE_CC_WEST_TEES,
            country: "USA",
            state: "OK",
            architect: "Pete Dye",
            type: "Private",
            phone: "(405) 340-1010",
            website: "https://www.oaktreecountryclub.com/",
            address: "700 Country Club Dr, Edmond, OK 73025",
            isWolfApproved: true
        ),
        c(
            OAK_TREE_NATIONAL_ID,
            "Oak Tree National",
            OAK_TREE_NATIONAL_PARS,
            OAK_TREE_NATIONAL_HCS,
            OAK_TREE_NATIONAL_TEES,
            country: "USA",
            state: "OK",
            architect: "Pete Dye",
            type: "Private",
            phone: "(405) 348-2004",
            website: "https://www.oaktreenational.com/",
            address: "1515 Oak Tree Drive, Edmond, OK 73025",
            isWolfApproved: true
        ),
        c(
            SOUTHERN_HILLS_CC_ID,
            "Southern Hills CC",
            SOUTHERN_HILLS_CC_PARS,
            SOUTHERN_HILLS_CC_HCS,
            SOUTHERN_HILLS_CC_TEES,
            country: "USA",
            state: "OK",
            architect: "Perry Maxwell",
            type: "Private",
            phone: "(918) 492-3351",
            website: "https://www.southernhillscc.com/",
            address: "2636 East 61st Street, Tulsa, OK 74136",
            isWolfApproved: true
        ),
        c(
            KARSTEN_CREEK_ID,
            "Karsten Creek GC",
            KARSTEN_CREEK_PARS,
            KARSTEN_CREEK_HCS,
            KARSTEN_CREEK_TEES,
            country: "USA",
            state: "OK",
            architect: "Tom Fazio / Dennis Wise",
            type: "Private",
            phone: "(405) 743-1658",
            website: "https://www.karstencreek.com/",
            address: "1800 S. Memorial Drive, Stillwater, OK 74074",
            isWolfApproved: true
        ),
        c(
            COLORADO_GOLF_CLUB_ID,
            "Colorado Golf Club",
            COLORADO_GOLF_CLUB_PARS,
            COLORADO_GOLF_CLUB_HCS,
            country: "USA",
            state: "CO",
            architect: "Bill Coore & Ben Crenshaw",
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
            architect: "Tom Fazio",
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
            architect: "Davis Love III & Mark Love",
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
            architect: "Davis Love III & Mark Love",
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
            architect: "Alister MacKenzie & Bobby Jones",
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
            architect: "Tom Doak & Angela Moser",
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
            architect: "Bill Coore & Ben Crenshaw",
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
            CHAMBERS_BAY_ID,
            "Chambers Bay",
            CHAMBERS_BAY_PARS,
            CHAMBERS_BAY_HCS,
            CHAMBERS_BAY_TEES,
            country: "USA",
            state: "WA",
            architect: "Robert Trent Jones Jr.",
            type: "Public",
            phone: "877-295-4657",
            website: "https://www.chambersbaygolf.com",
            address: "6320 Grandview Drive West, University Place, WA 98467",
            isWolfApproved: true
        ),
        c(
            SAHALEE_EAST_NORTH_ID,
            "Sahalee Country Club (East-North)",
            SAHALEE_EAST_NORTH_PARS,
            SAHALEE_EAST_NORTH_HCS,
            SAHALEE_EAST_NORTH_TEES,
            country: "USA",
            state: "WA",
            architect: "Ted Robinson Sr.",
            type: "Private",
            phone: "(425) 868-8800",
            website: "https://www.sahalee.com",
            address: "21200 NE Sahalee Country Club Dr, Sammamish, WA 98074",
            isWolfApproved: true
        ),
        c(
            SAHALEE_EAST_SOUTH_ID,
            "Sahalee Country Club (East-South)",
            SAHALEE_EAST_SOUTH_PARS,
            SAHALEE_EAST_SOUTH_HCS,
            SAHALEE_EAST_SOUTH_TEES,
            country: "USA",
            state: "WA",
            architect: "Ted Robinson Sr.",
            type: "Private",
            phone: "(425) 868-8800",
            website: "https://www.sahalee.com",
            address: "21200 NE Sahalee Country Club Dr, Sammamish, WA 98074",
            isWolfApproved: true
        ),
        c(
            SAHALEE_NORTH_SOUTH_ID,
            "Sahalee Country Club (North-South)",
            SAHALEE_NORTH_SOUTH_PARS,
            SAHALEE_NORTH_SOUTH_HCS,
            SAHALEE_NORTH_SOUTH_TEES,
            country: "USA",
            state: "WA",
            architect: "Ted Robinson Sr.",
            type: "Private",
            phone: "(425) 868-8800",
            website: "https://www.sahalee.com",
            address: "21200 NE Sahalee Country Club Dr, Sammamish, WA 98074",
            isWolfApproved: true
        ),
        c(
            ALDARRA_GC_ID,
            "Aldarra Golf Club",
            ALDARRA_GC_PARS,
            ALDARRA_GC_HCS,
            ALDARRA_GC_TEES,
            country: "USA",
            state: "WA",
            architect: "Tom Fazio",
            type: "Private",
            address: "23005 SE Tiger Mountain Rd, Fall City, WA 98024",
            isWolfApproved: true
        ),
        c(
            WINE_VALLEY_GC_ID,
            "Wine Valley Golf Club",
            WINE_VALLEY_GC_PARS,
            WINE_VALLEY_GC_HCS,
            WINE_VALLEY_GC_TEES,
            country: "USA",
            state: "WA",
            architect: "Dan Hixson",
            type: "Daily-Fee",
            phone: "(509) 522-4653",
            website: "https://www.winevalleygolfclub.com",
            address: "17111 N Stateline Rd, Walla Walla, WA 99362",
            isWolfApproved: true
        ),
        c(
            PALOUSE_RIDGE_GC_ID,
            "Palouse Ridge Golf Club",
            PALOUSE_RIDGE_GC_PARS,
            PALOUSE_RIDGE_GC_HCS,
            PALOUSE_RIDGE_GC_TEES,
            country: "USA",
            state: "WA",
            architect: "John Harbottle III",
            type: "Daily-Fee",
            phone: "(509) 335-4342",
            website: "https://www.palouseridge.com",
            address: "1260 NE Palouse Ridge Dr, Pullman, WA 99163",
            isWolfApproved: true
        ),
        c(
            HOME_COURSE_ID,
            "The Home Course",
            HOME_COURSE_PARS,
            HOME_COURSE_HCS,
            HOME_COURSE_TEES,
            country: "USA",
            state: "WA",
            architect: "Mike Asmundson",
            type: "Daily-Fee",
            phone: "(253) 964-5965",
            website: "https://www.thehomecourse.com",
            address: "5 Inverness Dr E, DuPont, WA 98327",
            isWolfApproved: true
        ),
        c(
            GOLD_MTN_OLYMPIC_ID,
            "Gold Mountain Golf Club (Olympic)",
            GOLD_MTN_OLYMPIC_PARS,
            GOLD_MTN_OLYMPIC_HCS,
            GOLD_MTN_OLYMPIC_TEES,
            country: "USA",
            state: "WA",
            architect: "John Harbottle III",
            type: "Municipal",
            phone: "(360) 415-5432",
            website: "https://www.goldmountaingolf.com",
            address: "7263 W Belfair Valley Rd, Bremerton, WA 98312",
            isWolfApproved: true
        ),
        c(
            GOLD_MTN_CASCADE_ID,
            "Gold Mountain Golf Club (Cascade)",
            GOLD_MTN_CASCADE_PARS,
            GOLD_MTN_CASCADE_HCS,
            GOLD_MTN_CASCADE_TEES,
            country: "USA",
            state: "WA",
            architect: "John Harbottle III",
            type: "Municipal",
            phone: "(360) 415-5432",
            website: "https://www.goldmountaingolf.com",
            address: "7263 W Belfair Valley Rd, Bremerton, WA 98312",
            isWolfApproved: true
        ),
        c(
            SALISH_CLIFFS_GC_ID,
            "Salish Cliffs Golf Club",
            SALISH_CLIFFS_GC_PARS,
            SALISH_CLIFFS_GC_HCS,
            SALISH_CLIFFS_GC_TEES,
            country: "USA",
            state: "WA",
            architect: "Gene Bates",
            type: "Daily-Fee",
            phone: "(360) 462-3673",
            address: "91 W State Route 108, Shelton, WA 98584",
            isWolfApproved: true
        ),
        c(
            INDIAN_CANYON_GC_ID,
            "Indian Canyon Golf Course",
            INDIAN_CANYON_GC_PARS,
            INDIAN_CANYON_GC_HCS,
            INDIAN_CANYON_GC_TEES,
            country: "USA",
            state: "WA",
            architect: "H. Chandler Egan",
            type: "Municipal",
            phone: "(509) 625-6200",
            address: "4304 W West Dr, Spokane, WA 99224"
        ),
        c(
            SUNCADIA_PROSPECTOR_ID,
            "Suncadia Resort (Prospector)",
            SUNCADIA_PROSPECTOR_PARS,
            SUNCADIA_PROSPECTOR_HCS,
            SUNCADIA_PROSPECTOR_TEES,
            country: "USA",
            state: "WA",
            architect: "Arnold Palmer",
            type: "Resort",
            phone: "(509) 260-4225",
            website: "https://www.suncadia.com",
            address: "3600 Suncadia Trail, Cle Elum, WA 98922",
            isWolfApproved: true
        ),
        c(
            SUNCADIA_ROPE_RIDER_ID,
            "Suncadia Resort (Rope Rider)",
            SUNCADIA_ROPE_RIDER_PARS,
            SUNCADIA_ROPE_RIDER_HCS,
            SUNCADIA_ROPE_RIDER_TEES,
            country: "USA",
            state: "WA",
            architect: "Peter Jacobsen & Jim Hardy",
            type: "Resort",
            phone: "(509) 260-4225",
            website: "https://www.suncadia.com",
            address: "3600 Suncadia Trail, Cle Elum, WA 98922",
            isWolfApproved: true
        ),
        c(
            ARCADIA_BLUFFS_BLUFFS_BLUE_ID,
            "Arcadia Bluffs (Bluffs — Blue)",
            ARCADIA_BLUFFS_BLUFFS_BLUE_PARS,
            ARCADIA_BLUFFS_BLUFFS_BLUE_HCS,
            ARCADIA_BLUFFS_BLUFFS_BLUE_TEES,
            country: "USA",
            state: "MI",
            architect: "Warren Henderson & Rick Smith",
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
            architect: "Old Tom Morris",
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
            PORTMARNOCK_CHAMPIONSHIP_ID,
            "Portmarnock Golf Club",
            PORTMARNOCK_CHAMPIONSHIP_PARS,
            PORTMARNOCK_CHAMPIONSHIP_HCS,
            PORTMARNOCK_CHAMPIONSHIP_TEES,
            country: "Ireland",
            state: nil,
            architect: "William C. Pickeman & George Coburn (1894)",
            type: "Private",
            phone: "+353 1 846 2968",
            website: "https://www.portmarnockgolfclub.ie",
            address: "Golf Links Road, Portmarnock, Co. Dublin, D13 KD96, Ireland"
        ),
        c(
            PORTMARNOCK_YELLOW_NINE_ID,
            "Portmarnock (Yellow Nine)",
            PORTMARNOCK_YELLOW_NINE_PARS,
            PORTMARNOCK_YELLOW_NINE_HCS,
            PORTMARNOCK_YELLOW_NINE_TEES,
            country: "Ireland",
            state: nil,
            architect: "Fred Hawtree (1971)",
            type: "Private",
            phone: "+353 1 846 2968",
            website: "https://www.portmarnockgolfclub.ie",
            address: "Golf Links Road, Portmarnock, Co. Dublin, D13 KD96, Ireland",
            routing: .nineStandard
        ),
        c(
            ROSAPENNA_ST_PATRICKS_ID,
            "Rosapenna (St. Patrick's Links)",
            ROSAPENNA_ST_PATRICKS_PARS,
            ROSAPENNA_ST_PATRICKS_HCS,
            ROSAPENNA_ST_PATRICKS_TEES,
            country: "Ireland",
            state: nil,
            region: "Donegal",
            architect: "Tom Doak",
            type: "Resort",
            website: "https://www.rosapenna.ie",
            address: "Rosapenna, Downings, Co. Donegal, Ireland"
        ),
        c(
            ROSAPENNA_SANDY_HILLS_ID,
            "Rosapenna (Sandy Hills Links)",
            ROSAPENNA_SANDY_HILLS_PARS,
            ROSAPENNA_SANDY_HILLS_HCS,
            ROSAPENNA_SANDY_HILLS_TEES,
            country: "Ireland",
            state: nil,
            region: "Donegal",
            architect: "Pat Ruddy",
            type: "Resort",
            website: "https://www.rosapenna.ie",
            address: "Rosapenna, Downings, Co. Donegal, Ireland"
        ),
        c(
            ROSAPENNA_OLD_TOM_MORRIS_ID,
            "Rosapenna (Old Tom Morris Links)",
            ROSAPENNA_OLD_TOM_MORRIS_PARS,
            ROSAPENNA_OLD_TOM_MORRIS_HCS,
            ROSAPENNA_OLD_TOM_MORRIS_TEES,
            country: "Ireland",
            state: nil,
            region: "Donegal",
            architect: "Old Tom Morris (1891)",
            type: "Resort",
            website: "https://www.rosapenna.ie",
            address: "Rosapenna, Downings, Co. Donegal, Ireland"
        ),
        c(
            COUNTY_SLIGO_ID,
            "County Sligo Golf Club (Rosses Point)",
            COUNTY_SLIGO_PARS,
            COUNTY_SLIGO_HCS,
            COUNTY_SLIGO_TEES,
            country: "Ireland",
            state: nil,
            region: "Sligo",
            architect: "Harry S. Colt (1927)",
            type: "Private",
            phone: "+353 71 9177134",
            website: "https://www.countysligogolfclub.ie",
            address: "Rosses Point, Co. Sligo, Ireland"
        ),
        c(
            EUROPEAN_CLUB_ID,
            "The European Club",
            EUROPEAN_CLUB_PARS,
            EUROPEAN_CLUB_HCS,
            EUROPEAN_CLUB_TEES,
            country: "Ireland",
            state: nil,
            region: "Wicklow",
            architect: "Pat Ruddy",
            type: "Private",
            website: "https://www.theeuropeanclub.com",
            address: "Brittas Bay, Co. Wicklow, Ireland"
        ),
        c(
            BALLINLOUGH_CASTLE_ID,
            "Ballinlough Castle Golf Club",
            BALLINLOUGH_CASTLE_PARS,
            BALLINLOUGH_CASTLE_HCS,
            BALLINLOUGH_CASTLE_TEES,
            country: "Ireland",
            state: nil,
            region: "Westmeath",
            architect: "Pat Ruddy",
            type: "Public",
            address: "Clonmellon, Co. Westmeath, Ireland"
        ),
        c(
            BALLYLIFFIN_GLASHEDY_ID,
            "Ballyliffin Golf Club (Glashedy Links)",
            BALLYLIFFIN_GLASHEDY_PARS,
            BALLYLIFFIN_GLASHEDY_HCS,
            BALLYLIFFIN_GLASHEDY_TEES,
            country: "Ireland",
            state: nil,
            region: "Donegal",
            architect: "Pat Ruddy",
            type: "Semi-Private",
            website: "https://www.ballyliffingolfclub.com",
            address: "Ballyliffin, Inishowen, Co. Donegal, Ireland"
        ),
        c(
            CASTLEGREGORY_ID,
            "Castlegregory Golf & Fishing Club",
            CASTLEGREGORY_PARS,
            CASTLEGREGORY_HCS,
            CASTLEGREGORY_TEES,
            country: "Ireland",
            state: nil,
            region: "Kerry",
            architect: "Arthur Spring (1989)",
            type: "Public",
            phone: "+353 66 713 9444",
            address: "Castlegregory, Co. Kerry, Ireland",
            routing: .nineStandard
        ),
        c(
            CASTLECOMER_ID,
            "Castlecomer Golf Club",
            CASTLECOMER_PARS,
            CASTLECOMER_HCS,
            CASTLECOMER_TEES,
            country: "Ireland",
            state: nil,
            region: "Kilkenny",
            architect: "Pat Ruddy",
            type: "Public",
            phone: "+353 56 444 1139",
            website: "https://www.castlecomergolf.ie",
            address: "Drumgoole, Castlecomer, Co. Kilkenny, Ireland"
        ),
        c(
            CO_TIPPERARY_GCC_ID,
            "Co. Tipperary Golf & Country Club",
            CO_TIPPERARY_GCC_PARS,
            CO_TIPPERARY_GCC_HCS,
            CO_TIPPERARY_GCC_TEES,
            country: "Ireland",
            state: nil,
            region: "Tipperary",
            architect: "Philip Walton & Ken Kearney",
            type: "Resort",
            phone: "+353 62 71116",
            website: "https://www.cotipperarygolfclub.ie",
            address: "Dundrum, Co. Tipperary, Ireland"
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
            architect: "Old Tom Morris",
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
            ALWOODLEY_GC_ID,
            "Alwoodley Golf Club",
            ALWOODLEY_GC_PARS,
            ALWOODLEY_GC_HCS,
            ALWOODLEY_GC_TEES,
            country: "England",
            state: nil,
            region: "Leeds",
            architect: "Alister MacKenzie",
            type: "Private",
            phone: "+44 (0)113 268 1680",
            website: "https://www.alwoodley.co.uk",
            address: "Wigton Lane, Leeds, LS17 8SA, England, United Kingdom"
        ),
        c(
            MOORTOWN_GC_ID,
            "Moortown Golf Club",
            MOORTOWN_GC_PARS,
            MOORTOWN_GC_HCS,
            MOORTOWN_GC_TEES,
            country: "England",
            state: nil,
            region: "Leeds",
            architect: "Alister MacKenzie",
            type: "Private",
            phone: "+44 (0)113 268 6521",
            website: "https://www.moortown-golf-club.co.uk",
            address: "Harrogate Road, Leeds, LS17 7DB, England, United Kingdom"
        ),
        c(
            SUNNINGDALE_OLD_ID,
            "Sunningdale Golf Club (Old Course)",
            SUNNINGDALE_OLD_PARS,
            SUNNINGDALE_OLD_HCS,
            SUNNINGDALE_OLD_TEES,
            country: "England",
            state: nil,
            region: "Berkshire",
            architect: "Willie Park Jr.",
            type: "Private",
            phone: "+44 (0)1344 621681",
            website: "https://www.sunningdalegolfclub.co.uk",
            address: "Ridgemount Road, Sunningdale, Berkshire, SL5 9RR, England, United Kingdom",
            isWolfApproved: true
        ),
        c(
            SUNNINGDALE_NEW_ID,
            "Sunningdale Golf Club (New Course)",
            SUNNINGDALE_NEW_PARS,
            SUNNINGDALE_NEW_HCS,
            SUNNINGDALE_NEW_TEES,
            country: "England",
            state: nil,
            region: "Berkshire",
            architect: "Harry Colt",
            type: "Private",
            phone: "+44 (0)1344 621681",
            website: "https://www.sunningdalegolfclub.co.uk",
            address: "Ridgemount Road, Sunningdale, Berkshire, SL5 9RR, England, United Kingdom"
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
            CARNOUSTIE_CHAMP_ID,
            "Carnoustie Golf Links (Championship Course)",
            CARNOUSTIE_CHAMP_PARS,
            CARNOUSTIE_CHAMP_HCS,
            CARNOUSTIE_CHAMP_TEES,
            country: "Scotland",
            state: nil,
            architect: "Old Tom Morris",
            type: "Public",
            phone: "+44 (0)1241 802270",
            website: "https://www.carnoustiegolflinks.com",
            address: "Links Parade, Carnoustie, Angus DD7 7JE, Scotland, United Kingdom",
            isWolfApproved: true
        ),
        c(
            CARNOUSTIE_BURNSIDE_ID,
            "Carnoustie Golf Links (Burnside Course)",
            CARNOUSTIE_BURNSIDE_PARS,
            CARNOUSTIE_BURNSIDE_HCS,
            CARNOUSTIE_BURNSIDE_TEES,
            country: "Scotland",
            state: nil,
            architect: "James Braid",
            type: "Public",
            phone: "+44 (0)1241 802270",
            website: "https://www.carnoustiegolflinks.com",
            address: "Links Parade, Carnoustie, Angus DD7 7JE, Scotland, United Kingdom"
        ),
        c(
            CARNOUSTIE_BUDDON_ID,
            "Carnoustie Golf Links (Buddon Course)",
            CARNOUSTIE_BUDDON_PARS,
            CARNOUSTIE_BUDDON_HCS,
            CARNOUSTIE_BUDDON_TEES,
            country: "Scotland",
            state: nil,
            architect: "Dave Thomas & Peter Alliss",
            type: "Public",
            phone: "+44 (0)1241 802270",
            website: "https://www.carnoustiegolflinks.com",
            address: "Links Parade, Carnoustie, Angus DD7 7JE, Scotland, United Kingdom"
        ),
        c(
            KINGSBARNS_ID,
            "Kingsbarns Golf Links",
            KINGSBARNS_PARS,
            KINGSBARNS_HCS,
            KINGSBARNS_TEES,
            country: "Scotland",
            state: nil,
            architect: "Kyle Phillips",
            type: "Public",
            phone: "+44 (0)1334 460860",
            website: "https://www.kingsbarns.com",
            address: "Kingsbarns, St Andrews, Fife KY16 8QD, Scotland, United Kingdom",
            isWolfApproved: true
        ),
        c(
            CASTLE_STUART_ID,
            "Castle Stuart Golf Links",
            CASTLE_STUART_PARS,
            CASTLE_STUART_HCS,
            CASTLE_STUART_TEES,
            country: "Scotland",
            state: nil,
            architect: "Gil Hanse",
            type: "Private",
            website: "https://www.castlestuartgolf.com",
            address: "Petty, Inverness IV2 7PG, Scotland, United Kingdom",
            isWolfApproved: true
        ),
        c(
            CRUDEN_BAY_ID,
            "Cruden Bay Golf Club",
            CRUDEN_BAY_PARS,
            CRUDEN_BAY_HCS,
            CRUDEN_BAY_TEES,
            country: "Scotland",
            state: nil,
            architect: "Tom Simpson / Herbert Fowler",
            type: "Public",
            phone: "+44 (0)1779 812285",
            website: "https://www.crudenbaygolfclub.co.uk",
            address: "Aulton Road, Cruden Bay, Aberdeenshire AB42 0NN, Scotland, United Kingdom",
            isWolfApproved: true
        ),
        c(
            KINGS_LINKS_ID,
            "Kings Links Golf Centre",
            KINGS_LINKS_PARS,
            KINGS_LINKS_HCS,
            KINGS_LINKS_TEES,
            country: "Scotland",
            state: nil,
            architect: "Graham Webster",
            type: "Public",
            phone: "+44 (0)1224 641577",
            website: "https://www.kings-links.com",
            address: "Golf Road, Aberdeen AB24 1RZ, Scotland, United Kingdom"
        ),
        c(
            PRESTWICK_GC_ID,
            "Prestwick Golf Club",
            PRESTWICK_GC_PARS,
            PRESTWICK_GC_HCS,
            PRESTWICK_GC_TEES,
            country: "Scotland",
            state: nil,
            architect: "Old Tom Morris",
            type: "Semi-Private",
            phone: "+44 (0)1292 477404",
            address: "2-4 Links Road, Prestwick, Ayrshire KA9 1QH, Scotland, United Kingdom",
            isWolfApproved: true
        ),
        c(
            WESTERN_GAILES_ID,
            "Western Gailes Golf Club",
            WESTERN_GAILES_PARS,
            WESTERN_GAILES_HCS,
            WESTERN_GAILES_TEES,
            country: "Scotland",
            state: nil,
            architect: "Fred Morris",
            type: "Private",
            phone: "+44 (0)1294 311649",
            website: "https://www.westerngailes.com",
            address: "Western Gailes, Gailes Rd, Irvine KA11 5AE, Scotland, United Kingdom",
            isWolfApproved: true
        ),
        c(
            MACHRIHANISH_GC_ID,
            "Machrihanish Golf Club",
            MACHRIHANISH_GC_PARS,
            MACHRIHANISH_GC_HCS,
            MACHRIHANISH_GC_TEES,
            country: "Scotland",
            state: nil,
            architect: "Old Tom Morris",
            type: "Semi-Private",
            phone: "+44 (0)1586 810213",
            website: "https://www.machgolf.com",
            address: "Machrihanish, Campbeltown, PA28 6PT, Scotland, United Kingdom",
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
            ROYAL_BIRKDALE_ID,
            "Royal Birkdale Golf Club",
            ROYAL_BIRKDALE_PARS,
            ROYAL_BIRKDALE_HCS,
            ROYAL_BIRKDALE_TEES,
            country: "England",
            state: nil,
            architect: "Frederick G. Hawtree / J.H. Taylor",
            type: "Private",
            phone: "+44 (0) 1704 552020",
            address: "Waterloo Road, Southport, PR8 2LX, England, United Kingdom",
            isWolfApproved: true
        ),
        c(
            RENAISSANCE_CLUB_ID,
            "The Renaissance Club",
            RENAISSANCE_CLUB_PARS,
            RENAISSANCE_CLUB_HCS,
            RENAISSANCE_CLUB_TEES,
            country: "Scotland",
            state: nil,
            architect: "Tom Doak",
            type: "Private",
            address: "Archerfield Estate, Dirleton, North Berwick EH39 5HQ, Scotland, United Kingdom",
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
          country: "USA", state: "WV", architect: "Seth Raynor & Jack Nicklaus", type: "Resort",
          phone: "800-624-6070",
          website: "https://www.greenbrier.com",
          address: "101 Main St W, White Sulphur Springs, WV 24986"),

        c(CONWAY_FARMS_ID, "Conway Farms", CONWAY_FARMS_PARS, CONWAY_FARMS_HCS, CONWAY_FARMS_TEES,
          country: "USA",
          state: "IL",
          architect: "Tom Fazio",
          type: "Private",
          phone: "847-234-7160",
          website: "https://www.conwayfarmsgolfclub.org",
          address: "425 S. Conway Farms Drive, Lake Forest, IL 60045"),

        c(SPANISH_BAY_ID, "The Links at Spanish Bay", SPANISH_BAY_PARS, SPANISH_BAY_HCS, SPANISH_BAY_TEES,
          country: "USA",
          state: "CA",
          region: "NorCal",
          architect: "Robert Trent Jones Jr. / Tom Watson / Sandy Tatum",
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
            VICTORIA_NATIONAL_ID,
            "Victoria National Golf Club",
            VICTORIA_NATIONAL_PARS,
            VICTORIA_NATIONAL_HCS,
            VICTORIA_NATIONAL_TEES,
            country: "USA",
            state: "IN",
            region: "Newburgh",
            architect: "Tom Fazio",
            type: "Private",
            website: "https://www.victorianational.com",
            isWolfApproved: true,
            resortBrand: "Dormie Network"
        ),
        c(
            BRICKYARD_CROSSING_ID,
            "Brickyard Crossing Golf Course",
            BRICKYARD_CROSSING_PARS,
            BRICKYARD_CROSSING_HCS,
            BRICKYARD_CROSSING_TEES,
            country: "USA",
            state: "IN",
            region: "Indianapolis",
            architect: "Pete Dye",
            type: "Public",
            phone: "(317) 492-6417",
            website: "https://www.brickyardcrossing.com",
            address: "4400 W 16th St, Indianapolis, IN 46222",
            isWolfApproved: true
        ),
        c(
            PFAU_COURSE_IU_ID,
            "Pfau Course at Indiana University",
            PFAU_COURSE_IU_PARS,
            PFAU_COURSE_IU_HCS,
            PFAU_COURSE_IU_TEES,
            country: "USA",
            state: "IN",
            region: "Bloomington",
            architect: "Steve Smyers",
            type: "Public",
            phone: "(812) 855-7543",
            website: "https://www.iugolfcourse.com",
            address: "1492 Indiana 45 46 Bypass, Bloomington, IN 47408",
            isWolfApproved: true
        ),
        c(
            WARREN_GC_ND_ID,
            "Warren Golf Course at Notre Dame",
            WARREN_GC_ND_PARS,
            WARREN_GC_ND_HCS,
            WARREN_GC_ND_TEES,
            country: "USA",
            state: "IN",
            region: "South Bend",
            architect: "Bill Coore & Ben Crenshaw",
            type: "Public",
            phone: "(574) 631-4653",
            website: "https://www.nd.edu/golf",
            address: "Notre Dame, IN 46556",
            isWolfApproved: true
        ),
        c(
            HARRISON_LAKE_CC_ID,
            "Harrison Lake Country Club",
            HARRISON_LAKE_CC_PARS,
            HARRISON_LAKE_CC_HCS,
            HARRISON_LAKE_CC_TEES,
            country: "USA",
            state: "IN",
            region: "Columbus",
            architect: "Gary Kern",
            type: "Private",
            phone: "(812) 342-4457",
            website: "https://www.harrisonlakeclub.com",
            address: "588 S. Country Club Rd, Columbus, IN 47201"
        ),
        c(
            BRIAR_RIDGE_BW_ID,
            "Briar Ridge CC — Blue/White",
            BRIAR_RIDGE_BW_PARS,
            BRIAR_RIDGE_BW_HCS,
            BRIAR_RIDGE_BW_TEES,
            country: "USA",
            state: "IN",
            region: "Schererville",
            architect: "Dick Nugent & Larry Packard & Gary Roger Baird",
            type: "Private",
            phone: "(219) 322-3660",
            address: "123 Country Club Dr., Schererville, IN 46375"
        ),
        c(
            BRIAR_RIDGE_CC_ID,
            "Briar Ridge CC — Red/White",
            BRIAR_RIDGE_CC_PARS,
            BRIAR_RIDGE_CC_HCS,
            BRIAR_RIDGE_CC_TEES,
            country: "USA",
            state: "IN",
            region: "Schererville",
            architect: "Gary Roger Baird & Larry Packard",
            type: "Private",
            phone: "(219) 322-3660",
            address: "123 Country Club Dr., Schererville, IN 46375"
        ),
        c(
            BRIAR_RIDGE_RB_ID,
            "Briar Ridge CC — Red/Blue",
            BRIAR_RIDGE_RB_PARS,
            BRIAR_RIDGE_RB_HCS,
            BRIAR_RIDGE_RB_TEES,
            country: "USA",
            state: "IN",
            region: "Schererville",
            architect: "Dick Nugent & Gary Roger Baird",
            type: "Private",
            phone: "(219) 322-3660",
            address: "123 Country Club Dr., Schererville, IN 46375"
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
        c(DISMAL_RIVER_RED_ID, "Dismal River (Red)",
          DISMAL_RIVER_RED_PARS, DISMAL_RIVER_RED_HCS,
          DISMAL_RIVER_RED_TEES,
          country: "USA",
          state: "NE",
          architect: "Tom Fazio",
          type: "Resort",
          website: "https://www.dismalriver.com",
          address: "83040 Dismal River Trail, Mullen, NE 69152",
          isWolfApproved: true),

        c(DISMAL_RIVER_WHITE_ID, "Dismal River (White)",
          DISMAL_RIVER_WHITE_PARS, DISMAL_RIVER_WHITE_HCS,
          DISMAL_RIVER_WHITE_TEES,
          country: "USA",
          state: "NE",
          architect: "Jack Nicklaus",
          type: "Resort",
          website: "https://www.dismalriver.com",
          address: "83040 Dismal River Trail, Mullen, NE 69152",
          isWolfApproved: true),

        c(CAPROCK_RANCH_ID, "CapRock Ranch",
          CAPROCK_RANCH_PARS, CAPROCK_RANCH_HCS,
          CAPROCK_RANCH_TEES,
          country: "USA",
          state: "NE",
          architect: "Gil Hanse / Jim Wagner",
          type: "Private",
          phone: "(402) 470-8088",
          website: "https://www.caprockranch.com",
          address: "38248 Caprock Ln, Valentine, NE 69201",
          isWolfApproved: true),

        c(LANDMAND_GC_ID, "Landmand Golf Club",
          LANDMAND_GC_PARS, LANDMAND_GC_HCS,
          LANDMAND_GC_TEES,
          country: "USA",
          state: "NE",
          architect: "King-Collins Golf Course Design",
          type: "Private",
          phone: "(402) 508-2238",
          website: "https://www.landmandgc.com",
          address: "2073 S. Bluff Rd., Homer, NE 68030",
          isWolfApproved: true),

        c(SAND_HILLS_GC_ID, "Sand Hills Golf Club",
          SAND_HILLS_GC_PARS, SAND_HILLS_GC_HCS,
          SAND_HILLS_GC_TEES,
          country: "USA",
          state: "NE",
          architect: "Bill Coore & Ben Crenshaw",
          type: "Private",
          website: "https://www.sandhillsgolfclub.com",
          address: "Mullen, NE 68103",
          isWolfApproved: true),

        c(WILD_HORSE_GC_ID, "Wild Horse Golf Club",
          WILD_HORSE_GC_PARS, WILD_HORSE_GC_HCS,
          WILD_HORSE_GC_TEES,
          country: "USA",
          state: "NE",
          architect: "Dave Axland & Dan Proctor",
          type: "Daily-Fee",
          phone: "(308) 537-7700",
          website: "https://www.playwildhorse.com",
          address: "40950 Road 768, Gothenburg, NE 69138",
          isWolfApproved: true),

        c(GRAYBULL_ID, "GrayBull",
          GRAYBULL_PARS, GRAYBULL_HCS,
          GRAYBULL_TEES,
          country: "USA",
          state: "NE",
          architect: "David McLay Kidd",
          type: "Private",
          website: "https://www.dormienetwork.com/clubs/graybull/",
          address: "Nebraska Sandhills, NE",
          isWolfApproved: true),

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
            architect: "Tom Weiskopf & Jay Morrish",
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
            PRAIRIE_CLUB_DUNES_TEES,
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
            PRAIRIE_CLUB_PINES_ID,
            "The Prairie Club - Pines Course",
            PRAIRIE_CLUB_PINES_PARS,
            PRAIRIE_CLUB_PINES_HCS,
            PRAIRIE_CLUB_PINES_TEES,
            country: "USA",
            state: "NE",
            architect: "Graham Marsh",
            type: "Resort",
            phone: "(888) 402-1101",
            website: "https://theprairieclub.com/golf/pines-course/",
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
            architect: "Tom Fazio",
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
            architect: "Tom Fazio",
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
            DEACONS_LODGE_ID,
            "Deacon's Lodge",
            DEACONS_LODGE_PARS,
            DEACONS_LODGE_HCS,
            DEACONS_LODGE_TEES,
            country: "USA",
            state: "MN",
            region: "Breezy Point",
            architect: "Arnold Palmer",
            type: "Resort",
            phone: "218-562-6262",
            website: "https://www.deaconslodge.com",
            address: "9348 Arnold Palmer Drive, Breezy Point, MN 56472"
        ),
        c(
            WHITEBIRCH_GC_ID,
            "Whitebirch Golf Course",
            WHITEBIRCH_GC_PARS,
            WHITEBIRCH_GC_HCS,
            WHITEBIRCH_GC_TEES,
            country: "USA",
            state: "MN",
            region: "Breezy Point",
            architect: "Joel Goldstrand",
            type: "Resort",
            phone: "218-562-7177",
            website: "https://www.breezypointresort.com",
            address: "7891 Co Rd 11, Breezy Point, MN 56472"
        ),
        c(
            STONERIDGE_GC_MN_ID,
            "StoneRidge Golf Club",
            STONERIDGE_GC_MN_PARS,
            STONERIDGE_GC_MN_HCS,
            STONERIDGE_GC_MN_TEES,
            country: "USA",
            state: "MN",
            region: "Stillwater",
            architect: "Bobby Weed",
            type: "Semi-Private"
        ),
        c(
            WILDERNESS_FORTUNE_BAY_ID,
            "The Wilderness at Fortune Bay",
            WILDERNESS_FORTUNE_BAY_PARS,
            WILDERNESS_FORTUNE_BAY_HCS,
            WILDERNESS_FORTUNE_BAY_TEES,
            country: "USA",
            state: "MN",
            region: "Tower",
            architect: "Jeffrey Brauer",
            type: "Resort",
            phone: "800-922-4680",
            website: "https://www.golfthewilderness.com",
            address: "1450 Bois Forte Road, Tower, MN 55790"
        ),
        c(
            HAZELTINE_NATIONAL_ID,
            "Hazeltine National Golf Club",
            HAZELTINE_NATIONAL_PARS,
            HAZELTINE_NATIONAL_HCS,
            HAZELTINE_NATIONAL_TEES,
            country: "USA",
            state: "MN",
            region: "Chaska",
            architect: "Robert Trent Jones, Sr.",
            type: "Private",
            phone: "952-556-5400",
            website: "https://www.hazeltinenational.com",
            address: "1900 Hazeltine Blvd., Chaska, MN 55318"
        ),
        c(
            RICHTER_PARK_GOLF_COURSE_ID,
            "Richter Park Golf Course",
            RICHTER_PARK_GOLF_COURSE_PARS,
            RICHTER_PARK_GOLF_COURSE_HCS,
            RICHTER_PARK_GOLF_COURSE_TEES,
            country: "USA",
            state: "CT",
            architect: "Edward Ryder",
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
            architect: "Rees Jones",
            type: "Resort",
            phone: "(860) 312-3636",
            website: "https://www.lakeofisles.com",
            address: "1 Clubhouse Drive, North Stonington, CT 06359",
            isWolfApproved: true
        ),

        c(
            LAKE_OF_ISLES_SOUTH_ID,
            "Lake of Isles (South Course)",
            LAKE_OF_ISLES_SOUTH_PARS,
            LAKE_OF_ISLES_SOUTH_HCS,
            LAKE_OF_ISLES_SOUTH_TEES,
            country: "USA",
            state: "CT",
            architect: "Rees Jones",
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
            architect: "A.W. Tillinghast",
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
            architect: "Dick Wilson",
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
            architect: "Michael Hurdzan & Dana Fry",
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
            architect: "Clive Clark",
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
            architect: "Michael Hurdzan & Dana Fry",
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
            PGA_FRISCO_EAST_ID,
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
            architect: "Bill Coore & Ben Crenshaw",
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
            PORTO_CIMA_ID,
            "The Club at Porto Cima",
            PORTO_CIMA_PARS,
            PORTO_CIMA_HCS,
            PORTO_CIMA_TEES,
            country: "USA",
            state: "MO",
            region: "Lake of the Ozarks",
            architect: "Jack Nicklaus",
            type: "Private",
            website: "https://www.portocima.com",
            address: "Lake of the Ozarks, MO"
        ),
        c(
            BRANSON_HILLS_GC_ID,
            "Branson Hills Golf Club",
            BRANSON_HILLS_GC_PARS,
            BRANSON_HILLS_GC_HCS,
            BRANSON_HILLS_GC_TEES,
            country: "USA",
            state: "MO",
            region: "Branson",
            architect: "Chuck Smith",
            type: "Public",
            phone: "417-337-2963",
            website: "https://www.bransonhillsgolfclub.com",
            address: "100 North Payne Stewart Drive, Branson, MO 65616"
        ),
        c(
            OLD_KINDERHOOK_GC_ID,
            "Old Kinderhook Golf Club",
            OLD_KINDERHOOK_GC_PARS,
            OLD_KINDERHOOK_GC_HCS,
            OLD_KINDERHOOK_GC_TEES,
            country: "USA",
            state: "MO",
            region: "Lake of the Ozarks",
            architect: "Tom Weiskopf",
            type: "Semi-Private",
            address: "678 Old Kinderhook Dr, Camdenton, MO 65020"
        ),
        c(
            BELLERIVE_CC_ID,
            "Bellerive Country Club",
            BELLERIVE_CC_PARS,
            BELLERIVE_CC_HCS,
            BELLERIVE_CC_TEES,
            country: "USA",
            state: "MO",
            region: "St. Louis",
            architect: "Robert Trent Jones, Sr.",
            type: "Private",
            phone: "(314) 434-4400",
            address: "12925 Ladue Road, St. Louis, MO 63141"
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
            architect: "Ken Killian / Greg Martin (2012)",
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
            architect: "Ken Killian / Greg Martin (2012)",
            type: "Public",
            phone: "(630) 653-5800",
            website: "https://arrowheadgolfclub.org",
            address: "26W151 Butterfield Rd, Wheaton, IL 60189",
            isWolfApproved: true,
            resortBrand: nil,
            promo: nil
        ),
        c(
            RED_HAWK_RIDGE_ID,
            "Red Hawk Ridge Golf Course",
            RED_HAWK_RIDGE_PARS,
            RED_HAWK_RIDGE_HCS,
            country: "USA",
            state: "CO",
            region: "Denver",
            architect: "Jim Engh",
            type: "Public",
            phone: "(720) 733-3500",
            website: "https://www.redhawkridge.com",
            address: "2156 Red Hawk Ridge Dr, Castle Rock, CO 80109",
            isWolfApproved: true
        ),
        c(
            COMMONGROUND_GC_ID,
            "CommonGround Golf Course",
            COMMONGROUND_GC_PARS,
            COMMONGROUND_GC_HCS,
            country: "USA",
            state: "CO",
            region: "Denver",
            architect: "Tom Doak / Robert Trent Jones Jr.",
            type: "Public",
            phone: "(303) 340-1520",
            website: "https://www.commongroundgolf.com",
            address: "10300 E Golfers Way, Aurora, CO 80010",
            isWolfApproved: true
        ),
        c(
            GREEN_VALLEY_RANCH_GC_ID,
            "Green Valley Ranch Golf Club",
            GREEN_VALLEY_RANCH_GC_PARS,
            GREEN_VALLEY_RANCH_GC_HCS,
            country: "USA",
            state: "CO",
            region: "Denver",
            architect: "Pete Dye",
            type: "Public",
            phone: "(303) 371-3131",
            website: "https://www.greenvalleyranchgolf.com",
            address: "4900 Himalaya Rd, Denver, CO 80249",
            isWolfApproved: true
        ),
        c(
            TPC_COLORADO_ID,
            "TPC Colorado",
            TPC_COLORADO_PARS,
            TPC_COLORADO_HCS,
            country: "USA",
            state: "CO",
            region: "Denver",
            architect: "Arthur Schaupeter",
            type: "Public",
            website: "https://www.tpc.com/tpccolorado",
            address: "2375 TPC Parkway, Berthoud, CO 80513",
            isWolfApproved: true
        ),
        c(
            POLE_CREEK_MEADOW_RANCH_ID,
            "Pole Creek GC (Meadow/Ranch)",
            POLE_CREEK_MEADOW_RANCH_PARS,
            POLE_CREEK_MEADOW_RANCH_HCS,
            country: "USA",
            state: "CO",
            region: "Denver",
            architect: "Denis Griffiths",
            type: "Public",
            phone: "(970) 887-9195",
            website: "https://www.polecreekgolf.com",
            address: "6827 County Road 51, Tabernash, CO 80478",
            isWolfApproved: true
        ),
        c(
            POLE_CREEK_MEADOW_RIDGE_ID,
            "Pole Creek GC (Meadow/Ridge)",
            POLE_CREEK_MEADOW_RIDGE_PARS,
            POLE_CREEK_MEADOW_RIDGE_HCS,
            country: "USA",
            state: "CO",
            region: "Denver",
            architect: "Denis Griffiths",
            type: "Public",
            phone: "(970) 887-9195",
            website: "https://www.polecreekgolf.com",
            address: "6827 County Road 51, Tabernash, CO 80478",
            isWolfApproved: true
        ),
        c(
            POLE_CREEK_RANCH_RIDGE_ID,
            "Pole Creek GC (Ranch/Ridge)",
            POLE_CREEK_RANCH_RIDGE_PARS,
            POLE_CREEK_RANCH_RIDGE_HCS,
            country: "USA",
            state: "CO",
            region: "Denver",
            architect: "Denis Griffiths",
            type: "Public",
            phone: "(970) 887-9195",
            website: "https://www.polecreekgolf.com",
            address: "6827 County Road 51, Tabernash, CO 80478",
            isWolfApproved: true
        ),
        c(
            RIVERDALE_DUNES_ID,
            "Riverdale Golf Club (Dunes)",
            RIVERDALE_DUNES_PARS,
            RIVERDALE_DUNES_HCS,
            country: "USA",
            state: "CO",
            region: "Denver",
            architect: "Pete Dye & Perry Dye",
            type: "Public",
            phone: "(303) 659-4700",
            website: "https://www.riverdalegolf.com",
            address: "13300 Riverdale Rd, Brighton, CO 80602",
            isWolfApproved: true
        ),
        c(
            RIVERDALE_KNOLLS_ID,
            "Riverdale Golf Club (Knolls)",
            RIVERDALE_KNOLLS_PARS,
            RIVERDALE_KNOLLS_HCS,
            country: "USA",
            state: "CO",
            region: "Denver",
            architect: "Henry B. Hughes",
            type: "Public",
            phone: "(303) 659-4700",
            website: "https://www.riverdalegolf.com",
            address: "13300 Riverdale Rd, Brighton, CO 80602",
            isWolfApproved: true
        ),
        c(
            FOX_ACRES_GC_ID,
            "Golf Club at Fox Acres",
            FOX_ACRES_GC_PARS,
            FOX_ACRES_GC_HCS,
            country: "USA",
            state: "CO",
            region: "Denver",
            architect: "John Cochran",
            type: "Private",
            phone: "(970) 881-2574",
            website: "https://www.foxacres.com",
            address: "3350 Fox Acres Drive East, Red Feather Lakes, CO 80545",
            isWolfApproved: true
        ),
        c(
            CHERRY_HILLS_CC_ID,
            "Cherry Hills Country Club",
            CHERRY_HILLS_CC_PARS,
            CHERRY_HILLS_CC_HCS,
            country: "USA",
            state: "CO",
            region: "Denver",
            architect: "William Flynn / Tom Doak",
            type: "Private",
            phone: "(303) 350-5200",
            website: "https://www.cherryhillscc.com",
            address: "4125 S University Blvd, Cherry Hills Village, CO 80113",
            isWolfApproved: true
        ),
        c(
            SANCTUARY_GC_ID,
            "Sanctuary Golf Course",
            SANCTUARY_GC_PARS,
            SANCTUARY_GC_HCS,
            country: "USA",
            state: "CO",
            region: "Denver",
            architect: "Jim Engh",
            type: "Private",
            phone: "(303) 224-2860",
            website: "https://www.sanctuarygolfcourse.com",
            address: "7549 N Daniels Park Rd, Sedalia, CO 80135",
            isWolfApproved: true
        ),
        c(
            BROADMOOR_EAST_ID,
            "The Broadmoor (East Course)",
            BROADMOOR_EAST_PARS,
            BROADMOOR_EAST_HCS,
            country: "USA",
            state: "CO",
            region: "Colorado Springs",
            architect: "Donald Ross / Robert Trent Jones, Sr.",
            type: "Resort",
            phone: "(855) 634-7711",
            website: "https://www.broadmoor.com/golf",
            address: "1 Lake Ave, Colorado Springs, CO 80906",
            isWolfApproved: true
        ),
        c(
            BROADMOOR_WEST_ID,
            "The Broadmoor (West Course)",
            BROADMOOR_WEST_PARS,
            BROADMOOR_WEST_HCS,
            country: "USA",
            state: "CO",
            region: "Colorado Springs",
            architect: "Donald Ross / Robert Trent Jones, Sr.",
            type: "Resort",
            phone: "(855) 634-7711",
            website: "https://www.broadmoor.com/golf",
            address: "1 Lake Ave, Colorado Springs, CO 80906",
            isWolfApproved: true
        ),
        c(
            RAINDANCE_NATIONAL_ID,
            "RainDance National Golf Course",
            RAINDANCE_NATIONAL_PARS,
            RAINDANCE_NATIONAL_HCS,
            RAINDANCE_NATIONAL_TEES,
            country: "USA",
            state: "CO",
            region: "Denver",
            architect: "Todd Eckenrode",
            type: "Public",
            phone: "(970) 833-1720",
            website: "https://www.raindancenational.com",
            address: "1775 RainDance National Dr, Windsor, CO 80550",
            isWolfApproved: true
        ),
        c(
            BRECKENRIDGE_GC_ID,
            "Breckenridge Golf Club",
            BRECKENRIDGE_GC_PARS,
            BRECKENRIDGE_GC_HCS,
            BRECKENRIDGE_GC_TEES,
            country: "USA",
            state: "CO",
            region: "Denver",
            architect: "Jack Nicklaus",
            type: "Public",
            phone: "(970) 453-9104",
            website: "https://www.breckenridgegolfclub.com",
            address: "200 Clubhouse Drive, Breckenridge, CO 80424",
            isWolfApproved: true
        ),
        c(
            KEYSTONE_RANCH_ID,
            "Keystone Ranch Golf Course",
            KEYSTONE_RANCH_PARS,
            KEYSTONE_RANCH_HCS,
            KEYSTONE_RANCH_TEES,
            country: "USA",
            state: "CO",
            region: "Vail",
            architect: "Robert Trent Jones Jr.",
            type: "Resort",
            phone: "(970) 496-4250",
            website: "https://www.keystoneresort.com/golf",
            address: "1239 Keystone Ranch Rd, Keystone, CO 80435",
            isWolfApproved: true
        ),
        c(
            KEYSTONE_RIVER_ID,
            "River Course at Keystone",
            KEYSTONE_RIVER_PARS,
            KEYSTONE_RIVER_HCS,
            KEYSTONE_RIVER_TEES,
            country: "USA",
            state: "CO",
            region: "Vail",
            architect: "Michael Hurdzan & Dana Fry",
            type: "Resort",
            phone: "(970) 496-1520",
            website: "https://www.keystoneresort.com/golf",
            address: "155 River Course Dr, Keystone, CO 80435",
            isWolfApproved: true
        ),
        c(
            MURPHY_CREEK_GC_ID,
            "Murphy Creek Golf Course",
            MURPHY_CREEK_GC_PARS,
            MURPHY_CREEK_GC_HCS,
            MURPHY_CREEK_GC_TEES,
            country: "USA",
            state: "CO",
            region: "Denver",
            architect: "Ken Kavanaugh",
            type: "Public",
            phone: "(303) 739-1560",
            website: "https://www.murphycreekgolf.com",
            address: "1700 S Old Tom Morris Rd, Aurora, CO 80018",
            isWolfApproved: true
        ),
        c(
            WALNUT_CREEK_GC_ID,
            "Walnut Creek Golf Preserve",
            WALNUT_CREEK_GC_PARS,
            WALNUT_CREEK_GC_HCS,
            WALNUT_CREEK_GC_TEES,
            country: "USA",
            state: "CO",
            region: "Denver",
            architect: "Michael Hurdzan",
            type: "Public",
            website: "https://www.walnutcreekgolf.com",
            address: "10555 Westmoor Dr, Westminster, CO 80021",
            isWolfApproved: true
        ),
        c(
            HOKUL_IA_CLUB_ID,
            "The Club at Hokuli'a",
            HOKUL_IA_CLUB_PARS,
            HOKUL_IA_CLUB_HCS,
            HOKUL_IA_CLUB_TEES,
            country: "USA",
            state: "HI",
            region: "Big Island",
            architect: "Jack Nicklaus",
            type: "Private",
            phone: "(808) 324-1500",
            website: "https://www.hokulia.com",
            address: "81-6636 Pu'u Ohau Place, Kealakekua, HI 96750",
            isWolfApproved: true
        ),
        c(
            POIPU_BAY_GC_ID,
            "Poipu Bay Golf Course",
            POIPU_BAY_GC_PARS,
            POIPU_BAY_GC_HCS,
            POIPU_BAY_GC_TEES,
            country: "USA",
            state: "HI",
            region: "Kauai",
            architect: "Robert Trent Jones Jr.",
            type: "Resort",
            phone: "(808) 742-8711",
            address: "2250 Ainako St., Koloa, HI 96756"
        ),
        c(
            PRINCEVILLE_MAKAI_GC_ID,
            "Princeville Makai Golf Club",
            PRINCEVILLE_MAKAI_GC_PARS,
            PRINCEVILLE_MAKAI_GC_HCS,
            PRINCEVILLE_MAKAI_GC_TEES,
            country: "USA",
            state: "HI",
            region: "Kauai",
            architect: "Robert Trent Jones Jr.",
            type: "Resort",
            phone: "(808) 826-1912",
            address: "4080 Lei O Papa Rd, Princeville, HI 96722"
        ),
        c(
            SHOREHAVEN_GC_ID,
            "Shorehaven Golf Club",
            SHOREHAVEN_GC_PARS,
            SHOREHAVEN_GC_HCS,
            SHOREHAVEN_GC_TEES,
            country: "USA",
            state: "CT",
            architect: "Willie Park Jr. & Robert White",
            type: "Private",
            phone: "(203) 866-5528",
            website: "https://www.shorehaven.com",
            address: "East Norwalk, CT",
            isWolfApproved: true
        ),
        c(
            TASHUA_KNOLLS_CHAMPIONSHIP_ID,
            "Tashua Knolls (Championship)",
            TASHUA_KNOLLS_PARS,
            TASHUA_KNOLLS_HCS_CHAMPIONSHIP,
            [TeeInfo(teeName: "Championship", yardage: 6540, rating: 72.0, slope: 139)],
            country: "USA",
            state: "CT",
            region: "Trumbull",
            architect: "Al Zikorus (1976)",
            type: "Public",
            phone: "(203) 452-5186",
            website: "https://www.tashuaknolls.com",
            address: "40 Tashua Knolls Lane, Trumbull, CT 06611"
        ),
        c(
            TASHUA_KNOLLS_BACK_ID,
            "Tashua Knolls (Back)",
            TASHUA_KNOLLS_PARS,
            TASHUA_KNOLLS_HCS_BACK,
            [TeeInfo(teeName: "Back", yardage: 6119, rating: 70.3, slope: 137)],
            country: "USA",
            state: "CT",
            region: "Trumbull",
            architect: "Al Zikorus (1976)",
            type: "Public",
            phone: "(203) 452-5186",
            website: "https://www.tashuaknolls.com",
            address: "40 Tashua Knolls Lane, Trumbull, CT 06611"
        ),
        c(
            TASHUA_KNOLLS_MIDDLE_ID,
            "Tashua Knolls (Middle)",
            TASHUA_KNOLLS_PARS,
            TASHUA_KNOLLS_HCS_MIDDLE,
            [TeeInfo(teeName: "Middle", yardage: 5656, rating: 68.3, slope: 124)],
            country: "USA",
            state: "CT",
            region: "Trumbull",
            architect: "Al Zikorus (1976)",
            type: "Public",
            phone: "(203) 452-5186",
            website: "https://www.tashuaknolls.com",
            address: "40 Tashua Knolls Lane, Trumbull, CT 06611"
        ),
        c(
            TASHUA_KNOLLS_FORWARD_ID,
            "Tashua Knolls (Forward)",
            TASHUA_KNOLLS_PARS,
            TASHUA_KNOLLS_HCS_FORWARD,
            [TeeInfo(teeName: "Forward", yardage: 5050, rating: 65.8, slope: 108)],
            country: "USA",
            state: "CT",
            region: "Trumbull",
            architect: "Al Zikorus (1976)",
            type: "Public",
            phone: "(203) 452-5186",
            website: "https://www.tashuaknolls.com",
            address: "40 Tashua Knolls Lane, Trumbull, CT 06611"
        ),
        c(
            TASHUA_GLEN_ID,
            "Tashua Glen Golf Course",
            TASHUA_GLEN_PARS,
            TASHUA_GLEN_HCS,
            TASHUA_GLEN_TEES,
            country: "USA",
            state: "CT",
            region: "Trumbull",
            architect: "Michael Zikorus (2004)",
            type: "Public",
            phone: "(203) 452-5186",
            website: "https://www.tashuaknolls.com",
            address: "40 Tashua Knolls Lane, Trumbull, CT 06611",
            routing: .nineStandard
        ),
        c(
            CORDILLERA_VALLEY_ID,
            "Cordillera Valley Course",
            CORDILLERA_VALLEY_PARS,
            CORDILLERA_VALLEY_HCS,
            CORDILLERA_VALLEY_TEES,
            country: "USA",
            state: "CO",
            region: "Vail",
            architect: "Tom Fazio",
            type: "Private",
            phone: "(970) 926-5950",
            website: "https://www.cordillera-vail.com",
            address: "655 Clubhouse Drive, Edwards, CO 81632",
            isWolfApproved: true
        ),
        c(
            CORDILLERA_MOUNTAIN_ID,
            "Cordillera Mountain Course",
            CORDILLERA_MOUNTAIN_PARS,
            CORDILLERA_MOUNTAIN_HCS,
            CORDILLERA_MOUNTAIN_TEES,
            country: "USA",
            state: "CO",
            region: "Vail",
            architect: "Jack Nicklaus",
            type: "Private",
            phone: "(970) 926-5100",
            website: "https://www.cordillera-vail.com",
            address: "Edwards, CO 81632",
            isWolfApproved: true
        ),
        c(
            CORDILLERA_SUMMIT_ID,
            "Cordillera Summit Course",
            CORDILLERA_SUMMIT_PARS,
            CORDILLERA_SUMMIT_HCS,
            CORDILLERA_SUMMIT_TEES,
            country: "USA",
            state: "CO",
            region: "Vail",
            architect: "Tom Fazio",
            type: "Private",
            phone: "(970) 926-5300",
            website: "https://www.cordillera-vail.com",
            address: "Edwards, CO 81632",
            isWolfApproved: true
        ),
        c(
            FROST_CREEK_GC_ID,
            "Frost Creek",
            FROST_CREEK_GC_PARS,
            FROST_CREEK_GC_HCS,
            FROST_CREEK_GC_TEES,
            country: "USA",
            state: "CO",
            region: "Vail",
            architect: "Tom Weiskopf",
            type: "Private",
            phone: "(970) 328-2326",
            website: "https://www.frostcreek.com",
            address: "1094 Frost Creek Drive, Eagle, CO 81631",
            isWolfApproved: true
        ),
        c(
            RAVEN_THREE_PEAKS_ID,
            "Raven Golf Club at Three Peaks",
            RAVEN_THREE_PEAKS_PARS,
            RAVEN_THREE_PEAKS_HCS,
            RAVEN_THREE_PEAKS_TEES,
            country: "USA",
            state: "CO",
            region: "Denver",
            architect: "Michael Hurdzan & Dana Fry / Tom Lehman",
            type: "Semi-Private",
            phone: "(970) 262-3636",
            website: "https://www.raventhreepeaks.com",
            address: "2929 N Golden Eagle Rd, Silverthorne, CO 80498",
            isWolfApproved: true
        ),
        c(
            ROARING_FORK_CLUB_ID,
            "Roaring Fork Club",
            ROARING_FORK_CLUB_PARS,
            ROARING_FORK_CLUB_HCS,
            ROARING_FORK_CLUB_TEES,
            country: "USA",
            state: "CO",
            region: "Vail",
            architect: "Jack Nicklaus",
            type: "Private",
            phone: "(970) 927-9000",
            website: "https://www.roaringforkclub.com",
            address: "100 Arbaney Ranch Rd, Basalt, CO 81621",
            isWolfApproved: true
        ),
        c(
            RIO_SECCO_GC_ID,
            "Rio Secco Golf Club",
            RIO_SECCO_GC_PARS,
            RIO_SECCO_GC_HCS,
            RIO_SECCO_GC_TEES,
            country: "USA",
            state: "NV",
            region: "Las Vegas",
            architect: "Rees Jones",
            type: "Daily-Fee",
            phone: "(702) 777-2400",
            website: "https://www.riosecco.com",
            address: "2851 Grand Hills Dr, Henderson, NV 89052",
            isWolfApproved: true
        ),
        c(
            PAIUTE_SNOW_MOUNTAIN_ID,
            "Las Vegas Paiute Golf Resort (Snow Mountain)",
            PAIUTE_SNOW_MOUNTAIN_PARS,
            PAIUTE_SNOW_MOUNTAIN_HCS,
            PAIUTE_SNOW_MOUNTAIN_TEES,
            country: "USA",
            state: "NV",
            region: "Las Vegas",
            architect: "Pete Dye",
            type: "Resort",
            phone: "(702) 658-1400",
            website: "https://www.lvpaiutegolf.com",
            address: "10325 Nu-Wav Kaiv Blvd, Las Vegas, NV 89124",
            isWolfApproved: true
        ),
        c(
            PAIUTE_SUN_MOUNTAIN_ID,
            "Las Vegas Paiute Golf Resort (Sun Mountain)",
            PAIUTE_SUN_MOUNTAIN_PARS,
            PAIUTE_SUN_MOUNTAIN_HCS,
            PAIUTE_SUN_MOUNTAIN_TEES,
            country: "USA",
            state: "NV",
            region: "Las Vegas",
            architect: "Pete Dye",
            type: "Resort",
            phone: "(702) 658-1400",
            website: "https://www.lvpaiutegolf.com",
            address: "10325 Nu-Wav Kaiv Blvd, Las Vegas, NV 89124",
            isWolfApproved: true
        ),
        c(
            CHIMERA_GC_ID,
            "Chimera Golf Club",
            CHIMERA_GC_PARS,
            CHIMERA_GC_HCS,
            CHIMERA_GC_TEES,
            country: "USA",
            state: "NV",
            region: "Las Vegas",
            architect: "Ted Robinson Jr.",
            type: "Daily-Fee",
            phone: "(702) 951-1500",
            website: "https://www.chimeragolfclub.com",
            address: "901 Olivia Pkwy, Henderson, NV 89011",
            isWolfApproved: true
        ),
        c(
            ARROYO_RED_ROCK_ID,
            "Arroyo Golf Club",
            ARROYO_RED_ROCK_PARS,
            ARROYO_RED_ROCK_HCS,
            ARROYO_RED_ROCK_TEES,
            country: "USA",
            state: "NV",
            region: "Las Vegas",
            architect: "Arnold Palmer",
            type: "Daily-Fee",
            phone: "(702) 258-2300",
            website: "https://www.redrockcanyonlv.org/golf/arroyo-golf-club",
            address: "2250 Red Springs Dr, Las Vegas, NV 89135",
            isWolfApproved: true
        ),
        c(
            BOULDER_CREEK_GC_ID,
            "Boulder Creek Golf Club",
            BOULDER_CREEK_GC_PARS,
            BOULDER_CREEK_GC_HCS,
            BOULDER_CREEK_GC_TEES,
            country: "USA",
            state: "NV",
            region: "Las Vegas",
            architect: "Mark Rathert",
            type: "Daily-Fee",
            phone: "(702) 294-6534",
            website: "https://www.golfbouldercity.com",
            address: "1501 Veterans Memorial Dr, Boulder City, NV 89005",
            isWolfApproved: true
        ),
        c(
            ANGEL_PARK_MOUNTAIN_ID,
            "Angel Park Golf Club (Mountain)",
            ANGEL_PARK_MOUNTAIN_PARS,
            ANGEL_PARK_MOUNTAIN_HCS,
            ANGEL_PARK_MOUNTAIN_TEES,
            country: "USA",
            state: "NV",
            region: "Las Vegas",
            architect: "Arnold Palmer / Ed Seay",
            type: "Daily-Fee",
            phone: "(702) 254-4653",
            website: "https://www.angelpark.com",
            address: "100 S Rampart Blvd, Las Vegas, NV 89145",
            isWolfApproved: true
        ),
        c(
            SOUTHSHORE_CC_ID,
            "SouthShore Country Club",
            SOUTHSHORE_CC_PARS,
            SOUTHSHORE_CC_HCS,
            SOUTHSHORE_CC_TEES,
            country: "USA",
            state: "NV",
            region: "Las Vegas",
            architect: "Jack Nicklaus",
            type: "Private",
            phone: "(702) 558-0021",
            website: "https://www.southshorecountryclub.com",
            address: "1 SouthShore Dr, Henderson, NV 89052",
            isWolfApproved: true
        ),
        c(
            DESERT_SPRINGS_PALMS_ID,
            "Desert Springs Golf Course (Palms)",
            DESERT_SPRINGS_PALMS_PARS,
            DESERT_SPRINGS_PALMS_HCS,
            DESERT_SPRINGS_PALMS_TEES,
            country: "USA",
            state: "CA",
            region: "Palm Desert",
            architect: "Ted Robinson Sr.",
            type: "Resort",
            phone: "(760) 341-1756",
            website: "https://www.marriott.com",
            address: "74855 Country Club Dr, Palm Desert, CA 92260",
            isWolfApproved: true
        ),
        c(
            RHODES_RANCH_GC_ID,
            "Rhodes Ranch Golf Club",
            RHODES_RANCH_GC_PARS,
            RHODES_RANCH_GC_HCS,
            RHODES_RANCH_GC_TEES,
            country: "USA",
            state: "NV",
            region: "Las Vegas",
            architect: "Ted Robinson Sr.",
            type: "Daily-Fee",
            phone: "(702) 740-4114",
            website: "https://www.rhodesranch.com",
            address: "20 Rhodes Ranch Pkwy, Las Vegas, NV 89148",
            isWolfApproved: true
        ),
        c(
            DESERT_PINES_GC_ID,
            "Desert Pines Golf Club",
            DESERT_PINES_GC_PARS,
            DESERT_PINES_GC_HCS,
            DESERT_PINES_GC_TEES,
            country: "USA",
            state: "NV",
            region: "Las Vegas",
            architect: "Dye Designs International",
            type: "Daily-Fee",
            phone: "(702) 450-8000",
            website: "https://www.desertpinesgolfclub.com",
            address: "3415 E Bonanza Rd, Las Vegas, NV 89101",
            isWolfApproved: true
        ),
        c(
            COYOTE_SPRINGS_GC_ID,
            "Coyote Springs Golf Club",
            COYOTE_SPRINGS_GC_PARS,
            COYOTE_SPRINGS_GC_HCS,
            COYOTE_SPRINGS_GC_TEES,
            country: "USA",
            state: "NV",
            region: "Las Vegas",
            architect: "Jack Nicklaus",
            type: "Resort",
            phone: "(877) 634-8438",
            website: "https://www.coyotesprings.com",
            address: "3100 State Route 168, Coyote Springs, NV 89037",
            isWolfApproved: true
        ),
        c(
            WOLF_CREEK_GC_ID,
            "Wolf Creek Golf Club",
            WOLF_CREEK_GC_PARS,
            WOLF_CREEK_GC_HCS,
            WOLF_CREEK_GC_TEES,
            country: "USA",
            state: "NV",
            region: "Mesquite",
            architect: "Dennis Rider",
            type: "Resort",
            phone: "(702) 346-1670",
            website: "https://www.golfwolfcreek.com",
            address: "403 Paradise Pkwy, Mesquite, NV 89027",
            isWolfApproved: true
        ),
        c(
            SAND_HOLLOW_CHAMPIONSHIP_ID,
            "Sand Hollow Resort (Championship)",
            SAND_HOLLOW_CHAMPIONSHIP_PARS,
            SAND_HOLLOW_CHAMPIONSHIP_HCS,
            SAND_HOLLOW_CHAMPIONSHIP_TEES,
            country: "USA",
            state: "UT",
            region: "St. George",
            architect: "John Fought",
            type: "Resort",
            phone: "(435) 656-4653",
            website: "https://www.sandhollowresort.com",
            address: "5662 W Clubhouse Dr, Hurricane, UT 84737",
            isWolfApproved: true
        ),
        c(
            CONESTOGA_GC_ID,
            "Conestoga Golf Club",
            CONESTOGA_GC_PARS,
            CONESTOGA_GC_HCS,
            CONESTOGA_GC_TEES,
            country: "USA",
            state: "NV",
            region: "Mesquite",
            architect: "Gary Panks",
            type: "Resort",
            phone: "(702) 346-4292",
            website: "https://www.conestogagolf.com",
            address: "1499 Falcon Ridge Pkwy, Mesquite, NV 89034",
            isWolfApproved: true
        ),
        c(
            FALCON_RIDGE_GC_ID,
            "Falcon Ridge Golf Course",
            FALCON_RIDGE_GC_PARS,
            FALCON_RIDGE_GC_HCS,
            FALCON_RIDGE_GC_TEES,
            country: "USA",
            state: "NV",
            region: "Mesquite",
            architect: "Kelby Hughes",
            type: "Daily-Fee",
            phone: "(702) 346-6363",
            website: "https://www.golffalcon.com",
            address: "1024 Normandy Ln, Mesquite, NV 89027",
            isWolfApproved: true
        ),
        c(
            SUMMIT_CLUB_ID,
            "Summit Club",
            SUMMIT_CLUB_PARS,
            SUMMIT_CLUB_HCS,
            SUMMIT_CLUB_TEES,
            country: "USA",
            state: "NV",
            region: "Las Vegas",
            architect: "Tom Fazio",
            type: "Private",
            phone: "(702) 970-2150",
            website: "https://www.thesummitclub.com",
            address: "11660 Summit Club Dr, Las Vegas, NV 89135",
            isWolfApproved: true
        ),
        c(
            REYNOLDS_PRESERVE_ID,
            "The Preserve at Reynolds Lake Oconee",
            REYNOLDS_PRESERVE_PARS,
            REYNOLDS_PRESERVE_HCS,
            REYNOLDS_PRESERVE_TEES,
            country: "USA",
            state: "GA",
            region: "Lake Oconee",
            architect: "Bob Cupp",
            type: "Private",
            phone: "(706) 467-1111",
            website: "https://www.reynoldslakeoconee.com",
            address: "100 Linger Longer Rd, Greensboro, GA 30642",
            isWolfApproved: true
        ),
        c(
            REYNOLDS_GREAT_WATERS_ID,
            "Reynolds Lake Oconee - Great Waters",
            REYNOLDS_GREAT_WATERS_PARS,
            REYNOLDS_GREAT_WATERS_HCS,
            REYNOLDS_GREAT_WATERS_TEES,
            country: "USA",
            state: "GA",
            region: "Lake Oconee",
            architect: "Jack Nicklaus",
            type: "Private",
            phone: "(706) 467-1111",
            website: "https://www.reynoldslakeoconee.com",
            address: "100 Linger Longer Rd, Greensboro, GA 30642",
            isWolfApproved: true
        ),
        c(
            REYNOLDS_NATIONAL_ID,
            "The National at Reynolds Lake Oconee - Ridge/Bluff",
            REYNOLDS_NATIONAL_PARS,
            REYNOLDS_NATIONAL_HCS,
            REYNOLDS_NATIONAL_TEES,
            country: "USA",
            state: "GA",
            region: "Lake Oconee",
            architect: "Tom Fazio",
            type: "Private",
            phone: "(706) 467-1111",
            website: "https://www.reynoldslakeoconee.com",
            address: "100 Linger Longer Rd, Greensboro, GA 30642",
            isWolfApproved: true
        ),
        c(
            REYNOLDS_OCONEE_ID,
            "The Oconee at Reynolds",
            REYNOLDS_OCONEE_PARS,
            REYNOLDS_OCONEE_HCS,
            REYNOLDS_OCONEE_TEES,
            country: "USA",
            state: "GA",
            region: "Lake Oconee",
            architect: "Rees Jones",
            type: "Private",
            phone: "(706) 467-1111",
            website: "https://www.reynoldslakeoconee.com",
            address: "100 Linger Longer Rd, Greensboro, GA 30642",
            isWolfApproved: true
        ),
        c(
            REYNOLDS_CREEK_CLUB_ID,
            "The Creek Club at Reynolds Lake Oconee",
            REYNOLDS_CREEK_CLUB_PARS,
            REYNOLDS_CREEK_CLUB_HCS,
            REYNOLDS_CREEK_CLUB_TEES,
            country: "USA",
            state: "GA",
            region: "Lake Oconee",
            architect: "Jim Engh",
            type: "Private",
            phone: "(706) 467-1111",
            website: "https://www.reynoldslakeoconee.com",
            address: "100 Linger Longer Rd, Greensboro, GA 30642",
            isWolfApproved: true
        ),
        c(
            REYNOLDS_LANDING_ID,
            "The Landing at Reynolds Lake Oconee",
            REYNOLDS_LANDING_PARS,
            REYNOLDS_LANDING_HCS,
            REYNOLDS_LANDING_TEES,
            country: "USA",
            state: "GA",
            region: "Lake Oconee",
            architect: "Bob Cupp",
            type: "Semi-Private",
            phone: "(706) 467-1111",
            website: "https://www.reynoldslakeoconee.com",
            address: "100 Linger Longer Rd, Greensboro, GA 30642",
            isWolfApproved: true
        ),
        c(
            STONE_MOUNTAIN_STONEMONT_ID,
            "Stone Mountain Golf Club (Stonemont)",
            STONE_MOUNTAIN_STONEMONT_PARS,
            STONE_MOUNTAIN_STONEMONT_HCS,
            STONE_MOUNTAIN_STONEMONT_TEES,
            country: "USA",
            state: "GA",
            region: "Stone Mountain",
            architect: "Robert Trent Jones, Sr.",
            type: "Private",
            isWolfApproved: true
        ),
        c(
            STONE_MOUNTAIN_LAKEMONT_ID,
            "Stone Mountain Golf Club (Lakemont)",
            STONE_MOUNTAIN_LAKEMONT_PARS,
            STONE_MOUNTAIN_LAKEMONT_HCS,
            STONE_MOUNTAIN_LAKEMONT_TEES,
            country: "USA",
            state: "GA",
            region: "Stone Mountain",
            architect: "John LaFoy",
            type: "Private",
            isWolfApproved: true
        ),
        c(
            THE_FROG_GC_ID,
            "The Frog Golf Club",
            THE_FROG_GC_PARS,
            THE_FROG_GC_HCS,
            THE_FROG_GC_TEES,
            country: "USA",
            state: "GA",
            region: "Villa Rica",
            architect: "Tom Fazio",
            type: "Public",
            phone: "(770) 459-4400",
            website: "https://thefroggolfclub.com",
            isWolfApproved: true
        ),
        c(
            BRASSTOWN_VALLEY_ID,
            "Brasstown Valley Resort",
            BRASSTOWN_VALLEY_PARS,
            BRASSTOWN_VALLEY_HCS,
            BRASSTOWN_VALLEY_TEES,
            country: "USA",
            state: "GA",
            region: "Young Harris",
            architect: "Denis Griffiths",
            type: "Resort",
            phone: "(706) 379-9900",
            website: "https://brasstownvalley.com",
            isWolfApproved: true
        ),
        c(
            CURRAHEE_CLUB_ID,
            "Currahee Club",
            CURRAHEE_CLUB_PARS,
            CURRAHEE_CLUB_HCS,
            CURRAHEE_CLUB_TEES,
            country: "USA",
            state: "GA",
            region: "Toccoa",
            architect: "Tom Fazio",
            type: "Private",
            isWolfApproved: true
        ),
        c(
            BLACK_CREEK_GC_GA_ID,
            "Black Creek Golf Club",
            BLACK_CREEK_GC_GA_PARS,
            BLACK_CREEK_GC_GA_HCS,
            BLACK_CREEK_GC_GA_TEES,
            country: "USA",
            state: "GA",
            region: "Savannah",
            architect: "Jim Bevins",
            type: "Semi-Private",
            phone: "912-858-4653",
            address: "277 Canterwood Drive, Ellabell, GA 31308"
        ),
        c(
            LOOKOUT_MOUNTAIN_GC_ID,
            "Lookout Mountain Golf Club",
            LOOKOUT_MOUNTAIN_GC_PARS,
            LOOKOUT_MOUNTAIN_GC_HCS,
            LOOKOUT_MOUNTAIN_GC_TEES,
            country: "USA",
            state: "GA",
            region: "Chattanooga",
            architect: "Seth Raynor",
            type: "Private",
            phone: "(706) 820-1551",
            address: "1201 Fleetwood Drive, Lookout Mountain, GA 30750"
        ),
        c(
            BLESSINGS_GC_ID,
            "Blessings Golf Club",
            BLESSINGS_GC_PARS,
            BLESSINGS_GC_HCS,
            BLESSINGS_GC_TEES,
            country: "USA",
            state: "AR",
            region: "Fayetteville",
            architect: "Robert Trent Jones Jr.",
            type: "Private",
            address: "Fayetteville, AR 72701"
        ),
        c(
            ALOTIAN_CLUB_ID,
            "The Alotian Club",
            ALOTIAN_CLUB_PARS,
            ALOTIAN_CLUB_HCS,
            ALOTIAN_CLUB_TEES,
            country: "USA",
            state: "AR",
            region: "Little Rock",
            architect: "Tom Fazio",
            type: "Private",
            address: "101 Alotian Dr, Roland, AR 72135"
        ),
        c(
            CASTLE_PINES_GC_ID,
            "Castle Pines Golf Club",
            CASTLE_PINES_GC_PARS,
            CASTLE_PINES_GC_HCS,
            country: "USA",
            state: "CO",
            region: "Denver",
            architect: "Jack Nicklaus",
            type: "Private",
            phone: "(303) 688-6000",
            website: "https://www.castlepinesgc.com",
            address: "1000 Hummingbird Dr, Castle Rock, CO 80108",
            isWolfApproved: true
        ),
        c(
            LAKOTA_CANYON_GC_ID,
            "Lakota Canyon Ranch Golf Club",
            LAKOTA_CANYON_GC_PARS,
            LAKOTA_CANYON_GC_HCS,
            country: "USA",
            state: "CO",
            region: "Denver",
            architect: "Jim Engh",
            type: "Public",
            phone: "(970) 984-9700",
            website: "https://www.lakotacanyonranch.com",
            address: "151 Clubhouse Dr, New Castle, CO 81647",
            isWolfApproved: true
        ),
        c(
            REDLANDS_MESA_GC_ID,
            "Redlands Mesa Golf Club",
            REDLANDS_MESA_GC_PARS,
            REDLANDS_MESA_GC_HCS,
            country: "USA",
            state: "CO",
            region: "Denver",
            architect: "Jim Engh",
            type: "Public",
            phone: "(970) 263-9270",
            website: "https://www.redlandsmesa.com",
            address: "2325 W Ridges Blvd, Grand Junction, CO 81503",
            isWolfApproved: true
        ),
        c(
            BALLYNEAL_GC_ID,
            "Ballyneal Golf Club",
            BALLYNEAL_GC_PARS,
            BALLYNEAL_GC_HCS,
            country: "USA",
            state: "CO",
            region: "Denver",
            architect: "Tom Fazio",
            type: "Private",
            phone: "(970) 854-5900",
            website: "https://www.ballyneal.com",
            address: "Holyoke, CO 80734",
            isWolfApproved: true
        ),
        c(
            RED_SKY_FAZIO_ID,
            "Red Sky Golf Club (Fazio Course)",
            RED_SKY_FAZIO_PARS,
            RED_SKY_FAZIO_HCS,
            country: "USA",
            state: "CO",
            region: "Vail",
            architect: "Tom Fazio",
            type: "Private",
            phone: "(970) 754-8400",
            website: "https://www.redskygolfclub.com",
            address: "376 Red Sky Rd, Wolcott, CO 81655",
            isWolfApproved: true
        ),
        c(
            RED_SKY_NORMAN_ID,
            "Red Sky Golf Club (Norman Course)",
            RED_SKY_NORMAN_PARS,
            RED_SKY_NORMAN_HCS,
            country: "USA",
            state: "CO",
            region: "Vail",
            architect: "Greg Norman",
            type: "Private",
            phone: "(970) 754-8400",
            website: "https://www.redskygolfclub.com",
            address: "376 Red Sky Rd, Wolcott, CO 81655",
            isWolfApproved: true
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
            architect: "Billy Casper & Greg Nash",
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
            architect: "Billy Casper & Greg Nash",
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
            BALTUSROL_LOWER_ID,
            "Baltusrol (Lower Course)",
            BALTUSROL_LOWER_PARS,
            BALTUSROL_LOWER_HCS,
            BALTUSROL_LOWER_TEES,
            country: "USA",
            state: "NJ",
            region: "Springfield",
            architect: "A.W. Tillinghast",
            type: "Private",
            phone: "(973) 376-1900",
            address: "201 Shunpike Road, Springfield, NJ 07081"
        ),
        c(
            BALTUSROL_UPPER_ID,
            "Baltusrol (Upper Course)",
            BALTUSROL_UPPER_PARS,
            BALTUSROL_UPPER_HCS,
            BALTUSROL_UPPER_TEES,
            country: "USA",
            state: "NJ",
            region: "Springfield",
            architect: "A.W. Tillinghast",
            type: "Private",
            phone: "(973) 376-1900",
            address: "201 Shunpike Road, Springfield, NJ 07081"
        ),
        c(
            PLAINFIELD_CC_CHAMPIONSHIP_ID,
            "Plainfield Country Club",
            PLAINFIELD_CC_CHAMPIONSHIP_PARS,
            PLAINFIELD_CC_CHAMPIONSHIP_HCS,
            PLAINFIELD_CC_TEES,
            country: "USA",
            state: "NJ",
            region: "Edison",
            architect: "Donald Ross / Gil Hanse",
            type: "Private",
            phone: "(908) 757-1800",
            address: "1591 Woodland Ave, Edison, NJ 08820"
        ),
        c(
            LIBERTY_NATIONAL_GC_ID,
            "Liberty National Golf Club",
            LIBERTY_NATIONAL_GC_PARS,
            LIBERTY_NATIONAL_GC_HCS,
            LIBERTY_NATIONAL_GC_TEES,
            country: "USA",
            state: "NJ",
            region: "Jersey City",
            architect: "Tom Kite / Bob Cupp",
            type: "Private",
            phone: "(201) 333-4105",
            address: "100 Caven Point Road, Jersey City, NJ 07305"
        ),
        c(
            RIDGEWOOD_CC_ID,
            "Ridgewood Country Club",
            RIDGEWOOD_CC_PARS,
            RIDGEWOOD_CC_HCS,
            RIDGEWOOD_CC_TEES,
            country: "USA",
            state: "NJ",
            region: "Paramus",
            architect: "A.W. Tillinghast",
            type: "Private",
            phone: "(201) 599-3900",
            address: "96 W Midland Avenue, Paramus, NJ 07652"
        ),
        c(
            BULLE_ROCK_GC_ID,
            "Bulle Rock Golf Club",
            BULLE_ROCK_GC_PARS,
            BULLE_ROCK_GC_HCS,
            BULLE_ROCK_GC_TEES,
            country: "USA",
            state: "MD",
            region: "Baltimore",
            architect: "Pete Dye",
            type: "Public",
            phone: "(410) 939-8887",
            address: "320 Blenheim Lane, Havre de Grace, MD 21078"
        ),
        c(
            WORTHINGTON_MANOR_GC_ID,
            "Worthington Manor Golf Club",
            WORTHINGTON_MANOR_GC_PARS,
            WORTHINGTON_MANOR_GC_HCS,
            WORTHINGTON_MANOR_GC_TEES,
            country: "USA",
            state: "MD",
            region: "Washington DC",
            architect: "Ault, Clark & Associates",
            type: "Public",
            phone: "(301) 874-5400",
            address: "Dickerson, MD 20842"
        ),
        c(
            TRUMP_NATIONAL_HUDSON_VALLEY_ID,
            "Trump National Golf Club (Hudson Valley)",
            TRUMP_NATIONAL_HUDSON_VALLEY_PARS,
            TRUMP_NATIONAL_HUDSON_VALLEY_HCS,
            TRUMP_NATIONAL_HUDSON_VALLEY_TEES,
            country: "USA",
            state: "NY",
            architect: "Jim Fazio",
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
            WILDHORSE_GC_DAVIS_ID,
            "Wildhorse Golf Course",
            WILDHORSE_GC_DAVIS_PARS,
            WILDHORSE_GC_DAVIS_HCS,
            WILDHORSE_GC_DAVIS_TEES,
            country: "USA",
            state: "CA",
            region: "Sacramento",
            architect: "Jeffrey Brauer",
            type: "Daily-Fee"
        ),
        c(
            RUSTIC_CANYON_ID,
            "Rustic Canyon Golf Course",
            RUSTIC_CANYON_PARS,
            RUSTIC_CANYON_HCS,
            RUSTIC_CANYON_TEES,
            country: "USA",
            state: "CA",
            region: "SoCal",
            architect: "Gil Hanse / Geoff Shackelford / Jim Wagner",
            type: "Daily-Fee",
            phone: "(805) 530-0221",
            website: "https://www.rusticcanyongolfcourse.com",
            address: "15100 Happy Camp Canyon Rd, Moorpark, CA 93021",
            isWolfApproved: true
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
            NC_CROOKED_TREE_ID,
            "Crooked Tree Golf Course",
            NC_CROOKED_TREE_PARS,
            NC_CROOKED_TREE_HCS,
            NC_CROOKED_TREE_TEES,
            country: "USA",
            state: "NC",
            region: "Greensboro",
            architect: "Tommy Pegram",
            type: "Daily-Fee",
            phone: "(336) 656-3211",
            website: "https://www.crookedtreegolfcourse.com",
            address: "7665 Caber Rd, Browns Summit, NC 27214",
            isWolfApproved: true
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
            FISHERS_ISLAND_CLUB_ID,
            "Fishers Island Club",
            FISHERS_ISLAND_CLUB_PARS,
            FISHERS_ISLAND_CLUB_HCS,
            FISHERS_ISLAND_CLUB_TEES,
            country: "USA",
            state: "NY",
            region: "Long Island",
            architect: "Seth Raynor",
            type: "Private",
            phone: "+1 631 788 7223",
            website: "https://www.ficlub.net",
            address: "Fishers Island, NY 06390"
        ),
        c(
            FRIARS_HEAD_ID,
            "Friar's Head",
            FRIARS_HEAD_PARS,
            FRIARS_HEAD_HCS,
            FRIARS_HEAD_TEES,
            country: "USA",
            state: "NY",
            region: "Long Island",
            architect: "Bill Coore & Ben Crenshaw",
            type: "Private",
            phone: "(631) 722-6010",
            address: "3000 Sound Avenue, Riverhead, NY 11901"
        ),
        c(
            WINGED_FOOT_EAST_ID,
            "Winged Foot Golf Club — East",
            WINGED_FOOT_EAST_PARS,
            WINGED_FOOT_EAST_HCS,
            WINGED_FOOT_EAST_TEES,
            country: "USA",
            state: "NY",
            region: "Westchester",
            architect: "A.W. Tillinghast",
            type: "Private",
            phone: "(914) 698-8400",
            address: "851 Fenimore Rd, Mamaroneck, NY 10543"
        ),
        c(
            WINGED_FOOT_WEST_ID,
            "Winged Foot Golf Club — West",
            WINGED_FOOT_WEST_PARS,
            WINGED_FOOT_WEST_HCS,
            WINGED_FOOT_WEST_TEES,
            country: "USA",
            state: "NY",
            region: "Westchester",
            architect: "A.W. Tillinghast",
            type: "Private",
            phone: "(914) 698-8400",
            address: "851 Fenimore Rd, Mamaroneck, NY 10543"
        ),
        c(
            SHINNECOCK_HILLS_ID,
            "Shinnecock Hills Golf Club",
            SHINNECOCK_HILLS_PARS,
            SHINNECOCK_HILLS_HCS,
            SHINNECOCK_HILLS_TEES,
            country: "USA",
            state: "NY",
            region: "Long Island",
            architect: "William S. Flynn",
            type: "Private",
            phone: "(631) 283-1310",
            address: "200 Tuckahoe Road, Southampton, NY 11968"
        ),
        c(
            NGLA_ID,
            "National Golf Links of America",
            NGLA_PARS,
            NGLA_HCS,
            NGLA_TEES,
            country: "USA",
            state: "NY",
            region: "Long Island",
            architect: "Charles Blair Macdonald",
            type: "Private",
            phone: "(631) 283-0410",
            website: "https://www.ngla.us",
            address: "Sebonac Inlet Road, Southampton, NY 11968"
        ),
        c(
            OAK_HILL_EAST_ID,
            "Oak Hill Country Club (East Course)",
            OAK_HILL_EAST_PARS,
            OAK_HILL_EAST_HCS,
            OAK_HILL_EAST_TEES,
            country: "USA",
            state: "NY",
            region: "Upstate NY",
            architect: "Donald Ross",
            type: "Private",
            phone: "(585) 586-1660",
            address: "145 Kilbourn Road, Rochester, NY 14618",
            isWolfApproved: true
        ),
        c(
            GARDEN_CITY_GC_ID,
            "Garden City Golf Club",
            GARDEN_CITY_GC_PARS,
            GARDEN_CITY_GC_HCS,
            GARDEN_CITY_GC_TEES,
            country: "USA",
            state: "NY",
            region: "Long Island",
            architect: "Devereux Emmet",
            type: "Private",
            phone: "(516) 747-2880",
            website: "https://www.gardencitygolfclub.com",
            address: "315 Stewart Avenue, Garden City, NY 11530"
        ),
        c(
            SLEEPY_HOLLOW_UPPER_ID,
            "Sleepy Hollow Country Club (Upper Course)",
            SLEEPY_HOLLOW_UPPER_PARS,
            SLEEPY_HOLLOW_UPPER_HCS,
            SLEEPY_HOLLOW_UPPER_TEES,
            country: "USA",
            state: "NY",
            region: "Westchester",
            architect: "C.B. Macdonald / Seth Raynor",
            type: "Private",
            phone: "+1 914 941 8070",
            website: "https://www.sleepyhollowcc.org",
            address: "777 Albany Post Road, Scarborough, NY 10510"
        ),
        c(
            SLEEPY_HOLLOW_LOWER_ID,
            "Sleepy Hollow Country Club (Lower Course)",
            SLEEPY_HOLLOW_LOWER_PARS,
            SLEEPY_HOLLOW_LOWER_HCS,
            SLEEPY_HOLLOW_LOWER_TEES,
            country: "USA",
            state: "NY",
            region: "Westchester",
            architect: "C.B. Macdonald / Seth Raynor",
            type: "Private",
            phone: "+1 914 941 8070",
            website: "https://www.sleepyhollowcc.org",
            address: "777 Albany Post Road, Scarborough, NY 10510"
        ),
        c(
            THE_CREEK_CLUB_ID,
            "The Creek Club",
            THE_CREEK_CLUB_PARS,
            THE_CREEK_CLUB_HCS,
            THE_CREEK_CLUB_TEES,
            country: "USA",
            state: "NY",
            region: "Long Island",
            architect: "Charles Blair Macdonald / Seth Raynor",
            type: "Private",
            phone: "(516) 676-1405",
            website: "https://www.creek.net",
            address: "1 Horse Hollow Road, Locust Valley, NY 11560"
        ),
        c(
            SEBONACK_GC_ID,
            "Sebonack Golf Club",
            SEBONACK_GC_PARS,
            SEBONACK_GC_HCS,
            SEBONACK_GC_TEES,
            country: "USA",
            state: "NY",
            region: "Long Island",
            architect: "Jack Nicklaus / Tom Doak",
            type: "Private",
            website: "https://www.sebonack.com",
            address: "405 Sebonac Road, Southampton, NY 11968",
            isWolfApproved: true
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
            architect: "Arnold Palmer",
            type: "Resort",
            phone: "(407) 996-1559",
            website: "https://www.shinglecreekgolf.com",
            address: "9939 Universal Blvd, Orlando, FL 32819",
            isWolfApproved: true,
            resortBrand: "Omni",
        ),
        c(
            KAROO_STREAMSONG_ID,
            "KAROO at Streamsong",
            KAROO_STREAMSONG_PARS,
            KAROO_STREAMSONG_HCS,
            KAROO_STREAMSONG_TEES,
            country: "USA",
            state: "FL",
            region: "Tampa Bay",
            architect: "Bill Coore & Ben Crenshaw",
            type: "Resort",
            address: "Brooksville, FL 34601",
            resortBrand: "Streamsong"
        ),
        c(
            TIBURON_BLACK_ID,
            "Tiburón Golf Club (Black Course)",
            TIBURON_BLACK_PARS,
            TIBURON_BLACK_HCS,
            TIBURON_BLACK_TEES,
            country: "USA",
            state: "FL",
            region: "Naples",
            architect: "Greg Norman",
            type: "Private",
            phone: "(239) 593-2200",
            address: "2620 Tiburón Dr, Naples, FL 34109"
        ),
        c(
            TIBURON_GOLD_ID,
            "Tiburón Golf Club (Gold Course)",
            TIBURON_GOLD_PARS,
            TIBURON_GOLD_HCS,
            TIBURON_GOLD_TEES,
            country: "USA",
            state: "FL",
            region: "Naples",
            architect: "Greg Norman",
            type: "Private",
            phone: "(239) 593-2200",
            address: "2620 Tiburón Dr, Naples, FL 34109"
        ),
        c(
            NAPLES_BEACH_CLUB_ID,
            "Naples Beach Club",
            NAPLES_BEACH_CLUB_PARS,
            NAPLES_BEACH_CLUB_HCS,
            NAPLES_BEACH_CLUB_TEES,
            country: "USA",
            state: "FL",
            region: "Naples",
            architect: "Hart Howerton",
            type: "Resort",
            phone: "(239) 944-7600",
            address: "801 Gulf Shore Blvd N, Naples, FL 34102",
            resortBrand: "Four Seasons"
        ),
        c(
            LELY_MUSTANG_ID,
            "Lely Resort (Mustang Course)",
            LELY_MUSTANG_PARS,
            LELY_MUSTANG_HCS,
            LELY_MUSTANG_TEES,
            country: "USA",
            state: "FL",
            region: "Naples",
            architect: "Lee Trevino",
            type: "Public",
            phone: "(239) 793-2600",
            address: "8004 Lely Resort Blvd, Naples, FL 34113"
        ),
        c(
            LELY_FLAMINGO_ID,
            "Lely Resort (Flamingo Island Course)",
            LELY_FLAMINGO_PARS,
            LELY_FLAMINGO_HCS,
            LELY_FLAMINGO_TEES,
            country: "USA",
            state: "FL",
            region: "Naples",
            architect: "Robert Trent Jones, Sr.",
            type: "Public",
            phone: "(239) 793-2600",
            address: "8004 Lely Resort Blvd, Naples, FL 34113"
        ),
        c(
            LELY_CLASSICS_ID,
            "Lely Resort (Classics Course)",
            LELY_CLASSICS_PARS,
            LELY_CLASSICS_HCS,
            LELY_CLASSICS_TEES,
            country: "USA",
            state: "FL",
            region: "Naples",
            architect: "Gary Player",
            type: "Private",
            phone: "(239) 732-1220",
            address: "7989 Grand Lely Dr, Naples, FL 34113"
        ),
        c(
            KING_BEAR_WGV_ID,
            "King & Bear (World Golf Village)",
            KING_BEAR_WGV_PARS,
            KING_BEAR_WGV_HCS,
            KING_BEAR_WGV_TEES,
            country: "USA",
            state: "FL",
            region: "Jacksonville",
            architect: "Arnold Palmer & Jack Nicklaus",
            type: "Public",
            website: "https://www.golfwgv.com",
            address: "World Golf Village, St. Augustine, FL 32092"
        ),
        c(
            SLAMMER_SQUIRE_WGV_ID,
            "Slammer & Squire (World Golf Village)",
            SLAMMER_SQUIRE_WGV_PARS,
            SLAMMER_SQUIRE_WGV_HCS,
            SLAMMER_SQUIRE_WGV_TEES,
            country: "USA",
            state: "FL",
            region: "Jacksonville",
            architect: "Sam Snead & Gene Sarazen",
            type: "Public",
            website: "https://www.golfwgv.com",
            address: "World Golf Village, St. Augustine, FL 32092"
        ),
        c(
            CRANDON_KEY_BISCAYNE_ID,
            "Crandon Golf at Key Biscayne",
            CRANDON_KEY_BISCAYNE_PARS,
            CRANDON_KEY_BISCAYNE_HCS,
            CRANDON_KEY_BISCAYNE_TEES,
            country: "USA",
            state: "FL",
            region: "Miami",
            architect: "Bruce Devlin & Robert Von Hagge",
            type: "Public",
            phone: "(305) 361-9129",
            website: "https://www.golfcrandon.com",
            address: "6700 Crandon Blvd, Key Biscayne, FL 33149"
        ),
        c(
            TRUMP_DORAL_RED_TIGER_ID,
            "Trump National Doral (Red Tiger)",
            TRUMP_DORAL_RED_TIGER_PARS,
            TRUMP_DORAL_RED_TIGER_HCS,
            TRUMP_DORAL_RED_TIGER_TEES,
            country: "USA",
            state: "FL",
            region: "Miami",
            architect: "Dick Wilson & Gil Hanse",
            type: "Resort",
            phone: "(305) 592-2000",
            website: "https://www.trumphotels.com/miami/golf",
            address: "4400 NW 87th Ave, Miami, FL 33178"
        ),
        c(
            TRUMP_DORAL_SILVER_FOX_ID,
            "Trump National Doral (Silver Fox)",
            TRUMP_DORAL_SILVER_FOX_PARS,
            TRUMP_DORAL_SILVER_FOX_HCS,
            TRUMP_DORAL_SILVER_FOX_TEES,
            country: "USA",
            state: "FL",
            region: "Miami",
            architect: "Robert Von Hagge",
            type: "Resort",
            phone: "(305) 592-2000",
            website: "https://www.trumphotels.com/miami/golf",
            address: "4400 NW 87th Ave, Miami, FL 33178"
        ),
        c(
            TRUMP_DORAL_GOLDEN_PALM_ID,
            "Trump National Doral (Golden Palm)",
            TRUMP_DORAL_GOLDEN_PALM_PARS,
            TRUMP_DORAL_GOLDEN_PALM_HCS,
            TRUMP_DORAL_GOLDEN_PALM_TEES,
            country: "USA",
            state: "FL",
            region: "Miami",
            architect: "Robert Von Hagge & Bruce Devlin",
            type: "Resort",
            phone: "(305) 592-2000",
            website: "https://www.trumphotels.com/miami/golf",
            address: "4400 NW 87th Ave, Miami, FL 33178"
        ),
        c(
            RITZ_CARLTON_ORLANDO_ID,
            "Ritz-Carlton Golf Club Orlando",
            RITZ_CARLTON_ORLANDO_PARS,
            RITZ_CARLTON_ORLANDO_HCS,
            RITZ_CARLTON_ORLANDO_TEES,
            country: "USA",
            state: "FL",
            region: "Orlando",
            architect: "Greg Norman",
            type: "Resort",
            phone: "(407) 393-4200",
            address: "4012 Central Florida Pkwy, Orlando, FL 32837",
            resortBrand: "Ritz-Carlton"
        ),
        c(
            DISNEY_MAGNOLIA_ID,
            "Disney's Magnolia Golf Course",
            DISNEY_MAGNOLIA_PARS,
            DISNEY_MAGNOLIA_HCS,
            DISNEY_MAGNOLIA_TEES,
            country: "USA",
            state: "FL",
            region: "Orlando",
            architect: "Joe Lee & Ken Baker",
            type: "Resort",
            phone: "(407) 939-4653",
            website: "https://www.golfwdw.com",
            address: "1950 W Magnolia-Palm Dr, Lake Buena Vista, FL 32830",
            resortBrand: "Disney"
        ),
        c(
            DISNEY_PALM_ID,
            "Disney's Palm Golf Course",
            DISNEY_PALM_PARS,
            DISNEY_PALM_HCS,
            DISNEY_PALM_TEES,
            country: "USA",
            state: "FL",
            region: "Orlando",
            architect: "Joe Lee",
            type: "Resort",
            phone: "(407) 939-4653",
            website: "https://www.golfwdw.com",
            address: "1950 W Magnolia-Palm Dr, Lake Buena Vista, FL 32830",
            resortBrand: "Disney"
        ),
        c(
            DISNEY_OSPREY_RIDGE_ID,
            "Disney's Osprey Ridge Golf Course",
            DISNEY_OSPREY_RIDGE_PARS,
            DISNEY_OSPREY_RIDGE_HCS,
            DISNEY_OSPREY_RIDGE_TEES,
            country: "USA",
            state: "FL",
            region: "Orlando",
            architect: "Tom Fazio",
            type: "Resort",
            phone: "(407) 939-4653",
            website: "https://www.golfwdw.com",
            address: "3451 Golf View Blvd, Lake Buena Vista, FL 32830",
            resortBrand: "Disney"
        ),
        c(
            WALDORF_ASTORIA_ORLANDO_ID,
            "Waldorf Astoria Golf Club",
            WALDORF_ASTORIA_ORLANDO_PARS,
            WALDORF_ASTORIA_ORLANDO_HCS,
            WALDORF_ASTORIA_ORLANDO_TEES,
            country: "USA",
            state: "FL",
            region: "Orlando",
            architect: "Rees Jones",
            type: "Resort",
            phone: "(407) 597-3780",
            website: "https://www.waldorfastoriaorlando.com",
            address: "14224 Bonnet Creek Resort Ln, Orlando, FL 32821",
            resortBrand: "Waldorf Astoria"
        ),
        c(
            TPC_SAN_ANTONIO_CANYONS_ID,
            "TPC San Antonio (AT&T Canyons Course)",
            TPC_SAN_ANTONIO_CANYONS_PARS,
            TPC_SAN_ANTONIO_CANYONS_HCS,
            TPC_SAN_ANTONIO_CANYONS_TEES,
            country: "USA",
            state: "TX",
            region: "San Antonio",
            architect: "Pete Dye",
            type: "Private",
            website: "https://www.tpc.com/tpcsanantonio",
            address: "23808 Resort Pkwy, San Antonio, TX 78261"
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
            architect: "Tom Weiskopf & Jay Morrish",
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
            architect: "Bill Coore & Ben Crenshaw",
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
            LOST_DUNES_ID,
            "Lost Dunes Golf Club",
            LOST_DUNES_PARS,
            LOST_DUNES_HCS,
            LOST_DUNES_TEES,
            country: "USA",
            state: "MI",
            architect: "Tom Doak",
            type: "Private",
            phone: "(269) 465-9300",
            website: "https://www.lostdunes.com",
            address: "9300 Red Arrow Highway, Bridgman, MI 49106",
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
            KESWICK_CLUB_ID,
            "Keswick Club",
            KESWICK_CLUB_PARS,
            KESWICK_CLUB_HCS,
            KESWICK_CLUB_TEES,
            country: "USA",
            state: "VA",
            region: "Charlottesville",
            architect: "Pete Dye",
            type: "Resort",
            address: "701 Club Dr, Keswick, VA 22947"
        ),
        c(
            SPRING_CREEK_GC_VA_ID,
            "Spring Creek Golf Club",
            SPRING_CREEK_GC_VA_PARS,
            SPRING_CREEK_GC_VA_HCS,
            SPRING_CREEK_GC_VA_TEES,
            country: "USA",
            state: "VA",
            region: "Charlottesville",
            architect: "Ed Carton",
            type: "Private",
            phone: "540-832-0744",
            website: "https://www.springcreekgolfclub.com",
            address: "109 Clubhouse Way, Zion Crossroads, VA 22942"
        ),
        c(
            KINLOCH_GC_ID,
            "Kinloch Golf Club",
            KINLOCH_GC_PARS,
            KINLOCH_GC_HCS,
            KINLOCH_GC_TEES,
            country: "USA",
            state: "VA",
            region: "Richmond",
            architect: "Lester George",
            type: "Private",
            address: "100 Kinloch Dr, Manakin-Sabot, VA 23103"
        ),
        c(
            BALLYHACK_GC_ID,
            "Ballyhack Golf Club",
            BALLYHACK_GC_PARS,
            BALLYHACK_GC_HCS,
            BALLYHACK_GC_TEES,
            country: "USA",
            state: "VA",
            region: "Roanoke",
            architect: "Lester George",
            type: "Private",
            website: "https://www.dormienetwork.com/clubs/ballyhack"
        ),
        c(
            CYPRESS_POINT_VA_BLUE_ID,
            "Cypress Point CC (Blue)",
            CYPRESS_POINT_VA_BLUE_PARS,
            CYPRESS_POINT_VA_BLUE_HCS,
            CYPRESS_POINT_VA_TEES,
            country: "USA",
            state: "VA",
            region: "Virginia Beach",
            architect: "Alister MacKenzie",
            type: "Private",
            address: "5340 Club Head Road, Virginia Beach, VA 23455"
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
            BAY_HARBOR_LQ_ID,
            "Bay Harbor Golf Club (Links / Quarry)",
            BAY_HARBOR_LQ_PARS,
            BAY_HARBOR_LQ_HCS,
            BAY_HARBOR_LQ_TEES,
            country: "USA",
            state: "MI",
            region: "Northern Michigan",
            architect: "Arthur Hills",
            type: "Resort",
            website: "https://www.bayharborgolf.com",
            address: "4096 Main St, Bay Harbor, MI 49770",
            isWolfApproved: true,
            resortBrand: "Boyne Golf"
        ),
        c(
            BAY_HARBOR_LP_ID,
            "Bay Harbor Golf Club (Links / Preserve)",
            BAY_HARBOR_LP_PARS,
            BAY_HARBOR_LP_HCS,
            BAY_HARBOR_LP_TEES,
            country: "USA",
            state: "MI",
            region: "Northern Michigan",
            architect: "Arthur Hills",
            type: "Resort",
            website: "https://www.bayharborgolf.com",
            address: "4096 Main St, Bay Harbor, MI 49770",
            isWolfApproved: true,
            resortBrand: "Boyne Golf"
        ),
        c(
            BAY_HARBOR_QP_ID,
            "Bay Harbor Golf Club (Quarry / Preserve)",
            BAY_HARBOR_QP_PARS,
            BAY_HARBOR_QP_HCS,
            BAY_HARBOR_QP_TEES,
            country: "USA",
            state: "MI",
            region: "Northern Michigan",
            architect: "Arthur Hills",
            type: "Resort",
            website: "https://www.bayharborgolf.com",
            address: "4096 Main St, Bay Harbor, MI 49770",
            isWolfApproved: true,
            resortBrand: "Boyne Golf"
        ),
        c(
            THE_HEATHER_ID,
            "The Heather at Boyne Highlands",
            THE_HEATHER_PARS,
            THE_HEATHER_HCS,
            THE_HEATHER_TEES,
            country: "USA",
            state: "MI",
            region: "Northern Michigan",
            architect: "Robert Trent Jones, Sr.",
            type: "Resort",
            phone: "(231) 526-3029",
            website: "https://www.boynehighlands.com",
            address: "250 Heather Drive, Harbor Springs, MI 49740",
            isWolfApproved: true,
            resortBrand: "Boyne Highlands"
        ),
        c(
            ARTHUR_HILLS_BH_ID,
            "Arthur Hills at Boyne Highlands",
            ARTHUR_HILLS_BH_PARS,
            ARTHUR_HILLS_BH_HCS,
            ARTHUR_HILLS_BH_TEES,
            country: "USA",
            state: "MI",
            region: "Northern Michigan",
            architect: "Arthur Hills",
            type: "Resort",
            website: "https://www.boynehighlands.com",
            address: "250 Heather Drive, Harbor Springs, MI 49740",
            isWolfApproved: true,
            resortBrand: "Boyne Highlands"
        ),
        c(
            THE_MOOR_ID,
            "The Moor at Boyne Highlands",
            THE_MOOR_PARS,
            THE_MOOR_HCS,
            THE_MOOR_TEES,
            country: "USA",
            state: "MI",
            region: "Northern Michigan",
            architect: "Arthur Hills",
            type: "Resort",
            website: "https://www.boynehighlands.com",
            address: "250 Heather Drive, Harbor Springs, MI 49740",
            isWolfApproved: true,
            resortBrand: "Boyne Highlands"
        ),
        c(
            CROOKED_TREE_GC_ID,
            "Crooked Tree Golf Club",
            CROOKED_TREE_GC_PARS,
            CROOKED_TREE_GC_HCS,
            CROOKED_TREE_GC_TEES,
            country: "USA",
            state: "MI",
            region: "Northern Michigan",
            architect: "Harry Bowers / Arthur Hills",
            type: "Resort",
            phone: "(231) 439-4030",
            website: "https://www.crookedtreegolfclub.com",
            address: "600 Crooked Tree Dr, Petoskey, MI 49770",
            isWolfApproved: true,
            resortBrand: "Boyne Golf"
        ),
        c(
            TRUE_NORTH_GC_ID,
            "True North Golf Club",
            TRUE_NORTH_GC_PARS,
            TRUE_NORTH_GC_HCS,
            TRUE_NORTH_GC_TEES,
            country: "USA",
            state: "MI",
            region: "Northern Michigan",
            architect: "Jim Engh",
            type: "Private",
            website: "https://www.truenorthgolfclub.com",
            address: "2500 True North Dr, Harbor Springs, MI 49740",
            isWolfApproved: true
        ),
        c(
            TULLYMORE_GC_ID,
            "Tullymore Golf Club",
            TULLYMORE_GC_PARS,
            TULLYMORE_GC_HCS,
            TULLYMORE_GC_TEES,
            country: "USA",
            state: "MI",
            region: "West Michigan",
            architect: "Jim Engh",
            type: "Resort",
            website: "https://www.tullymore.com",
            address: "11969 Tullymore Dr, Stanwood, MI 49346",
            isWolfApproved: true
        ),
        c(
            PILGRIMS_RUN_GC_ID,
            "Pilgrim's Run Golf Club",
            PILGRIMS_RUN_GC_PARS,
            PILGRIMS_RUN_GC_HCS,
            PILGRIMS_RUN_GC_TEES,
            country: "USA",
            state: "MI",
            region: "West Michigan",
            architect: "Mike DeVries & Kris Shumacker",
            type: "Public",
            website: "https://www.pilgrimsrun.com",
            isWolfApproved: true
        ),
        c(
            EAGLE_EYE_GC_ID,
            "Eagle Eye Golf Club",
            EAGLE_EYE_GC_PARS,
            EAGLE_EYE_GC_HCS,
            EAGLE_EYE_GC_TEES,
            country: "USA",
            state: "MI",
            region: "Mid-Michigan",
            architect: "Chris Lutzke",
            type: "Daily-Fee",
            phone: "(517) 903-8064",
            website: "https://www.eagleeyegolf.com",
            address: "15500 Chandler Rd, Bath Township, MI 48808",
            isWolfApproved: true
        ),
        c(
            GREYWALLS_GC_ID,
            "Greywalls Golf Course",
            GREYWALLS_GC_PARS,
            GREYWALLS_GC_HCS,
            GREYWALLS_GC_TEES,
            country: "USA",
            state: "MI",
            region: "Upper Peninsula",
            architect: "Mike DeVries",
            type: "Public",
            phone: "(906) 225-0721",
            website: "https://www.greywallsgolf.com",
            address: "1075 Grove St, Marquette, MI 49855",
            isWolfApproved: true,
            resortBrand: "Marquette Golf Club"
        ),
        c(
            HARBOR_SHORES_GC_ID,
            "Harbor Shores Resort",
            HARBOR_SHORES_GC_PARS,
            HARBOR_SHORES_GC_HCS,
            HARBOR_SHORES_GC_TEES,
            country: "USA",
            state: "MI",
            region: "Southwest Michigan",
            architect: "Jack Nicklaus",
            type: "Resort",
            phone: "(269) 927-4653",
            website: "https://www.harborshoresresort.com",
            address: "201 Graham Ave, Benton Harbor, MI 49022",
            isWolfApproved: true
        ),
        c(
            STOATIN_BRAE_GC_ID,
            "Stoatin Brae Golf Club",
            STOATIN_BRAE_GC_PARS,
            STOATIN_BRAE_GC_HCS,
            STOATIN_BRAE_GC_TEES,
            country: "USA",
            state: "MI",
            region: "Southwest Michigan",
            architect: "Tom Fazio",
            type: "Public",
            phone: "(269) 220-3976",
            website: "https://www.stoatinbrae.com",
            address: "15579 E Augusta Dr, Augusta, MI 49012",
            isWolfApproved: true,
            resortBrand: "Gull Lake View Resort"
        ),
        c(
            GULL_LAKE_VIEW_EAST_ID,
            "Gull Lake View East Course",
            GULL_LAKE_VIEW_EAST_PARS,
            GULL_LAKE_VIEW_EAST_HCS,
            GULL_LAKE_VIEW_EAST_TEES,
            country: "USA",
            state: "MI",
            region: "Southwest Michigan",
            architect: "Jerry Matthews",
            type: "Resort",
            phone: "(269) 731-4149",
            website: "https://www.gulllakeview.com",
            address: "7417 N 38th St, Augusta, MI 49012",
            isWolfApproved: true,
            resortBrand: "Gull Lake View Resort"
        ),
        c(
            LAWSONIA_LINKS_ID,
            "Lawsonia Links",
            LAWSONIA_LINKS_PARS,
            LAWSONIA_LINKS_HCS,
            LAWSONIA_LINKS_TEES,
            country: "USA",
            state: "WI",
            architect: "William Langford & Theodore Moreau",
            type: "Public",
            phone: "(920) 294-3320",
            website: "https://www.lawsonia.com/",
            address: "W2615 S Valley View Dr, Green Lake, WI 54941",
            isWolfApproved: true,
            resortBrand: nil,
            promo: nil
        ),
        c(
            SENTRYWORLD_ID,
            "SentryWorld",
            SENTRYWORLD_PARS,
            SENTRYWORLD_HCS,
            SENTRYWORLD_TEES,
            country: "USA",
            state: "WI",
            region: "Central Wisconsin",
            architect: "Robert Trent Jones Jr.",
            type: "Public",
            phone: "866-479-6753",
            website: "https://www.sentryworld.com",
            address: "601 Michigan Ave. N., Stevens Point, WI 54481"
        ),
        c(
            BLUE_MOUND_GCC_ID,
            "Blue Mound Golf & Country Club",
            BLUE_MOUND_GCC_PARS,
            BLUE_MOUND_GCC_HCS,
            BLUE_MOUND_GCC_TEES,
            country: "USA",
            state: "WI",
            region: "Milwaukee",
            architect: "Seth Raynor",
            type: "Private",
            phone: "+1 414 258 4656",
            website: "https://www.bluemoundgcc.com",
            address: "Wauwatosa, WI 53205"
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
            architect: "Hugh Moore",
            type: "Private",
            phone: "(334) 792-6650",
            website: "https://www.dothancountryclub.com/",
            address: "200 South Cherokee Avenue, Dothan, AL 36301",
            isWolfApproved: true,
            resortBrand: nil,
            promo: nil
        ),
        c(
            SWEETENS_COVE_GC_ID,
            "Sweetens Cove Golf Club",
            SWEETENS_COVE_GC_PARS,
            SWEETENS_COVE_GC_HCS,
            SWEETENS_COVE_GC_TEES,
            country: "USA",
            state: "TN",
            region: "Southeast Tennessee",
            architect: "King-Collins Golf Course Design",
            type: "Daily-Fee",
            address: "2040 Sweetens Cove Road, South Pittsburg, TN 37380"
        ),
        c(
            HONORS_COURSE_ID,
            "The Honors Course",
            HONORS_COURSE_PARS,
            HONORS_COURSE_HCS,
            HONORS_COURSE_TEES,
            country: "USA",
            state: "TN",
            region: "Chattanooga",
            architect: "Pete Dye",
            type: "Private",
            phone: "fax 423-238-5284",
            address: "Ooltewah, TN 37363"
        ),
        c(
            HERMITAGE_PR_ID,
            "Hermitage Golf Course (President's Reserve)",
            HERMITAGE_PR_PARS,
            HERMITAGE_PR_HCS,
            HERMITAGE_PR_TEES,
            country: "USA",
            state: "TN",
            region: "Nashville",
            architect: "Denis Griffiths",
            type: "Daily-Fee",
            phone: "615.847.4001",
            address: "3939 Old Hickory Boulevard, Old Hickory, TN 37138"
        ),
        c(
            GAYLORD_SPRINGS_ID,
            "Gaylord Springs Golf Links",
            GAYLORD_SPRINGS_PARS,
            GAYLORD_SPRINGS_HCS,
            GAYLORD_SPRINGS_TEES,
            country: "USA",
            state: "TN",
            region: "Nashville",
            architect: "Larry Nelson",
            type: "Resort",
            phone: "(615) 458-1730",
            address: "18 Springhouse Ln, Nashville, TN 37214"
        ),
        c(
            TENNESSEE_NATIONAL_ID,
            "Tennessee National",
            TENNESSEE_NATIONAL_PARS,
            TENNESSEE_NATIONAL_HCS,
            TENNESSEE_NATIONAL_TEES,
            country: "USA",
            state: "TN",
            region: "Knoxville",
            architect: "Greg Norman",
            type: "Semi-Private",
            phone: "(865) 408-9992",
            address: "Loudon, TN 37774"
        ),
        c(
            KNOLLWOOD_CLUB_ID,
            "Knollwood Club",
            KNOLLWOOD_CLUB_PARS,
            KNOLLWOOD_CLUB_HCS,
            KNOLLWOOD_CLUB_TEES,
            country: "USA",
            state: "IL",
            region: "Chicago North Shore",
            architect: "H.S. Colt / C.H. Alison",
            type: "Private",
            phone: "(847) 234-1600",
            website: "https://www.knollwoodclub.org",
            address: "1890 Knollwood Rd, Lake Forest, IL 60045",
            isWolfApproved: true
        ),
        c(
            BOB_OLINK_ID,
            "Bob O'Link Golf Club",
            BOB_OLINK_PARS,
            BOB_OLINK_HCS,
            BOB_OLINK_TEES,
            country: "USA",
            state: "IL",
            region: "Chicago North Shore",
            architect: "Donald Ross / C.H. Alison",
            type: "Private",
            phone: "(847) 432-0917",
            website: "https://www.bobolinkgolfclub.com",
            address: "408 Skokie Blvd, Highland Park, IL 60035",
            isWolfApproved: true
        ),
        c(
            SHOREACRES_ID,
            "Shoreacres",
            SHOREACRES_PARS,
            SHOREACRES_HCS,
            SHOREACRES_TEES,
            country: "USA",
            state: "IL",
            region: "Chicago North Shore",
            architect: "Seth Raynor",
            type: "Private",
            phone: "(847) 234-1470",
            website: "https://www.shoreacres.com",
            address: "1601 Shoreacres Rd, Lake Bluff, IL 60044",
            isWolfApproved: true
        ),
        c(
            EXMOOR_CC_ID,
            "Exmoor Country Club",
            EXMOOR_CC_PARS,
            EXMOOR_CC_HCS,
            EXMOOR_CC_TEES,
            country: "USA",
            state: "IL",
            region: "Chicago North Shore",
            architect: "Donald Ross",
            type: "Private",
            phone: "(847) 432-3600",
            website: "https://www.exmoorcountryclub.org",
            address: "700 Vine Ave, Highland Park, IL 60035",
            isWolfApproved: true
        ),
        
        c(
            CANTIGNY_WOODSIDE_LAKESIDE_ID,
            "Cantigny (Woodside / Lakeside)",
            CANTIGNY_WOODSIDE_LAKESIDE_PARS,
            CANTIGNY_WOODSIDE_LAKESIDE_HCS,
            CANTIGNY_WOODSIDE_LAKESIDE_TEES,
            country: "USA",
            state: "IL",
            region: "Chicago West",
            architect: "Roger Packard",
            type: "Daily-Fee",
            phone: "(630) 668-8463",
            website: "https://cantignygolf.com",
            address: "27W270 Mack Rd, Wheaton, IL 60189",
            isWolfApproved: true,
            resortBrand: "Cantigny"
        ),

        c(
            CANTIGNY_WOODSIDE_HILLSIDE_ID,
            "Cantigny (Woodside / Hillside)",
            CANTIGNY_WOODSIDE_HILLSIDE_PARS,
            CANTIGNY_WOODSIDE_HILLSIDE_HCS,
            CANTIGNY_WOODSIDE_HILLSIDE_TEES,
            country: "USA",
            state: "IL",
            region: "Chicago West",
            architect: "Roger Packard",
            type: "Daily-Fee",
            phone: "(630) 668-8463",
            website: "https://cantignygolf.com",
            address: "27W270 Mack Rd, Wheaton, IL 60189",
            isWolfApproved: true,
            resortBrand: "Cantigny"
        ),

        c(
            CANTIGNY_LAKESIDE_HILLSIDE_ID,
            "Cantigny (Lakeside / Hillside)",
            CANTIGNY_LAKESIDE_HILLSIDE_PARS,
            CANTIGNY_LAKESIDE_HILLSIDE_HCS,
            CANTIGNY_LAKESIDE_HILLSIDE_TEES,
            country: "USA",
            state: "IL",
            region: "Chicago West",
            architect: "Roger Packard",
            type: "Daily-Fee",
            phone: "(630) 668-8463",
            website: "https://cantignygolf.com",
            address: "27W270 Mack Rd, Wheaton, IL 60189",
            isWolfApproved: true,
            resortBrand: "Cantigny"
        ),
        
        c(
            CHICAGO_GC_ID,
            "Chicago Golf Club",
            CHICAGO_GC_PARS,
            CHICAGO_GC_HCS,
            CHICAGO_GC_TEES,
            country: "USA",
            state: "IL",
            region: "Chicago West",
            architect: "C.B. Macdonald (1895) / Seth Raynor (1923)",
            type: "Private",
            phone: "+1 630 665 2988",
            address: "Wheaton, IL 60189"
        ),
        c(
            GLEN_CLUB_ID,
            "The Glen Club",
            GLEN_CLUB_PARS,
            GLEN_CLUB_HCS,
            GLEN_CLUB_TEES,
            country: "USA",
            state: "IL",
            region: "Chicago North Shore",
            architect: "Tom Fazio",
            type: "Daily-Fee",
            phone: "(847) 724-7272",
            website: "https://www.theglenclub.com",
            address: "2901 West Lake Ave, Glenview, IL 60026",
            isWolfApproved: true,
            resortBrand: "KemperSports"
        ),
        c(
            THUNDERHAWK_ID,
            "ThunderHawk Golf Club",
            THUNDERHAWK_PARS,
            THUNDERHAWK_HCS,
            THUNDERHAWK_TEES,
            country: "USA",
            state: "IL",
            region: "Lake County",
            architect: "Robert Trent Jones Jr.",
            type: "Daily-Fee",
            phone: "(847) 968-3100",
            website: "https://www.thunderhawkgolfclub.org",
            address: "39700 N Lewis Ave, Beach Park, IL 60099",
            isWolfApproved: true
        ),
        c(
            BOWES_CREEK_ID,
            "Bowes Creek Country Club",
            BOWES_CREEK_PARS,
            BOWES_CREEK_HCS,
            BOWES_CREEK_TEES,
            country: "USA",
            state: "IL",
            region: "Chicago Northwest",
            architect: "Rick Jacobson",
            type: "Daily-Fee",
            phone: "(847) 214-5880",
            website: "https://bowescreekcc.com",
            address: "1250 Bowes Creek Blvd, Elgin, IL 60124",
            isWolfApproved: true
        ),
        c(
            WHITE_DEER_RUN_ID,
            "White Deer Run Golf Club",
            WHITE_DEER_RUN_PARS,
            WHITE_DEER_RUN_HCS,
            WHITE_DEER_RUN_TEES,
            country: "USA",
            state: "IL",
            region: "Chicago North Suburbs",
            architect: "Dick Nugent",
            type: "Public",
            phone: "(847) 680-6100",
            website: "https://www.whitedeergolf.com",
            address: "250 W Greggs Pkwy, Vernon Hills, IL",
            isWolfApproved: true
        ),
        c(GLEN_OAK_CC_ID, "Glen Oak Country Club", GLEN_OAK_CC_PARS, GLEN_OAK_CC_HCS, GLEN_OAK_CC_TEES,
          country: "USA",
          state: "IL",
          region: "Chicago West Suburbs",
          architect: "Tom Bendelow",
          type: "Private",
          phone: "(630) 469-5600",
          website: "https://www.glenoakcountryclub.org",
          address: "21W451 Hill Ave, Glen Ellyn, IL 60137"),
        c(
        BETHPAGE_BLACK_ID,
        "Bethpage State Park - Black",
        BETHPAGE_BLACK_PARS,
        BETHPAGE_BLACK_HCS,
        BETHPAGE_BLACK_TEES,
        country: "USA",
        state: "NY",
        region: "Long Island",
        architect: "A.W. Tillinghast",
        type: "Public",
        phone: "(516) 249-0700",
        website: "https://www.bethpagegolfcourse.com",
        address: "99 Quaker Meeting House Rd, Farmingdale, NY",
        isWolfApproved: true
        ),
        c(
        BETHPAGE_RED_ID,
        "Bethpage State Park - Red",
        BETHPAGE_RED_PARS,
        BETHPAGE_RED_HCS,
        BETHPAGE_RED_TEES,
        country: "USA",
        state: "NY",
        region: "Long Island",
        architect: "A.W. Tillinghast",
        type: "Public",
        phone: "(516) 249-0700",
        website: "https://www.bethpagegolfcourse.com",
        address: "99 Quaker Meeting House Rd, Farmingdale, NY"
        ),
        c(
        HARBOR_LINKS_ID,
        "Harbor Links Golf Course",
        HARBOR_LINKS_PARS,
        HARBOR_LINKS_HCS,
        HARBOR_LINKS_TEES,
        country: "USA",
        state: "NY",
        region: "Long Island",
        architect: "Michael Hurdzan & Dana Fry",
        type: "Public",
        phone: "(516) 767-4816",
        address: "1 Fairway Drive, Port Washington, NY 11050"
        ),
        // MARK: - Built-In Course Entries

        // MARK: - Built-In Course Entries

        c(
            OLD_BARNWELL_ID,
            "Old Barnwell",
            OLD_BARNWELL_PARS,
            OLD_BARNWELL_HCS,
            OLD_BARNWELL_TEES,
            country: "USA",
            state: "SC",
            region: "Aiken",
            architect: "Brian Schneider & Blake Conant",
            type: "Private",
            phone: "(803) 761-9040",
            website: "https://oldbarnwell.com",
            address: "6200 Gilroy Lane, Aiken, SC 29803",
            isWolfApproved: true
        ),

        c(
            YEAMANS_HALL_ID,
            "Yeamans Hall Club",
            YEAMANS_HALL_PARS,
            YEAMANS_HALL_HCS,
            YEAMANS_HALL_TEES,
            country: "USA",
            state: "SC",
            region: "Charleston",
            architect: "Seth Raynor & Charles Banks",
            type: "Private",
            phone: "(843) 744-3351",
            website: "https://www.yeamanshallclub.com",
            address: "900 Yeamans Hall Road, Charleston, SC 29410",
            isWolfApproved: true
        ),

        c(
            TREE_FARM_ID,
            "The Tree Farm",
            TREE_FARM_PARS,
            TREE_FARM_HCS,
            TREE_FARM_TEES,
            country: "USA",
            state: "SC",
            region: "Batesburg",
            architect: "Tom Doak & Kye Goalby",
            type: "Private",
            phone: "(507) 993-6292",
            website: "https://thetreefarm.golf",
            address: "4456 Tree Farm Trail, Batesburg, SC 29006",
            isWolfApproved: true
        ),

        c(
            CONGAREE_ID,
            "Congaree Golf Club",
            CONGAREE_PARS,
            CONGAREE_HCS,
            CONGAREE_TEES,
            country: "USA",
            state: "SC",
            region: "Ridgeland",
            architect: "Tom Fazio",
            type: "Private",
            phone: "(843) 717-3400",
            website: "https://www.congareegc.com",
            address: "384 Davant Drive, Ridgeland, SC 29936",
            isWolfApproved: true
        ),

        c(
            PALMETTO_ID,
            "Palmetto Golf Club",
            PALMETTO_PARS,
            PALMETTO_HCS,
            PALMETTO_TEES,
            country: "USA",
            state: "SC",
            region: "Aiken",
            architect: "Alister MacKenzie",
            type: "Private",
            phone: "(803) 649-2951",
            website: "https://palmettogolfclub.net",
            address: "275 Berrie Road SW, Aiken, SC 29801",
            isWolfApproved: true
        ),

        c(
            SAGE_VALLEY_ID,
            "Sage Valley Golf Club",
            SAGE_VALLEY_PARS,
            SAGE_VALLEY_HCS,
            SAGE_VALLEY_TEES,
            country: "USA",
            state: "SC",
            region: "Graniteville",
            architect: "Tom Fazio",
            type: "Private",
            phone: "(803) 663-0900",
            website: "https://sagevalleygolf.com",
            address: "2240 Sage Valley Drive, Graniteville, SC 29829",
            isWolfApproved: true
        ),

        c(
            QUIXOTE_ID,
            "Quixote Club",
            QUIXOTE_PARS,
            QUIXOTE_HCS,
            QUIXOTE_TEES,
            country: "USA",
            state: "SC",
            region: "Sumter",
            architect: "Kris Spence",
            type: "Private",
            phone: "(803) 775-5541",
            website: "https://www.quixoteclub.com",
            address: "875 Pinewood Road, Sumter, SC 29154",
            isWolfApproved: true
        ),
        c(
            MAY_RIVER_ID,
            "May River Golf Club",
            MAY_RIVER_PARS,
            MAY_RIVER_HCS,
            MAY_RIVER_TEES,
            country: "USA",
            state: "SC",
            region: "Bluffton",
            architect: "Jack Nicklaus",
            type: "Private / Resort",
            phone: "(843) 706-6580",
            website: "https://www.palmettobluff.com/experience/golf/",
            address: "477 Mount Pelia Road, Bluffton, SC 29910",
            isWolfApproved: true
        ),

        c(
            SECESSION_ID,
            "Secession Golf Club",
            SECESSION_PARS,
            SECESSION_HCS,
            SECESSION_TEES,
            country: "USA",
            state: "SC",
            region: "Beaufort",
            architect: "Bruce Devlin",
            type: "Private",
            phone: "(843) 522-4600",
            website: "https://www.secessiongolf.club",
            address: "100 Islands Causeway, Beaufort, SC 29907",
            isWolfApproved: true
        ),

        c(
            BULLS_BAY_ID,
            "Bulls Bay Golf Club",
            BULLS_BAY_PARS,
            BULLS_BAY_HCS,
            BULLS_BAY_TEES,
            country: "USA",
            state: "SC",
            region: "Awendaw / Charleston",
            architect: "Mike Strantz",
            type: "Private",
            phone: "(843) 881-2223",
            website: "https://www.bullsbaygolf.com",
            address: "995 Bulls Bay Drive, Awendaw, SC 29429",
            isWolfApproved: true
        ),
        c(
            DUNES_GOLF_BEACH_GOLD_ID,
            "Dunes Golf & Beach Club",
            DUNES_GOLF_BEACH_GOLD_PARS,
            DUNES_GOLF_BEACH_GOLD_HCS,
            DUNES_GOLF_BEACH_TEES,
            country: "USA",
            state: "SC",
            region: "Myrtle Beach",
            architect: "Robert Trent Jones, Sr.",
            type: "Semi-Private",
            phone: "(843) 449-5236",
            address: "9000 N. Ocean Blvd, Myrtle Beach, SC 29572"
        ),
        c(
            WARREN_GC_ID,
            "Warren Golf & Country Club",
            WARREN_GC_PARS,
            WARREN_GC_HCS,
            WARREN_GC_TEES,
            country: "Singapore",
            state: nil,
            region: "Singapore",
            architect: "Nelson & Haworth",
            type: "Private",
            phone: "+65 6586 1245",
            website: "https://www.warrengolf.com",
            address: "81 Choa Chu Kang Way, Singapore 688263",
            isWolfApproved: false
        ),
        c(
            LAGUNA_NATIONAL_ID,
            "Laguna National Golf Resort Club",
            LAGUNA_NATIONAL_PARS,
            LAGUNA_NATIONAL_HCS,
            LAGUNA_NATIONAL_TEES,
            country: "Singapore",
            state: nil,
            region: "Singapore",
            architect: "Andy Dye",
            type: "Private / Resort",
            phone: nil,
            website: "https://www.lagunanational.com",
            address: "11 Laguna Golf Green, Singapore 488047",
            isWolfApproved: false
        ),

        c(
            SENTOSA_TANJONG_ID,
            "Sentosa Golf Club - The Tanjong",
            SENTOSA_TANJONG_PARS,
            SENTOSA_TANJONG_HCS,
            SENTOSA_TANJONG_TEES,
            country: "Singapore",
            state: nil,
            region: "Sentosa",
            architect: "Ron Fream & Gene Bates",
            type: "Parkland",
            phone: "+65 6275 0022",
            website: "https://www.sentosagolf.com",
            address: "27 Bukit Manis Road, Singapore 099892",
            isWolfApproved: false
        ),
        c(
            TANAH_MERAH_TAMPINES_ID,
            "Tanah Merah Country Club – Tampines Course",
            TANAH_MERAH_TAMPINES_PARS,
            TANAH_MERAH_TAMPINES_HCS,
            TANAH_MERAH_TAMPINES_TEES,
            country: "Singapore",
            state: nil,
            region: "Singapore",
            architect: "Phil Jacobs",
            type: "Private",
            phone: "+65 6513 7818",
            website: "https://www.tmcc.org.sg",
            address: "151 Xilin Avenue, Singapore 486798",
            isWolfApproved: false
        ),
        c(
            SENTOSA_NEW_TANJONG_ID,
            "Sentosa Golf Club - New Tanjong Course",
            SENTOSA_NEW_TANJONG_PARS,
            SENTOSA_NEW_TANJONG_HCS,
            SENTOSA_NEW_TANJONG_TEES,
            country: "Singapore",
            state: nil,
            region: "Sentosa",
            architect: "Ronald Fream",
            type: "Private",
            phone: "+65 6275 0022",
            website: "https://www.sentosagolf.com",
            address: "27 Bukit Manis Road, Singapore 099892",
            isWolfApproved: false
        ),
        c(
            KEPPEL_CLUB_ID,
            "Keppel Club",
            KEPPEL_CLUB_PARS,
            KEPPEL_CLUB_HCS,
            KEPPEL_CLUB_TEES,
            country: "Singapore",
            state: nil,
            region: "Singapore",
            architect: "Phil Jacobs",
            type: "Private",
            phone: nil,
            website: nil,
            address: "239 Sime Road, Singapore 289685",
            isWolfApproved: false
        ),
        c(
            RIVER_OAKS_CC_ID,
            "River Oaks Country Club",
            RIVER_OAKS_CC_PARS,
            RIVER_OAKS_CC_HCS,
            RIVER_OAKS_CC_TEES,
            country: "USA",
            state: "TX",
            region: "Houston",
            architect: "Donald Ross",
            type: "Private",
            phone: "(713) 529-4321",
            website: "https://www.riveroakscc.net",
            address: "1600 River Oaks Boulevard, Houston, TX 77019",
            isWolfApproved: true
        ),
        c(
            CHAMPIONS_GC_ID,
            "Champions Golf Club",
            CHAMPIONS_GC_PARS,
            CHAMPIONS_GC_HCS,
            CHAMPIONS_GC_TEES,
            country: "USA",
            state: "TX",
            region: "Houston",
            architect: "Robert Trent Jones, Sr.",
            type: "Private",
            phone: "(281) 444-6262",
            website: "https://www.championsgolfclub.com",
            address: "13722 Champions Drive, Houston, TX 77069",
            isWolfApproved: true
        ),
        c(
            MEMORIAL_PARK_GC_ID,
            "Memorial Park Golf Course",
            MEMORIAL_PARK_GC_PARS,
            MEMORIAL_PARK_GC_HCS,
            MEMORIAL_PARK_GC_TEES,
            country: "USA",
            state: "TX",
            region: "Houston",
            architect: "John Bredemus",
            type: "Municipal",
            phone: "(832) 968-7486",
            website: "https://www.memorialparkgolf.com",
            address: "1001 E Memorial Loop Drive, Houston, TX 77007",
            isWolfApproved: true
        ),
        c(
            SHARPSTOWN_PARK_GC_ID,
            "Sharpstown Park Golf Course",
            SHARPSTOWN_PARK_GC_PARS,
            SHARPSTOWN_PARK_GC_HCS,
            SHARPSTOWN_PARK_GC_TEES,
            country: "USA",
            state: "TX",
            region: "Houston",
            architect: "Jay Riviere",
            type: "Municipal",
            phone: "(713) 988-2099",
            website: "https://www.memorialparkgolf.com/sharpstown-park-golf-course",
            address: "6600 Harbor Town Drive, Houston, TX 77036",
            isWolfApproved: true
        ),
        c(
            CYPRESSWOOD_CYPRESS_ID,
            "Cypresswood Golf Club - Cypress Course",
            CYPRESSWOOD_CYPRESS_PARS,
            CYPRESSWOOD_CYPRESS_HCS,
            CYPRESSWOOD_CYPRESS_TEES,
            country: "USA",
            state: "TX",
            region: "Spring (Houston)",
            architect: "Rick Forester",
            type: "Public",
            phone: "(281) 821-6300",
            website: "https://www.cypresswood.com",
            address: "21602 Cypresswood Drive, Spring, TX 77373",
            isWolfApproved: true
        ),
        c(
            GUS_WORTHAM_PARK_GC_ID,
            "Gus Wortham Park Golf Course",
            GUS_WORTHAM_PARK_GC_PARS,
            GUS_WORTHAM_PARK_GC_HCS,
            GUS_WORTHAM_PARK_GC_TEES,
            country: "USA",
            state: "TX",
            region: "Houston",
            architect: "A.W. Pollard",
            type: "Municipal",
            phone: "(713) 928-4260",
            website: "https://www.houstongolfassociation.org",
            address: "7000 Capitol Street, Houston, TX 77011",
            isWolfApproved: true
        ),
        c(
            GOLF_CLUB_OF_HOUSTON_TOURNAMENT_ID,
            "Golf Club of Houston - Tournament Course",
            GOLF_CLUB_OF_HOUSTON_TOURNAMENT_PARS,
            GOLF_CLUB_OF_HOUSTON_TOURNAMENT_HCS,
            GOLF_CLUB_OF_HOUSTON_TOURNAMENT_TEES,
            country: "USA",
            state: "TX",
            region: "Houston",
            architect: "Rees Jones & David Toms",
            type: "Private",
            phone: "(281) 459-7820",
            website: "https://www.golfclubofhouston.com",
            address: "5860 Wilson Road, Humble, TX 77396",
            isWolfApproved: true
        ),
        c(
            WILDCAT_HIGHLANDS_ID,
            "Wildcat Golf Club - Highlands Course",
            WILDCAT_HIGHLANDS_PARS,
            WILDCAT_HIGHLANDS_HCS,
            WILDCAT_HIGHLANDS_TEES,
            country: "USA",
            state: "TX",
            region: "Houston",
            architect: "Michael Hurdzan & Dana Fry",
            type: "Daily-Fee",
            phone: "(713) 413-3400",
            website: "https://www.wildcatgolfclub.com",
            address: "12000 Almeda Road, Houston, TX 77045",
            isWolfApproved: true
        ),
        c(
            WILDCAT_LAKES_ID,
            "Wildcat Golf Club - Lakes Course",
            WILDCAT_LAKES_PARS,
            WILDCAT_LAKES_HCS,
            WILDCAT_LAKES_TEES,
            country: "USA",
            state: "TX",
            region: "Houston",
            architect: "Roy Case",
            type: "Daily-Fee",
            phone: "(713) 413-3400",
            website: "https://www.wildcatgolfclub.com",
            address: "12000 Almeda Road, Houston, TX 77045",
            isWolfApproved: true
        ),
        c(
            GOLFCREST_OLD_ID,
            "Golfcrest CC (Old Course)",
            GOLFCREST_CC_PARS,
            GOLFCREST_OLD_HCS,
            GOLFCREST_CC_TEES,
            country: "USA",
            state: "TX",
            region: "Houston",
            architect: "Harry Bowers",
            type: "Private",
            phone: "(281) 485-4323",
            website: "https://www.golfcrestcountryclub.com",
            address: "2509 Country Club Drive, Pearland, TX 77581",
            isWolfApproved: true
        ),
        c(
            GOLFCREST_NEW_ID,
            "Golfcrest CC (New Course)",
            GOLFCREST_CC_PARS,
            GOLFCREST_NEW_HCS,
            GOLFCREST_CC_TEES,
            country: "USA",
            state: "TX",
            region: "Houston",
            architect: "Harry Bowers",
            type: "Private",
            phone: "(281) 485-4323",
            website: "https://www.golfcrestcountryclub.com",
            address: "2509 Country Club Drive, Pearland, TX 77581",
            isWolfApproved: true
        ),
        c(
            BLACKHORSE_SOUTH_ID,
            "BlackHorse Golf Club - South Course",
            BLACKHORSE_SOUTH_PARS,
            BLACKHORSE_SOUTH_HCS,
            BLACKHORSE_SOUTH_TEES,
            country: "USA",
            state: "TX",
            region: "Cypress",
            architect: "Peter Jacobsen & Jim Hardy",
            type: "Private",
            phone: "(281) 304-1747",
            website: "https://www.blackhorsegolfclub.com",
            address: "12205 Fry Road, Cypress, TX 77433",
            isWolfApproved: true
        ),
        c(
            BLACKHORSE_NORTH_ID,
            "BlackHorse Golf Club - North Course",
            BLACKHORSE_NORTH_PARS,
            BLACKHORSE_NORTH_HCS,
            BLACKHORSE_NORTH_TEES,
            country: "USA",
            state: "TX",
            region: "Cypress",
            architect: "Peter Jacobsen & Jim Hardy",
            type: "Private",
            phone: "(281) 304-1747",
            website: "https://www.blackhorsegolfclub.com",
            address: "12205 Fry Road, Cypress, TX 77433",
            isWolfApproved: true
        ),
        c(
            HERSHEY_EAST_ID,
            "Hershey Country Club - East Course",
            HERSHEY_EAST_PARS,
            HERSHEY_EAST_HCS,
            HERSHEY_EAST_TEES,
            country: "USA",
            state: "PA",
            region: "Hershey",
            architect: "Maurice McCarthy",
            type: "Semi-Private",
            phone: "(717) 533-2360",
            website: "https://www.hersheycountryclub.com",
            address: "1000 East Derry Road, Hershey, PA 17033",
            isWolfApproved: true
        ),
        c(
            HERSHEY_WEST_ID,
            "Hershey Country Club - West Course",
            HERSHEY_WEST_PARS,
            HERSHEY_WEST_HCS,
            HERSHEY_WEST_TEES,
            country: "USA",
            state: "PA",
            region: "Hershey",
            architect: "Maurice McCarthy",
            type: "Semi-Private",
            phone: "(717) 533-2360",
            website: "https://www.hersheycountryclub.com",
            address: "1000 East Derry Road, Hershey, PA 17033",
            isWolfApproved: true
        ),
        c(
            BEDFORD_SPRINGS_ID,
            "Bedford Springs Resort",
            BEDFORD_SPRINGS_PARS,
            BEDFORD_SPRINGS_HCS,
            BEDFORD_SPRINGS_TEES,
            country: "USA",
            state: "PA",
            region: "Bedford",
            architect: "William S. Flynn",
            type: "Resort",
            website: "https://www.omnihotels.com/hotels/bedford-springs/golf",
            address: "Bedford, PA",
            isWolfApproved: true
        ),
        c(
            NEMACOLIN_MYSTIC_ROCK_ID,
            "Nemacolin Woodlands Resort - Mystic Rock",
            NEMACOLIN_MYSTIC_ROCK_PARS,
            NEMACOLIN_MYSTIC_ROCK_HCS,
            NEMACOLIN_MYSTIC_ROCK_TEES,
            country: "USA",
            state: "PA",
            region: "Farmington",
            architect: "Pete Dye",
            type: "Resort",
            website: "https://www.nemacolin.com/golf",
            address: "Farmington, PA",
            isWolfApproved: true
        ),
        c(
            OLDE_STONEWALL_ID,
            "Olde Stonewall Golf Club",
            OLDE_STONEWALL_PARS,
            OLDE_STONEWALL_HCS,
            OLDE_STONEWALL_TEES,
            country: "USA",
            state: "PA",
            region: "Ellwood City",
            architect: "Michael Hurdzan",
            type: "Daily Fee",
            phone: "(724) 752-4653",
            website: "https://www.oldestonewall.com",
            address: "1495 Mercer Road, Ellwood City, PA 16117",
            isWolfApproved: true
        ),
        c(
            GLEN_MILLS_ID,
            "The Golf Course at Glen Mills",
            GLEN_MILLS_PARS,
            GLEN_MILLS_HCS,
            GLEN_MILLS_TEES,
            country: "USA",
            state: "PA",
            region: "Glen Mills",
            architect: "Bobby Weed",
            type: "Public",
            phone: "(610) 558-2142",
            website: "https://www.glenmillsgolf.com",
            address: "221 Glen Mills Road, Glen Mills, PA 19342",
            isWolfApproved: true
        ),
        c(
            FOX_CHAPEL_ID,
            "Fox Chapel Golf Club",
            FOX_CHAPEL_PARS,
            FOX_CHAPEL_HCS,
            FOX_CHAPEL_TEES,
            country: "USA",
            state: "PA",
            region: "Pittsburgh",
            architect: "Seth Raynor",
            type: "Private",
            website: "https://www.foxchapelgolfclub.org",
            address: "Pittsburgh, PA",
            isWolfApproved: true
        ),
        c(
            OAKMONT_CC_ID,
            "Oakmont Country Club",
            OAKMONT_CC_PARS,
            OAKMONT_CC_HCS,
            OAKMONT_CC_TEES,
            country: "USA",
            state: "PA",
            region: "Pittsburgh",
            architect: "H.C. Fownes",
            type: "Private",
            phone: "(412) 828-8000",
            website: "https://www.oakmontcc.org",
            address: "1233 Hulton Rd., Oakmont, PA 15139"
        ),
        c(
            ARONIMINK_GC_ID,
            "Aronimink Golf Club",
            ARONIMINK_GC_PARS,
            ARONIMINK_GC_HCS,
            ARONIMINK_GC_TEES,
            country: "USA",
            state: "PA",
            region: "Philadelphia",
            architect: "Donald Ross",
            type: "Private",
            phone: "(610) 356-8000",
            address: "3600 St. Davids Road, Newtown Square, PA 19073"
        ),
        c(
            PCC_WISSAHICKON_ID,
            "Philadelphia Cricket Club (Wissahickon)",
            PCC_WISSAHICKON_PARS,
            PCC_WISSAHICKON_HCS,
            PCC_WISSAHICKON_TEES,
            country: "USA",
            state: "PA",
            region: "Philadelphia",
            architect: "Willie Tucker",
            type: "Private",
            phone: "215.247.6113",
            address: "6025 West Valley Green Road, Flourtown, PA 19031"
        ),
        c(
            MERION_EAST_ID,
            "Merion Golf Club (East)",
            MERION_EAST_PARS,
            MERION_EAST_HCS,
            MERION_EAST_TEES,
            country: "USA",
            state: "PA",
            region: "Philadelphia",
            architect: "Hugh Wilson",
            type: "Private",
            address: "450 Ardmore Ave., Ardmore, PA 19003"
        ),
        c(
            MERION_WEST_ID,
            "Merion Golf Club (West)",
            MERION_WEST_PARS,
            MERION_WEST_HCS,
            MERION_WEST_TEES,
            country: "USA",
            state: "PA",
            region: "Philadelphia",
            architect: "Hugh Wilson",
            type: "Private",
            address: "450 Ardmore Ave., Ardmore, PA 19003"
        ),
        c(
            FOWLERS_MILL_ID,
            "Fowler's Mill Golf Course",
            FOWLERS_MILL_PARS,
            FOWLERS_MILL_HCS,
            country: "USA",
            state: "OH",
            region: "Cleveland East",
            architect: "Pete Dye",
            type: "Public",
            phone: "(440) 729-7569",
            website: "https://www.fowlersmillgc.com",
            address: "13095 Rockhaven Rd, Chesterland, OH",
            isWolfApproved: true
        ),
        c(
            STONELICK_HILLS_ID,
            "Stonelick Hills Golf Club",
            STONELICK_HILLS_PARS,
            STONELICK_HILLS_HCS,
            country: "USA",
            state: "OH",
            region: "Cincinnati",
            architect: "Jeff Osterfeld",
            type: "Public",
            phone: "(513) 735-4653",
            website: "https://www.stonelickhills.com",
            address: "3155 Sherilyn Ln, Batavia, OH",
            isWolfApproved: true
        ),
        c(
            CAMARGO_CLUB_ID,
            "Camargo Club",
            CAMARGO_CLUB_PARS,
            CAMARGO_CLUB_HCS,
            CAMARGO_CLUB_TEES,
            country: "USA",
            state: "OH",
            region: "Cincinnati",
            architect: "Seth Raynor",
            type: "Private",
            phone: "(513) 561-9292",
            address: "8605 Shawnee Run Road, Cincinnati, OH 45243"
        ),
        c(
            MANAKIKI_ID,
            "Manakiki Golf Course",
            MANAKIKI_PARS,
            MANAKIKI_HCS,
            country: "USA",
            state: "OH",
            region: "Cleveland East",
            architect: "Donald Ross",
            type: "Municipal",
            phone: "(440) 942-2500",
            website: "https://www.clevelandmetroparks.com",
            address: "35501 Eddy Rd, Willoughby Hills, OH",
            isWolfApproved: true
        ),
        c(
            BOULDER_CREEK_ID,
            "Boulder Creek Golf Club",
            BOULDER_CREEK_PARS,
            BOULDER_CREEK_HCS,
            country: "USA",
            state: "OH",
            region: "Cleveland South",
            architect: "Joe Salemi",
            type: "Semi-Private",
            phone: "(330) 626-2680",
            website: "https://www.bouldercreekoh.com",
            address: "9700 Page Rd, Streetsboro, OH",
            isWolfApproved: true
        ),
        c(
            QUARRY_GC_ID,
            "The Quarry Golf Club",
            QUARRY_GC_PARS,
            QUARRY_GC_HCS,
            country: "USA",
            state: "OH",
            region: "Canton",
            architect: "Brian Huntley",
            type: "Private",
            phone: "(330) 488-3178",
            website: "https://www.thequarrygolfclub.com",
            address: "5650 Quarry Lake Dr, East Canton, OH",
            isWolfApproved: true
        ),
        c(
            DEER_RIDGE_ID,
            "Deer Ridge Golf Club",
            DEER_RIDGE_PARS,
            DEER_RIDGE_HCS,
            country: "USA",
            state: "OH",
            region: "Central Ohio",
            architect: "Brian Huntley",
            type: "Public",
            phone: "(419) 886-7090",
            website: "https://www.deerridgegolfclub.com",
            address: "900 Comfort Plaza Dr, Bellville, OH",
            isWolfApproved: true
        ),
        c(
            VALLEY_EAGLES_ID,
            "Valley of the Eagles",
            VALLEY_EAGLES_PARS,
            VALLEY_EAGLES_HCS,
            country: "USA",
            state: "OH",
            region: "Cleveland West",
            architect: "Greg Norman",
            type: "Public",
            phone: "(440) 365-1411",
            website: "https://www.valleyeagles.com",
            address: "1100 Gulf Rd, Elyria, OH",
            isWolfApproved: true
        ),
        c(
            FIRESTONE_SOUTH_ID,
            "Firestone Country Club - South Course",
            FIRESTONE_SOUTH_PARS,
            FIRESTONE_SOUTH_HCS,
            FIRESTONE_SOUTH_TEES,
            country: "USA",
            state: "OH",
            region: "Akron",
            architect: "Tom Fazio",
            type: "Private",
            phone: "(330) 644-8441",
            website: "https://www.firestonecountryclub.com",
            address: "452 E Warner Road, Akron, OH 44319",
            isWolfApproved: true
        ),
        c(
            FIRESTONE_NORTH_ID,
            "Firestone Country Club - North Course",
            FIRESTONE_NORTH_PARS,
            FIRESTONE_NORTH_HCS,
            FIRESTONE_NORTH_TEES,
            country: "USA",
            state: "OH",
            region: "Akron",
            architect: "Tom Fazio",
            type: "Private",
            phone: "(330) 644-8441",
            website: "https://www.firestonecountryclub.com",
            address: "452 E Warner Road, Akron, OH 44319",
            isWolfApproved: true
        ),
        c(
            FIRESTONE_FAZIO_ID,
            "Firestone Country Club - Fazio Course",
            FIRESTONE_FAZIO_PARS,
            FIRESTONE_FAZIO_HCS,
            FIRESTONE_FAZIO_TEES,
            country: "USA",
            state: "OH",
            region: "Akron",
            architect: "Tom Fazio",
            type: "Private",
            phone: "(330) 644-8441",
            website: "https://www.firestonecountryclub.com",
            address: "452 E Warner Road, Akron, OH 44319",
            isWolfApproved: true
        ),
        c(
            VIRTUES_GOLF_CLUB_ID,
            "The Virtues Golf Club",
            VIRTUES_GOLF_CLUB_PARS,
            VIRTUES_GOLF_CLUB_HCS,
            VIRTUES_GOLF_CLUB_TEES,
            country: "USA",
            state: "OH",
            region: "Nashport",
            architect: "Arthur Hills",
            type: "Public",
            phone: "(740) 763-1100",
            website: "https://www.thevirtuesgolfclub.com",
            address: "One Long Drive, Nashport, OH 43830",
            isWolfApproved: true
        ),
        c(
            SLEEPY_HOLLOW_GC_ID,
            "Sleepy Hollow Golf Course",
            SLEEPY_HOLLOW_GC_PARS,
            SLEEPY_HOLLOW_GC_HCS,
            SLEEPY_HOLLOW_GC_TEES,
            country: "USA",
            state: "OH",
            region: "Brecksville",
            architect: "Stanley Thompson",
            type: "Municipal",
            phone: "(216) 635-3200",
            website: "https://www.clevelandmetroparks.com/golf/courses/sleepy-hollow-golf-course",
            address: "9445 Brecksville Road, Brecksville, OH 44141",
            isWolfApproved: true
        ),

        // -------------------------
        // Canada
        // -------------------------
        c(
            TPC_TORONTO_NORTH_ID,
            "TPC Toronto at Osprey Valley (North)",
            TPC_TORONTO_NORTH_PARS,
            TPC_TORONTO_NORTH_HCS,
            TPC_TORONTO_NORTH_TEES,
            country: "Canada",
            state: "ON",
            region: "Caledon",
            architect: "Doug Carrick",
            type: "Resort",
            address: "19131 Main St., Caledon, ON L7K 1R1",
            isWolfApproved: true
        ),
        c(
            TPC_TORONTO_HOOT_ID,
            "TPC Toronto at Osprey Valley (Hoot)",
            TPC_TORONTO_HOOT_PARS,
            TPC_TORONTO_HOOT_HCS,
            TPC_TORONTO_HOOT_TEES,
            country: "Canada",
            state: "ON",
            region: "Caledon",
            architect: "Doug Carrick",
            type: "Resort",
            address: "19131 Main St., Caledon, ON L7K 1R1",
            isWolfApproved: true
        ),
        c(
            TPC_TORONTO_HEATHLANDS_ID,
            "TPC Toronto at Osprey Valley (Heathlands)",
            TPC_TORONTO_HEATHLANDS_PARS,
            TPC_TORONTO_HEATHLANDS_HCS,
            TPC_TORONTO_HEATHLANDS_TEES,
            country: "Canada",
            state: "ON",
            region: "Caledon",
            architect: "Doug Carrick",
            type: "Resort",
            address: "19131 Main St., Caledon, ON L7K 1R1",
            isWolfApproved: true
        ),

        // -------------------------
        // Japan
        // -------------------------
        c(
            NARA_KOKUSAI_GC_ID,
            "Nara Kokusai GC",
            NARA_KOKUSAI_GC_PARS,
            NARA_KOKUSAI_GC_HCS,
            NARA_KOKUSAI_GC_TEES,
            country: "Japan",
            state: nil,
            region: "Nara",
            architect: "Osamu Ueda",
            type: "Private"
        ),
        c(
            HIRONO_GC_ID,
            "Hirono Golf Club",
            HIRONO_GC_PARS,
            HIRONO_GC_HCS,
            HIRONO_GC_TEES,
            country: "Japan",
            state: nil,
            region: "Hyogo",
            architect: "Charles Hugh Alison",
            type: "Private"
        ),
        c(
            KAWANA_FUJI_ID,
            "Kawana Hotel GC (Fuji Course)",
            KAWANA_FUJI_PARS,
            KAWANA_FUJI_HCS,
            KAWANA_FUJI_TEES,
            country: "Japan",
            state: nil,
            region: "Shizuoka",
            architect: "Charles Hugh Alison",
            type: "Resort"
        ),
        c(
            NARUO_GC_ID,
            "Naruo GC",
            NARUO_GC_PARS,
            NARUO_GC_HCS,
            NARUO_GC_TEES,
            country: "Japan",
            state: nil,
            region: "Hyogo",
            architect: "Charles Hugh Alison",
            type: "Private",
            phone: "+81 727 94 1011"
        ),
        c(
            TOKYO_GC_ID,
            "Tokyo Golf Club",
            TOKYO_GC_PARS,
            TOKYO_GC_HCS,
            TOKYO_GC_TEES,
            country: "Japan",
            state: nil,
            region: "Saitama",
            architect: "Komei Otani (1939) / Gil Hanse redesign",
            type: "Private",
            phone: "+81 4 2953 9111",
            website: "https://www.tokyogolfclub.jp",
            address: "1984 Kashiwabara, Sayama, Saitama, Japan"
        ),
        c(
            KASUMIGASEKI_EAST_ID,
            "Kasumigaseki CC (East Course)",
            KASUMIGASEKI_EAST_PARS,
            KASUMIGASEKI_EAST_HCS,
            KASUMIGASEKI_EAST_TEES,
            country: "Japan",
            state: nil,
            region: "Saitama",
            architect: "C.H. Alison (1930)",
            type: "Private",
            phone: "+81 49 231 2181",
            website: "https://www.kasumigasekicc.or.jp",
            address: "3398 Kasahata, Kawagoe, Saitama 350-1175, Japan"
        ),
        c(
            KASUMIGASEKI_WEST_ID,
            "Kasumigaseki CC (West Course)",
            KASUMIGASEKI_WEST_PARS,
            KASUMIGASEKI_WEST_HCS,
            KASUMIGASEKI_WEST_TEES,
            country: "Japan",
            state: nil,
            region: "Saitama",
            architect: "C.H. Alison (1932)",
            type: "Private",
            phone: "+81 49 231 2181",
            website: "https://www.kasumigasekicc.or.jp",
            address: "3398 Kasahata, Kawagoe, Saitama 350-1175, Japan"
        ),
        c(
            YOKOHAMA_CC_WEST_ID,
            "Yokohama CC (West Course)",
            YOKOHAMA_CC_WEST_PARS,
            YOKOHAMA_CC_WEST_HCS,
            YOKOHAMA_CC_WEST_TEES,
            country: "Japan",
            state: nil,
            region: "Kanagawa",
            architect: "Aiyama Takeo & Takemura Hideo (1960) / Coore & Crenshaw redesign (2016)",
            type: "Private",
            phone: "+81 45 351 1001",
            website: "https://www.yokohama-cc.jp/west/",
            address: "1025 Imai-cho, Hodogaya-ku, Yokohama, Kanagawa 240-0035, Japan"
        ),

        // -------------------------
        // Sweden
        // -------------------------
        c(
            BRO_HOF_STADIUM_ID,
            "Bro Hof Slott (Stadium Course)",
            BRO_HOF_STADIUM_PARS,
            BRO_HOF_STADIUM_HCS,
            BRO_HOF_STADIUM_TEES,
            country: "Sweden",
            state: nil,
            region: "Bro",
            architect: "Robert Trent Jones Jr. / Bruce Charlton",
            type: "Resort",
            phone: "+46 (0)8 545 279 90",
            website: "https://www.brohofslott.se",
            address: "Bro Hof Slott, 197 91 Bro, Sweden",
            isWolfApproved: true
        ),
        c(
            BRO_HOF_CASTLE_ID,
            "Bro Hof Slott (Castle Course)",
            BRO_HOF_CASTLE_PARS,
            BRO_HOF_CASTLE_HCS,
            BRO_HOF_CASTLE_TEES,
            country: "Sweden",
            state: nil,
            region: "Bro",
            architect: "Robert Trent Jones Jr. / Bruce Charlton",
            type: "Resort",
            phone: "+46 (0)8 545 279 90",
            website: "https://www.brohofslott.se",
            address: "Bro Hof Slott, 197 91 Bro, Sweden",
            isWolfApproved: true
        ),
        c(
            VISBY_GC_ID,
            "Visby Golf Club",
            VISBY_GC_PARS,
            VISBY_GC_HCS,
            country: "Sweden",
            state: nil,
            region: "Gotland",
            architect: "Pierre Fulke / Adam Mednickson",
            type: "Semi-Private",
            phone: "+46 498 200930",
            website: "https://www.visbygk.com",
            address: "Västergarn Kronholmen 415, 622 30 Gotlands Tofta, Sweden",
            isWolfApproved: true
        ),
        c(
            FALSTERBO_GC_ID,
            "Falsterbo Golf Club",
            FALSTERBO_GC_PARS,
            FALSTERBO_GC_HCS,
            FALSTERBO_GC_TEES,
            country: "Sweden",
            state: nil,
            region: "Falsterbo",
            architect: "Robert Turnbull / Gunnar Bauer / Peter Nordwall / Peter Chamberlain",
            type: "Private",
            phone: "+46 40-47 00 78",
            website: "https://www.falsterbogk.se",
            address: "Fyrvägen 34, 239 40, Falsterbo, Sweden",
            isWolfApproved: true
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
        case .nineStandard:     return "9-Hole"
        case .loopAtoB: return "A → B"
        case .loopBtoC: return "B → C"
        case .loopAtoC: return "A → C"
        }
    }
}
