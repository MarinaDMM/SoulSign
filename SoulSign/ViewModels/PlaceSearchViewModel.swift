//
//  PlaceSearchViewModel.swift
//  SoulSign
//
//  Created by Marina Dedikova on 14/06/2025.
//
import Foundation
import GooglePlaces
import CoreLocation

class PlaceSearchViewModel: ObservableObject {
    @Published var searchText: String = "" {
        didSet {
            fetchSuggestions(for: searchText)
        }
    }
    @Published var suggestions: [GMSAutocompletePrediction] = []
    @Published var shouldShowSuggestions: Bool = false
    @Published var selectedPlaceName: String = ""
    @Published var selectedCoordinates: CLLocationCoordinate2D? = nil

    private var fetchTask: Task<Void, Never>? = nil

    func fetchSuggestions(for query: String) {
        guard !query.isEmpty else {
            suggestions = []
            shouldShowSuggestions = false
            return
        }

        let filter = GMSAutocompleteFilter()
        filter.type = .geocode

        GMSPlacesClient.shared().findAutocompletePredictions(fromQuery: query, filter: filter, sessionToken: nil) { results, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Autocomplete error: \(error.localizedDescription)")
                }

                if let results = results {
                    self.suggestions = results
                    self.shouldShowSuggestions = !results.isEmpty
                } else {
                    self.suggestions = []
                    self.shouldShowSuggestions = false
                }
            }
        }
    }

    func selectSuggestion(_ suggestion: GMSAutocompletePrediction) {
        self.shouldShowSuggestions = false
        fetchPlaceDetails(for: suggestion.placeID)
    }

    private func fetchPlaceDetails(for placeID: String) {
        let placesClient = GMSPlacesClient.shared()
        let fields: GMSPlaceField = [.coordinate, .formattedAddress]

        placesClient.fetchPlace(fromPlaceID: placeID, placeFields: fields, sessionToken: nil) { place, error in
            DispatchQueue.main.async {
                if let place = place {
                    self.selectedCoordinates = place.coordinate
                    self.selectedPlaceName = place.formattedAddress ?? ""
                    self.searchText = place.formattedAddress ?? ""
                } else {
                    print("Failed to fetch place details: \(error?.localizedDescription ?? "Unknown error")")
                    self.selectedCoordinates = nil
                    self.selectedPlaceName = ""
                }
            }
        }
    }
}
