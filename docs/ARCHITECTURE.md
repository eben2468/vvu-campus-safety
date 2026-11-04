# Architecture — VVU Campus Safety App

## 1. System overview

```
 ┌────────────────────────┐        ┌────────────────────────────┐
 │ Flutter mobile app     │        │ Flutter web admin dashboard│
 │ student/staff/officer  │        │ admin (CSO, supervisors)   │
 └──────────┬─────────────┘        └─────────────┬──────────────┘
            │  Firebase SDKs (Auth, Firestore, FCM)        │
            │  + HTTPS API calls with the user's ID token  │
            ▼                                              ▼
 ┌────────────────────────────┐        ┌───────────────────────────────┐
 │ Firebase (free Spark plan) │◄───────│ API on Vercel (functions/)    │
 │  Auth (claims: role)       │ Admin  │  privileged work: ID checks,  │
 │  Firestore                 │  SDK   │  roles, pushes, SMS, audit    │
 │  Cloud Messaging           │        │  Vercel Blob: photos, backups │
 │  Hosting (admin web)       │        └───────────▲───────────┬───────┘
 └────────────────────────────┘                    │           │
                                 every minute: sweep           ▼
                                 (cron-job.org)    SMS gateway (behind
                                                   SmsProvider interface)
```

Firebase's free plan has no Cloud Functions or Storage, so those jobs run on Vercel's free plan instead (DECISIONS D52).

One Flutter codebase builds both targets. `kIsWeb` + the user's role decide which shell/router branch loads: web → admin routes only; mobile → student/staff or officer routes.

## 2. Roles and claims

- Custom claim `role` ∈ `student | staff | officer | admin`, set only by the server API.
- Custom claim `verified: true` set after ID verification.
- App reads claims via `user.getIdTokenResult(true)` after sign-in and after role changes.
- `users/{uid}.role` mirrors the claim for display/search only — rules never trust it.

## 3. Firestore data model

All timestamps are Firestore `Timestamp` (server time via `FieldValue.serverTimestamp()` on create).

### `idRoster/{idNumber}`
| Field | Type | Notes |
| --- | --- | --- |
| idNumber | string | Doc id, e.g. `223IT0100946` |
| fullName | string | From Registry/HR |
| type | string | `student` \| `staff` |
| department | string | optional |
| active | bool | Inactive IDs can't register |
| claimedBy | string? | uid once registered |
| importedAt | timestamp | |

Admin-only read/write (via dashboard import). Clients never read it directly — `verifyId` function does.

### `users/{uid}`
| Field | Type | Notes |
| --- | --- | --- |
| fullName | string | |
| idNumber | string? | null for officer/admin created by admin |
| email | string | |
| phone | string | E.164 `+233…` |
| role | string | mirror of claim |
| verified | bool | |
| onDuty | bool | officers only |
| fcmTokens | array<string> | Push IDs of the user's devices (FCM installation IDs, see D23) |
| falseAlarmCount | number | incremented by function |
| deactivated | bool | |
| createdAt | timestamp | |

Subcollection `users/{uid}/contacts/{contactId}`: `name`, `phone` (+233…), `relationship`, `createdAt`. Owner-only in rules. Max 5: enforced in the app; `syncIncident` texts at most 5.

### `incidents/{incidentId}`
| Field | Type | Notes |
| --- | --- | --- |
| kind | string | `sos` \| `report` |
| category | string | for reports; `emergency` for SOS |
| description | string | empty for SOS |
| status | string | see state machine |
| reporterId | string | uid |
| reporterName | string | denormalised for officer view |
| reporterPhone | string | denormalised |
| location | geopoint? | location at creation; null if the phone had no fix (D24) |
| geohash | string | for future geo queries |
| lastLocation | geopoint | latest during active SOS |
| locationLabel | string? | nearest named campus zone, optional |
| mediaUrls | array<string> | max 3 |
| assignedTo | array<string> | officer uids |
| createdAt | timestamp | |
| acknowledgedAt | timestamp? | first accept |
| resolvedAt | timestamp? | resolved or false_alarm |
| responseSeconds | number? | `acknowledgedAt − createdAt`, set by the server |
| active | bool | true until resolved/false_alarm (simplifies queries) |
| handledStatus | string? | last status the server finished handling; server-only (§5) |

Subcollections:
- `locations/{autoId}`: `point` (geopoint), `accuracy` (number, m), `timestamp`. Written by reporter device during active SOS only.
- `events/{autoId}`: `type` (`created|alerted|accepted|assigned|on_scene|note|resolved|false_alarm|cancelled`), `actorId`, `actorName`, `text`, `timestamp`. `created` and `alerted` are written by `syncIncident` (`actorId: system` for alerted); clients write only their own actions.
- `messages/{autoId}`: `senderId`, `senderName`, `senderRole`, `text`, `imageUrl?`, `timestamp`, `pushedAt?` (server-only). Chat photos are stored at `incidents/{id}/chat_{messageId}.jpg` (D35).

### `announcements/{id}`
`title`, `body`, `audience` (`all|students|staff|officers`), `createdBy`, `createdAt`.

### `auditLogs/{id}`
`actorId`, `action` (`user_created`, `role_changed`, `user_deactivated`, `user_reactivated`, `roster_imported`; `settings_updated` from Milestone 6), `target` (uid, or `idRoster`), `details` (map), `timestamp`. Written by functions only; read by admins.

### `settings/app` (single doc)
`categories` (array<string>), `securityPhone` (string), `sosCountdownSec` (number, default 3), `campusBoundary` (array<geopoint>), `zones` (array of `{name, center: geopoint, radiusM}`).

Default categories: `Theft`, `Assault`, `Harassment`, `Medical`, `Fire`, `Accident`, `Suspicious activity`, `Other`.

### Indexes (`firestore.indexes.json`)
- `incidents`: `active ASC, createdAt DESC`
- `incidents`: `reporterId ASC, createdAt DESC`
- `incidents`: `category ASC, createdAt DESC`
- `incidents`: `assignedTo ARRAY_CONTAINS, createdAt DESC`
- `announcements`: `audience ASC, createdAt DESC` (each user's announcement list)
- `users`: `role ASC, onDuty ASC` (on-duty officer lookup in `syncIncident`)
- `events` (collection group): `timestamp DESC` field override — the live board's activity feed across all incidents (rules: `match /{path=**}/events/{e}` readable by officers/admins)

## 4. Incident state machine

```
new ──(function fan-out)──▶ alerted ──accept──▶ accepted ──▶ on_scene ──▶ resolved
  │                            │                  │             │
  └──── cancel by reporter ────┴────── false_alarm (officer/admin) ┘
```

| From | To | Who |
| --- | --- | --- |
| (none) | `new` | reporter creates |
| `new` | `alerted` | `syncIncident` (server) |
| `new`, `alerted` | `cancelled`* | reporter ("I'm safe") within any time before accept |
| `alerted` | `accepted` | officer/admin |
| `accepted` | `on_scene` | assigned officer/admin |
| `accepted`, `on_scene` | `resolved` | assigned officer/admin |
| `alerted`, `accepted`, `on_scene` | `false_alarm` | officer/admin |

\* `cancelled` is recorded as an `events` type and sets status `resolved` with `cancelledByReporter: true` — keeps the status enum to the six values in CLAUDE.md.

Every transition: update `status` (+ timestamps), write an `events` doc, notify reporter. Enforce allowed transitions in security rules (simple version) and in a shared Dart `IncidentStatus.canTransition()` helper.

## 5. Server API (`/functions`)

One Vercel function (`functions/api/index.ts`, rewritten from every `/api/*` address by `vercel.json`) runs `handleApi` in `src/api/router.ts`. Keeping the whole API in one function means it stays warm, which keeps SOS alerts fast. `npm run api:dev` runs the same router on your PC against the emulators.

The app sends `POST /api/<name>` with a JSON body and `Authorization: Bearer <Firebase ID token>`; the router verifies the token. Replies are `{ "result": ... }` or `{ "error": { "code", "message" } }`.

| Call | Who | Purpose |
| --- | --- | --- |
| `verifyId` | signed in | Check `idRoster`, set claims `role`+`verified`, create `users` doc, mark roster `claimedBy`. Transaction to prevent double claim. |
| `syncIncident` | signed in | Bring an incident up to date (below). The app calls it after every incident write. |
| `notifyMessage` | message sender | Push a chat message to the other party(ies), once. |
| `notifyAnnouncement` | admin | Push to the audience via FCM topics (`all`, `students`, `staff`, `officers`), once. |
| `uploadPhoto` | verified member, officer, admin | Store a JPEG under 2 MB in Vercel Blob and return its URL. |
| `adminCreateUser` | admin | Create officer/admin account, set claims, audit log. |
| `adminSetRole` | admin | Change role / deactivate (also `auth.updateUser({disabled})`), audit log. |
| `adminImportRoster` | admin | Accept parsed CSV rows (≤ 5000 per call), batch-write `idRoster`, audit log. |
| `adminUpdateSettings` | admin | Validate and save `settings/app` (clients cannot write it), audit log `settings_updated` with the changed fields. |
| `sweep` | `CRON_SECRET` | Every minute (cron-job.org): sync anything the app couldn't report. |
| `backup` | `CRON_SECRET` | Daily 02:00 UTC (Vercel cron): save an encrypted copy of every document to Blob. |

**`syncIncident`.** A Firestore trigger would run by itself after each write; on the free plan the app has to ask instead. `incidents/{id}.handledStatus` (server-only) records the last status the server finished handling, and `syncAction()` compares it with `status`:

- `new` → **alert**: set `status: alerted`, write the `created` and `alerted` events, push to all `onDuty` officers (high priority), SMS emergency contacts if `kind == sos`.
- `status != handledStatus` → **status change**: compute `responseSeconds`, set `active=false` and `resolvedAt` when closed, increment `falseAlarmCount`, push the update to the reporter.
- otherwise nothing.

Each step runs in a transaction that also writes `handledStatus`, so repeated or simultaneous calls do the work once.

**Why an SOS can't get lost.** The call is attached to the Firestore write, so an SOS saved offline syncs the moment it reaches the server. If the phone is switched off first, `sweep` finds it within a minute (`active == true` and `status` in `new`, `accepted`, `resolved`, `false_alarm`). Whatever happens, the incident is already on the live board and officers' queues through Firestore; only the push can be delayed. An officer accepting a still-`new` incident syncs it first, because rules only allow accepting from `alerted`.

`pushedAt` on messages and announcements stops a repeated call sending a second notification.

SMS: `functions/src/sms/SmsProvider.ts` interface `send(to: string, text: string)`; `ConsoleSmsProvider` for dev; real provider added once chosen, with its key in a Vercel environment variable.

Topics: on login the app subscribes to `all` + role topic; unsubscribes on logout.

## 6. Security rules (outline — implement fully in `firestore.rules`)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {
    function signedIn() { return request.auth != null; }
    function role() { return request.auth.token.role; }
    function isAdmin() { return signedIn() && role() == 'admin'; }
    function isOfficer() { return signedIn() && role() in ['officer', 'admin']; }
    function isMember() { return signedIn() && request.auth.token.verified == true
                                 && role() in ['student', 'staff']; }

    match /idRoster/{id} { allow read, write: if isAdmin(); }

    match /users/{uid} {
      allow read: if signedIn() && (request.auth.uid == uid || isOfficer());
      // owner may edit only profile fields; role/verified/deactivated are function-only
      allow update: if request.auth.uid == uid
        && !request.resource.data.diff(resource.data).affectedKeys()
             .hasAny(['role', 'verified', 'deactivated', 'falseAlarmCount', 'idNumber']);
      allow create, delete: if false; // server only
      match /contacts/{cid} {
        allow read, write: if request.auth.uid == uid;
      }
    }

    match /incidents/{iid} {
      allow read: if isOfficer() || (signedIn() && resource.data.reporterId == request.auth.uid);
      allow create: if isMember()
        && request.resource.data.reporterId == request.auth.uid
        && request.resource.data.status == 'new';
      // reporter may only cancel; officers move status forward (validated transitions)
      allow update: if isOfficer()
        || (resource.data.reporterId == request.auth.uid
            && request.resource.data.diff(resource.data).affectedKeys()
                 .hasOnly(['lastLocation', 'status', 'cancelledByReporter', 'resolvedAt', 'active']));
      allow delete: if false;

      match /locations/{lid} {
        allow create: if get(/databases/$(db)/documents/incidents/$(iid)).data.reporterId == request.auth.uid;
        allow read: if isOfficer() || get(/databases/$(db)/documents/incidents/$(iid)).data.reporterId == request.auth.uid;
      }
      match /events/{eid} {
        allow read: if isOfficer() || get(/databases/$(db)/documents/incidents/$(iid)).data.reporterId == request.auth.uid;
        allow create: if isOfficer() || get(/databases/$(db)/documents/incidents/$(iid)).data.reporterId == request.auth.uid;
      }
      match /messages/{mid} {
        allow read, create: if isOfficer() || get(/databases/$(db)/documents/incidents/$(iid)).data.reporterId == request.auth.uid;
      }
    }

    match /announcements/{a} { allow read: if signedIn(); allow write: if isAdmin(); }
    match /auditLogs/{a} { allow read: if isAdmin(); allow write: if false; }
    match /settings/{s} { allow read: if signedIn(); allow write: if false; }  // via adminUpdateSettings
  }
}
```

Photos: there are no Storage rules on the free plan. `uploadPhoto` makes the same checks on the server (signed-in verified member or officer, JPEG only, under 2 MB, safe file name). Blob URLs carry a random suffix, so like Firebase download URLs they are unguessable and only reach people who can read the incident. A file can never be overwritten.

Write rules tests with `@firebase/rules-unit-testing` against the emulator.

## 7. Notifications

- Officers: high-priority FCM data message with `type: 'sos'|'report'`, `incidentId`. An SOS uses Android channel `sos_alarm` (max importance, a 10-second siren at alarm volume, strong vibration); a report uses `sos_alerts` (max importance, default sound), as do status and chat pushes.
- Reporters: `type: 'status'` with new status; `type: 'message'` for chat.
- App handles `onMessage` (foreground → local notification), `onMessageOpenedApp` and `getInitialMessage` → route to incident screen.
- Request notification permission at onboarding (Android 13+ requires runtime permission).

## 8. Location

- `geolocator` with `LocationAccuracy.high`; ask permission at onboarding and again on first SOS if denied.
- Active SOS: `Geolocator.getPositionStream(distanceFilter: 10)` + a 10 s timer fallback; each fix → `locations` doc + `lastLocation` on incident.
- Android: foreground service notification while SOS is active so streaming continues with the screen off (`geolocator` Android foreground notification config). No background tracking otherwise.
- Web dashboard reads `lastLocation` and renders markers; heatmap uses `location` of all incidents in the filter range.

## 9. App structure (Flutter)

```
lib/
  main.dart                 # Firebase.initializeApp, ProviderScope, FCM bootstrap
  app.dart                  # MaterialApp.router(theme, routerConfig)
  core/
    constants.dart          # collection names, enums, defaults
    theme.dart
    utils/ (validators.dart, formatters.dart, geo.dart)
    errors/app_exception.dart
  models/
    app_user.dart  incident.dart  incident_event.dart  chat_message.dart
    emergency_contact.dart  announcement.dart  app_settings.dart
    incident_status.dart    # enum + canTransition()
  services/
    auth_service.dart  firestore_service.dart  api_client.dart
    location_service.dart  messaging_service.dart
  routing/
    router.dart             # go_router, redirect on auth/role
    routes.dart
  features/
    auth/{data,presentation}/...
    sos/...  incidents/...  officer/...  contacts/...
    notifications/...  profile/...
    admin/{shell,live_board,incidents,analytics,users,roster,announcements,settings,audit}/...
test/
  models/  features/  (unit + widget tests)
functions/                  # the server, deployed to Vercel
  api/index.ts              # Vercel entry point
  vercel.json
  src/api/router.ts         # every API call
  src/verifyId.ts  src/incidents.ts  src/chat.ts  src/admin.ts
  src/photos.ts  src/backup.ts  src/sms/
  scripts/devServer.ts      # the API on your PC
  test/
```

## 10. Environments

- `dev`: Firebase Emulator Suite (auth 9099, firestore 8080, UI 4000) plus the local API (`npm run api:dev`, port 3000). App connects to both when `--dart-define=USE_EMULATOR=true`.
- `prod`: one Firebase project on the free Spark plan, plus one Vercel project (root directory `functions`). App built with `--dart-define=API_URL=https://<project>.vercel.app/api`.
- Secrets, all as Vercel environment variables: `FIREBASE_SERVICE_ACCOUNT`, `CRON_SECRET`, `BACKUP_KEY`, `BLOB_STORE_ID` (added by Vercel), and later the SMS key. Maps need no key: OpenStreetMap tiles via `flutter_map` (DECISIONS D50).
