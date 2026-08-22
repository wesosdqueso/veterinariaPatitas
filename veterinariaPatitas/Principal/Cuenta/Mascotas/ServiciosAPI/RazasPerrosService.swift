import Foundation

final class RazasPerrosService {
    private struct ListaResponse: Decodable {
        let message: [String: [String]]
        let status: String
    }

    private let session: URLSession

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
