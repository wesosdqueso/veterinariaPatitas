import { execFileSync } from "node:child_process";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { randomUUID } from "node:crypto";

const projectId = "veterinaria-patitas-ios";
const bucket = "veterinaria-patitas-ios.firebasestorage.app";
const outputDirectory = new URL("./imagenes-adopcion/", import.meta.url);

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

await mkdir(outputDirectory, { recursive: true });

for (const mascota of mascotas) {
  const imageResponse = await fetch(mascota.source, {
    headers: { "User-Agent": "VeterinariaPatitas/1.0 (educational project)" },
  });
  if (!imageResponse.ok) {
    throw new Error(`No se pudo descargar ${mascota.id}: ${imageResponse.statusText}`);
  }

  const imageData = Buffer.from(await imageResponse.arrayBuffer());
  await writeFile(new URL(mascota.filename, outputDirectory), imageData);

  const storagePath = `mascotas-adopcion/${mascota.filename}`;
  const downloadToken = randomUUID();
  const uploadURL = new URL(`https://storage.googleapis.com/upload/storage/v1/b/${bucket}/o`);
  uploadURL.searchParams.set("uploadType", "media");
  uploadURL.searchParams.set("name", storagePath);

  const uploadResponse = await fetch(uploadURL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "image/jpeg",
      "x-goog-meta-firebaseStorageDownloadTokens": downloadToken,
    },
    body: await readFile(new URL(mascota.filename, outputDirectory)),
  });
  if (!uploadResponse.ok) {
    throw new Error(`No se pudo subir ${mascota.id}: ${await uploadResponse.text()}`);
  }

  const downloadURL = `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/${encodeURIComponent(storagePath)}?alt=media&token=${downloadToken}`;
  const firestoreURL = new URL(
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/mascotasAdopcion/${mascota.id}`,
  );
  firestoreURL.searchParams.set("updateMask.fieldPaths", "imagenNombre");
  firestoreURL.searchParams.set("updateMask.fieldPaths", "imagenURL");

  const firestoreResponse = await fetch(firestoreURL, {
    method: "PATCH",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      fields: {
        imagenNombre: { stringValue: downloadURL },
        imagenURL: { stringValue: downloadURL },
      },
    }),
  });
  if (!firestoreResponse.ok) {
    throw new Error(`No se pudo actualizar ${mascota.id}: ${await firestoreResponse.text()}`);
  }

  console.log(`Actualizada: ${mascota.id} -> ${storagePath}`);
}

await writeFile(
  new URL("ATRIBUCIONES.md", outputDirectory),
  mascotas.map((mascota) => `- ${mascota.filename}: ${mascota.attribution}`).join("\n") + "\n",
);
