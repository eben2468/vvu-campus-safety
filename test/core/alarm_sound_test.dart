import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// The alarm must stay long and loud enough to wake an officer.
void main() {
  test('the SOS alarm is a loud 16-bit WAV of at least 8 seconds', () {
    final bytes = File(
      'android/app/src/main/res/raw/sos_alarm.wav',
    ).readAsBytesSync();
    final file = ByteData.sublistView(bytes);

    expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
    expect(file.getUint16(34, Endian.little), 16);

    final bytesPerSecond = file.getUint32(28, Endian.little);
    final dataBytes = file.getUint32(40, Endian.little);
    expect(dataBytes / bytesPerSecond, greaterThanOrEqualTo(8));

    var peak = 0;
    for (var offset = 44; offset < 44 + dataBytes; offset += 2) {
      final sample = file.getInt16(offset, Endian.little).abs();
      if (sample > peak) peak = sample;
    }
    expect(peak / 32767, greaterThan(0.9));
  });
}
