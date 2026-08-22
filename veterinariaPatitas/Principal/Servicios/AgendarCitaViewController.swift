import UIKit
import FirebaseFirestore

final class AgendarCitaViewController: UIViewController {
    var servicio = "Servicio"
    @IBOutlet private weak var mascotaButton: UIButton!
    @IBOutlet private weak var estadoMascotasLabel: UILabel!
    @IBOutlet private weak var fechaPicker: UIDatePicker!
    @IBOutlet private weak var guardarButton: UIButton!
    private let mascotasRepository = MascotasRepository()
    private let citasRepository = CitasRepository()
    private var mascotas: [Mascota] = []
    private var mascotaSeleccionada: Mascota?
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
        do {
            listener = try mascotasRepository.escuchar { [weak self] resultado in
                guard let self else { return }
                self.mascotaButton.configuration?.showsActivityIndicator = false

                switch resultado {
                case .failure(let error):
                    self.mostrarEstadoSinMascotas("No se pudieron cargar tus mascotas. \(error.localizedDescription)")
                case .success(let mascotas):
                    self.mascotas = mascotas
                    self.mostrarMascotas()
                }
            }
        } catch {
            mostrarEstadoSinMascotas(error.localizedDescription)
        }
    }

    private func mostrarMascotas() {
        guard !mascotas.isEmpty else {
            mostrarEstadoSinMascotas("Primero registra una mascota desde Mi cuenta → Mis mascotas.")
            return
        }

        estadoMascotasLabel.isHidden = true
        mascotaButton.isEnabled = true
        actualizarMenuMascotas()

        if let seleccionada = mascotaSeleccionada,
           !mascotas.contains(where: { $0.id == seleccionada.id }) {
            mascotaSeleccionada = nil
            guardarButton.isEnabled = false
        }

        if mascotaSeleccionada == nil {
            mascotaButton.configuration?.title = "Seleccionar mascota"
            mascotaButton.configuration?.subtitle = nil
            mascotaButton.configuration?.image = UIImage(systemName: "pawprint.fill")
        }
    }

    private func actualizarMenuMascotas() {
        mascotaButton.menu = UIMenu(
            title: "Selecciona una mascota",
            children: mascotas.map { mascota in
                let presentacion = presentacionMascota(mascota)
                return UIAction(
                    title: mascota.nombre,
                    subtitle: presentacion.detalle,
                    image: presentacion.imagen.withRenderingMode(presentacion.tieneFoto ? .alwaysOriginal : .alwaysTemplate),
                    state: mascota.id == mascotaSeleccionada?.id ? .on : .off
                ) { [weak self] _ in
                    guard let self else { return }
                    self.seleccionar(mascota)
                }
            }
        )
        mascotaButton.showsMenuAsPrimaryAction = true
    }

    private func seleccionar(_ mascota: Mascota) {
        let presentacion = presentacionMascota(mascota)
        mascotaSeleccionada = mascota
        mascotaButton.configuration?.title = mascota.nombre
        mascotaButton.configuration?.subtitle = presentacion.detalle
        mascotaButton.configuration?.image = presentacion.imagen.withRenderingMode(
            presentacion.tieneFoto ? .alwaysOriginal : .alwaysTemplate
        )
        mascotaButton.configuration?.imagePlacement = .leading
        mascotaButton.configuration?.imagePadding = 12
        guardarButton.isEnabled = true
        actualizarMenuMascotas()
    }

    private func presentacionMascota(_ mascota: Mascota) -> (detalle: String, imagen: UIImage, tieneFoto: Bool) {
        let peso = mascota.peso.map { " · \(String(format: "%.1f", $0)) kg" } ?? ""
        let foto = fotosRepository.imagen(mascotaId: mascota.id)
        let imagen = foto.map { miniatura($0, tamano: CGSize(width: 44, height: 44)) }
            ?? UIImage(systemName: mascota.especie == "Gato" ? "cat.fill" : "pawprint.fill")
            ?? UIImage()
        return ("\(mascota.especie) · \(mascota.raza) · \(mascota.sexo)\(peso)", imagen, foto != nil)
    }

    private func miniatura(_ imagen: UIImage, tamano: CGSize) -> UIImage {
        guard imagen.size.width > 0, imagen.size.height > 0 else { return UIImage() }

        let escala = max(tamano.width / imagen.size.width, tamano.height / imagen.size.height)
        let tamanoEscalado = CGSize(
            width: imagen.size.width * escala,
            height: imagen.size.height * escala
        )
        let origen = CGPoint(
            x: (tamano.width - tamanoEscalado.width) / 2,
            y: (tamano.height - tamanoEscalado.height) / 2
        )

        let formato = UIGraphicsImageRendererFormat.default()
        formato.opaque = false
        return UIGraphicsImageRenderer(size: tamano, format: formato).image { _ in
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: tamano), cornerRadius: 8).addClip()
            imagen.draw(in: CGRect(origin: origen, size: tamanoEscalado))
        }
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
            Alerts.show(on: self, title: "Falta información", message: "Selecciona una de tus mascotas.")
            return
        }
        guardarButton.isEnabled = false
        guardarButton.configuration?.showsActivityIndicator = true

        do {
            try citasRepository.registrar(
                servicio: servicio,
                mascota: mascota,
                fecha: fechaPicker.date
            ) { [weak self] error in
                guard let self else { return }
                if let error {
                    self.restaurarBotonGuardar()
                    Alerts.show(on: self, title: "No se pudo registrar", message: error.localizedDescription)
                } else {
                    self.mostrarConfirmacion(mascota: mascota.nombre)
                }
            }
        } catch {
            restaurarBotonGuardar()
            Alerts.show(on: self, title: "No se pudo registrar", message: error.localizedDescription)
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
}
