import Foundation

// Derives a US state abbreviation from a ZIP code's 3-digit prefix.
// Source: USPS ZIP prefix allocations (US domestic only).
// Returns nil for unrecognised or non-US prefixes.
struct ZipStateCorrector {
    static func state(forZip zip: String) -> String? {
        guard zip.count >= 3, let prefix = Int(zip.prefix(3)) else { return nil }
        switch prefix {
        case 5:               return "VT"   // 005
        case 6...9:           return "PR"
        case 10...27:         return "MA"
        case 28...29:         return "RI"
        case 30...38:         return "NH"
        case 39...49:         return "ME"
        case 50...59:         return "VT"
        case 60...69:         return "CT"
        case 70...89:         return "NJ"
        case 100...149:       return "NY"
        case 150...196:       return "PA"
        case 197...199:       return "DE"
        case 200, 202...205:  return "DC"
        case 201, 213,
             220...246:       return "VA"
        case 206...212,
             214...219:       return "MD"
        case 247...269:       return "WV"
        case 270...289:       return "NC"
        case 290...299:       return "SC"
        case 300...319:       return "GA"
        case 320...349:       return "FL"
        case 350...369:       return "AL"
        case 370...385:       return "TN"
        case 386...397:       return "MS"
        case 398...399:       return "GA"
        case 400...427:       return "KY"
        case 428...429:       return "WV"
        case 430...458:       return "OH"
        case 459...479:       return "IN"
        case 480...499:       return "MI"
        case 500...528:       return "IA"
        case 529...549:       return "WI"
        case 550...567:       return "MN"
        case 570...577:       return "SD"
        case 580...588:       return "ND"
        case 590...599:       return "MT"
        case 600...629:       return "IL"
        case 630...658:       return "MO"
        case 660...679:       return "KS"
        case 680...693:       return "NE"
        case 700...714:       return "LA"
        case 716...729:       return "AR"
        case 730...749:       return "OK"
        case 750...799:       return "TX"
        case 800...816:       return "CO"
        case 820...831:       return "WY"
        case 832...838:       return "ID"
        case 840...847:       return "UT"
        case 850...865:       return "AZ"
        case 870...884:       return "NM"
        case 885:             return "TX"   // El Paso area
        case 889...898:       return "NV"
        case 900...961:       return "CA"
        case 967...968:       return "HI"
        case 969:             return "GU"
        case 970...979:       return "OR"
        case 980...994:       return "WA"
        case 995...999:       return "AK"
        default:              return nil
        }
    }

    // Returns the ZIP-derived state when known; otherwise returns `fallback`.
    static func state(forZip zip: String?, fallback: String?) -> String? {
        guard let zip, let derived = state(forZip: zip) else { return fallback }
        return derived
    }
}
