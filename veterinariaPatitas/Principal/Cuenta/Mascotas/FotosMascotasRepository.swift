import CoreData
import UIKit

@objc(FotoMascotaLocal)
final class FotoMascotaLocal: NSManagedObject {
    @NSManaged var mascotaId: String
    @NSManaged var rutaImagen: String
}

@MainActor
final class FotosMascotasRepository {
    private let context: NSManagedObjectContext
    private let fileManager: FileManager

    init(
        context: NSManagedObjectContext? = nil,
        fileManager: FileManager = .default
    ) {
        if let context {
            self.context = context
        } else {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            self.context = appDelegate.persistentContainer.viewContext
        }
        self.fileManager = fileManager
    }

    func guardar(imagen: UIImage, para mascotaId: String) throws {
        guard let datos = imagen.jpegData(compressionQuality: 0.8) else {
            throw FotosMascotasError.noSePudoConvertir
        }

        let registro = try buscar(mascotaId: mascotaId) ?? FotoMascotaLocal(context: context)
        let rutaRelativa: String
        if registro.rutaImagen.isEmpty {
            rutaRelativa = "FotosMascotas/\(UUID().uuidString).jpg"
        } else {
            rutaRelativa = registro.rutaImagen
        }

        let archivo = try urlArchivo(rutaRelativa: rutaRelativa, crearCarpeta: true)
        try datos.write(to: archivo, options: .atomic)

        registro.mascotaId = mascotaId
        registro.rutaImagen = rutaRelativa
        try context.save()
    }

    func imagen(mascotaId: String) -> UIImage? {
        guard let registro = try? buscar(mascotaId: mascotaId),
              let archivo = try? urlArchivo(rutaRelativa: registro.rutaImagen) else {
            return nil
        }
        return UIImage(contentsOfFile: archivo.path)
    }

    func eliminar(mascotaId: String) throws {
        guard let registro = try buscar(mascotaId: mascotaId) else { return }
        if let archivo = try? urlArchivo(rutaRelativa: registro.rutaImagen),
           fileManager.fileExists(atPath: archivo.path) {
            try fileManager.removeItem(at: archivo)
        }
        context.delete(registro)
        try context.save()
    }

    private func buscar(mascotaId: String) throws -> FotoMascotaLocal? {
        let request = NSFetchRequest<FotoMascotaLocal>(entityName: "FotoMascotaLocal")
        request.predicate = NSPredicate(format: "mascotaId == %@", mascotaId)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func urlArchivo(
        rutaRelativa: String,
        crearCarpeta: Bool = false
    ) throws -> URL {
        let documentos = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let archivo = documentos.appendingPathComponent(rutaRelativa)

        if crearCarpeta {
            try fileManager.createDirectory(
                at: archivo.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        }
        return archivo
    }
}

enum FotosMascotasError: LocalizedError {
    case noSePudoConvertir

    var errorDescription: String? {
        "No se pudo preparar la fotografía seleccionada."
    }
}
