# API Spec — Cart Module (Coffee Shop Backend)

## Base Information

- **Base URL:** `/api/v1`
- **Module:** Cart
- **Cart Model:** 1 user Customer memiliki tepat 1 cart aktif (persisten).
- **No guest cart:** wajib login.
- **No cache:** cart selalu real-time.

---

## 1. Authorization Matrix

| Endpoint | Public | Customer | Pegawai | Admin | Internal (Order Service) |
|---|:---:|:---:|:---:|:---:|:---:|
| `GET /cart` | ❌ | ✅ | ❌ | ❌ | ❌ |
| `POST /cart/items` | ❌ | ✅ | ❌ | ❌ | ❌ |
| `PATCH /cart/items/:item_id` | ❌ | ✅ | ❌ | ❌ | ❌ |
| `DELETE /cart/items/:item_id` | ❌ | ✅ | ❌ | ❌ | ❌ |
| `DELETE /cart/items` | ❌ | ✅ | ❌ | ❌ | ❌ |
| `DELETE /internal/cart/items` | ❌ | ❌ | ❌ | ❌ | ✅ |

### Security Notes
- Semua endpoint customer wajib JWT + cek `is_active = true`.
- Endpoint internal **tidak** pakai JWT user.
  - Header wajib: `X-Internal-Api-Key: <secret>`

### Routing Note (penting)
Karena path mirip:
- `DELETE /cart/items/:item_id`
- `DELETE /cart/items`

Pastikan router register keduanya eksplisit dan tidak saling ketuker.

---

## 2. Data Schemas

## 2.1 Cart Item (response)
```json
{
  "item_id": "uuid",
  "product_id": "uuid",
  "name": "Americano",
  "image_url": "https://...",
  "price": 25000,
  "quantity": 2,
  "subtotal": 50000,
  "is_available": true
}
```

## 2.2 Cart Response
```json
{
  "cart_id": "uuid",
  "user_id": "uuid",
  "items": [],
  "grand_total": 0,
  "updated_at": "2024-01-01T00:00:00Z"
}
```

> `grand_total` hanya menjumlahkan item dengan `is_available = true`.

---

## 3. Validation Rules

### Common
- `product_id`: UUID valid, harus ada di products, tidak soft-deleted
- `item_id`: UUID valid
- `quantity`: integer, min 1

### Important Semantics
- **Add item (`POST`)**: quantity adalah **delta increment**.
- **Update item (`PATCH`)**: quantity adalah **final value**.
- `quantity = 0` saat update -> `VALIDATION_ERROR` (harus pakai DELETE untuk hapus item).

### Product status on add
- `status=unavailable` atau soft-deleted -> `PRODUCT_UNAVAILABLE` / `PRODUCT_NOT_FOUND`
- `status=out_of_stock` -> `PRODUCT_OUT_OF_STOCK`

---

## 4. Endpoint Specifications

## 4.1 GET `/api/v1/cart` — Get My Cart

### Auth
- JWT required
- Role: Customer only

### Description
Ambil cart milik user login + real-time product availability.

### Business Rules
1. Jika cart belum ada, return cart kosong (200).
2. Join `cart_items` ke `products` untuk resolve status terbaru.
3. Set `is_available=false` jika:
   - product status `unavailable` atau `out_of_stock`
   - atau product soft-deleted (`deleted_at IS NOT NULL`)
4. `grand_total` hanya dari item `is_available=true`.

### Success Response (200)
```json
{
  "success": true,
  "data": {
    "cart_id": "uuid",
    "user_id": "uuid",
    "items": [
      {
        "item_id": "uuid",
        "product_id": "uuid",
        "name": "Americano",
        "image_url": "https://...",
        "price": 25000,
        "quantity": 2,
        "subtotal": 50000,
        "is_available": true
      },
      {
        "item_id": "uuid",
        "product_id": "uuid",
        "name": "Croissant",
        "image_url": "https://...",
        "price": 18000,
        "quantity": 1,
        "subtotal": 18000,
        "is_available": false
      }
    ],
    "grand_total": 50000,
    "updated_at": "2024-01-01T00:00:00Z"
  },
  "message": "Cart berhasil diambil"
}
```

### Errors
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `403 ACCOUNT_DISABLED`
- `500 INTERNAL_SERVER_ERROR`

---

## 4.2 POST `/api/v1/cart/items` — Add Item to Cart

### Auth
- JWT required
- Role: Customer only

### Request Body
```json
{
  "product_id": "uuid",
  "quantity": 2
}
```

### Behavior
1. Validasi auth, role, `is_active`.
2. Validasi `product_id`, `quantity`.
3. Validasi product tersedia.
4. Jika cart belum ada -> auto create cart.
5. Jika produk sudah ada di cart -> increment quantity.
6. Jika belum ada -> insert cart_item baru.
7. Semua proses dalam 1 DB transaction.
8. Return isi cart terbaru.

### Success Response (200)
```json
{
  "success": true,
  "data": {
    "cart_id": "uuid",
    "user_id": "uuid",
    "items": [],
    "grand_total": 0,
    "updated_at": "2024-01-01T00:00:00Z"
  },
  "message": "Item berhasil ditambahkan ke cart"
}
```

### Errors
- `400 VALIDATION_ERROR`
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `403 ACCOUNT_DISABLED`
- `404 PRODUCT_NOT_FOUND`
- `422 PRODUCT_UNAVAILABLE`
- `422 PRODUCT_OUT_OF_STOCK`
- `500 INTERNAL_SERVER_ERROR`

---

## 4.3 PATCH `/api/v1/cart/items/:item_id` — Update Quantity

### Auth
- JWT required
- Role: Customer only

### Path Params
- `item_id` UUID required

### Request Body
```json
{
  "quantity": 3
}
```

### Behavior
- Update quantity menjadi nilai final.
- Cart item harus milik user login.
- `quantity <= 0` ditolak (`VALIDATION_ERROR`).
- Boleh update meskipun item sedang `is_available=false`.

### Success Response (200)
```json
{
  "success": true,
  "data": {
    "cart_id": "uuid",
    "user_id": "uuid",
    "items": [],
    "grand_total": 0,
    "updated_at": "2024-01-01T00:00:00Z"
  },
  "message": "Quantity item cart berhasil diperbarui"
}
```

### Errors
- `400 VALIDATION_ERROR`
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `403 ACCOUNT_DISABLED`
- `404 CART_ITEM_NOT_FOUND`
- `500 INTERNAL_SERVER_ERROR`

> Untuk item milik user lain tetap return `404 CART_ITEM_NOT_FOUND` (jangan bocorkan ownership).

---

## 4.4 DELETE `/api/v1/cart/items/:item_id` — Remove One Item

### Auth
- JWT required
- Role: Customer only

### Path Params
- `item_id` UUID required

### Behavior
- Hard delete 1 row cart_item.
- Jika cart jadi kosong, record `cart` tetap dipertahankan.

### Success Response (200)
```json
{
  "success": true,
  "message": "Item berhasil dihapus dari cart"
}
```

### Errors
- `400 VALIDATION_ERROR`
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `403 ACCOUNT_DISABLED`
- `404 CART_ITEM_NOT_FOUND`
- `500 INTERNAL_SERVER_ERROR`

---

## 4.5 DELETE `/api/v1/cart/items` — Clear All Items (Customer)

### Auth
- JWT required
- Role: Customer only

### Behavior
- Hapus semua cart_items milik user.
- Idempotent:
  - cart belum ada / sudah kosong -> tetap 200
- Record `cart` tetap ada.

### Success Response (200)
```json
{
  "success": true,
  "message": "Item berhasil dihapus dari cart"
}
```

### Errors
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `403 ACCOUNT_DISABLED`
- `500 INTERNAL_SERVER_ERROR`

---

## 4.6 DELETE `/api/v1/internal/cart/items` — Clear Specific Items (Internal)

### Auth
- Header `X-Internal-Api-Key` wajib valid
- No user JWT

### Request Body
```json
{
  "item_ids": ["uuid-1", "uuid-2", "uuid-3"]
}
```

### Validation
- `item_ids` wajib array non-empty
- Semua elemen harus UUID valid

### Behavior
1. Validasi internal API key.
2. Hard delete item yang ada di daftar.
3. Item yang tidak ditemukan diabaikan (idempotent).
4. Update `updated_at` untuk cart terdampak.
5. Return sukses.

### Success Response (200)
```json
{
  "success": true,
  "message": "Cart items cleared"
}
```

### Errors
- `401 UNAUTHORIZED` (key tidak valid/tidak ada)
- `400 VALIDATION_ERROR` (item_ids kosong/invalid)
- `500 INTERNAL_SERVER_ERROR`

> Jika semua item_ids tidak ditemukan -> tetap 200 (idempotent).

---

## 5. Standard Response Format

### Success with data
```json
{
  "success": true,
  "data": {},
  "message": "Operasi berhasil"
}
```

### Success without data
```json
{
  "success": true,
  "message": "Operasi berhasil"
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

## 6. Error Code Catalog (Cart)

| Code | HTTP | Trigger |
|---|:---:|---|
| `VALIDATION_ERROR` | 400 | format field invalid, quantity < 1, item_ids invalid |
| `UNAUTHORIZED` | 401 | JWT invalid/missing atau internal API key invalid |
| `FORBIDDEN` | 403 | role tidak punya akses |
| `ACCOUNT_DISABLED` | 403 | `is_active = false` |
| `PRODUCT_NOT_FOUND` | 404 | product tidak ada / soft-deleted |
| `CART_ITEM_NOT_FOUND` | 404 | item tidak ada atau bukan milik user |
| `PRODUCT_UNAVAILABLE` | 422 | product status unavailable |
| `PRODUCT_OUT_OF_STOCK` | 422 | product status out_of_stock |
| `INTERNAL_SERVER_ERROR` | 500 | server error |

---

## 7. DB & Transaction Policy

- Semua mutasi wajib transaction:
  - add item
  - update quantity
  - delete item
  - clear all
  - clear internal items
- `cart_items` pakai **hard delete**
- `carts` tidak dihapus walau kosong
- Unique constraint: `(cart_id, product_id)`

### Reference Tables

#### `carts`
- `id` UUID PK
- `user_id` UUID FK ke `public.users` (unique)
- `created_at`, `updated_at`

#### `cart_items`
- `id` UUID PK
- `cart_id` UUID FK
- `product_id` UUID FK
- `quantity` INTEGER (min 1)
- `created_at`, `updated_at`

---

## 8. Logging & Monitoring

Wajib log:
- Mutasi cart (`user_id`, `product_id`/`item_id`)
- Panggilan internal clear item + daftar `item_ids`
- Akses ditolak auth/role (WARNING)
- Error 500 + stack trace (ERROR)

Tidak perlu log:
- GET cart sukses
- clear idempotent yang sukses