import UIKit
import FirebaseAuth
import FirebaseFirestore

final class MisCitasViewController: UIViewController {
    private struct Cita {
        let id: String
        let servicio: String
        let mascota: String
        let fecha: Date
        let estado: String
    }

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var emptyLabel: UILabel!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    private var citas: [Cita] = []
    private var listener: ListenerRegistration?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Mis citas"
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CitaCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 68

        escucharCitas()
    }

    deinit {
        listener?.remove()
    }

    private func escucharCitas() {
        guard let uid = Auth.auth().currentUser?.uid else {
            mostrarError("Debes iniciar sesión para consultar tus citas.")
            return
        }
        activityIndicator.startAnimating()
        emptyLabel.isHidden = true
        listener = Firestore.firestore()
            .collection("usuarios").document(uid)
            .collection("citas")
            .order(by: "fecha", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                if let error {
                    self.mostrarError("No se pudieron cargar las citas. \(error.localizedDescription)")
                    return
                }
                self.citas = snapshot?.documents.compactMap { documento in
                    let datos = documento.data()
                    guard let servicio = datos["servicio"] as? String,
                          let mascota = datos["mascotaNombre"] as? String,
                          let fecha = datos["fecha"] as? Timestamp else { return nil }
                    return Cita(
                        id: documento.documentID,
                        servicio: servicio,
                        mascota: mascota,
                        fecha: fecha.dateValue(),
                        estado: datos["estado"] as? String ?? "Pendiente"
                    )
                } ?? []
                self.emptyLabel.isHidden = !self.citas.isEmpty
                self.tableView.reloadData()
            }
    }

    private func cancelar(_ cita: Cita) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let alert = UIAlertController(
            title: "Cancelar cita",
            message: "¿Deseas cancelar la cita de \(cita.mascota) para \(cita.servicio)?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Conservar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Cancelar cita", style: .destructive) { [weak self] _ in
            Firestore.firestore().collection("usuarios").document(uid).collection("citas")
                .document(cita.id).updateData(["estado": "Cancelada"]) { error in
                    if let error { self?.mostrarError(error.localizedDescription) }
                }
        })
        present(alert, animated: true)
    }

    private func mostrarError(_ mensaje: String) {
        let alert = UIAlertController(title: "No se pudo completar", message: mensaje, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Aceptar", style: .default))
        present(alert, animated: true)
    }
}

extension MisCitasViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        citas.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cita = citas[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "CitaCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = cita.servicio
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_PE")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        content.secondaryText = "\(cita.mascota) · \(formatter.string(from: cita.fecha)) · \(cita.estado)"
        content.secondaryTextProperties.numberOfLines = 0
        content.image = UIImage(systemName: cita.estado == "Cancelada" ? "calendar.badge.minus" : "calendar.badge.clock")
        content.imageProperties.tintColor = cita.estado == "Cancelada" ? .systemRed : .systemGreen
        cell.contentConfiguration = content
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let cita = citas[indexPath.row]
        guard cita.estado != "Cancelada", cita.fecha > Date() else { return nil }
        let accion = UIContextualAction(style: .destructive, title: "Cancelar") { [weak self] _, _, completion in
            self?.cancelar(cita)
            completion(true)
        }
        accion.image = UIImage(systemName: "calendar.badge.minus")
        return UISwipeActionsConfiguration(actions: [accion])
    }
}
