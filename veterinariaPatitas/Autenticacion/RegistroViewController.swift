import UIKit
import FirebaseAuth

final class RegistroViewController: UIViewController {
    @IBOutlet private weak var nombreTextField: UITextField!
    @IBOutlet private weak var correoTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    @IBOutlet private weak var confirmarTextField: UITextField!
    @IBOutlet private weak var crearCuentaButton: UIButton!

    @IBAction private func crearCuenta(_ sender: UIButton) {
        view.endEditing(true)

        let nombre = nombreTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let correo = correoTextField.text?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
        let password = passwordTextField.text ?? ""
        guard !nombre.isEmpty else {
            let alerta = UIAlertController(title: "Faltan datos", message: "Ingresa tu nombre.", preferredStyle: .alert)
            alerta.addAction(UIAlertAction(title: "Aceptar", style: .default) { [weak self] _ in
                guard let self else { return }
                self.nombreTextField.becomeFirstResponder()
            })
            present(alerta, animated: true)
            return
        }
        guard !correo.isEmpty else {
            let alerta = UIAlertController(title: "Faltan datos", message: "Ingresa tu correo.", preferredStyle: .alert)
            alerta.addAction(UIAlertAction(title: "Aceptar", style: .default) { [weak self] _ in
                guard let self else { return }
                self.correoTextField.becomeFirstResponder()
            })
            present(alerta, animated: true)
            return
        }
        guard !password.isEmpty else {
            let alerta = UIAlertController(title: "Faltan datos", message: "Ingresa una contraseña.", preferredStyle: .alert)
            alerta.addAction(UIAlertAction(title: "Aceptar", style: .default) { [weak self] _ in
                guard let self else { return }
                self.passwordTextField.becomeFirstResponder()
            })
            present(alerta, animated: true)
            return
        }
        guard let confirmacion = confirmarTextField.text, !confirmacion.isEmpty else {
            let alerta = UIAlertController(title: "Faltan datos", message: "Confirma tu contraseña.", preferredStyle: .alert)
            alerta.addAction(UIAlertAction(title: "Aceptar", style: .default) { [weak self] _ in
                guard let self else { return }
                self.confirmarTextField.becomeFirstResponder()
            })
            present(alerta, animated: true)
            return
        }
        guard password.count >= 6 else {
            let alerta = UIAlertController(title: "Contraseña corta", message: "Usa al menos 6 caracteres.", preferredStyle: .alert)
            alerta.addAction(UIAlertAction(title: "Aceptar", style: .default) { [weak self] _ in
                guard let self else { return }
                self.passwordTextField.becomeFirstResponder()
                self.passwordTextField.selectAll(nil)
            })
            present(alerta, animated: true)
            return
        }
        guard password == confirmacion else {
            let alerta = UIAlertController(title: "Contraseñas diferentes", message: "Las contraseñas deben coincidir.", preferredStyle: .alert)
            alerta.addAction(UIAlertAction(title: "Aceptar", style: .default) { [weak self] _ in
                guard let self else { return }
                self.confirmarTextField.becomeFirstResponder()
                self.confirmarTextField.selectAll(nil)
            })
            present(alerta, animated: true)
            return
        }

        registrarUsuario(nombre: nombre, correo: correo, password: password)
    }

    private func registrarUsuario(nombre: String, correo: String, password: String) {
        crearCuentaButton.isEnabled = false
        crearCuentaButton.configuration?.showsActivityIndicator = true

        Auth.auth().createUser(withEmail: correo, password: password) { [weak self] resultado, error in
            guard let self else { return }

            if let error {
                self.crearCuentaButton.isEnabled = true
                self.crearCuentaButton.configuration?.showsActivityIndicator = false
                let correoInvalido = AuthErrorCode(rawValue: (error as NSError).code) == .invalidEmail
                let alerta = UIAlertController(
                    title: "No se pudo crear la cuenta",
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

            guard let usuario = resultado?.user else {
                self.crearCuentaButton.isEnabled = true
                self.crearCuentaButton.configuration?.showsActivityIndicator = false
                let alerta = UIAlertController(
                    title: "No se pudo completar el registro",
                    message: "Firebase creó la sesión, pero no devolvió los datos del usuario.",
                    preferredStyle: .alert
                )
                alerta.addAction(UIAlertAction(title: "Aceptar", style: .default))
                self.present(alerta, animated: true)
                return
            }

            self.guardarNombre(nombre, para: usuario)
        }
    }

    private func guardarNombre(_ nombre: String, para usuario: User) {
        let cambio = usuario.createProfileChangeRequest()
        cambio.displayName = nombre
        cambio.commitChanges { error in
            if let error {
                print("No se pudo actualizar el nombre del perfil: \(error.localizedDescription)")
            }

            let sceneDelegate = self.view.window?.windowScene?.delegate as! SceneDelegate
            sceneDelegate.mostrarPantallaPrincipal()
        }
    }
}
