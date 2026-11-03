# Architecture — VVU Campus Safety App

## 1. System overview

```
 ┌────────────────────────┐        ┌────────────────────────────┐
 │ Flutter mobile app     │        │ Flutter web admin dashboard│
 │ student/staff/officer  │        │ admin (CSO, supervisors)   │
 └──────────┬─────────────┘        └─────────────┬──────────────┘
            │  Firebase SDKs (Auth, Firestore, Storage, FCM, callable Functions)
            ▼                                    ▼
 ┌──────────────────────────────────────────────────────────────┐
 │ Firebase                                                      │
 │  Auth (custom claims: role)   Firestore   Storage   FCM       │
 │  Cloud Functions (TypeScript, v2)   Hosting (admin web)       │
 └──────────────────────────────────────────────────────────────┘
            │
            ▼
   SMS gateway (Ghana provider, behind SmsProvider interface)
```

One Flutter codebase builds both targets. `kIsWeb` + the user's role decide which shell/router branch loads: web → admin routes only; mobile → student/staff or officer routes.

## 2. Roles and claims

- Custom claim `role` ∈ `student | staff | officer | admin`, set only by Cloud Functions.
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

Subcollection `users/{uid}/contacts/{contactId}`: `name`, `phone` (+233…), `relationship`, `createdAt`. Owner-only in rules. Max 5: enforced in the app; `onIncidentCreated` texts at most 5.

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
| responseSeconds | number? | `acknowledgedAt − createdAt`, set by function |
| active | bool | true until resolved/false_alarm (simplifies queries) |

Subcollections:
- `locations/{autoId}`: `point` (geopoint), `accuracy` (number, m), `timestamp`. Written by reporter device during active SOS only.
- `events/{autoId}`: `type` (`created|alerted|accepted|assigned|on_scene|note|resolved|false_alarm|cancelled`), `actorId`, `actorName`, `text`, `timestamp`. `created` and `alerted` are written by `onIncidentCreated` (`actorId: system` for alerted); clients write only their own actions.
- `messages/{autoId}`: `senderId`, `senderName`, `senderRole`, `text`, `imageUrl?`, `timestamp`. Chat photos are stored at `incidents/{id}/chat_{messageId}.jpg` (D35).

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
- `users`: `role ASC, onDuty ASC` (on-duty officer lookup in `onIncidentCreated`)
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
| `new` | `alerted` | `onIncidentCreated` function |
| `new`, `alerted` | `cancelled`* | reporter ("I'm safe") within any time before accept |
| `alerted` | `accepted` | officer/admin |
| `accepted` | `on_scene` | assigned officer/admin |
| `accepted`, `on_scene` | `resolved` | assigned officer/admin |
| `alerted`, `accepted`, `on_scene` | `false_alarm` | officer/admin |

\* `cancelled` is recorded as an `events` type and sets status `resolved` with `cancelledByReporter: true` — keeps the status enum to the six values in CLAUDE.md.

Every transition: update `status` (+ timestamps), write an `events` doc, notify reporter. Enforce allowed transitions in security rules (simple version) and in a shared Dart `IncidentStatus.canTransition()` helper.

## 5. Cloud Functions (`/functions/src`)

| Function | Type | Purpose |
| --- | --- | --- |
| `verifyId` | callable | Check `idRoster`, set claims `role`+`verified`, create `users` doc, mark roster `claimedBy`. Transaction to prevent double claim. |
| `onIncidentCreated` | Firestore onCreate `incidents/{id}` | Set `status: alerted`, write `events`, send FCM to all `onDuty` officers (high priority, data + notification), SMS emergency contacts if `kind == sos`. |
| `onIncidentUpdated` | Firestore onUpdate | On status change: compute `responseSeconds`, set `active=false` when closed, increment `falseAlarmCount`, push update to reporter. |
| `onMessageCreated` | Firestore onCreate `incidents/{id}/messages/{m}` | Push to the other party(ies). |
| `onAnnouncementCreated` | Firestore onCreate | Push to audience via FCM topics (`all`, `students`, `staff`, `officers`). |
| `adminCreateUser` | callable (admin) | Create officer/admin account, set claims, audit log. |
| `adminSetRole` | callable (admin) | Change role / deactivate (also `auth.updateUser({disabled})`), audit log. |
| `adminImportRoster` | callable (admin) | Accept parsed CSV rows (≤ 5000 per call), batch-write `idRoster`, audit log. |
| `adminUpdateSettings` | callable (admin) | Validate and save `settings/app` (clients cannot write it), audit log `settings_updated` with the changed fields. |
| `scheduledBackup` | scheduled (daily 02:00 Africa/Accra) | Firestore export to `gs://<bucket>/backups/YYYY-MM-DD`. |

SMS: `functions/src/sms/SmsProvider.ts` interface `send(to: string, text: string)`; `ConsoleSmsProvider` for dev; real provider added once chosen. API key via `defineSecret`.

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
      allow create, delete: if false; // functions only
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

Storage (`storage.rules`): `incidents/{incidentId}/{file}` — write if signed in, `contentType.matches('image/.*')`, size < 2 MB; read if officer or the incident's reporter (check via Firestore `get` in rules or store `reporterId` in custom metadata).

Write rules tests with `@firebase/rules-unit-testing` against the emulator.

## 7. Notifications

- Officers: high-priority FCM data message with `type: 'sos'|'report'`, `incidentId`. Android notification channel `sos_alerts` with max importance and a distinct sound.
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
    auth_service.dart  firestore_service.dart  storage_service.dart
    location_service.dart  messaging_service.dart  functions_service.dart
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
functions/
  src/index.ts  src/verifyId.ts  src/incidents.ts  src/admin.ts  src/backup.ts  src/sms/
  test/
```

## 10. Environments

- `dev`: Firebase Emulator Suite (auth 9099, firestore 8080, functions 5001, storage 9199, UI 4000). App connects to emulators when `--dart-define=USE_EMULATOR=true`.
- `prod`: single Firebase project (e.g. `vvu-campus-safety`) on the Blaze plan.
- Secrets: the SMS key in Functions secrets. Maps need no key: OpenStreetMap tiles via `flutter_map` (DECISIONS D50).
