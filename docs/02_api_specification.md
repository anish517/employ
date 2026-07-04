# API Specification — Detailed

Base URL: `/api`
Auth: all routes except `/auth/login` and `/auth/refresh` require `Authorization: Bearer <access_token>`.

**Standard error shape** (see `06_validation_error_handling.md` for full reference):
```json
{
  "success": false,
  "error": { "code": "VALIDATION_ERROR", "message": "Email is required", "details": {} }
}
```

**Standard success shape:**
```json
{ "success": true, "data": { }, "meta": { } }
```

---

## Auth

### `POST /api/auth/login`
Request:
```json
{ "email": "admin@company.com", "password": "••••••" }
```
Response `200`:
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOi...",
    "refreshToken": "8f3a...",
    "admin": { "id": "...", "fullName": "...", "email": "..." }
  }
}
```
`401` if credentials invalid.

### `POST /api/auth/refresh`
Request: `{ "refreshToken": "..." }`
Response: new `accessToken` (+ rotated `refreshToken`).

### `POST /api/auth/logout`
Request: `{ "refreshToken": "..." }` → revokes it.

### `POST /api/auth/change-password`
Request: `{ "currentPassword": "...", "newPassword": "..." }`

---

## Employees

### `POST /api/employees`
Request:
```json
{
  "fullName": "Ram Bahadur",
  "gender": "Male",
  "dateOfBirth": "1998-04-12",
  "phone": "9800000000",
  "email": "ram@company.com",
  "address": "Biratnagar, Nepal",
  "emergencyContact": { "name": "Sita", "phone": "9811111111", "relation": "Spouse" },
  "departmentId": "664f...",
  "designationId": "664f...",
  "joiningDate": "2026-07-01",
  "employmentType": "Full-time",
  "hourlyRate": 350
}
```
Validation: `fullName`, `phone`, `email`, `departmentId`, `designationId`, `hourlyRate` required. `email` unique. `hourlyRate` must be > 0.
Response `201`: created employee with auto-generated `employeeId` (e.g. `EMP-0001`).

### `GET /api/employees?search=&department=&status=&page=&limit=`
Response includes `meta: { total, page, totalPages }`.

### `PUT /api/employees/:id` — partial update, same validation rules as create for any field present.

### `DELETE /api/employees/:id` — soft delete (sets `status: "Inactive"`, `deletedAt`) if the employee has any historical records; hard delete only allowed if no attendance/salary/leave history exists.

---

## Attendance

### `POST /api/attendance/mark`
```json
{ "employeeId": "...", "date": "2026-07-04", "status": "Present", "checkIn": "09:05", "checkOut": "17:30" }
```
Server computes `workingHours`, `overtimeHours`, `isLate` from `company_settings.workingHours` — client does not send these.

### `POST /api/attendance/bulk-mark`
```json
{ "date": "2026-07-04", "entries": [ { "employeeId": "...", "status": "Present" }, { "employeeId": "...", "status": "Absent" } ] }
```

### `GET /api/attendance/monthly?month=2026-07&employeeId=`
Returns a calendar-style array of daily statuses for one or all employees.

---

## Leave

### `POST /api/leave-requests`
```json
{ "employeeId": "...", "leaveTypeId": "...", "startDate": "2026-07-10", "endDate": "2026-07-12", "reason": "Family event" }
```
Validation: rejects if it overlaps an existing Pending/Approved request for the same employee (see business rules doc). `totalDays` computed server-side.

### `PUT /api/leave-requests/:id/approve` / `/reject`
No body required; sets `status` and `reviewedAt`.

### `GET /api/leave-requests/balance/:employeeId`
Response:
```json
{ "data": [ { "leaveType": "Annual", "maxDays": 18, "used": 4, "remaining": 14 } ] }
```

---

## Payroll

### `POST /api/salary/generate`
```json
{ "employeeId": "...", "month": "2026-07" }
```
Server flow:
1. Sum `attendance.workingHours` / `overtimeHours` for that employee/month.
2. Check attendance completeness — if missing days on non-holiday working days, response includes a `warnings` array but still allows generation unless the admin explicitly wants a hard block.
3. Compute pay per business rules, apply active loan EMI, sum bonuses/fines for the month.
4. Save `salary` doc, snapshot it into `salary_history`.

Response `201`:
```json
{
  "success": true,
  "data": { "salaryId": "...", "netSalary": 45250, "payslipUrl": "/api/salary/.../payslip" },
  "warnings": ["3 working days missing attendance records"]
}
```
`409` if a `salary` record for that employee/month already exists (must void/regenerate explicitly, not silently overwrite).

### `GET /api/salary/:id/payslip`
Streams a generated PDF (see `docx`/PDF generation notes — uses `pdfkit`).

### `GET /api/salary-history?employeeId=&year=`
Returns list of past months with `netSalary`, `status`, and a `payslipUrl` for download — this is the "history" screen.

---

## Bonuses / Fines / Loans / Expenses / Holidays

These follow standard CRUD with the fields defined in the schema doc. Key validation notes:
- `bonuses`/`fines`: `amount` must be > 0, `month` required (format `YYYY-MM`).
- `loans`: `emiAmount` must be ≤ `totalAmount`; reject creation of a second `Active` loan for an employee who already has one (one active loan at a time, unless you decide otherwise).
- `expenses`: `amount` > 0, `category` must be one of the enum values.
- `holidays`: reject duplicate `date` + `type` combination.

---

## Reports

All `/api/reports/*` endpoints accept `?format=pdf|excel|csv` and common filters (`from`, `to`, `departmentId`, `employeeId` where applicable). They read from existing collections — no separate "report" data is stored.
