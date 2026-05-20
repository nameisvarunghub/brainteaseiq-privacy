import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/extensions/context_ext.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction.dart';
import '../../data/providers/providers.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/cards/glass_card.dart';
import '../../widgets/common/aurora_background.dart';

class ReceiptScannerScreen extends ConsumerStatefulWidget {
  const ReceiptScannerScreen({super.key});
  @override
  ConsumerState<ReceiptScannerScreen> createState() =>
      _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState
    extends ConsumerState<ReceiptScannerScreen> with TickerProviderStateMixin {
  late final AnimationController _scan = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  bool _captured = false;

  @override
  void dispose() {
    _scan.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    HapticFeedback.mediumImpact();
    setState(() => _captured = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final ocr = ref.read(ocrServiceProvider);
    final ai = ref.read(aiParserProvider);
    final raw = await ocr.recognizeFromImagePath('demo://receipt');
    final draft = ai.parseOcrText(raw, source: CaptureSource.receipt);
    await ref.read(transactionsProvider.notifier).add(
          ExpenseTxn(
            id: const Uuid().v4(),
            amount: draft.amount,
            merchant: draft.merchant,
            categoryKey: draft.categoryKey,
            date: draft.date,
            payment: draft.payment,
            source: CaptureSource.receipt,
            rawSourceText: raw,
          ),
        );
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CapturedSheet(
        amount: draft.amount,
        merchant: draft.merchant,
        onDone: () {
          Navigator.of(context).pop();
          context.go('/home');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // fake camera frame backdrop
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1A0E29), Color(0xFF000000)],
                  ),
                ),
              ),
            ),
            // viewfinder
            Center(
              child: AnimatedBuilder(
                animation: _scan,
                builder: (_, __) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 260,
                        height: 360,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                            width: 1.4,
                          ),
                        ),
                      ),
                      // corner brackets
                      ..._corners(),
                      // scan line
                      Positioned(
                        top: 80 + _scan.value * 200,
                        child: Container(
                          width: 220,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.8),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
            Positioned(
              top: 22,
              right: 24,
              child: Text(
                'Align receipt within frame',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _captured ? null : _capture,
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.6),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.black, size: 32),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _corners() {
    final w = MediaQuery.of(context).size.width;
    final inset = (w / 2) - 130 + 6;
    Widget bracket({
      double? top,
      double? bottom,
      required double horizontal,
      required Alignment alignment,
    }) {
      return Positioned(
        top: top,
        bottom: bottom,
        left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft
            ? horizontal
            : null,
        right: alignment == Alignment.topRight || alignment == Alignment.bottomRight
            ? horizontal
            : null,
        child: CustomPaint(
          size: const Size(24, 24),
          painter: _CornerPainter(alignment: alignment),
        ),
      );
    }

    return [
      bracket(top: 6, horizontal: inset, alignment: Alignment.topLeft),
      bracket(top: 6, horizontal: inset, alignment: Alignment.topRight),
      bracket(bottom: 6, horizontal: inset, alignment: Alignment.bottomLeft),
      bracket(bottom: 6, horizontal: inset, alignment: Alignment.bottomRight),
    ];
  }
}

class _CornerPainter extends CustomPainter {
  final Alignment alignment;
  _CornerPainter({required this.alignment});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const r = 8.0;
    final s = size.width;
    final path = Path();
    if (alignment == Alignment.topLeft) {
      path.moveTo(0, s);
      path.lineTo(0, r);
      path.quadraticBezierTo(0, 0, r, 0);
      path.lineTo(s, 0);
    } else if (alignment == Alignment.topRight) {
      path.moveTo(0, 0);
      path.lineTo(s - r, 0);
      path.quadraticBezierTo(s, 0, s, r);
      path.lineTo(s, s);
    } else if (alignment == Alignment.bottomLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, s - r);
      path.quadraticBezierTo(0, s, r, s);
      path.lineTo(s, s);
    } else {
      path.moveTo(0, s);
      path.lineTo(s - r, s);
      path.quadraticBezierTo(s, s, s, s - r);
      path.lineTo(s, 0);
    }
    canvas.drawPath(path, paint..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter old) => old.alignment != alignment;
}

class _CapturedSheet extends StatelessWidget {
  final double amount;
  final String merchant;
  final VoidCallback onDone;
  const _CapturedSheet({
    required this.amount,
    required this.merchant,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 16 + context.padding.bottom,
        top: 16,
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppGradients.brand,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(height: 14),
            Text('Captured ${Money.inr(amount)}',
                style: context.text.headlineSmall),
            const SizedBox(height: 4),
            Text(merchant, style: context.text.bodyMedium),
            const SizedBox(height: 18),
            GradientButton(
              label: 'Done',
              icon: Icons.done_rounded,
              expand: true,
              onPressed: onDone,
            ),
          ],
        ),
      ),
    );
  }
}
