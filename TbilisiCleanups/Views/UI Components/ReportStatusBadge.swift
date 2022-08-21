import SwiftUI

struct ReportStatusBadge: View {
    let status: Report.Status

    var body: some View {
        Text(status.localizedDescription)
            .font(.footnote)
            .foregroundColor(.white)
            .padding(EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8))
            .background(statusLabelBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var statusLabelBackground: Color {
        switch status {
        case .unknown:
            return .gray
        case .rejected:
            return .gray
        case .scheduled:
            return .purple
        case .dirty:
            return .red
        case .clean:
            return .green
        case .moderation:
            return .blue
        }
    }
}

struct ReportStatusBadge_Previews: PreviewProvider {
    static var previews: some View {
        ReportStatusBadge(status: .scheduled)
    }
}
