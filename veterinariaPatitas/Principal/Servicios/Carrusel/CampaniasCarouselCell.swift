import UIKit

final class CampaniasCarouselCell: UITableViewCell,
                                    UICollectionViewDataSource,
                                    UICollectionViewDelegateFlowLayout {
    static let reuseIdentifier = "CampaniasCarouselCell"

    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var pageControl: UIPageControl!

    private var campanias: [String] = []

    override func awakeFromNib() {
        super.awakeFromNib()

        collectionView.isPagingEnabled = true
        collectionView.decelerationRate = .fast

        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumLineSpacing = 0
            layout.minimumInteritemSpacing = 0
            layout.sectionInset = .zero
        }

        let tapEnPuntos = UITapGestureRecognizer(target: self, action: #selector(seleccionarPagina(_:)))
        pageControl.addGestureRecognizer(tapEnPuntos)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    func configure(with campanias: [String]) {
        self.campanias = campanias
        pageControl.numberOfPages = campanias.count
        pageControl.currentPage = 0
        pageControl.isHidden = campanias.count <= 1
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        collectionView.setContentOffset(.zero, animated: false)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        campanias.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CampaniaCardCell.reuseIdentifier,
            for: indexPath
        ) as! CampaniaCardCell
        cell.configure(imageNamed: campanias[indexPath.item])
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        collectionView.bounds.size
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        actualizarPagina()
    }

    @objc private func seleccionarPagina(_ gesture: UITapGestureRecognizer) {
        guard campanias.count > 1 else { return }

        let anchoPorPagina = pageControl.bounds.width / CGFloat(campanias.count)
        guard anchoPorPagina > 0 else { return }

        let posicionX = gesture.location(in: pageControl).x
        let pagina = min(max(Int(posicionX / anchoPorPagina), 0), campanias.count - 1)
        pageControl.currentPage = pagina

        collectionView.scrollToItem(
            at: IndexPath(item: pagina, section: 0),
            at: .centeredHorizontally,
            animated: true
        )
    }

    private func actualizarPagina() {
        guard collectionView.bounds.width > 0, !campanias.isEmpty else { return }

        let pagina = Int(round(collectionView.contentOffset.x / collectionView.bounds.width))
        pageControl.currentPage = min(max(pagina, 0), campanias.count - 1)
    }
}
