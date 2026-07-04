# Environment & Setup Guide

## Prerequisites
- Node.js 18+
- MongoDB Atlas account (free tier is enough to start) or local MongoDB
- Flutter SDK (stable channel)

## Backend Setup

```bash
git clone <repo-url>
cd server
npm install
cp .env.example .env   # fill in the values below
npm run dev             # starts with nodemon
```

### `.env` variables

```
PORT=5000
NODE_ENV=development

MONGODB_URI=mongodb+srv://<user>:<password>@cluster.mongodb.net/ems

JWT_ACCESS_SECRET=replace_with_long_random_string
JWT_REFRESH_SECRET=replace_with_a_different_long_random_string
ACCESS_TOKEN_EXPIRY=15m
REFRESH_TOKEN_EXPIRY=30d

CORS_ORIGIN=http://localhost:3000

# Optional, if using Cloudinary for profile photos
CLOUDINARY_CLOUD_NAME=
CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=
```

### Seed Script

Create `server/src/scripts/seed.js` to insert:
- One default admin (`email`, hashed password)
- Default `company_settings` document (currency: NPR, standard working hours, overtime multiplier)
- A few default `departments`/`designations` if you want sample data to build the UI against

Run with: `node src/scripts/seed.js`

## Flutter Setup

```bash
cd flutter_app
flutter pub get
flutter run
```

### API base URL config

Keep the API base URL in `lib/core/constants/api_constants.dart`, switched by build flavor or a simple `--dart-define`:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api   # Android emulator → localhost
```

## Local MongoDB (alternative to Atlas)

```bash
# macOS
brew install mongodb-community
brew services start mongodb-community
# MONGODB_URI=mongodb://localhost:27017/ems
```

## Verifying the Setup

1. `npm run dev` → confirm "Connected to MongoDB" and "Server running on port 5000" in the console.
2. Hit `POST /api/auth/login` with the seeded admin credentials (Postman/Thunder Client) → confirm you get an `accessToken`.
3. Run the Flutter app → confirm the login screen can reach the API (check for CORS or network errors first if it fails).
