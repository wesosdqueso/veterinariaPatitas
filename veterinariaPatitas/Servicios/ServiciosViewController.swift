import UIKit

final class ServiciosViewController: UITableViewController {
    private let servicios = ["Consulta veterinaria", "Grooming", "Vacunación"]
    private let campanias = [
        "campania-vacunacion.png",
        "campania-esterilizacion.png",
        "festival-huellitas-2026.png"
    ]
    private var servicioSeleccionado: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Servicios"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ServicioCell")
        tableView.register(CampaniasCarouselCell.self, forCellReuseIdentifier: CampaniasCarouselCell.reuseIdentifier)
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
        servicioSeleccionado = servicios[indexPath.row]
        performSegue(withIdentifier: "showAgendarCita", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showAgendarCita",
              let destino = segue.destination as? AgendarCitaViewController else { return }
        destino.servicio = servicioSeleccionado ?? "Servicio"
    }
}

private final class CampaniasCarouselCell: UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    static let reuseIdentifier = "CampaniasCarouselCell"

    private let collectionView: UICollectionView
    private let pageControl = UIPageControl()
    private var campanias: [String] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = .fast
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(CampaniaCardCell.self, forCellWithReuseIdentifier: CampaniaCardCell.reuseIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        pageControl.currentPageIndicatorTintColor = .systemGreen
        pageControl.pageIndicatorTintColor = .systemGray4
        pageControl.isUserInteractionEnabled = false
        pageControl.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(collectionView)
        contentView.addSubview(pageControl)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -2),
            pageControl.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),
            pageControl.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with campanias: [String]) {
        self.campanias = campanias
        pageControl.numberOfPages = campanias.count
        pageControl.currentPage = 0
        collectionView.setContentOffset(.zero, animated: false)
        collectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        campanias.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CampaniaCardCell.reuseIdentifier,
            for: indexPath
        ) as! CampaniaCardCell
        cell.configure(imageNamed: campanias[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.bounds.width - 38, height: collectionView.bounds.height - 2)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        actualizarPagina()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        actualizarPagina()
    }

    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        let anchoTarjeta = collectionView.bounds.width - 38
        let paso = anchoTarjeta + 12
        guard paso > 0 else { return }
        let pagina = round(targetContentOffset.pointee.x / paso)
        targetContentOffset.pointee.x = max(0, pagina * paso)
    }

    private func actualizarPagina() {
        let centro = CGPoint(
            x: collectionView.contentOffset.x + collectionView.bounds.width / 2,
            y: collectionView.bounds.height / 2
        )
        if let indexPath = collectionView.indexPathForItem(at: centro) {
            pageControl.currentPage = indexPath.item
        }
    }
}

private final class CampaniaCardCell: UICollectionViewCell {
    static let reuseIdentifier = "CampaniaCardCell"

    private let bannerImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true

        bannerImageView.contentMode = .scaleAspectFill
        bannerImageView.clipsToBounds = true
        bannerImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bannerImageView)

        NSLayoutConstraint.activate([
            bannerImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bannerImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bannerImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bannerImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(imageNamed imageName: String) {
        bannerImageView.image = UIImage(named: imageName)
    }
}
