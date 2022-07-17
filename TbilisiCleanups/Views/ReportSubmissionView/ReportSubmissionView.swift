import SwiftUI

struct ReportSubmissionView: View {

    @EnvironmentObject private var reportService: ReportService

    var body: some View {
        ProgressView()
            .task {
                try? await reportService.submitCurrentDraft()
            }
    }
}

struct ReportSubmissionView_Previews: PreviewProvider {
    static var previews: some View {
        ReportSubmissionView()
    }
}
