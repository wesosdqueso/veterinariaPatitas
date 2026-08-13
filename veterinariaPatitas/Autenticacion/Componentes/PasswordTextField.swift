import UIKit

@IBDesignable
final class PasswordTextField: UITextField {
    private let visibilityButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureVisibilityButton()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureVisibilityButton()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        configureVisibilityButton()
    }

    private func configureVisibilityButton() {
        isSecureTextEntry = true
        visibilityButton.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        visibilityButton.tintColor = .secondaryLabel
        visibilityButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        rightView = visibilityButton
        rightViewMode = .always
        updateVisibilityIcon()
    }

    @objc private func togglePasswordVisibility() {
        isSecureTextEntry.toggle()
        updateVisibilityIcon()

        // Evita que UIKit mueva el cursor al alternar secureTextEntry.
        if let currentText = text, isFirstResponder {
            text = nil
            insertText(currentText)
        }
    }

    private func updateVisibilityIcon() {
        let symbol = isSecureTextEntry ? "eye" : "eye.slash"
        visibilityButton.setImage(UIImage(systemName: symbol), for: .normal)
        visibilityButton.accessibilityLabel = isSecureTextEntry
            ? "Mostrar contraseña"
            : "Ocultar contraseña"
    }

    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.rightViewRect(forBounds: bounds)
        rect.origin.x -= 6
        return rect
    }
}
