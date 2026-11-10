// Prepara las perfumerías de OpenStreetMap y las sube a Firestore
// (colección `stores`, un documento por tienda).
//
// Uso (desde tools/stores):
//   node seed_stores.mjs <tiendas.json>            → solo vista previa: no sube nada
//   node seed_stores.mjs <tiendas.json> --upload   → sube a Firestore
//   node seed_stores.mjs --delete-excluded         → solo borra las cadenas excluidas
//   ... --key <ruta>   clave de la cuenta de servicio (por defecto ./serviceAccountKey.json)
//
// La vista previa se guarda junto al fichero de entrada como
// stores_seed_preview.json, para revisarla antes de subir.
//
// Se puede ejecutar varias veces: cada tienda se escribe con su id fijo, así
// que repetir la subida sobrescribe los documentos en vez de duplicarlos.

import fs from 'node:fs';
import path from 'node:path';

import { cert, initializeApp } from 'firebase-admin/app';
import { GeoPoint, getFirestore, Timestamp } from 'firebase-admin/firestore';
import { geohashForLocation } from 'geofire-common';
import opening_hours from 'opening_hours';

const COLLECTION = 'stores';
const DUPLICATE_RADIUS_M = 15; // misma cadena a menos de 15 m = la misma tienda
const BATCH_SIZE = 400; // Firestore admite hasta 500 escrituras por lote

// Cadenas que no se suben: venden sobre todo maquillaje o solo perfumes de
// marca propia, así que no sirven para encontrar un perfume del catálogo.
// Al subir, sus documentos se borran de Firestore si ya estaban.
const EXCLUDED_CHAINS = ['KIKO Milano', 'Yves Rocher', 'Rituals', 'Equivalenza'];

// Firestore no admite listas dentro de listas, así que el horario se guarda
// como un mapa { mon: [...], tue: [...], ... }. La Cloud Function lo
// convertirá en la lista de 7 días que espera la app.
const DAY_KEYS = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

// Semana de referencia para leer los horarios de OSM: del lunes 2 al domingo
// 8 de junio de 2025, sin festivos nacionales. Así "PH off" (festivos
// cerrado) no vacía ningún día por casualidad.
const REFERENCE_MONDAY = new Date(2025, 5, 2);

// Ubicación genérica en España para que opening_hours sepa qué festivos
// aplicar si un horario menciona PH.
const NOMINATIM_SPAIN = {
  lat: 40.4168,
  lon: -3.7038,
  address: { country_code: 'es', state: 'Comunidad de Madrid' },
};

// ---------------------------------------------------------------------------
// Normalización de cada tienda
// ---------------------------------------------------------------------------

/** "Elche/Elx" → "Elche"; "Donostia / San Sebastián" → "Donostia". */
function normalizeCity(city) {
  if (!city) return null;
  return city.split(/\s*\/\s*/)[0].trim() || null;
}

/** "+34 670 23 79 12; +34 915 22 98 82" → "+34 670 23 79 12". */
function normalizePhone(phone) {
  if (!phone) return null;
  return phone.split(';')[0].trim() || null;
}

function pad(n) {
  return String(n).padStart(2, '0');
}

/** Hora de una fecha como "HH:MM"; la medianoche del día siguiente es "24:00". */
function formatTime(date, dayStart) {
  const minutes = Math.round((date - dayStart) / 60000);
  return `${pad(Math.floor(minutes / 60))}:${pad(minutes % 60)}`;
}

/**
 * Convierte un horario de OSM ("Mo-Sa 10:00-14:00,17:00-20:30; Su off") en
 * { mon: ["10:00-14:00", "17:00-20:30"], ..., sun: [] }.
 * Devuelve null si no hay horario, si no se entiende o si no abre ningún día.
 */
function parseWeeklyHours(osmValue, stats) {
  if (!osmValue) return null;

  let oh;
  try {
    oh = new opening_hours(osmValue, NOMINATIM_SPAIN, { mode: 0 });
  } catch (error) {
    stats.hoursUnparsed.push(osmValue);
    return null;
  }

  const week = {};
  for (let day = 0; day < 7; day++) {
    const dayStart = new Date(REFERENCE_MONDAY);
    dayStart.setDate(dayStart.getDate() + day);
    const dayEnd = new Date(dayStart);
    dayEnd.setDate(dayEnd.getDate() + 1);

    // Tramos abiertos de ese día. opening_hours ya los recorta al rango que
    // le pedimos, así que un tramo que cruza medianoche queda partido en dos.
    const intervals = oh.getOpenIntervals(dayStart, dayEnd);
    week[DAY_KEYS[day]] = intervals.map(
      ([from, to]) => `${formatTime(from, dayStart)}-${formatTime(to, dayStart)}`,
    );
  }

  const opensSomeDay = DAY_KEYS.some((key) => week[key].length > 0);
  return opensSomeDay ? week : null;
}

/** Pasa una tienda del JSON de origen al formato del seeder (aún sin GeoPoint). */
function normalizeStore(raw, stats) {
  return {
    id: raw.id,
    chain: raw.cadena,
    address: raw.direccion || null,
    postalCode: raw.cp || null,
    city: normalizeCity(raw.ciudad),
    lat: raw.lat,
    lng: raw.lng,
    phone: normalizePhone(raw.telefono),
    weeklyHours: parseWeeklyHours(raw.horario_osm, stats),
    osmIds: raw.osm_ids,
  };
}

// ---------------------------------------------------------------------------
// Duplicados: el mismo local mapeado dos veces en OSM
// ---------------------------------------------------------------------------

function distanceMeters(a, b) {
  const R = 6371000;
  const rad = (deg) => (deg * Math.PI) / 180;
  const dLat = rad(b.lat - a.lat);
  const dLng = rad(b.lng - a.lng);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(rad(a.lat)) * Math.cos(rad(b.lat)) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}

/** Cuántos datos tiene una tienda; una dirección con número cuenta doble. */
function completeness(store) {
  let score = 0;
  for (const key of ['address', 'postalCode', 'city', 'phone', 'weeklyHours']) {
    if (store[key]) score++;
  }
  if (store.address && /\d/.test(store.address)) score++;
  return score;
}

/**
 * Agrupa las tiendas de la misma cadena que están a menos de
 * DUPLICATE_RADIUS_M entre sí y fusiona cada grupo en una sola: se queda la
 * más completa y rellena sus huecos con los datos de las demás.
 */
function mergeDuplicates(stores, stats) {
  const used = new Set();
  const result = [];

  for (let i = 0; i < stores.length; i++) {
    if (used.has(i)) continue;

    // Búsqueda en anchura: A cerca de B y B cerca de C → A, B y C juntas.
    const group = [i];
    used.add(i);
    for (let g = 0; g < group.length; g++) {
      for (let j = 0; j < stores.length; j++) {
        if (used.has(j)) continue;
        const a = stores[group[g]];
        const b = stores[j];
        if (a.chain === b.chain && distanceMeters(a, b) < DUPLICATE_RADIUS_M) {
          group.push(j);
          used.add(j);
        }
      }
    }

    if (group.length === 1) {
      result.push(stores[i]);
      continue;
    }

    const members = group.map((index) => stores[index]);
    members.sort((a, b) => completeness(b) - completeness(a));
    const merged = { ...members[0], osmIds: [] };
    for (const member of members) {
      for (const key of ['address', 'postalCode', 'city', 'phone', 'weeklyHours']) {
        if (!merged[key] && member[key]) merged[key] = member[key];
      }
      merged.osmIds.push(...member.osmIds);
    }
    stats.mergedGroups.push(members.map((m) => `${m.id} (${m.address ?? '¿?'})`));
    result.push(merged);
  }

  return result;
}

// ---------------------------------------------------------------------------
// Documento de Firestore
// ---------------------------------------------------------------------------

/** Lo que se guarda en stores/{id}. */
function toFirestoreDoc(store, now) {
  // Cadena que codifica la posición: tiendas cercanas comparten prefijo.
  const geohash = geohashForLocation([store.lat, store.lng]);
  return {
    chain: store.chain,
    address: store.address,
    postalCode: store.postalCode,
    city: store.city,
    location: new GeoPoint(store.lat, store.lng),
    geohash,
    // Prefijos de 3, 4 y 5 caracteres: la "celda" del mapa en la que cae la
    // tienda, de ~156 km, ~39 km y ~5 km de lado. La Cloud Function pide las
    // tiendas de varias celdas a la vez con un filtro "in" sobre uno de ellos.
    geohash3: geohash.slice(0, 3),
    geohash4: geohash.slice(0, 4),
    geohash5: geohash.slice(0, 5),
    phone: store.phone,
    weeklyHours: store.weeklyHours,
    osmIds: store.osmIds,
    updatedAt: now,
  };
}

/** Conecta con Firestore usando la clave de la cuenta de servicio. */
function connect(keyPath) {
  if (!fs.existsSync(keyPath)) {
    console.error(`\nNo encuentro la clave de la cuenta de servicio en ${keyPath}`);
    console.error('Descárgala en Firebase Console → Configuración del proyecto →');
    console.error('Cuentas de servicio → Generar nueva clave privada.');
    process.exit(1);
  }

  const serviceAccount = JSON.parse(fs.readFileSync(keyPath, 'utf8'));
  initializeApp({ credential: cert(serviceAccount) });
  console.log(`\nProyecto: ${serviceAccount.project_id}`);
  return getFirestore();
}

/** Borra de Firestore las tiendas de las cadenas excluidas. */
async function deleteExcluded(db) {
  const excluded = await db
    .collection(COLLECTION)
    .where('chain', 'in', EXCLUDED_CHAINS)
    .get();
  for (let start = 0; start < excluded.docs.length; start += BATCH_SIZE) {
    const batch = db.batch();
    for (const doc of excluded.docs.slice(start, start + BATCH_SIZE)) {
      batch.delete(doc.ref);
    }
    await batch.commit();
  }
  console.log(`Borradas ${excluded.docs.length} tiendas de cadenas excluidas.`);
}

async function upload(stores, db) {
  const now = Timestamp.now();

  console.log(`Subiendo ${stores.length} tiendas a ${COLLECTION}...`);
  for (let start = 0; start < stores.length; start += BATCH_SIZE) {
    const chunk = stores.slice(start, start + BATCH_SIZE);
    const batch = db.batch();
    for (const store of chunk) {
      batch.set(db.collection(COLLECTION).doc(store.id), toFirestoreDoc(store, now));
    }
    await batch.commit();
    console.log(`  ${start + chunk.length}/${stores.length}`);
  }
  console.log('Hecho.');
}

// ---------------------------------------------------------------------------
// Programa principal
// ---------------------------------------------------------------------------

async function main() {
  const args = process.argv.slice(2);
  let inputPath = null;
  let shouldUpload = false;
  let onlyDelete = false;
  let keyPath = './serviceAccountKey.json';
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--upload') {
      shouldUpload = true;
    } else if (args[i] === '--delete-excluded') {
      onlyDelete = true;
    } else if (args[i] === '--key') {
      keyPath = args[i + 1];
      i++; // el siguiente argumento es la ruta, no el fichero de entrada
      if (!keyPath) {
        console.error('Falta la ruta después de --key.');
        process.exit(1);
      }
    } else if (args[i].startsWith('--')) {
      // Una opción mal escrita (p. ej. --deleted-excluded) no debe tomarse
      // como el nombre del fichero de tiendas.
      console.error(`Opción desconocida: ${args[i]}`);
      process.exit(1);
    } else {
      inputPath = args[i];
    }
  }

  // Solo borrar: no hace falta el fichero de tiendas ni volver a subirlas.
  if (onlyDelete) {
    await deleteExcluded(connect(keyPath));
    return;
  }

  if (!inputPath) {
    console.error(
      'Uso: node seed_stores.mjs <tiendas.json> [--upload] [--key <ruta>]\n' +
        '     node seed_stores.mjs --delete-excluded [--key <ruta>]',
    );
    process.exit(1);
  }

  const raw = JSON.parse(fs.readFileSync(inputPath, 'utf8'));
  const stats = { hoursUnparsed: [], mergedGroups: [] };

  const kept = raw.filter((store) => !EXCLUDED_CHAINS.includes(store.cadena));
  const normalized = kept.map((store) => normalizeStore(store, stats));
  const stores = mergeDuplicates(normalized, stats);

  // Vista previa: lo mismo que se subiría, con lat/lng en vez de GeoPoint
  // para que se pueda leer como JSON normal.
  const preview = stores.map((store) => ({
    id: store.id,
    ...toFirestoreDoc(store, '(hora de subida)'),
    location: { lat: store.lat, lng: store.lng },
  }));
  const previewPath = path.join(path.dirname(inputPath), 'stores_seed_preview.json');
  fs.writeFileSync(previewPath, JSON.stringify(preview, null, 2));

  const count = (predicate) => stores.filter(predicate).length;
  console.log(`Tiendas de entrada:        ${raw.length}`);
  console.log(`Excluidas por cadena:      ${raw.length - kept.length}`);
  console.log(`Duplicados fusionados:     ${stats.mergedGroups.length} grupos`);
  for (const group of stats.mergedGroups) console.log(`   · ${group.join('  +  ')}`);
  console.log(`Tiendas a subir:           ${stores.length}`);
  console.log(`  con dirección:           ${count((s) => s.address)}`);
  console.log(`  con horario:             ${count((s) => s.weeklyHours)}`);
  console.log(`  con teléfono:            ${count((s) => s.phone)}`);
  console.log(`Horarios no entendidos:    ${stats.hoursUnparsed.length}`);
  for (const value of stats.hoursUnparsed) console.log(`   · ${value}`);
  console.log(`\nVista previa guardada en ${previewPath}`);

  if (shouldUpload) {
    const db = connect(keyPath);
    await upload(stores, db);
    await deleteExcluded(db);
  } else {
    console.log('No se ha subido nada. Revisa la vista previa y repite con --upload.');
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
