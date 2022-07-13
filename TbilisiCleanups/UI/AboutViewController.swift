import UIKit

final class AboutViewController: UIViewController {

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
            "About",
            comment: "The title of the About screen"
        )
    }

    private func configureTabBar() {
        tabBarItem = UITabBarItem(
            title: NSLocalizedString(
                "About",
                comment: "A tab that opens the About screen"
            ),
            image: UIImage(systemName: "info"),
            selectedImage: nil
        )
    }
}

