# Employee Management System — Documentation Index

Admin-only HR & payroll system. Stack: Flutter (Riverpod) + Node.js/Express + MongoDB, hourly-rate-based payroll.

## Documents

| # | Document | Covers |
|---|---|---|
| 00 | [Schema, API, Folders, Roadmap](00_schema_api_folders_roadmap.md) | MongoDB collections, endpoint list, backend/Flutter folder structure, phased roadmap |
| 01 | [Business Rules](01_business_rules.md) | Attendance, leave, hourly payroll, bonus/fine, loan logic — the "why" behind the schema |
| 02 | [API Specification](02_api_specification.md) | Request/response bodies, validation, status codes per endpoint |
| 03 | [Auth & Security](03_auth_security.md) | JWT flow, password hashing, rate limiting, audit logging |
| 04 | [Architecture](04_architecture.md) | System diagram, layered backend structure, auth flow, payroll generation flow |
| 05 | [Environment & Setup](05_environment_setup.md) | `.env` variables, local run steps, seed script, Flutter config |
| 06 | [Validation & Error Handling](06_validation_error_handling.md) | Standard error shape, error codes, field validation rules |
| 07 | [Screen Inventory](07_screen_inventory.md) | Flutter screens per module, navigation structure |
| 08 | [State Management](08_state_management.md) | Riverpod provider map, invalidation rules |
| 09 | [Testing Strategy](09_testing_strategy.md) | Unit tests (payroll math priority), integration tests, manual QA checklist |
| 10 | [Deployment Guide](10_deployment_guide.md) | Backend + MongoDB Atlas + Flutter build/release steps |
| 11 | [Changelog](11_changelog.md) | Version history, update at end of each dev phase |

## Suggested Reading Order

If you're about to start coding: **00 → 01 → 04 → 05**, then reference **02, 03, 06** while building each module, and **07, 08** when you get to the Flutter side. **09** and **10** matter most once the first few modules are working end-to-end.

## Quick Facts

- Payroll is **hourly-rate based**: `netSalary` is derived from `attendance` hours × `employees.hourlyRate`, not a fixed monthly amount.
- Payslips are **immutable once finalized** — `salary_history` freezes a snapshot so later edits never rewrite past pay.
- Single admin, no employee login — auth is intentionally simple (one role, no permission matrix).
