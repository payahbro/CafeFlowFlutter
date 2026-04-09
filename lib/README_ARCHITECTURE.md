# Coffee Shop App Architecture (Flutter)

This project uses a feature-first structure with a lightweight clean architecture style.

## High-level folders

- `app/` : app-level setup (router, DI, theme, config)
- `bootstrap/` : app bootstrap entry helpers
- `core/` : global technical layer (network, errors, storage, base usecases)
- `shared/` : reusable cross-feature UI/models/helpers
- `features/` : business modules (auth, product, cart, order, payment, employee, admin)

## Feature module pattern

Each feature follows:

- `data/`
  - `datasources/` : REST API/Supabase gateway calls
  - `models/` : DTO and serialization
  - `repositories/` : repository implementations
- `domain/`
  - `entities/` : pure business objects
  - `repositories/` : repository contracts
  - `usecases/` : business actions
- `presentation/`
  - `cubit/` : state management
  - `pages/` : screens
  - `widgets/` : feature-scoped widgets

## Included feature modules

- `auth` : login, logout, forgot password, session
- `product` : CRUD product + category handling (coffee/snack/food)
- `cart` : add/remove/update quantity
- `order` : checkout, history, status tracking
- `payment` : Midtrans payment flow and callback handling
- `employee` : order queue and status update by staff
- `admin` : reports, user/order/product management

## API integration conventions (Go + Supabase/PostgreSQL backend)

- Keep API contracts in `features/<feature>/data/models/`.
- Keep HTTP client/interceptors in `core/network/`.
- Put token/session persistence in `core/storage/`.
- Route guards by role go in `app/router/guards/`.
- Avoid direct network calls in `presentation/`; use `usecases`.

## Suggested next implementation order

1. Setup app router and auth guard (`app/router`).
2. Build `core/network` (`Dio` client + auth interceptor).
3. Implement auth module end-to-end.
4. Implement product + cart modules for customer flow.
5. Implement order + payment (Midtrans) flow.
6. Implement employee and admin modules.

