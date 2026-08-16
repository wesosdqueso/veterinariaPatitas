import FirebaseAuth
import FirebaseFirestore

final class MascotasRepository {
    private let auth: Auth
    private let firestore: Firestore

    init(auth: Auth = .auth(), firestore: Firestore = .firestore()) {
        self.auth = auth
        self.firestore = firestore
    }

    @discardableResult
    func escuchar(
        cambios: @escaping (Result<[Mascota], Error>) -> Void
    ) throws -> ListenerRegistration {
        guard let collection = collection else { throw MascotasRepositoryError.sinSesion }

        return collection
            .order(by: "creadoEn", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error {
                    cambios(.failure(error))
                    return
                }
                let mascotas = snapshot?.documents.compactMap(Mascota.init(document:)) ?? []
                cambios(.success(mascotas))
            }
    }

    func registrar(
        datos: [String: Any],
        completion: @escaping (Result<String, Error>) -> Void
    ) throws {
        guard let collection else { throw MascotasRepositoryError.sinSesion }
        let document = collection.document()
        document.setData(datos) { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(document.documentID))
            }
        }
    }

    func actualizar(
        id: String,
        datos: [String: Any],
        completion: @escaping (Error?) -> Void
    ) throws {
        guard let collection else { throw MascotasRepositoryError.sinSesion }
        collection.document(id).setData(datos, merge: true, completion: completion)
    }

    func eliminar(id: String, completion: @escaping (Error?) -> Void) throws {
        guard let collection else { throw MascotasRepositoryError.sinSesion }
        collection.document(id).delete(completion: completion)
    }

    private var collection: CollectionReference? {
        guard let uid = auth.currentUser?.uid else { return nil }
        return firestore.collection("usuarios").document(uid).collection("mascotas")
    }
}

enum MascotasRepositoryError: LocalizedError {
    case sinSesion

    var errorDescription: String? {
        "Debes iniciar sesión para gestionar tus mascotas."
    }
}
