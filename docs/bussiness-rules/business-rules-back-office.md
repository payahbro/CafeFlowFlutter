# Business Rules: Back Office

Dokumen ini mendefinisikan aturan bisnis untuk modul **Back Office** pada sistem **Backend Service Cafe**.

> **Catatan Penamaan:** Modul ini disebut "Back Office" (bukan "Admin Panel" atau "Reporting") karena merangkum seluruh operasional internal cafe — manajemen order, produk, user, dan laporan — dalam satu modul yang kohesif.

---

## 1. Overview & Scope

- **Deskripsi singkat fitur:** Menyediakan antarmuka operasional internal untuk Admin dan Pegawai dalam mengelola order harian, produk, data customer, serta melihat laporan bisnis dasar.
- **Actor yang terlibat:**
  - `Pegawai` — akses terbatas: lihat dan update status order, dan lihat summary dashboard operasional harian
  - `Admin` — akses penuh ke semua sub-fitur Back Office
- **Fitur/modul yang dependen:**
  - **Order** — data order dibaca dan statusnya diubah dari sini
  - **Product** — CRUD produk dilakukan dari sini oleh Admin
  - **User** — data Customer dibaca (read-only) dari sini
  - **Payment** — data payment dibaca untuk keperluan reporting
- **Out of scope:**
  - Manajemen akun Pegawai dan Admin — dilakukan langsung via Supabase Dashboard (sesuai keputusan arsitektur di User BR)
  - Notifikasi real-time ke Pegawai (WebSocket/push notification)
  - Export grafik/chart — tabel saja untuk saat ini
  - Rekonsiliasi keuangan manual
  - Akses ke data payment (refund, detail pembayaran) dari Back Office — ini tetap di modul Payment

---

## 2. Authorization & Access Control

> **Catatan Auth:** Tidak ada endpoint login terpisah untuk Back Office. Login menggunakan flow Supabase `signInWithPassword` yang sama dengan sistem utama. Frontend mengecek `role` dari JWT dan melakukan redirect ke halaman Back Office jika role adalah `Pegawai` atau `Admin`. Middleware Golang tetap memvalidasi role dan `is_active` di setiap request.

### Matriks Akses

#### Order Management

| Operasi                                          | Pegawai | Admin |
|--------------------------------------------------|:-------:|:-----:|
| GET list semua order                             | ✓       | ✓     |
| GET detail order                                 | ✓       | ✓     |
| PATCH update status `CONFIRMED → COMPLETED`      | ✓       | ✓     |
| PATCH update status (semua transisi yang valid)  | ✗       | ✓     |
| PATCH cancel order                               | ✗       | ✓     |

#### Product Management

| Operasi                  | Pegawai | Admin |
|--------------------------|:-------:|:-----:|
| GET list produk          | ✓       | ✓     |
| GET detail produk        | ✓       | ✓     |
| POST create produk       | ✗       | ✓     |
| PUT update produk (full) | ✗       | ✓     |
| PATCH update status      | ✓       | ✓     |
| DELETE produk (soft)     | ✗       | ✓     |
| PATCH restore produk     | ✗       | ✓     |

#### User/Customer Management

| Operasi                  | Pegawai | Admin |
|--------------------------|:-------:|:-----:|
| GET list customer        | ✗       | ✓     |
| GET detail customer      | ✗       | ✓     |

#### Reporting

| Operasi                        | Pegawai | Admin |
|--------------------------------|:-------:|:-----:|
| GET summary dashboard (versi terbatas) | ✓  | ✓     |
| GET laporan periodik           | ✗       | ✓     |
| GET laporan per produk         | ✗       | ✓     |
| GET export CSV/PDF             | ✗       | ✓     |

**Catatan Authorization:**
- Semua endpoint Back Office wajib melewati middleware Golang yang mengecek `is_active` di `public.users` — sesuai arsitektur di User BR.
- Pegawai yang mencoba mengakses endpoint di luar haknya mendapat HTTP 403 `FORBIDDEN`.
- Endpoint Order Management di Back Office adalah **endpoint yang sama** dengan modul Order (`/api/v1/orders/...`) — tidak ada endpoint duplikat. Pembedaan akses dikendalikan oleh middleware role.
- Endpoint Product Management di Back Office adalah **endpoint yang sama** dengan modul Product (`/api/v1/products/...`).

---

## 3. Validation Rules

> Sebagian besar validasi di sub-fitur ini sudah didefinisikan di BR masing-masing modul (Order, Product). Section ini hanya mendokumentasikan validasi yang **baru** atau **spesifik** untuk Back Office.

### Reporting — Filter Parameter

| Parameter    | Tipe   | Required | Constraint                                                              |
|--------------|--------|----------|-------------------------------------------------------------------------|
| `date_from`  | string | ✗        | Format ISO 8601 (`YYYY-MM-DD`); tidak boleh lebih besar dari `date_to` |
| `date_to`    | string | ✗        | Format ISO 8601 (`YYYY-MM-DD`); tidak boleh lebih kecil dari `date_from` |
| `group_by`   | string | ✗        | Nilai valid: `day`, `week`, `month`; default: `day`                    |

**Catatan khusus:**
- Jika `date_from` dan `date_to` tidak dikirim, default menampilkan data 30 hari terakhir.
- Jika hanya salah satu dikirim, endpoint mengembalikan `VALIDATION_ERROR`.
- Range maksimal antara `date_from` dan `date_to` adalah 1 tahun (365 hari). Lebih dari itu ditolak dengan `DATE_RANGE_TOO_LARGE`.

### User/Customer Management — Filter Parameter (GET list)

| Parameter  | Tipe   | Required | Constraint                                         |
|------------|--------|----------|----------------------------------------------------|
| `search`   | string | ✗        | Pencarian berdasarkan `full_name` atau `email`     |
| `is_active`| boolean| ✗        | Filter berdasarkan status aktif; default: semua    |
| `cursor`   | string | ✗        | Cursor pagination (lihat pola di BR Order)         |
| `limit`    | integer| ✗        | Default 20, max 100                                |

---

## 4. Business Rules per Operasi

### 4.1 Order Management

> **Cross-reference:** Semua business rules operasional order (checkout, update status, cancel, dll) sudah didefinisikan lengkap di **Business Rules: Order**. Section ini hanya mendokumentasikan rules tambahan yang relevan dari perspektif Back Office (antrian kasir/barista).

**Deskripsi:** Pegawai dan Admin melihat dan mengelola antrian order masuk secara real-time dari halaman Back Office.

**Pre-conditions:**
- Request terautentikasi dengan role `Pegawai` atau `Admin`.
- `is_active = true` di `public.users`.

**Rules khusus dari perspektif Back Office:**

- **GET list order (antrian):** Pegawai dan Admin melihat **semua** order tanpa filter kepemilikan. Default sort: `created_at DESC`. Direkomendasikan filter tambahan: `status` (misal: hanya tampilkan `CONFIRMED` untuk antrian aktif).
- **Update status `CONFIRMED → COMPLETED`:** Ini adalah aksi utama Pegawai — menandai bahwa pesanan sudah selesai dibuat dan diserahkan ke Customer. Rules transisi status lengkap ada di BR Order Section 4.
- **Cancel order oleh Admin:** Admin bisa cancel order di status apapun yang masih bisa dibatalkan — rules lengkap ada di BR Order.

**Sad Path tambahan (perspektif Back Office):**

| Kondisi                                        | Behavior Sistem                    | HTTP Status |
|------------------------------------------------|------------------------------------|-------------|
| Pegawai mencoba update status selain `CONFIRMED → COMPLETED` | Return `FORBIDDEN`  | 403         |
| Pegawai mencoba cancel order                   | Return `FORBIDDEN`                 | 403         |

---

### 4.2 Product Management

> **Cross-reference:** Semua business rules CRUD produk sudah didefinisikan lengkap di **Business Rules: Product**. Section ini hanya mendokumentasikan konteks penggunaannya dari Back Office.

**Deskripsi:** Admin mengelola produk cafe (CRUD, perubahan status, restore) dari halaman Back Office. Pegawai bisa update status produk (misal: tandai `out_of_stock` saat stok habis).

**Rules penting yang perlu diingat (dari BR Product):**
- Produk dibagi 3 kategori: `COFFEE`, `SNACK`, `FOOD`. Setiap kategori punya atribut berbeda.
- Delete produk adalah **soft delete** — produk tidak hilang dari DB, hanya tidak tampil ke Customer.
- Pegawai hanya bisa `PATCH update status` (misal: `available → out_of_stock`) — tidak bisa create, edit, atau delete.

---

### 4.3 User/Customer Management

**Deskripsi:** Admin melihat daftar Customer yang terdaftar di sistem beserta informasi dasarnya. Ini adalah fitur **read-only** — tidak ada operasi mutasi pada data Customer dari Back Office.

**Pre-conditions:**
- Request terautentikasi dengan role `Admin`.
- `is_active = true` di `public.users`.

**Happy Path — GET list customer:**
1. Admin mengirim request dengan filter opsional (`search`, `is_active`, `cursor`, `limit`).
2. Backend query tabel `public.users` dengan `role = 'Customer'`.
3. Hasil difilter sesuai parameter yang dikirim.
4. Return list customer dengan cursor pagination.

**Happy Path — GET detail customer:**
1. Admin mengirim request dengan `user_id`.
2. Backend query tabel `public.users` — pastikan `role = 'Customer'` (Admin tidak bisa lihat profil Pegawai/Admin lain via endpoint ini).
3. Return data profil customer.

**Data yang dikembalikan (per customer):**

| Field           | Keterangan                                      |
|-----------------|-------------------------------------------------|
| `id`            | UUID user                                       |
| `full_name`     | Nama lengkap                                    |
| `email`         | Email terdaftar                                 |
| `phone_number`  | Nomor telepon (nullable)                        |
| `is_active`     | Status aktif akun                               |
| `is_verified`   | Status verifikasi email                         |
| `created_at`    | Tanggal registrasi                              |

> **Catatan:** `avatar_url` tidak perlu dikembalikan di list — hanya di detail jika dibutuhkan.

**Sad Path & Edge Cases:**

| Kondisi                                      | Behavior Sistem                             | HTTP Status |
|----------------------------------------------|---------------------------------------------|-------------|
| `user_id` tidak ditemukan                    | Return `CUSTOMER_NOT_FOUND`                 | 404         |
| `user_id` ditemukan tapi bukan Customer      | Return `CUSTOMER_NOT_FOUND` (jangan expose bahwa ID valid tapi bukan customer) | 404 |
| Pegawai mencoba akses endpoint ini           | Return `FORBIDDEN`                          | 403         |

**Post-conditions:** Tidak ada — ini operasi read-only. Tidak ada perubahan state di DB.

---

### 4.4 Reporting — Summary Dashboard

**Deskripsi:** Admin dan Pegawai melihat ringkasan metrik bisnis. Admin melihat semua metrik lengkap; Pegawai hanya melihat subset metrik yang relevan untuk operasional harian (order hari ini saja).

**Pre-conditions:**
- Request terautentikasi dengan role `Admin` atau `Pegawai`.
- `is_active = true` di `public.users`.

**Endpoint:** `GET /api/v1/admin/reports/summary`

**Metrik yang ditampilkan:**

| Metrik                  | Sumber Data                                             | Keterangan                                           | Pegawai |
|-------------------------|---------------------------------------------------------|------------------------------------------------------|---------|
| Total order hari ini    | `orders` WHERE `created_at = today`                     | Count semua order hari ini                           | ✓       |
| Order aktif (CONFIRMED) | `orders` WHERE `status = 'CONFIRMED'`                   | Count order yang sedang diproses                     | ✓       |
| Total revenue           | `payments` WHERE `status = 'SUCCESS'`                   | Sum `amount` dalam periode; **Admin only**           | ✗       |
| Total order (periodik)  | `orders`                                                | Count semua order dalam periode; **Admin only**      | ✗       |
| Order berhasil          | `orders` WHERE `status = 'COMPLETED'`                   | Count order selesai dalam periode; **Admin only**    | ✗       |
| Order dibatalkan        | `orders` WHERE `status = 'CANCELLED'`                   | Count order cancelled dalam periode; **Admin only**  | ✗       |
| Produk terlaris         | `order_items` JOIN `orders` WHERE status `COMPLETED`    | Top 5 produk terjual; **Admin only**                 | ✗       |
| Total customer baru     | `public.users` WHERE `role = 'Customer'`                | Count registrasi dalam periode; **Admin only**       | ✗       |

**Happy Path:**
1. Admin atau Pegawai mengirim request ke endpoint yang sama.
2. Middleware mengidentifikasi role dari JWT.
3. **Jika Pegawai:** Backend hanya menghitung metrik yang bertanda ✓ di tabel atas (total order hari ini dan order aktif) — filter tanggal diabaikan, selalu hari ini.
4. **Jika Admin:** Backend menghitung semua metrik dengan filter `date_from`, `date_to` (opsional, default 30 hari terakhir).
5. Return summary dalam satu response.

**Sad Path & Edge Cases:**

| Kondisi                                     | Behavior Sistem                         | HTTP Status |
|---------------------------------------------|-----------------------------------------|-------------|
| Hanya salah satu dari `date_from`/`date_to` dikirim | Return `VALIDATION_ERROR`      | 400         |
| Range tanggal > 365 hari                    | Return `DATE_RANGE_TOO_LARGE`           | 400         |
| `date_from` > `date_to`                     | Return `VALIDATION_ERROR`               | 400         |
| Tidak ada data dalam range                  | Return summary dengan semua nilai 0 / array kosong — bukan 404 | 200 |

**Post-conditions:** Tidak ada — operasi read-only.

---

### 4.5 Reporting — Laporan Periodik (Tabel)

**Deskripsi:** Admin melihat data order dan revenue yang dikelompokkan berdasarkan periode waktu (harian/mingguan/bulanan) dalam bentuk tabel.

**Endpoint:** `GET /api/v1/admin/reports/orders`

**Data per baris tabel:**

| Kolom             | Keterangan                                                |
|-------------------|-----------------------------------------------------------|
| `period`          | Label periode (misal: `2025-04-10`, `2025-W15`, `2025-04`) |
| `total_orders`    | Jumlah order dalam periode                                |
| `completed_orders`| Jumlah order `COMPLETED`                                  |
| `cancelled_orders`| Jumlah order `CANCELLED`                                  |
| `total_revenue`   | Sum revenue dari payment `SUCCESS` dalam periode          |

**Happy Path:**
1. Admin mengirim request dengan `date_from`, `date_to`, `group_by` (opsional).
2. Backend query dan group data sesuai parameter.
3. Return array of rows diurutkan dari periode terbaru ke terlama.

**Sad Path:** Sama dengan Section 4.4.

---

### 4.6 Reporting — Laporan Per Produk

**Deskripsi:** Admin melihat performa penjualan per produk dalam bentuk tabel — berapa unit terjual dan berapa revenue yang dihasilkan setiap produk dalam periode tertentu.

**Endpoint:** `GET /api/v1/admin/reports/products`

**Query Parameters:** Sama dengan Section 4.5 (`date_from`, `date_to`) — `group_by` tidak berlaku di sini karena data dikelompokkan per produk, bukan per periode waktu.

**Data per baris tabel:**

| Kolom              | Keterangan                                                               |
|--------------------|--------------------------------------------------------------------------|
| `product_id`       | UUID produk                                                              |
| `product_name`     | Nama produk (snapshot dari `order_items.product_name`)                   |
| `category`         | Kategori produk (`COFFEE`, `SNACK`, `FOOD`)                              |
| `total_sold`       | Total unit terjual dalam periode (dari `order_items` WHERE order `COMPLETED`) |
| `total_revenue`    | Total revenue dari produk ini dalam periode                              |

**Catatan:**
- Data diambil dari `order_items` JOIN `orders` WHERE `orders.status = 'COMPLETED'` — produk dari order yang `CANCELLED` tidak dihitung.
- Produk yang tidak memiliki penjualan dalam periode yang dipilih **tidak ditampilkan** (bukan ditampilkan dengan nilai 0).
- Default sort: `total_sold DESC`.

**Happy Path:**
1. Admin mengirim request dengan `date_from`, `date_to` (opsional, default 30 hari terakhir).
2. Backend query `order_items` JOIN `orders`, group by `product_id` dan `product_name`.
3. Return array of rows diurutkan dari produk terlaris.

**Sad Path:** Sama dengan Section 4.4.

---

### 4.7 Reporting — Export CSV/PDF

**Deskripsi:** Admin mengunduh data laporan periodik dalam format CSV atau PDF.

**Endpoint:** `GET /api/v1/admin/reports/export`

**Query Parameters tambahan:**

| Parameter | Tipe   | Required | Constraint                        |
|-----------|--------|----------|-----------------------------------|
| `format`  | string | ✓        | Nilai valid: `csv`, `pdf`         |

**Happy Path:**
1. Admin mengirim request dengan parameter yang sama seperti Section 4.5, ditambah `format`. Untuk laporan per produk, gunakan parameter Section 4.6.
2. Backend generate file sesuai format.
3. Response dengan header yang tepat:
   - CSV: `Content-Type: text/csv`, `Content-Disposition: attachment; filename="report-{date_from}-{date_to}.csv"`
   - PDF: `Content-Type: application/pdf`, `Content-Disposition: attachment; filename="report-{date_from}-{date_to}.pdf"`

**Sad Path:**

| Kondisi                   | Behavior Sistem               | HTTP Status |
|---------------------------|-------------------------------|-------------|
| `format` tidak valid      | Return `VALIDATION_ERROR`     | 400         |
| Validasi tanggal gagal    | Sama dengan Section 4.4       | 400         |
| Gagal generate file       | Return `EXPORT_FAILED`        | 500         |

---

## 5. Caching Policy

Reporting adalah kandidat utama untuk caching karena query-nya bisa berat (aggregate dari banyak tabel).

- **Engine:** Redis
- **Key pattern:**
  - Summary: `report:summary:{date_from}:{date_to}`
  - Periodik: `report:orders:{date_from}:{date_to}:{group_by}`
- **TTL:** 5 menit — laporan tidak perlu real-time, tapi tidak boleh terlalu stale untuk kebutuhan operasional harian.
- **Invalidation trigger:** Tidak ada invalidasi aktif — biarkan TTL expire secara natural. Data laporan bersifat historis dan tidak berubah drastis dalam hitungan menit.
- **Fallback jika cache down:** Fallback langsung ke DB query. Jangan return error hanya karena Redis down.
- **Export CSV/PDF tidak di-cache** — generate langsung setiap request untuk memastikan data akurat saat diunduh.

---

## 6. Response Format

### Success — List (dengan pagination)
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

### Success — Summary Dashboard
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

### Success — Laporan Periodik
```json
{
  "success": true,
  "data": {
    "period": { "date_from": "2025-03-01", "date_to": "2025-03-31", "group_by": "day" },
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

### Success — Laporan Per Produk
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

### Daftar Error Code — Back Office

| Error Code              | HTTP Status | Trigger                                                               |
|-------------------------|:-----------:|-----------------------------------------------------------------------|
| `UNAUTHORIZED`          | 401         | Token tidak ada / tidak valid                                         |
| `FORBIDDEN`             | 403         | Role tidak memiliki izin untuk operasi ini                            |
| `ACCOUNT_DISABLED`      | 403         | `is_active = false`                                                   |
| `VALIDATION_ERROR`      | 400         | Parameter tidak valid (format tanggal, filter, dsb)                   |
| `DATE_RANGE_TOO_LARGE`  | 400         | Range tanggal `date_from` ke `date_to` melebihi 365 hari             |
| `CUSTOMER_NOT_FOUND`    | 404         | Customer tidak ditemukan (atau ID valid tapi bukan role Customer)     |
| `EXPORT_FAILED`         | 500         | Gagal generate file CSV/PDF                                           |
| `INTERNAL_SERVER_ERROR` | 500         | Error tidak terduga di server                                         |

> **Catatan:** Error code untuk operasi Order dan Product (misal: `ORDER_NOT_FOUND`, `PRODUCT_NOT_FOUND`) tetap mengacu ke daftar error code di BR masing-masing modul.

---

## 7. Database & Transaction Policy

- **Transaction scope:** Tidak ada operasi mutasi baru di modul ini di luar yang sudah terdefinisi di BR Order dan Product. Operasi reporting bersifat read-only — tidak perlu transaction.
- **Soft delete atau hard delete:** Tidak ada delete di modul ini.
- **Kolom audit:** Tidak ada tabel baru di modul ini.
- **Locking strategy:** Tidak diperlukan — semua operasi Back Office yang read-only tidak membutuhkan locking. Untuk operasi mutasi (update status order, edit produk), locking strategy mengikuti BR masing-masing modul.

---

## 8. Logging & Monitoring

**Yang wajib di-log:**
- Setiap akses ke endpoint reporting beserta `admin_id`, parameter filter, dan durasi query (level: INFO) — berguna untuk deteksi query lambat
- Request export CSV/PDF beserta `admin_id`, format, dan ukuran file yang dihasilkan (level: INFO)
- Query reporting yang melebihi threshold latency (misal: > 2 detik) — level: WARNING
- Kegagalan generate export file (level: ERROR)
- Akses ditolak karena role tidak sesuai (level: WARNING)
- Error 500 dengan full stack trace (level: ERROR)

**Yang tidak perlu di-log:**
- GET list order / produk / customer yang sukses (sudah di-log di masing-masing modul)
- Cache hit pada query reporting

---

## 9. Open Questions

- [x] Apakah Pegawai perlu bisa lihat summary dashboard sederhana? → **Resolved:** Ya. Pegawai mendapat akses ke endpoint summary yang sama, namun response dibatasi hanya pada metrik operasional hari ini (total order hari ini, order aktif). Filter tanggal diabaikan untuk role Pegawai — lihat Section 4.4.
- [x] Apakah perlu endpoint untuk melihat detail per produk di laporan? → **Resolved:** Ya. Ditambahkan endpoint `GET /api/v1/admin/reports/products` — lihat Section 4.6 (Laporan Per Produk) dan Section 4.7 (Export).
- [x] Apakah PDF export perlu menggunakan template dengan logo/branding cafe? → **Resolved:** Tidak perlu. Plain table saja.
- [x] Apakah perlu fitur scheduled export? → **Resolved:** Tidak perlu untuk saat ini.
- [x] Apakah Admin perlu bisa nonaktifkan/aktifkan akun Customer dari Back Office? → **Resolved:** Tidak. Tetap via Supabase Dashboard sesuai keputusan arsitektur di User BR.
