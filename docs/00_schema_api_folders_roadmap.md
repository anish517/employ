# Employee Management System — Technical Documentation

**Type:** Admin-only Employment Management System
**Stack:** Flutter (Riverpod) · Node.js/Express · MongoDB · JWT Auth
**Scope:** Single-admin, no employee login

---

## 1. Project Overview

An admin-only HR and payroll management system covering employee records, attendance, leave, payroll, bonuses, fines, loans, expenses, holidays, and reporting. No employee-facing login — all data entry and approvals are performed by the admin.

---

## 2. Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter + Riverpod (state management), GoRouter (navigation) |
| Backend | Node.js + Express |
| Database | MongoDB (Mongoose ODM) |
| Auth | JWT (access + refresh tokens) |
| File Storage | Local / Cloudinary (profile photos) |
| PDF/Excel Export | `pdfkit` or `puppeteer` (PDF), `exceljs` (Excel) |
| Deployment | Render / Railway (API), MongoDB Atlas (DB) |

---

## 3. MongoDB Schema Design

Since MongoDB is document-based, some SQL-style join tables are replaced with references (`ObjectId`) or embedded sub-documents where the data is small and tightly coupled (e.g., salary components inside a payroll record).

### 3.1 `admins`
```js
{
  _id: ObjectId,
  fullName: String,
  email: String,        // unique
  passwordHash: String,
  profilePhoto: String,
  companyId: ObjectId,  // ref -> company_settings
  createdAt: Date,
  updatedAt: Date
}
```

### 3.2 `refresh_tokens`
```js
{
  _id: ObjectId,
  adminId: ObjectId,     // ref -> admins
  token: String,
  expiresAt: Date,
  revoked: Boolean,
  createdAt: Date
}
```

### 3.3 `departments`
```js
{
  _id: ObjectId,
  name: String,          // "HR", "IT", "Finance"...
  description: String,
  createdAt: Date,
  updatedAt: Date
}
```

### 3.4 `designations`
```js
{
  _id: ObjectId,
  title: String,          // "Software Engineer"
  departmentId: ObjectId, // ref -> departments (optional, if designation is dept-specific)
  createdAt: Date,
  updatedAt: Date
}
```

### 3.5 `employees`
```js
{
  _id: ObjectId,
  employeeId: String,      // auto-generated, e.g. "EMP-0001"
  fullName: String,
  profilePhoto: String,
  gender: String,          // "Male" | "Female" | "Other"
  dateOfBirth: Date,
  phone: String,
  email: String,
  address: String,
  emergencyContact: {
    name: String,
    phone: String,
    relation: String
  },
  departmentId: ObjectId,  // ref -> departments
  designationId: ObjectId, // ref -> designations
  joiningDate: Date,
  employmentType: String,  // "Full-time" | "Part-time" | "Contract"
  hourlyRate: Number,       // hourly wage, used for monthly payroll calculation
  status: String,          // "Active" | "Inactive"
  createdAt: Date,
  updatedAt: Date
}
```
**Indexes:** `employeeId` (unique), `email` (unique), `departmentId`, `status`

### 3.6 `attendance` (daily summary — one doc per employee per day)
```js
{
  _id: ObjectId,
  employeeId: ObjectId,   // ref -> employees
  date: Date,
  status: String,         // "Present" | "Absent" | "Half Day" | "Leave" | "Holiday"
  checkIn: Date,
  checkOut: Date,
  workingHours: Number,
  overtimeHours: Number,
  isLate: Boolean,
  createdAt: Date,
  updatedAt: Date
}
```
**Indexes:** compound unique `(employeeId, date)`

### 3.7 `attendance_logs` (raw punches — supports multiple check-ins/outs per day)
```js
{
  _id: ObjectId,
  employeeId: ObjectId,
  timestamp: Date,
  type: String,           // "check-in" | "check-out"
  source: String,         // "manual" | "biometric" | "app"
  createdAt: Date
}
```

### 3.8 `leave_types`
```js
{
  _id: ObjectId,
  name: String,           // "Annual", "Sick", "Casual", "Emergency"
  maxDaysPerYear: Number,
  isPaid: Boolean
}
```

### 3.9 `leave_requests`
```js
{
  _id: ObjectId,
  employeeId: ObjectId,
  leaveTypeId: ObjectId,
  startDate: Date,
  endDate: Date,
  totalDays: Number,
  reason: String,
  status: String,         // "Pending" | "Approved" | "Rejected"
  reviewedAt: Date,
  createdAt: Date
}
```

### 3.10 `holidays`
```js
{
  _id: ObjectId,
  name: String,
  date: Date,
  type: String,           // "Public" | "Company" | "Weekly Off"
}
```

### 3.11 `bonuses`
```js
{
  _id: ObjectId,
  employeeId: ObjectId,
  type: String,           // "Festival" | "Performance" | "Custom"
  amount: Number,
  reason: String,
  month: String,          // "2026-07"
  createdAt: Date
}
```

### 3.12 `fines`
```js
{
  _id: ObjectId,
  employeeId: ObjectId,
  type: String,           // "Late" | "Absent" | "Manual"
  amount: Number,
  reason: String,
  month: String,
  createdAt: Date
}
```

### 3.13 `loans`
```js
{
  _id: ObjectId,
  employeeId: ObjectId,
  totalAmount: Number,
  emiAmount: Number,
  remainingBalance: Number,
  status: String,         // "Active" | "Closed"
  startDate: Date,
  createdAt: Date
}
```

### 3.14 `loan_installments`
```js
{
  _id: ObjectId,
  loanId: ObjectId,       // ref -> loans
  month: String,
  amountPaid: Number,
  paidOn: Date
}
```
*Keeping installments as their own collection avoids balance-drift bugs — `remainingBalance` on `loans` is recalculated from this collection, not edited directly.*

### 3.15 `salary` (monthly payroll run per employee — hourly-based)
```js
{
  _id: ObjectId,
  employeeId: ObjectId,
  month: String,             // "2026-07"
  hourlyRate: Number,        // snapshotted from employees.hourlyRate at generation time
  regularHours: Number,      // sum of attendance.workingHours for the month
  overtimeHours: Number,     // sum of attendance.overtimeHours for the month
  overtimeMultiplier: Number,// e.g. 1.5, pulled from company_settings
  regularPay: Number,        // hourlyRate * regularHours
  overtimePay: Number,       // hourlyRate * overtimeMultiplier * overtimeHours
  allowances: Number,
  bonusTotal: Number,
  grossSalary: Number,       // regularPay + overtimePay + allowances + bonusTotal
  deductions: {
    tax: Number,
    fine: Number,
    medical: Number,
    advanceSalary: Number,
    loanDeduction: Number
  },
  netSalary: Number,         // grossSalary - sum(deductions)
  status: String,            // "Draft" | "Finalized" | "Paid"
  generatedAt: Date
}
```
**Indexes:** compound unique `(employeeId, month)`

**Calculation flow:** `regularHours` and `overtimeHours` are summed from that employee's `attendance` documents for the given month (already tracked per day). `hourlyRate` is snapshotted from `employees.hourlyRate` at generation time, so a later rate change never rewrites an already-generated month's pay.

### 3.16 `salary_history`
```js
{
  _id: ObjectId,
  salaryId: ObjectId,     // ref -> salary
  employeeId: ObjectId,
  month: String,
  snapshot: Object,       // full frozen copy of the salary doc at generation time
  payslipUrl: String,
  createdAt: Date
}
```
*Storing a frozen `snapshot` (not live references) means past payslips never silently change if a fine or bonus is edited later.*

### 3.17 `expenses`
```js
{
  _id: ObjectId,
  category: String,       // "Office" | "Travel" | "Equipment" | "Miscellaneous"
  description: String,
  amount: Number,
  date: Date,
  createdAt: Date
}
```

### 3.18 `company_settings`
```js
{
  _id: ObjectId,
  companyName: String,
  logo: String,
  address: String,
  phone: String,
  email: String,
  currency: String,        // "NPR"
  workingHours: { start: String, end: String },
  taxPercentage: Number,
  overtimeMultiplier: Number // e.g. 1.5, applied to hourlyRate for overtime pay
}
```

### 3.19 `audit_logs`
```js
{
  _id: ObjectId,
  adminId: ObjectId,
  action: String,          // "CREATE" | "UPDATE" | "DELETE" | "APPROVE" | "REJECT"
  collectionName: String,
  documentId: ObjectId,
  metadata: Object,
  timestamp: Date
}
```

---

## 4. REST API Endpoints

### Auth
```
POST   /api/auth/login
POST   /api/auth/refresh
POST   /api/auth/logout
POST   /api/auth/change-password
```

### Dashboard
```
GET    /api/dashboard/summary
```

### Employees
```
GET    /api/employees              ?search=&department=&status=&page=
GET    /api/employees/:id
POST   /api/employees
PUT    /api/employees/:id
DELETE /api/employees/:id
GET    /api/employees/export       ?format=pdf|excel
```

### Departments
```
GET    /api/departments
POST   /api/departments
PUT    /api/departments/:id
DELETE /api/departments/:id
```

### Designations
```
GET    /api/designations
POST   /api/designations
PUT    /api/designations/:id
DELETE /api/designations/:id
```

### Attendance
```
GET    /api/attendance             ?employeeId=&date=&month=
POST   /api/attendance/mark
POST   /api/attendance/bulk-mark
GET    /api/attendance/monthly     ?month=
GET    /api/attendance/report      ?from=&to=&format=pdf|excel
```

### Leave
```
GET    /api/leave-types
POST   /api/leave-types
GET    /api/leave-requests         ?status=&employeeId=
POST   /api/leave-requests
PUT    /api/leave-requests/:id/approve
PUT    /api/leave-requests/:id/reject
GET    /api/leave-requests/balance/:employeeId
```

### Payroll
```
POST   /api/salary/generate        { employeeId, month }   // pulls hours from attendance, computes pay
GET    /api/salary                 ?month=&employeeId=
GET    /api/salary/:id
GET    /api/salary/:id/payslip     (PDF, generates/streams payslip)
GET    /api/salary-history         ?employeeId=&year=       // list of past months, for the history/download screen
GET    /api/salary-history/:id/payslip  (PDF, re-download an already-generated payslip)
```

### Bonuses
```
GET    /api/bonuses                ?employeeId=&month=
POST   /api/bonuses
DELETE /api/bonuses/:id
```

### Fines
```
GET    /api/fines                  ?employeeId=&month=
POST   /api/fines
DELETE /api/fines/:id
```

### Loans
```
GET    /api/loans                  ?employeeId=
POST   /api/loans
GET    /api/loans/:id/installments
POST   /api/loans/:id/installments
```

### Expenses
```
GET    /api/expenses               ?category=&from=&to=
POST   /api/expenses
PUT    /api/expenses/:id
DELETE /api/expenses/:id
```

### Holidays
```
GET    /api/holidays               ?year=
POST   /api/holidays
PUT    /api/holidays/:id
DELETE /api/holidays/:id
```

### Reports
```
GET    /api/reports/employee       ?format=pdf|excel|csv
GET    /api/reports/attendance     ?format=pdf|excel|csv
GET    /api/reports/leave          ?format=pdf|excel|csv
GET    /api/reports/payroll        ?format=pdf|excel|csv
GET    /api/reports/bonus          ?format=pdf|excel|csv
GET    /api/reports/fine           ?format=pdf|excel|csv
```

### Settings
```
GET    /api/settings
PUT    /api/settings
```

---

## 5. Backend Folder Structure

```
server/
├── src/
│   ├── config/
│   │   ├── db.js
│   │   └── env.js
│   ├── models/
│   │   ├── admin.model.js
│   │   ├── employee.model.js
│   │   ├── department.model.js
│   │   ├── designation.model.js
│   │   ├── attendance.model.js
│   │   ├── attendanceLog.model.js
│   │   ├── leaveType.model.js
│   │   ├── leaveRequest.model.js
│   │   ├── salary.model.js
│   │   ├── salaryHistory.model.js
│   │   ├── bonus.model.js
│   │   ├── fine.model.js
│   │   ├── loan.model.js
│   │   ├── loanInstallment.model.js
│   │   ├── expense.model.js
│   │   ├── holiday.model.js
│   │   ├── companySettings.model.js
│   │   └── auditLog.model.js
│   ├── controllers/
│   ├── routes/
│   ├── middlewares/
│   │   ├── auth.middleware.js
│   │   ├── error.middleware.js
│   │   └── audit.middleware.js
│   ├── services/
│   │   ├── payroll.service.js     // salary computation logic
│   │   ├── export.service.js      // PDF/Excel generation
│   │   └── attendance.service.js  // working hours / overtime calc
│   ├── utils/
│   └── app.js
├── .env
└── server.js
```

---

## 6. Flutter Frontend Folder Structure

```
lib/
├── core/
│   ├── constants/
│   ├── theme/
│   ├── routes/
│   ├── utils/
│   ├── services/       // api client, token storage
│   └── widgets/
│
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── employee/
│   ├── department/
│   ├── designation/
│   ├── attendance/
│   ├── leave/
│   ├── payroll/
│   ├── bonus/
│   ├── fine/
│   ├── loan/
│   ├── expense/
│   ├── holiday/
│   ├── reports/
│   ├── settings/
│   └── profile/
│
└── main.dart
```

Each feature folder follows: `data/` (models, repository), `domain/` (optional if using clean architecture), `presentation/` (screens, widgets, riverpod providers).

---

## 7. Development Roadmap

| Phase | Milestone |
|---|---|
| 1 | Backend project setup (Express, MongoDB connection, env config) |
| 2 | Admin auth (JWT login, refresh, change password) |
| 3 | Departments & Designations CRUD |
| 4 | Employee CRUD + search/filter/export |
| 5 | Attendance (mark, bulk mark, monthly view, report) |
| 6 | Leave management (types, requests, approve/reject, balance) |
| 7 | Payroll engine (hourly rate × attendance hours → pay, deductions, payslip PDF, payslip history/download) |
| 8 | Bonuses, fines, loans + installments |
| 9 | Expenses & holidays |
| 10 | Reports module (PDF/Excel/CSV exports across all modules) |
| 11 | Company settings & admin profile |
| 12 | Dashboard (aggregation queries: present/absent today, pending leaves, total salary this month) |
| 13 | Flutter frontend build-out, module by module, mirroring backend order |

**Dashboard note:** most dashboard stats (present today, absent today, pending leave requests, total salary this month) are best served by a single `/api/dashboard/summary` endpoint that runs aggregation pipelines server-side, rather than the Flutter app assembling them from multiple calls.

---

## 8. Key Design Decisions Worth Locking In Early

- **Hourly payroll calculation:** monthly pay is derived, not manually entered — `regularHours`/`overtimeHours` are summed from `attendance` for the month, multiplied by the employee's `hourlyRate` (and `overtimeMultiplier` for overtime). This means attendance must be reasonably complete before running `POST /api/salary/generate` for a month.
- **Payslip immutability:** `salary_history.snapshot` freezes the computed payslip so later edits to fines/bonuses, or a later change to the employee's `hourlyRate`, don't retroactively change past pay records.
- **Loan balance:** derived from `loan_installments`, never edited directly on the `loans` document — prevents balance drift.
- **Attendance vs attendance_logs:** `attendance` is the daily summary used everywhere in the UI/reports; `attendance_logs` is the raw punch trail, useful for audits or future multi check-in support.
- **Audit logging:** even single-admin systems benefit from an `audit_logs` trail for approvals/deletions — cheap to add now, painful to retrofit.
- **Soft delete for employees:** consider a `deletedAt` field instead of hard delete, so payroll/attendance history for past employees remains queryable.
