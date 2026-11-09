"""Corte automático de facturación (kill switch) de ParfumDex.

Escucha el tema de Pub/Sub `budget-alerts`, donde publican:
  - el presupuesto de Cloud Billing (varias veces al día):
      {"costAmount": 0.37, "budgetAmount": 2.0, "currencyCode": "EUR", ...}
  - las alertas de Cloud Monitoring (paso 5), en cuanto salta un pico:
      {"incident": {"state": "open", "policy_name": "...", ...}, "version": "1.2"}

Si el gasto llega al presupuesto, o si se abre una alerta de Monitoring,
desvincula la cuenta de facturación del proyecto: todo lo de pago se para.
Para volver, se revincula a mano en Facturación > Mis proyectos.

No tiene URL pública: solo la dispara un mensaje del tema.
"""

import os

from firebase_functions import options, pubsub_fn
from google.cloud import billing_v1

PROJECT_ID = os.environ.get("GCLOUD_PROJECT", "parfumdex")
PROJECT_NAME = f"projects/{PROJECT_ID}"

# Con KILL_SWITCH_DRY_RUN=1 (en functions/.env) solo escribe en el log lo
# que haría. Útil para la primera prueba.
DRY_RUN = os.environ.get("KILL_SWITCH_DRY_RUN") == "1"


@pubsub_fn.on_message_published(
    topic="budget-alerts",
    region="europe-southwest1",
    max_instances=1,
    timeout_sec=60,
    memory=options.MemoryOption.MB_256,
    # Cuenta de servicio propia, con un único rol: gestor de facturación del
    # proyecto. Así no hay que dar permisos de facturación a la cuenta por
    # defecto (que tiene rol Editor y usan las demás funciones).
    service_account=f"billing-killer@{PROJECT_ID}.iam.gserviceaccount.com",
)
def stopBilling(event: pubsub_fn.CloudEvent[pubsub_fn.MessagePublishedData]) -> None:  # noqa: N802
    try:
        data = event.data.message.json
    except Exception:  # mensaje que no es JSON
        data = None
    if not isinstance(data, dict):
        print("Mensaje sin JSON válido: se ignora.")
        return

    reason = should_cut(data)
    if reason is None:
        print(f"Sin corte. Gasto {data.get('costAmount')} / presupuesto {data.get('budgetAmount')}.")
        return

    client = billing_v1.CloudBillingClient()
    info = client.get_project_billing_info(name=PROJECT_NAME)
    if not info.billing_enabled:
        print("La facturación ya estaba desactivada.")
        return

    if DRY_RUN:
        print(f"[DRY RUN] Se cortaría la facturación. Motivo: {reason}")
        return

    client.update_project_billing_info(
        name=PROJECT_NAME,
        # Cuenta vacía = desvincular la facturación del proyecto.
        project_billing_info=billing_v1.ProjectBillingInfo(billing_account_name=""),
    )
    print(f"FACTURACIÓN DESACTIVADA. Motivo: {reason}")


def should_cut(data: dict):
    """Devuelve el motivo del corte, o None si no hay que cortar.

    Lógica pura (sin red): se puede probar con pytest como nearby.py.
    """
    # Alerta de Cloud Monitoring: se corta cuando se abre (no al cerrarse).
    incident = data.get("incident")
    if isinstance(incident, dict):
        if incident.get("state") == "open":
            return f"alerta de Monitoring: {incident.get('policy_name')}"
        return None

    # Notificación del presupuesto.
    cost = data.get("costAmount")
    budget = data.get("budgetAmount")
    numbers = all(
        isinstance(v, (int, float)) and not isinstance(v, bool) for v in (cost, budget)
    )
    if numbers and budget > 0 and cost >= budget:
        return f"presupuesto: {cost} >= {budget}"
    return None
