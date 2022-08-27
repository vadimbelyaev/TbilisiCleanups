import NukeUI
import SwiftUI

struct UserReportsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var reportService: ReportService

    var body: some View {
        List {
            if appState.userReportsLoadingState == .loading {
                Text("Loading...")
            }
            if appState.userReportsLoadingState == .loaded,
               appState.userReports.isEmpty
            {
                Text("You haven't submitted any reports of littered places yet.")
                Button {
                    appState.selectedTab = .reportStart
                } label: {
                    Text("Submit a report")
                }
                .buttonStyle(.borderless)
            }
            if appState.userReportsLoadingState == .failed {
                Label {
                    Text("Error loading your reports.")
                } icon: {
                    Image(systemName: "exclamationmark.octagon")
                        .foregroundColor(.red)
                }

                Button {
                    Task.detached(priority: .low) {
                        try await reportService.fetchReportsByCurrentUser()
                    }
                } label: {
                    Text("Retry")
                }
                .buttonStyle(.borderless)
            }
            ForEach(appState.userReports) { report in
                reportCell(for: report)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 32, trailing: 0))
            }
        }
        .listStyle(.plain)
        .refreshable {
            try? await reportService.fetchReportsByCurrentUser()
        }
        .navigationTitle("My Reports")
    }

    private func reportCell(for report: Report) -> some View {
        Button {
            appState.userProfileSelectedReportId = report.id
        } label: {
            VStack(alignment: .leading) {
                Text(report.description ?? "No description")
                    .fontWeight(.semibold)
                    .font(.title3)
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal)

                LazyImage(url: report.mainPreviewImageURL)
                    .ignoresSafeArea(.container)
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .overlay(
                        VStack(alignment: .leading) {
                            Spacer()
                            HStack {
                                Text(formatted(report.createdOn))
                                    .font(.footnote)
                                    .padding(EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8))
                                    .background(Material.thickMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                Spacer()
                                ReportStatusBadge(status: report.status)
                            }
                            .padding(4)
                        }
                    )
            }
        }
        .background(
            NavigationLink(tag: report.id, selection: $appState.userProfileSelectedReportId) {
                ReportDetailsView(report: report)
            } label: {
                EmptyView()
            }
            .hidden()
        )
        .buttonStyle(.plain)
        .listRowSeparator(.hidden)
    }

    private static let dateFormatter = RelativeDateTimeFormatter()

    private func formatted(_ date: Date) -> String {
        Self.dateFormatter.localizedString(for: date, relativeTo: .now)
    }
}
