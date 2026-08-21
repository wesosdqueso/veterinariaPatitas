import UIKit

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
                guard let data else { throw RazasServiceError.respuestaInvalida }
                let response = try JSONDecoder().decode(ListaResponse.self, from: data)
                guard response.status == "success" else {
                    throw RazasServiceError.respuestaInvalida
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
