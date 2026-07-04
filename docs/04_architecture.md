# System Architecture

## High-Level Overview

```
┌─────────────────────┐         HTTPS/REST          ┌──────────────────────┐
│   Flutter App        │  ─────────────────────────▶ │   Express API         │
│   (Admin, Riverpod)   │  ◀───────────────────────── │   (Node.js)           │
└─────────────────────┘         JSON responses       └───────────┬──────────┘
                                                                   │
                                                        Mongoose ODM
                                                                   │
                                                                   ▼
                                                        ┌──────────────────────┐
                                                        │   MongoDB Atlas       │
                                                        └──────────────────────┘
```

## Backend Layers

```
Route (HTTP verbs + path)
   → Middleware (auth check, validation, audit logging)
      → Controller (parses request, calls service, shapes response)
         → Service (business logic — e.g. payroll.service.js does the actual pay calculation)
            → Model (Mongoose schema, DB read/write)
```

Keeping business logic in the **service layer** (not the controller) means the payroll calculation, attendance aggregation, and loan deduction logic are unit-testable independent of HTTP.

## Auth Flow

```
1. Admin submits email/password → POST /api/auth/login
2. Server verifies password hash → issues accessToken (15m) + refreshToken (stored in DB, 7-30d)
3. Client stores accessToken in memory, refreshToken in secure storage (flutter_secure_storage)
4. Client sends accessToken on every request via Authorization header
5. On 401 (expired access token) → client calls POST /api/auth/refresh with refreshToken
6. Server validates + rotates refreshToken → issues new accessToken + refreshToken
7. If refreshToken is invalid/revoked → force client back to login screen
```

## Payroll Generation Flow

```
Admin taps "Generate Salary" for Employee X, Month Y
   → POST /api/salary/generate { employeeId, month }
      → payroll.service.js:
         1. Query attendance for employeeId + month → sum regularHours, overtimeHours
         2. Check completeness → build warnings[] if days missing
         3. Pull hourlyRate from employees, overtimeMultiplier from company_settings
         4. Sum bonuses, fines for employeeId + month
         5. Check for active loan → create loan_installments entry, get loanDeduction
         6. Compute grossSalary, netSalary
         7. Save salary doc (status: "Finalized")
         8. Snapshot into salary_history
      ← Response: { salaryId, netSalary, payslipUrl, warnings }
   → Client shows result, offers "View/Download Payslip"
```

## Export/Report Flow

Reports and payslips are generated **on-demand**, not pre-computed — `export.service.js` queries the relevant collections at request time and streams a PDF (`pdfkit`) or Excel (`exceljs`) file. This keeps the DB free of redundant "report" documents; the only pre-computed/frozen data is `salary_history.snapshot`, which exists specifically so past payslips don't drift.

## Why This Split

- **Service layer isolation** → payroll math can be unit tested without spinning up Express or MongoDB (mock the DB calls).
- **Snapshot in `salary_history`** → the one deliberate exception to "derive everything on read," because payslips are a legal/financial record that must not silently change.
- **Audit middleware** → sits between controller and service for write operations, so every mutating action is logged consistently instead of scattered `logAudit()` calls per controller.
