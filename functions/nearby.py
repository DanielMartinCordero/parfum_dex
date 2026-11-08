"""Lógica pura de la búsqueda de tiendas cercanas.

No usa Firestore ni red, así que se puede probar sin emulador
(ver test_nearby.py). main.py la usa para atender las peticiones.
"""

import math

import pygeohash
from haversine import haversine

# Radios que se prueban en orden, en km.
RADII_KM = (2, 10, 25, 40)

# Cuántas tiendas se devuelven como mucho.
MAX_RESULTS = 5

# Claves del horario en Firestore, de lunes a domingo.
DAY_KEYS = ("mon", "tue", "wed", "thu", "fri", "sat", "sun")

# Cada tienda guarda los prefijos de 5, 4 y 3 caracteres de su geohash
# (campos geohash5, geohash4 y geohash3). Se prueban de más fino a más grueso.
PRECISIONS = (5, 4, 3)

# Firestore admite como mucho 30 valores en un filtro "in".
MAX_CELLS = 30

# Kilómetros que mide un grado de latitud (casi constante en toda la Tierra).
KM_PER_DEGREE = 111.32


def parse_center(data):
    """Devuelve (lat, lng) si la petición trae {lat, lng} válidos, o None."""
    if not isinstance(data, dict):
        return None

    lat = data.get("lat")
    lng = data.get("lng")
    for value in (lat, lng):
        # En Python, True y False también son int: se descartan aparte.
        if isinstance(value, bool) or not isinstance(value, (int, float)):
            return None
        if not math.isfinite(value):
            return None

    if not (-90 <= lat <= 90 and -180 <= lng <= 180):
        return None
    return (float(lat), float(lng))


def cell_size_degrees(precision):
    """Alto y ancho, en grados, de una celda de geohash de esa precisión.

    Cada carácter del geohash son 5 bits, que se reparten alternando entre
    longitud y latitud (la longitud se lleva el bit sobrante).
    """
    bits = 5 * precision
    lng_bits = (bits + 1) // 2
    lat_bits = bits // 2
    return 180 / 2**lat_bits, 360 / 2**lng_bits


def covering_cells(center, radius_km, precision):
    """Celdas de geohash de esa precisión que cubren el círculo.

    Se recorre el rectángulo que envuelve el círculo en pasos del tamaño de
    una celda y se anota la celda de cada punto. Puede incluir alguna celda
    que solo roce el círculo: within_radius descarta después lo que sobra.
    """
    lat, lng = center
    # Medio lado del rectángulo, en grados. Un grado de longitud mide menos
    # cuanto más lejos del ecuador, por eso se divide por el coseno.
    half_lat = radius_km / KM_PER_DEGREE
    half_lng = radius_km / (KM_PER_DEGREE * max(math.cos(math.radians(lat)), 0.01))
    cell_lat, cell_lng = cell_size_degrees(precision)

    lat_steps = math.ceil(2 * half_lat / cell_lat) + 1
    lng_steps = math.ceil(2 * half_lng / cell_lng) + 1

    cells = set()
    for i in range(lat_steps + 1):
        point_lat = min(lat - half_lat + i * cell_lat, lat + half_lat)
        point_lat = max(-89.999999, min(89.999999, point_lat))
        for j in range(lng_steps + 1):
            point_lng = min(lng - half_lng + j * cell_lng, lng + half_lng)
            point_lng = (point_lng + 180) % 360 - 180  # vuelta al rango -180..180
            cells.add(pygeohash.encode(point_lat, point_lng, precision=precision))
    return cells


def choose_cells(center, radius_km):
    """Elige la precisión más fina cuyas celdas quepan en un solo filtro "in".

    Celdas más finas = menos tiendas leídas de más. Devuelve
    (precisión, celdas).
    """
    for precision in PRECISIONS:
        cells = covering_cells(center, radius_km, precision)
        if len(cells) <= MAX_CELLS:
            return precision, cells
    precision = PRECISIONS[-1]
    return precision, covering_cells(center, radius_km, precision)


def weekly_hours_to_list(hours):
    """Firestore no admite listas dentro de listas, así que el horario se
    guarda como mapa {"mon": [...], ...}. La app espera 7 listas en orden."""
    if not hours:
        return None
    return [list(hours.get(key, [])) for key in DAY_KEYS]


def to_response(doc_id, doc, center):
    """Convierte un documento de stores en lo que espera la app
    (NearbyStore.fromMap), con su distancia al centro."""
    location = doc["location"]
    lat = location.latitude
    lng = location.longitude
    return {
        "id": doc_id,
        "chain": doc.get("chain") or "Perfumería",
        "address": doc.get("address"),
        "postalCode": doc.get("postalCode"),
        "city": doc.get("city"),
        "lat": lat,
        "lng": lng,
        # haversine devuelve km. Tres decimales (metros) bastan.
        "distanceKm": round(haversine((lat, lng), center), 3),
        "phone": doc.get("phone"),
        "weeklyHours": weekly_hours_to_list(doc.get("weeklyHours")),
    }


def within_radius(stores, radius_km):
    """Se queda con las tiendas que de verdad están dentro del radio (las
    celdas cubren algo más que el círculo), sin repetidas, de más cerca a
    más lejos."""
    seen = set()
    result = []
    for store in stores:
        if store["id"] in seen:
            continue
        seen.add(store["id"])
        if store["distanceKm"] <= radius_km:
            result.append(store)
    result.sort(key=lambda store: store["distanceKm"])
    return result
