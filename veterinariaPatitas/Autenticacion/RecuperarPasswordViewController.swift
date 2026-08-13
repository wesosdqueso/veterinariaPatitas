import UIKit
import FirebaseAuth

final class RecuperarPasswordViewController: UIViewController {
    @IBOutlet private weak var correoTextField: UITextField!
    @IBOutlet private weak var enviarButton: UIButton!

    @IBAction private func enviarRecuperacion(_ sender: UIButton) {
        let correo = correoTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !correo.isEmpty else {
            mostrarMensaje("Falta el correo", "Ingresa el correo de tu cuenta.", enfocar: correoTextField)
            return
        }

        cambiarCarga(true, boton: enviarButton)
        Auth.auth().sendPasswordReset(withEmail: correo) { [weak self] error in
            guard let self else { return }
            self.cambiarCarga(false, boton: self.enviarButton)
            if let error {
                self.mostrarErrorFirebase(
                    error,
                    titulo: "No se pudo enviar",
                    campoCorreo: self.correoTextField
                )
                return
            }
            let alerta = UIAlertController(
                title: "Correo enviado",
                message: "Revisa tu bandeja de entrada y sigue el enlace para crear una contraseña nueva.",
                preferredStyle: .alert
            )
            alerta.addAction(UIAlertAction(title: "Aceptar", style: .default) { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            })
            self.present(alerta, animated: true)
        }
    }
}
