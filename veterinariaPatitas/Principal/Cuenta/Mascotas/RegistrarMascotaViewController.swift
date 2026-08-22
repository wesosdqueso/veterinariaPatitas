import UIKit
import PhotosUI
import FirebaseFirestore

final class RegistrarMascotaViewController: UIViewController {
    var mascotaEditar: Mascota?

    private let repository = MascotasRepository()
    private let razasService = RazasPerrosService()
    private let razasGatosService = RazasGatosService()
    private lazy var fotosRepository = FotosMascotasRepository()
    private var imagenSeleccionada: UIImage?
    private var razas: [RazaOpcion] = []
    private var razasPerros: [RazaOpcion] = []
    private var razasGatos: [RazaOpcion] = []
    private var razaPendienteEdicion: String?
    private var razasPerrosCargadas = false
    private var razasGatosCargadas = false
    private var ingresoManualRaza = false

    @IBOutlet private weak var fotoImageView: UIImageView!
    @IBOutlet private weak var nombreField: UITextField!
    @IBOutlet private weak var especieControl: UISegmentedControl!
    @IBOutlet private weak var razaPicker: UIPickerView!
    @IBOutlet private weak var ingresoManualRazaButton: UIButton!
    @IBOutlet private weak var razaField: UITextField!
    @IBOutlet private weak var sexoControl: UISegmentedControl!
    @IBOutlet private weak var nacimientoPicker: UIDatePicker!
    @IBOutlet private weak var pesoField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Guardar",
            style: .prominent,
            target: self,
            action: #selector(guardarDesdeNavegacion)
        )
        nacimientoPicker.preferredDatePickerStyle = .compact
        nacimientoPicker.maximumDate = Date()
        fotoImageView.layer.cornerRadius = 16
        fotoImageView.clipsToBounds = true
        razaPicker.dataSource = self
        razaPicker.delegate = self
        configurarModoEdicion()
        actualizarControlesRaza()
        cargarRazasPerros()
        cargarRazasGatos()
    }

    @IBAction private func cambiarEspecie(_ sender: UISegmentedControl) {
        razaPendienteEdicion = nil
        ingresoManualRaza = false
        razaField.text = ""
        actualizarControlesRaza()
        if !razaPicker.isHidden, !razas.isEmpty {
            razaPicker.selectRow(0, inComponent: 0, animated: false)
            actualizarEntradaManualRaza()
        }
    }

    @IBAction private func alternarIngresoManualRaza(_ sender: UIButton) {
        ingresoManualRaza.toggle()
        actualizarEntradaManualRaza()
        if ingresoManualRaza {
            razaField.becomeFirstResponder()
        }
    }

    @IBAction private func seleccionarFoto(_ sender: UIButton) {
        var configuracion = PHPickerConfiguration(photoLibrary: .shared())
        configuracion.filter = .images
        configuracion.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuracion)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func guardarDesdeNavegacion() {
        validarYGuardar()
    }

    private func validarYGuardar() {
        let nombre = nombreField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let raza = razaSeleccionada()
        let pesoTexto = pesoField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let peso = Double(pesoTexto.replacingOccurrences(of: ",", with: "."))

        guard !nombre.isEmpty else { return mostrarValidacion("Ingresa el nombre de tu mascota.", campo: nombreField) }
        guard !raza.isEmpty else {
            return mostrarValidacion("Ingresa la raza de tu mascota.", campo: razaField)
        }
        guard pesoTexto.isEmpty || (peso != nil && peso! > 0) else {
            return mostrarValidacion("Ingresa un peso válido mayor que cero.", campo: pesoField)
        }

        var datos: [String: Any] = [
            "nombre": nombre,
            "especie": especieControl.titleForSegment(at: especieControl.selectedSegmentIndex) ?? "Otro",
            "raza": raza,
            "sexo": sexoControl.titleForSegment(at: sexoControl.selectedSegmentIndex) ?? "Macho",
            "fechaNacimiento": Timestamp(date: nacimientoPicker.date)
        ]
        if let peso {
            datos["peso"] = peso
        } else if mascotaEditar != nil {
            datos["peso"] = FieldValue.delete()
        }

        if let mascotaEditar {
            datos["actualizadoEn"] = FieldValue.serverTimestamp()
            actualizar(mascotaId: mascotaEditar.id, datos: datos)
        } else {
            datos["creadoEn"] = FieldValue.serverTimestamp()
            registrar(datos)
        }
    }

    private func registrar(_ datos: [String: Any]) {
        cambiarEstadoGuardado(guardando: true)
        do {
            try repository.registrar(datos: datos) { [weak self] resultado in
                guard let self else { return }
                self.cambiarEstadoGuardado(guardando: false)

                switch resultado {
                case .failure(let error):
                    self.mostrarValidacion("No se pudo guardar la mascota. \(error.localizedDescription)")

                case .success(let mascotaId):
                    self.guardarFotoLocal(mascotaId: mascotaId)
                }
            }
        } catch {
            cambiarEstadoGuardado(guardando: false)
            mostrarValidacion(error.localizedDescription)
        }
    }

    private func actualizar(mascotaId: String, datos: [String: Any]) {
        cambiarEstadoGuardado(guardando: true)
        do {
            try repository.actualizar(id: mascotaId, datos: datos) { [weak self] error in
                guard let self else { return }
                self.cambiarEstadoGuardado(guardando: false)
                if let error {
                    self.mostrarValidacion("No se pudo actualizar la mascota. \(error.localizedDescription)")
                } else {
                    self.guardarFotoLocal(mascotaId: mascotaId)
                }
            }
        } catch {
            cambiarEstadoGuardado(guardando: false)
            mostrarValidacion(error.localizedDescription)
        }
    }

    private func cambiarEstadoGuardado(guardando: Bool) {
        navigationItem.rightBarButtonItem?.isEnabled = !guardando
    }

    private func configurarModoEdicion() {
        guard let mascotaEditar else { return }

        title = "Editar mascota"
        nombreField.text = mascotaEditar.nombre
        razaField.text = mascotaEditar.raza
        pesoField.text = mascotaEditar.peso.map { String(format: "%.1f", $0) }
        if let fechaNacimiento = mascotaEditar.fechaNacimiento {
            nacimientoPicker.date = fechaNacimiento
        }
        seleccionarSegmento(titulo: mascotaEditar.especie, en: especieControl)
        seleccionarSegmento(titulo: mascotaEditar.sexo, en: sexoControl)
        razaPendienteEdicion = mascotaEditar.raza

        if let imagen = fotosRepository.imagen(mascotaId: mascotaEditar.id) {
            imagenSeleccionada = imagen
            fotoImageView.image = imagen
        }
    }

    private func cargarRazasPerros() {
        razaPicker.isUserInteractionEnabled = false
        razasService.cargarRazas { [weak self] resultado in
            guard let self else { return }
            self.razaPicker.isUserInteractionEnabled = true

            switch resultado {
            case .success(let razas):
                self.razasPerrosCargadas = true
                self.razasPerros = razas

            case .failure:
                self.razasPerrosCargadas = true
                self.razasPerros = []
            }
            if self.especieSeleccionada == "Perro" {
                self.actualizarControlesRaza()
            }
        }
    }

    private func cargarRazasGatos() {
        razasGatosService.cargarRazas { [weak self] resultado in
            guard let self else { return }
            switch resultado {
            case .success(let razas):
                self.razasGatosCargadas = true
                self.razasGatos = razas
            case .failure:
                self.razasGatosCargadas = true
                self.razasGatos = []
            }
            if self.especieSeleccionada == "Gato" {
                self.actualizarControlesRaza()
            }
        }
    }

    private func seleccionarRazaPendiente() {
        guard especieSeleccionada == "Perro" || especieSeleccionada == "Gato" else {
            razaField.text = razaPendienteEdicion
            return
        }

        if let razaPendienteEdicion,
           let indice = razas.firstIndex(where: {
               $0.nombre.caseInsensitiveCompare(razaPendienteEdicion) == .orderedSame
           }) {
            razaPicker.selectRow(indice, inComponent: 0, animated: false)
        } else if let razaPendienteEdicion {
            ingresoManualRaza = true
            razaField.text = razaPendienteEdicion
        }
        actualizarEntradaManualRaza()
        self.razaPendienteEdicion = nil
    }

    private var especieSeleccionada: String {
        especieControl.titleForSegment(at: especieControl.selectedSegmentIndex) ?? "Otro"
    }

    private func razaSeleccionada() -> String {
        guard especieSeleccionada == "Perro" || especieSeleccionada == "Gato" else {
            return razaField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }

        if ingresoManualRaza {
            return razaField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
        let indice = razaPicker.selectedRow(inComponent: 0)
        guard razas.indices.contains(indice) else { return "" }
        return razas[indice].nombre
    }

    private func actualizarControlesRaza() {
        let usaCatalogo = especieSeleccionada == "Perro" || especieSeleccionada == "Gato"
        razaPicker.isHidden = !usaCatalogo
        ingresoManualRazaButton.isHidden = !usaCatalogo
        if usaCatalogo {
            razas = especieSeleccionada == "Perro" ? razasPerros : razasGatos
            let catalogoCargado = especieSeleccionada == "Perro"
                ? razasPerrosCargadas
                : razasGatosCargadas
            razaPicker.reloadAllComponents()
            razaPicker.isUserInteractionEnabled = catalogoCargado
            if catalogoCargado {
                if razas.isEmpty {
                    ingresoManualRaza = true
                }
                seleccionarRazaPendiente()
            } else {
                razaField.isHidden = true
            }
        } else {
            ingresoManualRaza = true
            razaField.isHidden = false
            if let razaPendienteEdicion {
                razaField.text = razaPendienteEdicion
                self.razaPendienteEdicion = nil
            }
        }
    }

    private func actualizarEntradaManualRaza() {
        let imagen = UIImage(systemName: ingresoManualRaza ? "checkmark.square.fill" : "square")
        ingresoManualRazaButton.configuration?.image = imagen
        razaField.isHidden = !ingresoManualRaza
        razaField.placeholder = "Escribe la raza"
    }

    private func seleccionarSegmento(titulo: String, en control: UISegmentedControl) {
        for indice in 0..<control.numberOfSegments where control.titleForSegment(at: indice) == titulo {
            control.selectedSegmentIndex = indice
            return
        }
    }

    private func guardarFotoLocal(mascotaId: String) {
        guard let imagenSeleccionada else {
            navigationController?.popViewController(animated: true)
            return
        }

        do {
            try fotosRepository.guardar(imagen: imagenSeleccionada, para: mascotaId)
            navigationController?.popViewController(animated: true)
        } catch {
            Alerts.show(
                on: self,
                title: "Mascota guardada",
                message: "La mascota se registró, pero no se pudo guardar su foto local. \(error.localizedDescription)"
            ) { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }

    private func mostrarValidacion(_ mensaje: String, campo: UITextField? = nil) {
        Alerts.show(on: self, title: "Revisa los datos", message: mensaje) {
            campo?.becomeFirstResponder()
        }
    }
}

extension RegistrarMascotaViewController: PHPickerViewControllerDelegate {
    func picker(
        _ picker: PHPickerViewController,
        didFinishPicking results: [PHPickerResult]
    ) {
        picker.dismiss(animated: true)

        guard let proveedor = results.first?.itemProvider,
              proveedor.canLoadObject(ofClass: UIImage.self) else {
            return
        }

        proveedor.loadObject(ofClass: UIImage.self) { [weak self] objeto, error in
            guard error == nil, let imagen = objeto as? UIImage else { return }
            DispatchQueue.main.async {
                self?.imagenSeleccionada = imagen
                self?.fotoImageView.image = imagen
            }
        }
    }
}

extension RegistrarMascotaViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        razas.count
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        56
    }

    func pickerView(
        _ pickerView: UIPickerView,
        viewForRow row: Int,
        forComponent component: Int,
        reusing view: UIView?
    ) -> UIView {
        let fila = (view as? RazaPickerRowView) ?? RazaPickerRowView()
        let raza = razas[row]
        fila.nombreLabel.text = raza.nombre
        return fila
    }

    func pickerView(
        _ pickerView: UIPickerView,
        didSelectRow row: Int,
        inComponent component: Int
    ) {
        actualizarEntradaManualRaza()
    }
}
