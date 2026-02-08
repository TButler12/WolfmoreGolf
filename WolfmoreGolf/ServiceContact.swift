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

    static let `default` = ServiceContacts(
        proShopName: "Pro Shop",
        proShop: "",
        drinkCartName: "Drink Cart",
        drinkCart: ""
    )
}



