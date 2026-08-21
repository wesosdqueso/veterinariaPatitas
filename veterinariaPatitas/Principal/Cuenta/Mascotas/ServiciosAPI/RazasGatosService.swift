import Foundation

final class RazasGatosService {
    private struct ListaResponse: Decodable {
        struct Raza: Decodable {
            let breed: String
        }

        let data: [Raza]
    }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func cargarRazas(completion: @escaping (Result<[RazaOpcion], Error>) -> Void) {
        let url = URL(string: "https://catfact.ninja/breeds?limit=100")!
        session.dataTask(with: url) { data, _, error in
            let resultado: Result<[RazaOpcion], Error>
            do {
                if let error { throw error }
                guard let data else { throw RazasServiceError.respuestaInvalida }
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
}
