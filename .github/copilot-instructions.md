<!-- Copilot instructions for the shop_app Flutter project -->
# shop_app — Copilot instructions

Keep suggestions concise and focused on this Flutter app's conventions.

- Big picture
  - This is a small Flutter app using Provider for state and Supabase for backend (auth + Postgres-like tables).
  - Entrypoint: `lib/main.dart` — initializes Supabase and wires `MultiProvider` with `ProductsProvider` and `CartProvider`.
  - UI layers live in `lib/screens/` and reusable pieces in `lib/widgets/` (see `widgets/auth_wrapper.dart`).
  - Business logic and backend access are encapsulated in services under `lib/services/` (e.g., `cart_service.dart`, `auth_service.dart`).
  - App state (in-memory) and UI synchronization use ChangeNotifier-based providers in `lib/providers/` (e.g., `products_provider.dart`, `cart_provider.dart`).

- What to change and how
  - When you modify state backed by the server, prefer updating services in `lib/services/` and then call provider methods in `lib/providers/` that notify listeners. Example: `CartService.addItem(...)` -> `CartProvider.addItem(...)`.
  - Keep Supabase client usage centralized: `lib/main.dart` initializes `Supabase.initialize(...)` and exposes `supabase` client variable used across services and providers.
  - Database table names (used by Supabase) are literal strings in services: `products` and `cart_items`. Use these exact names when writing queries.

- Patterns & conventions (examples)
  - Auth flow: `widgets/auth_wrapper.dart` listens to `supabase.auth.onAuthStateChange` and switches between `AuthScreen` and `ProductListScreen`.
  - Model factories: data maps returned from Supabase are converted using `fromMap(...)` factory methods (see `lib/models/product.dart` and `lib/services/cart_service.dart`'s `CartItem.fromMap`).
  - Providers call services and manage loading/error state. See `CartProvider.loadCart()` for the common pattern:
    1. check `AuthService.currentUser` for null
    2. set loading/error fields and notify listeners
    3. call service, convert results into local models, notify listeners

- Developer workflows (commands you can suggest)
  - Standard Flutter workflow applies. Recommend these platform-agnostic commands when relevant:

    ```powershell
    # get dependencies
    flutter pub get

    # run on connected device or emulator
    flutter run

    # run tests (project has a widget test)
    flutter test
    ```

  - Note: Supabase is configured with keys inside `lib/main.dart` (anon key & url). Do not expose or rotate keys without coordination — treat as configured for local/dev only.

- Integration points / external dependencies
  - Supabase: used for auth and DB (see `pubspec.yaml` for exact package versions). Services use `supabase.from('<table>')...` query chains.
  - Provider: app-wide state via `MultiProvider` in `lib/main.dart`.

- Files to reference for implementation patterns
  - `lib/main.dart` — initialization, providers, routes
  - `lib/providers/products_provider.dart` — fetching `products` table, loading pattern
  - `lib/providers/cart_provider.dart` — cart operations, error/loading handling, uses `CartService`
  - `lib/services/cart_service.dart` — CRUD interactions with `cart_items` table, returns `CartItem` model
  - `lib/services/auth_service.dart` — Supabase auth wrapper (signInWithOtp, verifyOtp, signOut)
  - `lib/widgets/auth_wrapper.dart` — auth-state-driven navigation

- What not to do
  - Do not hardcode new Supabase URLs/keys; reuse the `supabase` client from `lib/main.dart`.
  - Avoid duplicating data shape logic — use existing `fromMap` factories in `lib/models/`.

- Small examples you can suggest
  - Add a new provider method: create a service method in `lib/services/` that returns model objects, then call that method from a provider in `lib/providers/` and wrap with `_setLoading/_setError` style used in `CartProvider`.
  - UI navigation: add routes in `MaterialApp.routes` in `lib/main.dart` and reference `SomeScreen.routeName` constants when available.

If anything above is unclear or you'd like the file to include more examples (e.g., typical code snippets for adding a new service/provider), tell me which part to expand and I'll iterate.
