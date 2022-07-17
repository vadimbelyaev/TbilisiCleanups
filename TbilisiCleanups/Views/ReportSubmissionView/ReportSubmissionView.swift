import SwiftUI

struct ReportSubmissionView: View {

    @EnvironmentObject private var reportService: ReportService

    @State private var status: SubmissionStatus = .notStarted

    var body: some View {
        statusView
            .navigationTitle("Submitting Report")
            .task {
                status = .inProgress
                do {
                    try await reportService.submitCurrentDraft()
                    status = .succeeded
                } catch {
                    status = .failed(error: error)
                }
            }
    }

    @ViewBuilder
    private var statusView: some View {
        switch status {
        case .notStarted:
            Text("Your report is about to be submitted.")
        case .inProgress:
            VStack(spacing: 24) {
                Text("Submitting your report...")
                ProgressView()
            }
        case .failed(let error):
            ScrollView {
                VStack {
                    Text("Submission failed:")
                        .foregroundColor(.red)
                    TextEditor(text: .constant(fullErrorText(error)))
                        .frame(height: 600)
                }
            }
            .padding(.horizontal)
        case .succeeded:
            Text("Submission succeeded!")
                .foregroundColor(.green)
        }
    }

    private func fullErrorText(_ error: Error) -> String {
        var errorText = ""
        dump(error, to: &errorText)
        return errorText
    }
}

enum SubmissionStatus {
    case notStarted
    case inProgress
    case failed(error: Error)
    case succeeded
}

struct ReportSubmissionView_Previews: PreviewProvider {
    static var previews: some View {
        ReportSubmissionView()
    }
}
