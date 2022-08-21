import SwiftUI

struct ReportStatusBadge: View {
    let status: Report.Status

    var body: some View {
        Text(status.localizedDescription)
            .font(.footnote)
            .foregroundColor(.white)
            .padding(EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8))
            .background(status.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct ReportStatusBadge_Previews: PreviewProvider {
    static var previews: some View {
        ReportStatusBadge(status: .scheduled)
    }
}
