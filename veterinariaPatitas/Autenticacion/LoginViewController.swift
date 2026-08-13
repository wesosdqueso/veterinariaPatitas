import UIKit
import FirebaseAuth

final class LoginViewController: UIViewController {
    @IBOutlet private weak var correoTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    @IBOutlet private weak var iniciarSesionButton: UIButton!

    @IBAction private func iniciarSesion(_ sender: UIButton) {
        let correo = correoTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordTextField.text ?? ""
        guard !correo.isEmpty else {
            mostrarMensaje("Faltan datos", "Ingresa tu correo.", enfocar: correoTextField)
            return
        }
        guard !password.isEmpty else {
            mostrarMensaje("Faltan datos", "Ingresa tu contraseña.", enfocar: passwordTextField)
            return
        }

        cambiarCarga(true, boton: iniciarSesionButton)
        Auth.auth().signIn(withEmail: correo, password: password) { [weak self] _, error in
            guard let self else { return }
            self.cambiarCarga(false, boton: self.iniciarSesionButton)
            if let error {
                self.mostrarErrorFirebase(
                    error,
                    titulo: "No se pudo iniciar sesión",
                    campoCorreo: self.correoTextField
                )
                return
            }
            AppFlow.showMain()
        }
    }

}
