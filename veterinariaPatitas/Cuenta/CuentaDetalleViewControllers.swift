import UIKit

class EmptyStateViewController: UIViewController {
    var screenTitle: String { "Detalle" }
    var message: String { "No hay información disponible." }
    var icon: String { "info.circle" }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = screenTitle
        view.backgroundColor = .systemBackground

        let image = UIImageView(image: UIImage(systemName: icon))
        image.tintColor = .systemGreen
        image.contentMode = .scaleAspectFit
        image.heightAnchor.constraint(equalToConstant: 90).isActive = true

        let label = UILabel()
        label.text = message
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [image, label])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
