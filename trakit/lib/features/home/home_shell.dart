import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/extensions/context_ext.dart';
import '../../core/theme/app_gradients.dart';

class HomeShell extends StatelessWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    return Scaffold(
      extendBody: true,
      body: child,
      floatingActionButton: _AddFab(onTap: () => context.push('/add')),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _GlassTabBar(active: loc),
    );
  }
}

class _AddFab extends StatelessWidget {
  final VoidCallback onTap;
  const _AddFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppGradients.brand,
          boxShadow: [
            BoxShadow(
              color: AppGradients.brand.colors.last.withValues(alpha: 0.55),
              blurRadius: 32,
              offset: const Offset(0, 14),
            ),
          ],
          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.2),
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}

class _GlassTabBar extends StatelessWidget {
  final String active;
  const _GlassTabBar({required this.active});

  @override
  Widget build(BuildContext context) {
    final items = const [
      _Tab('/home', Icons.home_rounded, 'Home'),
      _Tab('/timeline', Icons.format_list_bulleted_rounded, 'Timeline'),
      _Tab('', Icons.add, ''), // FAB notch placeholder
      _Tab('/insights', Icons.auto_awesome_rounded, 'Insights'),
      _Tab('/settings', Icons.person_outline_rounded, 'Profile'),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + context.padding.bottom * 0.2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: context.isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.85),
              border: Border.all(
                color: context.isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.04),
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                for (final tab in items)
                  Expanded(
                    child: tab.label.isEmpty
                        ? const SizedBox.shrink()
                        : _TabButton(
                            tab: tab,
                            active: active == tab.route,
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab {
  final String route;
  final IconData icon;
  final String label;
  const _Tab(this.route, this.icon, this.label);
}

class _TabButton extends StatelessWidget {
  final _Tab tab;
  final bool active;
  const _TabButton({required this.tab, required this.active});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.go(tab.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: active ? AppGradients.brand : null,
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                tab.icon,
                color: active
                    ? Colors.white
                    : context.scheme.onSurface.withValues(alpha: 0.6),
                size: 22,
              ),
              if (active) ...[
                const SizedBox(width: 6),
                Text(
                  tab.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
