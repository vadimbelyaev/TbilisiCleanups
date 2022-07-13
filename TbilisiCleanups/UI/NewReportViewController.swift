import UIKit

final class NewReportViewController: UIViewController {

    // MARK: - Lifecycle

    init() {
        super.init(nibName: nil, bundle: nil)
        configureTitle()
        configureTabBar()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()
    }

    // MARK: - Private

    private func configureAppearance() {
        view.backgroundColor = .systemBackground
    }

    private func configureTitle() {
        title = NSLocalizedString(
            "New Report",
            comment: "The title of the New Report screen"
        )
    }

    private func configureTabBar() {
        tabBarItem = UITabBarItem(
            title: NSLocalizedString(
                "New Report",
                comment: "A tab that opens the new report screen"
            ),
            image: UIImage(systemName: "square.and.pencil"),
            selectedImage: nil
        )
    }
}

