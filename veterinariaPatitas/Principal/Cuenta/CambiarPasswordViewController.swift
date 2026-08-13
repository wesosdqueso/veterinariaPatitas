import UIKit
import FirebaseAuth

final class CambiarPasswordViewController: UIViewController {
    @IBOutlet private weak var actualTextField: UITextField!
    @IBOutlet private weak var nuevaTextField: UITextField!
    @IBOutlet private weak var confirmarTextField: UITextField!
    @IBOutlet private weak var guardarButton: UIButton!

    @IBAction private func cambiarPassword(_ sender: UIButton) {
        guard let usuario = Auth.auth().currentUser, let correo = usuario.email else {
            let alerta = UIAlertController(title: "Sesión no disponible", message: "Vuelve a iniciar sesión.", preferredStyle: .alert)
            alerta.addAction(UIAlertAction(title: "Aceptar", style: .default))
            present(alerta, animated: true)
            return
        }
        let actual = actualTextField.text ?? ""
        let nueva = nuevaTextField.text ?? ""
        guard !actual.isEmpty else {
            let alerta = UIAlertController(title: "Faltan datos", message: "Ingresa tu contraseña actual.", preferredStyle: .alert)
            alerta.addAction(UIAlertAction(title: "Aceptar", style: .default) { [weak self] _ in
                guard let self else { return }
                self.actualTextField.becomeFirstResponder()
            })
            present(alerta, animated: true)
            return
        }
        guard !nueva.isEmpty else {
            let alerta = UIAlertController(title: "Faltan datos", message: "Ingresa una contraseña nueva.", preferredStyle: .alert)
            alerta.addAction(UIAlertAction(title: "Aceptar", style: .default) { [weak self] _ in
                guard let self else { return }
                self.nuevaTextField.becomeFirstResponder()
            })
            present(alerta, animated: true)
            return
        }
        guard nueva.count >= 6 else {
            let alerta = UIAlertController(title: "Contraseña corta", message: "Usa al menos 6 caracteres.", preferredStyle: .alert)
            alerta.addAction(UIAlertAction(title: "Aceptar", style: .default) { [weak self] _ in
                guard let self else { return }
                self.nuevaTextField.becomeFirstResponder()
            })
            present(alerta, animated: true)
            return
        }
        guard let confirmacion = confirmarTextField.text, !confirmacion.isEmpty else {
            let alerta = UIAlertController(title: "Faltan datos", message: "Confirma tu nueva contraseña.", preferredStyle: .alert)
            alerta.addAction(UIAlertAction(title: "Aceptar", style: .default) { [weak self] _ in
                guard let self else { return }
                self.confirmarTextField.becomeFirstResponder()
            })
            present(alerta, animated: true)
            return
        }
        guard nueva == confirmacion else {
            let alerta = UIAlertController(title: "Contraseñas diferentes", message: "La nueva contraseña y su confirmación deben coincidir.", preferredStyle: .alert)
            alerta.addAction(UIAlertAction(title: "Aceptar", style: .default) { [weak self] _ in
                guard let self else { return }
                self.confirmarTextField.becomeFirstResponder()
            })
            present(alerta, animated: true)
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
                let alerta = UIAlertController(
                    title: "No se pudo verificar",
                    message: MensajeErrorFirebase.texto(para: error),
                    preferredStyle: .alert
                )
                alerta.addAction(UIAlertAction(title: "Aceptar", style: .default))
                self.present(alerta, animated: true)
                return
            }
            usuario.updatePassword(to: nueva) { [weak self] error in
                guard let self else { return }
                self.guardarButton.isEnabled = true
                self.guardarButton.configuration?.showsActivityIndicator = false
                self.view.isUserInteractionEnabled = true
                if let error {
                    let alerta = UIAlertController(
                        title: "No se pudo cambiar",
                        message: MensajeErrorFirebase.texto(para: error),
                        preferredStyle: .alert
                    )
                    alerta.addAction(UIAlertAction(title: "Aceptar", style: .default))
                    self.present(alerta, animated: true)
                    return
                }
                let alerta = UIAlertController(
                    title: "Contraseña actualizada",
                    message: "Ya puedes usar tu nueva contraseña.",
                    preferredStyle: .alert
                )
                alerta.addAction(UIAlertAction(title: "Aceptar", style: .default) { [weak self] _ in
                    guard let self else { return }
                    self.navigationController?.popViewController(animated: true)
                })
                self.present(alerta, animated: true)
            }
        }
    }
}
