import UIKit
import FirebaseAuth

final class MiCuentaViewController: UITableViewController {
    private let opciones: [(titulo: String, icono: String, segue: String)] = [
        ("Mis mascotas", "pawprint.fill", "showMisMascotas"),
        ("Mis citas", "calendar", "showMisCitas"),
        ("Solicitudes de adopción", "heart.fill", "showSolicitudesAdopcion")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Mi cuenta"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CuentaCell")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        Auth.auth().currentUser == nil ? 1 : 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard Auth.auth().currentUser != nil else { return 1 }
        switch section {
        case 0: return 1
        case 1: return opciones.count
        default: return 2
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CuentaCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        guard let usuario = Auth.auth().currentUser else {
            content.text = "Iniciar sesión o crear cuenta"
            content.secondaryText = "Accede a tus mascotas, citas y solicitudes"
            content.image = UIImage(systemName: "person.crop.circle.badge.checkmark")
            cell.contentConfiguration = content
            cell.accessoryType = .disclosureIndicator
            return cell
        }

        if indexPath.section == 0 {
            content.text = usuario.displayName ?? "Mi perfil"
            content.secondaryText = usuario.email
            content.image = UIImage(systemName: "person.crop.circle.fill")
            cell.accessoryType = .none
        } else if indexPath.section == 1 {
            let opcion = opciones[indexPath.row]
            content.text = opcion.0
            content.image = UIImage(systemName: opcion.1)
            cell.accessoryType = .disclosureIndicator
        } else if indexPath.row == 0 {
            content.text = "Cambiar contraseña"
            content.image = UIImage(systemName: "key.fill")
            cell.accessoryType = .disclosureIndicator
        } else {
            content.text = "Cerrar sesión"
            content.image = UIImage(systemName: "rectangle.portrait.and.arrow.right")
            content.textProperties.color = .systemRed
            cell.accessoryType = .none
        }
        cell.contentConfiguration = content
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard Auth.auth().currentUser != nil else { return }

        if indexPath.section == 1 {
            performSegue(withIdentifier: opciones[indexPath.row].segue, sender: self)
        } else if indexPath.section == 2, indexPath.row == 0 {
            performSegue(withIdentifier: "showCambiarPassword", sender: self)
        } else if indexPath.section == 2, indexPath.row == 1 {
            cerrarSesion()
        }
    }

    private func cerrarSesion() {
        do {
            try Auth.auth().signOut()
            AppFlow.showAuthentication()
        } catch {
            let alerta = UIAlertController(title: "No se pudo cerrar sesión", message: error.localizedDescription, preferredStyle: .alert)
            alerta.addAction(UIAlertAction(title: "Aceptar", style: .default))
            present(alerta, animated: true)
        }
    }
}
