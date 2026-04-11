# API Spec — Order Module (Coffee Shop Backend)

## Base Information

- **Base URL:** `/api/v1`
- **Module:** Order
- **Main Purpose:** checkout dari cart, kelola lifecycle order (`PENDING -> CONFIRMED -> COMPLETED / CANCELLED`)
- **Integrasi utama:** Cart, Product, Payment, User

---

## 1. Authorization Matrix

| Endpoint | Public | Customer | Pegawai | Admin | Internal (Payment Service) |
|---|:---:|:---:|:---:|:---:|:---:|
| `POST /orders/checkout` | ❌ | ✅ (milik sendiri) | ❌ | ❌ | ❌ |
| `GET /orders` | ❌ | ✅ (milik sendiri) | ✅ (semua) | ✅ (semua) | ❌ |
| `GET /orders/:order_id` | ❌ | ✅ (milik sendiri) | ✅ (semua) | ✅ (semua) | ❌ |
| `PATCH /orders/:order_id/cancel` | ❌ | ✅ (milik sendiri) | ❌ | ✅ | ❌ |
| `PATCH /orders/:order_id/status` | ❌ | ❌ | ✅ (hanya `CONFIRMED->COMPLETED`) | ✅ | ❌ |
| `PATCH /internal/orders/:order_id/status` | ❌ | ❌ | ❌ | ❌ | ✅ |

### Security Notes
- Endpoint publik Order selalu lewat JWT middleware + cek `is_active`.
- Endpoint internal tidak pakai JWT user, pakai:
  - `X-Internal-Api-Key: <secret>`

---

## 2. Order Data Schema

## 2.1 Order Detail Response
```json
{
  "order_id": "uuid",
  "order_number": "ORD-20250405-001",
  "user_id": "uuid",
  "status": "PENDING",
  "notes": "Tolong bungkus rapi",
  "total_amount": 68000,
  "expires_at": "2025-04-05T10:15:00Z",
  "items": [
    {
      "order_item_id": "uuid",
      "product_id": "uuid",
      "product_name": "Americano",
      "price_at_checkout": 25000,
      "quantity": 2,
      "subtotal": 50000,
      "selected_attributes": {
        "temperature": "iced",
        "sizes": "medium",
        "sugar_levels": "less",
        "ice_levels": "normal"
      }
    }
  ],
  "created_at": "2025-04-05T10:00:00Z",
  "updated_at": "2025-04-05T10:00:00Z"
}
```

### Status Enum
- `PENDING`
- `CONFIRMED`
- `COMPLETED`
- `CANCELLED`

---

## 3. Validation Rules

## 3.1 Checkout Payload

### Request body
```json
{
  "notes": "optional max 255",
  "items": [
    {
      "cart_item_id": "uuid",
      "attributes": {}
    }
  ]
}
```

### Rules
- `notes`: optional, max 255
- `items`: required, array non-empty
- each `cart_item_id`: UUID valid
- setiap `cart_item_id` harus milik user login

## 3.2 Attribute Validation by Category

### Coffee
- Required:
  - `temperature` (harus ada di `product.attributes.temperature`)
  - `sizes` (harus ada di `product.attributes.sizes`)
- Optional:
  - `sugar_levels` default `normal`
  - `ice_levels` default `normal` (hanya relevan jika `temperature=iced`)
- Jika `temperature=hot`, `ice_levels` diabaikan meskipun dikirim

### Food/Snack
- Required:
  - `portions` (valid di `product.attributes.portions`)
- Optional:
  - `spicy_levels` default `no_spicy`

### General Rules
- Value atribut harus valid terhadap **opsi di produk itu sendiri** (bukan sekadar enum global)
- Atribut tidak relevan untuk kategori tertentu diabaikan (tidak error)
- Atribut tidak memengaruhi harga (harga tetap `products.price`)

---

## 4. Endpoint Specifications

## 4.1 POST `/api/v1/orders/checkout` — Create Order from Cart

### Auth
- JWT required
- Role: Customer only
- Precondition user:
  - `is_active = true`
  - `is_verified = true`
  - `phone_number` terisi

### Business Flow
1. Validasi auth + user preconditions.
2. Validasi payload.
3. Ambil semua cart item; pastikan milik user.
4. Join product dan validasi:
   - tidak soft-deleted
   - status `available`
   - stok cukup
5. Validasi atribut per kategori + apply default.
6. Dalam 1 DB transaction:
   - buat `orders` status `PENDING`
   - generate `order_number` format `ORD-YYYYMMDD-XXX` (WIB)
   - set `expires_at = created_at + 15 menit`
   - insert `order_items` (snapshot price/name/attributes + `cart_item_id`)
   - kurangi stok produk (`SELECT ... FOR UPDATE`)
   - simpan `total_amount`
7. Return detail order.

### Request Body Example
```json
{
  "notes": "Tolong bungkus rapi",
  "items": [
    {
      "cart_item_id": "uuid-cart-item-1",
      "attributes": {
        "temperature": "iced",
        "sizes": "medium",
        "sugar_levels": "less",
        "ice_levels": "normal"
      }
    },
    {
      "cart_item_id": "uuid-cart-item-2",
      "attributes": {
        "portions": "regular",
        "spicy_levels": "mild"
      }
    }
  ]
}
```

### Success Response (201)
```json
{
  "success": true,
  "data": {
    "order_id": "uuid",
    "order_number": "ORD-20250405-001",
    "user_id": "uuid",
    "status": "PENDING",
    "notes": "Tolong bungkus rapi",
    "total_amount": 68000,
    "expires_at": "2025-04-05T10:15:00Z",
    "items": [],
    "created_at": "2025-04-05T10:00:00Z",
    "updated_at": "2025-04-05T10:00:00Z"
  },
  "message": "Order berhasil dibuat"
}
```

### Errors
- `400 VALIDATION_ERROR`
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `403 ACCOUNT_DISABLED`
- `403 EMAIL_UNVERIFIED`
- `403 PHONE_NUMBER_REQUIRED`
- `404 CART_ITEM_NOT_FOUND`
- `404 PRODUCT_NOT_FOUND`
- `422 PRODUCT_UNAVAILABLE`
- `422 PRODUCT_OUT_OF_STOCK`
- `422 INSUFFICIENT_STOCK`
- `500 INTERNAL_SERVER_ERROR`

---

## 4.2 GET `/api/v1/orders` — List Orders / Queue

### Auth
- JWT required
- Role: Customer/Pegawai/Admin

### Query Params

| Param | Type | Required | Rules |
|---|---|---:|---|
| `cursor` | string | ❌ | opaque base64 |
| `direction` | enum | ❌ | `next|prev`, default `next` |
| `limit` | int | ❌ | default 10, max 50 |
| `status` | enum | ❌ | `PENDING|CONFIRMED|COMPLETED|CANCELLED` |
| `user_id` | UUID | ❌ | hanya berlaku untuk Admin |

### Role Behavior
- Customer: auto filter `order.user_id = JWT user`; `user_id` query diabaikan
- Pegawai: lihat semua order; `user_id` query diabaikan
- Admin: lihat semua order; bisa filter `user_id`

### Success Response (200)
```json
{
  "success": true,
  "data": [
    {
      "order_id": "uuid",
      "order_number": "ORD-20250405-001",
      "status": "PENDING",
      "total_amount": 68000,
      "created_at": "2025-04-05T10:00:00Z"
    }
  ],
  "pagination": {
    "next_cursor": "base64string_or_null",
    "prev_cursor": "base64string_or_null",
    "limit": 10,
    "has_next": true,
    "has_prev": false
  }
}
```

### Errors
- `400 VALIDATION_ERROR`
- `400 INVALID_CURSOR`
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `403 ACCOUNT_DISABLED`
- `500 INTERNAL_SERVER_ERROR`

---

## 4.3 GET `/api/v1/orders/:order_id` — Order Detail

### Auth
- JWT required
- Role: Customer/Pegawai/Admin

### Path Param
- `order_id` UUID required

### Access Rule
- Customer hanya boleh order miliknya
- Pegawai/Admin boleh semua

### Success Response (200)
```json
{
  "success": true,
  "data": {
    "order_id": "uuid",
    "order_number": "ORD-20250405-001",
    "user_id": "uuid",
    "status": "CONFIRMED",
    "notes": "Tolong bungkus rapi",
    "total_amount": 68000,
    "expires_at": null,
    "items": [],
    "created_at": "2025-04-05T10:00:00Z",
    "updated_at": "2025-04-05T10:02:00Z"
  },
  "message": "Order berhasil diambil"
}
```

### Errors
- `400 VALIDATION_ERROR`
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `403 ACCOUNT_DISABLED`
- `404 ORDER_NOT_FOUND`
- `500 INTERNAL_SERVER_ERROR`

---

## 4.4 PATCH `/api/v1/orders/:order_id/cancel` — Cancel Order

### Auth
- JWT required
- Role: Customer or Admin
- Precondition: order status harus `PENDING`

### Path Param
- `order_id` UUID required

### Business Flow
1. Validasi auth/role.
2. Validasi ownership untuk Customer.
3. Pastikan status `PENDING`.
4. Dalam 1 transaction:
   - update order -> `CANCELLED`
   - kembalikan stok produk dari `order_items` (`SELECT ... FOR UPDATE`)
5. Return order terbaru.

### Success Response (200)
```json
{
  "success": true,
  "data": {
    "order_id": "uuid",
    "status": "CANCELLED",
    "updated_at": "2025-04-05T10:05:00Z"
  },
  "message": "Order berhasil dibatalkan"
}
```

### Errors
- `400 VALIDATION_ERROR`
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `403 ACCOUNT_DISABLED`
- `404 ORDER_NOT_FOUND`
- `422 ORDER_NOT_CANCELLABLE`
- `422 ORDER_ALREADY_CANCELLED`
- `500 INTERNAL_SERVER_ERROR`

---

## 4.5 PATCH `/api/v1/orders/:order_id/status` — Manual Status Update

### Auth
- JWT required
- Role: Pegawai or Admin

### Path Param
- `order_id` UUID required

### Request Body
```json
{
  "status": "COMPLETED"
}
```

### Allowed Transitions

| Current | Target | Pegawai | Admin |
|---|---|:---:|:---:|
| `PENDING` | `CONFIRMED` | ❌ | ✅ |
| `CONFIRMED` | `COMPLETED` | ✅ | ✅ |
| `PENDING` | `COMPLETED` | ❌ | ❌ |
| `CANCELLED` | any | ❌ | ❌ |
| `COMPLETED` | any | ❌ | ❌ |

### Notes
- Pegawai hanya boleh `CONFIRMED -> COMPLETED`
- Saat jadi `COMPLETED`, update `products.total_sold` dilakukan async

### Success Response (200)
```json
{
  "success": true,
  "data": {
    "order_id": "uuid",
    "status": "COMPLETED",
    "updated_at": "2025-04-05T11:00:00Z"
  },
  "message": "Status order berhasil diperbarui"
}
```

### Errors
- `400 VALIDATION_ERROR`
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `403 ACCOUNT_DISABLED`
- `404 ORDER_NOT_FOUND`
- `422 INVALID_STATUS_TRANSITION`
- `500 INTERNAL_SERVER_ERROR`

---

## 4.6 PATCH `/api/v1/internal/orders/:order_id/status` — Internal Update by Payment Service

### Auth
- Header: `X-Internal-Api-Key` required
- No user JWT

### Path Param
- `order_id` UUID required

### Behavior
1. Validasi API key.
2. Pastikan order status `PENDING`.
3. Dalam transaction:
   - update status `PENDING -> CONFIRMED`
4. Setelah commit:
   - panggil Cart Service: `DELETE /internal/cart/items`
   - kirim item dari `order_items.cart_item_id`
5. Return sukses ke Payment Service.

### Success Response (200)
```json
{
  "success": true,
  "message": "Order status updated to CONFIRMED"
}
```

### Errors
- `401 UNAUTHORIZED`
- `400 VALIDATION_ERROR`
- `404 ORDER_NOT_FOUND`
- `422 INVALID_STATUS_TRANSITION`
- `500 INTERNAL_SERVER_ERROR`

> Jika clear cart gagal: status order tetap `CONFIRMED`, log error, retry via mekanisme terpisah (eventual consistency).

---

## 5. Scheduled Job Spec

## 5.1 Auto-cancel expired pending orders

### Trigger
- Cron/worker tiap 1 menit

### Rule
- Cari order `PENDING` dengan `expires_at <= now()`
- Per order, transaction:
  - set status `CANCELLED`
  - restore stok dari order_items (locking)
- Log alasan cancel = `EXPIRED`

### Operational Notes
- Jika job overlap, gunakan distributed lock/idempotency check
- Error pada 1 order tidak menghentikan order lain

---

## 6. Standard Response Format

### Success (detail/order object)
```json
{
  "success": true,
  "data": {},
  "message": "Operasi berhasil"
}
```

### Success (list + pagination)
```json
{
  "success": true,
  "data": [],
  "pagination": {
    "next_cursor": "base64_or_null",
    "prev_cursor": "base64_or_null",
    "limit": 10,
    "has_next": true,
    "has_prev": false
  }
}
```

### Error
```json
{
  "success": false,
  "error": {
    "code": "SNAKE_CASE_ERROR_CODE",
    "message": "Pesan yang dapat dibaca manusia"
  }
}
```

---

## 7. Error Code Catalog (Order)

| Code | HTTP | Trigger |
|---|:---:|---|
| `VALIDATION_ERROR` | 400 | input/path/body invalid |
| `INVALID_CURSOR` | 400 | cursor invalid |
| `UNAUTHORIZED` | 401 | token/api key invalid |
| `FORBIDDEN` | 403 | role tidak diizinkan |
| `ACCOUNT_DISABLED` | 403 | `is_active=false` |
| `EMAIL_UNVERIFIED` | 403 | customer belum verifikasi |
| `PHONE_NUMBER_REQUIRED` | 403 | phone belum terisi |
| `CART_ITEM_NOT_FOUND` | 404 | cart item tidak ada/bukan milik user |
| `PRODUCT_NOT_FOUND` | 404 | product soft-deleted/tidak ada |
| `ORDER_NOT_FOUND` | 404 | order tidak ada / bukan milik customer |
| `PRODUCT_UNAVAILABLE` | 422 | product unavailable |
| `PRODUCT_OUT_OF_STOCK` | 422 | product out_of_stock |
| `INSUFFICIENT_STOCK` | 422 | stok kurang |
| `ORDER_NOT_CANCELLABLE` | 422 | status bukan `PENDING` |
| `ORDER_ALREADY_CANCELLED` | 422 | status sudah `CANCELLED` |
| `INVALID_STATUS_TRANSITION` | 422 | transisi status tidak valid |
| `INTERNAL_SERVER_ERROR` | 500 | server error |

---

## 8. Database & Transaction Policy

### Tables (reference)

#### `orders`
- `id` UUID PK
- `order_number` unique (`ORD-YYYYMMDD-XXX`)
- `user_id` UUID FK
- `status` enum
- `notes` nullable
- `total_amount` int
- `expires_at` timestamptz
- `created_at`, `updated_at`

#### `order_items`
- `id` UUID PK
- `order_id` UUID FK
- `product_id` UUID
- `cart_item_id` UUID (untuk clear cart)
- `product_name` snapshot
- `price_at_checkout` snapshot
- `quantity`, `subtotal`
- `selected_attributes` JSONB
- `created_at`

### Transaction rules
- Checkout/cancel/update status/auto-cancel wajib transaction
- Lock stok produk pakai pessimistic locking saat checkout & cancel
- Tidak ada hard delete order (append-only status changes)

### Order number format
- `ORD-YYYYMMDD-XXX` (WIB UTC+7)
- reset sequence harian
- >999 tetap lanjut digit (`...-1000`, dst)

---

## 9. Side Effects & Integrations

- Checkout sukses -> stok produk berkurang (sync)
- Payment success webhook -> internal update order ke `CONFIRMED`
- `CONFIRMED` setelah internal update -> trigger clear cart ke Cart Service
- `COMPLETED` -> update `products.total_sold` async
- Cancel (manual/expired) -> stok dikembalikan sync

---

## 10. Logging & Monitoring

Wajib log:
- Checkout (`user_id`, `order_id`, `order_number`, product list)
- Perubahan status (`actor`, `status_lama`, `status_baru`)
- Cancel (manual/expired + reason)
- Race condition stok (`INSUFFICIENT_STOCK`) sebagai WARNING
- Gagal clear cart setelah payment success (ERROR)
- Gagal update `total_sold` async (ERROR)
- auth/role denied (WARNING)
- error 500 + stack trace (ERROR)

Tidak perlu log:
- GET list/detail sukses
- scheduler run tanpa expired order
- panggilan internal idempotent yang sukses