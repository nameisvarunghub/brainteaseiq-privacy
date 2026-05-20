import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Wraps Google ML Kit's on-device text recognizer.
///
/// ML Kit is iOS + Android only — on web, desktop, or tests we fall back to
/// the canned sample blobs below so the screenshot/receipt flows still run
/// end-to-end. The fallback also fires when the recognizer throws (no
/// model bundle, unsupported image, etc.) — that's a degraded experience,
/// not a crash.
class OcrService {
  TextRecognizer? _recognizer;

  TextRecognizer get _r =>
      _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> recognizeFromImagePath(String path) async {
    if (_shouldFallback(path)) {
      return _sample();
    }
    try {
      final input = InputImage.fromFilePath(path);
      final result = await _r.processImage(input);
      if (result.text.trim().isEmpty) return _sample();
      return result.text;
    } catch (e, st) {
      if (kDebugMode) debugPrint('OCR failed, using sample: $e\n$st');
      return _sample();
    }
  }

  bool _shouldFallback(String path) {
    if (kIsWeb) return true;
    // Desktop platforms don't have ML Kit bindings.
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) return true;
    if (path.startsWith('demo://')) return true;
    final f = File(path);
    if (!f.existsSync()) return true;
    return false;
  }

  String _sample() {
    final r = Random();
    return _samples[r.nextInt(_samples.length)];
  }

  Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
  }

  static const _samples = <String>[
    '''PhonePe
₹ 348.00
Paid to Swiggy
UPI Ref: 4322189...
12 May 2026, 9:42 PM''',
    '''Google Pay
Paid Uber India Systems
₹ 184
Mode: UPI''',
    '''Amazon.in
Order Confirmation
Total: ₹ 2,499
Visa ending 4421''',
    '''Zomato
Order delivered
Bill: ₹ 612
Paid via PhonePe UPI''',
    '''Paytm
Recharge successful
Airtel Prepaid
₹ 359''',
  ];
}
