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

    // MARK: - Numbers

    func setProShop(_ number: String) {
        contacts.proShop = number
        save()
    }

    func setDrinkCart(_ number: String) {
        contacts.drinkCart = number
        save()
    }

    func setCoordinator(_ number: String) {
        contacts.coordinator = number
        save()
    }

    // MARK: - Names

    func setProShopName(_ name: String) {
        contacts.proShopName = name
        save()
    }

    func setDrinkCartName(_ name: String) {
        contacts.drinkCartName = name
        save()
    }

    func setCoordinatorName(_ name: String) {
        contacts.coordinatorName = name
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            contacts = .default
            return
        }

        do {
            contacts = try JSONDecoder().decode(ServiceContacts.self, from: data)
        } catch {
            // If an old/invalid save exists, don't crash
            contacts = .default
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(contacts)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            // Optional debug:
            // print("❌ ServiceContactStore save error:", error)
        }
    }
}
