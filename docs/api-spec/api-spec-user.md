# API Spec — User Module (Coffee Shop Backend)

## Base Information

- **Base URL (Golang API):** `/api/v1`
- **Auth Provider:** Supabase Auth (JWT)
- **Response Format:** standar `success/data/message` dan `success:false/error`

---

## 1. Architecture & Routing

### Endpoint melalui Golang API
- `POST /auth/register`
- `GET /users/profile`
- `PATCH /users/profile`

### Endpoint langsung ke Supabase (bukan Golang API)
- Login: `signInWithPassword`
- Logout: `signOut`
- Refresh token: auto-refresh SDK
- Forgot password: `resetPasswordForEmail`
- Reset password: `updateUser` (OTP flow)
- Resend verification: `resend`

> **Catatan:** Pembuatan akun `Pegawai` dan `Admin` **tidak melalui endpoint publik**, hanya via Supabase Dashboard.

---

## 2. Security & Authorization

- Semua endpoint protected wajib header:
  - `Authorization: Bearer <supabase_jwt>`
- Middleware Golang wajib validasi:
  - JWT valid
  - user ada di `public.users`
  - `is_active = true`
  - role sesuai endpoint

### Konvensi status auth
- **401 `UNAUTHORIZED`**: token tidak ada / tidak valid / expired
- **403 `FORBIDDEN`**: token valid, tapi role tidak punya akses
- **403 `ACCOUNT_DISABLED`**: akun nonaktif (`is_active = false`)

---

## 3. User Object Schema (Response)

```json
{
  "id": "uuid",
  "email": "user@email.com",
  "full_name": "Radit",
  "role": "Customer|Pegawai|Admin",
  "is_verified": true,
  "is_active": true,
  "phone_number": "+628123456789",
  "avatar_url": "https://<supabase-storage-url>/..."
}
```

> **Source of truth API:** `public.users`

---

## 4. Endpoint Specifications

## 4.1 Register

### `POST /api/v1/auth/register`

Mendaftarkan akun baru dengan role default **Customer**.

### Auth
- Public (tanpa JWT)

### Request Body
```json
{
  "email": "user@email.com",
  "password": "minimum8chars",
  "full_name": "Nama Lengkap"
}
```

### Validation Rules
- `email`: required, format email valid
- `password`: required, minimal 8 karakter
- `full_name`: required, minimal 3 karakter, maksimal 50 karakter

### Business Flow
1. Validasi payload di Golang.
2. Call Supabase Auth untuk create account, sertakan `full_name` di metadata.
3. Trigger PostgreSQL sinkronisasi ke `public.users`:
   - `role = Customer`
   - `is_verified = false`
   - `is_active = true`
4. Supabase mengirim email verifikasi.
5. Return response sukses.

### Success Response
- **HTTP 201**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "email": "user@email.com",
    "full_name": "Radit",
    "role": "Customer",
    "is_verified": false,
    "is_active": true,
    "avatar_url": null,
    "phone_number": null
  },
  "message": "Registrasi berhasil. Silakan verifikasi email."
}
```

### Error Responses
- **400** `VALIDATION_ERROR`
- **400** `EMAIL_ALREADY_EXISTS`
- **500** `PROFILE_NOT_SYNCED`
- **500** `INTERNAL_SERVER_ERROR`

---

## 4.2 Get Profile

### `GET /api/v1/users/profile`

Mengambil profil user dari `public.users`.

### Auth
- JWT required
- Role: `Customer`, `Pegawai`, `Admin`

### Behavior
- Mengembalikan profil milik user login (`sub` dari JWT).

> Catatan: BR menyebut Admin bisa akses semua user, namun endpoint ini tidak memiliki parameter target user. Untuk fase ini, endpoint ini diperlakukan sebagai **get my profile**.

### Success Response
- **HTTP 200**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "email": "admin@cafe.com",
    "full_name": "Admin Cafe",
    "role": "Admin",
    "is_verified": true,
    "is_active": true,
    "avatar_url": "https://...",
    "phone_number": "+628123456789"
  },
  "message": "Profil berhasil diambil"
}
```

### Error Responses
- **401** `UNAUTHORIZED`
- **403** `ACCOUNT_DISABLED`
- **500** `PROFILE_NOT_SYNCED`
- **500** `INTERNAL_SERVER_ERROR`

---

## 4.3 Update Profile

### `PATCH /api/v1/users/profile`

Update parsial profil user.

### Auth
- JWT required
- Role: `Customer`, `Pegawai`, `Admin`

### Request Body (all optional)
```json
{
  "full_name": "Nama Baru",
  "phone_number": "+628111222333",
  "avatar_url": "https://<project>.supabase.co/storage/v1/object/public/avatars/..."
}
```

### Validation Rules
- `full_name` (optional): min 3, max 50
- `phone_number` (optional): format E.164, max 15 digit
- `avatar_url` (optional): URL valid, domain Supabase Storage project yang sama
- Field selain whitelist (`full_name`, `phone_number`, `avatar_url`) diabaikan

### Security Rule (Privilege Escalation Protection)
Field berikut **tidak boleh bisa diubah** via endpoint ini:
- `role`
- `is_active`
- `is_verified`
- `email`

### Success Response
- **HTTP 200**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "email": "user@email.com",
    "full_name": "Nama Baru",
    "role": "Customer",
    "is_verified": true,
    "is_active": true,
    "phone_number": "+628111222333",
    "avatar_url": "https://..."
  },
  "message": "Profil berhasil diperbarui"
}
```

### Error Responses
- **400** `VALIDATION_ERROR`
- **401** `UNAUTHORIZED`
- **403** `ACCOUNT_DISABLED`
- **500** `INTERNAL_SERVER_ERROR`

---

## 5. Standard Response Format

### Success
```json
{
  "success": true,
  "data": {},
  "message": "Operasi berhasil"
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

### Validation Error
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

---

## 6. Error Code Catalog (User Module)

| Error Code              | HTTP Status | Keterangan |
|-------------------------|-------------|------------|
| `VALIDATION_ERROR`      | 400         | Payload tidak valid |
| `EMAIL_ALREADY_EXISTS`  | 400         | Email sudah terdaftar |
| `UNAUTHORIZED`          | 401         | Token tidak ada/tidak valid/expired |
| `FORBIDDEN`             | 403         | Role tidak diizinkan |
| `ACCOUNT_DISABLED`      | 403         | `is_active = false` |
| `EMAIL_UNVERIFIED`      | 403         | Dipakai lintas modul saat transaksi |
| `PHONE_NUMBER_REQUIRED` | 403         | Dipakai lintas modul saat transaksi |
| `PROFILE_NOT_SYNCED`    | 500         | Gagal sinkron auth.users -> public.users |
| `INTERNAL_SERVER_ERROR` | 500         | Error server tidak terduga |

---

## 7. Non-Functional & Implementation Notes

- **Celah arsitektur yang disadari:** akun disabled tetap bisa login Supabase dan dapat JWT, tapi akan diblokir saat akses endpoint Golang.
- **Mitigasi wajib:** semua endpoint bisnis harus melewati middleware pengecekan `is_active`.
- **RLS Supabase:** disarankan membatasi akses langsung user disabled ke data.
- **Token TTL:** default Supabase relatif pendek (mis. ~1 jam), membantu pembatasan akses lanjutan.
```