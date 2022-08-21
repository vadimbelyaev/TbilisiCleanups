import MapKit
import NukeUI
import SwiftUI
import UniformTypeIdentifiers

struct ReportDetailsView: View {
    let report: Report
    @State private var mapRegion: MKCoordinateRegion

    init(report: Report) {
        self.report = report
        self._mapRegion = .init(initialValue: MKCoordinateRegion(
            center: report.location.clLocationCoordinate2D,
            latitudinalMeters: 500,
            longitudinalMeters: 500
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Location")
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                Text(report.description ?? "No description")
                    .padding(.horizontal)
                ReportStatusBadge(status: report.status)
                    .padding(.horizontal)
                ReportLocationMapRepresentable(
                    region: $mapRegion,
                    location: .constant(report.location.clLocationCoordinate2D),
                    isInteractive: false
                )
                .frame(height: 320)
                CopyCoordinatesButton(coordinates: machineReadableCoordinates)
                    .padding(.horizontal)

                openInGoogleMapsButton
                    .padding(.horizontal)

                Text("Photos and videos")
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding(.top)
                    .padding(.horizontal)
                ForEach(report.videos) { video in
                    AVPlayerRepresentable(url: video.url)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(16 / 9, contentMode: .fill)
                }
                ForEach(report.photos) { photo in
                    NukeUI.LazyImage(url: photo.previewImageURL, resizingMode: .aspectFit)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(4 / 3, contentMode: .fill)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Report Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var openInGoogleMapsButton: some View {
        Button {
            var components = URLComponents(string: "https://www.google.com/maps/search/?api=1")
            components?.queryItems?.append(.init(name: "query", value: machineReadableCoordinates))
            guard let url = components?.url,
                  UIApplication.shared.canOpenURL(url)
            else {
                return
            }
            UIApplication.shared.open(url)
        } label: {
            Label("Open in Google Maps", systemImage: "globe")
        }
    }

    private var machineReadableCoordinates: String {
        String(format: "%f,%f", report.location.lat, report.location.lon)
    }
}

private struct CopyCoordinatesButton: View {
    let coordinates: String

    @State private var copied = false

    var body: some View {
        Button {
            UIPasteboard.general.items = [
                [UTType.plainText.identifier: coordinates]
            ]
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation {
                copied = true
            }
            withAnimation(.default.delay(3)) {
                copied = false
            }
        } label: {
            Label(coordinates, systemImage: "doc.on.doc")
        }
        .disabled(copied)
        .opacity(copied ? 0 : 1)
        .overlay(
            HStack {
                Label("Copied!", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .opacity(copied ? 1 : 0)
                Spacer()
            }
        )
    }
}