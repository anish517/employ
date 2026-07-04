# Deployment Guide

## Backend (Node/Express) → Railway or Render

1. Push `server/` to GitHub.
2. Create a new Web Service on Railway/Render, connect the repo, set root directory to `server` (if monorepo).
3. Build command: `npm install` — Start command: `node server.js` (or `npm start`).
4. Set environment variables in the platform dashboard (same keys as `.env` — see `05_environment_setup.md`), pointing `MONGODB_URI` to your Atlas connection string.
5. Enable auto-deploy on push to `main` once you're confident in the deploy pipeline.
6. Note the deployed URL (e.g. `https://ems-api.up.railway.app`) — this becomes the Flutter app's `API_BASE_URL`.

## Database → MongoDB Atlas

1. Create a free-tier cluster.
2. Add a database user (not your personal Atlas login) with a strong password, scoped to this cluster.
3. Network Access → allow the hosting platform's IPs, or `0.0.0.0/0` if the platform uses dynamic IPs (acceptable for a small internal tool, but keep the DB user's password strong and rotate periodically).
4. Run the seed script once against the production `MONGODB_URI` to create the initial admin account.

## Flutter App

**Mobile (Android):**
```bash
flutter build apk --release --dart-define=API_BASE_URL=https://ems-api.up.railway.app/api
```
Distribute the APK directly (internal tool, no Play Store needed) or publish to Play Store internal testing track if you want update management.

**If also building a Flutter Web admin panel** (same pattern as your Omway assignment — Flutter Web deployed on Vercel):
```bash
flutter build web --dart-define=API_BASE_URL=https://ems-api.up.railway.app/api
```
Deploy the `build/web` output to Vercel/Netlify. Remember to set `CORS_ORIGIN` on the backend to the deployed web URL.

## Post-Deployment Checklist

- [ ] Login works against production API
- [ ] Payslip PDF generation works in production (fonts/assets sometimes behave differently in containerized environments — test this specifically)
- [ ] CORS allows only the intended origin(s)
- [ ] `.env` secrets are not committed to git
- [ ] Atlas backups enabled (even free tier has some backup options — verify)
