# Dokumentasi Business Rules: Coffee Shop Backend
**Modul:** User Management & Authentication (Fase 1)
**Infrastruktur:** Supabase (Auth, Database, Storage) + Golang (API Service)
**Arsitektur Toko:** Single Branch

---

## 0. Authorization & Access Control

### Definisi Role
| Role | Deskripsi |
| :--- | :--- |
| `Customer` | Pelanggan umum. Default saat registrasi. |
| `Pegawai` | Kasir / Barista. Dibuat oleh Admin, tidak bisa self-register. |
| `Admin` | Pengelola toko. Akses penuh ke semua endpoint. |

> **Aturan Penting:** Role `Pegawai` dan `Admin` **tidak bisa didaftarkan melalui endpoint publik** (`POST /auth/register`). Pembuatan akun `Pegawai` dan `Admin` dilakukan **langsung via Supabase Dashboard** oleh Admin — tidak ada endpoint Golang untuk ini. Ini adalah keputusan arsitektur yang disengaja (out of scope API service).

### Matriks Akses & Routing Endpoint

> **Legenda Routing:**
> - 🟦 **Supabase langsung** — Frontend memanggil Supabase SDK/API langsung, tidak melalui Golang
> - 🟩 **Golang API** — Frontend memanggil Golang API (`/api/v1/...`)

| Endpoint | Routing | Public | Customer | Pegawai | Admin |
| :--- | :---: | :---: | :---: | :---: | :---: |
| Register | 🟩 `POST /api/v1/auth/register` | ✓ | ✗ | ✗ | ✗ |
| Login | 🟦 Supabase `signInWithPassword` | ✓ | ✗ | ✗ | ✗ |
| Logout | 🟦 Supabase `signOut` | ✗ | ✓ | ✓ | ✓ |
| Refresh Token | 🟦 Supabase auto-refresh | ✗ | ✓ | ✓ | ✓ |
| Forgot Password | 🟦 Supabase `resetPasswordForEmail` | ✓ | ✗ | ✗ | ✗ |
| Reset Password | 🟦 Supabase `updateUser` (via OTP token) | ✓ | ✗ | ✗ | ✗ |
| Resend Verification | 🟦 Supabase `resend` | ✗ | ✓ | ✓ | ✓ |
| Get Profile | 🟩 `GET /api/v1/users/profile` | ✗ | ✓ (milik sendiri) | ✓ (milik sendiri) | ✓ (semua user) |
| Update Profile | 🟩 `PATCH /api/v1/users/profile` | ✗ | ✓ (milik sendiri) | ✓ (milik sendiri) | ✓ (semua user) |

### Catatan Authorization
- Setiap request ke endpoint Golang terproteksi **wajib** menyertakan `Authorization: Bearer <JWT>`.
- Middleware Golang memvalidasi JWT dari Supabase, lalu mengecek `is_active` dan mengambil `role` dari `public.users`.
- User hanya bisa mengakses/mengubah data milik dirinya sendiri, kecuali Admin.

### ⚠️ Celah Arsitektur & Mitigasinya

Karena Login dilakukan langsung ke Supabase (bypass Golang), ada celah yang harus dipahami:

```
User login via Supabase → JWT diterbitkan SEBELUM Golang bisa cek is_active
→ Akun disabled tetap bisa mendapat JWT yang valid
→ Pemblokiran baru terjadi saat JWT dipakai hit endpoint Golang
```

**Mitigasi wajib:**
1. **Semua endpoint bisnis** (cart, order, payment, dll) **wajib** melewati middleware Golang yang mengecek `is_active`. Tidak boleh ada endpoint bisnis yang bisa diakses dengan JWT tanpa middleware ini.
2. **Supabase RLS (Row Level Security)** di tabel `public.users` harus dikonfigurasi agar user yang `is_active = false` tidak bisa baca/tulis data langsung ke Supabase (antisipasi jika frontend bypass Golang).
3. Access Token Supabase memiliki TTL pendek (default 1 jam) — akun disabled otomatis ter-blokir penuh setelah token expired tanpa perlu aksi tambahan.

---

## 1. Source of Truth Policy

Untuk menghindari ambiguitas, berikut adalah sumber data resmi untuk setiap field:

| Field | Source of Truth | Catatan |
| :--- | :--- | :--- |
| `id` | `auth.users` | UUID dari Supabase |
| `email` | `auth.users` | Dikelola penuh oleh Supabase Auth |
| `full_name` | `public.users` | Di-sync via trigger dari `user_metadata` |
| `role` | `public.users` | Dikelola oleh Golang API |
| `is_verified` | `public.users` | Di-sync via trigger dari `auth.users.email_confirmed_at` |
| `is_active` | `public.users` | Dikelola oleh Golang API (soft delete) |
| `avatar_url` | `public.users` | Dikelola oleh Golang API |
| `phone_number` | `public.users` | Dikelola oleh Golang API |

> **Aturan Penting:** API Golang **selalu** membaca data dari `public.users`. Tidak ada query langsung ke `auth.users` kecuali untuk keperluan autentikasi yang ditangani Supabase SDK.

---

## 2. Sub-fitur: Registrasi (Sign Up)

**Aturan Main:** Pendaftaran wajib menyertakan Email, Password, dan Full Name. Nama lengkap akan disisipkan ke dalam `user_metadata` saat memanggil Supabase Auth. Data akan disinkronisasi ke `public.users` menggunakan PostgreSQL Trigger. Endpoint ini hanya menghasilkan akun dengan role `Customer`.

### A. Happy Path
1. Klien mengirimkan *payload* (Email, Password, Full Name) ke API Golang.
2. Golang memvalidasi payload. Jika valid, diteruskan ke Supabase Auth.
3. Supabase Auth memvalidasi format dan keamanan kredensial, lalu menyimpan `full_name` di kolom *metadata*.
4. Akun berhasil dibuat di `auth.users` Supabase.
5. *Trigger* PostgreSQL berjalan otomatis: mengekstrak `id`, `email`, dan `full_name` (dari *metadata*), lalu mengeset `role = 'Customer'`, `is_verified = false`, dan `is_active = true` ke tabel `public.users`.
6. Supabase otomatis mengirimkan email verifikasi.
7. Klien menerima respons sukses (HTTP 201).

### B. Sad Path & Edge Cases
* **Kasus 1: Payload Tidak Lengkap / Tidak Valid**
    * *Kondisi:* Klien tidak mengirimkan `full_name`, atau format email salah, atau password kurang dari 8 karakter.
    * *Penanganan:* Validasi di sisi Golang menolak *request* (HTTP 400 `VALIDATION_ERROR`) sebelum diteruskan ke Supabase.
* **Kasus 2: Email Sudah Terdaftar**
    * *Kondisi:* User mendaftar dengan email yang sudah ada di sistem.
    * *Penanganan:* Supabase mengembalikan error. API meneruskan HTTP 400 dengan `error_code: EMAIL_ALREADY_EXISTS`.
* **Kasus 3: Kegagalan Trigger Database**
    * *Kondisi:* Akun tercipta di `auth.users`, namun *trigger* gagal melakukan *insert* ke `public.users`.
    * *Penanganan:* Saat login, *middleware* Golang tidak menemukan profil di `public.users`. API mengembalikan HTTP 500 `PROFILE_NOT_SYNCED`.

---

## 3. Sub-fitur: Login & Sesi (Sign In)

**Aturan Main:** Login dilakukan **langsung ke Supabase** dari frontend menggunakan `signInWithPassword`. Golang **tidak terlibat** di flow ini. Pemblokiran akun disabled terjadi di middleware Golang saat JWT dipakai hit endpoint bisnis — bukan saat login.

### A. Happy Path
1. Frontend memanggil Supabase `signInWithPassword` dengan Email dan Password.
2. Supabase memvalidasi kredensial dan merilis *Access Token* (JWT) dan *Refresh Token*.
3. Frontend menyimpan token.
4. Saat user hit endpoint Golang pertama kali, middleware mengecek `is_active` di `public.users`.
5. Jika `is_active = true`, request diproses normal.

### B. Sad Path & Edge Cases
* **Kasus 1: Kredensial Salah**
    * *Kondisi:* Email atau password tidak cocok.
    * *Penanganan:* Supabase mengembalikan error langsung ke frontend. Frontend menampilkan pesan generik tanpa menyebutkan bagian yang salah (mencegah user enumeration).
* **Kasus 2: Akun Dinonaktifkan (Soft Deleted)**
    * *Kondisi:* Login berhasil di Supabase (JWT diterbitkan), namun `is_active = false` di `public.users`.
    * *Penanganan:* JWT tetap diterima Supabase. Middleware Golang memblokir saat JWT dipakai dengan HTTP 403 `ACCOUNT_DISABLED`. Ini adalah perilaku yang disengaja — lihat ⚠️ Celah Arsitektur di Section 0.
* **Kasus 3: Token Expired**
    * *Kondisi:* JWT kedaluwarsa saat aplikasi digunakan.
    * *Penanganan:* Supabase SDK di frontend melakukan *refresh token* secara otomatis. Jika refresh gagal, frontend redirect ke halaman login.

---

## 4. Sub-fitur: Logout

**Aturan Main:** Logout dilakukan **langsung ke Supabase** dari frontend menggunakan `signOut`. Golang tidak terlibat. Supabase me-revoke Refresh Token sehingga sesi tidak bisa diperpanjang. Access Token yang sudah beredar dibiarkan expired secara alami.

### A. Happy Path
1. Frontend memanggil Supabase `signOut`.
2. Supabase me-revoke refresh token aktif.
3. Frontend menghapus token dari local storage.

### B. Sad Path & Edge Cases
* **Kasus 1: Token Sudah Expired Saat Logout**
    * *Kondisi:* User mencoba logout dengan access token yang sudah expired.
    * *Penanganan:* Supabase tetap memproses `signOut` dengan sukses. Frontend tetap hapus token lokal.

---

## 5. Sub-fitur: Verifikasi Email & Otorisasi Transaksi

**Aturan Main:** Status verifikasi disimpan di kolom `is_verified` pada tabel `public.users`. User wajib memiliki status `is_verified = true` untuk dapat melakukan pemesanan.

### A. Happy Path
1. User mengklik tautan verifikasi di email dari Supabase.
2. Kolom `email_confirmed_at` di tabel `auth.users` terisi oleh Supabase.
3. *Trigger* PostgreSQL mendeteksi perubahan ini dan otomatis mengupdate `is_verified = true` di `public.users`.
4. User melakukan pemesanan. Middleware Golang mengecek `is_verified` dari `public.users`.
5. Karena bernilai `true`, pesanan diproses.

### B. Sad Path & Edge Cases
* **Kasus 1: Tautan Verifikasi Expired**
    * *Kondisi:* User menggunakan tautan yang sudah kedaluwarsa.
    * *Penanganan:* Frontend menampilkan pesan error dari Supabase dan tombol "Kirim Ulang Email" yang memanggil endpoint resend-verification.
* **Kasus 2: Belum Verifikasi tapi Mencoba Pesan**
    * *Kondisi:* User memanggil `POST /api/v1/orders`.
    * *Penanganan:* Middleware Golang mendapati `is_verified = false`. API menolak *request* dengan HTTP 403 `EMAIL_UNVERIFIED`.
* **Kasus 3: `phone_number` Kosong tapi Mencoba Pesan**
    * *Kondisi:* User memanggil `POST /api/v1/orders` tapi kolom `phone_number` di `public.users` masih `null`.
    * *Penanganan:* Middleware Golang mendapati `phone_number = null`. API menolak *request* dengan HTTP 403 `PHONE_NUMBER_REQUIRED`. Client harus arahkan user ke halaman update profil terlebih dahulu.

---

## 6. Sub-fitur: Resend Verification Email

**Aturan Main:** Dilakukan **langsung ke Supabase** dari frontend menggunakan `resend`. Rate limit dihandle di sisi Supabase (konfigurasi di Supabase Dashboard), bukan di Golang.

### A. Happy Path
1. Frontend memanggil Supabase `resend` dengan type `signup`.
2. Supabase mengirim ulang email verifikasi.
3. Frontend menampilkan konfirmasi ke user.

### B. Sad Path & Edge Cases
* **Kasus 1: Email Sudah Verified**
    * *Kondisi:* User yang sudah `is_verified = true` mencoba resend.
    * *Penanganan:* Supabase mengembalikan error. Frontend menampilkan pesan `EMAIL_ALREADY_VERIFIED`.
* **Kasus 2: Rate Limit Tercapai**
    * *Kondisi:* User terlalu sering request dalam waktu singkat.
    * *Penanganan:* Supabase mengembalikan error rate limit. Frontend menampilkan pesan dan waktu retry.

---

## 7. Sub-fitur: Forgot Password & Reset Password

**Aturan Main:** Seluruh flow reset password dilakukan **langsung ke Supabase** dari frontend. Golang tidak terlibat sama sekali.

### A. Happy Path — Forgot Password
1. Frontend memanggil Supabase `resetPasswordForEmail` dengan email user.
2. Supabase mengirim email reset password.
3. Frontend menampilkan konfirmasi "Email telah dikirim" — **tidak peduli email terdaftar atau tidak** (mencegah user enumeration, Supabase handle ini secara default).

### B. Happy Path — Reset Password
1. User mengklik tautan di email, diarahkan ke halaman reset password di frontend.
2. Supabase menyertakan token OTP di URL.
3. Frontend memanggil Supabase `updateUser` dengan password baru menggunakan token tersebut.
4. Supabase memvalidasi token dan mengupdate password.
5. User diminta login ulang dengan password baru.

### C. Sad Path & Edge Cases
* **Kasus 1: Token Reset Expired atau Sudah Dipakai**
    * *Kondisi:* User menggunakan tautan reset yang sudah kedaluwarsa atau sudah pernah dipakai.
    * *Penanganan:* Supabase menolak. Frontend menampilkan pesan error dan opsi "Kirim ulang email reset".
* **Kasus 2: Password Baru Sama dengan Password Lama**
    * *Kondisi:* User memasukkan password yang identik dengan sebelumnya.
    * *Penanganan:* Dibiarkan — tidak menjadi concern bisnis. Tidak perlu validasi tambahan.

---

## 8. Sub-fitur: Manajemen Profil & Avatar (Update Profile)

**Aturan Main:** Pembaruan data menggunakan metode HTTP PATCH. Pengunggahan avatar dilakukan secara terpisah ke Supabase Storage, lalu URL-nya disimpan ke database. User hanya bisa update profil milik dirinya sendiri.

### A. Happy Path
1. Klien mengunggah *file* gambar langsung ke Supabase Storage (bucket: `avatars`).
2. Supabase mengembalikan *public URL* dari gambar tersebut.
3. Klien mengirim request PATCH ke Golang API membawa payload yang ingin diupdate.
4. Backend memvalidasi format, binding hanya ke field yang diizinkan, dan memperbarui baris di `public.users`.
5. API mengembalikan profil terbaru (HTTP 200).

### B. Sad Path & Edge Cases
* **Kasus 1: Format File Avatar Ditolak**
    * *Kondisi:* User mencoba mengunggah file selain `jpg`, `jpeg`, `png`, `webp` ke bucket `avatars`. Ukuran maksimal: 2MB.
    * *Penanganan:* Storage Policies di Supabase menolak *upload* (HTTP 400).
* **Kasus 2: Mencoba Eskalasi Role (Privilege Escalation)**
    * *Kondisi:* Klien menyisipkan `{"role": "Admin"}` atau `{"is_active": true}` dalam *payload*.
    * *Penanganan:* API secara ketat hanya melakukan binding pada field yang diizinkan (`full_name`, `phone_number`, `avatar_url`). Field lain diabaikan sepenuhnya.
* **Kasus 3: Zero-Value Override pada Partial Update**
    * *Kondisi:* Payload *update* tidak menyertakan field tertentu (misal hanya kirim nama, tidak kirim nomor telepon).
    * *Penanganan:* API Golang menggunakan tipe data *pointer* pada *struct* payload (contoh: `PhoneNumber *string`). Field yang bernilai `nil` (tidak dikirim) tidak akan menimpa data yang sudah ada di DB.
* **Kasus 4: Ganti Email**
    * *Kondisi:* User mencoba mengubah email melalui endpoint ini.
    * *Penanganan:* Field `email` tidak termasuk dalam binding yang diizinkan. Perubahan email tidak di-scope dalam modul ini — memerlukan flow verifikasi ulang yang terpisah.

---

## 9. Sub-fitur: Soft Delete Akun

**Aturan Main:** Tidak ada hard delete. Akun yang dinonaktifkan hanya diset `is_active = false`. Data tetap tersimpan di database. Nonaktifasi akun dilakukan langsung via Supabase Dashboard oleh Admin — tidak ada endpoint Golang untuk ini.

### A. Happy Path
1. Admin membuka Supabase Dashboard dan mengupdate kolom `is_active = false` di tabel `public.users` secara manual.
2. Akun Supabase Auth **tidak** dihapus — hanya `is_active` di `public.users` yang diubah.
3. Sesi aktif user akan diblokir di middleware Golang saat request berikutnya masuk.

### B. Sad Path & Edge Cases
* **Kasus 1: User yang Sudah Nonaktif Login Kembali**
    * *Kondisi:* User dengan `is_active = false` mencoba login.
    * *Penanganan:* Supabase Auth tetap merilis JWT (karena akun di `auth.users` masih aktif). Middleware Golang mendeteksi `is_active = false` dan mengembalikan HTTP 403 `ACCOUNT_DISABLED`.
* **Kasus 2: Reactive Akun**
    * *Kondisi:* Admin ingin mengaktifkan kembali akun yang sudah dinonaktifkan.
    * *Penanganan:* Update `is_active = true` di `public.users`. Tidak perlu aksi di Supabase Auth.

---

## 10. Payload Constraints (Input Validation)

> Hanya endpoint Golang yang didokumentasikan di sini. Endpoint yang langsung ke Supabase mengikuti validasi bawaan Supabase SDK.

### A. Register (`POST /api/v1/auth/register`) — Golang
| Field | Tipe Data | Aturan |
| :--- | :--- | :--- |
| `email` | String | Required, valid email format |
| `password` | String | Required, min 8 char |
| `full_name` | String | Required, min 3 char, max 50 char |

### B. Update Profile (`PATCH /api/v1/users/profile`) — Golang
*Gunakan pointer (`*`) di Golang struct untuk semua field.*
| Field | Tipe Data | Aturan |
| :--- | :--- | :--- |
| `full_name` | *String | Optional, min 3 char, max 50 char (jika dikirim) |
| `phone_number` | *String | Optional di profil, **wajib terisi sebelum bisa checkout**. Format E.164 (misal: +6281...), max 15 digit |
| `avatar_url` | *String | Optional, valid URL format, harus dari domain Supabase Storage project ini |

---

## 11. Standardisasi Format Response

> **Konvensi lintas modul:** User mengikuti format response yang sama dengan Product/Cart/Order.

### A. Format Sukses (200 OK / 201 Created)
```json
{
  "success": true,
  "data": {
    "id": "uuid-v4",
    "email": "user@email.com",
    "full_name": "Radit",
    "role": "Customer",
    "is_verified": true,
    "avatar_url": "https://..."
  },
  "message": "Operasi berhasil"
}
```

### B. Format Error (40x / 50x)
```json
{
  "success": false,
  "error": {
    "code": "SNAKE_CASE_ERROR_CODE",
    "message": "Deskripsi error yang human-readable"
  }
}
```

### C. Format Error Validation (400)
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Input tidak valid",
    "details": {
      "full_name": "Nama lengkap wajib diisi"
    }
  }
}
```

### D. Daftar Error Code — Golang API

| Error Code | HTTP Status | Trigger |
| :--- | :---: | :--- |
| `VALIDATION_ERROR` | 400 | Payload tidak lengkap atau format salah (Register, Update Profile) |
| `EMAIL_ALREADY_EXISTS` | 400 | Registrasi dengan email yang sudah terdaftar |
| `UNAUTHORIZED` | 401 | Token tidak ada / tidak valid / expired saat hit endpoint Golang |
| `FORBIDDEN` | 403 | Role tidak memiliki izin akses endpoint |
| `ACCOUNT_DISABLED` | 403 | Akun dengan `is_active = false` mencoba hit endpoint Golang |
| `EMAIL_UNVERIFIED` | 403 | User belum verifikasi email tapi mencoba order |
| `PHONE_NUMBER_REQUIRED` | 403 | User belum mengisi phone_number tapi mencoba order |
| `PROFILE_NOT_SYNCED` | 500 | Trigger DB gagal sync ke `public.users` |

> Catatan: format lama (`status`, `errors`, `error_code`) dinyatakan deprecated dan tidak dipakai untuk endpoint baru.
---

## 12. Keputusan Arsitektur (Resolved)

Dicatat di sini supaya AI tidak mempertanyakan atau mengubah keputusan ini:

| Keputusan | Pilihan | Alasan |
| :--- | :--- | :--- |
| Routing Login, Logout, Refresh Token | Langsung ke Supabase dari frontend | Pure auth flow, tidak ada business logic tambahan |
| Routing Forgot/Reset Password | Langsung ke Supabase dari frontend | Pure Supabase flow |
| Routing Resend Verification | Langsung ke Supabase dari frontend | Pure Supabase flow, rate limit dihandle Supabase |
| Routing Register | Via Golang | Perlu validasi `full_name` sebelum ke Supabase |
| Routing Get/Update Profile | Via Golang | Perlu cek privilege escalation & pointer binding |
| Pembuatan akun Pegawai/Admin | Via Supabase Dashboard manual | Tidak perlu endpoint tambahan, lebih simple |
| Logout dari semua device | Tidak ada fitur ini | Out of scope |
| Notifikasi nonaktifasi akun | Tidak ada | Out of scope |
| Audit log perubahan role | Tidak ada | Out of scope |
| `phone_number` saat checkout | **Wajib terisi** | Diperlukan untuk keperluan notifikasi order |
| Mitigasi celah akun disabled | Supabase RLS + middleware wajib di semua endpoint bisnis | JWT tetap diterbitkan Supabase meski akun disabled |