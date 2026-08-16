import UIKit
import FirebaseAuth

final class MiCuentaViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
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
        case 1: return 3
        case 2: return 2
        default: return 0
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

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            content.text = usuario.displayName ?? "Mi perfil"
            content.secondaryText = usuario.email
            content.image = UIImage(systemName: "person.crop.circle.fill")
            cell.accessoryType = .none

        case (1, 0):
            content.text = "Mis mascotas"
            content.image = UIImage(systemName: "pawprint.fill")
            cell.accessoryType = .disclosureIndicator

        case (1, 1):
            content.text = "Mis citas"
            content.image = UIImage(systemName: "calendar")
            cell.accessoryType = .disclosureIndicator

        case (1, 2):
            content.text = "Mis solicitudes de adopción"
            content.image = UIImage(systemName: "heart.fill")
            cell.accessoryType = .disclosureIndicator

        case (2, 0):
            content.text = "Cambiar contraseña"
            content.image = UIImage(systemName: "key.fill")
            cell.accessoryType = .disclosureIndicator

        case (2, 1):
            content.text = "Cerrar sesión"
            content.image = UIImage(systemName: "rectangle.portrait.and.arrow.right")
            content.textProperties.color = .systemRed
            cell.accessoryType = .none

        default:
            break
        }

        cell.contentConfiguration = content
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard Auth.auth().currentUser != nil else { return }

        switch (indexPath.section, indexPath.row) {
        case (1, 0):
            performSegue(withIdentifier: "showMisMascotas", sender: self)

        case (1, 1):
            performSegue(withIdentifier: "showMisCitas", sender: self)

        case (1, 2):
            performSegue(withIdentifier: "showMisSolicitudesAdopcion", sender: self)

        case (2, 0):
            performSegue(withIdentifier: "showCambiarPassword", sender: self)

        case (2, 1):
            cerrarSesion()

        default:
            break
        }
    }

    private func cerrarSesion() {
        do {
            try Auth.auth().signOut()
            let sceneDelegate = view.window?.windowScene?.delegate as! SceneDelegate
            sceneDelegate.mostrarLogin()
        } catch {
            Alerts.show(on: self, title: "No se pudo cerrar sesión", message: error.localizedDescription)
        }
    }
}
