// Completa dirección, código postal y localidad de las tiendas que no los
// traen, usando la geocodificación inversa de Nominatim (OpenStreetMap).
//
// Uso:
//   node tools/stores/enrich_addresses.mjs <entrada.json> [salida.json] [--limit N]
//
// - Solo consulta las tiendas a las que les falta algún campo; los valores
//   que ya vienen en el fichero no se tocan.
// - Respeta la política de uso de Nominatim: 1 petición por segundo como
//   máximo y un User-Agent que identifica la aplicación.
// - Guarda cada respuesta en data/nominatim_cache.json, así que se puede
//   cortar y relanzar sin repetir peticiones.
// - Los datos devueltos son de OSM (ODbL), la misma licencia que el fichero.

import fs from 'node:fs';
import path from 'node:path';

const args = process.argv.slice(2);
const limitIdx = args.indexOf('--limit');
const limit = limitIdx >= 0 ? Number(args[limitIdx + 1]) : Infinity;
const positional = args.filter(
  (a, i) => !a.startsWith('--') && (limitIdx < 0 || i !== limitIdx + 1),
);
const [inputPath, outputPath = 'data/tiendas_enriquecidas.json'] = positional;

if (!inputPath) {
  console.error('Uso: node tools/stores/enrich_addresses.mjs <entrada.json> [salida.json] [--limit N]');
  process.exit(1);
}

const CACHE_PATH = 'data/nominatim_cache.json';
const USER_AGENT = 'PerfumeDex-store-seeder/1.0 (one-off reverse geocoding of OSM shops)';
const DELAY_MS = 1100;

fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.mkdirSync(path.dirname(CACHE_PATH), { recursive: true });

const stores = JSON.parse(fs.readFileSync(inputPath, 'utf8'));
const cache = fs.existsSync(CACHE_PATH) ? JSON.parse(fs.readFileSync(CACHE_PATH, 'utf8')) : {};

const isEmpty = (v) => v == null || String(v).trim() === '';
const needsLookup = (s) => isEmpty(s.direccion) || isEmpty(s.cp) || isEmpty(s.ciudad);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function reverse(lat, lng) {
  const url = new URL('https://nominatim.openstreetmap.org/reverse');
  url.search = new URLSearchParams({
    lat: String(lat),
    lon: String(lng),
    format: 'jsonv2',
    addressdetails: '1',
    zoom: '18',
    'accept-language': 'es',
  }).toString();

  for (let attempt = 1; attempt <= 4; attempt++) {
    const res = await fetch(url, { headers: { 'User-Agent': USER_AGENT } });
    if (res.ok) return res.json();
    if (res.status === 429 || res.status >= 500) {
      const wait = 5000 * attempt;
      console.warn(`  HTTP ${res.status}, reintento en ${wait / 1000}s`);
      await sleep(wait);
      continue;
    }
    throw new Error(`HTTP ${res.status}`);
  }
  throw new Error('Demasiados reintentos');
}

function extract(result) {
  const a = result?.address ?? {};
  const road = a.road ?? a.pedestrian ?? a.footway ?? a.square ?? null;
  const direccion = road ? [road, a.house_number].filter(Boolean).join(' ') : null;
  const ciudad = a.city ?? a.town ?? a.village ?? a.municipality ?? a.hamlet ?? null;
  return { direccion, cp: a.postcode ?? null, ciudad };
}

const pending = stores.filter((s) => needsLookup(s) && !cache[s.id]).slice(0, limit);
console.log(`${stores.length} tiendas, ${stores.filter(needsLookup).length} incompletas, ` +
  `${pending.length} por consultar (~${Math.ceil((pending.length * DELAY_MS) / 60000)} min)`);

let done = 0;
for (const s of pending) {
  try {
    cache[s.id] = await reverse(s.lat, s.lng);
  } catch (e) {
    console.warn(`  ${s.id}: ${e.message}`);
  }
  done++;
  if (done % 25 === 0 || done === pending.length) {
    fs.writeFileSync(CACHE_PATH, JSON.stringify(cache));
    console.log(`  ${done}/${pending.length}`);
  }
  await sleep(DELAY_MS);
}
fs.writeFileSync(CACHE_PATH, JSON.stringify(cache));

// Rellena solo los huecos y marca de dónde sale cada campo completado.
const filled = { direccion: 0, cp: 0, ciudad: 0 };
const output = stores.map((s) => {
  const hit = cache[s.id];
  if (!needsLookup(s) || !hit) return s;
  const found = extract(hit);
  const out = { ...s };
  const added = [];
  for (const key of ['direccion', 'cp', 'ciudad']) {
    if (isEmpty(s[key]) && !isEmpty(found[key])) {
      out[key] = found[key];
      filled[key]++;
      added.push(key);
    }
  }
  if (added.length) out.campos_geocodificados = added;
  return out;
});

fs.writeFileSync(outputPath, JSON.stringify(output, null, 1));
console.log('Campos completados:', filled);
console.log('Siguen sin dato:', {
  direccion: output.filter((s) => isEmpty(s.direccion)).length,
  cp: output.filter((s) => isEmpty(s.cp)).length,
  ciudad: output.filter((s) => isEmpty(s.ciudad)).length,
});
console.log(`Escrito ${outputPath}`);
