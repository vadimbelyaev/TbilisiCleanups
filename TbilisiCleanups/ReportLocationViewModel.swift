import CoreLocation
import MapKit
import SwiftUI

final class ReportLocationViewModel: NSObject, ObservableObject {
    @Binding var currentDraft: ReportDraft

    let locationManager: CLLocationManager

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
        print("didUpdateLocations: \(locations)")
        guard let location = locations.first else { return }
        let meters = location.horizontalAccuracy * 6
        currentDraft.locationRegion = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: meters,
            longitudinalMeters: meters
        )
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError: \(error.localizedDescription)")
    }
}
