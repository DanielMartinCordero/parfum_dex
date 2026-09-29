# ParfumDex 📱

> Open-source mobile and web application designed for fragrance collectors and enthusiasts. Manage your personal vault, compute remaining volume in opaque bottles using scale tare data, and aggregate real-time retail pricing.

Built with **Flutter** & **Firebase**.

_Soon deployed in Play Store and Web._

---

## 🏛️ Architecture & Project Structure

The project follows a clean, modular structure under the `lib/` directory to ensure separation of concerns, testability, and maintainability:

* **`models/` (Domain Layer):** Immutable Dart data classes representing business entities (`Perfume`, `UserProfile`). Handles serialization (`fromFirestore` / `toFirestore`) with strict null-safety, completely decoupled from the UI layer.
* **`services/` (Data & Infrastructure Layer):** Encapsulates external APIs, authentication flows (`FirebaseAuth`), and cloud persistence (`Cloud Firestore`). View layers do not access database drivers directly.
* **`screens/` (Presentation / Views):** Stateful and stateless components managing layout structure (`Scaffold`), stream lifecycles, and declarative routing.
* **`widgets/` (Reusable UI Components):** Atomic visual elements (perfume grid cards, liquid level indicators, asynchronous state feedback widgets).

---

##  Roadmap & Features

For a detailed breakdown of current deliverables, upcoming background scraping workers, and architectural milestones, see [ROADMAP.md](ROADMAP.md).

---

##  Configuration & Credentials

For security purposes, sensitive infrastructure credentials are not committed to version control and are excluded via `.gitignore`:
* `android/app/google-services.json`
* `ios/Runner/GoogleService-Info.plist`
* Local environment files (`.env`)