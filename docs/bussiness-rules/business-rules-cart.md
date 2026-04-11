# Business Rules: Cart

Dokumen ini mendefinisikan aturan bisnis untuk modul **Cart** pada sistem **Backend Service Cafe**.

---

## 1. Overview & Scope

- **Deskripsi singkat fitur:** Memungkinkan Customer untuk mengumpulkan produk yang ingin dibeli sebelum melakukan checkout. Cart bersifat persisten — satu Customer memiliki tepat satu cart aktif sepanjang waktu.
- **Actor yang terlibat:**
  - `Customer` — satu-satunya role yang memiliki dan mengelola cart
  - `System (Order Service)` — meng-clear cart setelah payment sukses
- **Fitur/modul yang dependen:**
  - **Product** — validasi ketersediaan dan harga produk saat add to cart
  - **Order & Payment** — trigger clear cart setelah transaksi selesai
- **Out of scope:**
  - Cart untuk role `Pegawai` dan `Admin` — tidak ada
  - Guest cart (tanpa login) — tidak didukung
  - Pemilihan attribute produk (suhu, ukuran, dll) — dilakukan di modul Order saat checkout
  - Manajemen stok — stok tidak dikurangi saat add to cart, hanya saat payment sukses
  - Batas maksimal quantity per item maupun total item dalam cart

---

## 2. Authorization & Access Control

| Operasi                                    | Public | Customer | Pegawai | Admin | Order Service (Internal) |
|--------------------------------------------|:------:|:--------:|:-------:|:-----:|:------------------------:|
| GET cart milik sendiri                     | ✗      | ✓        | ✗       | ✗     | ✗                        |
| POST add item ke cart                      | ✗      | ✓        | ✗       | ✗     | ✗                        |
| PATCH update quantity item                 | ✗      | ✓        | ✗       | ✗     | ✗                        |
| DELETE remove satu item dari cart          | ✗      | ✓        | ✗       | ✗     | ✗                        |
| DELETE clear semua item (oleh Customer)    | ✗      | ✓        | ✗       | ✗     | ✗                        |
| DELETE clear item spesifik (internal)      | ✗      | ✗        | ✗       | ✗     | ✓                        |

**Catatan:**
- Semua endpoint cart yang diakses Customer wajib melewati middleware Golang yang mengecek `is_active` di `public.users` (sesuai arsitektur User BR — mitigasi celah akun disabled).
- Customer hanya bisa mengakses cart milik dirinya sendiri. `cart.user_id` harus selalu dicocokkan dengan `user_id` dari JWT.
- Mekanisme clear cart dibedakan tegas:
  1. `DELETE /cart/items` → endpoint **Customer** untuk menghapus semua item cart milik sendiri.
  2. `DELETE /internal/cart/items` → endpoint **internal** untuk dipanggil Order Service (hapus item spesifik berdasarkan `item_ids`).
- Endpoint internal `DELETE /internal/cart/items` **tidak** melewati middleware JWT user; autentikasinya menggunakan shared internal API key pada header:
  `X-Internal-Api-Key: <secret>`.
- `is_verified` dan `phone_number` **tidak** menjadi pre-condition untuk mengelola cart. Validasi ini dilakukan saat checkout di modul Order.
- **Klarifikasi routing:** `DELETE /cart/items/:item_id` (hapus satu item) dan `DELETE /cart/items` (hapus semua) adalah dua endpoint berbeda pada path yang hampir identik. Pastikan router Golang mendaftarkan keduanya secara eksplisit dan urutan registrasinya benar.
- **Warning implementasi (fase coding):** karena path mirip, pastikan request ke `/cart/items` tidak salah terbaca sebagai route `/:item_id` (dan sebaliknya).

---

## 3. Validation Rules

### Cart Item

| Field        | Tipe    | Required | Constraint                                                       |
|--------------|---------|----------|------------------------------------------------------------------|
| `product_id` | UUID    | ✓        | Harus exist di tabel `products`, tidak soft-deleted              |
| `quantity`   | integer | ✓        | Min 1, tidak ada batas maksimal                                  |

**Batasan kontrak Cart terkait opsi produk:**
- Cart item **tidak** menyimpan atribut pilihan final Customer (mis. `temperature`, `sizes`, `sugar_levels`, dll).
- Payload Cart hanya memuat identitas item (`product_id`) dan `quantity`.
- Pemilihan atribut final dilakukan saat checkout di modul Order.

**Catatan khusus:**
- `quantity` pada operasi **add** adalah jumlah yang ingin ditambahkan, bukan quantity final. Jika item sudah ada di cart, `quantity` lama + `quantity` baru = quantity akhir.
- `quantity` pada operasi **update** adalah nilai final yang diinginkan (bukan delta). Jika dikirim `quantity: 0`, trapping sebagai request hapus item — tolak dengan `VALIDATION_ERROR`.
- Tidak ada field attribute produk (suhu, ukuran, dll) di cart item. Ini adalah keputusan kontrak API: Cart hanya menampung item + quantity, sedangkan pilihan atribut final wajib dikirim saat checkout di modul Order.

---

## 4. Business Rules per Operasi

### 4.1 GET /cart — Ambil Cart Milik Sendiri

**Deskripsi:** Mengambil isi cart aktif milik Customer yang sedang login, beserta status terkini setiap item.

**Pre-conditions:**
- Request terautentikasi dengan role `Customer`.
- `is_active = true` di `public.users`.

**Happy Path:**
1. Validasi autentikasi dan role Customer.
2. Ambil `cart` milik user berdasarkan `user_id` dari JWT.
3. Jika cart belum pernah dibuat, return cart kosong (bukan error).
4. Untuk setiap cart item, join dengan tabel `products` untuk mendapatkan data terkini: `name`, `price`, `image_url`, `status`, `deleted_at`.
5. Tandai setiap item dengan field `is_available`:
   - `is_available: false` jika product `status = unavailable`, `status = out_of_stock`, atau `deleted_at IS NOT NULL`.
   - `is_available: true` untuk kondisi lainnya.
6. Hitung `subtotal` per item (`price × quantity`) dan `grand_total` hanya dari item yang `is_available: true`.
7. Return data cart beserta summary.

**Sad Path & Edge Cases:**

| Kondisi                                      | Behavior Sistem                                      | HTTP Status |
|----------------------------------------------|------------------------------------------------------|-------------|
| Role bukan Customer                          | Return forbidden                                     | 403         |
| `is_active = false`                          | Return `ACCOUNT_DISABLED`                            | 403         |
| Cart belum pernah dibuat                     | Return cart kosong `{ items: [], grand_total: 0 }`   | 200         |
| Beberapa item sudah unavailable/deleted      | Item tetap tampil dengan `is_available: false`       | 200         |
| DB error                                     | Log error, return error                              | 500         |

**Post-conditions:** Tidak ada perubahan state.

**Catatan penting:**
- `grand_total` di response hanya bersifat **indikatif**. Harga final yang mengikat dihitung ulang di modul Order saat checkout, bukan dari nilai ini.
- Status item di cart **tidak di-cache** — selalu di-join real-time ke tabel `products` agar status terkini selalu akurat.

---

### 4.2 POST /cart/items — Add Item ke Cart

**Deskripsi:** Menambahkan produk ke cart. Jika produk sudah ada di cart, quantity akan di-increment. Jika cart belum ada, cart baru dibuat otomatis.

**Pre-conditions:**
- Request terautentikasi dengan role `Customer`.
- `is_active = true` di `public.users`.

**Happy Path:**
1. Validasi autentikasi dan role Customer.
2. Validasi format dan keberadaan `product_id` (UUID, harus exist, tidak soft-deleted).
3. Validasi `quantity` (integer, min 1).
4. Cek status product:
   - Jika `status = unavailable` atau `deleted_at IS NOT NULL` → tolak dengan `PRODUCT_UNAVAILABLE`.
   - Jika `status = out_of_stock` → tolak dengan `PRODUCT_OUT_OF_STOCK`.
5. Cek apakah cart untuk user ini sudah ada:
   - Jika belum → buat record `cart` baru untuk user ini.
6. Cek apakah `product_id` sudah ada di `cart_items` milik user:
   - Jika sudah ada → increment `quantity` sebesar nilai yang dikirim.
   - Jika belum ada → insert `cart_item` baru.
7. Semua operasi di atas dalam satu DB transaction.
8. Return isi cart terbaru (sama seperti response GET /cart).

**Sad Path & Edge Cases:**

| Kondisi                                        | Behavior Sistem                                  | HTTP Status |
|------------------------------------------------|--------------------------------------------------|-------------|
| Role bukan Customer                            | Return forbidden                                 | 403         |
| `is_active = false`                            | Return `ACCOUNT_DISABLED`                        | 403         |
| `product_id` format bukan UUID                 | Return `VALIDATION_ERROR`                        | 400         |
| `quantity` < 1 atau bukan integer              | Return `VALIDATION_ERROR`                        | 400         |
| Product tidak ditemukan atau soft-deleted      | Return `PRODUCT_NOT_FOUND`                       | 404         |
| Product status `unavailable`                   | Return `PRODUCT_UNAVAILABLE`                     | 422         |
| Product status `out_of_stock`                  | Return `PRODUCT_OUT_OF_STOCK`                    | 422         |
| Product berubah jadi `out_of_stock` setelah item ada di cart | Item lama tetap ada dengan `is_available: false`; add baru ditolak | 422 |
| DB error                                       | Rollback transaction, log error                  | 500         |

**Post-conditions:**
- Cart item tersimpan atau ter-update di DB.
- `updated_at` pada cart ter-update.

---

### 4.3 PATCH /cart/items/:item_id — Update Quantity Item

**Deskripsi:** Mengubah quantity sebuah item di cart menjadi nilai yang diinginkan (bukan delta/increment).

**Pre-conditions:**
- Request terautentikasi dengan role `Customer`.
- `is_active = true` di `public.users`.
- Cart item dengan `item_id` tersebut milik user yang sedang login.

**Happy Path:**
1. Validasi autentikasi dan role Customer.
2. Validasi format `item_id` (UUID).
3. Pastikan cart item exist dan `cart.user_id` cocok dengan `user_id` dari JWT.
4. Validasi `quantity` (integer, min 1).
5. Update `quantity` di DB.
6. Return isi cart terbaru.

**Sad Path & Edge Cases:**

| Kondisi                                        | Behavior Sistem                                  | HTTP Status |
|------------------------------------------------|--------------------------------------------------|-------------|
| Role bukan Customer                            | Return forbidden                                 | 403         |
| `is_active = false`                            | Return `ACCOUNT_DISABLED`                        | 403         |
| `item_id` format bukan UUID                    | Return `VALIDATION_ERROR`                        | 400         |
| `quantity` = 0 atau negatif                    | Return `VALIDATION_ERROR` (gunakan DELETE untuk hapus) | 400    |
| Cart item tidak ditemukan                      | Return `CART_ITEM_NOT_FOUND`                     | 404         |
| Cart item milik user lain                      | Return `CART_ITEM_NOT_FOUND` (jangan bocorkan 403) | 404      |
| DB error                                       | Rollback transaction, log error                  | 500         |

**Catatan:** Update quantity diperbolehkan meskipun item sedang berstatus `is_available: false` — user mungkin ingin menyesuaikan quantity sambil menunggu produk kembali tersedia.

**Post-conditions:**
- `quantity` cart item ter-update di DB.
- `updated_at` pada cart ter-update.

---

### 4.4 DELETE /cart/items/:item_id — Hapus Item dari Cart

**Deskripsi:** Menghapus satu item dari cart secara permanen (hard delete).

**Pre-conditions:**
- Request terautentikasi dengan role `Customer`.
- `is_active = true` di `public.users`.
- Cart item dengan `item_id` tersebut milik user yang sedang login.

**Happy Path:**
1. Validasi autentikasi dan role Customer.
2. Validasi format `item_id` (UUID).
3. Pastikan cart item exist dan `cart.user_id` cocok dengan `user_id` dari JWT.
4. Hard delete record `cart_item` dari DB.
5. Update `updated_at` pada cart.
6. Return 200 dengan pesan sukses (tanpa return isi cart).

**Sad Path & Edge Cases:**

| Kondisi                                        | Behavior Sistem                                  | HTTP Status |
|------------------------------------------------|--------------------------------------------------|-------------|
| Role bukan Customer                            | Return forbidden                                 | 403         |
| `is_active = false`                            | Return `ACCOUNT_DISABLED`                        | 403         |
| `item_id` format bukan UUID                    | Return `VALIDATION_ERROR`                        | 400         |
| Cart item tidak ditemukan                      | Return `CART_ITEM_NOT_FOUND`                     | 404         |
| Cart item milik user lain                      | Return `CART_ITEM_NOT_FOUND` (jangan bocorkan eksistensi data user lain) | 404 |
| DB error                                       | Log error, return error                          | 500         |

**Post-conditions:**
- Record `cart_item` dihapus permanen dari DB.
- `updated_at` pada cart ter-update.
- Jika cart menjadi kosong setelah delete, record `cart` tetap ada (tidak dihapus).

---

### 4.5 DELETE /cart/items — Hapus Semua Item Sekaligus (Customer)

**Deskripsi:** Menghapus seluruh item dari cart milik Customer yang sedang login sekaligus. Record `cart` tetap dipertahankan.

**Pre-conditions:**
- Request terautentikasi dengan role `Customer`.
- `is_active = true` di `public.users`.

**Happy Path:**
1. Validasi autentikasi dan role Customer.
2. Ambil `cart` milik user berdasarkan `user_id` dari JWT.
3. Hard delete semua `cart_items` yang berelasi ke cart tersebut dalam satu transaction.
4. Record `cart` tetap dipertahankan.
5. Update `updated_at` pada cart.
6. Return 200 sukses.

**Sad Path & Edge Cases:**

| Kondisi                                        | Behavior Sistem                                                   | HTTP Status |
|------------------------------------------------|-------------------------------------------------------------------|-------------|
| Role bukan Customer                            | Return forbidden                                                  | 403         |
| `is_active = false`                            | Return `ACCOUNT_DISABLED`                                         | 403         |
| Cart belum pernah dibuat atau sudah kosong     | Return 200 tetap (idempotent)                                     | 200         |
| DB error                                       | Rollback transaction, log error                                   | 500         |

**Post-conditions:**
- Semua `cart_items` milik user dihapus permanen.
- Record `cart` tetap ada dan siap digunakan kembali.
- `updated_at` pada cart ter-update.

---

### 4.6 DELETE /internal/cart/items — Clear Item Tertentu (Internal, dipanggil Order Service)

**Deskripsi:** Menghapus item-item spesifik dari cart setelah payment sukses. Dipanggil oleh Order Service dengan mengirimkan daftar `item_id` yang berhasil dibayar. Jika semua item di cart dibayar, cart menjadi kosong — record `cart` tetap dipertahankan.

**Pre-conditions:**
- Request berasal dari Order Service dengan header `X-Internal-Api-Key` yang valid.
- Daftar `item_id` tidak boleh kosong.

**Request Body:**
```json
{
  "item_ids": ["uuid-1", "uuid-2", "uuid-3"]
}
```

**Happy Path:**
1. Validasi header `X-Internal-Api-Key`.
2. Validasi `item_ids` — array tidak boleh kosong, setiap elemen harus format UUID.
3. Hard delete semua `cart_items` yang `id`-nya ada dalam daftar `item_ids` dalam satu transaction.
4. Item yang ada di daftar tapi sudah tidak exist di DB diabaikan (tidak error — idempotent).
5. Record `cart` tetap dipertahankan.
6. Update `updated_at` pada cart yang terdampak.
7. Return 200 sukses ke Order Service.

**Sad Path & Edge Cases:**

| Kondisi                                              | Behavior Sistem                                       | HTTP Status |
|------------------------------------------------------|-------------------------------------------------------|-------------|
| Header `X-Internal-Api-Key` tidak valid / tidak ada  | Return `UNAUTHORIZED`                                 | 401         |
| `item_ids` kosong atau tidak dikirim                 | Return `VALIDATION_ERROR`                             | 400         |
| Salah satu `item_id` format bukan UUID               | Return `VALIDATION_ERROR`                             | 400         |
| Semua `item_id` tidak ditemukan di DB                | Return 200 tetap (idempotent — dianggap sudah di-clear) | 200       |
| DB error                                             | Rollback transaction, log error, return error         | 500         |

**Post-conditions:**
- `cart_items` yang ada dalam daftar `item_ids` dihapus permanen.
- Record `cart` tetap ada dan siap digunakan untuk order berikutnya.
- `updated_at` pada cart ter-update.

**Catatan idempotency:** Jika Order Service memanggil endpoint ini dua kali untuk `item_ids` yang sama (misal karena retry after failure), harus tetap return 200. Item yang sudah terhapus di iterasi pertama cukup diabaikan di iterasi kedua.

---

## 5. Caching Policy

Tidak ada caching untuk modul Cart.

**Alasan:**
- Data cart bersifat highly personal dan berubah sering — cache hit rate akan rendah.
- Status item di cart harus selalu real-time (join ke `products`) agar flag `is_available` akurat.
- Volume data per cart kecil — query langsung ke DB tidak memberikan bottleneck yang signifikan.

---

## 6. External Service & Side Effects

| Trigger                        | Service / Action                                                      | Sync/Async |
|--------------------------------|-----------------------------------------------------------------------|------------|
| Payment sukses (dari Order)    | Order Service memanggil `DELETE /internal/cart/items` dengan daftar `item_id` yang dibayar | Sync |

**Catatan:**
- Tidak ada integrasi ke external service lain (email, notifikasi, CDN, dsb) yang di-trigger oleh operasi cart.
- Clear cart dilakukan **sync** oleh Order Service — Order Service menunggu konfirmasi sukses dari Cart sebelum menyelesaikan flow order. Jika clear cart gagal, Order Service harus menangani retry-nya.
- Jika Customer membayar **sebagian item**, hanya item yang dibayar yang dihapus dari cart. Sisa item tetap ada.
- Jika Customer membayar **semua item**, seluruh item terhapus dan cart menjadi kosong — record `cart` tetap dipertahankan.
- Stok produk **tidak** dikurangi di modul Cart. Pengurangan stok adalah tanggung jawab modul Order/Payment setelah transaksi selesai.

---

## 7. Response Format

Mengikuti format standar yang sudah didefinisikan di Product BR.

### Success — GET cart & operasi yang return cart
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

> **Catatan:** `grand_total` hanya menjumlahkan item dengan `is_available: true`. Item yang `is_available: false` tetap ditampilkan namun tidak masuk kalkulasi.

### Success — DELETE satu item (4.4) & DELETE semua item oleh Customer (4.5)
```json
{
  "success": true,
  "message": "Item berhasil dihapus dari cart"
}
```

### Success — DELETE /internal/cart/items (4.6, response ke Order Service)
```json
{
  "success": true,
  "message": "Cart items cleared"
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

| Code                    | HTTP Status | Trigger                                                              |
|-------------------------|:-----------:|----------------------------------------------------------------------|
| `VALIDATION_ERROR`      | 400         | Format field tidak valid, quantity < 1, dsb                          |
| `PRODUCT_NOT_FOUND`     | 404         | `product_id` tidak exist atau sudah soft-deleted                     |
| `CART_ITEM_NOT_FOUND`   | 404         | `item_id` tidak exist atau bukan milik user yang login               |
| `PRODUCT_UNAVAILABLE`   | 422         | Product status `unavailable` — tidak bisa di-add ke cart             |
| `PRODUCT_OUT_OF_STOCK`  | 422         | Product status `out_of_stock` — tidak bisa di-add ke cart            |
| `ACCOUNT_DISABLED`      | 403         | `is_active = false` di `public.users`                                |
| `FORBIDDEN`             | 403         | Role tidak memiliki izin untuk operasi ini                           |
| `UNAUTHORIZED`          | 401         | Token tidak ada, tidak valid, atau (khusus internal) service token invalid |
| `INTERNAL_SERVER_ERROR` | 500         | Error tidak terduga di server                                        |

---

## 8. Database & Transaction Policy

- **Transaction scope:** Operasi add item (yang bisa membuat cart baru sekaligus insert item), update quantity, delete item, dan clear cart semuanya wajib menggunakan DB transaction.
- **Hard delete:** Cart item menggunakan hard delete. Tidak ada soft delete — cart item tidak memiliki nilai historis. Data historis order tersimpan di modul Order, bukan di cart.
- **Kolom audit:** `created_at`, `updated_at` pada tabel `cart` dan `cart_items`.
- **Locking strategy:** Tidak diperlukan untuk saat ini.

### Desain Tabel (Referensi)

**Tabel `carts`:**

| Kolom        | Tipe        | Keterangan                                       |
|--------------|-------------|--------------------------------------------------|
| `id`         | UUID        | Primary key                                      |
| `user_id`    | UUID        | Foreign key ke `public.users`, unique (1 user = 1 cart) |
| `created_at` | TIMESTAMPTZ | Auto set                                         |
| `updated_at` | TIMESTAMPTZ | Auto update setiap ada perubahan item            |

**Tabel `cart_items`:**

| Kolom        | Tipe        | Keterangan                                       |
|--------------|-------------|--------------------------------------------------|
| `id`         | UUID        | Primary key                                      |
| `cart_id`    | UUID        | Foreign key ke `carts`                           |
| `product_id` | UUID        | Foreign key ke `products`                        |
| `quantity`   | INTEGER     | Min 1, tidak ada batas maksimal                  |
| `created_at` | TIMESTAMPTZ | Auto set                                         |
| `updated_at` | TIMESTAMPTZ | Auto update                                      |

> **Unique constraint:** `(cart_id, product_id)` — satu produk hanya boleh muncul satu baris per cart. Increment quantity ditangani di aplikasi, bukan via insert duplikat.

---

## 9. Logging & Monitoring

**Yang wajib di-log:**
- Setiap operasi mutasi (add / update / delete item, clear cart) beserta `user_id` dan `product_id` / `item_id` terkait
- Panggilan masuk ke endpoint internal `DELETE /internal/cart/items` beserta daftar `item_id` yang di-clear
- Error 500 dengan full stack trace (level: ERROR)
- Akses yang ditolak karena role tidak sesuai atau autentikasi internal gagal (level: WARNING)

**Yang tidak perlu di-log:**
- GET cart yang sukses
- Operasi clear cart yang idempotent (cart sudah kosong saat dipanggil)

---

## 10. Open Questions

- [x] **Mekanisme autentikasi internal untuk endpoint `DELETE /internal/cart/items`** → **Resolved:** Pakai shared internal API key via header `X-Internal-Api-Key`, disimpan sebagai environment variable di Cart Service dan Order Service.
- [x] **Apakah perlu endpoint hapus semua item sekaligus oleh Customer?** → **Resolved:** Ya, perlu. Didefinisikan sebagai `DELETE /cart/items` (Section 4.5).
- [x] **Jika product kembali `available` setelah sempat `out_of_stock`, apakah `is_available` otomatis pulih?** → **Resolved:** Ya, otomatis — karena `is_available` di-resolve real-time dari status product saat GET cart dipanggil. Tidak ada state yang perlu diubah di tabel `cart_items`.
- [x] **Apakah perlu notifikasi ke Customer saat item di cart berubah jadi unavailable?** → **Resolved:** Tidak perlu. Customer mengetahui status item saat membuka cart.
- [x] **Apakah cart item yang `is_available: false` diblokir saat checkout?** → **Resolved:** Ya, diblokir. Modul Order wajib memvalidasi bahwa semua item yang disubmit untuk checkout berstatus `is_available: true` — validasi ini dilakukan di sisi Order BR, bukan di Cart BR.

