import UIKit
import FirebaseAuth
import FirebaseFirestore

final class SolicitudesAdopcionViewController: UIViewController {
    private struct Solicitud {
        let id: String
        let mascota: String
        let detalles: String
        let imagenNombre: String
        let estado: String
    }

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var emptyLabel: UILabel!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    private var solicitudes: [Solicitud] = []
    private var listener: ListenerRegistration?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Solicitudes"
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SolicitudCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 82
        escucharSolicitudes()
    }

    deinit {
        listener?.remove()
    }

    private func escucharSolicitudes() {
        guard let uid = Auth.auth().currentUser?.uid else {
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            return
        }
        activityIndicator.startAnimating()
        emptyLabel.isHidden = true
        listener = Firestore.firestore().collection("usuarios").document(uid)
            .collection("solicitudesAdopcion")
            .order(by: "creadoEn", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                if let error {
                    self.mostrarError(error.localizedDescription)
                    return
                }
                self.solicitudes = snapshot?.documents.compactMap { documento in
                    let datos = documento.data()
                    guard let nombre = datos["mascotaNombre"] as? String else { return nil }
                    return Solicitud(
                        id: documento.documentID,
                        mascota: nombre,
                        detalles: datos["detalles"] as? String ?? "",
                        imagenNombre: datos["imagenNombre"] as? String ?? "",
                        estado: datos["estado"] as? String ?? "Pendiente"
                    )
                } ?? []
                self.emptyLabel.isHidden = !self.solicitudes.isEmpty
                self.tableView.reloadData()
            }
    }

    private func confirmarCancelacion(_ solicitud: Solicitud) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let alerta = UIAlertController(
            title: "Cancelar solicitud",
            message: "¿Deseas cancelar tu solicitud para adoptar a \(solicitud.mascota)?",
            preferredStyle: .alert
        )
        alerta.addAction(UIAlertAction(title: "Conservar", style: .cancel))
        alerta.addAction(UIAlertAction(title: "Cancelar solicitud", style: .destructive) { [weak self] _ in
            Firestore.firestore().collection("usuarios").document(uid)
                .collection("solicitudesAdopcion").document(solicitud.id)
                .updateData(["estado": "Cancelada"]) { error in
                    if let error { self?.mostrarError(error.localizedDescription) }
                }
        })
        present(alerta, animated: true)
    }

    private func mostrarError(_ mensaje: String) {
        let alerta = UIAlertController(title: "No se pudo completar", message: mensaje, preferredStyle: .alert)
        alerta.addAction(UIAlertAction(title: "Aceptar", style: .default))
        present(alerta, animated: true)
    }
}

extension SolicitudesAdopcionViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        solicitudes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let solicitud = solicitudes[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "SolicitudCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = solicitud.mascota
        content.secondaryText = "\(solicitud.detalles) · \(solicitud.estado)"
        content.secondaryTextProperties.numberOfLines = 0
        content.image = UIImage(named: solicitud.imagenNombre) ?? UIImage(systemName: "heart.fill")
        content.imageProperties.maximumSize = CGSize(width: 58, height: 58)
        content.imageProperties.cornerRadius = 10
        cell.contentConfiguration = content
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let solicitud = solicitudes[indexPath.row]
        guard solicitud.estado == "Pendiente" else { return nil }
        let accion = UIContextualAction(style: .destructive, title: "Cancelar") { [weak self] _, _, completion in
            self?.confirmarCancelacion(solicitud)
            completion(true)
        }
        accion.image = UIImage(systemName: "xmark.circle")
        return UISwipeActionsConfiguration(actions: [accion])
    }
}
