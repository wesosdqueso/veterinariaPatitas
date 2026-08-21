import FirebaseAuth
import FirebaseFirestore

final class CitasRepository {
    private let auth: Auth
    private let firestore: Firestore

    init(auth: Auth = .auth(), firestore: Firestore = .firestore()) {
        self.auth = auth
        self.firestore = firestore
    }

    @discardableResult
    func escuchar(
        cambios: @escaping (Result<[Cita], Error>) -> Void
    ) throws -> ListenerRegistration {
        try collection()
            .order(by: "fecha", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error {
                    cambios(.failure(error))
                    return
                }

                let citas = snapshot?.documents.compactMap(Cita.init(document:)) ?? []
                cambios(.success(citas))
            }
    }

    func registrar(
        servicio: String,
        mascota: Mascota,
        fecha: Date,
        completion: @escaping (Error?) -> Void
    ) throws {
        let datos: [String: Any] = [
            "servicio": servicio,
            "mascotaId": mascota.id,
            "mascotaNombre": mascota.nombre,
            "fecha": Timestamp(date: fecha),
            "estado": EstadoCita.pendiente.rawValue,
            "creadoEn": FieldValue.serverTimestamp()
        ]
        try collection().document().setData(datos, completion: completion)
    }

    func cancelar(id: String, completion: @escaping (Error?) -> Void) throws {
        try collection().document(id).updateData(
            ["estado": EstadoCita.cancelada.rawValue],
            completion: completion
        )
    }

    private func collection() throws -> CollectionReference {
        guard let uid = auth.currentUser?.uid else {
            throw CitasRepositoryError.sinSesion
        }
        return firestore.collection("usuarios").document(uid).collection("citas")
    }
}

enum CitasRepositoryError: LocalizedError {
    case sinSesion

    var errorDescription: String? {
        "Debes iniciar sesión para gestionar tus citas."
    }
}
