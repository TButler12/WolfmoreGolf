//
//  ServiceContactStore.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 2/6/26.
//

import Foundation

final class ServiceContactStore {

    static let shared = ServiceContactStore()
    private let key = "serviceContacts"

    private(set) var contacts: ServiceContacts = .default

    private init() { load() }

    func setProShop(_ number: String) {
        contacts.proShop = number
        save()
    }

    func setDrinkCart(_ number: String) {
        contacts.drinkCart = number
        save()
    }

    func setProShopName(_ name: String) {
        contacts.proShopName = name
        save()
    }

    func setDrinkCartName(_ name: String) {
        contacts.drinkCartName = name
        save()
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode(ServiceContacts.self, from: data)
        else {
            contacts = .default
            return
        }
        contacts = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(contacts) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

