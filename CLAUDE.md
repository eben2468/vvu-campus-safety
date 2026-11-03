# CLAUDE.md — VVU Campus Safety App

This file is the standing context for Claude Code. Read it first, then the doc in `docs/` that matches the task.

## What we are building

A campus emergency and safety system for **Valley View University (VVU), Oyibi campus, Ghana**.

- **Mobile app (Flutter, Android first):** students and staff send a one-tap SOS with live GPS location, report incidents with photos, chat with security, and get alerts. Security officers use the same app (different home screen by role) to receive, accept, navigate to and resolve incidents.
- **Admin web dashboard (Flutter Web, same codebase):** the Chief Security Officer / supervisors see live alerts on a campus map, manage incidents and users, push announcements, and view heatmap analytics and reports.
- **Backend:** Firebase (Auth, Firestore, Storage, Cloud Messaging, Cloud Functions, Hosting).

This is a final-year BSc IT project (proposal: "Design and Implementation of a Smart Campus Emergency and Safety Mobile Application"). Code must be clean, readable and explainable in a thesis — prefer clarity over cleverness.

## Docs map

| File | Read it when |
| --- | --- |
| `docs/PRD.md` | Building any feature or screen — requirements, user stories, acceptance criteria |
| `docs/ARCHITECTURE.md` | Touching data, Firestore rules, Cloud Functions, notifications, folder layout |
| `docs/BUILD_PLAN.md` | Picking the next task — milestones in order with checklists |
| `docs/SETUP.md` | Environment, Firebase project, API keys, running locally |
| `docs/DECISIONS.md` | Before assuming anything the proposal left open |
| `docs/TESTING.md` | Running the test suites, alpha/beta sessions, Chapter 6 measurements |
| `docs/USER_MANUAL.md`, `docs/ADMIN_MANUAL.md` | Changing anything users see — keep the manuals in step |

## Tech stack (fixed)

- Flutter (stable channel), Dart 3, null safety. Targets: Android, Web. iOS optional later.
- State: `flutter_riverpod` (with code-gen optional; plain providers are fine).
- Routing: `go_router` with role-based redirects.
- Firebase: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging`, `cloud_functions`. Configure with FlutterFire CLI (`firebase_options.dart`).
- Location and maps: `geolocator`, `flutter_map` + `latlong2` with OpenStreetMap tiles (no API key; see DECISIONS D50). Directions open Google Maps by URL via `url_launcher`.
- Media: `image_picker`, `flutter_image_compress`.
- Other: `flutter_local_notifications` (foreground alerts), `url_launcher` (call / navigate), `fl_chart` (dashboard charts), `intl`.
- Cloud Functions: TypeScript, Firebase Functions v2, Node LTS, in `/functions`.

Always add packages with `flutter pub add <name>` (gets current stable) — do not hand-write version numbers.

## Repo layout

```
/lib
  main.dart
  app.dart                     # MaterialApp.router, theme
  firebase_options.dart        # generated — do not edit
  core/                        # constants, theme, utils, errors, extensions
  routing/                     # go_router config + role guards
  models/                      # plain Dart models with fromMap/toMap
  services/                    # thin wrappers around Firebase APIs
  features/
    auth/                      # register, login, verify ID, reset password
    sos/                       # SOS button, active SOS screen, location streaming
    incidents/                 # report form, my reports, incident detail, chat
    officer/                   # officer home, alert detail, response actions
    contacts/                  # emergency contacts
    notifications/             # FCM setup, announcements list
    profile/
    admin/                     # web-only dashboard pages
/functions                     # Cloud Functions (TypeScript)
firestore.rules
firestore.indexes.json
storage.rules
firebase.json
/docs
```

Each feature folder: `data/` (repositories), `presentation/` (screens + widgets), `providers.dart`.

## Conventions

- Models are immutable classes with `fromMap`, `toMap`, `copyWith`. Use Firestore `Timestamp` ↔ `DateTime` conversion in models only.
- UI never calls Firebase directly — go through a repository in the feature's `data/` folder.
- Collection and field names exactly as in `docs/ARCHITECTURE.md`. Do not invent new collections without updating that doc.
- Incident `status` values are a fixed enum: `new`, `alerted`, `accepted`, `on_scene`, `resolved`, `false_alarm`. Every status change also writes an `events` sub-document.
- Roles come from Firebase Auth **custom claims** (`role`: `student` | `staff` | `officer` | `admin`). Never trust a role field written by the client.
- Anything privileged (setting roles, verifying IDs, sending pushes/SMS, audit logs) runs in a Cloud Function, not the app.
- SOS must work in as few taps as possible and must never be blocked by optional data (photos, description).
- Handle permission denial (location, notifications, camera) gracefully with a clear explanation screen.
- Ghana context: phone numbers in E.164 (`+233…`), times shown in Africa/Accra (UTC+0).
- Keep widgets small; extract anything over ~150 lines.
- Write user-facing strings in plain English; no placeholder lorem ipsum in committed code.

## Commands

```bash
flutter pub get
flutter run -d <android-device>          # mobile
flutter run -d chrome --web-port 5000    # admin dashboard
flutter analyze && flutter test
firebase emulators:start                 # auth, firestore, functions, storage locally
cd functions && npm run build && npm run lint
firebase deploy --only firestore:rules,storage,functions,hosting
```

Use the Firebase Emulator Suite for development; only deploy when a milestone is done.

## How to work in this repo

1. Pick the next unchecked task in `docs/BUILD_PLAN.md`.
2. Re-read the matching section of `docs/PRD.md` (acceptance criteria) and `docs/ARCHITECTURE.md`.
3. Implement in small commits. Run `flutter analyze` and tests before finishing.
4. Tick the task in `BUILD_PLAN.md` and note anything decided in `docs/DECISIONS.md`.

## Do not

- Do not build visitor management, vehicle access, key register, patrol logs or shift handover — those are Phase 2 (see `DECISIONS.md`).
- Do not implement custom password hashing — Firebase Auth handles it.
- Do not store API keys or service-account JSON in the repo.
- Do not let a student read another student's incidents.
- Do not add video upload in the MVP (photos only).
