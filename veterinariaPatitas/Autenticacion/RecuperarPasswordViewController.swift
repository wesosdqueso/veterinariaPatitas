import UIKit
import FirebaseAuth

final class RecuperarPasswordViewController: UIViewController {
    @IBOutlet private weak var correoTextField: UITextField!
    @IBOutlet private weak var enviarButton: UIButton!

    @IBAction private func enviarRecuperacion(_ sender: UIButton) {
        let correo = correoTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !correo.isEmpty else {
            Alerts.show(on: self, title: "Falta el correo", message: "Ingresa el correo de tu cuenta.") { [weak self] in
                guard let self = self else { return }
                self.correoTextField.becomeFirstResponder()
            }
            return
        }

        enviarButton.isEnabled = false
        enviarButton.configuration?.showsActivityIndicator = true
        view.isUserInteractionEnabled = false
        Auth.auth().sendPasswordReset(withEmail: correo) { [weak self] error in
            guard let self else { return }
            self.enviarButton.isEnabled = true
            self.enviarButton.configuration?.showsActivityIndicator = false
            self.view.isUserInteractionEnabled = true
            if let error {
                let correoInvalido = AuthErrorCode(rawValue: (error as NSError).code) == .invalidEmail
                Alerts.show(
                    on: self,
                    title: "No se pudo enviar",
                    message: error.localizedDescription
                ) { [weak self] in
                    guard let self = self, correoInvalido else { return }
                    self.correoTextField.becomeFirstResponder()
                    self.correoTextField.selectAll(nil)
                }
                return
            }
            Alerts.show(
                on: self,
                title: "Correo enviado",
                message: "Revisa tu bandeja de entrada y sigue el enlace para crear una contraseña nueva."
            ) { [weak self] in
                guard let self = self else { return }
                self.dismiss(animated: true)
            }
        }
    }
}
