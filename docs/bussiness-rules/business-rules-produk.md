# Business Rules: Produk (CRUD)

Dokumen ini mendefinisikan aturan bisnis untuk modul **Produk** pada sistem **Backend Service Cafe**.

---

## 1. Overview & Scope

- **Deskripsi singkat fitur:** Mengelola data produk cafe (Coffee, Food, Snack) yang dapat dilihat oleh semua pengguna dan dikelola oleh Admin/Pegawai. Produk memiliki attribute khusus per kategori yang digunakan sebagai opsi saat melakukan order.
- **Actor yang terlibat:** Customer (read-only), Pegawai (update status), Admin (full CRUD + restore), System (update penjualan & rating otomatis)
- **Fitur/modul yang dependen:**
  - **Order & Payment** — memicu update `total_sold` pada produk setelah pembayaran sukses
  - **Review/Rating** — menjadi sumber data `rating` produk
- **Out of scope:**
  - Pemilihan final opsi oleh Customer (suhu, level gula, ukuran, dll) — dilakukan saat checkout di modul Order, bukan saat CRUD produk
  - Multi-branch management — sistem ini single-branch
  - Audit log perubahan harga
  - Batas maksimal jumlah produk

---

## 2. Authorization & Access Control

| Operasi                  | Customer (Public) | Pegawai | Admin |
|--------------------------|:-----------------:|:-------:|:-----:|
| GET list produk          | ✓                 | ✓       | ✓     |
| GET detail produk        | ✓                 | ✓       | ✓     |
| POST create produk       | ✗                 | ✗       | ✓     |
| PUT update produk (full) | ✗                 | ✗       | ✓     |
| PATCH update status      | ✗                 | ✓       | ✓     |
| DELETE produk            | ✗                 | ✗       | ✓     |
| PATCH restore produk     | ✗                 | ✗       | ✓     |

**Catatan:**
- Customer dan request tanpa autentikasi diperlakukan sama — keduanya hanya bisa read.
- Pegawai **hanya** boleh mengubah field `status`, dan hanya ke nilai `available` atau `out_of_stock`. Set ke `unavailable` ditolak dengan 403. Field lain yang dikirim diabaikan.
- Hanya Admin yang boleh set status ke `unavailable` (via PATCH update status).
- Admin memiliki akses penuh ke semua operasi.

### Konvensi Kode Status Auth & Authorization

Untuk konsistensi lintas modul:

- **401 `UNAUTHORIZED`**: token tidak ada, tidak valid, atau expired.
- **403 `FORBIDDEN`**: token valid, tetapi role tidak memiliki izin operasi.

**Implementasi wording di semua sad path:**
- Jika kasusnya role tidak sesuai (mis. bukan Admin/Pegawai), gunakan istilah **FORBIDDEN (403)**, bukan “unauthorized”.

---

## 3. Validation Rules

### Field Umum (semua kategori)

| Field         | Tipe    | Required | Constraint                                                                 |
|---------------|---------|----------|---------------------------------------------------------------------------|
| `name`        | string  | ✓        | min 3, max 100 karakter; unik (case-insensitive) dalam tabel produk       |
| `description` | string  | ✗        | max 500 karakter                                                           |
| `price`       | integer | ✓        | min 0, max 99_999_999 (dalam satuan Rupiah)                               |
| `category`    | enum    | ✓        | nilai: `coffee`, `food`, `snack`                                          |
| `status`      | enum    | ✓        | nilai: `available`, `out_of_stock`, `unavailable`; default: `available`   |
| `image_url`   | string  | ✓        | valid URL Supabase Storage; wajib saat CREATE                             |

### Attribute Khusus per Kategori

Attribute khusus disimpan sebagai **JSON column** (`attributes`) di tabel produk.

### Peran `attributes` sebagai API Contract ke Frontend

Kolom `attributes` pada produk adalah **source of truth** daftar opsi yang tersedia untuk dipilih Customer pada saat checkout.

- Backend Product **mendefinisikan** opsi valid per produk (mis. `temperature`, `sizes`, `sugar_levels`, dst).
- Frontend (Flutter) menampilkan opsi berdasarkan `attributes` dari endpoint Product (`GET /products`, `GET /products/:id`).
- Backend Product **tidak** menyimpan pilihan final Customer.
- Pilihan final Customer dikirim pada payload checkout di modul Order dan divalidasi terhadap `products.attributes` terbaru.

**Coffee:**

| Field             | Tipe           | Required | Constraint                                      |
|-------------------|----------------|----------|-------------------------------------------------|
| `temperature`     | array\<enum\>  | ✓        | nilai valid: `hot`, `iced`; min 1 item          |
| `sugar_levels`    | array\<enum\>  | ✓        | nilai valid: `normal`, `less`, `no_sugar`; min 1 item |
| `ice_levels`      | array\<enum\>  | ✓        | nilai valid: `normal`, `less`, `no_ice`; min 1 item; **wajib ada jika `iced` tersedia** |
| `sizes`           | array\<enum\>  | ✓        | nilai valid: `small`, `medium`, `large`; min 1 item |

> **Catatan:** `ice_levels` wajib diisi jika array `temperature` mengandung nilai `iced`.

**Food & Snack:**

| Field             | Tipe           | Required | Constraint                                       |
|-------------------|----------------|----------|--------------------------------------------------|
| `portions`        | array\<enum\>  | ✓        | nilai valid: `regular`, `large`; min 1 item      |
| `spicy_levels`    | array\<enum\>  | ✗        | nilai valid: `no_spicy`, `mild`, `medium`, `hot`; min 1 item jika diisi |

**Catatan umum validasi:**
- Saat PATCH update status oleh Pegawai, hanya field `status` yang diproses. Field lain yang dikirim diabaikan (tidak di-update, tidak error).
- Saat PUT update oleh Admin, semua field wajib yang tidak dikirim **tidak** di-reset ke default — berlaku partial update semantik.
- `price = 0` adalah **valid** (untuk promo gratis / complimentary item).

---

## 4. Business Rules per Operasi

### 4.1 GET /products — List Produk

**Deskripsi:** Mengambil daftar produk dengan dukungan filter, search, sort, dan cursor-based pagination.

**Query Parameters:**

| Parameter        | Tipe    | Required | Deskripsi                                                                       |
|------------------|---------|----------|---------------------------------------------------------------------------------|
| `cursor`         | string  | ✗        | Cursor untuk navigasi maju (next page) atau mundur (prev page) — opaque base64  |
| `direction`      | enum    | ✗        | `next` atau `prev`; default: `next`. Digunakan bersama `cursor`                 |
| `limit`          | int     | ✗        | Jumlah item per halaman; default: 10; max: 50                                   |
| `category`       | enum    | ✗        | Filter: `coffee`, `food`, `snack`                                               |
| `status`         | enum    | ✗        | Filter: `available`, `out_of_stock`, `unavailable`                              |
| `search`         | string  | ✗        | Search by nama produk (case-insensitive); min 2 karakter                        |
| `sort_by`        | enum    | ✗        | `name`, `price`, `total_sold`, `rating`; default: `name`                        |
| `sort_dir`       | enum    | ✗        | `asc`, `desc`; default: `asc`                                                   |
| `include_deleted`| boolean | ✗        | Tampilkan produk yang sudah soft-deleted; default: `false`; **hanya Admin**     |

**Pre-conditions:** Tidak ada (endpoint publik).

**Happy Path:**
1. Parse dan validasi semua query parameters.
2. Terapkan filter `category` jika ada.
3. Terapkan filter `status` jika ada.
4. Terapkan full-text search pada kolom `name` jika `search` ada.
5. Terapkan sort sesuai `sort_by` dan `sort_dir`.
6. Decode `cursor` (opaque base64) dan `direction` untuk menentukan posisi pagination. Jika tidak ada cursor, mulai dari awal (next) atau akhir (prev).
7. Query ke cache Redis terlebih dahulu. Jika cache miss, query ke DB.
8. Return data beserta `next_cursor` dan `prev_cursor` (null jika tidak ada halaman selanjutnya/sebelumnya).

**Sad Path & Edge Cases:**

| Kondisi                              | Behavior Sistem                                              | HTTP Status |
|--------------------------------------|--------------------------------------------------------------|-------------|
| `limit` > 50                                   | Gunakan limit maksimum: 50                                                | 200         |
| `search` < 2 karakter                          | Return validation error                                                   | 400         |
| `sort_by` atau `sort_dir` invalid              | Return validation error                                                   | 400         |
| `category` atau `status` value invalid         | Return validation error                                                   | 400         |
| `direction` value invalid                      | Return validation error                                                   | 400         |
| `cursor` tidak valid / expired                 | Return error cursor invalid                                               | 400         |
| `cursor` tidak dikirim + `direction: prev`     | Mulai dari item terakhir (halaman paling akhir)                           | 200         |
| `include_deleted=true` oleh non-Admin          | Return forbidden                                                          | 403         |
| Tidak ada produk yang cocok                    | Return array kosong, `next_cursor: null`, `prev_cursor: null`             | 200         |
| Cache Redis down                               | Fallback langsung ke DB, log warning                                      | 200         |

**Post-conditions:** Tidak ada perubahan state.

---

### 4.2 GET /products/:id — Detail Produk

**Deskripsi:** Mengambil detail satu produk berdasarkan ID.

**Pre-conditions:** Tidak ada (endpoint publik).

**Happy Path:**
1. Validasi format `id` (UUID).
2. Cek cache Redis. Jika hit, return dari cache.
3. Jika cache miss, query ke DB.
4. Return data produk beserta `attributes` khusus kategori.

**Sad Path & Edge Cases:**

| Kondisi                          | Behavior Sistem                           | HTTP Status |
|----------------------------------|-------------------------------------------|-------------|
| Format `id` bukan UUID           | Return validation error                   | 400         |
| Produk tidak ditemukan           | Return `PRODUCT_NOT_FOUND`                | 404         |
| Produk sudah soft-deleted        | Return `PRODUCT_NOT_FOUND`                | 404         |
| Cache Redis down                 | Fallback ke DB, log warning               | 200         |

**Post-conditions:** Tidak ada perubahan state.

---

### 4.3 POST /products — Create Produk

**Deskripsi:** Membuat produk baru. Hanya dapat dilakukan oleh Admin.

**Pre-conditions:**
- Request terautentikasi dengan role `admin`.
- Gambar produk sudah di-upload ke Supabase Storage dan URL valid.

**Happy Path:**
1. Validasi autentikasi dan role admin.
2. Validasi semua field umum dan attribute khusus sesuai kategori.
3. Cek duplikasi nama produk (case-insensitive).
4. Simpan data produk ke DB dalam satu transaction.
5. Invalidate cache list produk di Redis.
6. Return data produk yang baru dibuat.

**Sad Path & Edge Cases:**

| Kondisi                              | Behavior Sistem                                    | HTTP Status |
|--------------------------------------|----------------------------------------------------|-------------|
| Role bukan admin                     | Return unauthorized                                | 403         |
| Validation error (field umum)        | Return detail error per field                      | 400         |
| Validation error (attribute kategori)| Return detail error per field di dalam `attributes`| 400         |
| Nama produk sudah ada                | Return `PRODUCT_NAME_ALREADY_EXISTS`               | 409         |
| `image_url` tidak valid              | Return validation error                            | 400         |
| `ice_levels` kosong padahal ada `iced` di temperature | Return validation error         | 400         |
| DB error                             | Rollback transaction, log error                    | 500         |

**Post-conditions:**
- Produk baru tersimpan di DB dengan `status: available`.
- Cache list produk di Redis di-invalidate.
- `created_at`, `updated_at` ter-set otomatis.

---

### 4.4 PUT /products/:id — Update Produk (Admin)

**Deskripsi:** Mengupdate data produk secara penuh oleh Admin.

**Pre-conditions:**
- Request terautentikasi dengan role `admin`.
- Produk dengan ID tersebut ada dan belum di-soft-delete.

**Happy Path:**
1. Validasi autentikasi dan role admin.
2. Validasi format `id` (UUID) dan pastikan produk ada.
3. Validasi field yang dikirim (partial update — field yang tidak dikirim tidak di-reset).
4. Cek duplikasi nama jika field `name` diubah.
5. Update data di DB.
6. Invalidate cache list dan cache detail produk tersebut di Redis.
7. Return data produk yang sudah diupdate.

**Sad Path & Edge Cases:**

| Kondisi                              | Behavior Sistem                                    | HTTP Status |
|--------------------------------------|----------------------------------------------------|-------------|
| Role bukan admin                     | Return unauthorized                                | 403         |
| Produk tidak ditemukan               | Return `PRODUCT_NOT_FOUND`                         | 404         |
| Produk sudah soft-deleted            | Return `PRODUCT_NOT_FOUND`                         | 404         |
| Nama baru sudah dipakai produk lain  | Return `PRODUCT_NAME_ALREADY_EXISTS`               | 409         |
| Validation error                     | Return detail error per field                      | 400         |
| DB error                             | Rollback transaction, log error                    | 500         |

**Post-conditions:**
- Data produk ter-update di DB.
- `updated_at` diperbarui.
- Cache list dan detail di Redis di-invalidate.

---

### 4.5 PATCH /products/:id/status — Update Status Produk (Pegawai & Admin)

**Deskripsi:** Mengubah status produk saja. Dapat dilakukan oleh Pegawai maupun Admin.

**Pre-conditions:**
- Request terautentikasi dengan role `pegawai` atau `admin`.
- Produk dengan ID tersebut ada dan belum di-soft-delete.

**Happy Path:**
1. Validasi autentikasi dan role (pegawai atau admin).
2. Validasi format `id` (UUID) dan pastikan produk ada.
3. Validasi nilai `status` (harus: `available`, `out_of_stock`, atau `unavailable`).
4. Abaikan field lain selain `status` yang mungkin ikut dikirim.
5. Update kolom `status` di DB.
6. Invalidate cache list dan cache detail produk tersebut di Redis.
7. Return data produk yang sudah diupdate.

**Sad Path & Edge Cases:**

| Kondisi                                        | Behavior Sistem                                    | HTTP Status |
|------------------------------------------------|----------------------------------------------------|-------------|
| Role bukan pegawai atau admin                  | Return unauthorized                                | 403         |
| Role pegawai mencoba set status `unavailable`  | Return forbidden                                   | 403         |
| Produk tidak ditemukan                         | Return `PRODUCT_NOT_FOUND`                         | 404         |
| Produk sudah soft-deleted                      | Return `PRODUCT_NOT_FOUND`                         | 404         |
| Nilai `status` tidak valid                     | Return validation error                            | 400         |
| Status sama dengan yang sekarang               | Tetap proses dan return 200 (idempotent)           | 200         |
| DB error                                       | Rollback transaction, log error                    | 500         |

**Post-conditions:**
- Kolom `status` produk ter-update di DB.
- `updated_at` diperbarui.
- Cache list dan detail di Redis di-invalidate.

---

### 4.6 DELETE /products/:id — Hapus Produk

**Deskripsi:** Melakukan soft-delete pada produk. Hanya dapat dilakukan oleh Admin.

**Pre-conditions:**
- Request terautentikasi dengan role `admin`.
- Produk dengan ID tersebut ada dan belum di-soft-delete.

**Happy Path:**
1. Validasi autentikasi dan role admin.
2. Validasi format `id` (UUID) dan pastikan produk ada dan belum di-soft-delete.
3. Set `deleted_at = NOW()` dan `status = unavailable` di DB dalam satu transaction.
4. Invalidate cache list dan cache detail produk tersebut di Redis.
5. Return 204 No Content.

**Sad Path & Edge Cases:**

| Kondisi                              | Behavior Sistem                                    | HTTP Status |
|--------------------------------------|----------------------------------------------------|-------------|
| Role bukan admin                     | Return unauthorized                                | 403         |
| Produk tidak ditemukan               | Return `PRODUCT_NOT_FOUND`                         | 404         |
| Produk sudah pernah di-soft-delete   | Return `PRODUCT_ALREADY_DELETED`                   | 409         |
| DB error                             | Rollback transaction, log error                    | 500         |

**Post-conditions:**
- Kolom `deleted_at` ter-set dan `status` berubah menjadi `unavailable` di DB.
- Produk tidak akan muncul di GET list maupun GET detail untuk semua role.
- Cache list dan detail di Redis di-invalidate.

---

### 4.7 PATCH /products/:id/restore — Restore Produk

**Deskripsi:** Memulihkan produk yang sudah di-soft-delete kembali ke status `available`. Hanya dapat dilakukan oleh Admin.

**Pre-conditions:**
- Request terautentikasi dengan role `admin`.
- Produk dengan ID tersebut ada dan sudah dalam kondisi soft-deleted.

**Happy Path:**
1. Validasi autentikasi dan role admin.
2. Validasi format `id` (UUID) dan pastikan produk ada.
3. Pastikan produk dalam kondisi soft-deleted (`deleted_at IS NOT NULL`).
4. Set `deleted_at = NULL` dan `status = available` di DB dalam satu transaction.
5. Invalidate cache list dan cache detail produk tersebut di Redis.
6. Return data produk yang sudah di-restore.

**Sad Path & Edge Cases:**

| Kondisi                              | Behavior Sistem                                    | HTTP Status |
|--------------------------------------|----------------------------------------------------|-------------|
| Role bukan admin                     | Return unauthorized                                | 403         |
| Produk tidak ditemukan               | Return `PRODUCT_NOT_FOUND`                         | 404         |
| Produk belum di-soft-delete (masih aktif) | Return `PRODUCT_NOT_DELETED`                  | 409         |
| DB error                             | Rollback transaction, log error                    | 500         |

**Post-conditions:**
- Kolom `deleted_at` di-set kembali ke `NULL` di DB.
- `status` produk di-set ke `available`.
- `updated_at` diperbarui.
- Produk muncul kembali di GET list dan GET detail.
- Cache list dan detail di Redis di-invalidate.

---

## 5. Caching Policy

- **Engine:** Redis
- **Key pattern:**
  - List: `products:list:[hash_dari_query_params]`
  - Detail: `products:detail:[product_id]`
- **TTL:**
  - List: 5 menit
  - Detail: 10 menit
- **Invalidation trigger:**
  - CREATE → invalidate semua key `products:list:*`
  - UPDATE (full/status) → invalidate `products:list:*` + `products:detail:[id]`
  - DELETE → invalidate `products:list:*` + `products:detail:[id]`
  - RESTORE → invalidate `products:list:*` + `products:detail:[id]` (termasuk cache yang sebelumnya include deleted)
- **Invalidation timing:** Setelah DB commit berhasil
- **Fallback jika cache down:** Fallback langsung ke DB, log warning level. Response tetap sukses.
- **Edge case — update `total_penjualan` / `rating`:** Ketika System memperbarui data ini (dari modul Order/Review), cache detail produk yang bersangkutan juga di-invalidate.

---

## 6. External Service & Side Effects

| Trigger                     | Service / Action                                              | Sync/Async |
|-----------------------------|-----------------------------------------------------------------|------------|
| Order sukses & payment done | System update kolom `total_sold` pada produk terkait          | Async      |
| Review customer submit      | System update kolom `rating` (rata-rata) pada produk terkait  | Async      |

**Catatan:**
- Update `total_sold` dan `rating` oleh System dilakukan secara async dan bukan bagian dari flow CRUD produk ini.
- Tidak ada integrasi ke external service (CDN, email, dsb) yang di-trigger langsung oleh operasi CRUD produk.
- Gambar produk dikelola oleh client (Flutter) yang langsung upload ke Supabase Storage. Backend hanya menerima dan menyimpan URL-nya.
- **Fallback gambar:** Jika `image_url` pada produk menghasilkan 404 saat diakses client (gambar dihapus manual dari Supabase Storage), backend tidak mendeteksi hal ini secara aktif. Client Flutter bertanggung jawab menampilkan gambar placeholder abu-abu jika URL gagal dimuat. Tidak ada mekanisme validasi URL gambar saat runtime di backend.

---

## 7. Response Format

### Success — dengan data
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
  "message": "Produk berhasil dibuat"
}
```

### Success — list (dengan pagination)
```json
{
  "success": true,
  "data": [...],
  "pagination": {
    "next_cursor": "base64string_or_null",
    "prev_cursor": "base64string_or_null",
    "limit": 10,
    "has_next": true,
    "has_prev": false
  }
}
```

### Success — tanpa data (DELETE)
```json
{
  "success": true,
  "message": "Produk berhasil dihapus"
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

### Error — validation (400)
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

### Daftar Error Code

| Code                          | Trigger                                                                    |
|-------------------------------|----------------------------------------------------------------------------|
| `VALIDATION_ERROR`            | Input tidak memenuhi constraint validasi                                   |
| `PRODUCT_NOT_FOUND`           | GET / PUT / PATCH / DELETE pada produk yang tidak ada atau sudah dihapus   |
| `PRODUCT_ALREADY_DELETED`     | DELETE pada produk yang sudah pernah di-soft-delete                        |
| `PRODUCT_NOT_DELETED`         | RESTORE pada produk yang belum di-soft-delete (masih aktif)                |
| `PRODUCT_NAME_ALREADY_EXISTS` | CREATE atau UPDATE dengan nama yang sudah dipakai produk lain              |
| `INVALID_CURSOR`              | Cursor pagination tidak valid atau expired                                 |
| `UNAUTHORIZED`                | Token tidak ada atau tidak valid                                            |
| `FORBIDDEN`                   | Role tidak memiliki izin untuk operasi ini                                 |
| `INTERNAL_SERVER_ERROR`       | Error tidak terduga di server                                              |

---

> **Catatan API Contract:** Field `attributes` pada response Product berfungsi sebagai kontrak opsi UI di frontend. Nilai pada field ini adalah daftar opsi yang boleh dipilih Customer saat checkout (divalidasi ulang di modul Order).

---
## 8. Database & Transaction Policy

- **Transaction scope:** Semua operasi mutasi (CREATE, UPDATE, DELETE, RESTORE) wajib menggunakan DB transaction.
- **Soft delete:** Menggunakan soft delete dengan kolom `deleted_at`. Alasan: data produk terikat ke histori order. Hard delete akan merusak integritas data order historis.
- **Kolom audit:** `created_at`, `updated_at`, `deleted_at`
- **Locking strategy:** Tidak diperlukan untuk saat ini. Operasi update produk tidak memiliki potensi race condition yang kritis. Dapat ditambahkan optimistic locking (via kolom `version`) di masa mendatang jika diperlukan.

### Desain Tabel (Referensi)

**Tabel `products`:**

| Kolom          | Tipe        | Keterangan                                              |
|----------------|-------------|-------------------------------------------------------- |
| `id`           | UUID        | Primary key                                             |
| `name`         | VARCHAR(100)| Unik (case-insensitive), gunakan unique index lowercase |
| `description`  | TEXT        | Nullable                                                |
| `price`        | INTEGER     | Dalam satuan Rupiah                                     |
| `category`     | ENUM        | `coffee`, `food`, `snack`                               |
| `status`       | ENUM        | `available`, `out_of_stock`, `unavailable`              |
| `image_url`    | TEXT        | URL Supabase Storage                                    |
| `attributes`   | JSONB       | Attribute khusus per kategori                           |
| `rating`       | DECIMAL(3,2)| Rata-rata rating, diupdate oleh modul Review            |
| `total_sold`   | INTEGER     | Diupdate oleh modul Order, default: 0                   |
| `created_at`   | TIMESTAMPTZ | Auto set                                                |
| `updated_at`   | TIMESTAMPTZ | Auto update                                             |
| `deleted_at`   | TIMESTAMPTZ | Nullable; non-null = soft deleted                       |

---

## 9. Logging & Monitoring

**Yang wajib di-log:**
- Setiap operasi mutasi (CREATE / UPDATE / DELETE / RESTORE) beserta `user_id`, `role`, dan `product_id`
- Cache miss yang berujung DB query (level: DEBUG)
- Redis down / timeout (level: WARNING)
- Error 500 dengan full stack trace (level: ERROR)
- Akses yang ditolak karena role tidak sesuai (level: WARNING)

**Yang tidak perlu di-log:**
- GET request yang sukses
- Cache hit

---

