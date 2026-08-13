import AVFoundation
import UIKit

final class PeluchesSonorosViewController: UIViewController {
    private let audios = ["plushie1", "plushie2", "plushie3", "plushie4"]
    private var audioPlayer: AVAudioPlayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Peluches"
        configureAudioSession()
    }

    @IBAction private func playSound(_ sender: UIButton) {
        guard audios.indices.contains(sender.tag) else { return }

        let audio = audios[sender.tag]
        guard let audioURL = Bundle.main.url(forResource: audio, withExtension: "mp3") else {
            assertionFailure("No se encontro el archivo \(audio).mp3")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("No se pudo reproducir \(audio).mp3: \(error.localizedDescription)")
        }

        UIView.animate(withDuration: 0.12, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }, completion: { _ in
            UIView.animate(withDuration: 0.12) { sender.transform = .identity }
        })
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("No se pudo configurar la sesion de audio: \(error.localizedDescription)")
        }
    }
}
