import MapKit
import NukeUI
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
        marker.leftCalloutAccessoryView = {
            let imageView = LazyImageView(frame: .init(origin: .zero, size: CGSize(width: 40, height: 40)))
            imageView.url = report.mainPreviewImageURL
            imageView.layer.cornerRadius = 4
            imageView.clipsToBounds = true
            return imageView
        }()
        marker.rightCalloutAccessoryView = {
            let button = UIButton(type: .detailDisclosure)
            let action = UIAction { [weak self] _ in
                self?.placeDetailsTapAction(report)
            }
            button.addAction(action, for: .touchUpInside)
            return button
        }()
        marker.detailCalloutAccessoryView = {
            let label = UILabel()
            label.text = report.status.localizedDescription
            label.font = .preferredFont(forTextStyle: .footnote)
            label.textColor = report.status.uiColor
            return label
        }()
        marker.displayPriority = .required
        marker.canShowCallout = true
        marker.animatesWhenAdded = false
        marker.titleVisibility = .hidden
        marker.markerTintColor = report.status.uiColor
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
        guard let description = report.description,
              !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return L10n.PlacesMap.noDescription
        }
        return description
    }

    var subtitle: String? {
        nil
    }
}
