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
            let alerta = UIAlertController(title: "Faltan datos", message: "Ingresa tu correo.", preferredStyle: .alert)
            alerta.addAction(UIAlertAction(title: "Aceptar", style: .default) { [weak self] _ in
                guard let self else { return }
                self.correoTextField.becomeFirstResponder()
            })
            present(alerta, animated: true)
            return
        }
        guard !password.isEmpty else {
            let alerta = UIAlertController(title: "Faltan datos", message: "Ingresa tu contraseña.", preferredStyle: .alert)
            alerta.addAction(UIAlertAction(title: "Aceptar", style: .default) { [weak self] _ in
                guard let self else { return }
                self.passwordTextField.becomeFirstResponder()
            })
            present(alerta, animated: true)
            return
        }

        iniciarSesionButton.isEnabled = false
        iniciarSesionButton.configuration?.showsActivityIndicator = true
        view.isUserInteractionEnabled = false
        Auth.auth().signIn(withEmail: correo, password: password) { [weak self] _, error in
            guard let self else { return }
            self.iniciarSesionButton.isEnabled = true
            self.iniciarSesionButton.configuration?.showsActivityIndicator = false
            self.view.isUserInteractionEnabled = true
            if let error {
                let correoInvalido = AuthErrorCode(rawValue: (error as NSError).code) == .invalidEmail
                let alerta = UIAlertController(
                    title: "No se pudo iniciar sesión",
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
            let sceneDelegate = self.view.window?.windowScene?.delegate as! SceneDelegate
            sceneDelegate.mostrarPantallaPrincipal()
        }
    }

}
