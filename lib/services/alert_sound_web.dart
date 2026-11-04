import 'package:web/web.dart' as web;

web.AudioContext? _context;

const _sweeps = 3;
const _lowHz = 800;
const _highHz = 1600;
const _riseSeconds = 0.85;
const _fadeSeconds = 0.02;
const _volume = 0.4;

/// Three rising siren sweeps, about 3 seconds, made with the Web Audio API
/// so no sound file is needed. Browsers only allow sound after the user has
/// interacted with the page; signing in to the dashboard counts.
void playAlertTone() {
  try {
    final context = _context ??= web.AudioContext();
    context.resume();
    final now = context.currentTime;
    final tone = context.createOscillator()..type = 'square';
    final volume = context.createGain()..gain.value = 0;
    tone.connect(volume);
    volume.connect(context.destination);
    for (var i = 0; i < _sweeps; i++) {
      final start = now + i;
      final end = start + _riseSeconds;
      tone.frequency
        ..setValueAtTime(_lowHz, start)
        ..linearRampToValueAtTime(_highHz, end);
      // Fades at each end avoid clicks.
      volume.gain
        ..setValueAtTime(0, start)
        ..linearRampToValueAtTime(_volume, start + _fadeSeconds)
        ..setValueAtTime(_volume, end - _fadeSeconds)
        ..linearRampToValueAtTime(0, end);
    }
    tone.start(now);
    tone.stop(now + _sweeps);
  } catch (_) {
    // No audio device or blocked by the browser: the banner still flashes.
  }
}
