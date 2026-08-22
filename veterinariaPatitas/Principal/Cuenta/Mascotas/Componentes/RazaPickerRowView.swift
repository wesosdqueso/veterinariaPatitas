import UIKit

final class RazaPickerRowView: UIView {
    let nombreLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        nombreLabel.font = .preferredFont(forTextStyle: .body)
        nombreLabel.adjustsFontForContentSizeCategory = true
        nombreLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nombreLabel)

        NSLayoutConstraint.activate([
            nombreLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            nombreLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            nombreLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) no está implementado")
    }
}
