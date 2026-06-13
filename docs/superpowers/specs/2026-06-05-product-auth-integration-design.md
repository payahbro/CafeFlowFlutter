# Product and Auth Integration Design

**Date:** 2026-06-05
**Project:** CafeFlowFlutter
**Status:** Draft approved in chat, pending file review

## Goal

Integrate real Supabase login and backend-backed product APIs into the existing Flutter app without changing the current state management approach or breaking the feature-first architecture.

## Scope

This design covers:

- Supabase login integration for the existing login flow
- Backend profile fetch after login via `GET /api/v1/users/profile`
- Session and bearer-token plumbing shared by protected API modules
- Product public flow integration:
  - product home featured list
  - product catalog list
  - product detail
- Product management integration for admin and pegawai:
  - create
  - update
  - status update
  - soft delete
  - restore
- Loading, error, and empty states for the above product screens

This design does not cover:

- Register integration
- Forgot password or other auth recovery flows
- Direct Supabase Storage upload flows
- Unrelated UI redesign

## Constraints

- Keep the existing feature-first and lightweight clean architecture structure.
- Do not replace the current `ChangeNotifier`-based controller pattern.
- Follow backend contracts already defined in `C:\projects\CafeBackend\docs\api-spec\api-spec-product.md` and `C:\projects\CafeBackend\docs\api-spec\api-spec-user.md`.
- Product integration must stop using the current mock-driven main flow.
- Android emulator and Android physical device usage must both be supported.

## Current State Summary

The project already contains:

- `ApiClient` in `lib/core/network/api_client.dart`
- feature modules for `auth`, `product`, `cart`, `order`, `payment`, and `admin`
- existing product data/domain layers and controllers
- product pages for customer and admin flows

However, the current app still has these gaps:

- login is local/demo-only and does not use Supabase
- `SessionController` does not hold a real token or server profile
- `AppConfig` points to a mock Postman base URL
- product home and product management still rely on `ProductMockStore`
- protected backend modules do not share a real bearer-token mechanism

## Recommended Approach

Use a minimal aligned integration approach:

1. Add a real auth/session foundation first.
2. Make `SessionController` the source of truth for session and access token.
3. Let `ApiClient` read bearer tokens through a shared token provider.
4. Replace mock-backed product entry points with existing remote product use cases and controllers.
5. Reuse the same token plumbing for `cart`, `order`, `payment`, and `admin` so product flows do not fail immediately after login.

This is preferred over a broad refactor because it preserves the current architecture while still producing an end-to-end working application state.

## Runtime Configuration

### Config keys

`AppConfig` should read runtime values from `dart-define`:

- `BACKEND_ORIGIN`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Derived values:

- `apiBaseUrl = '$BACKEND_ORIGIN/api/v1'`
- `productBaseUrl = apiBaseUrl`
- `orderBaseUrl = apiBaseUrl`
- `paymentBaseUrl = apiBaseUrl`
- `adminBaseUrl = apiBaseUrl`

### Initial environment values

- `SUPABASE_URL=https://kangzprbrstwuuejpmso.supabase.co`
- `BACKEND_ORIGIN` should not default to `http://localhost:8080` on mobile

### Android networking rule

- Android emulator should use `http://10.0.2.2:8080`
- Android physical devices should use `http://<pc-lan-ip>:8080`
- `localhost` only works when the Flutter app runs on the same machine as the backend process, such as Windows desktop

Because the user will test first on Android emulator, the initial recommended `BACKEND_ORIGIN` is `http://10.0.2.2:8080`.

## Auth and Session Design

### Source of truth

`SessionController` becomes the single source of truth for:

- current authenticated user
- access token
- logged-in state
- login/logout in-progress state
- session restoration state

### Login flow

When the user logs in:

1. Call Supabase `signInWithPassword(email, password)`.
2. Read the returned access token from the Supabase session.
3. Call backend `GET /api/v1/users/profile` with `Authorization: Bearer <token>`.
4. Map the backend response to app user data.
5. Only then mark the session as logged in.

If Supabase login succeeds but backend profile fetch fails, the app must not enter the authenticated shell.

### Restore session flow

At startup:

1. Initialize Supabase.
2. Check whether Supabase already has a valid session.
3. If yes, reuse the current access token.
4. Fetch backend profile again.
5. If profile fetch succeeds, restore authenticated app state.
6. If it fails with `UNAUTHORIZED`, `ACCOUNT_DISABLED`, or `PROFILE_NOT_SYNCED`, clear the local session and show the unauthenticated flow.

### Logout flow

Logout should:

1. Call Supabase `signOut`
2. clear local session state
3. notify listeners so the app returns to onboarding/login

If remote sign-out fails, local session still needs to be cleared so the app does not remain in an invalid half-logged-in state.

### Auth data layering

The `auth` feature should gain:

- data source for Supabase login and logout
- remote data source for backend profile fetch
- auth repository that composes both
- login use case
- restore-session use case or equivalent session bootstrap helper

The register path remains out of scope and can stay skipped for now.

## User Model Changes

The app-level user model should stop being only a role simulation.

`AppUser` should be expanded to represent the backend profile:

- `id`
- `email`
- `fullName`
- `role`
- `isVerified`
- `isActive`
- `phoneNumber`
- `avatarUrl`

Role mapping should be based on backend profile values, not email heuristics.

Backend values:

- `Customer`
- `Pegawai`
- `Admin`

These should be mapped consistently into the existing `UserRole` enum.

## API Client Design

### Token provider

`ApiClient` should be extended to accept an optional token provider callback, for example:

- no token provider: request stays public
- token provider returns token: send `Authorization: Bearer <token>`

This keeps the client reusable without putting auth logic into presentation or repository classes.

### Error handling

Existing backend error shape should continue to map into `AppException`:

```json
{
  "success": false,
  "error": {
    "code": "...",
    "message": "...",
    "details": ...
  }
}
```

`AppException` should preserve:

- `message`
- `code`
- `statusCode`

That information is required for auth failures, product validation failures, and role-based API failures.

## Module Wiring

### Main app bootstrap

`main.dart` should become async and perform:

1. `WidgetsFlutterBinding.ensureInitialized()`
2. `Supabase.initialize(...)`
3. create `SessionController`
4. create API-backed modules using a shared token provider sourced from `SessionController`
5. trigger session restoration before final authenticated routing settles

### Shared protected modules

The following modules should be wired to the same authenticated `ApiClient` pattern:

- `ProductModule`
- `CartModule`
- `OrderModule`
- `PaymentModule`
- `AdminModule`

Reason:

- product detail leads into add-to-cart
- cart, order, payment, and admin all use protected backend endpoints
- a real login is not useful if only product requests can see the token

## Product Data Design

### Backend contract assumptions

Base API path:

- `/api/v1`

Product endpoints:

- public:
  - `GET /products`
  - `GET /products/:id`
- protected:
  - `POST /products`
  - `PUT /products/:id`
  - `PATCH /products/:id/status`
  - `DELETE /products/:id`
  - `PATCH /products/:id/restore`

### Response parsing

The product data layer should follow backend response structure exactly:

- list:
  - `data: []`
  - `pagination: {...}`
- detail and mutations:
  - `data: {...}`
- delete:
  - success body may contain only `success` and `message`

The existing `ProductModel` and `ProductListPageModel` are close to the contract and should be retained, only adjusted where needed for real backend responses.

### Fields

Product parsing must support:

- `id`
- `name`
- `description`
- `price`
- `category`
- `status`
- `image_url`
- `rating`
- `total_sold`
- `attributes`
- `created_at`
- `updated_at`
- `deleted_at`

## Product Public Flow Design

### Product home

`ProductHomePage` currently depends on `ProductMockStore` for featured products. This should be replaced with remote-backed data.

Recommended behavior:

- fetch a small remote list for the home section, such as `limit: 8`
- show loading state while fetching
- show empty state when no visible products are returned
- show error state with retry when request fails

The page should still navigate into the existing catalog and detail flows.

### Product catalog

`ProductCatalogPage` should stop receiving `mockProducts` for the main flow.

It should rely on:

- `ProductCatalogController`
- `GetProductsUseCase`

Supported behavior:

- category filter
- search
- pagination
- loading state
- error state
- empty state

### Product detail

`ProductDetailController` remains the controller for detail loading.

Behavior:

- if an initial product snapshot is available, it can still render immediately
- detail should still be refreshable through real API calls
- if no product is available and load fails, show a proper error state with retry

## Product Management Flow Design

### Replace mock controller

`ProductManagementPage` currently uses `_ProductManagementMockController`. That should be removed from the main app path.

Instead:

- the page receives a real `ProductManagementController`
- the controller uses existing product use cases and repository layers

### Authorization behavior

Admin:

- load list
- create
- edit
- update status
- delete
- restore
- use `include_deleted`

Pegawai:

- load list
- update status only
- cannot create, edit, delete, or restore
- cannot use `include_deleted`

The UI should mirror backend permissions rather than invent local-only rules.

### Mutations

Mutation order for implementation:

1. create
2. update
3. status update
4. delete
5. restore

Each mutation should:

- clear previous mutation error
- perform the API request
- reload product management list after success
- keep the user on the same screen
- show feedback using backend error or success messaging

## Loading, Error, and Empty States

The app should explicitly handle these states in product screens:

### Customer-facing

- product home:
  - loading indicator
  - error with retry
  - empty state when no products available
- product catalog:
  - loading
  - pagination loading
  - request error
  - empty search/filter result
- product detail:
  - loading
  - detail error with retry

### Admin-facing

- product management:
  - loading indicator while fetching list
  - inline/banner error for list failures
  - empty state when list has no data
  - empty state when filters/search return no results
  - inline or snackbar feedback for mutation failures

## Testing Strategy

Testing remains TDD-based and split into incremental phases.

### Phase 1: auth foundation

- config tests
- auth repository tests
- `SessionController` login success tests
- `SessionController` failure tests:
  - invalid credentials
  - `ACCOUNT_DISABLED`
  - profile fetch failure
- login page widget tests for loading and error rendering

### Phase 2: authenticated API plumbing

- `ApiClient` tests for bearer header injection
- tests for public requests without bearer header
- tests for `401` and `403` mapping into `AppException`

### Phase 3: public product integration

- product list and detail data-source parsing tests
- `ProductCatalogController` tests for loading/error/empty/pagination
- widget tests for remote-backed product home/catalog/detail states

### Phase 4: product management integration

- controller tests for create/update/status/delete/restore
- widget tests for admin and pegawai management behavior
- guard tests for restricted actions

### Phase 5: regression verification

- focused test runs during development
- final `flutter test`
- manual emulator verification for:
  - login
  - product home
  - catalog
  - detail
  - admin or pegawai product management

## Definition of Done

This work is done when all of the following are true:

- login uses Supabase instead of local/demo logic
- backend profile is fetched after login and becomes app session state
- `SessionController` exposes real authenticated session information
- protected API modules can send bearer tokens
- product home, catalog, and detail use backend data
- product management uses backend data and mutations
- admin and pegawai permissions follow backend rules
- loading, error, and empty states exist for product list, detail, and management flows
- the primary app flow no longer depends on `ProductMockStore`
- relevant tests pass

## Risks and Mitigations

### Mobile host mismatch

Risk:

- using `localhost` from Android will fail

Mitigation:

- use `BACKEND_ORIGIN`
- start emulator testing with `http://10.0.2.2:8080`

### Supabase login succeeds but backend access fails

Risk:

- app enters inconsistent state after login

Mitigation:

- only mark session authenticated after backend profile fetch succeeds

### Token is available only in auth flow

Risk:

- product, cart, order, payment, or admin fail after login

Mitigation:

- inject one shared token provider into all protected API modules

### Mock paths remain active

Risk:

- some screens still show stale local data while others use backend

Mitigation:

- replace mock entry points in the main app shell path, not only in data layer

## File Impact Summary

Likely affected areas:

- `lib/app/config/app_config.dart`
- `lib/main.dart`
- `lib/core/network/api_client.dart`
- `lib/shared/models/app_user.dart`
- `lib/shared/services/session_controller.dart`
- `lib/features/auth/...`
- `lib/app/di/product_module.dart`
- `lib/app/di/cart_module.dart`
- `lib/app/di/order_module.dart`
- `lib/app/di/payment_module.dart`
- `lib/app/di/admin_module.dart`
- `lib/features/product/data/...`
- `lib/features/product/presentation/pages/product_home_page.dart`
- `lib/features/product/presentation/pages/product_catalog_page.dart`
- `lib/features/product/presentation/pages/product_management_page.dart`
- relevant test files under `test/features/auth` and `test/features/product`

## Open Decisions Already Resolved

- Login uses Supabase directly, not Golang auth login endpoint.
- Profile is fetched from backend after login.
- Register integration is skipped for now.
- Real runtime config is preferred over fake placeholders.
- Initial backend target for emulator testing should use Android emulator networking rules rather than `localhost`.

## Notes

This spec is intentionally focused on the smallest architecture-aligned path to get real login and real product integration working end-to-end. It does not attempt to redesign unrelated modules or replace the current controller pattern.
