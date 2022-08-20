import MapKit
import UIKit

final class ReportLocationMapViewController: UIViewController {
    public var region: MKCoordinateRegion {
        didSet {
            if oldValue != region {
                updateRegion()
            }
        }
    }

    public var location: CLLocationCoordinate2D {
        didSet {
            if oldValue != location {
                setOrMoveMarker()
            }
        }
    }

    private let isInteractive: Bool
    private let regionDidChange: ((MKCoordinateRegion) -> Void)?
    private let locationDidChange: ((CLLocationCoordinate2D) -> Void)?

    private let mapView = MKMapView()
    private let tapRecognizer = UITapGestureRecognizer()

    init(
        initialRegion: MKCoordinateRegion,
        initialLocation: CLLocationCoordinate2D,
        isInteractive: Bool,
        regionDidChange: ((MKCoordinateRegion) -> Void)?,
        locationDidChange: ((CLLocationCoordinate2D) -> Void)?
    ) {
        self.region = initialRegion
        self.location = initialLocation
        self.isInteractive = isInteractive
        self.regionDidChange = regionDidChange
        self.locationDidChange = locationDidChange
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
        setOrMoveMarker()
    }

    func setUpMapView() {
        mapView.delegate = self
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "ReportLocation")
        if isInteractive {
            tapRecognizer.addTarget(self, action: #selector(tapHandler(_:)))
            mapView.addGestureRecognizer(tapRecognizer)
        } else {
            mapView.isScrollEnabled = false
            mapView.isZoomEnabled = false
            mapView.isPitchEnabled = false
            mapView.isPitchEnabled = false
        }
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

    func setOrMoveMarker() {
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(MKPlacemark(coordinate: location))
    }

    @objc private func tapHandler(_ recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .ended else { return }
        let touchPoint = recognizer.location(in: mapView)
        location = mapView.convert(touchPoint, toCoordinateFrom: mapView)

        // Communicate the new state back to SwiftUI
        locationDidChange?(location)

        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

extension ReportLocationMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        region = mapView.region
        // Communicate the new state back to SwiftUI
        regionDidChange?(region)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let marker = mapView.dequeueReusableAnnotationView(
            withIdentifier: "ReportLocation",
            for: annotation
        ) as? MKMarkerAnnotationView
        else { return nil }
        marker.animatesWhenAdded = true
        marker.titleVisibility = .hidden
        return marker
    }
}
