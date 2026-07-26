//
//  UserProfileTests.swift
//  SoulSignTests
//
import XCTest
import CoreLocation
@testable import SoulSign

final class UserProfileTests: XCTestCase {

    private func makeProfile(name: String, lat: Double? = nil, lon: Double? = nil) -> UserProfile {
        UserProfile(name: name, birthDate: Date(), birthTime: Date(),
                    birthPlace: "Paris, France", latitude: lat, longitude: lon)
    }

    func testInitialsUseFirstTwoWords() {
        XCTAssertEqual(makeProfile(name: "Luna Rivers").initials, "LR")
        XCTAssertEqual(makeProfile(name: "Madonna").initials, "M")
        XCTAssertEqual(makeProfile(name: "Mary Jane Watson").initials, "MJ",
                       "only the first two words are used")
    }

    func testFirstName() {
        XCTAssertEqual(makeProfile(name: "Luna Rivers").firstName, "Luna")
        XCTAssertEqual(makeProfile(name: "Madonna").firstName, "Madonna")
    }

    func testCoordinatesNilWhenMissing() {
        XCTAssertNil(makeProfile(name: "X").coordinates)
        XCTAssertNil(makeProfile(name: "X", lat: 1.0).coordinates, "needs both lat and lon")
    }

    func testCoordinatesWhenPresent() {
        let coords = makeProfile(name: "X", lat: 48.8566, lon: 2.3522).coordinates
        XCTAssertEqual(coords?.latitude, 48.8566)
        XCTAssertEqual(coords?.longitude, 2.3522)
    }

    func testCodableRoundTrip() throws {
        let original = makeProfile(name: "Luna Rivers", lat: 48.8566, lon: 2.3522)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UserProfile.self, from: data)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.birthPlace, original.birthPlace)
        XCTAssertEqual(decoded.latitude, original.latitude)
    }

    func testEqualityByID() {
        var a = makeProfile(name: "Luna")
        let b = a
        XCTAssertEqual(a, b)
        a.name = "Changed"
        XCTAssertEqual(a, b, "equality is by id, not fields")
    }
}
