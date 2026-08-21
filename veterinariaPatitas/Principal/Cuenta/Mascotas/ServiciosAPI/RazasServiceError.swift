import Foundation

enum RazasServiceError: LocalizedError {
    case respuestaInvalida

    var errorDescription: String? {
        "El servicio de razas devolvió una respuesta no válida."
    }
}
