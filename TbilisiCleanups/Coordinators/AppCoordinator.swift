import UIKit

final class AppCoordinator {

    func makeRootViewController() -> some UIViewController {
        let tabBarVC = UITabBarController()
        let viewControllers: [UIViewController] = [
            NewReportViewController(),
            MyReportsViewController(),
            AboutViewController()
        ].map { embeddedInNavigationController($0) }
        tabBarVC.setViewControllers(viewControllers, animated: false)
        tabBarVC.selectedIndex = 0
        return tabBarVC
    }

    private func embeddedInNavigationController(
        _ controller: UIViewController
    ) -> UIViewController {
        let navController = UINavigationController(rootViewController: controller)
        navController.navigationBar.prefersLargeTitles = true
        return navController
    }
}
