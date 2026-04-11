# API Spec — Back Office Module (Coffee Shop Backend)

## Base Information

- **Base URL:** `/api/v1`
- **Module Name:** Back Office
- **Actors:**
  - `Pegawai` (akses terbatas operasional)
  - `Admin` (akses penuh)
- **Scope utama:** order queue ops, product ops, customer read-only, reporting & export

---

## 1. Access Matrix (Back Office)

## 1.1 Order Management

| Operasi | Pegawai | Admin | Catatan Endpoint |
|---|:---:|:---:|---|
| GET list semua order | ✅ | ✅ | **[IRISAN]** gunakan endpoint Order: `GET /orders` |
| GET detail order | ✅ | ✅ | **[IRISAN]** gunakan endpoint Order: `GET /orders/:order_id` |
| PATCH `CONFIRMED -> COMPLETED` | ✅ | ✅ | **[IRISAN]** gunakan endpoint Order: `PATCH /orders/:order_id/status` |
| PATCH transisi status valid lain | ❌ | ✅ | **[IRISAN]** endpoint Order yang sama |
| PATCH cancel order | ❌ | ✅ | **[IRISAN]** gunakan endpoint Order: `PATCH /orders/:order_id/cancel` |

## 1.2 Product Management

| Operasi | Pegawai | Admin | Catatan Endpoint |
|---|:---:|:---:|---|
| GET list produk | ✅ | ✅ | **[IRISAN]** `GET /products` |
| GET detail produk | ✅ | ✅ | **[IRISAN]** `GET /products/:id` |
| POST create produk | ❌ | ✅ | **[IRISAN]** `POST /products` |
| PUT update produk | ❌ | ✅ | **[IRISAN]** `PUT /products/:id` |
| PATCH update status | ✅ | ✅ | **[IRISAN]** `PATCH /products/:id/status` |
| DELETE produk (soft) | ❌ | ✅ | **[IRISAN]** `DELETE /products/:id` |
| PATCH restore produk | ❌ | ✅ | **[IRISAN]** `PATCH /products/:id/restore` |

## 1.3 User/Customer Management

| Operasi | Pegawai | Admin | Catatan Endpoint |
|---|:---:|:---:|---|
| GET list customer | ❌ | ✅ | Endpoint Back Office khusus |
| GET detail customer | ❌ | ✅ | Endpoint Back Office khusus |

## 1.4 Reporting

| Operasi | Pegawai | Admin | Catatan |
|---|:---:|:---:|---|
| GET summary dashboard | ✅ (versi terbatas) | ✅ (full) | Endpoint sama, response by role |
| GET laporan periodik | ❌ | ✅ | Admin only |
| GET laporan per produk | ❌ | ✅ | Admin only |
| GET export CSV/PDF | ❌ | ✅ | Admin only |

---

## 2. Routing Notes (Endpoint Irisan vs Endpoint Khusus)

## Endpoint **[IRISAN]** (pakai modul sebelumnya)
- Orders:
  - `GET /orders`
  - `GET /orders/:order_id`
  - `PATCH /orders/:order_id/status`
  - `PATCH /orders/:order_id/cancel`
- Products:
  - `GET /products`
  - `GET /products/:id`
  - `POST /products`
  - `PUT /products/:id`
  - `PATCH /products/:id/status`
  - `DELETE /products/:id`
  - `PATCH /products/:id/restore`

## Endpoint Back Office khusus (baru/fokus reporting+customer)
- `GET /admin/customers`
- `GET /admin/customers/:user_id`
- `GET /admin/reports/summary`
- `GET /admin/reports/orders`
- `GET /admin/reports/products`
- `GET /admin/reports/export`

---

## 3. Common Security Rules

- Semua endpoint Back Office wajib:
  - JWT valid
  - cek role (`Pegawai`/`Admin`)
  - cek `is_active = true` di `public.users`
- Pelanggaran akses -> `403 FORBIDDEN`
- Tidak ada endpoint login terpisah Back Office (pakai Supabase login flow utama).

---

## 4. Endpoint Specifications (Back Office Khusus)

## 4.1 GET `/api/v1/admin/customers` — List Customers (Admin only)

### Auth
- JWT required
- Role: Admin only

### Query Params

| Param | Type | Required | Rules |
|---|---|---:|---|
| `search` | string | ❌ | search by `full_name` or `email` |
| `is_active` | boolean | ❌ | default semua |
| `cursor` | string | ❌ | cursor pagination |
| `limit` | integer | ❌ | default 20, max 100 |

### Business Rules
- Query sumber data: `public.users` dengan filter `role = 'Customer'`
- Read-only
- `avatar_url` tidak perlu di list (boleh di detail)

### Success Response (200)
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "uuid",
        "full_name": "Budi",
        "email": "budi@mail.com",
        "phone_number": "+628123",
        "is_active": true,
        "is_verified": true,
        "created_at": "2025-01-01T00:00:00Z"
      }
    ],
    "next_cursor": "cursor_string_atau_null"
  },
  "message": "Berhasil mengambil data"
}
```

### Errors
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `403 ACCOUNT_DISABLED`
- `400 VALIDATION_ERROR`
- `500 INTERNAL_SERVER_ERROR`

---

## 4.2 GET `/api/v1/admin/customers/:user_id` — Customer Detail (Admin only)

### Auth
- JWT required
- Role: Admin only

### Path Param
- `user_id` UUID required

### Business Rules
- Hanya return data jika `role='Customer'`
- Jika `user_id` valid tapi role bukan customer -> tetap `CUSTOMER_NOT_FOUND` (anti data leak)

### Success Response (200)
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "full_name": "Budi",
    "email": "budi@mail.com",
    "phone_number": "+628123",
    "is_active": true,
    "is_verified": true,
    "avatar_url": "https://...",
    "created_at": "2025-01-01T00:00:00Z"
  },
  "message": "Berhasil mengambil data"
}
```

### Errors
- `400 VALIDATION_ERROR`
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `403 ACCOUNT_DISABLED`
- `404 CUSTOMER_NOT_FOUND`
- `500 INTERNAL_SERVER_ERROR`

---

## 4.3 GET `/api/v1/admin/reports/summary` — Summary Dashboard

### Auth
- JWT required
- Role: `Pegawai` or `Admin`

### Query Params

| Param | Type | Required | Rules |
|---|---|---:|---|
| `date_from` | string (date) | ❌ | format `YYYY-MM-DD` |
| `date_to` | string (date) | ❌ | format `YYYY-MM-DD` |

### Validation Rules
- jika salah satu date dikirim tanpa pasangannya -> `VALIDATION_ERROR`
- `date_from > date_to` -> `VALIDATION_ERROR`
- range > 365 hari -> `DATE_RANGE_TOO_LARGE`
- jika keduanya kosong -> default 30 hari terakhir

### Role-based Behavior
- **Pegawai:** hanya metrik operasional hari ini, filter tanggal diabaikan
  - `total_orders_today`
  - `active_confirmed_orders`
- **Admin:** full metrics by range
  - total revenue
  - total orders
  - completed
  - cancelled
  - new customers
  - top products

### Success Response (Admin, 200)
```json
{
  "success": true,
  "data": {
    "period": {
      "date_from": "2025-03-01",
      "date_to": "2025-03-31"
    },
    "total_revenue": 15000000,
    "total_orders": 320,
    "completed_orders": 290,
    "cancelled_orders": 30,
    "new_customers": 45,
    "top_products": [
      { "product_id": "uuid", "product_name": "Kopi Susu", "total_sold": 120 }
    ]
  },
  "message": "Berhasil mengambil summary"
}
```

### Success Response (Pegawai, 200)
```json
{
  "success": true,
  "data": {
    "period": {
      "date_from": "2026-04-10",
      "date_to": "2026-04-10"
    },
    "total_orders_today": 52,
    "active_confirmed_orders": 14
  },
  "message": "Berhasil mengambil summary"
}
```

### Errors
- `400 VALIDATION_ERROR`
- `400 DATE_RANGE_TOO_LARGE`
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `403 ACCOUNT_DISABLED`
- `500 INTERNAL_SERVER_ERROR`

> Jika tidak ada data -> tetap 200 dengan angka 0/array kosong.

---

## 4.4 GET `/api/v1/admin/reports/orders` — Periodic Orders Report (Admin only)

### Auth
- JWT required
- Role: Admin only

### Query Params

| Param | Type | Required | Rules |
|---|---|---:|---|
| `date_from` | string (date) | ❌ | `YYYY-MM-DD` |
| `date_to` | string (date) | ❌ | `YYYY-MM-DD` |
| `group_by` | string | ❌ | `day|week|month`, default `day` |

### Validation
- sama seperti summary (pairing date, max range 365, order date valid)

### Success Response (200)
```json
{
  "success": true,
  "data": {
    "period": {
      "date_from": "2025-03-01",
      "date_to": "2025-03-31",
      "group_by": "day"
    },
    "rows": [
      {
        "period": "2025-03-31",
        "total_orders": 15,
        "completed_orders": 13,
        "cancelled_orders": 2,
        "total_revenue": 750000
      }
    ]
  },
  "message": "Berhasil mengambil laporan"
}
```

### Errors
- `400 VALIDATION_ERROR`
- `400 DATE_RANGE_TOO_LARGE`
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `403 ACCOUNT_DISABLED`
- `500 INTERNAL_SERVER_ERROR`

---

## 4.5 GET `/api/v1/admin/reports/products` — Product Sales Report (Admin only)

### Auth
- JWT required
- Role: Admin only

### Query Params

| Param | Type | Required | Rules |
|---|---|---:|---|
| `date_from` | string (date) | ❌ | `YYYY-MM-DD` |
| `date_to` | string (date) | ❌ | `YYYY-MM-DD` |

> `group_by` tidak berlaku di endpoint ini.

### Business Rules
- Data dari `order_items JOIN orders` dengan `orders.status='COMPLETED'`
- Produk tanpa penjualan di range tidak ditampilkan
- sort default: `total_sold DESC`

### Success Response (200)
```json
{
  "success": true,
  "data": {
    "period": { "date_from": "2025-03-01", "date_to": "2025-03-31" },
    "rows": [
      {
        "product_id": "uuid",
        "product_name": "Kopi Susu",
        "category": "COFFEE",
        "total_sold": 120,
        "total_revenue": 3600000
      }
    ]
  },
  "message": "Berhasil mengambil laporan per produk"
}
```

### Errors
- `400 VALIDATION_ERROR`
- `400 DATE_RANGE_TOO_LARGE`
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `403 ACCOUNT_DISABLED`
- `500 INTERNAL_SERVER_ERROR`

---

## 4.6 GET `/api/v1/admin/reports/export` — Export Report (CSV/PDF, Admin only)

### Auth
- JWT required
- Role: Admin only

### Query Params
Gabungan parameter laporan + format:

| Param | Type | Required | Rules |
|---|---|---:|---|
| `format` | string | ✅ | `csv|pdf` |
| `date_from` | string (date) | ❌ | `YYYY-MM-DD` |
| `date_to` | string (date) | ❌ | `YYYY-MM-DD` |
| `group_by` | string | ❌ | `day|week|month` (jika export report periodik) |
| `report_type` | string | ❌ | disarankan: `orders|products` untuk menentukan sumber report |

> BR menyebut export bisa untuk report periodik dan per produk. Agar eksplisit di implementasi, disarankan tambahkan `report_type`.

### Success Response
- **CSV**
  - `Content-Type: text/csv`
  - `Content-Disposition: attachment; filename="report-{date_from}-{date_to}.csv"`
- **PDF**
  - `Content-Type: application/pdf`
  - `Content-Disposition: attachment; filename="report-{date_from}-{date_to}.pdf"`

### Errors
- `400 VALIDATION_ERROR` (termasuk format invalid)
- `400 DATE_RANGE_TOO_LARGE`
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `403 ACCOUNT_DISABLED`
- `500 EXPORT_FAILED`
- `500 INTERNAL_SERVER_ERROR`

---

## 5. Endpoint Irisan (Referensi cepat)

## 5.1 Order endpoints yang dipakai Back Office (**[IRISAN]**)
- `GET /api/v1/orders`
- `GET /api/v1/orders/:order_id`
- `PATCH /api/v1/orders/:order_id/status`
- `PATCH /api/v1/orders/:order_id/cancel`

## 5.2 Product endpoints yang dipakai Back Office (**[IRISAN]**)
- `GET /api/v1/products`
- `GET /api/v1/products/:id`
- `POST /api/v1/products`
- `PUT /api/v1/products/:id`
- `PATCH /api/v1/products/:id/status`
- `DELETE /api/v1/products/:id`
- `PATCH /api/v1/products/:id/restore`

> Untuk detail request/response masing-masing endpoint irisan, ikuti spec modul Order/Product yang sudah dibuat sebelumnya.

---

## 6. Standard Response Format

### Success — List with cursor
```json
{
  "success": true,
  "data": {
    "items": [],
    "next_cursor": "cursor_string_atau_null"
  },
  "message": "Berhasil mengambil data"
}
```

### Success — Data object
```json
{
  "success": true,
  "data": {},
  "message": "Berhasil mengambil data"
}
```

### Error
```json
{
  "success": false,
  "error": {
    "code": "SNAKE_CASE_ERROR_CODE",
    "message": "Deskripsi error yang human-readable"
  }
}
```

---

## 7. Error Code Catalog (Back Office)

| Code | HTTP | Trigger |
|---|:---:|---|
| `UNAUTHORIZED` | 401 | token invalid/missing |
| `FORBIDDEN` | 403 | role tidak berhak |
| `ACCOUNT_DISABLED` | 403 | `is_active=false` |
| `VALIDATION_ERROR` | 400 | query/path invalid |
| `DATE_RANGE_TOO_LARGE` | 400 | range tanggal >365 hari |
| `CUSTOMER_NOT_FOUND` | 404 | customer tidak ditemukan / bukan role customer |
| `EXPORT_FAILED` | 500 | gagal generate file export |
| `INTERNAL_SERVER_ERROR` | 500 | server error |

> Error code dari endpoint **[IRISAN]** mengikuti modul asal (Order/Product).

---

## 8. Caching Policy (Reporting)

- **Engine:** Redis
- **Key pattern:**
  - Summary: `report:summary:{date_from}:{date_to}`
  - Orders periodic: `report:orders:{date_from}:{date_to}:{group_by}`
- **TTL:** 5 menit
- **Invalidation:** tidak aktif (biarkan expire by TTL)
- **Fallback:** jika Redis down -> query DB langsung, jangan fail request
- **Export:** tidak di-cache, generate fresh per request

---

## 9. DB & Transaction Notes

- Back Office tidak menambah mutasi baru di luar modul Order/Product yang sudah ada.
- Reporting bersifat read-only, tidak butuh transaction.
- Tidak ada tabel baru khusus Back Office di BR ini.

---

## 10. Logging & Monitoring

Wajib log:
- akses endpoint reporting + `admin_id/pegawai_id`, filter params, durasi query (INFO)
- request export + actor, format, ukuran file (INFO)
- query reporting lambat (mis. >2s) (WARNING)
- gagal generate export (ERROR)
- akses ditolak role (WARNING)
- error 500 + stack trace (ERROR)

Tidak perlu log:
- GET list order/produk/customer yang sukses (sudah di modul masing-masing)
- cache hit reporting