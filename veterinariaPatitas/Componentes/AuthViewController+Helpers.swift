import UIKit
import FirebaseAuth

extension UIViewController {
    func mostrarMensaje(
        _ titulo: String,
        _ mensaje: String,
        enfocar campo: UITextField? = nil,
        seleccionarTodo: Bool = false
    ) {
        let alerta = UIAlertController(title: titulo, message: mensaje, preferredStyle: .alert)
        alerta.addAction(UIAlertAction(title: "Aceptar", style: .default) { _ in
            campo?.becomeFirstResponder()
            if seleccionarTodo {
                campo?.selectAll(nil)
            }
        })
        present(alerta, animated: true)
    }

    func mostrarErrorFirebase(
        _ error: Error,
        titulo: String,
        campoCorreo: UITextField? = nil
    ) {
        let esCorreoInvalido = AuthErrorCode(rawValue: (error as NSError).code) == .invalidEmail
        mostrarMensaje(
            titulo,
            mensajeFirebase(error),
            enfocar: esCorreoInvalido ? campoCorreo : nil,
            seleccionarTodo: esCorreoInvalido
        )
    }

    func mensajeFirebase(_ error: Error) -> String {
        switch AuthErrorCode(rawValue: (error as NSError).code) {
        case .invalidEmail:
            return "El correo no tiene un formato válido."
        case .wrongPassword, .invalidCredential:
            return "El correo o la contraseña son incorrectos."
        case .operationNotAllowed:
            return "El acceso con correo y contraseña todavía no está habilitado en Firebase."
        case .internalError:
            return "Firebase Authentication todavía no está configurado para procesar esta solicitud."
        case .emailAlreadyInUse:
            return "Ya existe una cuenta con este correo."
        case .weakPassword:
            return "La contraseña debe tener al menos 6 caracteres."
        case .userNotFound:
            return "No existe una cuenta con este correo."
        case .networkError:
            return "No se pudo conectar. Revisa tu conexión a internet."
        case .requiresRecentLogin:
            return "Por seguridad, vuelve a iniciar sesión antes de continuar."
        default:
            return error.localizedDescription
        }
    }

    func cambiarCarga(_ cargando: Bool, boton: UIButton) {
        boton.isEnabled = !cargando
        boton.configuration?.showsActivityIndicator = cargando
        view.isUserInteractionEnabled = !cargando
    }

}
