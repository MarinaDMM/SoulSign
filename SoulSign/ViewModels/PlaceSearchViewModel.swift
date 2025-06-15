//
//  PlaceSearchViewModel.swift
//  SoulSign
//
//  Created by Marina Dedikova on 14/06/2025.
//
import Foundation
import GooglePlaces
import CoreLocation
import Combine

class PlaceSearchViewModel: NSObject, ObservableObject {
    @Published var searchQuery: String = ""
    @Published var suggestions: [GMSAutocompletePrediction] = []
    @Published var shouldShowSuggestions: Bool = false

    @Published var selectedPlaceName: String = ""
    @Published var selectedCoordinates: CLLocationCoordinate2D?

    private var placesClient = GMSPlacesClient.shared()
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        observeSearchQuery()
    }

    private func observeSearchQuery() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.fetchSuggestions(for: query)
            }
            .store(in: &cancellables)
    }

    func fetchSuggestions(for query: String) {
        guard !query.isEmpty else {
            suggestions = []
            shouldShowSuggestions = false
            return
        }

        let filter = GMSAutocompleteFilter()
        filter.type = .geocode

        let token = GMSAutocompleteSessionToken.init()
        placesClient.findAutocompletePredictions(
            fromQuery: query,
            filter: filter,
            sessionToken: token
        ) { [weak self] results, error in
            DispatchQueue.main.async {
                if let results = results {
                    self?.suggestions = results
                    self?.shouldShowSuggestions = true
                } else {
                    self?.suggestions = []
                    self?.shouldShowSuggestions = false
                }
            }
        }
    }

    func selectSuggestion(_ prediction: GMSAutocompletePrediction) {
        shouldShowSuggestions = false
        searchQuery = prediction.attributedFullText.string
        selectedPlaceName = prediction.attributedFullText.string

        placesClient.fetchPlace(
            fromPlaceID: prediction.placeID,
            placeFields: [.coordinate],
            sessionToken: nil
        ) { [weak self] place, error in
            if let place = place {
                self?.selectedCoordinates = place.coordinate
            }
        }
    }
}
