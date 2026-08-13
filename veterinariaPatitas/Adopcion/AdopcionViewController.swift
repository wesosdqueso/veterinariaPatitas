import UIKit
import FirebaseAuth
import FirebaseFirestore

struct MascotaAdopcion {
    let id: String
    let nombre: String
    let detalles: String
    let imagenNombre: String
}

final class AdopcionViewController: UITableViewController {
    private let mascotas = [
        MascotaAdopcion(id: "toby", nombre: "Toby", detalles: "Perro · 2 años · Macho", imagenNombre: "Alimentacion.jpeg"),
        MascotaAdopcion(id: "luna", nombre: "Luna", detalles: "Gato · 1 año · Hembra", imagenNombre: "patitas_1_4 2.png"),
        MascotaAdopcion(id: "max", nombre: "Max", detalles: "Perro · 3 años · Macho", imagenNombre: "patitas2.png"),
        MascotaAdopcion(id: "simba", nombre: "Simba", detalles: "Gato · 6 meses · Macho", imagenNombre: "Unknown-4.jpeg")
    ]
    private var mascotaSeleccionada: MascotaAdopcion?
    private var solicitudesActivas: [String: String] = [:]
    private var solicitudesCargadas = false
    private var listener: ListenerRegistration?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Adopción"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MascotaCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 88
        escucharSolicitudes()
    }

    deinit {
        listener?.remove()
    }

    private func escucharSolicitudes() {
        guard let uid = Auth.auth().currentUser?.uid else {
            solicitudesCargadas = true
            tableView.reloadData()
            return
        }
        listener = Firestore.firestore().collection("usuarios").document(uid)
            .collection("solicitudesAdopcion")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                self.solicitudesCargadas = true
                if error == nil {
                    self.solicitudesActivas = snapshot?.documents.reduce(into: [:]) { resultado, documento in
                        let estado = documento.data()["estado"] as? String ?? "Pendiente"
                        if estado != "Cancelada" {
                            resultado[documento.documentID] = estado
                        }
                    } ?? [:]
                }
                self.tableView.reloadData()
            }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        mascotas.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let mascota = mascotas[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "MascotaCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = mascota.nombre
        if let estado = solicitudesActivas[mascota.id] {
            content.secondaryText = "\(mascota.detalles) · Solicitud \(estado.lowercased())"
            content.textProperties.color = .secondaryLabel
            content.secondaryTextProperties.color = .tertiaryLabel
        } else {
            content.secondaryText = mascota.detalles
        }
        content.secondaryTextProperties.numberOfLines = 0
        content.image = UIImage(named: mascota.imagenNombre)
        content.imageProperties.maximumSize = CGSize(width: 64, height: 64)
        content.imageProperties.cornerRadius = 12
        cell.contentConfiguration = content
        cell.accessoryType = solicitudesActivas[mascota.id] == nil ? .disclosureIndicator : .checkmark
        cell.tintColor = .systemGreen
        cell.isUserInteractionEnabled = solicitudesCargadas && solicitudesActivas[mascota.id] == nil
        cell.contentView.alpha = cell.isUserInteractionEnabled ? 1 : 0.55
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard solicitudesCargadas else { return }
        let mascota = mascotas[indexPath.row]
        guard solicitudesActivas[mascota.id] == nil else { return }
        mascotaSeleccionada = mascota
        performSegue(withIdentifier: "showAdopcionDetalle", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showAdopcionDetalle",
              let destino = segue.destination as? AdopcionDetalleViewController,
              let mascotaSeleccionada else { return }
        destino.mascota = mascotaSeleccionada
    }
}
