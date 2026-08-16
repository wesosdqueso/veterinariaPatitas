import UIKit
import FirebaseFirestore

final class MisMascotasViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var emptyLabel: UILabel!

    private let repository = MascotasRepository()
    private lazy var fotosRepository = FotosMascotasRepository()
    private var mascotas: [Mascota] = []
    private var listener: ListenerRegistration?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MascotaCell")
        escucharMascotas()
    }

    deinit {
        listener?.remove()
    }

    private func escucharMascotas() {
        activityIndicator.startAnimating()
        emptyLabel.isHidden = true

        do {
            listener = try repository.escuchar { [weak self] resultado in
                guard let self else { return }
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                switch resultado {
                case .success(let mascotas):
                    self.mascotas = mascotas
                    self.emptyLabel.isHidden = !mascotas.isEmpty
                    self.tableView.reloadData()
                case .failure(let error):
                    self.mostrarError("No se pudieron cargar las mascotas. \(error.localizedDescription)")
                }
            }
        } catch {
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            mostrarError(error.localizedDescription)
        }
    }

    private func mostrarError(_ mensaje: String) {
        Alerts.show(on: self, title: "No se pudo completar", message: mensaje)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showEditarMascota",
              let destino = segue.destination as? RegistrarMascotaViewController,
              let mascota = sender as? Mascota else {
            return
        }
        destino.mascotaEditar = mascota
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
        content.image = fotosRepository.imagen(mascotaId: mascota.id)
            ?? UIImage(systemName: mascota.especie == "Gato" ? "cat.fill" : "pawprint.fill")
        content.imageProperties.maximumSize = CGSize(width: 64, height: 64)
        content.imageProperties.cornerRadius = 12
        content.imageProperties.tintColor = .systemGreen
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "showEditarMascota", sender: mascotas[indexPath.row])
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let mascota = mascotas[indexPath.row]
        let eliminar = UIContextualAction(style: .destructive, title: "Eliminar") { [weak self] _, _, completion in
            guard let self else {
                completion(false)
                return
            }
            do {
                try self.repository.eliminar(id: mascota.id) { [weak self] error in
                    guard let self else {
                        completion(false)
                        return
                    }
                    if let error {
                        self.mostrarError(error.localizedDescription)
                        completion(false)
                        return
                    }
                    do {
                        try self.fotosRepository.eliminar(mascotaId: mascota.id)
                        completion(true)
                    } catch {
                        self.mostrarError("La mascota se eliminó, pero su foto local no pudo borrarse. \(error.localizedDescription)")
                        completion(true)
                    }
                }
            } catch {
                self.mostrarError(error.localizedDescription)
                completion(false)
            }
        }
        eliminar.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [eliminar])
    }
}
