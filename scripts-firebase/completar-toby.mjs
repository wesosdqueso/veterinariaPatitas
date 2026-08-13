import { execFileSync } from "node:child_process";

const projectId = "veterinaria-patitas-ios";
const documentPath = "mascotasAdopcion/toby";
const endpoint = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/${documentPath}`;

const token = execFileSync("gcloud", ["auth", "print-access-token"], {
  encoding: "utf8",
}).trim();

const headers = {
  Authorization: `Bearer ${token}`,
  "Content-Type": "application/json",
};

const currentResponse = await fetch(endpoint, { headers });
if (!currentResponse.ok) {
  throw new Error(`No se pudo leer Toby: ${await currentResponse.text()}`);
}

const currentDocument = await currentResponse.json();
const defaults = {
  nombre: { stringValue: "Toby" },
  especie: { stringValue: "Perro" },
  edad: { stringValue: "2 años" },
  sexo: { stringValue: "Macho" },
  detalles: { stringValue: "Perro · 2 años · Macho" },
  imagenNombre: { stringValue: "Alimentacion.jpeg" },
  disponible: { booleanValue: true },
  creadoEn: { timestampValue: new Date().toISOString() },
};

const missingEntries = Object.entries(defaults).filter(
  ([field]) => currentDocument.fields?.[field] === undefined,
);

if (missingEntries.length === 0) {
  console.log("Toby ya tiene todos los campos requeridos.");
  process.exit(0);
}

const updateURL = new URL(endpoint);
for (const [field] of missingEntries) {
  updateURL.searchParams.append("updateMask.fieldPaths", field);
}

const updateResponse = await fetch(updateURL, {
  method: "PATCH",
  headers,
  body: JSON.stringify({ fields: Object.fromEntries(missingEntries) }),
});

if (!updateResponse.ok) {
  throw new Error(`No se pudo completar Toby: ${await updateResponse.text()}`);
}

console.log(
  `Toby completado. Campos agregados: ${missingEntries.map(([field]) => field).join(", ")}`,
);
