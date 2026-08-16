import UIKit

enum Alerts {

    static func show(
        on viewController: UIViewController,
        title: String,
        message: String,
        completion: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        let action = UIAlertAction(
            title: "Aceptar",
            style: .default
        ) { _ in
            completion?()
        }

        alert.addAction(action)
        viewController.present(alert, animated: true)
    }
}
