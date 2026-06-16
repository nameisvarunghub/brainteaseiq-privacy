import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/extensions/context_ext.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction.dart';
import '../../data/providers/providers.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/cards/glass_card.dart';
import '../../widgets/common/aurora_background.dart';

/// Live camera preview with a custom glass viewfinder.
///
/// We initialise a [CameraController] in `initState`. If that fails — no
/// permission, no camera, desktop/web — we silently fall back to the
/// system camera via `image_picker(source: ImageSource.camera)`. Both
/// paths feed the same OCR + AI pipeline.
class ReceiptScannerScreen extends ConsumerStatefulWidget {
  const ReceiptScannerScreen({super.key});
  @override
  ConsumerState<ReceiptScannerScreen> createState() =>
      _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends ConsumerState<ReceiptScannerScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _scan = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  CameraController? _controller;
  bool _initializing = true;
  bool _hasCamera = false;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw CameraException('no_cameras', 'No cameras');
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final c = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _hasCamera = true;
        _initializing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasCamera = false;
        _initializing = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      c.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scan.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_capturing) return;
    HapticFeedback.mediumImpact();
    setState(() => _capturing = true);

    String? path;
    try {
      if (_hasCamera && _controller != null) {
        final file = await _controller!.takePicture();
        path = file.path;
      } else {
        // Fallback path: kick to the OS camera.
        final picked =
            await ImagePicker().pickImage(source: ImageSource.camera);
        path = picked?.path;
      }
    } catch (_) {
      path = null;
    }

    final ocr = ref.read(ocrServiceProvider);
    final ai = ref.read(aiParserProvider);
    final raw = await ocr.recognizeFromImagePath(path ?? 'demo://receipt');
    final draft = await ai.parseOcrText(raw, source: CaptureSource.receipt);

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

    if (path != null && path != 'demo://receipt') {
      // Best-effort cleanup of the temp image — failures are fine.
      try {
        await File(path).delete();
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() => _capturing = false);
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
          fit: StackFit.expand,
          children: [
            _backdrop(),
            _viewfinder(),
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
                _hasCamera
                    ? 'Align receipt within frame'
                    : (_initializing
                        ? 'Starting camera…'
                        : 'Tap to use system camera'),
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
              child: Center(child: _shutter()),
            ),
            if (_capturing)
              Container(
                color: Colors.black.withValues(alpha: 0.55),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      'Reading receipt…',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _backdrop() {
    final c = _controller;
    if (_hasCamera && c != null && c.value.isInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: c.value.aspectRatio,
          child: CameraPreview(c),
        ),
      );
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0E29), Color(0xFF000000)],
        ),
      ),
    );
  }

  Widget _viewfinder() {
    return Center(
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
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 1.4,
                  ),
                ),
              ),
              ..._corners(),
              if (_hasCamera)
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
    );
  }

  Widget _shutter() {
    return GestureDetector(
      onTap: _capturing ? null : _capture,
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
        right: alignment == Alignment.topRight ||
                alignment == Alignment.bottomRight
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
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
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
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter old) =>
      old.alignment != alignment;
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
              decoration: const BoxDecoration(
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
