import UIKit
import FirebaseAuth
import FirebaseFirestore

final class AdopcionDetalleViewController: UIViewController {
    var mascota = MascotaAdopcion(id: "mascota", nombre: "Mascota", detalles: "Información no disponible", imagenNombre: "")
    @IBOutlet private weak var mascotaImageView: UIImageView!
    @IBOutlet private weak var detallesLabel: UILabel!
    @IBOutlet private weak var solicitarButton: UIButton!
    private var solicitudFinalizada = false
    private var esperaFirestore: DispatchWorkItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = mascota.nombre
        mascotaImageView.image = UIImage(named: mascota.imagenNombre)
        mascotaImageView.layer.cornerRadius = 20
        detallesLabel.text = mascota.detalles

        solicitarButton.configuration?.title = "Solicitar adopción"
        solicitarButton.configuration?.baseBackgroundColor = .systemGreen
        solicitarButton.addTarget(self, action: #selector(solicitarAdopcion), for: .touchUpInside)

    }

    @objc private func solicitarAdopcion() {
        guard let usuario = Auth.auth().currentUser else {
            mostrarAlerta(titulo: "Sesión finalizada", mensaje: "Vuelve a iniciar sesión para enviar la solicitud.")
            return
        }

        mostrarFormularioContacto(usuario: usuario)
    }

    private func mostrarFormularioContacto(usuario: User, telefonoInicial: String = "") {
        let confirmacion = UIAlertController(
            title: "Solicitar adopción",
            message: "Ingresa un número para que la veterinaria pueda contactarte por la adopción de \(mascota.nombre).",
            preferredStyle: .alert
        )
        confirmacion.addTextField { campo in
            campo.placeholder = "Número de contacto"
            campo.text = telefonoInicial
            campo.keyboardType = .phonePad
            campo.textContentType = .telephoneNumber
        }
        confirmacion.addAction(UIAlertAction(title: "Ahora no", style: .cancel))
        confirmacion.addAction(UIAlertAction(title: "Enviar solicitud", style: .default) { [weak self] _ in
            guard let self else { return }
            let telefono = confirmacion.textFields?.first?.text?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let digitos = telefono.filter(\.isNumber)
            guard (7...15).contains(digitos.count) else {
                let alerta = UIAlertController(
                    title: "Número no válido",
                    message: "Ingresa un número de contacto de 7 a 15 dígitos.",
                    preferredStyle: .alert
                )
                alerta.addAction(UIAlertAction(title: "Corregir", style: .default) { [weak self] _ in
                    self?.mostrarFormularioContacto(usuario: usuario, telefonoInicial: telefono)
                })
                self.present(alerta, animated: true)
                return
            }
            self.guardarSolicitud(usuario: usuario, telefono: telefono)
        })
        present(confirmacion, animated: true)
    }

    private func guardarSolicitud(usuario: User, telefono: String) {
        solicitudFinalizada = false
        solicitarButton.isEnabled = false
        solicitarButton.configuration?.showsActivityIndicator = true

        let referencia = Firestore.firestore()
            .collection("usuarios").document(usuario.uid)
            .collection("solicitudesAdopcion").document(mascota.id)
        let datos: [String: Any] = [
            "mascotaId": mascota.id,
            "mascotaNombre": mascota.nombre,
            "detalles": mascota.detalles,
            "imagenNombre": mascota.imagenNombre,
            "nombreUsuario": usuario.displayName ?? "",
            "correoUsuario": usuario.email ?? "",
            "telefonoContacto": telefono,
            "estado": "Pendiente",
            "creadoEn": FieldValue.serverTimestamp()
        ]

        referencia.setData(datos) { [weak self] error in
            guard let self else { return }
            self.esperaFirestore?.cancel()
            guard !self.solicitudFinalizada else { return }
            if let error {
                self.restaurarBoton()
                self.mostrarAlerta(titulo: "No se pudo enviar", mensaje: error.localizedDescription)
            } else {
                self.solicitudFinalizada = true
                self.mostrarExito(pendiente: false)
            }
        }

        let espera = DispatchWorkItem { [weak self] in
            guard let self, !self.solicitudFinalizada else { return }
            self.solicitudFinalizada = true
            self.mostrarExito(pendiente: true)
        }
        esperaFirestore = espera
        DispatchQueue.main.asyncAfter(deadline: .now() + 8, execute: espera)
    }

    private func restaurarBoton() {
        solicitarButton.isEnabled = true
        solicitarButton.configuration?.showsActivityIndicator = false
    }

    private func mostrarExito(pendiente: Bool) {
        restaurarBoton()
        let extra = pendiente ? " Se sincronizará automáticamente cuando haya conexión." : ""
        let alerta = UIAlertController(
            title: "Solicitud enviada",
            message: "Registramos tu interés en adoptar a \(mascota.nombre). Puedes consultar el estado desde Mi cuenta → Solicitudes de adopción.\(extra)",
            preferredStyle: .alert
        )
        alerta.addAction(UIAlertAction(title: "Aceptar", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alerta, animated: true)
    }

    private func mostrarAlerta(titulo: String, mensaje: String) {
        let alerta = UIAlertController(title: titulo, message: mensaje, preferredStyle: .alert)
        alerta.addAction(UIAlertAction(title: "Aceptar", style: .default))
        present(alerta, animated: true)
    }
}
