import UIKit
import FirebaseAuth
import FirebaseFirestore

struct MascotaAdopcion {
    let id: String
    let nombre: String
    let detalles: String
    let imagenNombre: String

    nonisolated init(id: String, nombre: String, detalles: String, imagenNombre: String) {
        self.id = id
        self.nombre = nombre
        self.detalles = detalles
        self.imagenNombre = imagenNombre
    }

    nonisolated init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        guard data["disponible"] as? Bool != false,
              let nombre = data["nombre"] as? String,
              let imagenNombre = data["imagenNombre"] as? String else { return nil }

        let especie = data["especie"] as? String ?? "Mascota"
        let edad = data["edad"] as? String ?? "Edad no indicada"
        let sexo = data["sexo"] as? String ?? "Sexo no indicado"

        id = document.documentID
        self.nombre = nombre
        detalles = data["detalles"] as? String ?? "\(especie) · \(edad) · \(sexo)"
        self.imagenNombre = imagenNombre
    }
}

final class AdopcionViewController: UITableViewController {
    private var mascotas: [MascotaAdopcion] = []
    private var solicitudesActivas: [String: String] = [:]
    private var mascotasCargadas = false
    private var solicitudesCargadas = false
    private var mascotasListener: ListenerRegistration?
    private var solicitudesListener: ListenerRegistration?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MascotaCell")
        mostrarEstado("Cargando mascotas…")
        escucharMascotas()
        escucharSolicitudes()
    }

    deinit {
        mascotasListener?.remove()
        solicitudesListener?.remove()
    }

    private func escucharMascotas() {
        mascotasListener = Firestore.firestore()
            .collection("mascotasAdopcion")
            .order(by: "creadoEn", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                self.mascotasCargadas = true

                if let error {
                    self.mostrarEstado("No se pudieron cargar las mascotas.\n\(error.localizedDescription)")
                    return
                }

                self.mascotas = snapshot?.documents.compactMap { document in
                    MascotaAdopcion(document: document)
                } ?? []
                self.tableView.backgroundView = nil
                if self.mascotas.isEmpty {
                    self.mostrarEstado("No hay mascotas disponibles para adopción.")
                }
                self.tableView.reloadData()
            }
    }

    private func escucharSolicitudes() {
        guard let uid = Auth.auth().currentUser?.uid else {
            solicitudesCargadas = true
            tableView.reloadData()
            return
        }
        solicitudesListener = Firestore.firestore().collection("usuarios").document(uid)
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
        guard mascotasCargadas, solicitudesCargadas else { return }
        let mascota = mascotas[indexPath.row]
        guard solicitudesActivas[mascota.id] == nil else { return }
        performSegue(withIdentifier: "showAdopcionDetalle", sender: mascota)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showAdopcionDetalle",
              let destino = segue.destination as? AdopcionDetalleViewController,
              let mascota = sender as? MascotaAdopcion else { return }
        destino.mascota = mascota
    }

    private func mostrarEstado(_ mensaje: String) {
        let label = UILabel()
        label.text = mensaje
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        tableView.backgroundView = label
    }
}
