import { execFileSync } from "node:child_process";
import { mkdir, writeFile } from "node:fs/promises";

const projectId = "veterinaria-patitas-ios";
const resourcesDirectory = new URL("../veterinariaPatitas/Recursos/", import.meta.url);

const mascotas = [
  {
    id: "toby",
    filename: "toby.jpg",
    source: "https://commons.wikimedia.org/wiki/Special:Redirect/file/Golden%20Retriever%20adult.jpg?width=1200",
    attribution: "Johan Spaedtke, Golden Retriever adult.jpg, CC0 1.0, Wikimedia Commons",
  },
  {
    id: "luna",
    filename: "luna.jpg",
    source: "https://commons.wikimedia.org/wiki/Special:Redirect/file/Grey%20cat%20portrait%20-%2026312887674.jpg?width=1200",
    attribution: "TimOve, Grey cat portrait - 26312887674.jpg, CC BY 2.0, Wikimedia Commons",
  },
  {
    id: "max",
    filename: "max.jpg",
    source: "https://commons.wikimedia.org/wiki/Special:Redirect/file/GoldenRetrieverPortrait.jpg?width=1200",
    attribution: "Ltshears, GoldenRetrieverPortrait.jpg, CC BY 3.0, Wikimedia Commons",
  },
  {
    id: "simba",
    filename: "simba.jpg",
    source: "https://commons.wikimedia.org/wiki/Special:Redirect/file/Orange%20Tabby.jpg?width=1200",
    attribution: "Miscellaneous contributor, Orange Tabby.jpg, CC0 1.0, Wikimedia Commons",
  },
];

const accessToken = execFileSync("gcloud", ["auth", "print-access-token"], {
  encoding: "utf8",
}).trim();

await mkdir(resourcesDirectory, { recursive: true });

for (const mascota of mascotas) {
  const response = await fetch(mascota.source, {
    headers: { "User-Agent": "VeterinariaPatitas/1.0 (educational project)" },
  });
  if (!response.ok) {
    throw new Error(`No se pudo descargar ${mascota.id}: ${response.statusText}`);
  }

  await writeFile(
    new URL(mascota.filename, resourcesDirectory),
    Buffer.from(await response.arrayBuffer()),
  );

  const firestoreURL = new URL(
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/mascotasAdopcion/${mascota.id}`,
  );
  firestoreURL.searchParams.set("updateMask.fieldPaths", "imagenNombre");

  const firestoreResponse = await fetch(firestoreURL, {
    method: "PATCH",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      fields: { imagenNombre: { stringValue: mascota.filename } },
    }),
  });
  if (!firestoreResponse.ok) {
    throw new Error(`No se pudo actualizar ${mascota.id}: ${await firestoreResponse.text()}`);
  }

  console.log(`Preparada: ${mascota.id} -> ${mascota.filename}`);
}

await writeFile(
  new URL("ATRIBUCIONES-IMAGENES.md", resourcesDirectory),
  mascotas.map((mascota) => `- ${mascota.filename}: ${mascota.attribution}`).join("\n") + "\n",
);
