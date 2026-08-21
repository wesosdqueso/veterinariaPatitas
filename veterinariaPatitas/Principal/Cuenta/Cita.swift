import FirebaseFirestore

struct Cita {
    let id: String
    let servicio: String
    let mascotaId: String
    let mascotaNombre: String
    let fecha: Date
    let estado: EstadoCita

    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        guard let servicio = data["servicio"] as? String,
              let mascotaId = data["mascotaId"] as? String,
              let mascotaNombre = data["mascotaNombre"] as? String,
              let fecha = data["fecha"] as? Timestamp else {
            return nil
        }

        id = document.documentID
        self.servicio = servicio
        self.mascotaId = mascotaId
        self.mascotaNombre = mascotaNombre
        self.fecha = fecha.dateValue()
        estado = EstadoCita(rawValue: data["estado"] as? String ?? "") ?? .pendiente
    }
}

enum EstadoCita: String {
    case pendiente = "Pendiente"
    case cancelada = "Cancelada"
}
