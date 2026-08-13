import UIKit
import FirebaseAuth
import FirebaseFirestore

private struct Mascota {
    let id: String
    let nombre: String
    let especie: String
    let raza: String
    let sexo: String
    let peso: Double?

    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        guard let nombre = data["nombre"] as? String,
              let especie = data["especie"] as? String,
              let raza = data["raza"] as? String,
              let sexo = data["sexo"] as? String else { return nil }
        id = document.documentID
        self.nombre = nombre
        self.especie = especie
        self.raza = raza
        self.sexo = sexo
        peso = data["peso"] as? Double
    }
}

final class MisMascotasViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var emptyLabel: UILabel!
    private var mascotas: [Mascota] = []
    private var listener: ListenerRegistration?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(registrarMascota)
        )

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MascotaCell")
        escucharMascotas()
    }

    deinit {
        listener?.remove()
    }

    private func escucharMascotas() {
        guard let uid = Auth.auth().currentUser?.uid else {
            mostrarError("Debes iniciar sesión para ver tus mascotas.")
            return
        }
        activityIndicator.startAnimating()
        emptyLabel.isHidden = true
        listener = Firestore.firestore()
            .collection("usuarios").document(uid)
            .collection("mascotas")
            .order(by: "creadoEn", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                if let error {
                    self.mostrarError("No se pudieron cargar las mascotas. \(error.localizedDescription)")
                    return
                }
                self.mascotas = snapshot?.documents.compactMap { Mascota(document: $0) } ?? []
                self.emptyLabel.isHidden = !self.mascotas.isEmpty
                self.tableView.reloadData()
            }
    }

    @objc private func registrarMascota() {
        navigationController?.pushViewController(RegistrarMascotaViewController(), animated: true)
    }

    private func mostrarError(_ mensaje: String) {
        let alert = UIAlertController(title: "No se pudo completar", message: mensaje, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Aceptar", style: .default))
        present(alert, animated: true)
    }
}

extension MisMascotasViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        mascotas.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let mascota = mascotas[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "MascotaCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = mascota.nombre
        let peso = mascota.peso.map { " · \(String(format: "%.1f", $0)) kg" } ?? ""
        content.secondaryText = "\(mascota.especie) · \(mascota.raza) · \(mascota.sexo)\(peso)"
        content.secondaryTextProperties.numberOfLines = 0
        content.image = UIImage(systemName: mascota.especie == "Gato" ? "cat.fill" : "pawprint.fill")
        content.imageProperties.tintColor = .systemGreen
        cell.contentConfiguration = content
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let mascota = mascotas[indexPath.row]
        let eliminar = UIContextualAction(style: .destructive, title: "Eliminar") { [weak self] _, _, completion in
            guard let self, let uid = Auth.auth().currentUser?.uid else {
                completion(false)
                return
            }
            Firestore.firestore().collection("usuarios").document(uid).collection("mascotas")
                .document(mascota.id).delete { [weak self] error in
                    guard let self else {
                        completion(false)
                        return
                    }
                    if let error { self.mostrarError(error.localizedDescription) }
                    completion(error == nil)
                }
        }
        eliminar.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [eliminar])
    }
}

final class RegistrarMascotaViewController: UIViewController {
    private let nombreField = UITextField()
    private let especieControl = UISegmentedControl(items: ["Perro", "Gato", "Otro"])
    private let razaField = UITextField()
    private let sexoControl = UISegmentedControl(items: ["Macho", "Hembra"])
    private let nacimientoPicker = UIDatePicker()
    private let pesoField = UITextField()
    private let guardarButton = UIButton(configuration: .filled())

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Registrar mascota"
        view.backgroundColor = .systemGroupedBackground
        configurarFormulario()
    }

    private func configurarFormulario() {
        nombreField.placeholder = "Nombre"
        razaField.placeholder = "Raza (por ejemplo, mestizo)"
        pesoField.placeholder = "Peso en kg (opcional)"
        pesoField.keyboardType = .decimalPad
        [nombreField, razaField, pesoField].forEach {
            $0.borderStyle = .roundedRect
            $0.autocorrectionType = .no
        }
        especieControl.selectedSegmentIndex = 0
        sexoControl.selectedSegmentIndex = 0
        nacimientoPicker.datePickerMode = .date
        nacimientoPicker.preferredDatePickerStyle = .compact
        nacimientoPicker.maximumDate = Date()

        guardarButton.configuration?.title = "Guardar mascota"
        guardarButton.configuration?.baseBackgroundColor = .systemGreen
        guardarButton.addTarget(self, action: #selector(guardar), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [
            etiqueta("Nombre"), nombreField,
            etiqueta("Especie"), especieControl,
            etiqueta("Raza"), razaField,
            etiqueta("Sexo"), sexoControl,
            etiqueta("Fecha de nacimiento"), nacimientoPicker,
            etiqueta("Peso"), pesoField,
            guardarButton
        ])
        stack.axis = .vertical
        stack.spacing = 10
        stack.setCustomSpacing(20, after: nombreField)
        stack.setCustomSpacing(20, after: especieControl)
        stack.setCustomSpacing(20, after: razaField)
        stack.setCustomSpacing(20, after: sexoControl)
        stack.setCustomSpacing(20, after: nacimientoPicker)

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
            guardarButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func etiqueta(_ texto: String) -> UILabel {
        let label = UILabel()
        label.text = texto
        label.font = .preferredFont(forTextStyle: .headline)
        return label
    }

    @objc private func guardar() {
        let nombre = nombreField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let raza = razaField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let pesoTexto = pesoField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let peso = Double(pesoTexto.replacingOccurrences(of: ",", with: "."))

        guard !nombre.isEmpty else { return mostrarValidacion("Ingresa el nombre de tu mascota.", campo: nombreField) }
        guard !raza.isEmpty else { return mostrarValidacion("Ingresa la raza de tu mascota.", campo: razaField) }
        guard pesoTexto.isEmpty || (peso != nil && peso! > 0) else {
            return mostrarValidacion("Ingresa un peso válido mayor que cero.", campo: pesoField)
        }
        guard let uid = Auth.auth().currentUser?.uid else {
            return mostrarValidacion("Tu sesión terminó. Vuelve a iniciar sesión.")
        }

        guardarButton.isEnabled = false
        guardarButton.configuration?.showsActivityIndicator = true
        var datos: [String: Any] = [
            "nombre": nombre,
            "especie": especieControl.titleForSegment(at: especieControl.selectedSegmentIndex) ?? "Otro",
            "raza": raza,
            "sexo": sexoControl.titleForSegment(at: sexoControl.selectedSegmentIndex) ?? "Macho",
            "fechaNacimiento": Timestamp(date: nacimientoPicker.date),
            "creadoEn": FieldValue.serverTimestamp()
        ]
        if let peso { datos["peso"] = peso }

        Firestore.firestore().collection("usuarios").document(uid).collection("mascotas")
            .addDocument(data: datos) { [weak self] error in
                guard let self else { return }
                self.guardarButton.isEnabled = true
                self.guardarButton.configuration?.showsActivityIndicator = false
                if let error {
                    self.mostrarValidacion("No se pudo guardar la mascota. \(error.localizedDescription)")
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
            }
    }

    private func mostrarValidacion(_ mensaje: String, campo: UITextField? = nil) {
        let alert = UIAlertController(title: "Revisa los datos", message: mensaje, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Aceptar", style: .default) { _ in campo?.becomeFirstResponder() })
        present(alert, animated: true)
    }
}
