import UIKit

final class RazaPickerRowView: UIView {
    let imageView = UIImageView()
    let nombreLabel = UILabel()
    var razaId = ""

    override init(frame: CGRect) {
        super.init(frame: frame)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.tintColor = .systemGreen
        imageView.translatesAutoresizingMaskIntoConstraints = false

        nombreLabel.font = .preferredFont(forTextStyle: .body)
        nombreLabel.adjustsFontForContentSizeCategory = true

        let stack = UIStackView(arrangedSubviews: [imageView, nombreLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 48),
            imageView.heightAnchor.constraint(equalToConstant: 48),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) no está implementado")
    }
}
