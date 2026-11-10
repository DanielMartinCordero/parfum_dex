# ParfumDex

A mobile and web app for fragrance collectors: browse a perfume catalog, keep a personal vault of the bottles you own and (planned) work out how much liquid is left in an opaque bottle from its weight.

Built with **Flutter** and **Firebase** (Authentication + Cloud Firestore). Runs on **Android** and **Web**. iOS is not configured.

## Current features

- Onboarding (3 swipeable pages, shown only on first launch) and a splash screen.
- Email/password sign-up and sign-in, with specific messages for the common errors (email already in use, weak password, invalid credentials).
- Catalog of perfumes as a grid, with in-memory search by name, brand or note.
- Perfume detail: olfactory pyramid, seasons and retail offers. The URL carries the perfume id, so it survives a page reload on web.
- Personal vault: add perfumes from the detail screen; the list updates in real time. Free tier limited to 5 perfumes.
- Nearby perfume shops (at the end of every perfume detail): on tap, asks for location permission, finds the 5 closest of ~1,100 shops in Spain (OpenStreetMap data), shows them on a map and in a list sorted by distance, and opens a card with address, opening hours, phone and directions. If the device cannot give its position, it offers the area of the last search.
- Profile: view and edit your display name, see and delete the saved search area, sign out.
- Route guard: private screens redirect to login when there is no session.
- Google sign-in: Authentication with Google in Android and Web

Planned (see [ROADMAP.md](ROADMAP.md)): remaining-volume calculator from scale tare data, retail price comparison, edit/delete of vault items, an AI-assisted advisor.

## Architecture

```
lib/
  main.dart            Firebase + preferences init, MaterialApp.router
  routes/              app_routes.dart: route table, constants, redirect guard
  models/              Perfume, CatalogEntry, RetailOffer, TareInfo,
                       UserProfile, VaultItem
  services/            auth_service, users_service, perfumes_service,
                       catalog_search_service, vault_service,
                       preferences_service
    app_check_services/ App Check providers, debug token on web
    map_services/      location_service (geolocator), nearby_stores_service
                       (session cache), cloud_function_stores_repository,
                       distance_ranking/ (isolate on native, main thread on web)
  screens/             splash, onboarding, login, register, home_shell,
                       explore (catalog), perfume_detail, vault, profile
  widgets/             perfume_card, vault_item_card, search_bar_widget
    nearby_stores/     section (state machine), blurred placeholder,
                       flutter_map map, sorted list, shop details sheet
  config/              map_config.dart: tile server, user agent, attribution
  utils/               validators.dart, search_normalizer.dart,
                       distance_format.dart
                       (pure functions, no Flutter or Firebase)
functions/             Cloud Function nearbyStores (Python)
tools/seeder/          Node script that bulk-loads the catalog into Firestore
tools/stores/          Node scripts that geocode and load the shops
```

**Why it is split this way.** Each layer has one job, so a change in one place does not ripple through the rest:

- `models/` are plain, immutable Dart classes with `fromFirestore` / `toFirestore`. They know nothing about widgets.
- `services/` are the only layer that talks to Firebase. Screens ask a service for objects and never build Firestore queries themselves. The two intentional exceptions are the session check in the splash and in the router guard.
- `screens/` compose widgets and decide what to show for each state (loading, empty, error, data).
- `widgets/` are reusable pieces that receive data and callbacks; they do not navigate or fetch.
- `routes/` holds every path as a constant and the navigation rules in one place.
- `utils/` holds pure functions such as form validators, which are easy to test.

### Key decisions

- **Typed Firestore access.** Every service creates its collection reference once with `withConverter`, using the model's `fromFirestore` / `toFirestore` (`Perfume`, `UserProfile`, `VaultItem`). The app works with objects, not raw maps.
- **go_router.** It declares the whole route table in one place, supports URLs with parameters on web (`/explore/detail/:id`), and expresses the auth guard as a single `redirect` function. It is maintained by the Flutter team. The three tabs use `StatefulShellRoute`, which keeps each tab alive when switching.
- **`go` instead of `push` for the detail.** On web, `push` does not update the browser URL, so reloading would lose the screen. The detail is a nested route under the catalog, so the back button still returns to it.
- **Search over a single index document.** Firestore cannot search text inside a field, so the catalog screen downloads `catalog/searchIndex` once per session (1 read), a summary of every perfume (`CatalogEntry`), and searches it in memory. `CatalogSearchService` is a singleton, so the index stays loaded across screens. Results are ranked: name starts with the query, then word prefixes, then substrings, then notes. The full perfume is read only when its detail opens.
- **Catalog uses a one-off `Future`; the vault uses a `Stream`.** Catalog data rarely changes, so reading once saves reads. The vault changes from another screen (the detail), so it listens with a manual subscription that is cancelled in `dispose()`.
- **Wide-screen catalog (provisional).** From 900 px wide, the catalog shows a left panel reserved for future filters (notes, genre, season), and cards up to 220×320 px in at most 6 columns, centered with empty strips at the sides. Fewer cards on screen also keeps web scrolling smooth (see Known limitations). This logic lives in `explore_screen.dart` for now; the planned redesign will move layout decisions to one shared place.
- **Errors are not swallowed in the vault checks.** If the duplicate or limit check cannot run (offline, permissions), nothing is added and the user sees an error.
- **Nearby shops go through a Cloud Function.** Firestore cannot query by radius, so each shop stores its `geohash` (nearby points share a prefix) plus its 3-, 4- and 5-character prefixes, which are the map "cells" it falls in. The function `nearbyStores` (Python) works out which cells cover the search circle, fetches the shops in those cells with a single `in` query, and drops the ones outside the circle. It tries 2, 10, 25 and 40 km and stops at the first radius with 5 shops, so a search in a city centre reads only the shops within 2 km. Clients cannot read `stores` at all, so nobody can download the whole collection.
- **Location is asked for only on tap,** never when a detail opens. The result is cached in memory for 30 minutes and shared by every perfume detail; the refresh button searches again. The device position is never stored: only a rounded area (2 decimals, about 1 km) is saved in the user's own profile, so the next search can fall back to it, and the profile has a button to delete it.
- **OpenStreetMap tiles** are requested with the app's package name as user agent (`userAgentPackageName`), as their tile usage policy requires, and the attribution is always visible under the map. The public tile server is meant for light use; before a public release the tiles will move to a commercial provider (MapTiler).

## Data model

| Path | Contents | Access (see `lib/firestore.rules`) |
|---|---|---|
| `perfumes/{id}` | Catalog entry | Read: anyone. Write: nobody from the client. |
| `catalog/searchIndex` | Search index: `items` with id, brand, name, image, genre and notes of every perfume | Read: anyone. Write: nobody from the client (the seeder uses the Admin SDK). |
| `stores/{osmId}` | Perfume shop: `chain`, `address`, `postalCode`, `city`, `location` (GeoPoint), `geohash` and its prefixes `geohash3`/`geohash4`/`geohash5`, `phone`, `weeklyHours` (map `mon`..`sun` of `"HH:MM-HH:MM"` slots), `osmIds`, `updatedAt` (Timestamp) | Nobody from the client. Read by the `nearbyStores` function; written by `tools/stores/seed_stores.mjs`. |
| `users/{uid}` | Profile (email, display name, created at, ...). Optional `lastSearchLocation` (GeoPoint, rounded to ~1 km), `lastSearchAt` (Timestamp) and `lastSearchArea` (city of the closest shop) | Owner only. |
| `users/{uid}/vault/{itemId}` | One owned bottle | Owner only. |

Minimal `perfumes` document (exact field names are in `lib/models/perfume.dart`; `prices` and `tareInfo` are optional):

```
name: "Dior Sauvage Eau de Toilette"   brand: "Dior"      concentration: "EDT"
nominalMl: 100                         imageUrl: "https://..."
season: ["spring", "summer"]
notes: { top: [...], heart: [...], base: [...] }
```

The catalog shipped with the maintainer's Firebase project is **sample data**: external image URLs and illustrative prices.

## Location: GPS, network and the fused provider

A phone can work out where it is in three ways, and they trade accuracy for speed and battery:

| | How it works | Accuracy | Battery and speed | Works indoors |
|---|---|---|---|---|
| **GPS (GNSS)** | Times the signals of navigation satellites | 3–10 m outdoors; poor or none indoors and between tall buildings | The most expensive: the receiver stays on, and a cold start can take from seconds to a minute | Barely |
| **Network** | Looks up nearby Wi-Fi access points and cell towers in a database (a desktop browser may also use the IP address) | 20–100 m with Wi-Fi in a city; hundreds of metres to kilometres with cell towers only | Cheap and fast, but needs a connection and a mapped area | Yes |
| **Fused provider** | Android's Fused Location Provider (Google Play services) mixes GPS, Wi-Fi, cell and motion sensors, and keeps a recent fix that apps can reuse | Whatever the requested priority asks for: high (~10 m, uses GPS), balanced (~100 m), low power (~10 km, city level), passive (only fixes other apps asked for) | Turns GPS on only when the priority needs it | Yes |

**When to use each.** GPS is for turn-by-turn navigation, tracking a run or anything that needs metres. Network location is enough for "what is around me" at street or neighbourhood scale, and it is the only one that works well indoors. On Android the fused provider is the sensible default, because it chooses the source for the accuracy you ask for and reuses fixes; asking for GPS directly only makes sense when you need raw satellite data.

**What this app does.** Shops are searched within 2 km or more, so street-level accuracy is plenty. `LocationService` asks `geolocator` for `LocationAccuracy.medium`, which on Android maps to the fused provider's *balanced* priority (~100 m, Wi-Fi and cell, no GPS). `low` was considered and rejected: it maps to *low power*, which Google describes as city-level (~10 km), too coarse for the first 2 km radius. The Android manifest only declares `ACCESS_COARSE_LOCATION`, so the system may hand out an approximate position anyway, and the app works with it. On web, `medium` keeps `enableHighAccuracy` off, so the browser uses network location. If no position arrives in 15 seconds (`Future.timeout`, applied the same way on every platform), the app tries the last position Android has cached and otherwise offers the area of the previous search.

## Distance ranking in an isolate

The list under the map orders the shops by their distance to the user. The work is split like this:

- **In the Cloud Function (server, Python):** the geohash query, the radius filter and choosing the 5 closest shops. This is where the real work is, since it has to look at every shop near the user.
- **In an isolate (Android):** recomputing the distance from the user to each of those shops (haversine formula) and sorting them. The isolate reports its progress to the UI through a `SendPort`; the list shows it as a progress bar. The code is in `lib/services/map_services/distance_ranking/`.
- **On the main thread:** everything else, and the same ranking on web, because the browser has no Dart isolates (`dart:isolate` does not exist there). A conditional import picks `ranker_native.dart` or `ranker_web.dart`; the web version yields to the browser every 50 shops so the bar can repaint.

**Why, if 5 shops do not need it.** Sorting five (or twenty) items takes microseconds; running it in an isolate is not about speed. It was built to measure the real cost of an isolate and to know where the threshold is. Average of 20 runs on a desktop PC (`flutter test`, Dart VM), total time including starting the isolate and copying the data both ways:

| Points | Main thread | Isolate |
|---:|---:|---:|
| 5 | 0.02 ms | 0.27 ms |
| 20 | 0.02 ms | 0.41 ms |
| 1,093 (every shop in Spain) | 0.42 ms | 1.65 ms |
| 100,000 | 61 ms | 93 ms |

The isolate is always slower end to end, because spawning it and copying the list costs a fraction of a millisecond. It only pays off once the work on the main thread would no longer fit in a frame (16 ms at 60 fps): at 100,000 points the main thread would freeze the UI for about four frames, while the isolate keeps it responsive. For 5 shops the isolate is pure overhead, and the measurement shows exactly how much. A first version sent one progress message per point and was nine times slower than the main thread at 100,000 points; the ranking now reports at most 100 updates (one per 1%).

## Getting started

### Prerequisites

- Flutter SDK (run `flutter doctor` and fix anything it reports) and Dart as required by `pubspec.yaml`.
- Google Chrome for web; Android Studio with an emulator (or a device) for Android.
- A Firebase project (see below).

### 1. Clone and install

```bash
git clone https://github.com/DanielMartinCordero/parfum_dex.git
cd parfum_dex
flutter pub get
```

### 2. Firebase configuration files

These files are **not in version control** and the app does not compile without the first one:

| File | Purpose |
|---|---|
| `lib/firebase_options.dart` | Firebase options per platform, imported by `main.dart` |
| `android/app/google-services.json` | Android Firebase config |
| `ios/Runner/GoogleService-Info.plist` | iOS only; not used |

Choose one:

- **Use the maintainer's project:** ask the maintainer for the two files and place them at the paths above.
- **Use your own Firebase project:**
  1. Create a Firebase project and enable **Authentication > Email/Password** and **Firestore Database**.
  2. Install the FlutterFire CLI and run `flutterfire configure --platforms=android,web`.
     When asked for the Android package name, use `com.perfumedex.app`, or change `applicationId` in `android/app/build.gradle.kts` to match the one you register.
  3. Publish the rules in `lib/firestore.rules` (Firebase console > Firestore > Rules, or `firebase deploy --only firestore:rules`).
  4. Load the perfume shops: in `tools/stores`, run `npm install`, then `node seed_stores.mjs <shops.json>` to preview and add `--upload` to write them (same service-account key, saved as `tools/stores/serviceAccountKey.json`). Then deploy the function (it needs the Blaze plan). It is written in Python 3.14: in `functions`, create the virtual environment the Firebase CLI expects with `py -3.14 -m venv venv` (macOS/Linux: `python3.14 -m venv venv`), install the dependencies with `venv\Scripts\pip install -r requirements.txt` (macOS/Linux: `venv/bin/pip`), then run `firebase deploy --only functions` from the project root.
  5. Load the catalog with the seeder in `tools/seeder` (`npm install`, then `npm run dry-run` and `npm run seed`). It needs a service-account key at `tools/seeder/serviceAccountKey.json` and a perfumes JSON file (default `data/perfumes_demo.json`, or pass `--data <file>`); both are git-ignored, and the demo dataset is not in the repo. It writes both `perfumes` and `catalog/searchIndex`. The catalog screen lists what is in the index, so perfumes added by hand in the console do not appear there.

### 3. Run

```bash
# Web
flutter run -d chrome

# Android: start an emulator, then run
flutter emulators
flutter emulators --launch <emulator_id>
flutter run
```

If you change flow-level code (sign-up, navigation) while running, do a full restart; hot reload does not always apply it.

App Check is enforced by the `nearbyStores` function, and reCAPTCHA Enterprise does not issue valid tokens on localhost. For web debug runs, register a debug token once in Firebase console > App Check > (web app) > Manage debug tokens and pass it on every run: `flutter run -d chrome --dart-define=APPCHECK_DEBUG_TOKEN=<token>`. On Android debug builds the SDK prints its own debug token in Logcat the first time; register that one for the Android app.

### 4. Check

```bash
flutter analyze
flutter test
# Cloud Function logic (no emulator needed)
cd functions && venv\Scripts\python -m unittest -v
```

## Using the app

1. **First launch:** swipe through the three onboarding pages, or skip. It is not shown again.
2. **Register** with an email, a display name and a password (6 or more characters), or **sign in** if you already have an account.
3. **Catalog tab:** browse the grid and use the search bar (name, brand or note). Tap a perfume to open its detail.
4. **Detail:** see notes, seasons and offers, and tap **Añadir a mi armario** (add to my wardrobe) to add it to your vault. Duplicates are blocked, and the free tier allows 5 perfumes.
5. **Vault tab:** your perfumes, updated in real time. A brand-new account shows an empty state with a shortcut to the catalog.
6. **Nearby shops:** at the bottom of a perfume detail, tap **Ver perfumerías cercanas** and allow location. Tap a marker or a row of the list to open the shop card.
7. **Profile tab:** edit your display name, delete the saved search area, or sign out.

## Configuration and credentials

- Credentials and per-project Firebase files are excluded by `.gitignore` (see the table above). Never commit service-account keys.
- **Onboarding flag:** whether onboarding was already seen is stored locally with `shared_preferences` (see `lib/services/preferences_service.dart`). To see onboarding again, clear the app data (Android) or the site data (web).

## Known limitations

- Display names are not unique.
- If creating the profile document fails right after sign-up, the account exists without a profile and the profile screen shows an error.
- The 5-perfume free limit is only enforced in the client.
- Catalog images are external URLs; some may be unavailable. Their host does not allow CORS, so on web each image is drawn as an HTML `<img>` element, which makes scrolling heavy when many are on screen. Hosting the images ourselves with CORS would remove this.
- Web debug mode is much slower than release; judge scrolling with `flutter run -d chrome --release`.
- iOS is not configured.
- Opening hours of the nearby shops come from OpenStreetMap as a typical week, so public holidays and seasonal changes are not reflected, and a slot that crosses midnight is not detected as open.
- The map uses the public OpenStreetMap tile server, which is not meant for production traffic.

## License

Not specified yet.
