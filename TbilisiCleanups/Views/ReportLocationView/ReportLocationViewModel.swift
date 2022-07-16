import CoreLocation
import MapKit
import os.log
import SwiftUI

final class ReportLocationViewModel: NSObject, ObservableObject {
    @ObservedObject var currentDraft: ReportDraft = .empty
    @Published var locationButtonState: LocationButtonState
    @Published var locationSettingsAlertPresented: Bool = false

    private let locationManager: CLLocationManager

    private let logger = Logger()

    override init() {
        locationManager = CLLocationManager()
        locationButtonState = locationManager.authorizationStatus == .denied ? .authorizationDenied : .idle
        super.init()

        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.delegate = self
    }

    func setUpBindings(currentDraft: ReportDraft) {
        self.currentDraft = currentDraft
    }

    func requestLocation() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationButtonState = .inProgress
            locationManager.startUpdatingLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            locationSettingsAlertPresented = true
        @unknown default:
            assertionFailure()
            break
        }

    }
}

extension ReportLocationViewModel: CLLocationManagerDelegate {
    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        manager.stopUpdatingLocation()
        locationButtonState = .idle
        guard let location = locations.first else { return }
        let meters = location.horizontalAccuracy * 6
        currentDraft.locationRegion = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: meters,
            longitudinalMeters: meters
        )
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        manager.stopUpdatingLocation()
        locationButtonState = .idle
        logger.error("Location manager did fail with error: \(error.localizedDescription, privacy: .public)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined, .authorizedWhenInUse, .authorizedAlways:
            requestLocation()
        case .restricted, .denied:
            locationButtonState = .authorizationDenied
        @unknown default:
            assertionFailure()
            break
        }
    }
}

extension ReportLocationViewModel {
    enum LocationButtonState {
        case idle
        case inProgress
        case authorizationDenied
    }
}
