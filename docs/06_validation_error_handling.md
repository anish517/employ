# Validation & Error Handling Reference

## Standard Response Shapes

**Success:**
```json
{ "success": true, "data": { }, "meta": { } }
```

**Error:**
```json
{ "success": false, "error": { "code": "VALIDATION_ERROR", "message": "human-readable message", "details": { "field": "hourlyRate", "issue": "must be greater than 0" } } }
```

## Standard Error Codes

| Code | HTTP Status | Meaning |
|---|---|---|
| `VALIDATION_ERROR` | 400 | Request body failed schema validation |
| `UNAUTHORIZED` | 401 | Missing/invalid/expired access token |
| `FORBIDDEN` | 403 | Valid token but action not permitted (reserved for future use) |
| `NOT_FOUND` | 404 | Resource doesn't exist |
| `CONFLICT` | 409 | Duplicate resource (e.g. salary already generated for that month) |
| `RATE_LIMITED` | 429 | Too many requests (login attempts) |
| `SERVER_ERROR` | 500 | Unhandled exception |

All errors are caught centrally by `error.middleware.js` — controllers throw typed errors (e.g. `throw new ApiError(409, 'CONFLICT', 'Salary already generated for this month')`) rather than formatting responses inline.

## Field Validation Rules by Entity

**Employee**
- `fullName`: required, 2–100 chars
- `email`: required, valid email format, unique
- `phone`: required, 10 digits (adjust regex to Nepal format if needed)
- `hourlyRate`: required, number > 0
- `departmentId` / `designationId`: required, must reference existing documents
- `dateOfBirth`: required, must result in age ≥ 16
- `joiningDate`: required, cannot be in the future

**Leave Request**
- `startDate` ≤ `endDate`
- No overlap with existing Pending/Approved request for the same employee
- `leaveTypeId` must exist

**Attendance**
- `date` required, cannot be in the future
- `checkOut` must be after `checkIn` if both provided
- One record per `(employeeId, date)` — enforced via unique compound index, not just app logic

**Salary Generation**
- No existing `salary` doc for `(employeeId, month)` — else `409 CONFLICT`
- `employeeId` must be `status: "Active"` (can't generate payroll for an inactive employee, unless explicitly reactivated for backpay — handle as a deliberate exception, not the default path)

**Loan**
- `emiAmount` ≤ `totalAmount`
- No second `Active` loan for the same employee (unless you decide to support concurrent loans)

**Bonus / Fine**
- `amount` > 0
- `month` matches `YYYY-MM` format

## Client-Side (Flutter) Validation

Mirror the same rules in form validators so the admin gets instant feedback rather than waiting for a server round-trip — but never rely on client-side validation alone; the server is the source of truth since this is where payroll integrity matters most.
