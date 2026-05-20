import 'dart:math';

/// Placeholder OCR pipeline.
///
/// PRODUCTION: wire `google_mlkit_text_recognition` for offline OCR or
/// Tesseract via FFI. This scaffold fakes a delay + returns one of several
/// realistic-looking blobs so the screenshot/receipt flows can be driven
/// end-to-end without any native config in the demo.
class OcrService {
  Future<String> recognizeFromImagePath(String path) async {
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    final r = Random();
    return _samples[r.nextInt(_samples.length)];
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
