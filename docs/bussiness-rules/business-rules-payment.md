# Business Rules: Payment

Dokumen ini mendefinisikan aturan bisnis untuk modul **Payment** pada sistem **Backend Service Cafe**.

---

## 1. Overview & Scope

- **Deskripsi singkat fitur:** Mengelola proses pembayaran order yang telah dibuat Customer, mengintegrasikan sistem dengan Midtrans Snap (redirect), menerima notifikasi status pembayaran via webhook, dan menangani retry payment serta refund melalui Midtrans Refund API.
- **Actor yang terlibat:**
  - `Customer` — menginisiasi payment untuk order miliknya, melihat status payment, melakukan retry jika payment sebelumnya gagal/expired
  - `Admin` — melihat semua data payment, memfilter berdasarkan berbagai parameter, menginisiasi refund
  - `Midtrans` — mengirim notifikasi status pembayaran via HTTP webhook ke backend
  - `System (Order Service)` — menerima trigger update status order dari Payment Service setelah payment sukses
  - `System (Cart Service)` — menerima trigger clear cart dari Order Service setelah payment dikonfirmasi
- **Fitur/modul yang dependen:**
  - **Order** — payment hanya bisa dibuat untuk order yang `status = PENDING`; setelah payment sukses, Order Service di-notifikasi untuk update status order ke `CONFIRMED`
  - **User** — validasi `is_active`, `is_verified`, dan `phone_number` sebagai pre-condition inisiasi payment (sama dengan pre-condition checkout di Order BR)
- **Out of scope:**
  - Pemilihan payment method di backend — user memilih sendiri di halaman Snap Midtrans
  - Notifikasi real-time ke Customer (WebSocket/push notification)
  - Rekonsiliasi manual laporan keuangan
  - Multi-currency — semua transaksi dalam IDR

---

## 2. Authorization & Access Control

| Operasi                                          | Public | Customer          | Pegawai | Admin |
|--------------------------------------------------|:------:|:-----------------:|:-------:|:-----:|
| POST initiate payment (buat payment baru)        | ✗      | ✓ (order sendiri) | ✗       | ✗     |
| GET payment detail by order                      | ✗      | ✓ (order sendiri) | ✗       | ✓     |
| GET payment list                                 | ✗      | ✗                 | ✗       | ✓     |
| GET payment history milik sendiri (`GET /payments/me`) | ✗ | ✓ (payment milik sendiri) | ✗ | ✗ |
| POST webhook Midtrans (notifikasi)               | ✓*     | ✗                 | ✗       | ✗     |
| POST refund                                      | ✗      | ✗                 | ✗       | ✓     |

**Catatan:**
- `*` Endpoint webhook bersifat public (tidak ada JWT), namun wajib divalidasi menggunakan **signature key** dari Midtrans sebelum diproses. Request tanpa signature valid langsung ditolak.
- Customer hanya bisa mengakses payment milik ordernya sendiri. `payment.order_id → order.user_id` harus selalu dicocokkan dengan `user_id` dari JWT.
- Semua endpoint Payment yang diakses Customer wajib melewati middleware Golang yang mengecek `is_active` di `public.users` — sesuai arsitektur User BR.
- Pegawai tidak memiliki akses ke modul Payment sama sekali.
- Admin bisa melihat dan memfilter semua data payment, serta menginisiasi refund.

---

## 3. Validation Rules

### Inisiasi Payment

| Field      | Tipe | Required | Constraint                                                              |
|------------|------|----------|-------------------------------------------------------------------------|
| `order_id` | UUID | ✓        | Harus exist, milik user yang login, dan berstatus `PENDING`             |

**Catatan khusus:**
- Tidak ada field lain yang dikirim saat inisiasi payment. Amount diambil dari `order.total_amount`, bukan dari input user.
- Jika order sudah memiliki payment aktif (`status = PENDING_PAYMENT`), backend mengembalikan Snap URL yang sudah ada (reuse) — tidak membuat payment baru.

### Webhook Midtrans

Tidak ada validasi field dari user. Validasi yang dilakukan adalah:
- Keberadaan dan kevalidan `signature_key` dari Midtrans.
- Keberadaan `order_id` (dalam format `PAY-{payment_id}-{unix_timestamp}`) yang bisa di-parse ke `payment_id` internal.
- Field wajib dari Midtrans: `transaction_status`, `fraud_status`, `gross_amount`.

### Refund (Admin)

| Field           | Tipe   | Required | Constraint                                                                       |
|-----------------|--------|----------|----------------------------------------------------------------------------------|
| `payment_id`    | UUID   | ✓        | Harus exist dan berstatus `SUCCESS`                                              |
| `reason`        | string | ✓        | min 5, max 255 karakter; alasan refund untuk audit trail                         |
| `refund_amount` | integer | ✗       | Jika tidak dikirim, refund penuh (`payment.amount`); jika dikirim, harus > 0 dan ≤ `payment.amount` |

---

## 4. Business Rules per Operasi

### 4.1 POST /payments/initiate — Inisiasi Payment

**Deskripsi:** Customer meminta Snap Token & Redirect URL Midtrans untuk membayar order yang masih `PENDING`. Jika payment aktif sudah ada, kembalikan URL yang sama (reuse). Jika belum ada atau sudah expired/gagal, buat payment baru.

**Pre-conditions:**
- Request terautentikasi dengan role `Customer`.
- `is_active = true` di `public.users`.
- `is_verified = true` di `public.users`.
- `phone_number` tidak null/kosong di `public.users`.
- Order dengan `order_id` yang dikirim harus berstatus `PENDING`.
- Order belum melewati `expires_at` (masih dalam 15 menit).

**Happy Path:**

**Skenario A — Payment aktif sudah ada (reuse):**
1. Validasi autentikasi, role, dan pre-conditions user.
2. Ambil record `order`, pastikan milik user dan berstatus `PENDING`.
3. Cek apakah ada record `payment` terkait order ini dengan `status = PENDING_PAYMENT`.
4. Jika ada → return `snap_redirect_url` yang sudah tersimpan langsung. Tidak ada pemanggilan ke Midtrans.

**Skenario B — Payment baru (tidak ada payment aktif):**
1. Validasi autentikasi, role, dan pre-conditions user.
2. Ambil record `order`, pastikan milik user dan berstatus `PENDING`.
3. Pastikan tidak ada payment aktif (`PENDING_PAYMENT`) untuk order ini. Jika ada payment lama dengan status `FAILED` atau `EXPIRED`, lanjutkan ke langkah berikutnya.
4. Generate `payment_id` (UUID baru).
5. Buat `midtrans_order_id` dengan format: `PAY-{payment_id}-{unix_timestamp}`. Format ini memastikan setiap request ke Midtrans memiliki `order_id` yang unik.
6. Panggil Midtrans Snap API dengan:
   - `transaction_details.order_id` = `midtrans_order_id`
   - `transaction_details.gross_amount` = `order.total_amount`
   - `customer_details` = data user (nama, email, phone)
   - `item_details` = list item dari `order_items` (nama produk, harga, qty)
   - `expiry` = sesuai sisa waktu `order.expires_at` (agar Snap tidak melebihi expiry order)
7. Simpan record `payment` baru di DB dengan status `PENDING_PAYMENT`, beserta `midtrans_order_id` dan `snap_redirect_url` dari response Midtrans.
8. Return `snap_redirect_url` ke Customer.

**Sad Path & Edge Cases:**

| Kondisi                                                       | Behavior Sistem                                                    | HTTP Status |
|---------------------------------------------------------------|--------------------------------------------------------------------|-------------|
| Role bukan Customer                                           | Return `FORBIDDEN`                                                 | 403         |
| `is_active = false`                                           | Return `ACCOUNT_DISABLED`                                          | 403         |
| `is_verified = false`                                         | Return `EMAIL_UNVERIFIED`                                          | 403         |
| `phone_number` kosong / null                                  | Return `PHONE_NUMBER_REQUIRED`                                     | 403         |
| `order_id` format bukan UUID                                  | Return `VALIDATION_ERROR`                                          | 400         |
| Order tidak ditemukan atau bukan milik user                   | Return `ORDER_NOT_FOUND`                                           | 404         |
| Order berstatus bukan `PENDING`                               | Return `ORDER_NOT_PAYABLE`                                         | 422         |
| Order sudah expired (`expires_at` terlewat)                   | Return `ORDER_EXPIRED` (order akan segera di-cancel oleh scheduler)| 422         |
| Midtrans API error / timeout                                  | Log error, return `PAYMENT_GATEWAY_ERROR`                          | 502         |
| DB error                                                      | Rollback, log error                                                | 500         |

**Post-conditions:**
- Record `payment` baru tersimpan di DB dengan status `PENDING_PAYMENT` (Skenario B).
- Customer mendapatkan `snap_redirect_url` untuk diarahkan ke halaman pembayaran Midtrans.

---

### 4.2 POST /payments/webhook — Terima Notifikasi Midtrans

**Deskripsi:** Endpoint yang dipanggil Midtrans secara otomatis untuk menginformasikan perubahan status transaksi. Endpoint ini memproses semua kemungkinan status dari Midtrans dan mengupdate status payment internal.

**Pre-conditions:**
- Request berasal dari Midtrans (tidak ada JWT).
- `signature_key` valid (hasil kalkulasi dari `order_id + status_code + gross_amount + server_key` yang di-SHA512).

**Happy Path:**
1. Terima request POST dari Midtrans.
2. Validasi `signature_key`:
   - Hitung: `SHA512(midtrans_order_id + status_code + gross_amount + server_key)`
   - Cocokkan dengan `signature_key` yang dikirim. Jika tidak cocok → tolak dengan 200 OK (jangan 401, agar Midtrans tidak retry berlebihan).
3. Parse `midtrans_order_id` dari field `order_id` di payload untuk mendapatkan `payment_id` internal.
   - Format: `PAY-{payment_id}-{unix_timestamp}` → ambil bagian `payment_id`.
4. Ambil record `payment` dari DB berdasarkan `payment_id`.
5. Tentukan status internal berdasarkan kombinasi `transaction_status` dan `fraud_status` dari Midtrans:

   | `transaction_status` | `fraud_status` | Status Internal |
   |----------------------|----------------|-----------------|
   | `settlement`         | `accept`       | `SUCCESS`       |
   | `capture`            | `accept`       | `SUCCESS`       |
   | `capture`            | `challenge`    | `SUCCESS`*      |
   | `pending`            | (any)          | `PENDING_PAYMENT` (tidak berubah) |
   | `deny`               | (any)          | `FAILED`        |
   | `cancel`             | (any)          | `FAILED`        |
   | `expire`             | (any)          | `EXPIRED`       |
   | `failure`            | (any)          | `FAILED`        |
   | `refund`             | (any)          | `REFUNDED`      |

   > `*` Status `capture + challenge` (fraud review): ikut best practice Midtrans — treat sebagai `SUCCESS` dan biarkan Midtrans yang mengelola review-nya. Jika dibutuhkan, admin bisa approve/deny dari Midtrans Dashboard.

6. Jika status internal berubah, update record `payment` di DB. Simpan juga `payment_method` dari field `payment_type` Midtrans dan `midtrans_transaction_id` dari field `transaction_id`.
7. Jika status baru adalah `SUCCESS`:
   a. Panggil endpoint internal Order Service (`PATCH /internal/orders/{order_id}/status`) untuk update status order ke `CONFIRMED`.
   b. Jika Order Service gagal: log error (level: ERROR), **simpan event ke outbox** untuk retry async (exponential backoff), dan tetap return 200 ke Midtrans.
8. Return HTTP 200 OK ke Midtrans, terlepas dari hasil proses internal — ini penting agar Midtrans tidak melakukan retry yang tidak perlu.

**Idempotency:**
- Webhook dari Midtrans bisa datang lebih dari sekali untuk transaksi yang sama. Sebelum update, cek apakah status payment sudah final (`SUCCESS`, `FAILED`, `EXPIRED`, `REFUNDED`). Jika sudah final → skip update, langsung return 200 OK.

**Reliability (Outbox & Retry):**
- Untuk kasus webhook `SUCCESS` namun call ke Order Service gagal, Payment Service **wajib** menulis event ke outbox dalam transaction DB yang sama dengan update status payment.
- Worker async memproses outbox dengan retry bertahap (exponential backoff) sampai sukses atau melewati threshold.
- Event yang melewati threshold dipindahkan ke DLQ/antrian gagal dan memicu alert operasional.
- Mekanisme ini menjaga eventual consistency antara Payment (`SUCCESS`) dan Order (`CONFIRMED`) tanpa mengganggu kontrak webhook Midtrans (tetap 200).

**Sad Path & Edge Cases:**

| Kondisi                                                    | Behavior Sistem                                                              | HTTP Status ke Midtrans |
|------------------------------------------------------------|------------------------------------------------------------------------------|:-----------------------:|
| `signature_key` tidak valid                                | Log warning, abaikan request                                                 | 200                     |
| `payment_id` tidak bisa di-parse dari `order_id`           | Log error, abaikan request                                                   | 200                     |
| Record `payment` tidak ditemukan di DB                     | Log error, abaikan request                                                   | 200                     |
| Payment sudah di status final (idempotency)                | Skip update, return sukses                                                   | 200                     |
| Order Service gagal di-update                              | Log error (level: ERROR), enqueue event ke outbox untuk retry async, payment tetap `SUCCESS` | 200 |
| DB error saat update payment                               | Log error (level: ERROR)                                                     | 200                     |

> **Catatan penting:** Seluruh sad path pada webhook tetap return HTTP 200 ke Midtrans. Ini adalah pola standar integrasi Midtrans — return non-200 akan menyebabkan Midtrans melakukan retry berulang.

**Post-conditions:**
- Status `payment` ter-update di DB sesuai notifikasi Midtrans.
- Jika `SUCCESS`: Order Service menerima trigger untuk update status order ke `CONFIRMED`, yang kemudian akan trigger clear cart di Cart Service.
- `payment_method` dan `midtrans_transaction_id` tersimpan di record `payment`.

---

### 4.3 GET /payments/order/:order_id — Detail Payment berdasarkan Order

**Deskripsi:** Customer atau Admin mengambil data payment terkini dari sebuah order.

**Pre-conditions:**
- Request terautentikasi dengan role `Customer` atau `Admin`.
- `is_active = true` di `public.users`.

**Happy Path:**
1. Validasi autentikasi dan role.
2. Validasi format `order_id` (UUID).
3. Jika Customer: pastikan `order.user_id` cocok dengan `user_id` dari JWT. Jika tidak cocok → return `ORDER_NOT_FOUND`.
4. Ambil **semua** record `payment` terkait `order_id`, diurutkan `created_at DESC`.
   - Record pertama (terbaru) adalah payment yang paling relevan ditampilkan ke user.
   - Untuk kasus retry, ada lebih dari satu record — semua dikembalikan agar Admin bisa melihat histori percobaan.
5. Jika Customer: return hanya record payment terbaru (single object), bukan array — cukup untuk mengetahui status terkini.
6. Jika Admin: return semua record payment untuk order tersebut (array), beserta histori retry.
7. Return data sesuai role.

**Sad Path & Edge Cases:**

| Kondisi                                        | Behavior Sistem                                                             | HTTP Status |
|------------------------------------------------|-----------------------------------------------------------------------------|-------------|
| Role tidak memiliki akses (Pegawai)            | Return `FORBIDDEN`                                                          | 403         |
| `is_active = false`                            | Return `ACCOUNT_DISABLED`                                                   | 403         |
| Format `order_id` bukan UUID                   | Return `VALIDATION_ERROR`                                                   | 400         |
| Order tidak ditemukan                          | Return `ORDER_NOT_FOUND`                                                    | 404         |
| Order milik user lain (Customer)               | Return `ORDER_NOT_FOUND` (jangan bocorkan eksistensi order milik user lain) | 404         |
| Payment belum pernah dibuat untuk order ini    | Return `PAYMENT_NOT_FOUND`                                                  | 404         |

**Post-conditions:** Tidak ada perubahan state.

---

### 4.4 GET /payments — List Payment (Admin)

**Deskripsi:** Admin mengambil daftar semua payment dengan opsi filter.

**Pre-conditions:**
- Request terautentikasi dengan role `Admin`.
- `is_active = true` di `public.users`.

**Query Parameters:**

| Parameter    | Tipe   | Required | Deskripsi                                                       |
|--------------|--------|----------|-----------------------------------------------------------------|
| `cursor`     | string | ✗        | Cursor untuk navigasi (opaque base64) — mengikuti pola Order BR |
| `direction`  | enum   | ✗        | `next` atau `prev`; default: `next`                             |
| `limit`      | int    | ✗        | Default: 10; max: 50                                            |
| `status`     | enum   | ✗        | `PENDING_PAYMENT`, `SUCCESS`, `FAILED`, `EXPIRED`, `REFUNDED`   |
| `order_id`   | UUID   | ✗        | Filter payment untuk order tertentu                             |
| `user_id`    | UUID   | ✗        | Filter payment milik user tertentu                              |
| `date_from`  | date   | ✗        | Filter dari tanggal (format: `YYYY-MM-DD`, timezone WIB)        |
| `date_to`    | date   | ✗        | Filter sampai tanggal (format: `YYYY-MM-DD`, timezone WIB)      |
| `method`     | string | ✗        | Filter by payment method (misal: `gopay`, `bca_va`, `qris`)     |

**Happy Path:**
1. Validasi autentikasi dan role Admin.
2. Terapkan semua filter yang dikirim.
3. Terapkan cursor-based pagination.
4. Return list payment.

**Sad Path & Edge Cases:**

| Kondisi                          | Behavior Sistem                    | HTTP Status |
|----------------------------------|------------------------------------|-------------|
| Role bukan Admin                 | Return `FORBIDDEN`                 | 403         |
| `is_active = false`              | Return `ACCOUNT_DISABLED`          | 403         |
| `status` value tidak valid       | Return `VALIDATION_ERROR`          | 400         |
| `cursor` tidak valid             | Return `INVALID_CURSOR`            | 400         |
| Format `order_id`/`user_id` bukan UUID | Return `VALIDATION_ERROR`   | 400         |
| `date_from` > `date_to`          | Return `VALIDATION_ERROR`          | 400         |
| Tidak ada payment                | Return array kosong                | 200         |

**Post-conditions:** Tidak ada perubahan state.

---

### 4.5 POST /payments/:payment_id/refund — Refund Payment (Admin)

**Deskripsi:** Admin meminta refund ke Midtrans untuk payment yang sudah berstatus `SUCCESS`. Refund bisa partial atau penuh. Semua aksi refund dicatat sebagai histori refund.

**Pre-conditions:**
- Request terautentikasi dengan role `Admin`.
- `is_active = true` di `public.users`.
- Payment berstatus `SUCCESS`.
- Belum pernah di-refund (`status != REFUNDED`).
- Untuk fase saat ini, satu payment maksimum satu kali refund (single-refund policy).

**Happy Path:**
1. Validasi autentikasi dan role Admin.
2. Validasi format `payment_id` (UUID).
3. Validasi field `reason` dan `refund_amount` (jika dikirim).
4. Ambil record `payment`, pastikan berstatus `SUCCESS`.
5. Panggil Midtrans Refund API menggunakan `midtrans_transaction_id` yang tersimpan.
   - Jika `refund_amount` tidak dikirim: refund penuh (`payment.amount`).
   - Jika `refund_amount` dikirim: refund partial.
6. Jika Midtrans API berhasil:
   a. Insert record histori ke tabel `payment_refunds` (`payment_id`, `midtrans_refund_id`, `refund_amount`, `reason`, `created_by`, `created_at`).
   b. Update agregat pada tabel `payments`: `status = REFUNDED`, `refund_amount`, `refund_reason`, `refunded_at`.
7. **Catatan:** Status order **tidak** diubah secara otomatis oleh sistem saat refund. Jika perlu mengubah status order (misal ke `CANCELLED`), Admin melakukannya manual via endpoint Order.
8. Return detail payment yang sudah di-refund.

**Sad Path & Edge Cases:**

| Kondisi                                              | Behavior Sistem                                            | HTTP Status |
|------------------------------------------------------|------------------------------------------------------------|-------------|
| Role bukan Admin                                     | Return `FORBIDDEN`                                         | 403         |
| `is_active = false`                                  | Return `ACCOUNT_DISABLED`                                  | 403         |
| Format `payment_id` bukan UUID                       | Return `VALIDATION_ERROR`                                  | 400         |
| `reason` tidak dikirim atau terlalu pendek           | Return `VALIDATION_ERROR`                                  | 400         |
| `refund_amount` <= 0 atau > `payment.amount`         | Return `VALIDATION_ERROR`                                  | 400         |
| Payment tidak ditemukan                              | Return `PAYMENT_NOT_FOUND`                                 | 404         |
| Payment bukan berstatus `SUCCESS`                    | Return `PAYMENT_NOT_REFUNDABLE`                            | 422         |
| Payment sudah di-refund sebelumnya                   | Return `PAYMENT_ALREADY_REFUNDED`                          | 422         |
| Midtrans Refund API error / timeout                  | Log error, return `PAYMENT_GATEWAY_ERROR` — status payment **tidak** berubah | 502 |
| DB error setelah Midtrans sukses                     | Log error (level: CRITICAL), perlu rekonsiliasi manual     | 500         |

**Post-conditions:**
- Record baru tersimpan di tabel `payment_refunds` (berisi `payment_id`, `midtrans_refund_id`, `amount`, `reason`, `created_by`).
- `payment.status` berubah menjadi `REFUNDED`; kolom agregat `refund_amount`, `refund_reason`, dan `refunded_at` di tabel `payments` ter-update.
- Status order **tidak** berubah otomatis — jika perlu diubah (misal ke `CANCELLED`), Admin melakukannya manual via endpoint Order.

---

### 4.6 GET /payments/me — History Payment Customer

**Deskripsi:** Customer mengambil riwayat payment miliknya sendiri dengan filter dan cursor-based pagination.

**Pre-conditions:**
- Request terautentikasi dengan role `Customer`.
- `is_active = true` di `public.users`.

**Query Parameters:**

| Parameter   | Tipe   | Required | Deskripsi                                                      |
|-------------|--------|----------|----------------------------------------------------------------|
| `cursor`    | string | ✗        | Cursor untuk navigasi (opaque base64)                         |
| `direction` | enum   | ✗        | `next` atau `prev`; default: `next`                           |
| `limit`     | int    | ✗        | Default: 10; max: 50                                           |
| `status`    | enum   | ✗        | `PENDING_PAYMENT`, `SUCCESS`, `FAILED`, `EXPIRED`, `REFUNDED` |
| `date_from` | date   | ✗        | Filter dari tanggal (format: `YYYY-MM-DD`, timezone WIB)      |
| `date_to`   | date   | ✗        | Filter sampai tanggal (format: `YYYY-MM-DD`, timezone WIB)    |

**Happy Path:**
1. Validasi autentikasi, role Customer, dan `is_active`.
2. Ambil seluruh payment yang berelasi ke order milik user login (`payment.order_id -> orders.user_id`).
3. Terapkan filter `status`, `date_from`, `date_to` jika dikirim.
4. Terapkan cursor-based pagination (`cursor`, `direction`, `limit`).
5. Return daftar payment milik user beserta metadata pagination.

**Sad Path & Edge Cases:**

| Kondisi                          | Behavior Sistem             | HTTP Status |
|----------------------------------|-----------------------------|-------------|
| Role bukan Customer              | Return `FORBIDDEN`          | 403         |
| `is_active = false`              | Return `ACCOUNT_DISABLED`   | 403         |
| `status` value tidak valid       | Return `VALIDATION_ERROR`   | 400         |
| `cursor` tidak valid             | Return `INVALID_CURSOR`     | 400         |
| `date_from` > `date_to`          | Return `VALIDATION_ERROR`   | 400         |
| Tidak ada data payment           | Return array kosong         | 200         |

**Post-conditions:** Tidak ada perubahan state.

---

## 5. Caching Policy

Tidak ada caching untuk modul Payment.

**Alasan:**
- Data payment bersifat highly sensitive dan harus selalu mencerminkan state terkini — terutama status yang bisa berubah kapan saja via webhook.
- Volume read relatif kecil (Customer hanya bisa baca payment miliknya sendiri).
- Risiko stale data jauh lebih besar dari manfaat caching.

---

## 6. External Service & Side Effects

| Trigger                                                   | Service / Action                                                                       | Sync/Async               |
|-----------------------------------------------------------|----------------------------------------------------------------------------------------|--------------------------|
| Inisiasi payment (Skenario B)                             | Panggil Midtrans Snap API → dapatkan `snap_redirect_url`                              | Sync                     |
| Webhook: status `SUCCESS`                                 | Panggil Order Service `PATCH /internal/orders/{order_id}/status` → `CONFIRMED`        | Sync (setelah DB commit) |
| Webhook: status `SUCCESS` + Order Service gagal           | Tulis event ke tabel outbox (dalam transaction DB yang sama dengan update payment)     | Async (via outbox worker)|
| Outbox worker: retry event gagal                          | Retry panggilan ke Order Service dengan exponential backoff sampai sukses / threshold  | Async                    |
| Outbox worker: event melewati threshold                   | Pindahkan ke DLQ + kirim alert operasional (Slack/Email)                               | Async                    |
| Webhook: status `SUCCESS` (delegasi)                      | Order Service memanggil Cart Service untuk clear cart                                  | Sync (dihandle Order BR) |
| Refund: Admin initiate                                    | Panggil Midtrans Refund API menggunakan `midtrans_transaction_id`                     | Sync                     |

**Catatan:**
- Midtrans Snap API dipanggil secara sync — jika Midtrans timeout, request inisiasi payment gagal dan tidak ada record `payment` yang dibuat.
- Penulisan event ke outbox dilakukan dalam satu transaction DB yang sama dengan update status `payment` ke `SUCCESS`. Ini menjamin atomicity: event tidak akan hilang meski worker belum sempat memprosesnya.
- Jika outbox worker sudah melewati threshold retry, event masuk DLQ dan alert dikirim ke tim operasional. Harus tersedia mekanisme manual replay untuk event di DLQ.
- Seluruh operasi refund ke Midtrans bersifat sync. Jika Midtrans gagal, status payment tidak berubah dan tidak ada record `payment_refunds` yang dibuat — Admin bisa coba ulang.

---

## 7. Response Format

Mengikuti format standar yang sudah didefinisikan di Product BR (`success`, `data`, `message`).

### Success — Detail Payment

```json
{
  "success": true,
  "data": {
    "payment_id": "uuid",
    "order_id": "uuid",
    "order_number": "ORD-20250405-001",
    "status": "SUCCESS",
    "amount": 68000,
    "payment_method": "gopay",
    "midtrans_transaction_id": "abc123-midtrans-txn-id",
    "snap_redirect_url": "https://app.midtrans.com/snap/v2/vtweb/...",
    "refund_amount": null,
    "refund_reason": null,
    "refunded_at": null,
    "created_at": "2025-04-05T10:00:00Z",
    "updated_at": "2025-04-05T10:02:30Z"
  },
  "message": "Payment berhasil diambil"
}
```

> **Catatan:** `snap_redirect_url` hanya relevan selama `status = PENDING_PAYMENT`. Untuk status lain, field ini bisa `null`.

### Success — Inisiasi Payment

```json
{
  "success": true,
  "data": {
    "payment_id": "uuid",
    "order_id": "uuid",
    "snap_redirect_url": "https://app.midtrans.com/snap/v2/vtweb/...",
    "expires_at": "2025-04-05T10:15:00Z"
  },
  "message": "Payment berhasil dibuat, silakan lanjutkan ke halaman pembayaran"
}
```

> **Catatan:** `expires_at` di response ini mengacu pada `order.expires_at` — bukan expiry Snap Token Midtrans (yang defaultnya 24 jam). Customer harus menyelesaikan pembayaran sebelum waktu ini.

### Success — Refund

```json
{
  "success": true,
  "data": {
    "payment_id": "uuid",
    "order_id": "uuid",
    "status": "REFUNDED",
    "amount": 68000,
    "refund_amount": 68000,
    "refund_reason": "Pesanan tidak bisa diproses",
    "refunded_at": "2025-04-05T11:00:00Z"
  },
  "message": "Refund berhasil diproses"
}
```

### Success — List Payment (dengan Pagination)

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

### Success — List Payment Customer (dengan Pagination)

```json
{
  "success": true,
  "data": [
    {
      "payment_id": "uuid",
      "order_id": "uuid",
      "order_number": "ORD-20250405-001",
      "status": "SUCCESS",
      "amount": 68000,
      "payment_method": "gopay",
      "created_at": "2025-04-05T10:00:00Z",
      "updated_at": "2025-04-05T10:02:30Z"
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

| Code                        | HTTP Status | Trigger                                                                          |
|-----------------------------|:-----------:|----------------------------------------------------------------------------------|
| `VALIDATION_ERROR`          | 400         | Format field tidak valid, `refund_amount` tidak valid, dsb                       |
| `INVALID_CURSOR`            | 400         | Cursor pagination tidak valid                                                    |
| `UNAUTHORIZED`              | 401         | Token tidak ada atau tidak valid                                                  |
| `FORBIDDEN`                 | 403         | Role tidak memiliki izin                                                         |
| `ACCOUNT_DISABLED`          | 403         | `is_active = false`                                                              |
| `EMAIL_UNVERIFIED`          | 403         | Customer belum verifikasi email                                                  |
| `PHONE_NUMBER_REQUIRED`     | 403         | Customer belum mengisi nomor telepon                                             |
| `ORDER_NOT_FOUND`           | 404         | Order tidak ditemukan atau bukan milik user yang login (untuk Customer)          |
| `PAYMENT_NOT_FOUND`         | 404         | Payment tidak ditemukan untuk order tersebut                                     |
| `ORDER_NOT_PAYABLE`         | 422         | Order tidak bisa dibayar karena statusnya bukan `PENDING`                        |
| `ORDER_EXPIRED`             | 422         | Order sudah melewati `expires_at`                                                |
| `PAYMENT_NOT_REFUNDABLE`    | 422         | Payment bukan berstatus `SUCCESS`                                                |
| `PAYMENT_ALREADY_REFUNDED`  | 422         | Payment sudah pernah di-refund                                                   |
| `PAYMENT_GATEWAY_ERROR`     | 502         | Midtrans API tidak bisa dihubungi atau mengembalikan error                       |
| `INTERNAL_SERVER_ERROR`     | 500         | Error tidak terduga di server                                                    |

---

## 8. Database & Transaction Policy

- **Transaction scope:** Operasi inisiasi payment (Section 4.1 Skenario B) wajib menggunakan DB transaction. Operasi webhook (Section 4.2) juga wajib transaksional untuk memastikan update status payment dan trigger ke Order Service bersifat atomic di sisi DB.
- **Soft delete atau hard delete:** Tidak ada delete pada modul ini. Record `payment` bersifat append-only untuk menjaga integritas historis transaksi. Retry payment menghasilkan record `payment` baru (bukan overwrite record lama).
- **Kolom audit:** `created_at`, `updated_at` pada tabel `payments`.
- **Locking strategy:** Gunakan **optimistic locking** atau **idempotency check** (`status IS NOT IN final_statuses`) pada handler webhook untuk mencegah race condition jika Midtrans mengirim webhook duplikat secara bersamaan.
- **Retention `snap_redirect_url`:** field ini hanya dipertahankan saat `status = PENDING_PAYMENT`. Saat status berubah ke final (`SUCCESS`, `FAILED`, `EXPIRED`, `REFUNDED`), `snap_redirect_url` di-set `NULL` dalam proses update yang sama.

### Desain Tabel (Referensi)

**Tabel `payments`:**

| Kolom                    | Tipe         | Keterangan                                                                                                              |
|--------------------------|--------------|-------------------------------------------------------------------------------------------------------------------------|
| `id`                     | UUID         | Primary key; digunakan sebagai bagian dari `midtrans_order_id`                                                         |
| `order_id`               | UUID         | Foreign key ke `orders`; satu order bisa punya lebih dari satu record payment (retry)                                   |
| `status`                 | ENUM         | `PENDING_PAYMENT`, `SUCCESS`, `FAILED`, `EXPIRED`, `REFUNDED`                                                          |
| `amount`                 | INTEGER      | Total yang dibayar (Rupiah); diambil dari `order.total_amount` saat inisiasi                                            |
| `payment_method`         | VARCHAR(50)  | Nullable; diisi dari `payment_type` webhook Midtrans setelah user memilih metode (misal: `gopay`, `bca_va`, `qris`)     |
| `midtrans_order_id`      | VARCHAR(100) | ID yang dikirim ke Midtrans; format: `PAY-{payment_id}-{unix_timestamp}`; unik                                          |
| `midtrans_transaction_id`| VARCHAR(100) | Nullable; `transaction_id` dari Midtrans; diisi setelah webhook diterima                                                |
| `snap_redirect_url`      | TEXT         | Nullable; URL redirect Midtrans Snap; diisi saat inisiasi, null setelah status final                                    |
| `refund_amount`          | INTEGER      | Nullable; jumlah yang di-refund (Rupiah)                                                                                |
| `refund_reason`          | TEXT         | Nullable; alasan refund yang diinput Admin                                                                              |
| `refunded_at`            | TIMESTAMPTZ  | Nullable; timestamp saat refund diproses                                                                                |
| `created_at`             | TIMESTAMPTZ  | Auto set                                                                                                                |
| `updated_at`             | TIMESTAMPTZ  | Auto update setiap ada perubahan status                                                                                  |

**Tabel `payment_refunds` (baru):**

| Kolom                | Tipe         | Keterangan                                                     |
|----------------------|--------------|----------------------------------------------------------------|
| `id`                 | UUID         | Primary key                                                    |
| `payment_id`         | UUID         | Foreign key ke `payments.id`                                   |
| `midtrans_refund_id` | VARCHAR(100) | ID refund dari Midtrans                                        |
| `amount`             | INTEGER      | Nominal refund (Rupiah)                                        |
| `reason`             | TEXT         | Alasan refund dari Admin                                       |
| `created_by`         | UUID         | User ID Admin yang melakukan refund                            |
| `created_at`         | TIMESTAMPTZ  | Waktu refund dibuat                                            |

> **Policy fase saat ini:** tetap single-refund per payment (maksimal 1 row refund per `payment_id`, enforce via unique index).  
> **Future-ready:** struktur tabel memungkinkan ekspansi ke multiple partial refund jika policy bisnis berubah.

> **Catatan desain `midtrans_order_id`:** Menggunakan format `PAY-{payment_id}-{unix_timestamp}` agar setiap request ke Midtrans memiliki `order_id` yang unik — ini diperlukan karena Midtrans menolak `order_id` yang sama jika masih aktif atau sudah pernah dibayar. Dengan format ini, `payment_id` internal bisa di-parse kembali dari `midtrans_order_id` untuk keperluan webhook handling, tanpa perlu kolom lookup tambahan.

> **Catatan desain multiple payment per order:** Satu `order_id` bisa punya lebih dari satu record `payment` (untuk kasus retry). Yang "aktif" adalah record dengan `status = PENDING_PAYMENT`. Saat Customer inisiasi payment, backend selalu cek dulu apakah ada record `PENDING_PAYMENT` sebelum membuat yang baru.

---

## 9. Logging & Monitoring

**Yang wajib di-log:**
- Setiap inisiasi payment beserta `user_id`, `order_id`, `payment_id`, dan skenario yang berjalan (A: reuse / B: baru) — level: INFO
- Setiap webhook yang diterima beserta `midtrans_order_id`, `transaction_status`, `fraud_status`, dan status internal hasil mapping — level: INFO
- Webhook dengan `signature_key` tidak valid — level: WARNING
- Setiap perubahan status payment beserta `payment_id`, `status_lama`, `status_baru` — level: INFO
- Kegagalan panggilan ke Order Service setelah webhook `SUCCESS` — level: ERROR (perlu alert)
- Kegagalan Midtrans API (timeout, error 5xx) saat inisiasi payment — level: ERROR
- Kegagalan Midtrans Refund API — level: ERROR
- Webhook duplikat yang di-skip karena status sudah final — level: DEBUG
- Error 500 dengan full stack trace — level: ERROR
- Kasus DB berhasil di-update setelah refund Midtrans sukses, tapi DB error — level: CRITICAL (perlu rekonsiliasi manual)
- Event retry sinkronisasi Payment->Order yang melewati threshold (jumlah retry > N atau umur event > X menit) — level: ERROR + trigger alert (Slack/Email/Pager)
- Jumlah event outbox gagal (DLQ) — level: CRITICAL (perlu investigasi manual/replay)

**Yang tidak perlu di-log:**
- GET payment detail yang sukses
- Webhook `pending` yang tidak mengubah status (idempotent, tidak ada perubahan)

**Alerting Rules (Operasional):**
- Alert dikirim jika event `payment_success_order_sync_failed` melewati threshold retry/latency.
- Alert minimal memuat: `payment_id`, `order_id`, retry_count, last_error, first_failed_at.
- Harus tersedia mekanisme manual replay untuk event gagal permanen.

---

## 10. Open Questions

- [x] **Apakah perlu endpoint untuk Customer melihat semua history payment miliknya?**  
  **Resolved:** Ya, perlu. Ditambahkan endpoint `GET /payments/me` (role `Customer`) untuk menampilkan riwayat payment milik user login dengan cursor pagination dan filter opsional (`status`, `date_from`, `date_to`). Endpoint existing `GET /payments/order/:order_id` tetap dipertahankan untuk detail per order.

- [x] **Apakah perlu retry mechanism otomatis (outbox/job) untuk kasus webhook `SUCCESS` tapi Order Service gagal di-update?**  
  **Resolved:** Ya, wajib. Diterapkan outbox + async retry (exponential backoff), DLQ, dan alerting threshold.

- [x] **Apakah partial refund perlu ditrack lebih detail (misal: refund history)?**  
  **Resolved:** Ya. Ditambahkan tabel `payment_refunds` untuk histori refund. Fase saat ini tetap single-refund policy, namun desain siap diekstensikan.

- [x] **Berapa lama `snap_redirect_url` disimpan?**  
  **Resolved:** Disimpan hanya saat `PENDING_PAYMENT`; otomatis di-null-kan saat status final.

- [x] **Apakah Admin perlu notifikasi (email/alert) saat ada payment `SUCCESS` yang gagal trigger ke Order Service?**  
  **Resolved:** Ya. Wajib ada alert operasional berbasis threshold retry/umur event + dukungan manual replay.
