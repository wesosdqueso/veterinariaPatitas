import UIKit
import FirebaseAuth
import FirebaseFirestore

final class AgendarCitaViewController: UIViewController {
    private struct MascotaOpcion {
        let id: String
        let nombre: String
        let detalle: String
        let imagen: UIImage
        let tieneFoto: Bool
    }

    var servicio = "Servicio"
    @IBOutlet private weak var mascotaButton: UIButton!
    @IBOutlet private weak var estadoMascotasLabel: UILabel!
    @IBOutlet private weak var fechaPicker: UIDatePicker!
    @IBOutlet private weak var guardarButton: UIButton!
    private var mascotas: [MascotaOpcion] = []
    private var mascotaSeleccionada: MascotaOpcion?
    private var listener: ListenerRegistration?
    private lazy var fotosRepository = FotosMascotasRepository()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = servicio

        mascotaButton.configuration?.showsActivityIndicator = true
        fechaPicker.preferredDatePickerStyle = .compact
        fechaPicker.minimumDate = Date()

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
                    let sexo = datos["sexo"] as? String ?? "Sexo no indicado"
                    let peso = (datos["peso"] as? Double)
                        .map { " · \(String(format: "%.1f", $0)) kg" } ?? ""
                    let foto = self.fotosRepository.imagen(mascotaId: documento.documentID)
                    let imagen = foto
                        ?? UIImage(systemName: especie == "Gato" ? "cat.fill" : "pawprint.fill")
                        ?? UIImage()
                    return MascotaOpcion(
                        id: documento.documentID,
                        nombre: nombre,
                        detalle: "\(especie) · \(raza) · \(sexo)\(peso)",
                        imagen: imagen,
                        tieneFoto: foto != nil
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
                    self.mascotaButton.configuration?.subtitle = nil
                    self.mascotaButton.configuration?.image = UIImage(systemName: "pawprint.fill")
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
                    image: mascota.imagen.withRenderingMode(mascota.tieneFoto ? .alwaysOriginal : .alwaysTemplate),
                    state: mascota.id == mascotaSeleccionada?.id ? .on : .off
                ) { [weak self] _ in
                    guard let self else { return }
                    self.seleccionar(mascota)
                }
            }
        )
        mascotaButton.showsMenuAsPrimaryAction = true
    }

    private func seleccionar(_ mascota: MascotaOpcion) {
        mascotaSeleccionada = mascota
        mascotaButton.configuration?.title = mascota.nombre
        mascotaButton.configuration?.subtitle = mascota.detalle
        mascotaButton.configuration?.image = mascota.imagen.withRenderingMode(
            mascota.tieneFoto ? .alwaysOriginal : .alwaysTemplate
        )
        mascotaButton.configuration?.imagePlacement = .leading
        mascotaButton.configuration?.imagePadding = 12
        guardarButton.isEnabled = true
        actualizarMenuMascotas()
    }

    private func mostrarEstadoSinMascotas(_ mensaje: String) {
        mascotas = []
        mascotaSeleccionada = nil
        mascotaButton.menu = nil
        mascotaButton.configuration?.title = "Sin mascotas disponibles"
        mascotaButton.configuration?.subtitle = nil
        mascotaButton.configuration?.image = nil
        mascotaButton.configuration?.showsActivityIndicator = false
        mascotaButton.isEnabled = false
        guardarButton.isEnabled = false
        estadoMascotasLabel.text = mensaje
        estadoMascotasLabel.isHidden = false
    }

    @IBAction private func guardarCita(_ sender: UIButton) {
        guard let mascota = mascotaSeleccionada else {
            presentAlert(title: "Falta información", message: "Selecciona una de tus mascotas.")
            return
        }
        guard let uid = Auth.auth().currentUser?.uid else {
            presentAlert(title: "Sesión finalizada", message: "Vuelve a iniciar sesión para registrar la cita.")
            return
        }

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
            if let error {
                self.restaurarBotonGuardar()
                self.presentAlert(title: "No se pudo registrar", message: error.localizedDescription)
            } else {
                self.mostrarConfirmacion(mascota: mascota.nombre)
            }
        }
    }

    private func restaurarBotonGuardar() {
        guardarButton.isEnabled = mascotaSeleccionada != nil
        guardarButton.configuration?.showsActivityIndicator = false
    }

    private func mostrarConfirmacion(mascota: String) {
        restaurarBotonGuardar()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_PE")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let mensaje = "Servicio: \(servicio)\nMascota: \(mascota)\nFecha: \(formatter.string(from: fechaPicker.date))"
        Alerts.show(on: self, title: "Cita registrada", message: mensaje) { [weak self] in
            guard let self = self else { return }
            self.navigationController?.popViewController(animated: true)
        }
    }

    private func presentAlert(title: String, message: String) {
        Alerts.show(on: self, title: title, message: message)
    }
}
