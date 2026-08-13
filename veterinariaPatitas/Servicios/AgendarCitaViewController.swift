import UIKit
import FirebaseAuth
import FirebaseFirestore

final class AgendarCitaViewController: UIViewController {
    private struct MascotaOpcion {
        let id: String
        let nombre: String
        let detalle: String
    }

    var servicio = "Servicio"
    @IBOutlet private weak var mascotaButton: UIButton!
    @IBOutlet private weak var estadoMascotasLabel: UILabel!
    @IBOutlet private weak var fechaPicker: UIDatePicker!
    @IBOutlet private weak var guardarButton: UIButton!
    private var mascotas: [MascotaOpcion] = []
    private var mascotaSeleccionada: MascotaOpcion?
    private var listener: ListenerRegistration?
    private var guardadoFinalizado = false
    private var esperaFirestore: DispatchWorkItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = servicio

        var mascotaConfiguration = UIButton.Configuration.tinted()
        mascotaConfiguration.title = "Cargando mascotas…"
        mascotaConfiguration.image = UIImage(systemName: "pawprint.fill")
        mascotaConfiguration.imagePadding = 10
        mascotaConfiguration.titleAlignment = .leading
        mascotaConfiguration.cornerStyle = .medium
        mascotaConfiguration.showsActivityIndicator = true
        mascotaButton.configuration = mascotaConfiguration
        mascotaButton.contentHorizontalAlignment = .fill
        mascotaButton.isEnabled = false

        estadoMascotasLabel.isHidden = true

        fechaPicker.datePickerMode = .dateAndTime
        fechaPicker.preferredDatePickerStyle = .compact
        fechaPicker.minimumDate = Date()

        guardarButton.configuration?.title = "Guardar cita"
        guardarButton.configuration?.baseBackgroundColor = .systemGreen
        guardarButton.isEnabled = false
        guardarButton.addTarget(self, action: #selector(guardarCita), for: .touchUpInside)

        escucharMascotas()
    }

    deinit {
        listener?.remove()
    }

    private func escucharMascotas() {
        guard let uid = Auth.auth().currentUser?.uid else {
            mostrarEstadoSinMascotas("Debes iniciar sesión para seleccionar una mascota.")
            return
        }

        listener = Firestore.firestore()
            .collection("usuarios").document(uid)
            .collection("mascotas")
            .order(by: "creadoEn", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                self.mascotaButton.configuration?.showsActivityIndicator = false

                if let error {
                    self.mostrarEstadoSinMascotas("No se pudieron cargar tus mascotas. \(error.localizedDescription)")
                    return
                }

                self.mascotas = snapshot?.documents.compactMap { documento in
                    let datos = documento.data()
                    guard let nombre = datos["nombre"] as? String else { return nil }
                    let especie = datos["especie"] as? String ?? "Mascota"
                    let raza = datos["raza"] as? String ?? "Sin raza"
                    return MascotaOpcion(
                        id: documento.documentID,
                        nombre: nombre,
                        detalle: "\(especie) · \(raza)"
                    )
                } ?? []

                guard !self.mascotas.isEmpty else {
                    self.mostrarEstadoSinMascotas("Primero registra una mascota desde Mi cuenta → Mis mascotas.")
                    return
                }

                self.estadoMascotasLabel.isHidden = true
                self.mascotaButton.isEnabled = true
                self.actualizarMenuMascotas()

                if let seleccionada = self.mascotaSeleccionada,
                   !self.mascotas.contains(where: { $0.id == seleccionada.id }) {
                    self.mascotaSeleccionada = nil
                    self.guardarButton.isEnabled = false
                }

                if self.mascotaSeleccionada == nil {
                    self.mascotaButton.configuration?.title = "Seleccionar mascota"
                }
            }
    }

    private func actualizarMenuMascotas() {
        mascotaButton.menu = UIMenu(
            title: "Selecciona una mascota",
            children: mascotas.map { mascota in
                UIAction(
                    title: mascota.nombre,
                    subtitle: mascota.detalle,
                    image: UIImage(systemName: "pawprint.fill"),
                    state: mascota.id == mascotaSeleccionada?.id ? .on : .off
                ) { [weak self] _ in
                    self?.seleccionar(mascota)
                }
            }
        )
        mascotaButton.showsMenuAsPrimaryAction = true
    }

    private func seleccionar(_ mascota: MascotaOpcion) {
        mascotaSeleccionada = mascota
        mascotaButton.configuration?.title = "\(mascota.nombre) — \(mascota.detalle)"
        guardarButton.isEnabled = true
        actualizarMenuMascotas()
    }

    private func mostrarEstadoSinMascotas(_ mensaje: String) {
        mascotas = []
        mascotaSeleccionada = nil
        mascotaButton.menu = nil
        mascotaButton.configuration?.title = "Sin mascotas disponibles"
        mascotaButton.configuration?.showsActivityIndicator = false
        mascotaButton.isEnabled = false
        guardarButton.isEnabled = false
        estadoMascotasLabel.text = mensaje
        estadoMascotasLabel.isHidden = false
    }

    @objc private func guardarCita() {
        guard let mascota = mascotaSeleccionada else {
            presentAlert(title: "Falta información", message: "Selecciona una de tus mascotas.")
            return
        }
        guard let uid = Auth.auth().currentUser?.uid else {
            presentAlert(title: "Sesión finalizada", message: "Vuelve a iniciar sesión para registrar la cita.")
            return
        }

        guardadoFinalizado = false
        guardarButton.isEnabled = false
        guardarButton.configuration?.showsActivityIndicator = true

        let documento = Firestore.firestore()
            .collection("usuarios").document(uid)
            .collection("citas").document()
        let datos: [String: Any] = [
            "servicio": servicio,
            "mascotaId": mascota.id,
            "mascotaNombre": mascota.nombre,
            "fecha": Timestamp(date: fechaPicker.date),
            "estado": "Pendiente",
            "creadoEn": FieldValue.serverTimestamp()
        ]

        documento.setData(datos) { [weak self] error in
            guard let self else { return }
            self.esperaFirestore?.cancel()
            guard !self.guardadoFinalizado else { return }
            if let error {
                self.restaurarBotonGuardar()
                self.presentAlert(title: "No se pudo registrar", message: error.localizedDescription)
            } else {
                self.guardadoFinalizado = true
                self.mostrarConfirmacion(mascota: mascota.nombre, pendiente: false)
            }
        }

        let espera = DispatchWorkItem { [weak self] in
            guard let self, !self.guardadoFinalizado else { return }
            self.guardadoFinalizado = true
            self.restaurarBotonGuardar()
            self.mostrarConfirmacion(mascota: mascota.nombre, pendiente: true)
        }
        esperaFirestore = espera
        DispatchQueue.main.asyncAfter(deadline: .now() + 8, execute: espera)
    }

    private func restaurarBotonGuardar() {
        guardarButton.isEnabled = mascotaSeleccionada != nil
        guardarButton.configuration?.showsActivityIndicator = false
    }

    private func mostrarConfirmacion(mascota: String, pendiente: Bool) {
        restaurarBotonGuardar()
        let sincronizacion = pendiente
            ? "\nQuedó pendiente de sincronización y se enviará automáticamente cuando haya conexión."
            : ""
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_PE")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let mensaje = "Servicio: \(servicio)\nMascota: \(mascota)\nFecha: \(formatter.string(from: fechaPicker.date))\(sincronizacion)"
        let alert = UIAlertController(title: "Cita registrada", message: mensaje, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Aceptar", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }

    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
