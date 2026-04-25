# API Spec — Product Module (Coffee Shop Backend)

## Base Information

- **Base URL:** `/api/v1`
- **Module:** Product (CRUD)
- **Main Actor:**
  - Public/Customer: read-only
  - Pegawai: update status terbatas
  - Admin: full CRUD + restore
- **Storage gambar:** Supabase Storage (URL disimpan di DB)

---

## 1. Authorization Matrix

| Endpoint | Public/Customer | Pegawai | Admin |
|---|:---:|:---:|:---:|
| `GET /products` | ✅ | ✅ | ✅ |
| `GET /products/:id` | ✅ | ✅ | ✅ |
| `POST /products` | ❌ | ❌ | ✅ |
| `PUT /products/:id` | ❌ | ❌ | ✅ |
| `PATCH /products/:id/status` | ❌ | ✅ | ✅ |
| `DELETE /products/:id` (soft delete) | ❌ | ❌ | ✅ |
| `PATCH /products/:id/restore` | ❌ | ❌ | ✅ |

### Auth status convention
- **401 `UNAUTHORIZED`**: token tidak ada/tidak valid/expired
- **403 `FORBIDDEN`**: token valid tapi role tidak punya izin

---

## 2. Product Data Schema

```json
{
  "id": "uuid",
  "name": "Americano",
  "description": "Espresso dengan air panas",
  "price": 25000,
  "category": "coffee",
  "status": "available",
  "image_url": "https://...",
  "rating": 4.5,
  "total_sold": 120,
  "attributes": {},
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z",
  "deleted_at": null
}
```

### Enum Values
- `category`: `coffee | food | snack`
- `status`: `available | out_of_stock | unavailable`

---

## 3. Validation Rules

## 3.1 Common Fields

| Field | Type | Required (Create) | Rules |
|---|---|---:|---|
| `name` | string | ✅ | min 3, max 100, unique case-insensitive |
| `description` | string | ❌ | max 500 |
| `price` | integer | ✅ | min 0, max 99_999_999 |
| `category` | enum | ✅ | `coffee|food|snack` |
| `status` | enum | ✅ | `available|out_of_stock|unavailable`, default `available` |
| `image_url` | string | ✅ | valid Supabase Storage URL |
| `attributes` | object/json | ✅ | wajib sesuai kategori |

> `price = 0` valid (gratis/promo item).

## 3.2 Category Attributes

### Coffee (`category=coffee`)
```json
{
  "temperature": ["hot", "iced"],
  "sugar_levels": ["normal", "less", "no_sugar"],
  "ice_levels": ["normal", "less", "no_ice"],
  "sizes": ["small", "medium", "large"]
}
```

Rules:
- `temperature`: required, min 1, value hanya `hot|iced`
- `sugar_levels`: required, min 1
- `ice_levels`: required, min 1, **wajib ada jika `temperature` memuat `iced`**
- `sizes`: required, min 1

### Food/Snack (`category=food|snack`)
```json
{
  "portions": ["regular", "large"],
  "spicy_levels": ["no_spicy", "mild", "medium", "hot"]
}
```

Rules:
- `portions`: required, min 1
- `spicy_levels`: optional; jika dikirim min 1 dan value valid

---

## 4. Endpoint Specifications

## 4.1 GET `/api/v1/products` — List Products

### Description
Ambil daftar produk dengan filter, search, sort, dan cursor pagination.

### Query Parameters

| Param | Type | Required | Rules |
|---|---|---:|---|
| `cursor` | string | ❌ | opaque base64 cursor |
| `direction` | enum | ❌ | `next|prev`, default `next` |
| `limit` | int | ❌ | default 10, max 50 |
| `category` | enum | ❌ | `coffee|food|snack` |
| `status` | enum | ❌ | `available|out_of_stock|unavailable` |
| `search` | string | ❌ | min 2 chars, case-insensitive by name |
| `sort_by` | enum | ❌ | `name|price|total_sold|rating`, default `name` |
| `sort_dir` | enum | ❌ | `asc|desc`, default `asc` |
| `include_deleted` | boolean | ❌ | default false, **Admin only** |

### Special Behaviors
- `limit > 50` → clamp ke 50 (tetap 200)
- `direction=prev` tanpa `cursor` → mulai dari data paling akhir
- `include_deleted=true` untuk non-admin → `403 FORBIDDEN`

### Success Response (200)
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "Americano",
      "price": 25000,
      "category": "coffee",
      "status": "available",
      "image_url": "https://...",
      "rating": 4.5,
      "total_sold": 120,
      "attributes": {
        "temperature": ["hot", "iced"],
        "sugar_levels": ["normal", "less", "no_sugar"],
        "ice_levels": ["normal", "less", "no_ice"],
        "sizes": ["small", "medium", "large"]
      },
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
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
- `400 VALIDATION_ERROR` (invalid query enum/search/cursor format)
- `400 INVALID_CURSOR`
- `403 FORBIDDEN` (`include_deleted=true` by non-admin)

---

## 4.2 GET `/api/v1/products/:id` — Product Detail

### Description
Ambil detail 1 produk by UUID.

### Path Param
- `id` (UUID, required)

### Success Response (200)
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "Americano",
    "description": "Espresso dengan air panas",
    "price": 25000,
    "category": "coffee",
    "status": "available",
    "image_url": "https://...",
    "rating": 4.5,
    "total_sold": 120,
    "attributes": {
      "temperature": ["hot", "iced"],
      "sugar_levels": ["normal", "less", "no_sugar"],
      "ice_levels": ["normal", "less", "no_ice"],
      "sizes": ["small", "medium", "large"]
    },
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
  },
  "message": "Produk berhasil diambil"
}
```

### Errors
- `400 VALIDATION_ERROR` (id bukan UUID)
- `404 PRODUCT_NOT_FOUND` (tidak ada / soft deleted)

---

## 4.3 POST `/api/v1/products` — Create Product (Admin)

### Auth
- JWT required
- Role: Admin only

### Request Body (coffee example)
```json
{
  "name": "Americano",
  "description": "Espresso dengan air panas",
  "price": 25000,
  "category": "coffee",
  "status": "available",
  "image_url": "https://.../americano.png",
  "attributes": {
    "temperature": ["hot", "iced"],
    "sugar_levels": ["normal", "less", "no_sugar"],
    "ice_levels": ["normal", "less", "no_ice"],
    "sizes": ["small", "medium", "large"]
  }
}
```

### Success Response (201)
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "Americano",
    "description": "Espresso dengan air panas",
    "price": 25000,
    "category": "coffee",
    "status": "available",
    "image_url": "https://.../americano.png",
    "rating": 0,
    "total_sold": 0,
    "attributes": {
      "temperature": ["hot", "iced"],
      "sugar_levels": ["normal", "less", "no_sugar"],
      "ice_levels": ["normal", "less", "no_ice"],
      "sizes": ["small", "medium", "large"]
    },
    "created_at": "2025-01-01T00:00:00Z",
    "updated_at": "2025-01-01T00:00:00Z"
  },
  "message": "Produk berhasil dibuat"
}
```

### Errors
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `400 VALIDATION_ERROR`
- `409 PRODUCT_NAME_ALREADY_EXISTS`
- `500 INTERNAL_SERVER_ERROR`

---

## 4.4 PUT `/api/v1/products/:id` — Update Product (Admin)

### Auth
- JWT required
- Role: Admin only

### Notes
- BR menamai operasi `PUT`, tapi semantik update adalah **partial**:
  - field yang tidak dikirim **tidak di-reset**
  - ini lebih mirip PATCH behavior secara implementasi

### Path Param
- `id` UUID required

### Request Body
Field sama seperti create, namun boleh kirim sebagian field.

### Success Response (200)
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "Americano Large",
    "description": "Updated desc",
    "price": 28000,
    "category": "coffee",
    "status": "available",
    "image_url": "https://.../americano-new.png",
    "rating": 4.5,
    "total_sold": 140,
    "attributes": {
      "temperature": ["hot", "iced"],
      "sugar_levels": ["normal", "less", "no_sugar"],
      "ice_levels": ["normal", "less", "no_ice"],
      "sizes": ["small", "medium", "large"]
    },
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2025-01-02T10:00:00Z"
  },
  "message": "Produk berhasil diperbarui"
}
```

### Errors
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 PRODUCT_NOT_FOUND`
- `409 PRODUCT_NAME_ALREADY_EXISTS`
- `400 VALIDATION_ERROR`
- `500 INTERNAL_SERVER_ERROR`

---

## 4.5 PATCH `/api/v1/products/:id/status` — Update Status (Pegawai/Admin)

### Auth
- JWT required
- Role: Pegawai or Admin

### Path Param
- `id` UUID required

### Request Body
```json
{
  "status": "out_of_stock"
}
```

### Rules
- Pegawai hanya boleh set:
  - `available`
  - `out_of_stock`
- Pegawai set `unavailable` → `403 FORBIDDEN`
- Field selain `status` di payload diabaikan
- Jika status sama dengan status saat ini: tetap `200` (idempotent)

### Success Response (200)
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "status": "out_of_stock",
    "updated_at": "2025-01-03T10:00:00Z"
  },
  "message": "Status produk berhasil diperbarui"
}
```

### Errors
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 PRODUCT_NOT_FOUND`
- `400 VALIDATION_ERROR`
- `500 INTERNAL_SERVER_ERROR`

---

## 4.6 DELETE `/api/v1/products/:id` — Soft Delete Product (Admin)

### Auth
- JWT required
- Role: Admin only

### Path Param
- `id` UUID required

### Behavior
- Set `deleted_at = NOW()`
- Set `status = unavailable`
- Soft delete (bukan hard delete)

### Success Response
- BR punya dua pola:
  - di operation: `204 No Content`
  - di format standar: body sukses dengan message
- **Rekomendasi implementasi konsisten:** gunakan **200** dengan body standar.

Contoh:
```json
{
  "success": true,
  "message": "Produk berhasil dihapus"
}
```

### Errors
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 PRODUCT_NOT_FOUND`
- `409 PRODUCT_ALREADY_DELETED`
- `500 INTERNAL_SERVER_ERROR`

---

## 4.7 PATCH `/api/v1/products/:id/restore` — Restore Product (Admin)

### Auth
- JWT required
- Role: Admin only

### Path Param
- `id` UUID required

### Behavior
- Hanya untuk produk soft-deleted
- Set `deleted_at = NULL`
- Set `status = available`

### Success Response (200)
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "status": "available",
    "deleted_at": null,
    "updated_at": "2025-01-04T10:00:00Z"
  },
  "message": "Produk berhasil dipulihkan"
}
```

### Errors
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 PRODUCT_NOT_FOUND`
- `409 PRODUCT_NOT_DELETED`
- `500 INTERNAL_SERVER_ERROR`

---

## 5. Caching Policy (Redis)

### Key Pattern
- List: `products:list:[hash_query_params]`
- Detail: `products:detail:[product_id]`

### TTL
- List: 5 menit
- Detail: 10 menit

### Invalidation
- Create: invalidate `products:list:*`
- Update full/status: invalidate `products:list:*` + `products:detail:[id]`
- Delete: invalidate `products:list:*` + `products:detail:[id]`
- Restore: invalidate `products:list:*` + `products:detail:[id]`
- System update (`total_sold`/`rating`): invalidate detail terkait

### Fallback
- Jika Redis down/timeout: fallback DB, response tetap sukses, log warning

---

## 6. Error Format

### Standard Error
```json
{
  "success": false,
  "error": {
    "code": "SNAKE_CASE_ERROR_CODE",
    "message": "Pesan yang dapat dibaca manusia"
  }
}
```

### Validation Error (detail per field)
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Input tidak valid",
    "details": {
      "name": "Nama produk wajib diisi",
      "attributes.ice_levels": "Wajib diisi jika temperature mengandung 'iced'"
    }
  }
}
```

---

## 7. Error Code Catalog (Product)

| Code | HTTP | Trigger |
|---|:---:|---|
| `VALIDATION_ERROR` | 400 | input/query/path tidak valid |
| `INVALID_CURSOR` | 400 | cursor pagination invalid/expired |
| `UNAUTHORIZED` | 401 | token invalid/missing |
| `FORBIDDEN` | 403 | role tidak diizinkan |
| `PRODUCT_NOT_FOUND` | 404 | produk tidak ada / soft deleted |
| `PRODUCT_ALREADY_DELETED` | 409 | delete pada produk yang sudah deleted |
| `PRODUCT_NOT_DELETED` | 409 | restore pada produk yang belum deleted |
| `PRODUCT_NAME_ALREADY_EXISTS` | 409 | duplikasi nama produk (case-insensitive) |
| `INTERNAL_SERVER_ERROR` | 500 | server error |

---
