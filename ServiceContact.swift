//
//  ServiceContact.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 2/6/26.
//

import Foundation

struct ServiceContacts: Codable {
    var proShopName: String
    var proShop: String
    var drinkCartName: String
    var drinkCart: String

    // NEW
    var coordinatorName: String
    var coordinator: String

    static let `default` = ServiceContacts(
        proShopName: "Pro Shop",
        proShop: "",
        drinkCartName: "Drink Cart",
        drinkCart: "",
        coordinatorName: "Coordinator",
        coordinator: ""
    )

    // ✅ Backwards-compatible decode (old saves won’t have coordinator fields)
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        proShopName   = try c.decodeIfPresent(String.self, forKey: .proShopName) ?? "Pro Shop"
        proShop       = try c.decodeIfPresent(String.self, forKey: .proShop) ?? ""
        drinkCartName = try c.decodeIfPresent(String.self, forKey: .drinkCartName) ?? "Drink Cart"
        drinkCart     = try c.decodeIfPresent(String.self, forKey: .drinkCart) ?? ""

        coordinatorName = try c.decodeIfPresent(String.self, forKey: .coordinatorName) ?? "Coordinator"
        coordinator     = try c.decodeIfPresent(String.self, forKey: .coordinator) ?? ""
    }

    // Keep a normal init too (nice for defaults/tests)
    init(
        proShopName: String,
        proShop: String,
        drinkCartName: String,
        drinkCart: String,
        coordinatorName: String,
        coordinator: String
    ) {
        self.proShopName = proShopName
        self.proShop = proShop
        self.drinkCartName = drinkCartName
        self.drinkCart = drinkCart
        self.coordinatorName = coordinatorName
        self.coordinator = coordinator
    }
}
