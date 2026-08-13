import UIKit

final class CampaniasCarouselCell: UITableViewCell,
                                    UICollectionViewDataSource,
                                    UICollectionViewDelegateFlowLayout {
    static let reuseIdentifier = "CampaniasCarouselCell"

    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var pageControl: UIPageControl!

    private var campanias: [String] = []

    func configure(with campanias: [String]) {
        self.campanias = campanias
        pageControl.numberOfPages = campanias.count
        pageControl.currentPage = 0
        collectionView.setContentOffset(.zero, animated: false)
        collectionView.reloadData()
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
        CGSize(width: collectionView.bounds.width - 38, height: collectionView.bounds.height - 2)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        actualizarPagina()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        actualizarPagina()
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
