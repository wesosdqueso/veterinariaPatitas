import UIKit
import FirebaseAuth

final class CambiarPasswordViewController: UIViewController {
    @IBOutlet private weak var actualTextField: UITextField!
    @IBOutlet private weak var nuevaTextField: UITextField!
    @IBOutlet private weak var confirmarTextField: UITextField!
    @IBOutlet private weak var guardarButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        actualTextField.isSecureTextEntry = true
        nuevaTextField.isSecureTextEntry = true
        confirmarTextField.isSecureTextEntry = true
    }

    @IBAction private func cambiarPassword(_ sender: UIButton) {
        guard let usuario = Auth.auth().currentUser, let correo = usuario.email else {
            Alerts.show(on: self, title: "Sesión no disponible", message: "Vuelve a iniciar sesión.")
            return
        }
        let actual = actualTextField.text ?? ""
        let nueva = nuevaTextField.text ?? ""
        guard !actual.isEmpty else {
            Alerts.show(on: self, title: "Faltan datos", message: "Ingresa tu contraseña actual.") { [weak self] in
                guard let self = self else { return }
                self.actualTextField.becomeFirstResponder()
            }
            return
        }
        guard !nueva.isEmpty else {
            Alerts.show(on: self, title: "Faltan datos", message: "Ingresa una contraseña nueva.") { [weak self] in
                guard let self = self else { return }
                self.nuevaTextField.becomeFirstResponder()
            }
            return
        }
        guard nueva.count >= 6 else {
            Alerts.show(on: self, title: "Contraseña corta", message: "Usa al menos 6 caracteres.") { [weak self] in
                guard let self = self else { return }
                self.nuevaTextField.becomeFirstResponder()
            }
            return
        }
        guard let confirmacion = confirmarTextField.text, !confirmacion.isEmpty else {
            Alerts.show(on: self, title: "Faltan datos", message: "Confirma tu nueva contraseña.") { [weak self] in
                guard let self = self else { return }
                self.confirmarTextField.becomeFirstResponder()
            }
            return
        }
        guard nueva == confirmacion else {
            Alerts.show(on: self, title: "Contraseñas diferentes", message: "La nueva contraseña y su confirmación deben coincidir.") { [weak self] in
                guard let self = self else { return }
                self.confirmarTextField.becomeFirstResponder()
            }
            return
        }

        guardarButton.isEnabled = false
        guardarButton.configuration?.showsActivityIndicator = true
        view.isUserInteractionEnabled = false
        let credencial = EmailAuthProvider.credential(withEmail: correo, password: actual)
        usuario.reauthenticate(with: credencial) { [weak self] _, error in
            guard let self else { return }
            if let error {
                self.guardarButton.isEnabled = true
                self.guardarButton.configuration?.showsActivityIndicator = false
                self.view.isUserInteractionEnabled = true
                Alerts.show(on: self, title: "No se pudo verificar", message: error.localizedDescription)
                return
            }
            usuario.updatePassword(to: nueva) { [weak self] error in
                guard let self else { return }
                self.guardarButton.isEnabled = true
                self.guardarButton.configuration?.showsActivityIndicator = false
                self.view.isUserInteractionEnabled = true
                if let error {
                    Alerts.show(on: self, title: "No se pudo cambiar", message: error.localizedDescription)
                    return
                }
                Alerts.show(
                    on: self,
                    title: "Contraseña actualizada",
                    message: "Ya puedes usar tu nueva contraseña."
                ) { [weak self] in
                    guard let self = self else { return }
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
}
