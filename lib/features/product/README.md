# Product Feature (Flutter)

This module follows lightweight clean architecture and consumes Product API contract from `docs/api-spec/api-spec-product.md`.

## Implemented scope

- Customer/public product browsing
  - `GET /products` with filter/search/pagination query support
  - `GET /products/:id` detail
- Back-office product operations
  - `POST /products`
  - `PUT /products/:id` (partial semantics as defined in BR/API notes)
  - `PATCH /products/:id/status`
  - `DELETE /products/:id` (soft delete)
  - `PATCH /products/:id/restore`
- Role simulation (customer/pegawai/admin) for UI visibility and allowed actions

## Architecture map

- Data layer
  - `data/datasources/product_remote_data_source.dart`
  - `data/models/*.dart`
  - `data/repositories/product_repository_impl.dart`
- Domain layer
  - `domain/entities/*.dart`
  - `domain/repositories/product_repository.dart`
  - `domain/usecases/*.dart`
- Presentation layer
  - Controllers (`presentation/cubit/*.dart`)
  - Pages (`presentation/pages/*.dart`)
  - Widgets (`presentation/widgets/*.dart`)

## Notes on cross-module consistency

- Product enums and field names use API-spec values:
  - `category`: `coffee|food|snack`
  - `status`: `available|out_of_stock|unavailable`
- Cart compatibility:
  - Add-to-cart UI message intentionally keeps BR contract in mind (cart item stores product_id + quantity only).
- Order compatibility:
  - Product detail loads `attributes` and renders selectable options from API response as source of truth.

## Quick try

1. Ensure Flutter SDK is installed and available on PATH.
2. Run:

```powershell
flutter pub get
flutter run
```

3. In app header, switch role between `Customer`, `Pegawai`, and `Admin` to test authorization behavior in UI.

