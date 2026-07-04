# Testing Strategy

## Priority: Payroll Math

The single highest-value place to invest in tests is `payroll.service.js` — money bugs are the most costly kind and the easiest to introduce silently (off-by-one hour, wrong overtime multiplier, double-counted leave). Write unit tests before wiring it to the API.

### Suggested unit test cases for `payroll.service.js`
- Standard month, no overtime, no leave, no bonus/fine/loan → `netSalary` matches manual calculation
- Month with overtime hours → `overtimePay` uses `overtimeMultiplier` correctly
- Month with approved paid leave → leave days count toward `regularHours`
- Month with approved unpaid leave → leave days do NOT count toward `regularHours`
- Month with multiple bonuses and fines → summed correctly
- Employee with an active loan → `loan_installments` entry created, `loanDeduction` applied, `remainingBalance` decreases
- Loan reaching exactly 0 balance → `loans.status` flips to "Closed", no further deduction next month
- Deductions exceeding gross salary → capped, never negative `netSalary`, warning logged
- Regenerating an already-`Finalized` month → returns `409 CONFLICT`, does not silently overwrite

## Integration Tests (API level)

Use `supertest` + an in-memory MongoDB (`mongodb-memory-server`) so tests don't touch real data:
- Auth: login success/failure, token refresh, expired token rejection
- Employee CRUD: create validation failures (missing `hourlyRate`, duplicate `email`)
- Attendance: unique `(employeeId, date)` constraint enforcement
- Leave: overlap rejection
- Salary generation: end-to-end from seeded attendance → correct payslip numbers

## Flutter Tests

- **Widget tests** for form screens with validation (Employee form, Leave request form) — verify error messages appear for invalid input before hitting the API.
- **Provider tests** for at least the payroll and leave notifiers — mock the repository layer, verify state transitions (loading → data / error).
- Full end-to-end (integration_test package) is optional for a solo-admin internal tool — prioritize unit + widget tests first.

## Manual QA Checklist (Month-End)

Since payroll generation is the highest-stakes recurring action, keep a simple manual checklist for the first few real months in production:
1. Confirm attendance is complete for the month before generating.
2. Generate salary for one employee, manually verify the math against the business rules doc.
3. Download the payslip PDF, confirm all fields render correctly.
4. Confirm the record appears in Salary History and is downloadable a second time.
5. Confirm loan balance decreased correctly if applicable.
