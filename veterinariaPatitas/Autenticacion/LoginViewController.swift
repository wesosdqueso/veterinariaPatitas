import UIKit
import FirebaseAuth
import FirebaseFirestore

final class LoginViewController: UIViewController {
    @IBOutlet private weak var correoTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    @IBOutlet private weak var iniciarSesionButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        passwordTextField.isSecureTextEntry = true
    }

    @IBAction private func iniciarSesion(_ sender: UIButton) {
        let correo = correoTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordTextField.text ?? ""
        guard !correo.isEmpty else {
            Alerts.show(on: self, title: "Faltan datos", message: "Ingresa tu correo.") { [weak self] in
                guard let self = self else { return }
                self.correoTextField.becomeFirstResponder()
            }
            return
        }
        guard !password.isEmpty else {
            Alerts.show(on: self, title: "Faltan datos", message: "Ingresa tu contraseña.") { [weak self] in
                guard let self = self else { return }
                self.passwordTextField.becomeFirstResponder()
            }
            return
        }

        iniciarSesionButton.isEnabled = false
        iniciarSesionButton.configuration?.showsActivityIndicator = true
        view.isUserInteractionEnabled = false
        Auth.auth().signIn(withEmail: correo, password: password) { [weak self] resultado, error in
            guard let self = self else { return }
            self.iniciarSesionButton.isEnabled = true
            self.iniciarSesionButton.configuration?.showsActivityIndicator = false
            self.view.isUserInteractionEnabled = true
            if let error = error {
                let correoInvalido = AuthErrorCode(rawValue: (error as NSError).code) == .invalidEmail
                Alerts.show(
                    on: self,
                    title: "No se pudo iniciar sesión",
                    message: error.localizedDescription
                ) { [weak self] in
                    guard let self = self, correoInvalido else { return }
                    self.correoTextField.becomeFirstResponder()
                    self.correoTextField.selectAll(nil)
                }
                return
            }
            guard let usuario = resultado?.user else { return }
            self.asegurarPerfilFirestore(usuario: usuario)
        }
    }

    private func asegurarPerfilFirestore(usuario: User) {
        var datos: [String: Any] = [
            "correo": usuario.email ?? "",
            "actualizadoEn": FieldValue.serverTimestamp()
        ]
        if let nombre = usuario.displayName, !nombre.isEmpty {
            datos["nombre"] = nombre
        }

        Firestore.firestore().collection("usuarios").document(usuario.uid)
            .setData(datos, merge: true) { [weak self] error in
                guard let self else { return }
                if let error {
                    print("No se pudo sincronizar el perfil en Firestore: \(error.localizedDescription)")
                }

                let sceneDelegate = self.view.window?.windowScene?.delegate as! SceneDelegate
                sceneDelegate.mostrarPantallaPrincipal()
            }
    }
}
