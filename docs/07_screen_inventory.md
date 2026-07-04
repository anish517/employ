# Screen Inventory — Flutter App

| Module | Screens | Notes |
|---|---|---|
| Auth | Login | Single admin login, no signup screen needed |
| Dashboard | Dashboard Home | Stat cards + recent activity feed + quick action buttons |
| Employee | Employee List, Employee Detail, Add/Edit Employee Form | List has search/filter bar; detail shows tabs (Info, Attendance, Leave, Salary history) |
| Department | Department List, Add/Edit Department (modal/dialog) | Shows employee count per department |
| Designation | Designation List, Add/Edit Designation (modal/dialog) | |
| Attendance | Daily Attendance (mark), Bulk Attendance, Monthly Calendar View, Attendance Report | Monthly Calendar View doubles as the "history" screen per employee |
| Leave | Leave Requests List (Pending/Approved/Rejected tabs), Leave Request Detail (approve/reject actions), Leave Balance View, Leave Type Management | |
| Payroll | Generate Salary, Salary List (by month), Payslip Preview/Download, Salary History (per employee) | Salary History screen satisfies "view/download past months' payslips" |
| Bonus | Bonus List, Add Bonus (modal) | |
| Fine | Fine List, Add Fine (modal) | |
| Loan | Loan List, Loan Detail (installment history), Add Loan | |
| Expense | Expense List, Add/Edit Expense | |
| Holiday | Holiday List, Add/Edit Holiday | |
| Reports | Reports Hub (pick report type + filters + export format) | Single flexible screen rather than one per report type |
| Settings | Company Settings Form | Logo upload, currency, working hours, overtime multiplier, tax % |
| Profile | Admin Profile, Change Password | |

## Navigation Structure (GoRouter)

- Bottom nav or side drawer (depending on target — side drawer works better if also targeting tablet/desktop/web) with top-level destinations: Dashboard, Employees, Attendance, Leave, Payroll, Reports, More (Departments/Designations/Bonus/Fine/Loan/Expense/Holiday/Settings/Profile grouped under "More" to avoid clutter).
- Employee Detail is reached via the Employee List, not a top-level destination.
- Deep-linkable routes recommended for at least: Employee Detail (`/employees/:id`), Salary History (`/payroll/history/:employeeId`), Leave Request Detail (`/leave/:id`) — useful once you add push notifications for pending leave approvals.
