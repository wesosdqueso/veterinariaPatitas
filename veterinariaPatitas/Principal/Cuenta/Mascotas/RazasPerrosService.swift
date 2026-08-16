import UIKit

struct RazaOpcion {
    let id: String
    let nombre: String
    let rutaAPI: String?
}

final class RazasPerrosService {
    private struct ListaResponse: Decodable {
        let message: [String: [String]]
        let status: String
    }

    private struct ImagenResponse: Decodable {
        let message: URL
        let status: String
    }

    private let session: URLSession
    private let imagenes = NSCache<NSString, UIImage>()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func cargarRazas(completion: @escaping (Result<[RazaOpcion], Error>) -> Void) {
        let url = URL(string: "https://dog.ceo/api/breeds/list/all")!
        session.dataTask(with: url) { data, _, error in
            let resultado: Result<[RazaOpcion], Error>
            do {
                if let error { throw error }
                guard let data else { throw RazasPerrosError.respuestaInvalida }
                let response = try JSONDecoder().decode(ListaResponse.self, from: data)
                guard response.status == "success" else {
                    throw RazasPerrosError.respuestaInvalida
                }
                resultado = .success(Self.convertir(response.message))
            } catch {
                resultado = .failure(error)
            }
            DispatchQueue.main.async { completion(resultado) }
        }.resume()
    }

    func cargarImagen(
        para raza: RazaOpcion,
        completion: @escaping (UIImage?) -> Void
    ) {
        guard let rutaAPI = raza.rutaAPI else {
            completion(nil)
            return
        }
        if let imagen = imagenes.object(forKey: raza.id as NSString) {
            completion(imagen)
            return
        }

        let url = URL(string: "https://dog.ceo/api/breed/\(rutaAPI)/images/random")!
        session.dataTask(with: url) { [weak self] data, _, _ in
            guard let self,
                  let data,
                  let response = try? JSONDecoder().decode(ImagenResponse.self, from: data),
                  response.status == "success" else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            self.session.dataTask(with: response.message) { [weak self] data, _, _ in
                let imagen = data.flatMap(UIImage.init(data:))
                if let imagen {
                    self?.imagenes.setObject(imagen, forKey: raza.id as NSString)
                }
                DispatchQueue.main.async { completion(imagen) }
            }.resume()
        }.resume()
    }

    private static func convertir(_ datos: [String: [String]]) -> [RazaOpcion] {
        datos.flatMap { raza, subrazas -> [RazaOpcion] in
            if subrazas.isEmpty {
                return [RazaOpcion(
                    id: "perro:\(raza)",
                    nombre: nombreVisible(raza),
                    rutaAPI: raza
                )]
            }
            return subrazas.map { subraza in
                RazaOpcion(
                    id: "perro:\(raza)-\(subraza)",
                    nombre: "\(nombreVisible(subraza)) \(nombreVisible(raza))",
                    rutaAPI: "\(raza)/\(subraza)"
                )
            }
        }
        .sorted { $0.nombre.localizedCaseInsensitiveCompare($1.nombre) == .orderedAscending }
    }

    private static func nombreVisible(_ valor: String) -> String {
        valor.replacingOccurrences(of: "-", with: " ").capitalized
    }
}

final class RazasGatosService {
    private struct ListaResponse: Decodable {
        struct Raza: Decodable {
            let breed: String
        }

        let data: [Raza]
    }

    private let session: URLSession
    private let imagenes = NSCache<NSString, UIImage>()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func cargarRazas(completion: @escaping (Result<[RazaOpcion], Error>) -> Void) {
        let url = URL(string: "https://catfact.ninja/breeds?limit=100")!
        session.dataTask(with: url) { data, _, error in
            let resultado: Result<[RazaOpcion], Error>
            do {
                if let error { throw error }
                guard let data else { throw RazasPerrosError.respuestaInvalida }
                let response = try JSONDecoder().decode(ListaResponse.self, from: data)
                let razas = response.data.map {
                    RazaOpcion(
                        id: "gato:\($0.breed.lowercased())",
                        nombre: $0.breed,
                        rutaAPI: nil
                    )
                }
                .sorted { $0.nombre.localizedCaseInsensitiveCompare($1.nombre) == .orderedAscending }
                resultado = .success(razas)
            } catch {
                resultado = .failure(error)
            }
            DispatchQueue.main.async { completion(resultado) }
        }.resume()
    }

    func cargarImagen(
        para raza: RazaOpcion,
        completion: @escaping (UIImage?) -> Void
    ) {
        guard let url = URL(string: "https://cataas.com/cat?width=120&height=120") else {
            completion(nil)
            return
        }
        if let imagen = imagenes.object(forKey: raza.id as NSString) {
            completion(imagen)
            return
        }

        session.dataTask(with: url) { [weak self] data, _, _ in
            let imagen = data.flatMap(UIImage.init(data:))
            if let imagen {
                self?.imagenes.setObject(imagen, forKey: raza.id as NSString)
            }
            DispatchQueue.main.async { completion(imagen) }
        }.resume()
    }
}

enum RazasPerrosError: LocalizedError {
    case respuestaInvalida

    var errorDescription: String? {
        "El servicio de razas devolvió una respuesta no válida."
    }
}

final class RazaPickerRowView: UIView {
    let imageView = UIImageView()
    let nombreLabel = UILabel()
    var razaId = ""

    override init(frame: CGRect) {
        super.init(frame: frame)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.tintColor = .systemGreen
        imageView.translatesAutoresizingMaskIntoConstraints = false

        nombreLabel.font = .preferredFont(forTextStyle: .body)
        nombreLabel.adjustsFontForContentSizeCategory = true

        let stack = UIStackView(arrangedSubviews: [imageView, nombreLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 48),
            imageView.heightAnchor.constraint(equalToConstant: 48),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) no está implementado")
    }
}
