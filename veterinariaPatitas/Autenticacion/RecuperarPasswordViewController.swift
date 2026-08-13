import UIKit
import FirebaseAuth

final class RecuperarPasswordViewController: UIViewController {
    @IBOutlet private weak var correoTextField: UITextField!
    @IBOutlet private weak var enviarButton: UIButton!

    @IBAction private func enviarRecuperacion(_ sender: UIButton) {
        let correo = correoTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !correo.isEmpty else {
            let alerta = UIAlertController(title: "Falta el correo", message: "Ingresa el correo de tu cuenta.", preferredStyle: .alert)
            alerta.addAction(UIAlertAction(title: "Aceptar", style: .default) { [weak self] _ in
                guard let self else { return }
                self.correoTextField.becomeFirstResponder()
            })
            present(alerta, animated: true)
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
                let alerta = UIAlertController(
                    title: "No se pudo enviar",
                    message: MensajeErrorFirebase.texto(para: error),
                    preferredStyle: .alert
                )
                alerta.addAction(UIAlertAction(title: "Aceptar", style: .default) { [weak self] _ in
                    guard let self, correoInvalido else { return }
                    self.correoTextField.becomeFirstResponder()
                    self.correoTextField.selectAll(nil)
                })
                self.present(alerta, animated: true)
                return
            }
            let alerta = UIAlertController(
                title: "Correo enviado",
                message: "Revisa tu bandeja de entrada y sigue el enlace para crear una contraseña nueva.",
                preferredStyle: .alert
            )
            alerta.addAction(UIAlertAction(title: "Aceptar", style: .default) { [weak self] _ in
                guard let self else { return }
                self.dismiss(animated: true)
            })
            self.present(alerta, animated: true)
        }
    }
}
