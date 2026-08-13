import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)
        if Auth.auth().currentUser == nil {
            mostrarLogin()
        } else {
            mostrarPantallaPrincipal()
        }
        window?.makeKeyAndVisible()
    }

    func mostrarLogin() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        window?.rootViewController = storyboard.instantiateViewController(
            withIdentifier: "LoginViewController"
        )
    }

    func mostrarPantallaPrincipal() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBar = UITabBarController()

        let servicios = storyboard.instantiateViewController(withIdentifier: "ServiciosViewController")
        let adopcion = storyboard.instantiateViewController(withIdentifier: "AdopcionViewController")
        let peluches = storyboard.instantiateViewController(withIdentifier: "PeluchesSonorosViewController")
        let cuenta = storyboard.instantiateViewController(withIdentifier: "MiCuentaViewController")

        let serviciosNavigation = UINavigationController(rootViewController: servicios)
        serviciosNavigation.tabBarItem = UITabBarItem(
            title: "Servicios",
            image: UIImage(systemName: "cross.case.fill"),
            tag: 0
        )

        let adopcionNavigation = UINavigationController(rootViewController: adopcion)
        adopcionNavigation.tabBarItem = UITabBarItem(
            title: "Adopción",
            image: UIImage(systemName: "heart.fill"),
            tag: 1
        )

        let peluchesNavigation = UINavigationController(rootViewController: peluches)
        peluchesNavigation.tabBarItem = UITabBarItem(
            title: "Peluches",
            image: UIImage(systemName: "speaker.wave.2.fill"),
            tag: 2
        )

        let cuentaNavigation = UINavigationController(rootViewController: cuenta)
        cuentaNavigation.tabBarItem = UITabBarItem(
            title: "Mi cuenta",
            image: UIImage(systemName: "person.crop.circle.fill"),
            tag: 3
        )

        tabBar.viewControllers = [
            serviciosNavigation,
            adopcionNavigation,
            peluchesNavigation,
            cuentaNavigation
        ]
        tabBar.tabBar.tintColor = .systemGreen
        window?.rootViewController = tabBar
    }
}
