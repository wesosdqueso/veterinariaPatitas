import UIKit
import FirebaseAuth

final class RegistroViewController: UIViewController {
    @IBOutlet private weak var nombreTextField: UITextField!
    @IBOutlet private weak var correoTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    @IBOutlet private weak var confirmarTextField: UITextField!
    @IBOutlet private weak var crearCuentaButton: UIButton!

    @IBAction private func crearCuenta(_ sender: UIButton) {
        let nombre = nombreTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let correo = correoTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordTextField.text ?? ""
        guard !nombre.isEmpty else {
            mostrarMensaje("Faltan datos", "Ingresa tu nombre.", enfocar: nombreTextField)
            return
        }
        guard !correo.isEmpty else {
            mostrarMensaje("Faltan datos", "Ingresa tu correo.", enfocar: correoTextField)
            return
        }
        guard !password.isEmpty else {
            mostrarMensaje("Faltan datos", "Ingresa una contraseña.", enfocar: passwordTextField)
            return
        }
        guard let confirmacion = confirmarTextField.text, !confirmacion.isEmpty else {
            mostrarMensaje("Faltan datos", "Confirma tu contraseña.", enfocar: confirmarTextField)
            return
        }
        guard password == confirmacion else {
            mostrarMensaje("Contraseñas diferentes", "Las contraseñas deben coincidir.", enfocar: confirmarTextField)
            return
        }
        guard password.count >= 6 else {
            mostrarMensaje("Contraseña corta", "Usa al menos 6 caracteres.", enfocar: passwordTextField)
            return
        }

        cambiarCarga(true, boton: crearCuentaButton)
        Auth.auth().createUser(withEmail: correo, password: password) { [weak self] resultado, error in
            guard let self else { return }
            if let error {
                self.cambiarCarga(false, boton: self.crearCuentaButton)
                self.mostrarErrorFirebase(
                    error,
                    titulo: "No se pudo crear la cuenta",
                    campoCorreo: self.correoTextField
                )
                return
            }

            self.cambiarCarga(false, boton: self.crearCuentaButton)
            let cambio = resultado?.user.createProfileChangeRequest()
            cambio?.displayName = nombre
            cambio?.commitChanges { error in
                if let error {
                    print("No se pudo actualizar el nombre del perfil: \(error.localizedDescription)")
                }
            }

            // La cuenta y la sesión ya existen. Guardar el nombre no debe bloquear la navegación.
            AppFlow.showMain()
        }
    }
}
