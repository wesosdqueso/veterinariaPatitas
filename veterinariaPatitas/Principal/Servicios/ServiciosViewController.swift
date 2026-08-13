import UIKit

final class ServiciosViewController: UITableViewController {
    private let servicios = ["Consulta veterinaria", "Grooming", "Vacunación"]
    private let campanias = [
        "campania-vacunacion.png",
        "campania-esterilizacion.png",
        "festival-huellitas-2026.png"
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.sectionHeaderTopPadding = 18
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? servicios.count : 1
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        section == 1 ? 8 : UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        section == 1 ? .leastNormalMagnitude : UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ServicioCell", for: indexPath)
            var content = cell.defaultContentConfiguration()
            content.text = servicios[indexPath.row]
            content.image = UIImage(systemName: "cross.case.fill")
            content.imageProperties.tintColor = .systemGreen
            cell.contentConfiguration = content
            cell.accessoryType = .disclosureIndicator
            return cell
        }

        let cell = tableView.dequeueReusableCell(
            withIdentifier: CampaniasCarouselCell.reuseIdentifier,
            for: indexPath
        ) as! CampaniasCarouselCell
        cell.configure(with: campanias)
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.section == 0 ? UITableView.automaticDimension : 174
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == 0 else { return }
        performSegue(withIdentifier: "showAgendarCita", sender: servicios[indexPath.row])
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showAgendarCita",
              let destino = segue.destination as? AgendarCitaViewController,
              let servicio = sender as? String else { return }
        destino.servicio = servicio
    }
}
