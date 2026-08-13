import { execFileSync } from "node:child_process";

const projectId = "veterinaria-patitas-ios";
const collection = "mascotasAdopcion";

const mascotas = [
  {
    id: "luna",
    nombre: "Luna",
    especie: "Gato",
    edad: "1 año",
    sexo: "Hembra",
    detalles: "Gato · 1 año · Hembra",
    imagenNombre: "patitas_1_4 2.png",
    disponible: true,
  },
  {
    id: "max",
    nombre: "Max",
    especie: "Perro",
    edad: "3 años",
    sexo: "Macho",
    detalles: "Perro · 3 años · Macho",
    imagenNombre: "patitas2.png",
    disponible: true,
  },
  {
    id: "simba",
    nombre: "Simba",
    especie: "Gato",
    edad: "6 meses",
    sexo: "Macho",
    detalles: "Gato · 6 meses · Macho",
    imagenNombre: "Unknown-4.jpeg",
    disponible: true,
  },
];

const token = execFileSync("gcloud", ["auth", "print-access-token"], {
  encoding: "utf8",
}).trim();

const stringValue = (value) => ({ stringValue: value });

for (const mascota of mascotas) {
  const endpoint = new URL(
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/${collection}`,
  );
  endpoint.searchParams.set("documentId", mascota.id);

  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      fields: {
        nombre: stringValue(mascota.nombre),
        especie: stringValue(mascota.especie),
        edad: stringValue(mascota.edad),
        sexo: stringValue(mascota.sexo),
        detalles: stringValue(mascota.detalles),
        imagenNombre: stringValue(mascota.imagenNombre),
        disponible: { booleanValue: mascota.disponible },
        creadoEn: { timestampValue: new Date().toISOString() },
      },
    }),
  });

  if (response.ok) {
    console.log(`Insertada: ${mascota.nombre} (${mascota.id})`);
    continue;
  }

  const error = await response.json();
  if (response.status === 409 || error.error?.status === "ALREADY_EXISTS") {
    console.log(`Omitida: ${mascota.nombre}; el documento ya existe.`);
    continue;
  }

  throw new Error(
    `No se pudo insertar ${mascota.nombre}: ${error.error?.message ?? response.statusText}`,
  );
}
