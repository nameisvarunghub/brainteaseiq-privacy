import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/extensions/context_ext.dart';
import '../../core/theme/app_gradients.dart';
import '../../widgets/cards/glass_card.dart';
import '../../widgets/common/aurora_background.dart';

class AddExpenseScreen extends StatelessWidget {
  const AddExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = <_Tile>[
      _Tile(
        emoji: '📸',
        title: 'Upload Screenshot',
        body: 'PhonePe, GPay, Swiggy, Amazon — instantly parsed.',
        route: '/add/screenshot',
        gradient: AppGradients.brand,
        primary: true,
      ),
      _Tile(
        emoji: '⚡️',
        title: 'Quick Add',
        body: 'Type "₹350 Zomato" — AI handles the rest.',
        route: '/add/quick',
        gradient: AppGradients.sunrise,
      ),
      _Tile(
        emoji: '📧',
        title: 'Gmail Sync',
        body: 'Scan transaction emails — one-tap import.',
        route: '/add/gmail',
        gradient: const LinearGradient(
            colors: [Color(0xFFFF94B8), Color(0xFFEA5A8A)]),
      ),
      _Tile(
        emoji: '🧾',
        title: 'Scan Receipt',
        body: 'Snap a restaurant or store bill.',
        route: '/add/receipt',
        gradient: const LinearGradient(
            colors: [Color(0xFF94EAFF), Color(0xFF5AC9EA)]),
      ),
    ];

    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add an expense', style: context.text.displaySmall),
                    const SizedBox(height: 6),
                    Text(
                      'Pick the fastest way — TrakIt fills in everything else.',
                      style: context.text.bodyLarge,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  itemCount: tiles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, i) => _MethodCard(tile: tiles[i])
                      .animate()
                      .fade(delay: (i * 80).ms, duration: 380.ms)
                      .moveY(
                        begin: 22,
                        end: 0,
                        delay: (i * 80).ms,
                        duration: 380.ms,
                        curve: Curves.easeOutCubic,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile {
  final String emoji;
  final String title;
  final String body;
  final String route;
  final LinearGradient gradient;
  final bool primary;
  const _Tile({
    required this.emoji,
    required this.title,
    required this.body,
    required this.route,
    required this.gradient,
    this.primary = false,
  });
}

class _MethodCard extends StatelessWidget {
  final _Tile tile;
  const _MethodCard({required this.tile});

  @override
  Widget build(BuildContext context) {
    if (tile.primary) {
      return InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => context.push(tile.route),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: tile.gradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: tile.gradient.colors.last.withValues(alpha: 0.45),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(tile.emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Recommended · ',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 1.0),
                        ),
                        const Text(
                          'MOST USED',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 1.0),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tile.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tile.body,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ],
          ),
        ),
      );
    }

    return GlassCard(
      onTap: () => context.push(tile.route),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: tile.gradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: tile.gradient.colors.last.withValues(alpha: 0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(tile.emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tile.title, style: context.text.titleLarge),
                const SizedBox(height: 4),
                Text(tile.body, style: context.text.bodyMedium),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
