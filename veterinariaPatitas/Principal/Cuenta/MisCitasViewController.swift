import UIKit
import FirebaseFirestore

final class MisCitasViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var emptyLabel: UILabel!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    private var citas: [Cita] = []
    private var listener: ListenerRegistration?
    private let repository = CitasRepository()
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_PE")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CitaCell")

        escucharCitas()
    }

    deinit {
        listener?.remove()
    }

    private func escucharCitas() {
        activityIndicator.startAnimating()
        emptyLabel.isHidden = true

        do {
            listener = try repository.escuchar { [weak self] resultado in
                guard let self else { return }
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true

                switch resultado {
                case .failure(let error):
                    self.mostrarError("No se pudieron cargar las citas. \(error.localizedDescription)")
                case .success(let citas):
                    self.citas = citas
                    self.emptyLabel.isHidden = !citas.isEmpty
                    self.tableView.reloadData()
                }
            }
        } catch {
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            mostrarError(error.localizedDescription)
        }
    }

    private func cancelar(_ cita: Cita) {
        let alert = UIAlertController(
            title: "Cancelar cita",
            message: "¿Deseas cancelar la cita de \(cita.mascotaNombre) para \(cita.servicio)?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Conservar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Cancelar cita", style: .destructive) { [weak self] _ in
            guard let self else { return }
            do {
                try self.repository.cancelar(id: cita.id) { [weak self] error in
                    guard let self else { return }
                    if let error { self.mostrarError(error.localizedDescription) }
                }
            } catch {
                self.mostrarError(error.localizedDescription)
            }
        })
        present(alert, animated: true)
    }

    private func mostrarError(_ mensaje: String) {
        Alerts.show(on: self, title: "No se pudo completar", message: mensaje)
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
        content.secondaryText = "\(cita.mascotaNombre) · \(Self.dateFormatter.string(from: cita.fecha)) · \(cita.estado.rawValue)"
        content.secondaryTextProperties.numberOfLines = 0
        content.image = UIImage(systemName: cita.estado == .cancelada ? "calendar.badge.minus" : "calendar.badge.clock")
        content.imageProperties.tintColor = cita.estado == .cancelada ? .systemRed : .systemGreen
        cell.contentConfiguration = content
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let cita = citas[indexPath.row]
        guard cita.estado != .cancelada, cita.fecha > Date() else { return nil }
        let accion = UIContextualAction(style: .destructive, title: "Cancelar") { [weak self] _, _, completion in
            guard let self else {
                completion(false)
                return
            }
            self.cancelar(cita)
            completion(true)
        }
        accion.image = UIImage(systemName: "calendar.badge.minus")
        return UISwipeActionsConfiguration(actions: [accion])
    }
}
