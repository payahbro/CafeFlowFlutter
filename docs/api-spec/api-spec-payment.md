# API Spec — Payment Module (Coffee Shop Backend)

## Base Information

- **Base URL:** `/api/v1`
- **Gateway:** Midtrans Snap + Midtrans Webhook + Midtrans Refund API
- **Main flow:** Customer initiate payment -> Midtrans process -> webhook update payment -> trigger Order internal status update

---

## 1. Authorization Matrix

| Endpoint | Public | Customer | Pegawai | Admin | Midtrans |
|---|:---:|:---:|:---:|:---:|:---:|
| `POST /payments/initiate` | ❌ | ✅ (order milik sendiri) | ❌ | ❌ | ❌ |
| `POST /payments/webhook` | ✅* | ❌ | ❌ | ❌ | ✅ |
| `GET /payments/order/:order_id` | ❌ | ✅ (order milik sendiri) | ❌ | ✅ | ❌ |
| `GET /payments` | ❌ | ❌ | ❌ | ✅ | ❌ |
| `GET /payments/me` | ❌ | ✅ | ❌ | ❌ | ❌ |
| `POST /payments/:payment_id/refund` | ❌ | ❌ | ❌ | ✅ | ❌ |

\* Webhook public tanpa JWT, tapi wajib validasi `signature_key` Midtrans.

---

## 2. Payment Data Schema

```json
{
  "payment_id": "uuid",
  "order_id": "uuid",
  "order_number": "ORD-20250405-001",
  "status": "PENDING_PAYMENT",
  "amount": 68000,
  "payment_method": "gopay",
  "midtrans_transaction_id": "midtrans-txn-id",
  "midtrans_order_id": "PAY-<payment_id>-<unix_timestamp>",
  "snap_redirect_url": "https://app.midtrans.com/snap/v2/vtweb/...",
  "refund_amount": null,
  "refund_reason": null,
  "refunded_at": null,
  "created_at": "2025-04-05T10:00:00Z",
  "updated_at": "2025-04-05T10:02:00Z"
}
```

### Payment Status Enum
- `PENDING_PAYMENT`
- `SUCCESS`
- `FAILED`
- `EXPIRED`
- `REFUNDED`

---

## 3. Validation Rules

## 3.1 Initiate Payment
Request body:
```json
{
  "order_id": "uuid"
}
```

Rules:
- `order_id` required, UUID valid
- order harus milik user login
- order status harus `PENDING`
- order belum expired (`expires_at` belum lewat)

## 3.2 Webhook Midtrans
Validasi utama:
- `signature_key` valid
- `order_id` Midtrans format parseable: `PAY-{payment_id}-{unix_timestamp}`
- field Midtrans minimal:
  - `transaction_status`
  - `fraud_status` (jika ada)
  - `gross_amount`
  - `status_code`
  - `transaction_id`
  - `payment_type`

## 3.3 Refund (Admin)
Request body:
```json
{
  "reason": "Pesanan tidak bisa diproses",
  "refund_amount": 50000
}
```

Rules:
- `payment_id` path: UUID valid
- `reason`: required, min 5, max 255
- `refund_amount` optional:
  - jika kosong = full refund
  - jika ada: `>0` dan `<= payment.amount`
- payment wajib status `SUCCESS`
- single-refund policy (1 payment maksimal 1 refund)

---

## 4. Endpoint Specifications

## 4.1 POST `/api/v1/payments/initiate` — Initiate Payment

### Auth
- JWT required
- Role: Customer only
- User preconditions:
  - `is_active = true`
  - `is_verified = true`
  - `phone_number` terisi

### Business Scenarios

### A) Reuse existing active payment
Jika sudah ada payment status `PENDING_PAYMENT` untuk order tsb, return Snap URL existing (tanpa create baru, tanpa call Midtrans lagi).

### B) Create new payment
Jika tidak ada active payment (atau payment sebelumnya `FAILED/EXPIRED`):
1. Generate `payment_id` baru
2. Build `midtrans_order_id = PAY-{payment_id}-{unix_timestamp}`
3. Call Midtrans Snap API
4. Simpan payment `PENDING_PAYMENT` + `snap_redirect_url`
5. Return redirect URL

### Request Body
```json
{
  "order_id": "uuid"
}
```

### Success Response (200)
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

### Errors
- `400 VALIDATION_ERROR`
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `403 ACCOUNT_DISABLED`
- `403 EMAIL_UNVERIFIED`
- `403 PHONE_NUMBER_REQUIRED`
- `404 ORDER_NOT_FOUND`
- `422 ORDER_NOT_PAYABLE`
- `422 ORDER_EXPIRED`
- `502 PAYMENT_GATEWAY_ERROR`
- `500 INTERNAL_SERVER_ERROR`

---

## 4.2 POST `/api/v1/payments/webhook` — Midtrans Notification Handler

### Auth
- Public endpoint
- Wajib signature validation:
  - `SHA512(order_id + status_code + gross_amount + server_key)`

### Midtrans -> Internal Status Mapping

| transaction_status | fraud_status | internal_status |
|---|---|---|
| `settlement` | `accept` | `SUCCESS` |
| `capture` | `accept` | `SUCCESS` |
| `capture` | `challenge` | `SUCCESS`* |
| `pending` | any | `PENDING_PAYMENT` |
| `deny` | any | `FAILED` |
| `cancel` | any | `FAILED` |
| `expire` | any | `EXPIRED` |
| `failure` | any | `FAILED` |
| `refund` | any | `REFUNDED` |

\* sesuai kebijakan BR saat ini.

### Business Flow
1. Validate signature.
2. Parse `payment_id` dari `order_id` Midtrans.
3. Find payment by `payment_id`.
4. Idempotency check:
   - jika status sudah final (`SUCCESS/FAILED/EXPIRED/REFUNDED`) -> skip update.
5. Update status + `payment_method` + `midtrans_transaction_id`.
6. Jika status jadi `SUCCESS`:
   - call Order internal endpoint: `PATCH /internal/orders/{order_id}/status`
   - jika gagal: simpan outbox event retry async.
7. **Selalu return 200 ke Midtrans** (termasuk sad path) untuk hindari retry spam.

### Success Response ke Midtrans
- **HTTP 200**
```json
{
  "success": true,
  "message": "OK"
}
```

### Internal Sad Paths (tetap 200 ke Midtrans)
- Signature invalid -> log warning, ignore
- Parse gagal -> log error, ignore
- payment not found -> log error, ignore
- DB update gagal -> log error
- Order service gagal -> log error + enqueue outbox retry

---

## 4.3 GET `/api/v1/payments/order/:order_id` — Payment Detail by Order

### Auth
- JWT required
- Role: Customer or Admin

### Path Param
- `order_id` UUID required

### Role Behavior
- Customer: hanya boleh order milik sendiri, return **payment terbaru saja** (single object)
- Admin: return **semua history payment** untuk order tsb (array, newest first)

### Success Response (Customer, 200)
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
    "snap_redirect_url": null,
    "refund_amount": null,
    "refund_reason": null,
    "refunded_at": null,
    "created_at": "2025-04-05T10:00:00Z",
    "updated_at": "2025-04-05T10:02:30Z"
  },
  "message": "Payment berhasil diambil"
}
```

### Success Response (Admin, 200)
```json
{
  "success": true,
  "data": [
    {
      "payment_id": "uuid-newest",
      "status": "SUCCESS"
    },
    {
      "payment_id": "uuid-old",
      "status": "EXPIRED"
    }
  ],
  "message": "Payment berhasil diambil"
}
```

### Errors
- `400 VALIDATION_ERROR`
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `403 ACCOUNT_DISABLED`
- `404 ORDER_NOT_FOUND`
- `404 PAYMENT_NOT_FOUND`

---

## 4.4 GET `/api/v1/payments` — List Payments (Admin)

### Auth
- JWT required
- Role: Admin only

### Query Parameters

| Param | Type | Required | Rules |
|---|---|---:|---|
| `cursor` | string | ❌ | opaque base64 |
| `direction` | enum | ❌ | `next|prev`, default `next` |
| `limit` | int | ❌ | default 10, max 50 |
| `status` | enum | ❌ | `PENDING_PAYMENT|SUCCESS|FAILED|EXPIRED|REFUNDED` |
| `order_id` | UUID | ❌ | filter by order |
| `user_id` | UUID | ❌ | filter by owner user |
| `date_from` | date | ❌ | `YYYY-MM-DD` |
| `date_to` | date | ❌ | `YYYY-MM-DD` |
| `method` | string | ❌ | e.g. `gopay`, `qris`, `bca_va` |

### Success Response (200)
```json
{
  "success": true,
  "data": [
    {
      "payment_id": "uuid",
      "order_id": "uuid",
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

### Errors
- `400 VALIDATION_ERROR`
- `400 INVALID_CURSOR`
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `403 ACCOUNT_DISABLED`

---

## 4.5 POST `/api/v1/payments/:payment_id/refund` — Refund (Admin)

### Auth
- JWT required
- Role: Admin only

### Path Param
- `payment_id` UUID required

### Request Body
```json
{
  "reason": "Pesanan tidak bisa diproses",
  "refund_amount": 68000
}
```

### Business Rules
- payment harus status `SUCCESS`
- belum pernah refund (`status != REFUNDED`)
- call Midtrans Refund API pakai `midtrans_transaction_id`
- jika berhasil:
  - insert `payment_refunds`
  - update `payments.status=REFUNDED` + refund aggregates
- status order **tidak diubah otomatis**

### Success Response (200)
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

### Errors
- `400 VALIDATION_ERROR`
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `403 ACCOUNT_DISABLED`
- `404 PAYMENT_NOT_FOUND`
- `422 PAYMENT_NOT_REFUNDABLE`
- `422 PAYMENT_ALREADY_REFUNDED`
- `502 PAYMENT_GATEWAY_ERROR`
- `500 INTERNAL_SERVER_ERROR`

---

## 4.6 GET `/api/v1/payments/me` — Customer Payment History

### Auth
- JWT required
- Role: Customer only

### Query Parameters

| Param | Type | Required | Rules |
|---|---|---:|---|
| `cursor` | string | ❌ | opaque base64 |
| `direction` | enum | ❌ | `next|prev`, default `next` |
| `limit` | int | ❌ | default 10, max 50 |
| `status` | enum | ❌ | `PENDING_PAYMENT|SUCCESS|FAILED|EXPIRED|REFUNDED` |
| `date_from` | date | ❌ | `YYYY-MM-DD` |
| `date_to` | date | ❌ | `YYYY-MM-DD` |

### Success Response (200)
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

### Errors
- `400 VALIDATION_ERROR`
- `400 INVALID_CURSOR`
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `403 ACCOUNT_DISABLED`

---

## 5. Standard Response Format

### Success (detail/object)
```json
{
  "success": true,
  "data": {},
  "message": "Operasi berhasil"
}
```

### Success (list + pagination)
```json
{
  "success": true,
  "data": [],
  "pagination": {
    "next_cursor": "base64_or_null",
    "prev_cursor": "base64_or_null",
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

---

## 6. Error Code Catalog (Payment)

| Code | HTTP | Trigger |
|---|:---:|---|
| `VALIDATION_ERROR` | 400 | input/query/path invalid |
| `INVALID_CURSOR` | 400 | cursor invalid |
| `UNAUTHORIZED` | 401 | token invalid/missing |
| `FORBIDDEN` | 403 | role tidak diizinkan |
| `ACCOUNT_DISABLED` | 403 | `is_active=false` |
| `EMAIL_UNVERIFIED` | 403 | customer belum verify |
| `PHONE_NUMBER_REQUIRED` | 403 | phone kosong |
| `ORDER_NOT_FOUND` | 404 | order tidak ditemukan/bukan milik customer |
| `PAYMENT_NOT_FOUND` | 404 | payment tidak ditemukan |
| `ORDER_NOT_PAYABLE` | 422 | status order bukan `PENDING` |
| `ORDER_EXPIRED` | 422 | order lewat `expires_at` |
| `PAYMENT_NOT_REFUNDABLE` | 422 | payment bukan `SUCCESS` |
| `PAYMENT_ALREADY_REFUNDED` | 422 | payment sudah refund |
| `PAYMENT_GATEWAY_ERROR` | 502 | Midtrans error/timeout |
| `INTERNAL_SERVER_ERROR` | 500 | server error |

---

## 7. Midtrans Webhook Contract Notes

### Signature validation
`SHA512(order_id + status_code + gross_amount + server_key)`

### Idempotency
- Jika payment sudah final (`SUCCESS/FAILED/EXPIRED/REFUNDED`) -> skip update, return 200.

### Webhook response policy
- Semua kondisi webhook **tetap return 200** ke Midtrans.
- Error internal cukup di-log + retry internal jika perlu.

---

## 8. Outbox, Retry, DLQ

Untuk kasus webhook `SUCCESS` tapi sync ke Order gagal:

1. Update payment ke `SUCCESS`
2. Tulis event ke outbox (dalam transaction DB yang sama)
3. Worker retry async (exponential backoff)
4. Lewat threshold -> pindah DLQ + kirim alert operasional
5. Sediakan manual replay untuk event DLQ

---

## 9. Database & Transaction Policy

## 9.1 Tables

### `payments`
- `id` UUID PK
- `order_id` UUID FK
- `status` enum
- `amount` int
- `payment_method` nullable
- `midtrans_order_id` unique
- `midtrans_transaction_id` nullable
- `snap_redirect_url` nullable
- `refund_amount` nullable
- `refund_reason` nullable
- `refunded_at` nullable
- `created_at`, `updated_at`

### `payment_refunds`
- `id` UUID PK
- `payment_id` UUID FK
- `midtrans_refund_id`
- `amount`
- `reason`
- `created_by` (admin_id)
- `created_at`

> Fase saat ini: single-refund policy (maks 1 refund per payment).

## 9.2 Transaction Rules
- Initiate create-payment: transactional
- Webhook update: transactional
- Refund: transactional
- Retry payment menghasilkan row payment baru (append-only), bukan overwrite lama
- Saat status final, `snap_redirect_url` di-null-kan

---

## 10. Logging & Monitoring

Wajib log:
- initiate payment (scenario reuse/new)
- webhook masuk + mapping result
- signature invalid (WARNING)
- status change payment
- gagal call Order service (ERROR + alert)
- Midtrans API failure (ERROR)
- Midtrans Refund failure (ERROR)
- webhook duplicate skipped (DEBUG)
- DB inconsistency post refund (CRITICAL)
- outbox threshold exceeded / DLQ count (ERROR/CRITICAL)

Tidak perlu log:
- GET payment sukses
- webhook pending yang tidak ubah state