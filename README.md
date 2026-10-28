# ParfumDex

A mobile and web app for fragrance collectors: browse a perfume catalog, keep a personal vault of the bottles you own and (planned) work out how much liquid is left in an opaque bottle from its weight.

Built with **Flutter** and **Firebase** (Authentication + Cloud Firestore). Runs on **Android** and **Web**. iOS is not configured.

## Current features

- Onboarding (3 swipeable pages, shown only on first launch) and a splash screen.
- Email/password sign-up and sign-in, with specific messages for the common errors (email already in use, weak password, invalid credentials).
- Catalog of perfumes as a grid, with in-memory search by name, brand or note.
- Perfume detail: olfactory pyramid, seasons and retail offers. The URL carries the perfume id, so it survives a page reload on web.
- Personal vault: add perfumes from the detail screen; the list updates in real time. Free tier limited to 5 perfumes.
- Profile: view and edit your display name, sign out.
- Route guard: private screens redirect to login when there is no session.
- Google sign-in: Authentication with Google in Android and Web

Planned (see [ROADMAP.md](ROADMAP.md)): remaining-volume calculator from scale tare data, retail price comparison, edit/delete of vault items, an AI-assisted advisor.

## Architecture

```
lib/
  main.dart            Firebase + preferences init, MaterialApp.router
  routes/              app_routes.dart: route table, constants, redirect guard
  models/              Perfume, RetailOffer, TareInfo, UserProfile, VaultItem
  services/            auth_service, users_service, perfumes_service,
                       vault_service, preferences_service
  screens/             splash, onboarding, login, register, home_shell,
                       explore (catalog), perfume_detail, vault, profile
  widgets/             perfume_card, vault_item_card, search_bar_widget
  utils/               validators.dart (pure functions, no Flutter or Firebase)
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
- **Catalog uses a one-off `Future`; the vault uses a `Stream`.** Catalog data rarely changes, so reading once saves reads. The vault changes from another screen (the detail), so it listens with a manual subscription that is cancelled in `dispose()`.
- **Errors are not swallowed in the vault checks.** If the duplicate or limit check cannot run (offline, permissions), nothing is added and the user sees an error.

## Data model

| Path | Contents | Access (see `firestore.rules`) |
|---|---|---|
| `perfumes/{id}` | Catalog entry | Read: anyone. Write: nobody from the client. |
| `users/{uid}` | Profile (email, display name, created at, ...) | Owner only. |
| `users/{uid}/vault/{itemId}` | One owned bottle | Owner only. |

Minimal `perfumes` document (exact field names are in `lib/models/perfume.dart`; `prices` and `tareInfo` are optional):

```
name: "Dior Sauvage Eau de Toilette"   brand: "Dior"      concentration: "EDT"
nominalMl: 100                         imageUrl: "https://..."
season: ["spring", "summer"]
notes: { top: [...], heart: [...], base: [...] }
```

The catalog shipped with the maintainer's Firebase project is **sample data**: external image URLs and illustrative prices.

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
     When asked for the Android package name, use `com.parfumdex.parfum_dex`, or change `applicationId` in `android/app/build.gradle.kts` to match the one you register.
  3. Publish the rules in `firestore.rules` (Firebase console > Firestore > Rules, or `firebase deploy --only firestore:rules`).
  4. Create a few documents in `perfumes` following the data model above. The catalog is read-only for clients, so add them from the console.

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

### 4. Check

```bash
flutter analyze
```

## Using the app

1. **First launch:** swipe through the three onboarding pages, or skip. It is not shown again.
2. **Register** with an email, a display name and a password (6 or more characters), or **sign in** if you already have an account.
3. **Catalog tab:** browse the grid and use the search bar (name, brand or note). Tap a perfume to open its detail.
4. **Detail:** see notes, seasons and offers, and tap **Añadir a mi armario** (add to my wardrobe) to add it to your vault. Duplicates are blocked, and the free tier allows 5 perfumes.
5. **Vault tab:** your perfumes, updated in real time. A brand-new account shows an empty state with a shortcut to the catalog.
6. **Profile tab:** edit your display name or sign out.

## Configuration and credentials

- Credentials and per-project Firebase files are excluded by `.gitignore` (see the table above). Never commit service-account keys.
- **Onboarding flag:** whether onboarding was already seen is stored locally with `shared_preferences` (see `lib/services/preferences_service.dart`). To see onboarding again, clear the app data (Android) or the site data (web).

## Known limitations

- Display names are not unique.
- If creating the profile document fails right after sign-up, the account exists without a profile and the profile screen shows an error.
- The 5-perfume free limit is only enforced in the client.
- Catalog images are external URLs; some may be unavailable, and on web a third-party host can fail because of CORS.
- iOS is not configured.

## License

Not specified yet.
