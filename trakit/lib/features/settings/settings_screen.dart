import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/extensions/context_ext.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../data/providers/providers.dart';
import '../../widgets/cards/glass_card.dart';
import '../../widgets/common/aurora_background.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final ctrl = ref.read(themeModeProvider.notifier);

    return AuroraBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 140),
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppGradients.sunrise,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text('V',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 24)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hi, Varun', style: context.text.headlineMedium),
                      Text('Premium · Trial', style: context.text.bodyMedium),
                    ],
                  ),
                ),
                const Icon(Icons.qr_code_rounded),
              ],
            ),
            const SizedBox(height: 22),
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppGradients.hero,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TrakIt Pro', style: context.text.titleLarge),
                        Text(
                          'Unlimited screenshot scans, Gmail sync and deeper insights.',
                          style: context.text.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _Section(
              title: 'Appearance',
              child: Row(
                children: [
                  _ThemeChip(
                      label: 'System',
                      icon: Icons.brightness_auto_rounded,
                      selected: mode == ThemeMode.system,
                      onTap: () => ctrl.set(ThemeMode.system)),
                  const SizedBox(width: 8),
                  _ThemeChip(
                      label: 'Light',
                      icon: Icons.light_mode_rounded,
                      selected: mode == ThemeMode.light,
                      onTap: () => ctrl.set(ThemeMode.light)),
                  const SizedBox(width: 8),
                  _ThemeChip(
                      label: 'Dark',
                      icon: Icons.dark_mode_rounded,
                      selected: mode == ThemeMode.dark,
                      onTap: () => ctrl.set(ThemeMode.dark)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _Section(
              title: 'Capture',
              child: Column(
                children: [
                  _TileRow(
                    icon: Icons.add_photo_alternate_rounded,
                    title: 'Default capture mode',
                    value: 'Screenshot',
                  ),
                  const Divider(height: 18),
                  _TileRow(
                    icon: Icons.alternate_email_rounded,
                    title: 'Gmail',
                    value: 'Not connected',
                    onTap: () => context.push('/add/gmail'),
                  ),
                  const Divider(height: 18),
                  _TileRow(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Bank sync (coming soon)',
                    value: '',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _Section(
              title: 'Data',
              child: Column(
                children: [
                  _TileRow(
                    icon: Icons.refresh_rounded,
                    title: 'Reseed demo data',
                    value: '',
                    onTap: () async {
                      await ref.read(transactionsProvider.notifier).reset();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Transactions reset. Pull to refresh.')),
                      );
                    },
                  ),
                  const Divider(height: 18),
                  _TileRow(
                    icon: Icons.file_download_outlined,
                    title: 'Export CSV',
                    value: 'Pro',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _Section(
              title: 'About',
              child: Column(
                children: const [
                  _TileRow(icon: Icons.shield_outlined, title: 'Privacy', value: ''),
                  Divider(height: 18),
                  _TileRow(icon: Icons.description_outlined, title: 'Terms', value: ''),
                  Divider(height: 18),
                  _TileRow(
                      icon: Icons.info_outline_rounded,
                      title: 'Version',
                      value: '1.0.0'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(title.toUpperCase(),
              style: context.text.labelSmall),
        ),
        GlassCard(child: child),
      ],
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: selected ? AppGradients.brand : null,
            color: selected ? null : context.scheme.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected
                      ? Colors.white
                      : context.scheme.onSurface.withValues(alpha: 0.7),
                  size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : context.scheme.onSurface.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;
  const _TileRow({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.brand),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: context.text.titleMedium)),
            if (value.isNotEmpty)
              Text(value, style: context.text.bodyMedium),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}
