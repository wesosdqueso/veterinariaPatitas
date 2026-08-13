import AVFoundation
import UIKit

final class PeluchesSonorosViewController: UIViewController {
    private var audioPlayer: AVAudioPlayer?

    override func viewDidLoad() {
        super.viewDidLoad()

        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    @IBAction private func playSound(_ sender: UIButton) {
        let audio = sender.configuration!.title!
        let audioURL = Bundle.main.url(forResource: audio, withExtension: "mp3")!
        audioPlayer = try? AVAudioPlayer(contentsOf: audioURL)
        audioPlayer?.play()
    }
}
