# Business Rules: Order

Dokumen ini mendefinisikan aturan bisnis untuk modul **Order** pada sistem **Backend Service Cafe**.

---

## 1. Overview & Scope

- **Deskripsi singkat fitur:** Memungkinkan Customer untuk melakukan checkout item-item yang valid dari cart, membuat record order beserta snapshot harga, detail produk, dan atribut pilihan saat itu, serta melacak status order. Order adalah jembatan antara Cart dan Payment — order dibuat setelah checkout, dan diselesaikan setelah payment sukses.
- **Actor yang terlibat:**
  - `Customer` — membuat order dari cart, melihat history dan status order milik sendiri, membatalkan order
  - `Pegawai` — melihat semua order (antrian), melihat detail order, mengubah status `CONFIRMED → COMPLETED`
  - `Admin` — melihat semua order, mengubah semua transisi status order yang diizinkan
  - `System (Payment Service)` — mengupdate status order setelah payment sukses via internal endpoint
  - `System (Cart Service)` — menerima trigger clear cart dari Order Service setelah payment sukses
- **Fitur/modul yang dependen:**
  - **Cart** — sumber item yang akan di-checkout; Order Service memanggil Cart Service untuk clear item setelah payment sukses
  - **Product** — validasi ketersediaan, stok, dan atribut saat checkout; `total_sold` di-update setelah order selesai
  - **User** — validasi `is_verified` dan `phone_number` sebagai pre-condition checkout
  - **Payment** — Order Service membuat order, Payment Service menyelesaikannya
- **Out of scope:**
  - Notifikasi real-time ke Customer (WebSocket/push notification)
  - Review/rating produk — dihandle di modul terpisah
  - Manajemen stok produk — stok hanya berkurang saat checkout dan dikembalikan saat cancel/expiry, bukan dikelola di sini

---

## 2. Authorization & Access Control

| Operasi                                     | Public | Customer          | Pegawai         | Admin |
|---------------------------------------------|:------:|:-----------------:|:---------------:|:-----:|
| POST checkout (buat order)                  | ✗      | ✓                 | ✗               | ✗     |
| GET order history / list antrian            | ✗      | ✓ (milik sendiri) | ✓ (semua order) | ✓     |
| GET order detail                            | ✗      | ✓ (milik sendiri) | ✓ (semua order) | ✓     |
| PATCH cancel order                          | ✗      | ✓ (milik sendiri) | ✗               | ✓     |
| PATCH update status (`CONFIRMED→COMPLETED`) | ✗      | ✗                 | ✓               | ✓     |
| PATCH update status (semua transisi)        | ✗      | ✗                 | ✗               | ✓     |
| PATCH internal update status (Payment)      | ✗      | ✗                 | ✗               | ✗     |

**Catatan:**
- Semua endpoint Order wajib melewati middleware Golang yang mengecek `is_active` di `public.users` — sesuai arsitektur User BR (mitigasi celah akun disabled). **Pengecualian:** endpoint internal `PATCH /internal/orders/:order_id/status` menggunakan `X-Internal-Api-Key`, bukan JWT user.
- Customer hanya bisa mengakses order milik dirinya sendiri. `order.user_id` harus selalu dicocokkan dengan `user_id` dari JWT.
- Pegawai hanya bisa mengubah status `CONFIRMED → COMPLETED` — transisi lain ditolak dengan `FORBIDDEN`.
- Admin memiliki akses penuh ke semua operasi dan semua transisi status yang diizinkan.
- Update status order oleh Payment Service menggunakan mekanisme internal (shared internal API key via header `X-Internal-Api-Key`) — sama seperti pola yang sudah digunakan di Cart BR.

---

## 3. Validation Rules

### Order (saat Checkout)

| Field    | Tipe            | Required | Constraint                                                                              |
|----------|-----------------|----------|-----------------------------------------------------------------------------------------|
| `notes`  | string          | ✗        | max 255 karakter; boleh kosong atau tidak dikirim                                       |
| `items`  | array\<object\> | ✓        | Tidak boleh kosong; setiap elemen adalah object `{ cart_item_id, attributes? }`         |

**Struktur setiap elemen `items`:**

| Field          | Tipe   | Required | Constraint                                                                              |
|----------------|--------|----------|-----------------------------------------------------------------------------------------|
| `cart_item_id` | UUID   | ✓        | Harus exist di `cart_items` dan merupakan milik user yang sedang login                  |
| `attributes`   | object | ✗*       | Atribut pilihan Customer per item; struktur tergantung kategori produk (lihat di bawah) |

> \* `attributes` wajib atau opsional per field tergantung kategori produk — lihat tabel di bawah.

### Atribut per Kategori Produk (dalam `attributes`)

**Coffee:**

| Field          | Required | Nilai Valid                                               | Default jika tidak dikirim                               |
|----------------|:--------:|-----------------------------------------------------------|----------------------------------------------------------|
| `temperature`  | **✓**    | salah satu dari `product.attributes.temperature`          | — (wajib diisi)                                          |
| `sizes`        | **✓**    | salah satu dari `product.attributes.sizes`                | — (wajib diisi)                                          |
| `sugar_levels` | ✗        | salah satu dari `product.attributes.sugar_levels`         | `normal`(string literal dari enum Product BR)                                               |
| `ice_levels`   | ✗        | salah satu dari `product.attributes.ice_levels`           | `normal` (hanya relevan jika `temperature = iced`)       |

> **Catatan:** `ice_levels` hanya divalidasi jika `temperature = iced`. Jika `temperature = hot`, field `ice_levels` diabaikan meskipun dikirim.

**Food & Snack:**

| Field          | Required | Nilai Valid                                               | Default jika tidak dikirim |
|----------------|:--------:|-----------------------------------------------------------|----------------------------|
| `portions`     | **✓**    | salah satu dari `product.attributes.portions`             | — (wajib diisi)            |
| `spicy_levels` | ✗        | salah satu dari `product.attributes.spicy_levels`         | `no_spicy`                     |

**Aturan validasi atribut:**
- Nilai yang dikirim harus ada dalam array atribut yang tersedia di `product.attributes` — bukan sekadar enum global. Misal: jika produk hanya menawarkan `["hot"]` untuk `temperature`, maka mengirim `"iced"` harus ditolak.
- Field atribut yang tidak relevan untuk kategori produk (misal: mengirim `temperature` untuk produk Food) diabaikan — tidak error.
- Harga tidak dipengaruhi oleh pilihan atribut — semua varian atribut memiliki harga yang sama sesuai `price` di tabel `products`.

### Sumber Nilai Opsi (Source of Truth)

Semua nilai valid untuk atribut checkout harus berasal dari `products.attributes` pada saat request checkout diproses.

- Product mendefinisikan daftar opsi yang tersedia.
- Frontend mengirim pilihan final Customer pada payload `items[].attributes`.
- Order Service memvalidasi nilai yang dikirim terhadap `products.attributes` terkini (bukan terhadap enum hardcoded semata).

---

## 4. Business Rules per Operasi

### 4.1 POST /orders/checkout — Buat Order (Checkout)

**Deskripsi:** Memvalidasi item-item dari cart yang dipilih Customer beserta atributnya, membuat record order beserta snapshot harga dan atribut, dan mengurangi stok produk terkait.

**Pre-conditions:**
- Request terautentikasi dengan role `Customer`.
- `is_active = true` di `public.users`.
- `is_verified = true` di `public.users` — user wajib sudah verifikasi email.
- `phone_number` tidak null/kosong di `public.users` — user wajib sudah mengisi nomor telepon.

**Happy Path:**
1. Validasi autentikasi, role Customer, `is_active`, `is_verified`, dan `phone_number`.
2. Validasi format payload: `items` tidak boleh kosong, setiap `cart_item_id` harus UUID valid.
3. Ambil semua `cart_items` berdasarkan `cart_item_id` yang dikirim. Pastikan semua exist dan `cart.user_id` cocok dengan `user_id` dari JWT.
4. Untuk setiap item, join ke tabel `products` dan validasi:
   - Product tidak soft-deleted (`deleted_at IS NULL`).
   - Product `status = available`.
   - Stok mencukupi (`stock >= quantity` yang dipesan).
5. Validasi `attributes` setiap item sesuai kategori produk (lihat Section 3):
   - Field wajib harus ada dan nilainya valid sesuai `product.attributes`.
   - Field opsional yang tidak dikirim diisi dengan nilai default.
6. Jika semua validasi lolos, dalam satu DB transaction:
   a. Buat record `order` baru dengan status `PENDING`.
   b. Generate `order_number` dengan format `ORD-YYYYMMDD-XXX` (sequential per hari, dijelaskan di Section 8).
   c. Set `expires_at = created_at + 15 menit`.
   d. Buat record `order_items` untuk setiap item, simpan snapshot: `product_id`, `product_name`, `price_at_checkout`, `quantity`, `subtotal`, dan `selected_attributes` (atribut final setelah default diterapkan).
   e. Kurangi stok (`stock`) di tabel `products` untuk setiap item sesuai quantity — gunakan pessimistic locking (`SELECT ... FOR UPDATE`).
   f. Hitung dan simpan `total_amount` di record `order` (sum dari semua `subtotal` order_items).
7. Return detail order yang baru dibuat.

**Sad Path & Edge Cases:**

| Kondisi                                                  | Behavior Sistem                                                    | HTTP Status |
|----------------------------------------------------------|--------------------------------------------------------------------|-------------|
| Role bukan Customer                                      | Return `FORBIDDEN`                                                 | 403         |
| `is_active = false`                                      | Return `ACCOUNT_DISABLED`                                          | 403         |
| `is_verified = false`                                    | Return `EMAIL_UNVERIFIED`                                          | 403         |
| `phone_number` kosong / null                             | Return `PHONE_NUMBER_REQUIRED`                                     | 403         |
| `items` kosong atau tidak dikirim                        | Return `VALIDATION_ERROR`                                          | 400         |
| Salah satu `cart_item_id` format bukan UUID              | Return `VALIDATION_ERROR`                                          | 400         |
| Field atribut wajib tidak dikirim                        | Return `VALIDATION_ERROR` beserta field yang kurang                | 400         |
| Nilai atribut tidak tersedia di `product.attributes`     | Return `VALIDATION_ERROR` beserta detail atribut yang tidak valid  | 400         |
| Salah satu `cart_item_id` tidak ditemukan / bukan milik user | Return `CART_ITEM_NOT_FOUND`                                   | 404         |
| Salah satu product soft-deleted                          | Return `PRODUCT_NOT_FOUND`                                         | 404         |
| Salah satu product `status = unavailable`                | Return `PRODUCT_UNAVAILABLE` beserta `product_id` terkait         | 422         |
| Salah satu product `status = out_of_stock`               | Return `PRODUCT_OUT_OF_STOCK` beserta `product_id` terkait        | 422         |
| Stok tidak mencukupi untuk salah satu item               | Return `INSUFFICIENT_STOCK` beserta `product_id` terkait          | 422         |
| Race condition stok (dua user checkout bersamaan)        | Pessimistic lock memastikan hanya satu yang lolos; yang kalah mendapat `INSUFFICIENT_STOCK` | 422 |
| DB error                                                 | Rollback transaction, log error                                    | 500         |

**Post-conditions:**
- Record `order` baru tersimpan di DB dengan status `PENDING` dan `expires_at` 15 menit dari waktu dibuat.
- Record `order_items` tersimpan dengan snapshot harga, atribut final, dan detail produk.
- Stok produk terkait berkurang sesuai quantity yang dipesan.
- Cart item yang di-checkout **tidak** langsung dihapus — cart di-clear setelah payment sukses.

---

### 4.2 GET /orders — List Order / Antrian

**Deskripsi:** Mengambil daftar order milik Customer yang sedang login. Untuk Pegawai dan Admin, mengambil semua order sebagai antrian operasional.

**Pre-conditions:**
- Request terautentikasi dengan role `Customer`, `Pegawai`, atau `Admin`.
- `is_active = true` di `public.users`.

**Query Parameters:**

| Parameter   | Tipe   | Required | Deskripsi                                                                      |
|-------------|--------|----------|--------------------------------------------------------------------------------|
| `cursor`    | string | ✗        | Cursor untuk navigasi (opaque base64) — mengikuti pola pagination Product BR   |
| `direction` | enum   | ✗        | `next` atau `prev`; default: `next`                                            |
| `limit`     | int    | ✗        | Jumlah item per halaman; default: 10; max: 50                                  |
| `status`    | enum   | ✗        | Filter: `PENDING`, `CONFIRMED`, `COMPLETED`, `CANCELLED`                       |
| `user_id`   | UUID   | ✗        | **Hanya Admin** — filter order milik user tertentu                             |

**Happy Path:**
1. Validasi autentikasi dan role.
2. Jika Customer: filter otomatis `order.user_id = user_id dari JWT`. Parameter `user_id` diabaikan.
3. Jika Pegawai: query semua order. Parameter `user_id` diabaikan.
4. Jika Admin: query semua order, bisa filter by `user_id` jika dikirim.
5. Terapkan filter `status` jika ada.
6. Terapkan cursor-based pagination.
7. Return list order beserta summary dan informasi pagination.

**Sad Path & Edge Cases:**

| Kondisi                                  | Behavior Sistem                                    | HTTP Status |
|------------------------------------------|----------------------------------------------------|-------------|
| Role tidak memiliki akses                | Return `FORBIDDEN`                                 | 403         |
| `is_active = false`                      | Return `ACCOUNT_DISABLED`                          | 403         |
| `status` value tidak valid               | Return `VALIDATION_ERROR`                          | 400         |
| `user_id` dikirim oleh Customer/Pegawai  | Parameter diabaikan                                | 200         |
| `cursor` tidak valid                     | Return `INVALID_CURSOR`                            | 400         |
| Tidak ada order                          | Return array kosong                                | 200         |
| DB error                                 | Log error, return error                            | 500         |

**Post-conditions:** Tidak ada perubahan state.

---

### 4.3 GET /orders/:order_id — Detail Order

**Deskripsi:** Mengambil detail satu order beserta seluruh `order_items`-nya termasuk `selected_attributes`.

**Pre-conditions:**
- Request terautentikasi dengan role `Customer`, `Pegawai`, atau `Admin`.
- `is_active = true` di `public.users`.

**Happy Path:**
1. Validasi autentikasi dan role.
2. Validasi format `order_id` (UUID).
3. Ambil record `order` dari DB.
4. Jika Customer: pastikan `order.user_id` cocok dengan `user_id` dari JWT.
5. Jika Pegawai atau Admin: tidak ada pembatasan ownership.
6. Return detail order beserta seluruh `order_items` (menggunakan data snapshot, bukan join real-time ke `products`).

**Sad Path & Edge Cases:**

| Kondisi                                  | Behavior Sistem                                                             | HTTP Status |
|------------------------------------------|-----------------------------------------------------------------------------|-------------|
| Role tidak memiliki akses                | Return `FORBIDDEN`                                                          | 403         |
| `is_active = false`                      | Return `ACCOUNT_DISABLED`                                                   | 403         |
| Format `order_id` bukan UUID             | Return `VALIDATION_ERROR`                                                   | 400         |
| Order tidak ditemukan                    | Return `ORDER_NOT_FOUND`                                                    | 404         |
| Order milik user lain (Customer)         | Return `ORDER_NOT_FOUND` (jangan bocorkan eksistensi order milik user lain) | 404         |
| DB error                                 | Log error, return error                                                     | 500         |

**Post-conditions:** Tidak ada perubahan state.

---

### 4.4 PATCH /orders/:order_id/cancel — Cancel Order

**Deskripsi:** Membatalkan order yang masih berstatus `PENDING`. Stok produk dikembalikan.

**Pre-conditions:**
- Request terautentikasi dengan role `Customer` atau `Admin`.
- `is_active = true` di `public.users`.
- Order berstatus `PENDING`.

**Happy Path:**
1. Validasi autentikasi dan role.
2. Validasi format `order_id` (UUID).
3. Ambil record `order` dari DB.
4. Jika Customer: pastikan `order.user_id` cocok dengan `user_id` dari JWT.
5. Pastikan status order adalah `PENDING`. Jika bukan, tolak.
6. Dalam satu DB transaction:
   a. Update status order menjadi `CANCELLED`.
   b. Kembalikan stok (`stock`) di tabel `products` untuk setiap `order_item` sesuai quantity — gunakan pessimistic locking.
7. Return order yang sudah di-cancel.

**Sad Path & Edge Cases:**

| Kondisi                                      | Behavior Sistem                 | HTTP Status |
|----------------------------------------------|---------------------------------|-------------|
| Role bukan Customer atau Admin               | Return `FORBIDDEN`              | 403         |
| `is_active = false`                          | Return `ACCOUNT_DISABLED`       | 403         |
| Format `order_id` bukan UUID                 | Return `VALIDATION_ERROR`       | 400         |
| Order tidak ditemukan                        | Return `ORDER_NOT_FOUND`        | 404         |
| Order milik user lain (Customer)             | Return `ORDER_NOT_FOUND`        | 404         |
| Order berstatus `CONFIRMED` atau `COMPLETED` | Return `ORDER_NOT_CANCELLABLE`  | 422         |
| Order sudah berstatus `CANCELLED`            | Return `ORDER_ALREADY_CANCELLED`| 422         |
| DB error                                     | Rollback transaction, log error | 500         |

**Post-conditions:**
- Status order berubah menjadi `CANCELLED`.
- Stok produk terkait dikembalikan sesuai quantity order.
- Cart item yang sebelumnya di-checkout **tidak** dikembalikan ke cart secara otomatis — user perlu add to cart manual jika ingin order ulang.

---

### 4.5 PATCH /orders/:order_id/status — Update Status Order (Pegawai & Admin)

**Deskripsi:** Pegawai atau Admin mengubah status order secara manual. Transisi yang diizinkan berbeda per role — lihat tabel di bawah.

**Pre-conditions:**
- Request terautentikasi dengan role `Pegawai` atau `Admin`.
- `is_active = true` di `public.users`.

**Happy Path:**
1. Validasi autentikasi dan role (`Pegawai` atau `Admin`).
2. Validasi format `order_id` (UUID).
3. Validasi field `status` yang dikirim — harus salah satu dari enum yang valid.
4. Ambil record `order` dari DB.
5. Validasi transisi status berdasarkan role dan status saat ini (lihat tabel di bawah).
6. Update status order di DB.
7. Return order yang sudah di-update.

**Transisi Status yang Diizinkan per Role:**

| Status Saat Ini | Status Tujuan | Pegawai | Admin |
|-----------------|---------------|:-------:|:-----:|
| `PENDING`       | `CONFIRMED`   | ✗       | ✓     |
| `CONFIRMED`     | `COMPLETED`   | ✓       | ✓     |
| `PENDING`       | `COMPLETED`   | ✗       | ✗     |
| `CANCELLED`     | (apapun)      | ✗       | ✗     |
| `COMPLETED`     | (apapun)      | ✗       | ✗     |

**Sad Path & Edge Cases:**

| Kondisi                                               | Behavior Sistem                    | HTTP Status |
|-------------------------------------------------------|------------------------------------|-------------|
| Role bukan Pegawai atau Admin                         | Return `FORBIDDEN`                 | 403         |
| `is_active = false`                                   | Return `ACCOUNT_DISABLED`          | 403         |
| Pegawai mencoba transisi selain `CONFIRMED→COMPLETED` | Return `FORBIDDEN`                 | 403         |
| Format `order_id` bukan UUID                          | Return `VALIDATION_ERROR`          | 400         |
| Field `status` tidak valid / tidak dikirim            | Return `VALIDATION_ERROR`          | 400         |
| Order tidak ditemukan                                 | Return `ORDER_NOT_FOUND`           | 404         |
| Transisi status tidak diizinkan                       | Return `INVALID_STATUS_TRANSITION` | 422         |
| DB error                                              | Rollback transaction, log error    | 500         |

**Post-conditions:**
- Status order ter-update di DB.
- Jika status berubah menjadi `COMPLETED`: kolom `total_sold` di tabel `products` di-update secara async untuk setiap produk dalam `order_items`.

---

### 4.6 PATCH /internal/orders/:order_id/status — Update Status (Internal, dipanggil Payment Service)

**Deskripsi:** Payment Service mengubah status order setelah payment sukses (`PENDING → CONFIRMED`). Endpoint ini tidak diekspos ke publik.

**Pre-conditions:**
- Request berasal dari Payment Service dengan header `X-Internal-Api-Key` yang valid.
- Order berstatus `PENDING`.

**Happy Path:**
1. Validasi header `X-Internal-Api-Key`.
2. Validasi format `order_id` (UUID).
3. Ambil record `order`, pastikan status `PENDING`.
4. Dalam satu DB transaction:
   a. Update status order menjadi `CONFIRMED`.
5. Setelah commit, panggil Cart Service (`DELETE /internal/cart/items`) secara sync dengan daftar `cart_item_id` dari `order_items` terkait untuk clear cart.
6. Return 200 sukses ke Payment Service.

**Sad Path & Edge Cases:**

| Kondisi                                              | Behavior Sistem                                                                                        | HTTP Status |
|------------------------------------------------------|--------------------------------------------------------------------------------------------------------|-------------|
| Header `X-Internal-Api-Key` tidak valid / tidak ada  | Return `UNAUTHORIZED`                                                                                  | 401         |
| Format `order_id` bukan UUID                         | Return `VALIDATION_ERROR`                                                                              | 400         |
| Order tidak ditemukan                                | Return `ORDER_NOT_FOUND`                                                                               | 404         |
| Order bukan berstatus `PENDING`                      | Return `INVALID_STATUS_TRANSITION`                                                                     | 422         |
| DB error saat update status                          | Rollback transaction, log error                                                                        | 500         |
| Cart Service gagal clear cart                        | Log error (level: ERROR); status order tetap `CONFIRMED` — tidak di-rollback. Retry ditangani terpisah.| 500         |

**Post-conditions:**
- Status order berubah menjadi `CONFIRMED`.
- Cart Service dipanggil untuk menghapus item yang sudah dibayar dari cart Customer.

**Catatan implementasi (fase coding):**
- Setelah status order berubah `PENDING -> CONFIRMED`, proses clear cart ke Cart Service wajib memiliki mekanisme retry terkontrol (mis. retry job/outbox) untuk mencapai eventual consistency.
- Daftar `item_ids` yang dikirim ke Cart Service harus berasal dari `order_items.cart_item_id` milik order terkait (bukan input bebas).
- Jika clear cart gagal, status order tetap `CONFIRMED` (tidak di-rollback), namun kegagalan wajib di-log dan dijadwalkan retry.

---

### 4.7 System: Auto-Cancel Order PENDING yang Expired

**Deskripsi:** Scheduled job yang berjalan secara periodik untuk membatalkan order berstatus `PENDING` yang sudah melewati `expires_at` (15 menit sejak dibuat). Stok produk dikembalikan secara otomatis.

**Trigger:** Scheduled job — dijalankan setiap 1 menit.

**Happy Path:**
1. Query semua order dengan status `PENDING` dan `expires_at <= NOW()`.
2. Untuk setiap order yang ditemukan, dalam satu DB transaction:
   a. Update status order menjadi `CANCELLED`.
   b. Kembalikan stok (`stock`) di tabel `products` untuk setiap `order_item` sesuai quantity — gunakan pessimistic locking.
3. Log setiap order yang di-cancel beserta `order_id` dan alasan (`EXPIRED`).

**Sad Path & Edge Cases:**

| Kondisi                                               | Behavior Sistem                                                                             |
|-------------------------------------------------------|---------------------------------------------------------------------------------------------|
| Tidak ada order expired                               | Job selesai tanpa aksi, tidak perlu di-log                                                  |
| DB error pada satu order                              | Rollback transaction untuk order tersebut; lanjutkan ke order berikutnya; log error         |
| Job berjalan overlap (sebelum job sebelumnya selesai) | Gunakan distributed lock atau idempotency check untuk mencegah double-cancel                |

**Post-conditions:**
- Semua order `PENDING` yang melewati `expires_at` berubah menjadi `CANCELLED`.
- Stok produk terkait dikembalikan.

---

## 5. Caching Policy

Tidak ada caching untuk modul Order.

**Alasan:**
- Data order bersifat highly personal dan sensitif terhadap perubahan status real-time.
- Volume read per user relatif kecil — tidak ada bottleneck signifikan tanpa cache.
- Risiko stale data (terutama untuk status order dan `expires_at`) lebih besar dibanding manfaat caching.

---

## 6. External Service & Side Effects

| Trigger                                       | Service / Action                                                                       | Sync/Async                        |
|-----------------------------------------------|----------------------------------------------------------------------------------------|-----------------------------------|
| Checkout berhasil (order `PENDING`)           | Kurangi stok produk di tabel `products`                                                | Sync (dalam transaction checkout) |
| Payment sukses → order `CONFIRMED`            | Order Service memanggil `DELETE /internal/cart/items` ke Cart Service                 | Sync (setelah DB commit)          |
| Order `COMPLETED`                             | Update kolom `total_sold` di tabel `products` untuk setiap produk dalam order         | Async                             |
| Order `CANCELLED` (manual atau auto-expired)  | Kembalikan stok produk di tabel `products` untuk setiap item dalam order              | Sync (dalam transaction cancel)   |

**Catatan:**
- Pengurangan dan pengembalian stok dilakukan di dalam DB transaction yang sama dengan perubahan status order — jika salah satu gagal, keduanya di-rollback.
- Update `total_sold` dilakukan async karena tidak mempengaruhi response ke user dan tidak kritis terhadap konsistensi transaksi.
- Clear cart ke Cart Service dilakukan setelah DB commit order `CONFIRMED` — jika Cart Service gagal, status order tidak di-rollback. Error dicatat di log dan perlu retry mechanism terpisah.

---

## 7. Response Format

Mengikuti format standar yang sudah didefinisikan di Product BR (`success`, `data`, `message`).

### Success — Detail Order & Operasi yang Return Order
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
      },
      {
        "order_item_id": "uuid",
        "product_id": "uuid",
        "product_name": "Croissant",
        "price_at_checkout": 18000,
        "quantity": 1,
        "subtotal": 18000,
        "selected_attributes": {
          "portions": "regular",
          "spicy_levels": "mild"
        }
      }
    ],
    "created_at": "2025-04-05T10:00:00Z",
    "updated_at": "2025-04-05T10:00:00Z"
  },
  "message": "Order berhasil dibuat"
}
```

> **Catatan:** `expires_at` hanya relevan saat status `PENDING`. Untuk status lain, field ini bisa `null` atau dihilangkan dari response.

### Success — List Order (dengan Pagination)
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

### Daftar Error Code

| Code                        | HTTP Status | Trigger                                                                            |
|-----------------------------|:-----------:|------------------------------------------------------------------------------------|
| `VALIDATION_ERROR`          | 400         | Format field tidak valid, `items` kosong, atribut wajib tidak dikirim, dsb         |
| `INVALID_CURSOR`            | 400         | Cursor pagination tidak valid                                                      |
| `UNAUTHORIZED`              | 401         | Token tidak ada, tidak valid, atau (khusus internal) service token invalid         |
| `FORBIDDEN`                 | 403         | Role tidak memiliki izin untuk operasi ini                                         |
| `ACCOUNT_DISABLED`          | 403         | `is_active = false` di `public.users`                                              |
| `EMAIL_UNVERIFIED`          | 403         | Customer belum verifikasi email                                                    |
| `PHONE_NUMBER_REQUIRED`     | 403         | Customer belum mengisi `phone_number`                                              |
| `CART_ITEM_NOT_FOUND`       | 404         | `cart_item_id` tidak exist atau bukan milik user yang login                        |
| `PRODUCT_NOT_FOUND`         | 404         | Produk dalam cart sudah soft-deleted                                               |
| `ORDER_NOT_FOUND`           | 404         | Order tidak ditemukan atau bukan milik user yang login (untuk Customer)            |
| `PRODUCT_UNAVAILABLE`       | 422         | Salah satu produk berstatus `unavailable` saat checkout                            |
| `PRODUCT_OUT_OF_STOCK`      | 422         | Salah satu produk berstatus `out_of_stock` saat checkout                           |
| `INSUFFICIENT_STOCK`        | 422         | Stok produk tidak mencukupi untuk quantity yang dipesan                            |
| `ORDER_NOT_CANCELLABLE`     | 422         | Order tidak bisa dibatalkan karena statusnya bukan `PENDING`                       |
| `ORDER_ALREADY_CANCELLED`   | 422         | Order sudah berstatus `CANCELLED`                                                  |
| `INVALID_STATUS_TRANSITION` | 422         | Transisi status order tidak diizinkan                                              |
| `INTERNAL_SERVER_ERROR`     | 500         | Error tidak terduga di server                                                      |

---

## 8. Database & Transaction Policy

- **Transaction scope:** Semua operasi mutasi (checkout, cancel, update status, auto-cancel) wajib menggunakan DB transaction.
- **Soft delete atau hard delete:** Tidak ada delete pada modul ini. Order bersifat append-only — status diubah, record tidak dihapus. Ini menjaga integritas historis transaksi.
- **Kolom audit:** `created_at`, `updated_at` pada tabel `orders` dan `order_items`.
- **Locking strategy:** Gunakan **pessimistic locking** (`SELECT ... FOR UPDATE`) pada baris `products` saat checkout dan cancel untuk mencegah race condition pada update stok. Ini penting karena dua Customer bisa checkout produk yang sama secara bersamaan.

### Generate Order Number

Format: `ORD-YYYYMMDD-XXX`

- `YYYYMMDD` adalah tanggal order dibuat (timezone WIB / UTC+7).
- `XXX` adalah nomor urut 3 digit, reset ke `001` setiap hari baru.
- Contoh: `ORD-20250405-001`, `ORD-20250405-002`, dst.
- Implementasi: gunakan DB sequence per hari atau query `COUNT(*) + 1` dari orders pada tanggal yang sama di dalam satu transaction — pastikan atomic untuk menghindari duplikasi.
- Jika volume order melebihi 999 dalam satu hari, format menyesuaikan digit (misal: `ORD-20250405-1000`).

### Desain Tabel (Referensi)

**Tabel `orders`:**

| Kolom          | Tipe        | Keterangan                                                                 |
|----------------|-------------|----------------------------------------------------------------------------|
| `id`           | UUID        | Primary key                                                                |
| `order_number` | VARCHAR(30) | Format `ORD-YYYYMMDD-XXX`; unik                                           |
| `user_id`      | UUID        | Foreign key ke `public.users`                                              |
| `status`       | ENUM        | `PENDING`, `CONFIRMED`, `COMPLETED`, `CANCELLED`                          |
| `notes`        | TEXT        | Nullable; catatan dari Customer                                            |
| `total_amount` | INTEGER     | Total harga dalam Rupiah; snapshot saat checkout                           |
| `expires_at`   | TIMESTAMPTZ | Waktu expiry order PENDING; `created_at + 15 menit`; null setelah tidak PENDING |
| `created_at`   | TIMESTAMPTZ | Auto set                                                                   |
| `updated_at`   | TIMESTAMPTZ | Auto update setiap ada perubahan status                                    |

**Tabel `order_items`:**

| Kolom                 | Tipe         | Keterangan                                                                           |
|-----------------------|--------------|--------------------------------------------------------------------------------------|
| `id`                  | UUID         | Primary key                                                                          |
| `order_id`            | UUID         | Foreign key ke `orders`                                                              |
| `product_id`          | UUID         | Foreign key ke `products` (soft reference — produk bisa dihapus, order tetap valid) |
| `cart_item_id`        | UUID         | Referensi ke `cart_items`; digunakan untuk trigger clear cart setelah payment sukses |
| `product_name`        | VARCHAR(100) | Snapshot nama produk saat checkout                                                   |
| `price_at_checkout`   | INTEGER      | Snapshot harga produk saat checkout (Rupiah)                                         |
| `quantity`            | INTEGER      | Jumlah yang dipesan                                                                  |
| `subtotal`            | INTEGER      | `price_at_checkout × quantity`                                                       |
| `selected_attributes` | JSONB        | Snapshot atribut final yang dipilih Customer (termasuk default yang diterapkan)      |
| `created_at`          | TIMESTAMPTZ  | Auto set                                                                             |

> **Catatan desain `cart_item_id`:** Disimpan di `order_items` agar Order Service bisa memanggil Cart Service dengan daftar `item_id` yang tepat saat clear cart setelah payment sukses — tanpa perlu Cart Service melakukan query balik ke Order.

> **Catatan desain `selected_attributes`:** Menyimpan atribut final setelah default diterapkan (bukan raw input dari user). Ini memastikan data yang tersimpan selalu lengkap dan konsisten, terlepas dari apakah user mengisi atribut opsional atau tidak.

---

## 9. Logging & Monitoring

**Yang wajib di-log:**
- Setiap operasi checkout beserta `user_id`, `order_id`, `order_number`, dan daftar `product_id` yang di-checkout (level: INFO)
- Setiap perubahan status order beserta `actor` (Customer, Pegawai, Admin, atau Payment Service), `order_id`, `status_lama`, dan `status_baru` (level: INFO)
- Setiap operasi cancel (manual maupun auto-expired) beserta `user_id`/`system`, `order_id`, dan alasan cancel (level: INFO)
- Race condition stok yang menyebabkan `INSUFFICIENT_STOCK` (level: WARNING)
- Kegagalan clear cart ke Cart Service setelah payment sukses (level: ERROR)
- Kegagalan update `total_sold` async (level: ERROR)
- Akses yang ditolak karena role tidak sesuai atau autentikasi internal gagal (level: WARNING)
- Error 500 dengan full stack trace (level: ERROR)

**Yang tidak perlu di-log:**
- GET order history atau detail yang sukses
- Scheduler berjalan tanpa menemukan order expired
- Panggilan internal yang idempotent dan sukses

---

## 10. Open Questions

- [x] **Apakah ada atribut produk yang perlu dipilih saat checkout?** → **Resolved:** Ya, per order item. Field wajib/opsional tergantung kategori produk dan ketersediaan default — lihat Section 3.
- [x] **Apakah ada batas waktu order PENDING?** → **Resolved:** Ya, 15 menit. Order yang tidak dibayar dalam 15 menit otomatis `CANCELLED` oleh scheduler dan stok dikembalikan — lihat Section 4.7.
- [x] **Apakah partial checkout diizinkan?** → **Resolved:** Ya. Customer mengirim `items` berisi `cart_item_id` yang dipilih — tidak harus semua item di cart.
- [x] **Format `order_number` untuk volume tinggi?** → **Resolved:** Format 3 digit untuk sekarang; otomatis menyesuaikan digit jika melebihi 999 dalam satu hari.
- [x] **Apakah Pegawai perlu akses ke order?** → **Resolved:** Ya. Pegawai bisa lihat list semua order (antrian), lihat detail order, dan update status `CONFIRMED → COMPLETED`.
