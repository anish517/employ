# Authentication & Security

## Token Strategy

- **Access token:** JWT, short-lived (15 minutes). Signed with `JWT_ACCESS_SECRET`. Sent as `Authorization: Bearer <token>` on every request.
- **Refresh token:** opaque random string (not a JWT), long-lived (7–30 days), stored hashed in `refresh_tokens` with `expiresAt` and `revoked`. Sent only on `/api/auth/refresh` and `/api/auth/logout`.
- **Rotation:** every successful `/auth/refresh` issues a new refresh token and revokes the old one (detects token theft — if a revoked token is reused, revoke the entire token family and force re-login).
- **Logout:** revokes the specific refresh token. "Logout everywhere" = revoke all `refresh_tokens` for that admin.

## Password Handling

- Hash with `bcrypt` (cost factor 10–12). Never store or log plaintext passwords.
- `change-password` requires the current password to be re-verified before accepting a new one.
- Minimum password policy: 8+ characters — enforce client-side (Flutter) and server-side.

## Rate Limiting

- Apply rate limiting on `/api/auth/login` (e.g. 5 attempts per 15 minutes per IP) using `express-rate-limit`, to slow down brute-force attempts against a single-admin system where the account is a single point of failure.

## Audit Logging

- Write to `audit_logs` on: employee create/update/delete, leave approve/reject, salary generation, loan creation, any deletion.
- Store `adminId`, `action`, `collectionName`, `documentId`, and a small `metadata` diff (not the full document) to keep entries lightweight.
- Audit logs are append-only — no update/delete endpoints for this collection.

## Transport & Environment

- Enforce HTTPS in production (handled by the hosting platform — Render/Railway provide this by default).
- Secrets (`JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`, `MONGODB_URI`) live only in `.env` / platform environment variables — never committed to git (`.env` in `.gitignore`).
- CORS: restrict `Access-Control-Allow-Origin` to the actual Flutter web origin (if using Flutter Web) or disable CORS entirely if the API is only ever called from a mobile app.

## Input Validation

- Validate and sanitize all input server-side (e.g. with `joi` or `zod`) even though there's only one trusted admin user — this protects against malformed data corrupting payroll calculations, not just malicious input.
