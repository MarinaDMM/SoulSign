//
//  PlaceSearchViewModel.swift
//  SoulSign
//
import Foundation
import MapKit
import CoreLocation
import Combine

final class PlaceSearchViewModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchText = ""
    @Published var suggestions: [MKLocalSearchCompletion] = []
    @Published var selectedPlaceName: String = ""
    @Published var selectedCoordinates: CLLocationCoordinate2D?

    private let completer = MKLocalSearchCompleter()
    private var cancellables = Set<AnyCancellable>()
    /// Text the view model set itself. Matched by value, so a fast typed change
    /// can't be mistaken for it when the debounce merges events.
    private var programmaticText: String?

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
        observeSearchText()
    }

    private func observeSearchText() {
        $searchText
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] query in
                guard let self else { return }
                if query == self.programmaticText {
                    self.programmaticText = nil
                    return
                }
                self.programmaticText = nil
                // The user is typing a new place, so the old selection no longer applies.
                self.selectedPlaceName = ""
                self.selectedCoordinates = nil
                if query.isEmpty {
                    self.suggestions = []
                    self.completer.cancel()
                } else {
                    self.completer.queryFragment = query
                }
            }
            .store(in: &cancellables)
    }

    /// Starts from an existing place, such as a saved person's birth place,
    /// without running a search for it.
    func prefill(placeName: String, coordinates: CLLocationCoordinate2D?) {
        programmaticText = placeName
        searchText = placeName
        selectedPlaceName = placeName
        selectedCoordinates = coordinates
    }

    func selectSuggestion(_ suggestion: MKLocalSearchCompletion) {
        let display = suggestion.subtitle.isEmpty
            ? suggestion.title
            : "\(suggestion.title), \(suggestion.subtitle)"
        programmaticText = display
        searchText = display
        selectedPlaceName = display
        suggestions = []
        fetchCoordinates(for: suggestion)
    }

    private func fetchCoordinates(for suggestion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: suggestion)
        MKLocalSearch(request: request).start { [weak self] response, error in
            guard let self, let item = response?.mapItems.first else {
                if let error { print("Place lookup error: \(error.localizedDescription)") }
                return
            }
            DispatchQueue.main.async {
                self.selectedCoordinates = item.placemark.coordinate
                let city    = item.placemark.locality ?? item.name ?? ""
                let country = item.placemark.country ?? ""
                self.selectedPlaceName = [city, country].filter { !$0.isEmpty }.joined(separator: ", ")
            }
        }
    }

    // MARK: MKLocalSearchCompleterDelegate

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async { self.suggestions = completer.results }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Autocomplete error: \(error.localizedDescription)")
    }
}
