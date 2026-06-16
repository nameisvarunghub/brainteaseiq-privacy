import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Direct Anthropic Messages API client.
///
/// We hit `POST /v1/messages` over raw HTTP because no official Dart SDK
/// exists. The system prompt is intentionally large + stable so it caches
/// (Haiku 4.5 minimum cacheable prefix is 4096 tokens); the varying OCR
/// blob lives in the user turn so the cached prefix stays bit-identical
/// across requests.
///
/// We use `claude-haiku-4-5` — the cheapest current Claude. For richer
/// narrative insights swap to `claude-sonnet-4-6`; the call shape is the
/// same and Sonnet caches at 2048 tokens.
///
/// Pass the API key at build time:
///   flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-...
///
/// If the key is absent the service returns `null` and callers fall back
/// to the deterministic rule-based parser.
class ClaudeService {
  static const _envKey = String.fromEnvironment('ANTHROPIC_API_KEY');
  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _apiVersion = '2023-06-01';
  static const _model = 'claude-haiku-4-5';

  final http.Client _client;
  final String _apiKey;

  /// In production [apiKey] defaults to the value baked in via
  /// `--dart-define=ANTHROPIC_API_KEY=...`. Tests inject an explicit key
  /// (and an http.MockClient) to exercise the HTTP path without leaking
  /// credentials.
  ClaudeService({http.Client? client, String? apiKey})
      : _client = client ?? http.Client(),
        _apiKey = apiKey ?? _envKey;

  bool get isConfigured => _apiKey.isNotEmpty;

  /// Parse an OCR / quick-add blob into structured fields.
  ///
  /// Returns the JSON object Claude produced (matching [_extractionSchema])
  /// or `null` when not configured / on parse failure. Throws on transport
  /// errors so callers can decide whether to retry.
  Future<Map<String, dynamic>?> extractExpense({
    required String inputText,
    required String captureSource,
  }) async {
    if (!isConfigured) return null;

    final body = <String, dynamic>{
      'model': _model,
      'max_tokens': 512,
      'system': [
        {
          'type': 'text',
          'text': _systemPrompt,
          // The system block is large and stable across every call, so we
          // park a cache breakpoint at its end. On Haiku 4.5 the minimum
          // cacheable prefix is 4096 tokens; below that this is a no-op
          // (no error, just `cache_creation_input_tokens: 0` — see usage
          // logging below).
          'cache_control': {'type': 'ephemeral'},
        },
      ],
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text':
                  'Capture source: $captureSource\n\nRaw text:\n"""\n$inputText\n"""',
            },
          ],
        },
      ],
      'output_config': {
        'format': {
          'type': 'json_schema',
          'schema': _extractionSchema,
        },
      },
    };

    final res = await _client.post(
      Uri.parse(_endpoint),
      headers: const {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': _apiVersion,
      },
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      // Surface 4xx loudly during development so misconfigured schemas
      // and bad keys don't silently fall back to rules.
      if (kDebugMode) {
        debugPrint('Claude ${res.statusCode}: ${res.body}');
      }
      return null;
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    _logUsage(decoded['usage'] as Map<String, dynamic>?);

    final content = decoded['content'] as List<dynamic>? ?? const [];
    for (final block in content) {
      if (block is Map<String, dynamic> && block['type'] == 'text') {
        final text = block['text'] as String? ?? '';
        try {
          return jsonDecode(text) as Map<String, dynamic>;
        } catch (_) {
          if (kDebugMode) debugPrint('Claude returned non-JSON text: $text');
          return null;
        }
      }
    }
    return null;
  }

  void _logUsage(Map<String, dynamic>? usage) {
    if (!kDebugMode || usage == null) return;
    final cached = usage['cache_read_input_tokens'] ?? 0;
    final written = usage['cache_creation_input_tokens'] ?? 0;
    final input = usage['input_tokens'] ?? 0;
    final output = usage['output_tokens'] ?? 0;
    debugPrint(
      'Claude usage — in:$input out:$output cache_write:$written cache_read:$cached',
    );
  }

  void dispose() => _client.close();

  // JSON schema constraining Claude's response. `output_config.format` with
  // `json_schema` enforces the shape — we still defensively parse on the
  // client because a model refusal can still produce non-conforming output.
  static const Map<String, dynamic> _extractionSchema = {
    'type': 'object',
    'properties': {
      'amount': {
        'type': 'number',
        'description': 'Total amount in INR. Use the largest sane value if the OCR shows line items + total.',
      },
      'merchant': {
        'type': 'string',
        'description': 'Cleaned, Title-Cased brand name. Example: "Swiggy", "Amazon", "Uber".',
      },
      'category': {
        'type': 'string',
        'enum': [
          'Food',
          'Groceries',
          'Entertainment',
          'Travel',
          'Shopping',
          'Bills',
          'Health',
          'Subscriptions',
          'Banking',
          'Other',
        ],
      },
      'payment_mode': {
        'type': 'string',
        'enum': ['upi', 'card', 'cash', 'wallet', 'netbanking', 'unknown'],
      },
      'confidence': {
        'type': 'number',
        'description': '0.0 to 1.0. Lower it when amount or merchant were guessed.',
      },
      'note': {
        'type': 'string',
        'description': 'Optional one-line context. Leave empty when nothing notable.',
      },
    },
    'required': ['amount', 'merchant', 'category', 'payment_mode', 'confidence'],
    'additionalProperties': false,
  };

  // Large + stable on purpose: detailed taxonomy makes Haiku precise without
  // a follow-up turn, and pushes the cached prefix above the 4096-token
  // threshold so subsequent calls hit the cache.
  static const String _systemPrompt = '''
You are TrakIt's expense extraction model. You read a single blob of OCR text or quick-add input from an Indian user and return a structured expense.

Output must be a single JSON object matching the provided schema — no preamble, no markdown, no extra fields.

# Categories (strict — use these exact names)

- **Food** — restaurants, cafés, food delivery. Examples: Swiggy, Zomato, Domino's, McDonald's, Burger King, Blue Tokai, Third Wave Coffee, Starbucks, KFC, Pizza Hut, Subway, Faasos, Box8, Behrouz, Wow! Momo, EatFit. Quick-add hints: "lunch", "dinner", "biryani", "pizza", "coffee", "café".
- **Groceries** — quick-commerce + supermarkets + kirana. Examples: Blinkit, Zepto, Swiggy Instamart, BigBasket, JioMart, DMart, Reliance Fresh, More, Spencer's. Hints: "milk", "vegetables", "atta", "rice".
- **Entertainment** — movies, events, gaming, OTT pay-per-view (not subscriptions). Examples: BookMyShow, PVR, INOX, Cinepolis, Steam, PlayStation Store, Epic Games, District by Zomato, Paytm Insider.
- **Travel** — ride-hail, cabs, flights, trains, buses, fuel, tolls, metro. Examples: Uber, Ola, Rapido, Meru, BluSmart, IndiGo, Vistara, Air India, SpiceJet, Akasa, IRCTC, RedBus, Yulu, Bounce, FASTag, HP, Indian Oil, BPCL, Shell. Hints: "petrol", "fuel", "cab", "auto", "metro", "toll".
- **Shopping** — e-commerce + retail. Examples: Amazon, Flipkart, Myntra, Ajio, Nykaa, Tata CLiQ, Meesho, Snapdeal, Decathlon, IKEA, H&M, Zara, Uniqlo, Lifestyle, Westside, Croma, Reliance Digital, Vijay Sales.
- **Bills** — utilities + telecom recharges. Examples: Airtel, Jio, Vi, BSNL, Tata Power, BESCOM, MSEB, Adani Electricity, JioFiber, ACT Fibernet, Hathway, broadband, electricity, water, gas, LPG, DTH.
- **Health** — pharmacy, fitness, doctors, hospitals. Examples: PharmEasy, 1mg, Apollo Pharmacy, MedPlus, Netmeds, Cult.fit, Cure.fit, gym, doctor, clinic, hospital, lab, diagnostic, dental.
- **Subscriptions** — recurring OTT + cloud + productivity. Examples: Netflix, Prime Video, Disney+ Hotstar, JioHotstar, JioSaavn, Spotify, YouTube Premium, Apple Music, iCloud+, Google One, Notion, Figma, Adobe, ChatGPT Plus, Claude, GitHub.
- **Banking** — EMIs, credit-card payments, interest, loan repayments, mutual fund SIPs. Examples: HDFC Credit Card, SBI Loan EMI, ICICI EMI, Bajaj Finserv, Groww, Zerodha, Coin, Kuvera.
- **Other** — anything that doesn't fit. Use sparingly; prefer a real category if you can justify it.

# Payment modes

- **upi** — PhonePe, GPay, Paytm UPI, BHIM, any "UPI Ref" / "VPA" / "@upi" marker, or a UPI handle.
- **card** — Visa/Mastercard/RuPay/AmEx, "card ending NNNN", "debit card", "credit card".
- **cash** — explicit "cash" / "COD" / "cash on delivery".
- **wallet** — Paytm Wallet, Amazon Pay balance, MobiKwik, Freecharge wallet (not the UPI flow).
- **netbanking** — IMPS, NEFT, RTGS, "netbanking", direct bank transfer.
- **unknown** — only when no signal at all. Don't default here lazily.

# Merchant cleaning rules

- Title Case. "swiggy" → "Swiggy". "AMAZON.IN" → "Amazon".
- Strip suffixes: ".in", ".com", "India Pvt Ltd", "Technologies", "Systems", "Bazaar Online".
- "Uber India Systems Private Limited" → "Uber". "Amazon Pay India" → "Amazon".
- For food orders via aggregators, the merchant is the aggregator (Swiggy / Zomato), not the restaurant — that's our consistent taxonomy.
- For autopay / auto-renewal subscriptions, keep the product brand: "Netflix", not "Netflix.com".

# Amount rules

- All amounts are INR. Strip ₹ / Rs. / INR prefixes. Treat "1,299.00" as 1299.0.
- When OCR shows multiple numbers (item subtotal, tax, total), pick the **total** — usually the largest sane value, often labelled "Total", "Grand Total", "Amount Paid", "You Paid".
- Reject obvious junk like "Order #4233189" — those aren't amounts.
- If you genuinely can't find an amount, return 0 and set confidence ≤ 0.3.

# Confidence

- 0.9+ when amount + merchant + category are all unambiguous from the text.
- 0.7-0.9 when one was inferred from context.
- 0.4-0.7 when multiple inferences were needed.
- ≤ 0.4 when the input was barely parseable.

# Examples

Input: "PhonePe ₹ 348.00 Paid to Swiggy UPI Ref: 4322189... 12 May 2026, 9:42 PM"
Output: {"amount": 348, "merchant": "Swiggy", "category": "Food", "payment_mode": "upi", "confidence": 0.96, "note": ""}

Input: "Amazon.in Order Confirmation Total: ₹ 2,499 Visa ending 4421"
Output: {"amount": 2499, "merchant": "Amazon", "category": "Shopping", "payment_mode": "card", "confidence": 0.94, "note": ""}

Input: "₹350 Zomato"
Output: {"amount": 350, "merchant": "Zomato", "category": "Food", "payment_mode": "unknown", "confidence": 0.88, "note": ""}

Input: "499 Netflix"
Output: {"amount": 499, "merchant": "Netflix", "category": "Subscriptions", "payment_mode": "card", "confidence": 0.9, "note": "Likely monthly renewal"}

Input: "120 petrol"
Output: {"amount": 120, "merchant": "Fuel", "category": "Travel", "payment_mode": "unknown", "confidence": 0.7, "note": ""}

Return only the JSON object. No other text.
''';
}
