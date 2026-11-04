// Generates the SOS alarm the phone plays, so the project owns the sound.
// The dashboard plays the same rising siren (lib/services/alert_sound_web.dart).
//
//   dart run tool/make_alarm_sound.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const _outputFile = 'android/app/src/main/res/raw/sos_alarm.wav';
const _sampleRate = 44100;
const _sweeps = 10;
const _sweepSeconds = 1.0;

/// Phone speakers are loudest around these frequencies.
const _lowHz = 800.0;
const _highHz = 1600.0;

/// Each sweep rises for this long, then pauses until the next one.
const _riseSeconds = 0.85;
const _fadeSeconds = 0.02;
const _peak = 0.95;

void main() {
  final samples = _siren();
  File(_outputFile)
    ..createSync(recursive: true)
    ..writeAsBytesSync(_wavFile(samples));
  stdout.writeln('Wrote $_outputFile (${samples.length ~/ _sampleRate} s)');
}

Int16List _siren() {
  final perSweep = (_sampleRate * _sweepSeconds).round();
  final samples = Int16List(perSweep * _sweeps);
  var phase = 0.0;
  for (var i = 0; i < samples.length; i++) {
    final t = (i % perSweep) / _sampleRate;
    if (t >= _riseSeconds) continue;
    final hz = _lowHz + (_highHz - _lowHz) * (t / _riseSeconds);
    phase += 2 * pi * hz / _sampleRate;
    // Fades at each end avoid clicks.
    final fade = min(1.0, min(t, _riseSeconds - t) / _fadeSeconds);
    samples[i] = (_squared(sin(phase)) * fade * _peak * 32767).round();
  }
  return samples;
}

/// Pushes a sine wave towards a square wave: much louder at the same peak.
double _squared(double x) {
  final e = exp(8 * x);
  return (e - 1) / (e + 1);
}

/// 16-bit mono PCM in a standard WAV container.
Uint8List _wavFile(Int16List samples) {
  const headerBytes = 44;
  final dataBytes = samples.length * 2;
  final file = ByteData(headerBytes + dataBytes);
  void tag(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      file.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  file.setUint32(4, headerBytes - 8 + dataBytes, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  file.setUint32(16, 16, Endian.little); // size of this section
  file.setUint16(20, 1, Endian.little); // PCM
  file.setUint16(22, 1, Endian.little); // mono
  file.setUint32(24, _sampleRate, Endian.little);
  file.setUint32(28, _sampleRate * 2, Endian.little); // bytes per second
  file.setUint16(32, 2, Endian.little); // bytes per sample
  file.setUint16(34, 16, Endian.little); // bits per sample
  tag(36, 'data');
  file.setUint32(40, dataBytes, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    file.setInt16(headerBytes + i * 2, samples[i], Endian.little);
  }
  return file.buffer.asUint8List();
}
