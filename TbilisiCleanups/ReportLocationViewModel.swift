import CoreLocation
import MapKit
import os.log
import SwiftUI

final class ReportLocationViewModel: NSObject, ObservableObject {
    @Binding var currentDraft: ReportDraft

    let locationManager: CLLocationManager

    private let logger = Logger()

    init(currentDraft: Binding<ReportDraft>) {
        locationManager = CLLocationManager()
        _currentDraft = currentDraft
        super.init()

        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
    }
}

extension ReportLocationViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        let meters = location.horizontalAccuracy * 6
        currentDraft.locationRegion = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: meters,
            longitudinalMeters: meters
        )
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger.error("Location manager did fail with error: \(error.localizedDescription, privacy: .public)")
    }
}
