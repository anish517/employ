# Business Rules — Employee Management System

This document defines the actual logic behind the schema and API — the "why," not just the "what." Most payroll bugs come from these rules being implicit rather than written down, so treat this as the source of truth when the code and the doc disagree.

---

## 1. Attendance Rules

- **Standard working hours:** defined in `company_settings.workingHours` (e.g. 9:00–17:00 = 8 hours/day).
- **Late entry:** `attendance.isLate = true` if `checkIn` is later than `workingHours.start` + grace period (recommend a configurable grace period, e.g. 10 minutes, stored in `company_settings`).
- **Overtime:** any hours worked beyond the standard daily hours count as `overtimeHours`. Example: standard = 8h, employee works 9.5h → `workingHours = 8`, `overtimeHours = 1.5`.
- **Half day:** if `workingHours` falls below a configurable threshold (e.g. < 4 hours), mark as "Half Day" rather than "Present." Half-day pay = 0.5 × daily equivalent, or simply `hourlyRate × actualHoursWorked` (since payroll is hourly, half-day is naturally handled by actual hours — no special-casing needed).
- **Absent:** no attendance record for a working day (not a holiday/weekly off) = 0 hours = 0 pay for that day.
- **Holiday / Weekly Off:** days in the `holidays` collection are excluded from "expected working days" when calculating attendance completeness warnings.
- **Leave days:** a day covered by an *approved* `leave_request` is marked `status: "Leave"` in attendance. Whether it's paid depends on `leave_types.isPaid`.

## 2. Leave Rules

- **Leave balance:** `leave_types.maxDaysPerYear` minus the sum of `totalDays` from that employee's *approved* requests of that type in the current year.
- **Unapproved leave:** a `leave_request` with `status: "Pending"` does **not** affect attendance or payroll until approved. If an employee doesn't show up without an approved request, it's simply "Absent."
- **Paid vs unpaid:** `leave_types.isPaid = true` → those days are paid at the normal hourly rate as if worked (a fixed number of hours per day, e.g. standard 8h). `isPaid = false` → those days contribute 0 hours to `regularHours` for payroll.
- **Overlapping requests:** reject a new leave request if it overlaps an existing `Approved` or `Pending` request for the same employee.

## 3. Payroll Rules (Hourly)

- **Regular pay:** `regularPay = hourlyRate × regularHours`, where `regularHours` is summed from that employee's `attendance` documents for the month (capped at standard daily hours per day — anything above is overtime, not double-counted).
- **Overtime pay:** `overtimePay = hourlyRate × overtimeMultiplier × overtimeHours`. `overtimeMultiplier` comes from `company_settings` (e.g. 1.5).
- **Paid leave pay:** added to `regularHours` as if worked (see Leave Rules above), so it flows through the same `regularPay` calculation.
- **Gross salary:** `grossSalary = regularPay + overtimePay + allowances + bonusTotal`.
- **Deduction order** (recommended, so partial-fund scenarios are handled consistently): tax → fine → medical deduction → advance salary recovery → loan installment. Apply in this order if you ever need to cap total deductions (e.g. "never deduct more than 50% of gross").
- **Net salary:** `netSalary = grossSalary − (tax + fine + medical + advanceSalary + loanDeduction)`. Should never go negative — if deductions exceed gross, cap deductions and log a warning (don't silently produce a negative payslip).
- **Rounding:** round `netSalary` and all currency fields to 2 decimal places at calculation time, not just at display time, to avoid cumulative rounding drift across months.
- **Generation prerequisite:** before `POST /api/salary/generate`, check attendance completeness for that employee/month. If working days are missing attendance records, surface a warning (not necessarily a hard block) — see API spec.
- **Immutability after generation:** once `salary.status = "Finalized"`, the record (and its `salary_history.snapshot`) is frozen. Corrections require a new adjustment entry (e.g. next month's bonus/fine), not editing history.

## 4. Bonus & Fine Rules

- Bonuses and fines are **per month, per employee**, and multiple entries of the same type can exist in a month (e.g. two "Manual Fine" entries) — `bonusTotal`/fine total in the salary calc is the sum of all entries for that employee/month.
- Bonuses/fines created *after* a month is finalized apply to the **next** payroll generation, not retroactively.

## 5. Loan Rules

- A loan is created once with `totalAmount` and `emiAmount`. `remainingBalance` starts equal to `totalAmount`.
- On each successful payroll generation for that employee, if they have an `Active` loan, automatically create a `loan_installments` entry for `emiAmount` (or the remaining balance if less than one EMI) and deduct it as `loanDeduction`.
- `remainingBalance` is **always recalculated** as `totalAmount − sum(loan_installments.amountPaid)`, never edited directly.
- When `remainingBalance` reaches 0, set `loans.status = "Closed"` and stop auto-deducting in future payroll runs.

## 6. Expense Rules

- Expenses are independent of payroll — they're company-level spend tracking (Office/Travel/Equipment/Misc), not tied to an employee. No calculation dependency on other modules.

## 7. Soft Delete

- Employees are never hard-deleted if they have any attendance, leave, salary, bonus, fine, or loan history — set `status: "Inactive"` and (recommended) a `deletedAt` field instead, so historical reports and past payslips remain valid.
