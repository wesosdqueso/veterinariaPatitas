import UIKit
import FirebaseAuth

final class CambiarPasswordViewController: UIViewController {
    @IBOutlet private weak var actualTextField: UITextField!
    @IBOutlet private weak var nuevaTextField: UITextField!
    @IBOutlet private weak var confirmarTextField: UITextField!
    @IBOutlet private weak var guardarButton: UIButton!

    @IBAction private func cambiarPassword(_ sender: UIButton) {
        guard let usuario = Auth.auth().currentUser, let correo = usuario.email else {
            mostrarMensaje("Sesión no disponible", "Vuelve a iniciar sesión.")
            return
        }
        let actual = actualTextField.text ?? ""
        let nueva = nuevaTextField.text ?? ""
        guard !actual.isEmpty else {
            mostrarMensaje("Faltan datos", "Ingresa tu contraseña actual.", enfocar: actualTextField)
            return
        }
        guard !nueva.isEmpty else {
            mostrarMensaje("Faltan datos", "Ingresa una contraseña nueva.", enfocar: nuevaTextField)
            return
        }
        guard nueva.count >= 6 else {
            mostrarMensaje("Contraseña corta", "Usa al menos 6 caracteres.", enfocar: nuevaTextField)
            return
        }
        guard let confirmacion = confirmarTextField.text, !confirmacion.isEmpty else {
            mostrarMensaje("Faltan datos", "Confirma tu nueva contraseña.", enfocar: confirmarTextField)
            return
        }
        guard nueva == confirmacion else {
            mostrarMensaje("Contraseñas diferentes", "La nueva contraseña y su confirmación deben coincidir.", enfocar: confirmarTextField)
            return
        }

        cambiarCarga(true, boton: guardarButton)
        let credencial = EmailAuthProvider.credential(withEmail: correo, password: actual)
        usuario.reauthenticate(with: credencial) { [weak self] _, error in
            guard let self else { return }
            if let error {
                self.cambiarCarga(false, boton: self.guardarButton)
                self.mostrarMensaje("No se pudo verificar", self.mensajeFirebase(error))
                return
            }
            usuario.updatePassword(to: nueva) { [weak self] error in
                guard let self else { return }
                self.cambiarCarga(false, boton: self.guardarButton)
                if let error {
                    self.mostrarMensaje("No se pudo cambiar", self.mensajeFirebase(error))
                    return
                }
                let alerta = UIAlertController(
                    title: "Contraseña actualizada",
                    message: "Ya puedes usar tu nueva contraseña.",
                    preferredStyle: .alert
                )
                alerta.addAction(UIAlertAction(title: "Aceptar", style: .default) { [weak self] _ in
                    self?.navigationController?.popViewController(animated: true)
                })
                self.present(alerta, animated: true)
            }
        }
    }
}
