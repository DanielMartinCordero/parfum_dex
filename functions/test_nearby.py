"""Pruebas de la lógica pura, sin emulador.

Desde functions/:  venv\\Scripts\\python -m unittest -v
"""

import math
import unittest
from types import SimpleNamespace

import pygeohash

import nearby

MADRID = (40.4169, -3.7035)


def store_doc(lat, lng):
    """Documento de stores mínimo. SimpleNamespace imita al GeoPoint de
    Firestore: un objeto con .latitude y .longitude."""
    return {
        "chain": "Druni",
        "city": "Madrid",
        "location": SimpleNamespace(latitude=lat, longitude=lng),
        "weeklyHours": None,
    }


class ParseCenterTest(unittest.TestCase):
    def test_acepta_coordenadas_validas(self):
        self.assertEqual(nearby.parse_center({"lat": 40.4, "lng": -3.7}), (40.4, -3.7))
        self.assertEqual(nearby.parse_center({"lat": 40, "lng": -3}), (40.0, -3.0))

    def test_rechaza_lo_demas(self):
        self.assertIsNone(nearby.parse_center(None))
        self.assertIsNone(nearby.parse_center({"lat": "40", "lng": -3.7}))
        self.assertIsNone(nearby.parse_center({"lat": True, "lng": -3.7}))
        self.assertIsNone(nearby.parse_center({"lat": 95, "lng": 0}))
        self.assertIsNone(nearby.parse_center({"lat": math.nan, "lng": 0}))


class CellsTest(unittest.TestCase):
    def test_la_celda_del_centro_siempre_esta(self):
        for radius in nearby.RADII_KM:
            precision, cells = nearby.choose_cells(MADRID, radius)
            self.assertIn(pygeohash.encode(*MADRID, precision=precision), cells)

    def test_caben_en_un_filtro_in(self):
        for radius in nearby.RADII_KM:
            _, cells = nearby.choose_cells(MADRID, radius)
            self.assertLessEqual(len(cells), nearby.MAX_CELLS)

    def test_cubren_los_bordes_del_circulo(self):
        # Puntos a radius km al norte, sur, este y oeste: sus celdas deben
        # estar entre las elegidas, o esas tiendas no se encontrarían.
        lat, lng = MADRID
        for radius in nearby.RADII_KM:
            precision, cells = nearby.choose_cells(MADRID, radius)
            dlat = radius / nearby.KM_PER_DEGREE
            dlng = radius / (nearby.KM_PER_DEGREE * math.cos(math.radians(lat)))
            for point in [(lat + dlat, lng), (lat - dlat, lng), (lat, lng + dlng), (lat, lng - dlng)]:
                self.assertIn(pygeohash.encode(*point, precision=precision), cells)


class ResponseTest(unittest.TestCase):
    def test_horario_a_siete_dias_en_orden(self):
        week = nearby.weekly_hours_to_list({"mon": ["10:00-14:00"], "sun": []})
        self.assertEqual(len(week), 7)
        self.assertEqual(week[0], ["10:00-14:00"])
        self.assertEqual(week[1], [])  # martes no venía: cerrado
        self.assertIsNone(nearby.weekly_hours_to_list(None))

    def test_distancia_en_km(self):
        store = nearby.to_response("a", store_doc(40.4259, -3.7035), MADRID)  # ~1 km al norte
        self.assertAlmostEqual(store["distanceKm"], 1.0, delta=0.05)
        self.assertEqual(store["lat"], 40.4259)

    def test_within_radius_filtra_quita_repetidas_y_ordena(self):
        near = nearby.to_response("near", store_doc(40.42, -3.70), MADRID)
        mid = nearby.to_response("mid", store_doc(40.44, -3.70), MADRID)
        far = nearby.to_response("far", store_doc(40.60, -3.70), MADRID)  # ~20 km
        result = nearby.within_radius([far, mid, near, near], 10)
        self.assertEqual([s["id"] for s in result], ["near", "mid"])


if __name__ == "__main__":
    unittest.main()
