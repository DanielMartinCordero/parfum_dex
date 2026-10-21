# Product Roadmap: ParfumDex 📱✨

| Attribute | Details |
| --- | --- |
| **Project** | ParfumDex |
| **Platform** | Flutter (Multiplatform: Android / Web) |
| **Backend & Auth** | Firebase (Auth & Cloud Firestore) |
| **Current Target** | Milestone 1b (Google Sign-In, vault editing, photos, location & store map) + H1 scope freeze — **13 November 2026** |
| **Final Target** | Signed build in Google Play closed testing — **19 February 2027**; defence **8–12 March 2027** (public production release is optional) |

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



> **Scope note:** the committed scope is frozen at milestone H1 (13 November 2026) and cannot be reduced afterwards, only extended. Until then every feature below is a candidate. Recommended MVP: Personal Vault + store map. Tare Calculator and AI Sommelier are extensions.

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

## 2b. Next: Milestone 1b (Deadline: November 13)

> **Objective:** Photos, location and queries on top of Milestone 1, delivered with tag `fase-1b` and the H1 documents (architecture diagram, justified technologies, marked requirements checklist, planned in-app products and ads, `CLAUDE.md`).

### Product decisions (October 21)

* No community-generated content: the catalogue and the personal vault are the data.
* Photo: picture of the user's own bottle, stored with the vault item.
* Location: the user's position, stored in their profile.
* Store map under each perfume: a "Show nearby stores" button asks for location permission and shows branches of the retail chains listed in the perfume's `prices`. Stock is never claimed.
* `tiendas` collection: 20-30 branches of retail chains in the author's province, loaded by script. Neighbourhood perfumeries are out of scope.

### Week 1 · Oct 21-27: Google & vault

- [ ] Review and merge PR #1 (rules at repo root, `firebase.json`, seed script)
- [ ] Google Sign-In on Android and web (SHA-1 / SHA-256, cancellation and error states, profile created or recovered)
- [ ] README: SHA fingerprints, OAuth client, files that are not committed
- [ ] Edit and add vault item attributes with `update`, delete with confirmation and error state
- [ ] Auth and Firestore emulators behind `--dart-define=USE_EMULATORS=true`
- [ ] `CLAUDE.md` and `IA.md` (first draft)

### Week 2 · Oct 28 - Nov 3: card, queries & photo

- [ ] Card redesign (time-boxed to 2 sessions)
- [ ] Catalogue of 20+ perfumes with a date field; 4 queries (two `where` conditions, `orderBy` + `limit`, date range, `startAfterDocument` pagination); index in `firestore.indexes.json`
- [ ] README: snapshot vs one-off `get` per screen, and why
- [ ] Bottle photo from camera and gallery, permissions and denial handled
- [ ] Compression in an isolate with progress; thumbnail under 300 KB as base64 in the document

### Week 3 · Nov 4-10: stores & map

- [ ] `tiendas` collection with `GeoPoint`, loaded by script
- [ ] "Show nearby stores": permission, position with `geolocator`, denied / GPS off / timeout handled
- [ ] Save position (`GeoPoint` + `Timestamp`) in the user profile
- [ ] `flutter_map` with one marker per store, OpenStreetMap attribution and `userAgentPackageName`; tapping a marker opens the detail
- [ ] "Near me" list sorted by distance in an isolate with progress
- [ ] README: GPS vs network vs fused provider comparison

### Week 4 · Nov 11-13: delivery

- [ ] Exported test data importable with one command
- [ ] `flutter build web` and Firebase Hosting deployment, public URL in the README
- [ ] Test table for Android and web (permissions denied, GPS off, offline)
- [ ] README verified on a clean clone
- [ ] H1 documents
- [ ] Tag `fase-1b` and short PDF to the virtual classroom

---

## 3. Engineering Phase Roadmap

```text
[Oct 16]      ──> H0 + Phase 1: Cross-Platform Client & Reactive Cloud Core (done)
[Nov 13]      ──> H1 + Phase 1b: Google Sign-In, photos, location, store map, emulators, Hosting
[Dec 4/18]    ──> Phase 2 / H2: Offline-First Architecture (Drift), sync, backup export/import
[Jan 29]      ──> Phase 3 / H3: Own service (API + WebSocket), push notifications, purchase validation
[Feb 19]      ──> Phase 4 / H4: Billing, ads, relational DB, roles, signed .aab in closed testing
                  (closed testing must start by Feb 22)
[Feb 26]      ──> H5: Test log and tester bug fixes
[Mar 5]       ──> H6: Release candidate, manuals, IA.md, slides
[Mar 8-12]    ──> H7: Presentation and defence (Mar 18: H8 recovery)
```
