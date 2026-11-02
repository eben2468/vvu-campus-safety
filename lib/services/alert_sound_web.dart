import 'package:web/web.dart' as web;

web.AudioContext? _context;

/// Three short beeps made with the Web Audio API, so no sound file is
/// needed. Browsers only allow sound after the user has interacted with the
/// page; signing in to the dashboard counts.
void playAlertTone() {
  try {
    final context = _context ??= web.AudioContext();
    context.resume();
    for (var i = 0; i < 3; i++) {
      final start = context.currentTime + i * 0.35;
      final tone = context.createOscillator()
        ..type = 'square'
        ..frequency.value = 880;
      final volume = context.createGain()..gain.value = 0.15;
      tone.connect(volume);
      volume.connect(context.destination);
      tone.start(start);
      tone.stop(start + 0.2);
    }
  } catch (_) {
    // No audio device or blocked by the browser: the banner still flashes.
  }
}
