# VVU Campus Safety

Campus emergency and safety app for Valley View University (Oyibi, Ghana):
one-tap SOS with live location, incident reports with photos, chat with
security, alerts, and a web dashboard for the Security Office.

Flutter (Android + Web) on Firebase. Start with [CLAUDE.md](CLAUDE.md) and
the [docs](docs/) folder.

## Run locally against the emulators

```bash
flutter pub get
cd functions && npm install && npm run build && cd ..
firebase emulators:start --project demo-vvu-campus-safety

# in another terminal
flutter run -d chrome --web-port 5000 --dart-define=USE_EMULATOR=true
flutter run -d <android-device> --dart-define=USE_EMULATOR=true
# physical phone: add --dart-define=EMULATOR_HOST=<your PC's LAN IP>
```

Emulator UI: http://localhost:4000

Until `flutterfire configure` is run, `lib/firebase_options.dart` holds
emulator-only values for the `demo-vvu-campus-safety` project — see
[docs/SETUP.md](docs/SETUP.md).
