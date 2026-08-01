//
//  UserProfile.swift
//  SoulSign
//
import Foundation
import CoreLocation

struct UserProfile: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var birthDate: Date
    var birthTime: Date
    var birthPlace: String
    var latitude: Double?
    var longitude: Double?
    var cachedReading: String?
    var readingDate: Date?
    var cachedReadingLanguage: String?
    var cachedDeepReading: String?
    var deepReadingDate: Date?
    var cachedDeepReadingLanguage: String?

    static func == (lhs: UserProfile, rhs: UserProfile) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    var coordinates: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var initials: String {
        name.components(separatedBy: " ")
            .prefix(2)
            .compactMap { $0.first.map(String.init) }
            .joined()
            .uppercased()
    }

    var firstName: String {
        name.components(separatedBy: " ").first ?? name
    }
}
