import MapKit
import UIKit

final class PlacesMapViewController: UIViewController {
    public var region: MKCoordinateRegion {
        didSet {
            if oldValue != region {
                updateRegion()
            }
        }
    }

    public var places: [Report] {
        didSet {
            updateAnnotations()
        }
    }

    public var placeDetailsTapAction: (Report) -> Void

    private let mapView = MKMapView()

    init(
        initialRegion: MKCoordinateRegion,
        places: [Report],
        placeDetailsTapAction: @escaping (Report) -> Void
    ) {
        self.region = initialRegion
        self.places = places
        self.placeDetailsTapAction = placeDetailsTapAction
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpMapView()
        setUpLayout()
        updateRegion()
        updateAnnotations()
    }

    func setUpMapView() {
        mapView.delegate = self
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "ReportLocation")
    }

    func setUpLayout() {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func updateRegion() {
        mapView.setRegion(region, animated: false)
    }

    func updateAnnotations() {
        mapView.removeAnnotations(mapView.annotations)
        let annotations = places.map { PlaceAnnotation(report: $0) }
        mapView.addAnnotations(annotations)
    }
}

extension PlacesMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let marker = mapView.dequeueReusableAnnotationView(
            withIdentifier: "ReportLocation",
            for: annotation
        ) as? MKMarkerAnnotationView,
            let placeAnnotation = annotation as? PlaceAnnotation
        else { return nil }
        let report = placeAnnotation.report
        marker.detailCalloutAccessoryView = UIButton(
            configuration: .plain(),
            primaryAction: .init(
                title: "Tap to see details",
                image: UIImage(systemName: "info.circle")?
                    .applyingSymbolConfiguration(
                        .init(font: .preferredFont(forTextStyle: .footnote))
                    ),
                handler: { [weak self] _ in
                    self?.placeDetailsTapAction(report)
                }
            )
        )
        marker.displayPriority = .required
        marker.canShowCallout = true
        marker.animatesWhenAdded = false
        marker.titleVisibility = .hidden
        return marker
    }
}

private final class PlaceAnnotation: NSObject, MKAnnotation {
    let report: Report

    init(report: Report) {
        self.report = report
        super.init()
    }

    var coordinate: CLLocationCoordinate2D {
        report.location.clLocationCoordinate2D
    }

    var title: String? {
        report.description
    }

    var subtitle: String? {
        nil
    }
}
