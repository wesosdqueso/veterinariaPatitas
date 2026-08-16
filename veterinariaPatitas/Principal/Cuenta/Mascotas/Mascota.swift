import FirebaseFirestore

struct Mascota {
    let id: String
    let nombre: String
    let especie: String
    let raza: String
    let sexo: String
    let peso: Double?
    let fechaNacimiento: Date?

    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        guard let nombre = data["nombre"] as? String,
              let especie = data["especie"] as? String,
              let raza = data["raza"] as? String,
              let sexo = data["sexo"] as? String else { return nil }

        id = document.documentID
        self.nombre = nombre
        self.especie = especie
        self.raza = raza
        self.sexo = sexo
        peso = data["peso"] as? Double
        fechaNacimiento = (data["fechaNacimiento"] as? Timestamp)?.dateValue()
    }
}
