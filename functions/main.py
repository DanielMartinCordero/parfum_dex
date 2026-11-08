"""Cloud Function `nearbyStores`: las perfumerías más cercanas a una posición.

Petición  {lat, lng}
Respuesta {radiusKm, stores: [{id, chain, address, postalCode, city, lat,
           lng, distanceKm, phone, weeklyHours}]}

Prueba radios de 2, 10, 25 y 40 km y se queda con el primero que reúna 5
tiendas; si ninguno llega, devuelve las que haya a 40 km (quizá ninguna).
Empezar por el radio pequeño abarata las ciudades grandes: en el centro de
Madrid basta con leer las tiendas a 2 km en vez de todas las de 40 km.

La posición del usuario no se guarda ni se escribe en los logs.
"""

from firebase_admin import firestore, initialize_app
from firebase_functions import https_fn, options
from google.cloud.firestore_v1.base_query import FieldFilter

import nearby

initialize_app()

# Madrid: la región más cercana a los usuarios. max_instances pone un techo
# al número de instancias (y a la factura) si algo empieza a llamar en bucle.
options.set_global_options(region="europe-southwest1", max_instances=10)

STORES = "stores"


@https_fn.on_call()
def nearbyStores(req: https_fn.CallableRequest) -> dict:  # noqa: N802 (nombre que usa la app)
    center = nearby.parse_center(req.data)
    if center is None:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="Se esperaba {lat, lng} numéricos.",
        )

    db = firestore.client()
    largest_radius = nearby.RADII_KM[-1]

    for radius_km in nearby.RADII_KM:
        stores = _stores_within(db, center, radius_km)
        if len(stores) >= nearby.MAX_RESULTS or radius_km == largest_radius:
            return {"radiusKm": radius_km, "stores": stores[: nearby.MAX_RESULTS]}

    # No se llega nunca: el último radio siempre devuelve.
    raise https_fn.HttpsError(
        code=https_fn.FunctionsErrorCode.INTERNAL,
        message="Sin resultado.",
    )


def _stores_within(db, center, radius_km):
    """Tiendas a menos de radius_km del centro, ordenadas por distancia.

    Firestore no sabe buscar por radio. Cada tienda guarda los prefijos de su
    geohash (geohash3, geohash4, geohash5): las tiendas de la misma "celda"
    del mapa comparten prefijo. Se calculan las celdas que cubren el círculo,
    se piden las tiendas de esas celdas en una sola consulta "in" y se
    descartan las que caen fuera del círculo.
    """
    precision, cells = nearby.choose_cells(center, radius_km)
    query = db.collection(STORES).where(
        filter=FieldFilter(f"geohash{precision}", "in", sorted(cells))
    )

    candidates = []
    for doc in query.stream():
        candidates.append(nearby.to_response(doc.id, doc.to_dict(), center))
    return nearby.within_radius(candidates, radius_km)
