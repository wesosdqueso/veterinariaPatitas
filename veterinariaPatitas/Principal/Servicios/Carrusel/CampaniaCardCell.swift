import UIKit

final class CampaniaCardCell: UICollectionViewCell {
    static let reuseIdentifier = "CampaniaCardCell"

    @IBOutlet private weak var bannerImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true
    }

    func configure(imageNamed imageName: String) {
        bannerImageView.image = UIImage(named: imageName)
    }
}
