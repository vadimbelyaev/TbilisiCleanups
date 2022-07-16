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
        print("MODEL INIT")
        locationManager = CLLocationManager()
        locationButtonState = locationManager.authorizationStatus == .restricted ? .restricted : .idle
        super.init()

        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.delegate = self
    }

    func setUpBindings(currentDraft: ReportDraft) {
        self.currentDraft = currentDraft
    }

    func requestLocation() {
        print("MODEL>REQUESTLOCATION")
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationButtonState = .inProgress
            locationManager.startUpdatingLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied:
            locationSettingsAlertPresented = true
        case .restricted:
            break
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
        print("LOCATION MANAGER DID CHANGE STATUS TO \(manager.authorizationStatus)")
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            requestLocation()
        case .notDetermined, .denied, .restricted:
            break
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
        case restricted
        case authorizationDenied
    }
}
