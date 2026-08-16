import UIKit
import FirebaseAuth

final class RegistroViewController: UIViewController {
    @IBOutlet private weak var nombreTextField: UITextField!
    @IBOutlet private weak var correoTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    @IBOutlet private weak var confirmarTextField: UITextField!
    @IBOutlet private weak var crearCuentaButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        passwordTextField.isSecureTextEntry = true
        confirmarTextField.isSecureTextEntry = true
    }

    @IBAction private func crearCuenta(_ sender: UIButton) {
        view.endEditing(true)

        let nombre = nombreTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let correo = correoTextField.text?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
        let password = passwordTextField.text ?? ""
        guard !nombre.isEmpty else {
            Alerts.show(on: self, title: "Faltan datos", message: "Ingresa tu nombre.") { [weak self] in
                guard let self = self else { return }
                self.nombreTextField.becomeFirstResponder()
            }
            return
        }
        guard !correo.isEmpty else {
            Alerts.show(on: self, title: "Faltan datos", message: "Ingresa tu correo.") { [weak self] in
                guard let self = self else { return }
                self.correoTextField.becomeFirstResponder()
            }
            return
        }
        guard !password.isEmpty else {
            Alerts.show(on: self, title: "Faltan datos", message: "Ingresa una contraseña.") { [weak self] in
                guard let self = self else { return }
                self.passwordTextField.becomeFirstResponder()
            }
            return
        }
        guard let confirmacion = confirmarTextField.text, !confirmacion.isEmpty else {
            Alerts.show(on: self, title: "Faltan datos", message: "Confirma tu contraseña.") { [weak self] in
                guard let self = self else { return }
                self.confirmarTextField.becomeFirstResponder()
            }
            return
        }
        guard password.count >= 6 else {
            Alerts.show(on: self, title: "Contraseña corta", message: "Usa al menos 6 caracteres.") { [weak self] in
                guard let self = self else { return }
                self.passwordTextField.becomeFirstResponder()
                self.passwordTextField.selectAll(nil)
            }
            return
        }
        guard password == confirmacion else {
            Alerts.show(on: self, title: "Contraseñas diferentes", message: "Las contraseñas deben coincidir.") { [weak self] in
                guard let self = self else { return }
                self.confirmarTextField.becomeFirstResponder()
                self.confirmarTextField.selectAll(nil)
            }
            return
        }

        registrarUsuario(nombre: nombre, correo: correo, password: password)
    }

    private func registrarUsuario(nombre: String, correo: String, password: String) {
        crearCuentaButton.isEnabled = false
        crearCuentaButton.configuration?.showsActivityIndicator = true

        Auth.auth().createUser(withEmail: correo, password: password) { [weak self] resultado, error in
            guard let self = self else { return }

            if let error = error {
                self.crearCuentaButton.isEnabled = true
                self.crearCuentaButton.configuration?.showsActivityIndicator = false
                let correoInvalido = AuthErrorCode(rawValue: (error as NSError).code) == .invalidEmail
                Alerts.show(
                    on: self,
                    title: "No se pudo crear la cuenta",
                    message: error.localizedDescription
                ) { [weak self] in
                    guard let self = self, correoInvalido else { return }
                    self.correoTextField.becomeFirstResponder()
                    self.correoTextField.selectAll(nil)
                }
                return
            }

            guard let usuario = resultado?.user else {
                self.crearCuentaButton.isEnabled = true
                self.crearCuentaButton.configuration?.showsActivityIndicator = false
                Alerts.show(
                    on: self,
                    title: "No se pudo completar el registro",
                    message: "Firebase creó la sesión, pero no devolvió los datos del usuario."
                )
                return
            }

            self.guardarNombre(nombre, para: usuario)
        }
    }

    private func guardarNombre(_ nombre: String, para usuario: User) {
        let cambio = usuario.createProfileChangeRequest()
        cambio.displayName = nombre
        cambio.commitChanges { error in
            if let error = error {
                print("No se pudo actualizar el nombre del perfil: \(error.localizedDescription)")
            }

            let sceneDelegate = self.view.window?.windowScene?.delegate as! SceneDelegate
            sceneDelegate.mostrarPantallaPrincipal()
        }
    }
}
