import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)
        guard let window else { return }
        AppFlow.configure(window: window)
        if Auth.auth().currentUser == nil {
            AppFlow.showAuthentication(animated: false)
        } else {
            AppFlow.showMain(animated: false)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Se llama cuando la escena se desconecta
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Se llama cuando la escena pasa a estado activo
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Se llama cuando la escena pasa a inactiva (ej. llamada entrante)
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Se llama cuando la app vuelve al foreground
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Se llama cuando la app pasa al background
    }
}
