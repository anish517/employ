# State Management Plan — Riverpod

## Pattern

```
Repository (raw API calls, returns models)
   → Provider/Notifier (holds state, calls repository, exposes to UI)
      → Widget (watches provider, renders, dispatches actions)
```

Use `AsyncNotifierProvider`/`AsyncNotifier` for anything that loads from the API (handles loading/error/data states without manual boilerplate).

## Provider Map by Feature

| Feature | Providers | Notes |
|---|---|---|
| Auth | `authNotifierProvider` (AsyncNotifier<AdminUser?>) | Holds login state; `main.dart` routes to Login vs Dashboard based on this |
| Dashboard | `dashboardSummaryProvider` (FutureProvider) | Refreshes on pull-to-refresh or on return-to-dashboard |
| Employee | `employeeListProvider` (AsyncNotifier, supports search/filter params), `employeeDetailProvider.family(id)` | `.family` for detail-by-id caching |
| Department | `departmentListProvider` | Small/rarely-changing list — safe to cache aggressively |
| Designation | `designationListProvider` | Same as above |
| Attendance | `dailyAttendanceProvider.family(date)`, `monthlyAttendanceProvider.family(month)` | Bulk-mark mutates then invalidates the relevant `.family` entry |
| Leave | `leaveRequestListProvider` (with status filter param), `leaveBalanceProvider.family(employeeId)` | Approve/reject actions invalidate both the list and the balance provider |
| Payroll | `salaryGenerationProvider` (mutation-only notifier), `salaryHistoryProvider.family(employeeId)` | Generation success invalidates `salaryHistoryProvider` for that employee |
| Bonus/Fine/Loan | one list provider each, `.family(employeeId)` when scoped to a single employee | |
| Expense | `expenseListProvider` (with category/date filters) | |
| Holiday | `holidayListProvider` | |
| Settings | `companySettingsProvider` (AsyncNotifier) | Read on app start, cached globally since it rarely changes |

## Invalidation Rules of Thumb

- After any create/update/delete mutation, `ref.invalidate()` the corresponding list provider rather than manually patching cached state — simpler and avoids stale-state bugs, at the cost of one extra API call.
- Cross-feature invalidation: approving a leave request should invalidate both `leaveRequestListProvider` and `monthlyAttendanceProvider` for the affected month (since approved leave shows up in attendance).
- Salary generation should invalidate `salaryHistoryProvider`, and optionally `dashboardSummaryProvider` if "Total Salary This Month" is shown there.

## Error Handling in UI

Every `AsyncNotifier`-backed screen should have a consistent `.when(data: ..., error: ..., loading: ...)` pattern with a shared error-display widget (`core/widgets/error_view.dart`) that shows the `error.message` from the standard API error shape, plus a retry button.
