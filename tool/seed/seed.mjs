// Carga el catálogo de ejemplo (perfumes.json) en la colección `perfumes`.
//
// Las reglas de Firestore prohíben escribir en `perfumes` desde la app, así que
// este script usa el Admin SDK, que se salta las reglas.
//
// Credenciales (nunca dentro del repo), una de estas dos:
//   - gcloud auth application-default login
//   - GOOGLE_APPLICATION_CREDENTIALS=/ruta/fuera/del/repo/clave.json
//
// Uso:
//   cd tool/seed && npm install
//   node seed.mjs              -> escribe en el proyecto de .firebaserc
//   node seed.mjs --dry-run    -> solo valida y muestra qué escribiría
//   node seed.mjs --project otro-proyecto
//
// Es idempotente: cada perfume tiene un id fijo y se sobrescribe entero.

import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run');
const projectFlag = args.indexOf('--project');

function defaultProject() {
  const rc = JSON.parse(readFileSync(join(here, '..', '..', '.firebaserc'), 'utf8'));
  return rc.projects.default;
}

const projectId = projectFlag >= 0 ? args[projectFlag + 1] : defaultProject();
const perfumes = JSON.parse(readFileSync(join(here, 'perfumes.json'), 'utf8'));

// Misma forma que espera Perfume.fromFirestore (lib/models/perfume.dart).
function validate(p) {
  const errors = [];
  if (!/^[a-z0-9-]+$/.test(p.id ?? '')) errors.push('id');
  for (const key of ['brand', 'name', 'concentration', 'imageUrl']) {
    if (typeof p[key] !== 'string') errors.push(key);
  }
  if (!Number.isInteger(p.nominalMl) || p.nominalMl <= 0) errors.push('nominalMl');
  if (!Array.isArray(p.season)) errors.push('season');
  for (const layer of ['top', 'heart', 'base']) {
    if (!Array.isArray(p.notes?.[layer])) errors.push(`notes.${layer}`);
  }
  if (p.tareInfo && !(p.tareInfo.emptyBottleWeight > 0)) errors.push('tareInfo');
  if (!Array.isArray(p.prices)) errors.push('prices');
  return errors;
}

const invalid = perfumes
  .map((p) => [p.id, validate(p)])
  .filter(([, errors]) => errors.length > 0);
if (invalid.length > 0) {
  for (const [id, errors] of invalid) console.error(`${id}: campos no válidos: ${errors.join(', ')}`);
  process.exit(1);
}

if (dryRun) {
  console.log(`[dry-run] ${perfumes.length} perfumes válidos para ${projectId}:`);
  for (const p of perfumes) console.log(`  perfumes/${p.id}  ${p.brand} ${p.name}`);
  process.exit(0);
}

const { initializeApp, applicationDefault } = await import('firebase-admin/app');
const { getFirestore } = await import('firebase-admin/firestore');

initializeApp({ credential: applicationDefault(), projectId });
const db = getFirestore();

const batch = db.batch();
for (const { id, ...data } of perfumes) {
  batch.set(db.collection('perfumes').doc(id), data);
}
try {
  await batch.commit();
} catch (e) {
  console.error(`No se pudo escribir en ${projectId}: ${e.message}`);
  console.error('Revisa las credenciales (ver cabecera de este archivo) y el id del proyecto.');
  process.exit(1);
}
console.log(`${perfumes.length} perfumes escritos en ${projectId}.`);
