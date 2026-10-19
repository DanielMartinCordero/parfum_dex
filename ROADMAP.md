# Product Roadmap: ParfumDex 📱✨

| Attribute | Details |
| --- | --- |
| **Project** | ParfumDex |
| **Platform** | Flutter (Multiplatform: Android / Web) |
| **Backend & Auth** | Firebase (Auth & Cloud Firestore) |
| **Current Target** | Milestone 1 (Core Prototype & Cloud Sync) — **Mid October** |
| **Final Target** | Production MVP & Public Release (v1.0) — **Q1** |

---

## 1. Product Vision (v1.0 Architecture)

An end-to-end multiplatform ecosystem tailored for fragrance collectors and enthusiasts, unifying active inventory management, technical valuation utilities, and smart consumer market aggregation.

### Core System Features

* **Personal Vault (Active Inventory):**
* Tracking for full presentation bottles and decants/samples.
* Remaining liquid estimation with automated wear-cost amortization (cost per spray).
* Publicly shareable vaults accessible via unique handle (`@handle`).


* **Tare & Level Calculator (Marketplace Valuation):**
* Benchmark tare database (empty bottle and cap weights) for market-leading opaque and blind bottles.
* High-precision volume calculation using digital scale data combined with a visual level slider for clear glassware.
* Exportable digital authenticity and volume certification cards for resale platforms (Wallapop, Vinted).


* **Retail Deal Aggregator:**
* Market monitoring for major fragrance retailers (Primor, Druni, Sephora, Notino).
* Best-deal identification engine linked directly to affiliated storefronts.


* **Contextual AI Sommelier:**
* Conversational advisory layer powered by Retrieval-Augmented Generation (RAG).
* Dynamic recommendations generated strictly against the user's registered vault items, correlated with weather, occasion, and outfit profile.



---

## 2. Immediate Roadmap: Milestone 1 (Deadline: October 16)

> **Objective:** Deliver a functional, navigable multiplatform client backed by reactive Cloud Firestore persistence, satisfying strict architectural separation and cross-platform reliability standards.

### Technical Deliverables & Sprint Backlog

#### 1. Architecture & Source Control

* [x] Enforce strict domain/data/presentation separation under `lib/`:
* `lib/models/` (Data classes, domain models)
* `lib/screens/` (Stateful/Stateless page layouts)
* `lib/services/` (External APIs, Firebase abstractions)
* `lib/widgets/` (Reusable, atomic UI components)


* [x] Maintain structured version control with collaborator access enabled and a minimum of **15 progressive, semantic commits**.
* [x] Provide comprehensive `README.md` detailing architectural trade-offs and structural layers.

#### 2. Application Entry & Onboarding

* [x] **SplashScreen:** Remote image resolution via network URL, handling all asynchronous states:
* Loading state: Centered `CircularProgressIndicator`.
* Error state: Graceful fallback to bundled local asset (avoiding unhandled blank screens).


* [x] **OnboardingFlow:** 3-step swipeable carousel (introducing Vault, Tare Calculator, and Price Aggregator):
* Skip action toggle.
* Persistent execution flag backed by `shared_preferences` to prevent redundant presentations after initial launch.



#### 3. Identity & Lifecycle Management

* [x] Firebase Authentication implementation via email/password credentials.
* [x] Comprehensive exception handling with clear UI messaging for auth faults:
* `email-already-in-use`
* `weak-password`
* `invalid-credential` / `user-not-found` / `wrong-password`


* [x] Memory leak prevention: Deterministic cancellation of active data streams (`StreamSubscription.cancel()`) inside widget `dispose()` methods.
* [x] Security documentation: Register private client infrastructure files excluded by `.gitignore` (`google-services.json`, private keys).

#### 4. Typed Cloud Persistence (Firestore)

* [x] **`perfumes` collection:** Provision at least 6 canonical benchmark documents containing:
* `name` (*String*)
* `brand` (*String*)
* `imageUrl` (*String*)
* `notes` (*Map<String, List>*)
* `tareInfo` (*Map*: empty bottle weight, cap weight, liquid density)
* `retailPrices` (*List*)


* [x] **`users` collection:** Base profile records linked directly to the authenticated UID.
* [x] Strict domain mapping via **`.withConverter`** on all Firestore references, enforcing immutable data objects over untyped `Map<String, dynamic>` maps.

#### 5. Declarative Routing & Dynamic Collections

* [x] Centralized named route definitions on `MaterialApp` with strongly-typed argument routing (avoiding inline widget instantiations).
* [x] **Persistent BottomNavigationBar** orchestrating 3 core view targets:
* **View 1 (Catalog - `GridView`):** Master collection grid with remote cover image, name, brand, and best-price indicator.
* **View 2 (Personal Vault - `ListView`):** User inventory list with dynamic remaining fluid level indicators.
* **View 3 (Profile):** Aggregated vault metrics and clean sign-out orchestration.


* [x] Mandatory asynchronous state feedback across all collection screens:
1. *Loading:* Centered indicator / skeleton shimmer.
2. *Empty:* Contextual illustration with corrective action CTA.
3. *Error:* Explicit failure state with an active retry handler.



#### 6. Multiplatform Verification & QA

* [x] Cross-platform execution parity verified on both target runtimes:
* Android Emulator / Physical Device.
* Desktop Web (Chromium Engine).


* [x] Documented QA verification matrix covering test scenario, expected behavior, actual result, and web/native runtime differences (e.g., CORS handling).
* [x] Zero-friction setup guide in `README.md` enabling clean clone-and-run execution.

---

## 3. Engineering Phase Roadmap

```text
[October]   ──> Milestone 1: Cross-Platform Client & Reactive Cloud Core
[December]  ──> Milestone 2: Offline-First Architecture & Bidirectional Sync
[February]  ──> Milestone 3: Concurrent Scraping Worker & AI Sommelier Gateway
[March]     ──> Milestone 4: Security Audit, Profiling & v1.0 Production Release

```