# High-Level System Overview — Backend Service Cafe

Bisa — dan saat ini **masih aman, belum lost context** ✅

Dokumen ini merangkum gambaran arsitektur tingkat tinggi dari seluruh business rules modul: **User/Auth, Product, Cart, Order, Payment, Back Office**.

---

## 1) Gambaran Arsitektur Umum

Sistem menggunakan kombinasi:

- **Supabase** untuk:
  - Authentication
  - PostgreSQL Database
  - Storage (asset seperti avatar / image produk)
- **Golang API Service** untuk business logic utama
- **Redis** untuk caching selektif
- **Midtrans** untuk payment gateway (Snap + webhook + refund)

Arsitektur toko: **single-branch**.

---

## 2) Modul Utama Sistem

1. **User & Authentication**
2. **Product**
3. **Cart**
4. **Order**
5. **Payment**
6. **Back Office**

Setiap modul punya batasan tanggung jawab yang jelas, dengan beberapa integrasi lintas modul untuk flow transaksi end-to-end.

---

## 3) Aktor dan Akses Tingkat Tinggi

### Aktor
- **Customer**
- **Pegawai**
- **Admin**
- **System/Internal Service** (Order Service, Payment Service, Cart Service)
- **Midtrans** (pengirim webhook pembayaran)

### Prinsip akses
- Public/unauthenticated: akses terbatas (umumnya read-only, tergantung endpoint).
- **Customer**: cart, checkout/order milik sendiri, payment milik sendiri, profile milik sendiri.
- **Pegawai**: operasional harian terbatas (mis. update status order tertentu, update status produk).
- **Admin**: akses penuh operasional + reporting + refund.
- Endpoint internal service-to-service menggunakan **`X-Internal-Api-Key`** (bukan JWT user).

---

## 4) Auth & Identity Model

### Pola auth
- Sebagian flow auth dilakukan **langsung via Supabase** dari frontend:
  - login/logout/reset/resend verification
- Golang API menangani:
  - endpoint bisnis
  - validasi JWT
  - validasi role
  - validasi status akun (`is_active`) via `public.users`

### Source of Truth
- `auth.users`: identitas inti (`id`, `email`)
- `public.users`: profil + role + status bisnis (`role`, `is_active`, `is_verified`, dll)

### Mitigasi celah arsitektur (disabled account)
Karena login langsung ke Supabase, akun disabled bisa sempat mendapat JWT valid. Mitigasi:
1. Semua endpoint bisnis wajib lewat middleware Golang (cek `is_active`).
2. Supabase RLS dikonfigurasi untuk mencegah akses langsung yang tidak semestinya.
3. Access token TTL pendek.

---

## 5) Alur End-to-End Utama (Customer Journey)

## A. Browse Produk
- Customer melihat list/detail produk publik.
- Product visibility dipengaruhi `status` dan soft delete (`deleted_at`).

## B. Cart
- Satu customer memiliki satu cart persisten.
- Add/update/delete item cart.
- Ketersediaan item (`is_available`) dihitung real-time dari status product.

## C. Checkout (Order)
- Pre-check: `is_active`, `is_verified`, `phone_number`.
- Validasi item cart + atribut per kategori produk.
- Order dibuat dengan status `PENDING` + `expires_at` 15 menit.
- Snapshot item disimpan di `order_items`.
- Stok dikurangi saat checkout (transaksional + locking).

## D. Payment
- Inisiasi payment via Midtrans Snap.
- Jika payment aktif sudah ada, URL payment di-reuse.
- Webhook Midtrans update status payment internal.
- Jika `SUCCESS`, trigger internal update order ke `CONFIRMED`.

## E. Cart Clearing
- Setelah order dikonfirmasi dari flow payment sukses, item cart terkait di-clear via endpoint internal Cart.

## F. Fulfillment
- Pegawai/Admin memproses order.
- Pegawai hanya boleh transisi `CONFIRMED -> COMPLETED`.
- Admin bisa melakukan transisi valid lain sesuai rules.

## G. Refund
- Admin dapat refund payment `SUCCESS` via Midtrans Refund API.
- Refund tidak otomatis mengubah status order (jika perlu, dilakukan manual via modul Order).

---

## 6) State Machine Inti

## Product
- `available`
- `out_of_stock`
- `unavailable`
- Soft delete: set `deleted_at`, produk tidak tampil untuk flow publik.
- Restore: aktif kembali sesuai rule modul Product.

## Order
- `PENDING` → `CONFIRMED` → `COMPLETED`
- Dapat menjadi `CANCELLED` sesuai aturan transisi.
- Auto-cancel scheduler untuk `PENDING` yang melewati `expires_at`.

## Payment
- `PENDING_PAYMENT`
- `SUCCESS`
- `FAILED`
- `EXPIRED`
- `REFUNDED`
- Status dipicu terutama oleh webhook Midtrans + aturan idempotensi.

---

## 7) Konsistensi Data & Transaksi

- Operasi mutasi penting selalu dalam **DB transaction**.
- Checkout/cancel order menggunakan **pessimistic locking** untuk mencegah race condition stok.
- Snapshot data order menjaga histori tetap konsisten walau data product berubah setelah checkout.
- Entity historikal penting menggunakan **soft delete** bila dibutuhkan (mis. produk).

---

## 8) Integrasi Antar Modul (Dependency Map)

- **Order** bergantung pada:
  - Cart (sumber item + clear cart pasca payment sukses)
  - Product (validasi status, stok, atribut)
  - User (verifikasi status akun, email, phone)
- **Payment** bergantung pada:
  - Order (hanya order `PENDING` yang bisa dibayar)
  - Midtrans (snap, webhook, refund)
- **Back Office** menggunakan endpoint operasional dari modul lain (Order/Product/User/Reporting), bukan duplikasi domain logic.

---

## 9) Caching Strategy

### Menggunakan Redis
- **Product**
  - List cache
  - Detail cache
- **Reporting**
  - Summary dan laporan periodik (TTL pendek)

### Tidak menggunakan cache
- **Cart**
- **Order**
- **Payment**

Alasan utama: data bersifat highly dynamic / sensitif status real-time.

---

## 10) Reliability & Operasional

- Webhook Midtrans selalu return **200** untuk mencegah retry berlebihan dari provider.
- Payment→Order sync failure ditangani dengan:
  - **Outbox**
  - retry exponential backoff
  - DLQ + alert operasional
- Logging dibedakan per level (INFO/WARNING/ERROR/CRITICAL).
- Standarisasi auth error lintas modul:
  - `401 UNAUTHORIZED`: token invalid/missing/expired
  - `403 FORBIDDEN`: role tidak memiliki izin

---

## 11) Kesimpulan

Secara high-level, sistem sudah memiliki fondasi yang kuat untuk production awal:

- domain boundary jelas,
- role-based access konsisten,
- transaksi & konsistensi data diperhatikan,
- payment flow realistis (webhook, idempotensi, outbox retry),
- risiko arsitektur Supabase-direct auth sudah diantisipasi dengan mitigasi yang tegas.

---