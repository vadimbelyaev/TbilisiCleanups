import UIKit

final class MyReportsViewController: UIViewController {

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
            "My Reports",
            comment: "The title of the My Reports screen"
        )
    }

    private func configureTabBar() {
        tabBarItem = UITabBarItem(
            title: NSLocalizedString(
                "My Reports",
                comment: "A tab that opens the My Reports screen"
            ),
            image: UIImage(systemName: "scroll"),
            selectedImage: nil
        )
    }
}

