import UIKit

enum AppFlow {
    private static weak var window: UIWindow?

    static func configure(window: UIWindow) {
        self.window = window
    }

    static func showAuthentication(animated: Bool = true) {
        setRoot(identifier: "AuthNavigationController", animated: animated)
    }

    static func showMain(animated: Bool = true) {
        setRoot(identifier: "MainTabBarController", animated: animated)
    }

    private static func setRoot(identifier: String, animated: Bool) {
        guard let window else { return }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: identifier)

        guard animated else {
            window.rootViewController = controller
            window.makeKeyAndVisible()
            return
        }

        UIView.transition(
            with: window,
            duration: 0.3,
            options: [.transitionCrossDissolve, .allowAnimatedContent],
            animations: { window.rootViewController = controller }
        )
    }
}
