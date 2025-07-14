//
//  PlaceSearchViewModel.swift
//  SoulSign
//
//  Created by Marina Dedikova on 09/05/2025.
//
import Foundation
import GooglePlaces
import CoreLocation
import Combine

final class PlaceSearchViewModel: NSObject, ObservableObject {
    @Published var searchText = ""
    @Published var suggestions: [GMSAutocompletePrediction] = []
    @Published var selectedPlaceName: String = ""
    @Published var selectedCoordinates: CLLocationCoordinate2D?

    private let placesClient = GMSPlacesClient.shared()
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        observeSearchText()
    }

    private func observeSearchText() {
        $searchText
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] query in
                guard let self = self, !query.isEmpty else {
                    self?.suggestions = []
                    return
                }
                self.fetchPlacePredictions(for: query)
            }
            .store(in: &cancellables)
    }

    private func fetchPlacePredictions(for query: String) {
        let filter = GMSAutocompleteFilter()
        filter.type = .geocode

        placesClient.findAutocompletePredictions(fromQuery: query, filter: filter, sessionToken: nil) { [weak self] results, error in
            if let error = error {
                print("Autocomplete error: \(error.localizedDescription)")
                return
            }
            self?.suggestions = results ?? []
        }
    }

    func fetchCoordinates(for prediction: GMSAutocompletePrediction) {
        let placeID = prediction.placeID
        let fields: GMSPlaceField = [.coordinate, .name, .formattedAddress]

        placesClient.fetchPlace(fromPlaceID: placeID, placeFields: fields, sessionToken: nil) { [weak self] place, error in
            if let error = error {
                print("Place details error: \(error.localizedDescription)")
                return
            }
            guard let place = place else { return }
            DispatchQueue.main.async {
                self?.selectedCoordinates = place.coordinate
                self?.selectedPlaceName = place.formattedAddress ?? place.name ?? ""
                self?.searchText = self?.selectedPlaceName ?? ""
            }
        }
    }
}

