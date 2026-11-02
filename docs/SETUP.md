# Setup — VVU Campus Safety App

## 1. Tools to install

| Tool | Check | Notes |
| --- | --- | --- |
| Flutter SDK (stable) | `flutter doctor` | Includes Dart |
| Android Studio | — | For Android SDK, emulator, platform tools (you'll code in VS Code) |
| Node.js LTS | `node -v` | For Firebase CLI and Cloud Functions |
| Firebase CLI | `firebase --version` | `npm install -g firebase-tools` |
| FlutterFire CLI | `flutterfire --version` | `dart pub global activate flutterfire_cli` |
| Java JDK 17+ | `java -version` | Needed by the Firestore emulator |
| Git | `git --version` | |

VS Code extensions: **Flutter**, **Dart**, **Claude Code**, **Firebase Explorer** (optional), **Error Lens** (optional).

Run `flutter doctor` until Android toolchain and Chrome show green ticks. Accept licences with `flutter doctor --android-licenses`.

## 2. Create the project

```bash
flutter create --org gh.edu.vvu --platforms=android,web vvu_campus_safety
cd vvu_campus_safety
# copy CLAUDE.md and docs/ from this pack into the project root
git init && git add . && git commit -m "Initial project + docs"
```

Then open the folder in VS Code and start Claude Code in it — it picks up `CLAUDE.md` automatically.

## 3. Firebase project

1. Go to the Firebase console → **Add project** → name it `vvu-campus-safety` (Analytics optional).
2. **Upgrade to Blaze** (pay-as-you-go) — required for Cloud Functions and scheduled backups. Set a budget alert (e.g. a small monthly amount) in Google Cloud Billing.
3. Enable products:
   - Authentication → Email/Password
   - Firestore Database → production mode, location close to Ghana (e.g. `europe-west1`)
   - Storage
   - Cloud Messaging (enabled by default)
   - Hosting
4. Connect the app:

```bash
firebase login
flutterfire configure --project=vvu-campus-safety --platforms=android,web
firebase init firestore functions storage hosting emulators
#   Functions: TypeScript, ESLint yes
#   Hosting public dir: build/web, single-page app: yes
#   Emulators: Auth, Functions, Firestore, Storage, Hosting
```

5. Set the Functions region to match Firestore (e.g. `europe-west1`) in `functions/src/index.ts` via `setGlobalOptions({ region: 'europe-west1' })`.

## 4. Google Maps keys

1. In Google Cloud Console (same project) enable **Maps SDK for Android** and **Maps JavaScript API**.
2. Create two API keys:
   - Android key, restricted to package `gh.edu.vvu.vvu_campus_safety` + your SHA-1 (`cd android && ./gradlew signingReport`).
   - Web key, restricted to your Hosting domain and `localhost`.
3. Android: put `MAPS_API_KEY=...` in `android/local.properties` (git-ignored) and reference it in `AndroidManifest.xml` via manifest placeholders.
4. Web: add the Maps JS script tag with the web key to `web/index.html`.

## 5. Android configuration

- `minSdkVersion` 23 or higher (Firebase requirement) in `android/app/build.gradle`.
- Permissions in `AndroidManifest.xml`: `INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`, `POST_NOTIFICATIONS`, `CAMERA`, `CALL_PHONE` (optional — or use the dialer intent without it).
- Create notification channel `sos_alerts` (max importance) at app start.

## 6. Run locally with emulators

The `.firebaserc` default project is `demo-vvu-campus-safety`, an emulator-only
project that needs no login, and the committed `lib/firebase_options.dart` points at
it. So you can run everything locally before steps 3–4 are done. After
`flutterfire configure`, use `firebase use prod` (or `--project prod`) for deploys.

```bash
firebase emulators:start --import=./emulator-data --export-on-exit
# in another terminal
cd functions && npm run build -- --watch
# seed sample roster + settings
cd functions && npm run seed   # sample IDs are listed in functions/scripts/seedRoster.ts
# optional: 120 past incidents over 12 weeks for the analytics demo
cd functions && npm run seed:demo
# run the app
flutter run -d <android-device> --dart-define=USE_EMULATOR=true
flutter run -d chrome --web-port 5000 --dart-define=USE_EMULATOR=true
```

Android emulator reaches your machine's emulators at `10.0.2.2` (the default in `main.dart`); a physical phone needs your PC's LAN IP via `--dart-define=EMULATOR_HOST=192.168.x.x`. Emulator UI: http://localhost:4000. Hosting emulator: port 5002 (5000 is used by `flutter run -d chrome`).

Note: FCM push doesn't fully work in the emulator — test push notifications against the real project with a physical phone.

## 7. First admin account

Self sign-up never creates admins. Bootstrap one with a one-off script run against the real project:

```bash
gcloud auth application-default login   # credentials stay on your PC, not in the repo
cd functions
npm run make-admin -- vvu-campus-safety cso@vvu.edu.gh "Full Name" +233XXXXXXXXX "temporary-password"
```

`functions/scripts/makeAdmin.ts` sets custom claims `{ role: 'admin', verified: true }` and creates the `users` doc. If the email already has an account it is promoted and the password is ignored. After that, create officers from the dashboard.

## 8. Deploy

```bash
flutter build web --release
firebase deploy --only firestore:rules,firestore:indexes,storage,functions,hosting
flutter build apk --release   # share the APK for testing
```

Daily backups (`scheduledBackup`, 02:00 Accra) export Firestore to
`gs://<default bucket>/backups/YYYY-MM-DD`. Once, after the first functions
deploy, give the Functions service account the export role:

```bash
gcloud projects add-iam-policy-binding vvu-campus-safety \
  --member=serviceAccount:vvu-campus-safety@appspot.gserviceaccount.com \
  --role=roles/datastore.importExportAdmin
```

The same account already writes to the default bucket. To restore, run
`gcloud firestore import gs://<bucket>/backups/<date>`. Scheduled functions
don't run in the emulator.

Emergency-contact SMS uses `ConsoleSmsProvider` (logs only) until a gateway
is chosen (DECISIONS O2). To add one, implement `SmsProvider` in
`functions/src/sms/`, store its key with `firebase functions:secrets:set`,
and return it from `getSmsProvider()`.

## 9. Data you need from VVU

- ID roster CSV from Registry/HR: `idNumber,fullName,type,department`
- Security Office emergency phone number
- Campus boundary + key zones (main gate, hostels, lecture halls, admin block, church, sports field) — can be traced in Google Maps and saved as coordinates in `settings/app`
- List of on-duty officers to create accounts for
